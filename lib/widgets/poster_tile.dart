import 'package:flutter/material.dart';
import 'package:sagemovies/app_state.dart';
import 'package:sagemovies/data/studio_catalog.dart';
import 'package:sagemovies/models/movie.dart';
import 'package:sagemovies/screens/studio_movies_screen.dart';
import 'package:sagemovies/services/studio_service.dart';
import 'package:sagemovies/services/toast_service.dart';
import 'package:sagemovies/widgets/safe_cached_image.dart';

class PosterTile extends StatelessWidget {
  final Movie movie;
  final VoidCallback? onTap;
  final bool tall;

  const PosterTile({
    super.key,
    required this.movie,
    this.onTap,
    this.tall = false,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(6);
    final aspect = tall ? 2 / 3 : 2 / 3;

    return GestureDetector(
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: aspect,
        child: ClipRRect(
          borderRadius: radius,
          child: Stack(
            fit: StackFit.expand,
            children: [
              SafeCachedImage(
                imageUrl: movie.posterUrl,
                fit: BoxFit.cover,
                memCacheWidth: 300,
                placeholder: (context, url) => _fallback(showSpinner: true),
                errorWidget: (context, url, error) => _fallback(),
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
                child: _StudioBadge(movie: movie),
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

/// Shows the title's real studio, or nothing at all.
///
/// The list endpoints carry no studio data, so this resolves lazily per title
/// via [StudioService]. It renders nothing until resolved and nothing when
/// unresolved — the old placeholder read the literal word "STUDIO" on every
/// poster and pushed a garbage search when tapped.
class _StudioBadge extends StatefulWidget {
  final Movie movie;
  const _StudioBadge({required this.movie});

  @override
  State<_StudioBadge> createState() => _StudioBadgeState();
}

class _StudioBadgeState extends State<_StudioBadge> {
  StudioEntry? _entry;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  @override
  void didUpdateWidget(covariant _StudioBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    // These tiles are recycled by position: the home rows render cached titles
    // first and swap in live ones at the same indices. Without this the badge
    // keeps showing the previous movie's studio.
    if (oldWidget.movie.id != widget.movie.id) {
      _entry = null;
      _resolve();
    }
  }

  void _resolve() {
    final movie = widget.movie;
    _entry = StudioService.peek(movie);
    if (_entry != null || StudioService.isResolved(movie)) return;

    StudioService.resolve(movie).then((entry) {
      // The tile may have been recycled again while the request was in flight.
      if (!mounted || widget.movie.id != movie.id) return;
      if (entry != null) setState(() => _entry = entry);
    });
  }

  @override
  Widget build(BuildContext context) {
    final entry = _entry;
    if (entry == null) return const SizedBox.shrink();

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => StudioMoviesScreen(
              studioName: entry.displayName,
              logoAsset: entry.asset,
              logoUrl: '',
              studioId: entry.companyId?.toString(),
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(3),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2.5),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.78),
          borderRadius: BorderRadius.circular(3),
          boxShadow: const [
            BoxShadow(color: Colors.black45, blurRadius: 4),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              entry.asset,
              width: 14,
              height: 14,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stack) =>
                  const Icon(Icons.movie_creation_outlined, color: Colors.white, size: 9),
            ),
            const SizedBox(width: 3),
            Text(
              entry.displayName.toUpperCase(),
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
    );
  }
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
