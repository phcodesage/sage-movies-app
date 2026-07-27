import 'package:flutter/material.dart';
import 'package:sagemovies/app_state.dart';
import 'package:sagemovies/models/movie.dart';
import 'package:sagemovies/screens/studio_movies_screen.dart';
import 'package:sagemovies/services/toast_service.dart';

class PosterTile extends StatelessWidget {
  final Movie movie;
  final VoidCallback? onTap;
  final bool tall;
  final String? studioName;

  const PosterTile({
    super.key,
    required this.movie,
    this.onTap,
    this.tall = false,
    this.studioName,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(6);
    final aspect = tall ? 2 / 3 : 2 / 3;
    final badgeLabel = (studioName != null && studioName!.trim().isNotEmpty)
        ? studioName!.trim().toUpperCase()
        : 'STUDIO';

    return GestureDetector(
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: aspect,
        child: ClipRRect(
          borderRadius: radius,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                movie.posterUrl,
                fit: BoxFit.cover,
                cacheWidth: 300,
                filterQuality: FilterQuality.low,
                errorBuilder: (context, error, stack) => _fallback(),
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return _fallback(showSpinner: true);
                },
              ),
              _GradientBottom(),
              if (movie.rating > 0)
                Positioned(
                  left: 6,
                  bottom: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.75),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 10),
                        const SizedBox(width: 2),
                        Text(
                          movie.rating.toStringAsFixed(1),
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              Positioned(
                left: 6,
                top: 6,
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => StudioMoviesScreen(
                          studioName: badgeLabel,
                          logoUrl: '',
                        ),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(3),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE50914),
                      borderRadius: BorderRadius.circular(3),
                      boxShadow: const [
                        BoxShadow(color: Colors.black45, blurRadius: 4),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.movie_creation_outlined, color: Colors.white, size: 9),
                        const SizedBox(width: 3),
                        Text(
                          badgeLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 6,
                top: 6,
                child: _MyListButton(movie: movie),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fallback({bool showSpinner = false}) => Container(
        color: const Color(0xFF222222),
        alignment: Alignment.center,
        child: showSpinner
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.movie, color: Colors.white54, size: 24),
      );
}

class _GradientBottom extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.black54, Colors.transparent],
        ),
      ),
    );
  }
}

class _MyListButton extends StatelessWidget {
  final Movie movie;
  const _MyListButton({required this.movie});

  @override
  Widget build(BuildContext context) {
    final app = AppStateProvider.of(context);
    final inList = app.isInMyList(movie.id);
    return InkWell(
      onTap: () {
        final added = app.toggleMyList(movie);
        if (added) {
          ToastService.showSuccess(context, '"${movie.title}" added to My List');
        } else {
          ToastService.showInfo(context, '"${movie.title}" removed from My List');
        }
      },
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(inList ? Icons.check : Icons.add, size: 16, color: Colors.white),
      ),
    );
  }
}
