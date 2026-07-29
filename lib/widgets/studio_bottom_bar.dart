import 'package:flutter/material.dart';
import 'package:sagemovies/data/studio_catalog.dart';
import 'package:sagemovies/screens/studio_movies_screen.dart';

class StudioBottomBar extends StatelessWidget {
  const StudioBottomBar({super.key});

  @override
  Widget build(BuildContext context) {
    final entries = StudioCatalog.entries;

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
        itemCount: entries.length,
        itemBuilder: (context, index) {
          final entry = entries[index];

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => StudioMoviesScreen(
                      studioName: entry.displayName,
                      logoAsset: entry.asset,
                      logoUrl: '',
                      // Null falls back to a title search, which beats sending a
                      // wrong id to the company discover endpoint.
                      studioId: entry.companyId?.toString(),
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
                      // Bundled asset: renders instantly and survives offline.
                      child: Image.asset(
                        entry.asset,
                        width: 22,
                        height: 22,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stack) =>
                            const Icon(Icons.movie, size: 16, color: Color(0xFFE50914)),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      entry.displayName,
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
