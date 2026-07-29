import 'package:flutter/material.dart';
import 'package:sagemovies/models/download_item.dart';
import 'package:sagemovies/screens/video_player_page.dart';
import 'package:sagemovies/services/download_service.dart';
import 'package:sagemovies/services/toast_service.dart';
import 'package:sagemovies/widgets/safe_cached_image.dart';

class DownloadsScreen extends StatelessWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text('Downloads'),
      ),
      // The screens live in an IndexedStack, so this page is built once and kept
      // alive — it has to listen for changes rather than read once in initState.
      body: ValueListenableBuilder<List<DownloadItem>>(
        valueListenable: DownloadService.items,
        builder: (context, downloads, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildExperimentalNotice(),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Downloaded Content (${downloads.length})',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                  if (downloads.isNotEmpty)
                    TextButton(
                      onPressed: () => _confirmClearAll(context, downloads.length),
                      child: const Text('Clear All', style: TextStyle(color: Colors.redAccent)),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              if (downloads.isEmpty)
                _buildEmptyState()
              else
                ...downloads.map((item) => _DownloadTile(item: item)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildExperimentalNotice() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF16161B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF26262D)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF0071EB).withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.download_for_offline_rounded, color: Color(0xFF0071EB), size: 24),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Offline Downloads (Experimental)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                ),
                SizedBox(height: 2),
                Text(
                  'Start playback on a title, then tap Download. Some servers '
                  'block saving and will report an error.',
                  style: TextStyle(color: Colors.white54, fontSize: 12, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.file_download_outlined, size: 48, color: Colors.white38),
          ),
          const SizedBox(height: 16),
          const Text(
            'Never be without SageMovies',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text(
            'Open a title, press play, then tap Download to save it for offline viewing.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54, fontSize: 12, height: 1.4),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmClearAll(BuildContext context, int count) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF16161B),
        title: const Text('Delete all downloads?', style: TextStyle(color: Colors.white)),
        content: Text(
          'This permanently removes $count file${count > 1 ? 's' : ''} from this device.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await DownloadService.clearAll();
    if (context.mounted) {
      ToastService.showInfo(context, 'Deleted $count download${count > 1 ? 's' : ''}');
    }
  }
}

class _DownloadTile extends StatelessWidget {
  final DownloadItem item;
  const _DownloadTile({required this.item});

  static String _formatBytes(int bytes) {
    if (bytes <= 0) return '—';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  String get _subtitle {
    switch (item.status) {
      case DownloadStatus.downloading:
        final pct = (item.progress * 100).toInt();
        return item.totalBytes > 0
            ? '$pct% • ${_formatBytes(item.bytes)} / ${_formatBytes(item.totalBytes)}'
            : '$pct% • ${_formatBytes(item.bytes)}';
      case DownloadStatus.queued:
        return 'Waiting to start… (${item.quality.label})';
      case DownloadStatus.complete:
        return '${_formatBytes(item.bytes)} • ${item.quality.label} • Ready to watch offline';
      case DownloadStatus.missing:
        return item.error ?? 'File removed from device';
      case DownloadStatus.failed:
        return item.error ?? 'Download failed';
    }
  }

  Color get _subtitleColor {
    switch (item.status) {
      case DownloadStatus.failed:
      case DownloadStatus.missing:
        return Colors.orangeAccent;
      case DownloadStatus.complete:
        return const Color(0xFF10B981);
      default:
        return Colors.white54;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF141419),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                width: 50,
                height: 65,
                child: SafeCachedImage(
                  imageUrl: item.posterUrl,
                  fit: BoxFit.cover,
                  errorWidget: (context, url, error) => Container(
                    color: const Color(0xFF2A2A2A),
                    child: const Icon(Icons.movie, color: Colors.white54, size: 28),
                  ),
                ),
              ),
            ),
            title: Text(
              item.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
            subtitle: Text(
              _subtitle,
              style: TextStyle(color: _subtitleColor, fontSize: 12),
            ),
            onTap: item.isPlayable ? () => _play(context) : null,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (item.isPlayable)
                  IconButton(
                    tooltip: 'Play offline',
                    icon: const Icon(Icons.play_circle_fill, color: Color(0xFFE50914)),
                    onPressed: () => _play(context),
                  ),
                IconButton(
                  tooltip: item.isActive ? 'Cancel' : 'Delete',
                  icon: Icon(
                    item.isActive ? Icons.close : Icons.delete_outline,
                    color: Colors.white54,
                  ),
                  onPressed: () => _remove(context),
                ),
              ],
            ),
          ),
          if (item.status == DownloadStatus.downloading)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: item.progress > 0 ? item.progress : null,
                  minHeight: 4,
                  backgroundColor: Colors.white10,
                  valueColor: const AlwaysStoppedAnimation(Color(0xFFE50914)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _play(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VideoPlayerPage.file(title: item.title, path: item.filePath),
      ),
    );
  }

  Future<void> _remove(BuildContext context) async {
    final wasActive = item.isActive;
    await DownloadService.remove(item);
    if (!context.mounted) return;
    ToastService.showInfo(
      context,
      wasActive
          ? 'Cancelled "${item.title}"'
          : 'Removed "${item.title}" from downloads',
    );
  }
}
