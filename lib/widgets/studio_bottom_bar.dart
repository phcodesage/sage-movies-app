import 'package:flutter/material.dart';
import 'package:sagemovies/models/movie.dart';
import 'package:sagemovies/screens/details_screen.dart';
import 'package:sagemovies/services/api_service.dart';

class StudioBottomBar extends StatelessWidget {
  final Function(String query)? onStudioTap;

  const StudioBottomBar({super.key, this.onStudioTap});

  static const List<Map<String, String>> studios = [
    {'name': 'Vivamax', 'url': 'https://image.tmdb.org/t/p/w92/149142.png', 'query': 'Vivamax'},
    {'name': 'Netflix', 'url': 'https://image.tmdb.org/t/p/w92/wwemzKWXHqRERyuR2VvM1yA4225.png', 'query': 'Netflix'},
    {'name': 'Disney+', 'url': 'https://image.tmdb.org/t/p/w92/7xOCo2g1u4n6p425d0xQ.png', 'query': 'Disney+'},
    {'name': 'Prime Video', 'url': 'https://image.tmdb.org/t/p/w92/if1Q8Tewh688f28j5t66u2j3441.png', 'query': 'Prime Video'},
    {'name': 'Apple TV+', 'url': 'https://image.tmdb.org/t/p/w92/6vB2F9c4e0p9G6j96j40j4.png', 'query': 'Apple TV+'},
    {'name': 'HBO Max', 'url': 'https://image.tmdb.org/t/p/w92/1DSpQ9G6537756f4d1e2.png', 'query': 'HBO Max'},
    {'name': 'Paramount+', 'url': 'https://image.tmdb.org/t/p/w92/8342478f2441.png', 'query': 'Paramount+'},
    {'name': 'Hulu', 'url': 'https://image.tmdb.org/t/p/w92/pqUtCleNUiTLLGsWyR62C92W67j.png', 'query': 'Hulu'},
    {'name': 'Warner Bros', 'url': 'https://upload.wikimedia.org/wikipedia/commons/thumb/6/64/Warner_Bros_logo.svg/512px-Warner_Bros_logo.svg.png', 'query': 'Warner Bros'},
    {'name': 'Marvel', 'url': 'https://upload.wikimedia.org/wikipedia/commons/thumb/7/71/Marvel-Studios-1-1.svg/512px-Marvel-Studios-1-1.svg.png', 'query': 'Marvel'},
    {'name': 'Universal', 'url': 'https://upload.wikimedia.org/wikipedia/commons/thumb/5/52/Universal_Pictures_logo.svg/512px-Universal_Pictures_logo.svg.png', 'query': 'Universal'},
    {'name': 'Sony', 'url': 'https://upload.wikimedia.org/wikipedia/commons/thumb/c/ca/Columbia_Pictures_logo.svg/512px-Columbia_Pictures_logo.svg.png', 'query': 'Sony'},
    {'name': 'A24', 'url': 'https://upload.wikimedia.org/wikipedia/commons/thumb/7/7b/A24_logo.svg/512px-A24_logo.svg.png', 'query': 'A24'},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: const Color(0xFF141419).withOpacity(0.95),
        border: const Border(
          top: BorderSide(color: Colors.white10, width: 1),
        ),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: studios.length,
        itemBuilder: (context, index) {
          final item = studios[index];
          final name = item['name']!;
          final url = item['url']!;
          final query = item['query']!;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () {
                if (onStudioTap != null) {
                  onStudioTap!(query);
                }
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E24),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.network(
                        url,
                        width: 22,
                        height: 22,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stack) =>
                            const Icon(Icons.movie, size: 16, color: Color(0xFFE50914)),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
