import 'package:flutter/material.dart';
import 'package:sagemovies/models/movie.dart';
import 'package:sagemovies/screens/details_screen.dart';
import 'package:sagemovies/services/api_service.dart';
import 'package:sagemovies/services/preload_service.dart';
import 'package:sagemovies/widgets/poster_tile.dart';

class StudioMoviesScreen extends StatefulWidget {
  final String studioName;
  final String logoUrl;
  final String? studioId;

  const StudioMoviesScreen({
    super.key,
    required this.studioName,
    required this.logoUrl,
    this.studioId,
  });

  @override
  State<StudioMoviesScreen> createState() => _StudioMoviesScreenState();
}

class _StudioMoviesScreenState extends State<StudioMoviesScreen> {
  List<Movie> _movies = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    if (widget.studioId != null) {
      final cached = PreloadService.getCollection('cached_studio_${widget.studioId}');
      if (cached.isNotEmpty) {
        _movies = cached;
        _loading = false;
      }
    }
    _loadStudioMovies();
  }

  Future<void> _loadStudioMovies() async {
    try {
      List<Movie> results = [];
      if (widget.studioId != null) {
        final idNum = int.tryParse(widget.studioId!);
        if (idNum != null) {
          results = await ApiService.fetchMoviesByStudio(idNum);
        }
      }
      if (results.isEmpty && _movies.isEmpty) {
        results = await ApiService.search(widget.studioName);
      }

      if (mounted && results.isNotEmpty) {
        setState(() {
          _movies = results.where((m) => m.posterUrl.isNotEmpty).toList();
          _loading = false;
        });
      } else if (mounted) {
        setState(() => _loading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _openDetails(Movie movie) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => DetailsScreen(movie: movie)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F11),
      appBar: AppBar(
        backgroundColor: const Color(0xFF141419),
        elevation: 0,
        title: Row(
          children: [
            if (widget.logoUrl.isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.network(
                  widget.logoUrl,
                  width: 24,
                  height: 24,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stack) =>
                      const Icon(Icons.movie_filter, color: Color(0xFFE50914), size: 20),
                ),
              ),
              const SizedBox(width: 10),
            ],
            Text(
              widget.studioName.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFE50914)),
            )
          : _movies.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.movie_outlined, size: 64, color: Colors.white24),
                      const SizedBox(height: 16),
                      Text(
                        'No titles found for ${widget.studioName}',
                        style: const TextStyle(color: Colors.white54, fontSize: 14),
                      ),
                    ],
                  ),
                )
              : CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                        child: Row(
                          children: [
                            Container(
                              width: 4,
                              height: 18,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE50914),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'CATALOG (${_movies.length} TITLES)',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                      sliver: SliverGrid(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.55,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final movie = _movies[index];
                            return GestureDetector(
                              onTap: () => _openDetails(movie),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: PosterTile(
                                      movie: movie,
                                      studioName: widget.studioName,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    movie.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      height: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                          childCount: _movies.length,
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
