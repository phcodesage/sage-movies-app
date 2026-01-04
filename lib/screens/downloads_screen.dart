import 'package:flutter/material.dart';

class DownloadsScreen extends StatelessWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Downloads')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _DownloadsHeader(),
          SizedBox(height: 12),
          _DownloadItem(title: 'Edge of Tomorrow'),
          _DownloadItem(title: 'Neon City'),
          _DownloadItem(title: 'Deep Space'),
        ],
      ),
    );
  }
}

class _DownloadsHeader extends StatelessWidget {
  const _DownloadsHeader();
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text('Smart Downloads', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        SizedBox(height: 4),
        Text('Automatically download recommended content', style: TextStyle(color: Colors.white70)),
      ],
    );
  }
}

class _DownloadItem extends StatelessWidget {
  final String title;
  const _DownloadItem({required this.title});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      leading: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: const Color(0xFF222222),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Icon(Icons.movie, color: Colors.white54),
      ),
      title: Text(title),
      subtitle: const Text('1.2 GB • HD', style: TextStyle(color: Colors.white70)),
      trailing: IconButton(
        icon: const Icon(Icons.more_vert),
        onPressed: () {},
      ),
    );
  }
}
