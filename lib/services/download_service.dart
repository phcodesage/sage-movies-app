import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sagemovies/models/download_item.dart';
import 'package:sagemovies/models/movie.dart';
import 'package:sagemovies/services/stream_sniffer_service.dart';

/// Raised with a message worth showing the user. These streams fail for
/// specific, explainable reasons and a generic error makes them undiagnosable.
class DownloadException implements Exception {
  final String message;
  DownloadException(this.message);
  @override
  String toString() => message;
}

/// Saves a sniffed stream to local storage.
///
/// Files go to the app documents directory. On targetSdk 36 scoped storage this
/// needs no runtime permission at all — WRITE_EXTERNAL_STORAGE is a no-op — so
/// there is deliberately no permission flow here.
class DownloadService {
  DownloadService._();

  static const String _prefsKey = 'downloads_v1';
  static const int _segmentRetries = 3;
  static const int _maxConsecutiveFailures = 5;

  static final ValueNotifier<List<DownloadItem>> items =
      ValueNotifier<List<DownloadItem>>([]);

  static final Map<String, bool> _cancelled = {};
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    final loaded = <DownloadItem>[];
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw != null && raw.isNotEmpty) {
        for (final e in json.decode(raw) as List) {
          loaded.add(DownloadItem.fromJson(e as Map<String, dynamic>));
        }
      }
    } catch (e) {
      debugPrint('[DownloadService] manifest load failed: $e');
    }

    // Reconcile with disk: users clear app data, and a tile that plays nothing
    // is worse than one labelled as removed.
    for (final item in loaded) {
      if (item.status == DownloadStatus.downloading ||
          item.status == DownloadStatus.queued) {
        // Nothing survives a process death mid-download.
        item.status = DownloadStatus.failed;
        item.error = 'Interrupted. Tap to retry.';
      }
      if (item.status == DownloadStatus.complete) {
        final file = File(item.filePath);
        if (!file.existsSync()) {
          item.status = DownloadStatus.missing;
          item.error = 'File removed from device';
        } else {
          item.bytes = file.statSync().size;
        }
      }
    }

    items.value = loaded;
  }

  static DownloadItem? find(String movieId) {
    for (final i in items.value) {
      if (i.id == movieId) return i;
    }
    return null;
  }

  static Future<Directory> _downloadDir() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/downloads');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  static String _sanitize(String name) =>
      name.replaceAll(RegExp(r'[^A-Za-z0-9._ -]'), '_').trim();

  /// Download the stream described by [hit] for [movie].
  ///
  /// [quality] lets the caller restrict which HLS variant is downloaded:
  ///   - [VideoQuality.low]    → lowest-bandwidth stream (smallest file)
  ///   - [VideoQuality.medium] → mid-bandwidth stream
  ///   - [VideoQuality.high]   → highest-bandwidth stream (best quality, default)
  ///
  /// For progressive MP4s the quality tier is stored for display only; actual
  /// resolution depends on what the server served.
  ///
  /// Throws [DownloadException] with a user-facing message on the failure modes
  /// that are expected in practice: hotlink protection, encrypted HLS, expired
  /// signed URLs, and a full disk.
  static Future<DownloadItem> start(
    Movie movie,
    StreamHit hit, {
    VideoQuality quality = VideoQuality.high,
  }) async {
    await init();

    final existing = find(movie.id);
    if (existing != null && existing.isActive) return existing;

    final dir = await _downloadDir();
    final ext = hit.isPlaylist ? 'ts' : 'mp4';
    // Encode quality label in filename so two downloads at different
    // qualities get separate files.
    final file = File(
      '${dir.path}/${_sanitize(movie.title)}_${movie.id}_${quality.label.replaceAll("p", "")}p.$ext',
    );

    final item = DownloadItem(
      id: movie.id,
      title: movie.title,
      posterUrl: movie.posterUrl,
      mediaType: movie.mediaType,
      filePath: file.path,
      addedAt: DateTime.now(),
      quality: quality,
      status: DownloadStatus.downloading,
    );

    _cancelled.remove(movie.id);
    _upsert(item);

    try {
      if (hit.isPlaylist) {
        await _downloadHls(hit, file, item, quality);
      } else {
        await _downloadProgressive(hit, file, item);
      }

      item.status = DownloadStatus.complete;
      item.progress = 1;
      item.bytes = await file.length();
      item.error = null;
      _upsert(item);
      return item;
    } on DownloadException catch (e) {
      await _cleanupPartial(file);
      item.status = DownloadStatus.failed;
      item.error = e.message;
      _upsert(item);
      rethrow;
    } catch (e) {
      await _cleanupPartial(file);
      item.status = DownloadStatus.failed;
      item.error = 'Download failed: $e';
      _upsert(item);
      throw DownloadException(item.error!);
    }
  }

  static void cancel(String movieId) => _cancelled[movieId] = true;

  static bool _isCancelled(String movieId) => _cancelled[movieId] == true;

  // --- Progressive (.mp4) ------------------------------------------------

  static Future<void> _downloadProgressive(
    StreamHit hit,
    File file,
    DownloadItem item,
  ) async {
    final request = http.Request('GET', Uri.parse(hit.url));
    request.headers.addAll(_replayHeaders(hit));

    final response = await http.Client().send(request);
    if (response.statusCode == 403 || response.statusCode == 401) {
      throw DownloadException(
        "This server doesn't allow downloads. Try a different server.",
      );
    }
    if (response.statusCode != 200 && response.statusCode != 206) {
      throw DownloadException('Server returned ${response.statusCode}.');
    }

    final total = response.contentLength ?? 0;
    item.totalBytes = total;

    final sink = file.openWrite();
    var downloaded = 0;
    try {
      await for (final chunk in response.stream) {
        if (_isCancelled(item.id)) throw DownloadException('Download cancelled.');
        downloaded += chunk.length;
        sink.add(chunk);
        item.bytes = downloaded;
        item.progress = total > 0 ? (downloaded / total).clamp(0.0, 1.0) : 0;
        _notify();
      }
    } on FileSystemException catch (e) {
      throw DownloadException('Not enough space on device (${e.osError?.message ?? e.message}).');
    } finally {
      await sink.flush();
      await sink.close();
    }
  }

  // --- HLS (.m3u8) -------------------------------------------------------

  /// Downloads every segment into a single file.
  ///
  /// Raw MPEG-TS concatenation is directly playable by ExoPlayer, which backs
  /// video_player on Android, so no remux step is needed.
  static Future<void> _downloadHls(
    StreamHit hit,
    File file,
    DownloadItem item,
    VideoQuality quality,
  ) async {
    final headers = _replayHeaders(hit);
    var playlistUrl = Uri.parse(hit.url);
    var body = await _fetchText(playlistUrl, headers);

    // A master playlist lists variants; pick the one matching the quality tier.
    if (body.contains('#EXT-X-STREAM-INF')) {
      final variant = _pickVariantForQuality(body, playlistUrl, quality);
      if (variant == null) {
        throw DownloadException('Could not read the stream quality list.');
      }
      playlistUrl = variant;
      body = await _fetchText(playlistUrl, headers);
    }

    if (_isEncrypted(body)) {
      throw DownloadException(
        "This stream is encrypted and can't be saved offline.",
      );
    }

    final segments = _parseSegments(body, playlistUrl);
    if (segments.isEmpty) {
      throw DownloadException('No downloadable segments found in this stream.');
    }

    item.totalBytes = 0;
    final sink = file.openWrite();
    var consecutiveFailures = 0;
    var downloaded = 0;

    try {
      for (var i = 0; i < segments.length; i++) {
        if (_isCancelled(item.id)) throw DownloadException('Download cancelled.');

        List<int>? data;
        for (var attempt = 0; attempt < _segmentRetries; attempt++) {
          try {
            final res = await http
                .get(segments[i], headers: headers)
                .timeout(const Duration(seconds: 30));
            if (res.statusCode == 200) {
              data = res.bodyBytes;
              break;
            }
            if (res.statusCode == 403 || res.statusCode == 410) {
              // Signed segment URLs expire; no point retrying this one harder.
              break;
            }
          } catch (e) {
            debugPrint('[DownloadService] segment $i attempt $attempt: $e');
          }
          await Future.delayed(Duration(milliseconds: 300 * (attempt + 1)));
        }

        if (data == null) {
          consecutiveFailures++;
          if (consecutiveFailures >= _maxConsecutiveFailures) {
            throw DownloadException('Download link expired, please retry.');
          }
          continue;
        }

        consecutiveFailures = 0;
        sink.add(data);
        downloaded += data.length;

        item.bytes = downloaded;
        item.progress = ((i + 1) / segments.length).clamp(0.0, 1.0);
        _notify();
      }
    } on FileSystemException catch (e) {
      throw DownloadException('Not enough space on device (${e.osError?.message ?? e.message}).');
    } finally {
      await sink.flush();
      await sink.close();
    }
  }

  static Future<String> _fetchText(Uri url, Map<String, String> headers) async {
    final res = await http.get(url, headers: headers).timeout(const Duration(seconds: 20));
    if (res.statusCode == 403 || res.statusCode == 401) {
      throw DownloadException(
        "This server doesn't allow downloads. Try a different server.",
      );
    }
    if (res.statusCode != 200) {
      throw DownloadException('Server returned ${res.statusCode}.');
    }
    return res.body;
  }

  static bool _isEncrypted(String playlist) {
    for (final line in const LineSplitter().convert(playlist)) {
      if (!line.startsWith('#EXT-X-KEY')) continue;
      // METHOD=NONE means the tag is present but the media is in the clear.
      if (line.contains('METHOD=NONE')) continue;
      return true;
    }
    return false;
  }

  /// Picks the HLS variant best matching [quality].
  ///
  /// Strategy per tier:
  ///   high   → highest-bandwidth variant (original behaviour)
  ///   medium → variant whose height is closest to 480; falls back to middle
  ///            of the sorted list if resolution tags are absent
  ///   low    → lowest-bandwidth variant
  static Uri? _pickVariantForQuality(String playlist, Uri base, VideoQuality quality) {
    final lines = const LineSplitter().convert(playlist);

    // Collect all variants with their bandwidth and optional resolution.
    final variants = <_HlsVariant>[];
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (!line.startsWith('#EXT-X-STREAM-INF')) continue;

      final bwMatch = RegExp(r'BANDWIDTH=(\d+)').firstMatch(line);
      final bandwidth = bwMatch != null ? int.parse(bwMatch.group(1)!) : 0;

      // RESOLUTION=WxH is optional but most streams include it.
      final resMatch = RegExp(r'RESOLUTION=\d+x(\d+)').firstMatch(line);
      final height = resMatch != null ? int.parse(resMatch.group(1)!) : null;

      // URI is on the next non-comment, non-empty line.
      for (var j = i + 1; j < lines.length; j++) {
        final candidate = lines[j].trim();
        if (candidate.isEmpty || candidate.startsWith('#')) continue;
        variants.add(_HlsVariant(uri: base.resolve(candidate), bandwidth: bandwidth, height: height));
        break;
      }
    }

    if (variants.isEmpty) return null;

    // Sort ascending by bandwidth so index 0 is lowest quality.
    variants.sort((a, b) => a.bandwidth.compareTo(b.bandwidth));

    switch (quality) {
      case VideoQuality.low:
        return variants.first.uri;

      case VideoQuality.high:
        return variants.last.uri;

      case VideoQuality.medium:
        // If resolution data is available, pick the variant whose height is
        // closest to 480p. Otherwise fall back to the middle of the list.
        final withHeight = variants.where((v) => v.height != null).toList();
        if (withHeight.isNotEmpty) {
          withHeight.sort((a, b) =>
              (a.height! - 480).abs().compareTo((b.height! - 480).abs()));
          return withHeight.first.uri;
        }
        return variants[variants.length ~/ 2].uri;
    }
  }

  // Kept for reference; replaced by _pickVariantForQuality.
  @Deprecated('Use _pickVariantForQuality instead')
  static Uri? _pickBestVariant(String playlist, Uri base) {
    return _pickVariantForQuality(playlist, base, VideoQuality.high);
  }

  static List<Uri> _parseSegments(String playlist, Uri base) {
    final lines = const LineSplitter().convert(playlist);
    final segments = <Uri>[];
    for (final raw in lines) {
      final line = raw.trim();
      if (line.isEmpty || line.startsWith('#')) continue;
      segments.add(base.resolve(line));
    }
    return segments;
  }

  /// Referer, Origin, User-Agent and Cookie together are what most of these
  /// CDNs check; replaying without them is the usual cause of a 403.
  static Map<String, String> _replayHeaders(StreamHit hit) {
    final headers = <String, String>{};
    hit.headers.forEach((k, v) {
      final key = k.toLowerCase();
      // Hop-by-hop and range headers must not be replayed verbatim.
      if (key == 'range' || key == 'host' || key == 'connection') return;
      headers[k] = v;
    });
    headers.putIfAbsent(
      'User-Agent',
      () => 'Mozilla/5.0 (Linux; Android 13; Mobile) AppleWebKit/537.36 '
          '(KHTML, like Gecko) Chrome/125.0.0.0 Mobile Safari/537.36',
    );
    return headers;
  }

  // --- Manifest ----------------------------------------------------------

  static Future<void> remove(DownloadItem item) async {
    cancel(item.id);
    try {
      final file = File(item.filePath);
      if (await file.exists()) await file.delete();
    } catch (e) {
      debugPrint('[DownloadService] delete failed: $e');
    }
    items.value = List.of(items.value)..removeWhere((i) => i.id == item.id);
    await _save();
  }

  static Future<void> clearAll() async {
    for (final item in List.of(items.value)) {
      await remove(item);
    }
  }

  static Future<void> _cleanupPartial(File file) async {
    try {
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }

  static void _upsert(DownloadItem item) {
    final next = List.of(items.value);
    final idx = next.indexWhere((i) => i.id == item.id);
    if (idx >= 0) {
      next[idx] = item;
    } else {
      next.insert(0, item);
    }
    items.value = next;
    _save();
  }

  /// Rebuild the list identity so ValueListenableBuilder repaints on progress.
  static void _notify() => items.value = List.of(items.value);

  static Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _prefsKey,
        json.encode(items.value.map((i) => i.toJson()).toList()),
      );
    } catch (e) {
      debugPrint('[DownloadService] manifest save failed: $e');
    }
  }
}

/// Internal record used by [DownloadService._pickVariantForQuality].
class _HlsVariant {
  final Uri uri;
  final int bandwidth;

  /// Height in pixels extracted from `RESOLUTION=WxH`, or null if the tag is absent.
  final int? height;

  const _HlsVariant({required this.uri, required this.bandwidth, this.height});
}
