import 'package:flutter/material.dart';
import 'package:sagemovies/app_state.dart';
import 'package:sagemovies/models/movie.dart';

class PosterTile extends StatelessWidget {
  final Movie movie;
  final VoidCallback? onTap;
  final bool tall;

  const PosterTile({super.key, required this.movie, this.onTap, this.tall = false});

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(6);
    final aspect = tall ? 2 / 3 : 2 / 3; // same ratio; tall sections can adjust height outside

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
                filterQuality: FilterQuality.low,
                errorBuilder: (context, error, stack) => _fallback(),
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return _fallback(showSpinner: true);
                },
              ),
              _GradientBottom(),
              Positioned(
                right: 6,
                top: 6,
                child: _MyListButton(movieId: movie.id),
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
  final String movieId;
  const _MyListButton({required this.movieId});

  @override
  Widget build(BuildContext context) {
    final app = AppStateProvider.of(context);
    final inList = app.isInMyList(movieId);
    return InkWell(
      onTap: () => app.toggleMyList(movieId),
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
