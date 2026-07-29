enum DownloadStatus { queued, downloading, complete, failed, missing }

/// The quality tier the user selected before the download started.
enum VideoQuality {
  /// Lowest file size – picks the lowest-bandwidth HLS variant (≤480p).
  low,
  /// Middle ground – 480p or the closest variant (≤720p).
  medium,
  /// Best quality – highest-bandwidth variant available.
  high;

  String get label {
    switch (this) {
      case VideoQuality.low:
        return '360p';
      case VideoQuality.medium:
        return '480p';
      case VideoQuality.high:
        return '720p';
    }
  }

  String get description {
    switch (this) {
      case VideoQuality.low:
        return 'Smallest file size';
      case VideoQuality.medium:
        return 'Balanced quality & size';
      case VideoQuality.high:
        return 'Best quality';
    }
  }
}

/// One entry in the download manifest.
///
/// [posterUrl] is stored as a plain string rather than round-tripped through
/// [Movie.toJson], which writes a full URL into `poster_path` that
/// `Movie.fromJson` then re-prefixes, corrupting the value on every reload.
class DownloadItem {
  final String id;
  final String title;
  final String posterUrl;
  final String mediaType;
  final String filePath;
  final DateTime addedAt;
  final VideoQuality quality;

  int bytes;
  int totalBytes;
  DownloadStatus status;
  double progress;
  String? error;

  DownloadItem({
    required this.id,
    required this.title,
    required this.posterUrl,
    required this.mediaType,
    required this.filePath,
    required this.addedAt,
    this.quality = VideoQuality.high,
    this.bytes = 0,
    this.totalBytes = 0,
    this.status = DownloadStatus.queued,
    this.progress = 0,
    this.error,
  });

  bool get isPlayable => status == DownloadStatus.complete;
  bool get isActive =>
      status == DownloadStatus.queued || status == DownloadStatus.downloading;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'posterUrl': posterUrl,
        'mediaType': mediaType,
        'filePath': filePath,
        'addedAt': addedAt.toIso8601String(),
        'quality': quality.name,
        'bytes': bytes,
        'totalBytes': totalBytes,
        'status': status.name,
        'progress': progress,
        'error': error,
      };

  factory DownloadItem.fromJson(Map<String, dynamic> json) {
    return DownloadItem(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'Untitled',
      posterUrl: json['posterUrl'] as String? ?? '',
      mediaType: json['mediaType'] as String? ?? 'movie',
      filePath: json['filePath'] as String? ?? '',
      addedAt: DateTime.tryParse(json['addedAt'] as String? ?? '') ?? DateTime.now(),
      quality: VideoQuality.values.firstWhere(
        (q) => q.name == json['quality'],
        orElse: () => VideoQuality.high,
      ),
      bytes: (json['bytes'] as num?)?.toInt() ?? 0,
      totalBytes: (json['totalBytes'] as num?)?.toInt() ?? 0,
      status: DownloadStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => DownloadStatus.failed,
      ),
      progress: (json['progress'] as num?)?.toDouble() ?? 0,
      error: json['error'] as String?,
    );
  }
}
