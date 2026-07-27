import 'package:flutter/material.dart';
import 'package:sagemovies/app_state.dart';
import 'package:sagemovies/screens/downloads_screen.dart';
import 'package:sagemovies/screens/home_screen.dart';
import 'package:sagemovies/screens/my_list_screen.dart';
import 'package:sagemovies/screens/search_screen.dart';
import 'package:sagemovies/theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
      bottomNavigationBar: BottomNavigationBar(
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
    );
  }
}
