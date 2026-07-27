import 'package:flutter/material.dart';
import 'package:sagemovies/screens/studio_movies_screen.dart';

class StudioBottomBar extends StatelessWidget {
  final Function(String query)? onStudioTap;

  const StudioBottomBar({super.key, this.onStudioTap});

  static const List<Map<String, String>> studios = [
    {'name': 'Vivamax', 'url': 'https://image.tmdb.org/t/p/w92/25oYoXHsfWYlddAzJSBReajN3BM.png', 'query': 'Vivamax'},
    {'name': 'Netflix', 'url': 'https://image.tmdb.org/t/p/w92/pbpMk2JmcoNnQwx5JGpXngfoWtp.jpg', 'query': 'Netflix'},
    {'name': 'Disney+', 'url': 'https://image.tmdb.org/t/p/w92/97yvRBw1GzX7fXprcF80er19ot.jpg', 'query': 'Disney+'},
    {'name': 'Prime Video', 'url': 'https://image.tmdb.org/t/p/w92/pvske1MyAoymrs5bguRfVqYiM9a.jpg', 'query': 'Prime Video'},
    {'name': 'Apple TV+', 'url': 'https://image.tmdb.org/t/p/w92/mcbz1LgtErU9p4UdbZ0rG6RTWHX.jpg', 'query': 'Apple TV+'},
    {'name': 'HBO Max', 'url': 'https://image.tmdb.org/t/p/w92/jbe4gVSfRlbPTdESXhEKpornsfu.jpg', 'query': 'HBO Max'},
    {'name': 'Paramount+', 'url': 'https://image.tmdb.org/t/p/w92/fts6X10Jn4QT0X6ac3udKEn2tJA.jpg', 'query': 'Paramount+'},
    {'name': 'Hulu', 'url': 'https://image.tmdb.org/t/p/w92/bxBlRPEPpMVDc4jMhSrTf2339DW.jpg', 'query': 'Hulu'},
    {'name': 'Warner Bros', 'url': 'https://image.tmdb.org/t/p/w92/zhD3hhtKB5qyv7ZeL4uLpNxgMVU.png', 'query': 'Warner Bros'},
    {'name': 'Marvel', 'url': 'https://image.tmdb.org/t/p/w92/hUzeosd33nzE5MStB42PioTJw15.png', 'query': 'Marvel'},
    {'name': 'Universal', 'url': 'https://image.tmdb.org/t/p/w92/8lvHyhjr8oUKOOy2dKXoALWKdp0.png', 'query': 'Universal'},
    {'name': 'Sony', 'url': 'https://image.tmdb.org/t/p/w92/b9HLm1GDP4j3PF9TZQercD0r8kg.jpg', 'query': 'Sony'},
    {'name': 'A24', 'url': 'https://image.tmdb.org/t/p/w92/u7nsZM0vmBMDpzIy27164AwMjXV.png', 'query': 'A24'},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
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
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => StudioMoviesScreen(
                      studioName: name,
                      logoUrl: url,
                    ),
                  ),
                );
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
