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
              String? derivedStudio;
              if (title.contains('Disney+')) derivedStudio = 'Disney+';
              else if (title.contains('Netflix')) derivedStudio = 'Netflix';
              else if (title.contains('Prime Video')) derivedStudio = 'Prime Video';
              else if (title.contains('Apple TV+')) derivedStudio = 'Apple TV+';
              else if (title.contains('HBO')) derivedStudio = 'HBO Max';
              else if (title.contains('Paramount')) derivedStudio = 'Paramount+';
              else if (title.contains('Vivamax')) derivedStudio = 'Vivamax';
              else if (title.contains('Hulu')) derivedStudio = 'Hulu';
              else if (title.contains('Warner')) derivedStudio = 'Warner Bros';
              else if (title.contains('Marvel')) derivedStudio = 'Marvel';
              else if (title.contains('Universal')) derivedStudio = 'Universal';
              else if (title.contains('Sony')) derivedStudio = 'Sony';
              else if (title.contains('A24')) derivedStudio = 'A24';

              return SizedBox(
                width: itemWidth,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: PosterTile(
                        movie: m,
                        tall: tall,
                        studioName: derivedStudio,
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
