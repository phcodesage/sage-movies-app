import 'package:flutter/material.dart';
import 'package:sagemovies/services/toast_service.dart';

class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  bool _smartDownloadsEnabled = true;
  bool _hasStoragePermission = true;
  final List<Map<String, String>> _downloads = [];

  void _requestStoragePermission() {
    setState(() {
      _hasStoragePermission = true;
    });
    ToastService.showSuccess(
      context,
      'Storage permission granted for offline downloads.',
      title: 'Permission Granted',
    );
  }

  void _clearAllDownloads() {
    if (_downloads.isEmpty) return;
    final count = _downloads.length;
    setState(() => _downloads.clear());
    ToastService.showInfo(
      context,
      'Cleared $count downloaded item${count > 1 ? 's' : ''}',
      title: 'Downloads Cleared',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text('Downloads'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSmartDownloadsHeader(),
          const SizedBox(height: 16),
          _buildPermissionAndStorageCard(),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Downloaded Content (${_downloads.length})',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
              if (_downloads.isNotEmpty)
                TextButton(
                  onPressed: _clearAllDownloads,
                  child: const Text('Clear All', style: TextStyle(color: Colors.redAccent)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (_downloads.isEmpty)
            _buildEmptyState()
          else
            ..._downloads.map((item) => _buildDownloadTile(item)),
        ],
      ),
    );
  }

  Widget _buildSmartDownloadsHeader() {
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Smart Downloads',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                ),
                const SizedBox(height: 2),
                Text(
                  _smartDownloadsEnabled
                      ? 'Auto-deletes watched titles & saves offline space'
                      : 'Smart downloads paused',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
          Switch(
            value: _smartDownloadsEnabled,
            activeColor: const Color(0xFFE50914),
            onChanged: (v) {
              setState(() => _smartDownloadsEnabled = v);
              ToastService.showInfo(
                context,
                v ? 'Smart downloads enabled' : 'Smart downloads paused',
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionAndStorageCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF16161B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF26262D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    _hasStoragePermission ? Icons.folder_special_rounded : Icons.folder_off_rounded,
                    color: _hasStoragePermission ? const Color(0xFFE50914) : Colors.amber,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Storage Permission',
                    style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _hasStoragePermission
                      ? const Color(0xFF10B981).withOpacity(0.15)
                      : Colors.amber.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _hasStoragePermission ? 'ALLOWED' : 'ACTION NEEDED',
                  style: TextStyle(
                    color: _hasStoragePermission ? const Color(0xFF10B981) : Colors.amber,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (!_hasStoragePermission) ...[
            const Text(
              'Grant storage access to save movie streams for offline viewing.',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE50914),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: _requestStoragePermission,
              icon: const Icon(Icons.security, size: 16),
              label: const Text('Grant Permission'),
            ),
          ] else ...[
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Device Path', style: TextStyle(color: Colors.white54, fontSize: 11)),
                Text('/storage/emulated/0/SageMovies', style: TextStyle(color: Colors.white38, fontSize: 11)),
              ],
            ),
          ],
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
            'Download your favorite movies & series so you can watch offline on the go.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54, fontSize: 12, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadTile(Map<String, String> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF141419),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white10),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        leading: Container(
          width: 50,
          height: 65,
          decoration: BoxDecoration(
            color: const Color(0xFF2A2A2A),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Icon(Icons.movie, color: Colors.white54, size: 28),
        ),
        title: Text(item['title']!, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        subtitle: Text(
          '${item['size']} • ${item['quality']} • ${item['duration']}',
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.white54),
          onPressed: () {
            setState(() {
              _downloads.remove(item);
            });
            ToastService.showInfo(context, 'Removed "${item['title']}" from downloads');
          },
        ),
      ),
    );
  }
}
