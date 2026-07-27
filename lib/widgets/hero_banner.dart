import 'package:flutter/material.dart';
import 'package:sagemovies/models/movie.dart';
import 'package:sagemovies/screens/details_screen.dart';
import 'package:sagemovies/screens/player_screen.dart';

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sagemovies/models/movie.dart';
import 'package:sagemovies/screens/details_screen.dart';
import 'package:sagemovies/screens/player_screen.dart';

class HeroBanner extends StatefulWidget {
  final List<Movie> movies;
  final Movie? movie;

  const HeroBanner({
    super.key,
    this.movies = const [],
    this.movie,
  });

  @override
  State<HeroBanner> createState() => _HeroBannerState();
}

class _HeroBannerState extends State<HeroBanner> {
  late PageController _pageController;
  Timer? _timer;
  int _currentIndex = 0;

  List<Movie> get _bannerMovies {
    if (widget.movies.isNotEmpty) {
      return widget.movies.take(10).toList();
    }
    if (widget.movie != null) {
      return [widget.movie!];
    }
    return [];
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    if (_bannerMovies.length > 1) {
      _timer = Timer.periodic(const Duration(seconds: 5), (_) {
        if (!mounted) return;
        final nextIndex = (_currentIndex + 1) % _bannerMovies.length;
        _pageController.animateToPage(
          nextIndex,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      });
    }
  }

  @override
  void didUpdateWidget(covariant HeroBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.movies != widget.movies || oldWidget.movie != widget.movie) {
      _startTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final list = _bannerMovies;
    if (list.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 420,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: list.length,
            onPageChanged: (index) {
              setState(() => _currentIndex = index);
            },
            itemBuilder: (context, index) {
              final movie = list[index];
              return Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    movie.backdropUrl.isNotEmpty ? movie.backdropUrl : movie.posterUrl,
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
                        stops: [0.0, 0.6, 1.0],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 24,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          movie.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                shadows: const [
                                  Shadow(blurRadius: 8, color: Colors.black, offset: Offset(0, 2)),
                                ],
                              ),
                        ),
                        if (movie.overview.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            movie.overview,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            _PrimaryButton(
                              icon: Icons.play_arrow,
                              label: 'Play',
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => DetailsScreen(movie: movie),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 10),
                            _SecondaryButton(
                              icon: Icons.info_outline,
                              label: 'More Info',
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
              );
            },
          ),
          if (list.length > 1)
            Positioned(
              right: 16,
              bottom: 24,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  list.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    width: _currentIndex == i ? 16 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: _currentIndex == i ? const Color(0xFFE50914) : Colors.white38,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
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
