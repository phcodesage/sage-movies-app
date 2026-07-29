import 'package:flutter/material.dart';
import 'package:sagemovies/app_state.dart';
import 'package:sagemovies/screens/downloads_screen.dart';
import 'package:sagemovies/screens/home_screen.dart';
import 'package:sagemovies/screens/my_list_screen.dart';
import 'package:sagemovies/screens/search_screen.dart';
import 'package:sagemovies/services/download_service.dart';
import 'package:sagemovies/services/preload_service.dart';
import 'package:sagemovies/services/studio_service.dart';
import 'package:sagemovies/theme.dart';
import 'package:sagemovies/widgets/studio_bottom_bar.dart';

import 'package:unity_ads_plugin/unity_ads_plugin.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PreloadService.init();
  await StudioService.init();
  await DownloadService.init();
  UnityAds.init(
    gameId: '800108318',
    testMode: false,
    onComplete: () {
      debugPrint('Unity Ads Initialized Successfully');
      UnityAds.load(placementId: 'Interstitial_Android');
    },
    onFailed: (error, message) => debugPrint('Unity Ads Init Failed: $error $message'),
  );
  runApp(AppStateProvider(child: const SageMoviesApp()));
}

class SageMoviesApp extends StatelessWidget {
  const SageMoviesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SageMovies',
      debugShowCheckedModeBanner: false,
      theme: buildDarkTheme(),
      home: const _MainScaffold(),
    );
  }
}

class _MainScaffold extends StatefulWidget {
  const _MainScaffold();

  @override
  State<_MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<_MainScaffold> {
  int _index = 0;

  final _pages = const [
    HomeScreen(),
    SearchScreen(),
    DownloadsScreen(),
    MyListScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: _pages,
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // The bar pushes StudioMoviesScreen itself; switching tabs here as
          // well used to strand the user on Search when they popped back.
          const StudioBottomBar(),
          BottomNavigationBar(
            currentIndex: _index,
            onTap: (i) => setState(() => _index = i),
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
              BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
              BottomNavigationBarItem(icon: Icon(Icons.download), label: 'Downloads'),
              BottomNavigationBarItem(icon: Icon(Icons.list), label: 'My List'),
            ],
          ),
        ],
      ),
    );
  }
}
