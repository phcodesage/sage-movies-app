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
    final movies = app.myList;

    return Scaffold(
      appBar: AppBar(
        title: Text('My List (${movies.length})'),
      ),
      body: movies.isEmpty
          ? const _EmptyState()
          : Padding(
              padding: const EdgeInsets.all(12),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 8,
                  childAspectRatio: 0.55,
                ),
                itemCount: movies.length,
                itemBuilder: (context, i) {
                  final movie = movies[i];
                  return GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => DetailsScreen(movie: movie),
                        ),
                      );
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: PosterTile(movie: movie)),
                        const SizedBox(height: 4),
                        Text(
                          movie.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11, color: Colors.white70),
                        ),
                      ],
                    ),
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
