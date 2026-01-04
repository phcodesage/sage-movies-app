import 'package:flutter/material.dart';
import 'package:sagemovies/app_state.dart';
import 'package:sagemovies/models/movie.dart';
import 'package:sagemovies/screens/details_screen.dart';
import 'package:sagemovies/widgets/poster_tile.dart';

class MyListScreen extends StatelessWidget {
  const MyListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppStateProvider.of(context);
    final ids = app.myListIds.toList();

    return Scaffold(
      appBar: AppBar(title: const Text('My List')),
      body: ids.isEmpty
          ? const _EmptyState()
          : Padding(
              padding: const EdgeInsets.all(12),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 2 / 3,
                ),
                itemCount: ids.length,
                itemBuilder: (context, i) {
                  final movie = Movie(
                    id: ids[i],
                    title: 'Saved Movie',
                    posterUrl: '',
                    backdropUrl: '',
                    overview: '',
                    rating: 0.0,
                  );
                  return GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => DetailsScreen(movie: movie),
                        ),
                      );
                    },
                    child: PosterTile(movie: movie),
                  );
                },
              ),
            ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.list_alt, size: 48, color: Colors.white38),
          SizedBox(height: 8),
          Text('No items in My List', style: TextStyle(color: Colors.white70)),
          SizedBox(height: 4),
          Text('Add movies and shows to see them here', style: TextStyle(color: Colors.white54, fontSize: 12)),
        ],
      ),
    );
  }
}
