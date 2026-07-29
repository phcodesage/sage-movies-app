import 'package:flutter/material.dart';
import 'package:sagemovies/models/movie.dart';
import 'package:sagemovies/widgets/poster_tile.dart';

class SectionRow extends StatelessWidget {
  final String title;
  final List<Movie> movies;
  final bool tall;
  final void Function(Movie) onTap;

  const SectionRow({
    super.key,
    required this.title,
    required this.movies,
    required this.onTap,
    this.tall = false,
  });

  @override
  Widget build(BuildContext context) {
    final cardHeight = tall ? 250.0 : 210.0;
    final itemWidth = tall ? 140.0 : 120.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Colors.white),
          ),
        ),
        SizedBox(
          height: cardHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: movies.length,
            separatorBuilder: (context, _) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              final m = movies[i];

              return SizedBox(
                width: itemWidth,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: PosterTile(
                        movie: m,
                        tall: tall,
                        onTap: () => onTap(m),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      m.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white70,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
