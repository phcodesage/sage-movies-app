import 'package:flutter/material.dart';
import 'package:sagemovies/services/api_service.dart';
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
  
  List<Movie> _trending = [];
  List<Movie> _popular = [];
  List<Movie> _originals = [];
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
      final trending = await ApiService.fetchTrending();
      final popular = await ApiService.fetchMovieCollection(); // Using collection as popular for now
      final originals = await ApiService.fetchAnimeCollection(); // Using anime as originals for variety

      if (mounted) {
        setState(() {
          _trending = trending;
          _popular = popular;
          _originals = originals;
          _loading = false;
        });
      }
    } catch (e) {
      print('Error loading home data: $e');
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
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final feature = _trending.isNotEmpty ? _trending.first : null;

    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        SliverAppBar(
          pinned: true,
          backgroundColor: _elevation == 0 ? Colors.transparent : const Color(0xE6000000),
          title: const _BrandTitle(),
        ),
        if (feature != null)
          SliverToBoxAdapter(child: HeroBanner(movie: feature)),
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_trending.isNotEmpty)
                SectionRow(
                  title: 'Trending Now',
                  movies: _trending,
                  onTap: (m) => _openDetails(context, m),
                ),
              if (_popular.isNotEmpty)
                SectionRow(
                  title: 'Popular on SageMovies',
                  movies: _popular,
                  onTap: (m) => _openDetails(context, m),
                ),
              if (_originals.isNotEmpty)
                SectionRow(
                  title: 'Anime Collection',
                  movies: _originals,
                  onTap: (m) => _openDetails(context, m),
                  tall: true,
                ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ],
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
