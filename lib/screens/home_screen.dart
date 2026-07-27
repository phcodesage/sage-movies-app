import 'package:flutter/material.dart';
import 'package:sagemovies/services/api_service.dart';
import 'package:sagemovies/services/update_service.dart';
import 'package:sagemovies/models/movie.dart';
import 'package:sagemovies/screens/details_screen.dart';
import 'package:sagemovies/widgets/hero_banner.dart';
import 'package:sagemovies/widgets/section_row.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _scrollController = ScrollController();
  double _elevation = 0;
  
  List<Movie> _trendingMovies = [];
  List<Movie> _actionMovies = [];
  List<Movie> _trendingTv = [];
  List<Movie> _animeList = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      final e = _scrollController.offset > 24 ? 2.0 : 0.0;
      if (e != _elevation) setState(() => _elevation = e);
    });
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        ApiService.fetchMovieCollection(),
        ApiService.fetchMoviesByGenre(28),
        ApiService.fetchTvCollection(),
        ApiService.fetchAnimeCollection(),
      ]);

      if (mounted) {
        setState(() {
          _trendingMovies = results[0];
          _actionMovies = results[1];
          _trendingTv = results[2];
          _animeList = results[3];
          _loading = false;
        });

        // Wireless backend OTA update check
        WidgetsBinding.instance.addPostFrameCallback((_) {
          UpdateService.promptUpdateIfNeeded(context);
        });
      }
    } catch (e) {
      debugPrint('Error loading home data: $e');
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              CircularProgressIndicator(color: Color(0xFFE50914)),
              SizedBox(height: 16),
              Text(
                'Loading Sage Movies...',
                style: TextStyle(color: Colors.white70, letterSpacing: 1),
              ),
            ],
          ),
        ),
      );
    }

    final feature = _trendingMovies.isNotEmpty ? _trendingMovies.first : null;

    return Scaffold(
      backgroundColor: Colors.black,
      body: RefreshIndicator(
        color: const Color(0xFFE50914),
        onRefresh: _loadData,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverAppBar(
              pinned: true,
              backgroundColor: _elevation == 0 ? Colors.transparent : const Color(0xE6000000),
              title: const _BrandTitle(),
            ),
            if (_trendingMovies.isNotEmpty)
              SliverToBoxAdapter(child: HeroBanner(movies: _trendingMovies)),
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_trendingMovies.isNotEmpty)
                    SectionRow(
                      title: 'Trending Movies',
                      movies: _trendingMovies,
                      onTap: (m) => _openDetails(context, m),
                    ),
                  if (_actionMovies.isNotEmpty)
                    SectionRow(
                      title: 'Action Movies',
                      movies: _actionMovies,
                      onTap: (m) => _openDetails(context, m),
                    ),
                  if (_trendingTv.isNotEmpty)
                    SectionRow(
                      title: 'Popular TV Shows',
                      movies: _trendingTv,
                      onTap: (m) => _openDetails(context, m),
                    ),
                  if (_animeList.isNotEmpty)
                    SectionRow(
                      title: 'Anime Collection',
                      movies: _animeList,
                      onTap: (m) => _openDetails(context, m),
                      tall: true,
                    ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openDetails(BuildContext context, Movie movie) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => DetailsScreen(movie: movie)),
    );
  }
}

class _BrandTitle extends StatelessWidget {
  const _BrandTitle();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Text('SAGE', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2)),
        SizedBox(width: 4),
        Text('MOVIES', style: TextStyle(color: Color(0xFFE50914), fontWeight: FontWeight.bold, letterSpacing: 2)),
      ],
    );
  }
}
