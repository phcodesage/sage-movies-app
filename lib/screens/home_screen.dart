import 'package:flutter/material.dart';
import 'package:sagemovies/services/api_service.dart';
import 'package:sagemovies/services/preload_service.dart';
import 'package:sagemovies/services/update_service.dart';
import 'package:sagemovies/models/movie.dart';
import 'package:sagemovies/screens/details_screen.dart';
import 'package:sagemovies/widgets/hero_banner.dart';
import 'package:sagemovies/widgets/section_row.dart';
import 'package:unity_ads_plugin/unity_ads_plugin.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _scrollController = ScrollController();
  double _elevation = 0;
  
  late List<Movie> _trendingMovies;
  late List<Movie> _actionMovies;
  late List<Movie> _trendingTv;
  late List<Movie> _animeList;
  bool _loading = false;
  bool _isBannerAdLoaded = false;

  @override
  void initState() {
    super.initState();
    // Instantly load preloaded dataset so app displays immediately with 0 delay
    _trendingMovies = PreloadService.getTrendingMovies();
    _actionMovies = PreloadService.getActionMovies();
    _trendingTv = PreloadService.getTrendingTv();
    _animeList = PreloadService.getAnimeCollection();

    _scrollController.addListener(() {
      final e = _scrollController.offset > 24 ? 2.0 : 0.0;
      if (e != _elevation) setState(() => _elevation = e);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      UpdateService.startPeriodicUpdateCheck(context);
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
          if (results[0].isNotEmpty) _trendingMovies = results[0];
          if (results[1].isNotEmpty) _actionMovies = results[1];
          if (results[2].isNotEmpty) _trendingTv = results[2];
          if (results[3].isNotEmpty) _animeList = results[3];
          _loading = false;
        });

        // Wireless backend OTA update check & image disk precaching
        WidgetsBinding.instance.addPostFrameCallback((_) {
          PreloadService.precacheMovieImages(context, _trendingMovies);
          PreloadService.precacheMovieImages(context, _actionMovies);
          PreloadService.precacheMovieImages(context, _trendingTv);
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
    if (_loading && _trendingMovies.isEmpty) {
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
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _isBannerAdLoaded
          ? SafeArea(
              child: SizedBox(
                height: 50,
                child: UnityBannerAd(
                  placementId: 'Banner_Android',
                  onLoad: (placementId) {
                    if (mounted && !_isBannerAdLoaded) {
                      setState(() => _isBannerAdLoaded = true);
                    }
                  },
                  onFailed: (placementId, error, message) {
                    if (mounted && _isBannerAdLoaded) {
                      setState(() => _isBannerAdLoaded = false);
                    }
                  },
                ),
              ),
            )
          : Stack(
              children: [
                SizedBox(
                  height: 1,
                  child: UnityBannerAd(
                    placementId: 'Banner_Android',
                    onLoad: (placementId) {
                      if (mounted) setState(() => _isBannerAdLoaded = true);
                    },
                    onFailed: (placementId, error, message) {
                      if (mounted && _isBannerAdLoaded) {
                        setState(() => _isBannerAdLoaded = false);
                      }
                    },
                  ),
                ),
              ],
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
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text('SAGE', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2)),
            SizedBox(width: 4),
            Text('MOVIES', style: TextStyle(color: Color(0xFFE50914), fontWeight: FontWeight.bold, letterSpacing: 2)),
          ],
        ),
        ValueListenableBuilder<AppVersionInfo?>(
          valueListenable: UpdateService.availableUpdate,
          builder: (context, updateInfo, child) {
            if (updateInfo == null) return const SizedBox.shrink();
            return InkWell(
              onTap: () => UpdateService.showUpdateDialog(context, updateInfo),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE50914),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(color: Color(0x66E50914), blurRadius: 8, spreadRadius: 1),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.system_update_rounded, color: Colors.white, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      'UPDATE ${updateInfo.latestVersion}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
