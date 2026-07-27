import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sagemovies/services/api_service.dart';

class AppVersionInfo {
  final String latestVersion;
  final int versionCode;
  final String downloadUrl;
  final String directApkUrl;
  final String releaseNotes;
  final bool forceUpdate;

  AppVersionInfo({
    required this.latestVersion,
    required this.versionCode,
    required this.downloadUrl,
    required this.directApkUrl,
    required this.releaseNotes,
    required this.forceUpdate,
  });

  factory AppVersionInfo.fromJson(Map<String, dynamic> json) {
    return AppVersionInfo(
      latestVersion: json['latest_version'] ?? '1.0.2',
      versionCode: json['version_code'] ?? 3,
      downloadUrl: json['download_url'] ?? 'https://shrinkme.click/wRTWJwKz',
      directApkUrl: json['direct_apk_url'] ??
          'https://pub-bd093e291a8941608e8a6fe70c3aca53.r2.dev/sagemovies-v1.0.0.apk',
      releaseNotes: json['release_notes'] ?? 'New in-app wireless update engine & studio hub features.',
      forceUpdate: json['force_update'] ?? false,
    );
  }
}

class UpdateService {
  static const int currentVersionCode = 4;
  static const String currentVersionName = '1.0.3';
  static const MethodChannel _installerChannel =
      MethodChannel('com.example.sagemovies/installer');

  static ValueNotifier<AppVersionInfo?> availableUpdate = ValueNotifier(null);

  static Future<AppVersionInfo?> checkUpdate() async {
    try {
      final response = await http
          .get(
            Uri.parse('${ApiService.baseUrl}/api/app-version'),
            headers: ApiService.defaultHeaders,
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final info = AppVersionInfo.fromJson(data);
        if (info.versionCode > currentVersionCode) {
          availableUpdate.value = info;
          return info;
        } else {
          availableUpdate.value = null;
        }
      }
    } catch (e) {
      debugPrint('Update check error: $e');
    }
    return null;
  }

  static void promptUpdateIfNeeded(BuildContext context,
      {bool showNoUpdateToast = false}) async {
    final updateInfo = await checkUpdate();

    if (!context.mounted) return;

    if (updateInfo == null) {
      if (showNoUpdateToast) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Your app is up to date (v1.0.0)'),
            backgroundColor: Color(0xFF1E1E24),
          ),
        );
      }
      return;
    }

    showUpdateDialog(context, updateInfo);
  }

  static void showUpdateDialog(BuildContext context, AppVersionInfo updateInfo) {
    showDialog(
      context: context,
      barrierDismissible: !updateInfo.forceUpdate,
      builder: (context) => _UpdateDialogContent(updateInfo: updateInfo),
    );
  }

  static Future<void> installDownloadedApk(String filePath) async {
    try {
      await _installerChannel.invokeMethod('installApk', {'filePath': filePath});
    } catch (e) {
      debugPrint('Error invoking native installer: $e');
    }
  }
}

class _UpdateDialogContent extends StatefulWidget {
  final AppVersionInfo updateInfo;

  const _UpdateDialogContent({required this.updateInfo});

  @override
  State<_UpdateDialogContent> createState() => _UpdateDialogContentState();
}

class _UpdateDialogContentState extends State<_UpdateDialogContent> {
  bool _isDownloading = false;
  double _progress = 0.0;
  String _statusText = '';
  String? _errorMessage;

  Future<void> _startInAppDownloadAndInstall() async {
    setState(() {
      _isDownloading = true;
      _progress = 0.0;
      _statusText = 'Connecting to update server...';
      _errorMessage = null;
    });

    try {
      final downloadUrl = widget.updateInfo.directApkUrl.isNotEmpty
          ? widget.updateInfo.directApkUrl
          : widget.updateInfo.downloadUrl;

      final request = http.Request('GET', Uri.parse(downloadUrl));
      final response = await http.Client().send(request);

      if (response.statusCode != 200) {
        throw Exception('Download failed with status code ${response.statusCode}');
      }

      final contentLength = response.contentLength ?? 52000000;
      final tempDir = await getTemporaryDirectory();
      final apkFile = File('${tempDir.path}/sagemovies_update.apk');

      if (await apkFile.exists()) {
        await apkFile.delete();
      }

      final sink = apkFile.openWrite();
      int downloaded = 0;

      await for (final chunk in response.stream) {
        downloaded += chunk.length;
        sink.add(chunk);

        final p = downloaded / contentLength;
        if (mounted) {
          setState(() {
            _progress = p.clamp(0.0, 1.0);
            final mb = (downloaded / (1024 * 1024)).toStringAsFixed(1);
            final totalMb = (contentLength / (1024 * 1024)).toStringAsFixed(1);
            _statusText = 'Downloading update... $mb MB / $totalMb MB (${(_progress * 100).toInt()}%)';
          });
        }
      }

      await sink.flush();
      await sink.close();

      if (mounted) {
        setState(() {
          _statusText = 'Download complete! Launching installer...';
          _progress = 1.0;
        });
      }

      // Trigger native package installer
      await UpdateService.installDownloadedApk(apkFile.path);

      if (mounted && !widget.updateInfo.forceUpdate) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      debugPrint('In-app update download error: $e');
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _errorMessage = 'In-app download failed. Opening browser...';
        });
      }
      // Fallback to url_launcher if direct download fails
      final fallbackUri = Uri.parse(widget.updateInfo.downloadUrl);
      if (await canLaunchUrl(fallbackUri)) {
        await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF141419),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Colors.white12),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFE50914).withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.system_update_alt_rounded,
              color: Color(0xFFE50914),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Update Available',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Version ${widget.updateInfo.latestVersion}',
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'WHAT\'S NEW:',
            style: TextStyle(
              color: Color(0xFFE50914),
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white10),
            ),
            child: Text(
              widget.updateInfo.releaseNotes,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
          if (_isDownloading) ...[
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: _progress > 0 ? _progress : null,
              backgroundColor: Colors.white10,
              color: const Color(0xFFE50914),
              minHeight: 6,
              borderRadius: BorderRadius.circular(3),
            ),
            const SizedBox(height: 8),
            Text(
              _statusText,
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ],
          if (_errorMessage != null) ...[
            const SizedBox(height: 10),
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.amber, fontSize: 11),
            ),
          ],
        ],
      ),
      actions: [
        if (!widget.updateInfo.forceUpdate && !_isDownloading)
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Later',
              style: TextStyle(color: Colors.white54),
            ),
          ),
        ElevatedButton.icon(
          onPressed: _isDownloading ? null : _startInAppDownloadAndInstall,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE50914),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
          icon: _isDownloading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.download, size: 18),
          label: Text(
            _isDownloading ? 'Downloading...' : 'Update Now',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
