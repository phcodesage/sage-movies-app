import 'package:flutter/material.dart';
import 'package:sagemovies/models/movie.dart';
import 'package:sagemovies/screens/details_screen.dart';
import 'package:sagemovies/screens/web_player_page.dart';
import 'package:flutter/foundation.dart';

class HeroBanner extends StatelessWidget {
  final Movie movie;
  const HeroBanner({super.key, required this.movie});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 420,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            movie.backdropUrl,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.low,
            errorBuilder: (context, error, stack) => _fallback(),
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return _fallback(showSpinner: true);
            },
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black45,
                  Colors.black,
                ],
                stops: [0.0, 0.7, 1.0],
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  movie.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _PrimaryButton(
                      icon: Icons.play_arrow,
                      label: 'Play',
                      onPressed: () {
                        final type = (movie.mediaType == 'tv') ? 'tv' : 'movie';
                        final idNum = int.tryParse(movie.id);
                        final url = movie.playUrl ?? (idNum != null
                            ? 'https://vidsrc.cc/v2/embed/$type/$idNum'
                            : null);
                        if (url == null) {
                          debugPrint('Play from banner: NO URL for title=${movie.title}, id=${movie.id}');
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('No stream available for this item yet')),
                          );
                          return;
                        }
                        debugPrint('Play from banner: title=${movie.title}, id=${movie.id}, type=$type, url=$url');
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => WebPlayerPage(
                              title: movie.title,
                              url: url,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    _SecondaryButton(
                      icon: Icons.info_outline,
                      label: 'Info',
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => DetailsScreen(movie: movie),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _fallback({bool showSpinner = false}) => Container(
        color: const Color(0xFF1A1A1A),
        alignment: Alignment.center,
        child: showSpinner
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.image, color: Colors.white54, size: 28),
      );
}

class _PrimaryButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  const _PrimaryButton({required this.icon, required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      icon: Icon(icon),
      label: Text(label),
    );
  }

}

class _SecondaryButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  const _SecondaryButton({required this.icon, required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: const BorderSide(color: Colors.white70),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      icon: Icon(icon),
      label: Text(label),
    );
  }
}
