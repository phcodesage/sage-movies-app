import 'package:flutter/material.dart';
import 'package:sagemovies/app_state.dart';
import 'package:sagemovies/models/movie.dart';
import 'package:sagemovies/screens/web_player_page.dart';
import 'package:flutter/foundation.dart';

class DetailsScreen extends StatelessWidget {
  final Movie movie;
  const DetailsScreen({super.key, required this.movie});

  @override
  Widget build(BuildContext context) {
    final app = AppStateProvider.of(context);
    final inList = app.isInMyList(movie.id);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(movie.title),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(
                    movie.backdropUrl,
                    fit: BoxFit.cover,
errorBuilder: (context, error, stack) => Container(color: const Color(0xFF1A1A1A)),
                  ),
                ),
                const Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [Colors.black87, Colors.transparent],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white12,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('${movie.rating.toStringAsFixed(1)} IMDb'),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.hd, size: 20),
                      const SizedBox(width: 4),
                      const Text('HD'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(movie.overview, style: const TextStyle(color: Colors.white70)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
onPressed: () {
                            final type = (movie.mediaType == 'tv') ? 'tv' : 'movie';
                            final idNum = int.tryParse(movie.id);
                            final url = movie.playUrl ?? (idNum != null
                                ? 'https://vidsrc.cc/v2/embed/$type/$idNum'
                                : null);
                            if (url == null) {
                              debugPrint('Play from details: NO URL for title=${movie.title}, id=${movie.id}');
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('No stream available for this item yet')),
                              );
                              return;
                            }
                            debugPrint('Play from details: title=${movie.title}, id=${movie.id}, type=$type, url=$url');
                            Navigator.of(context).push(
                              MaterialPageRoute(
builder: (_) => WebPlayerPage(
                                title: movie.title,
                                url: url,
                              ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Play'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.download),
                          label: const Text('Download'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _ActionIcon(
                        icon: inList ? Icons.check : Icons.add,
                        label: 'My List',
                        onTap: () => app.toggleMyList(movie.id),
                      ),
                      const _ActionIcon(icon: Icons.thumb_up_alt_outlined, label: 'Rate'),
                      const _ActionIcon(icon: Icons.share_outlined, label: 'Share'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

}

class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  const _ActionIcon({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.white70)),
        ],
      ),
    );
  }
}
