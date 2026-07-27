import 'package:flutter/material.dart';

class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  bool _smartDownloadsEnabled = true;

  final List<Map<String, String>> _downloads = [
    {'title': 'The Odyssey', 'size': '1.8 GB', 'quality': 'HD 1080p', 'duration': '2h 15m'},
    {'title': 'The Dink', 'size': '1.2 GB', 'quality': 'HD 720p', 'duration': '1h 45m'},
    {'title': 'In the Grey', 'size': '2.1 GB', 'quality': 'HD 1080p', 'duration': '2h 05m'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Downloads'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSmartDownloadsHeader(),
          const SizedBox(height: 16),
          _buildStorageBar(),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Downloaded Content (${_downloads.length})',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
              ),
              if (_downloads.isNotEmpty)
                TextButton(
                  onPressed: () {
                    setState(() => _downloads.clear());
                  },
                  child: const Text('Clear All', style: TextStyle(color: Colors.redAccent)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (_downloads.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: [
                  Icon(Icons.download_done, size: 56, color: Colors.white24),
                  SizedBox(height: 12),
                  Text('No downloads yet', style: TextStyle(color: Colors.white70, fontSize: 16)),
                  SizedBox(height: 4),
                  Text('Movies & shows you download will appear here', style: TextStyle(color: Colors.white38, fontSize: 12)),
                ],
              ),
            )
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
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.blueAccent, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Smart Downloads', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)),
                const SizedBox(height: 2),
                Text(
                  _smartDownloadsEnabled ? 'Auto-deleting watched episodes & downloading next' : 'Smart downloads paused',
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                ),
              ],
            ),
          ),
          Switch(
            value: _smartDownloadsEnabled,
            activeColor: const Color(0xFFE50914),
            onChanged: (v) => setState(() => _smartDownloadsEnabled = v),
          ),
        ],
      ),
    );
  }

  Widget _buildStorageBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Device Storage', style: TextStyle(color: Colors.white70, fontSize: 13)),
            Text('5.1 GB used / 64 GB free', style: TextStyle(color: Colors.white38, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: 0.18,
            backgroundColor: Colors.white12,
            color: const Color(0xFFE50914),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  Widget _buildDownloadTile(Map<String, String> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(8),
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
        subtitle: Text('${item['size']} • ${item['quality']} • ${item['duration']}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.white54),
          onPressed: () {
            setState(() {
              _downloads.remove(item);
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Removed "${item['title']}" from downloads'), behavior: SnackBarBehavior.floating),
            );
          },
        ),
      ),
    );
  }
}
