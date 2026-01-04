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
    final height = tall ? 220.0 : 180.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
          child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        ),
        SizedBox(
          height: height,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: movies.length,
separatorBuilder: (context, _) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final m = movies[i];
              return SizedBox(
                width: height * (2 / 3),
                child: PosterTile(
                  movie: m,
                  tall: tall,
                  onTap: () => onTap(m),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
