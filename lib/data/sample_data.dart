import 'package:sagemovies/models/movie.dart';

// Using picsum.photos for placeholder images.
// In the future, replace these with your API image URLs.

const tmdb = 'https://image.tmdb.org/t/p';

const List<Movie> trending = [
  Movie(
    id: 't1',
    title: 'Abyss',
    posterUrl: '$tmdb/w342/foyiQu23zq4WhmffnQkFiNAvqcJ.jpg',
    backdropUrl: '$tmdb/w1280/foyiQu23zq4WhmffnQkFiNAvqcJ.jpg',
    overview: 'A thrilling descent into the unknown.',
    rating: 7.9,
  ),
  Movie(
    id: 't2',
    title: 'Afterburn',
    posterUrl: '$tmdb/w342/xR0IhVBjbNU34b8erhJCgRbjXo3.jpg',
    backdropUrl: '$tmdb/w1280/xR0IhVBjbNU34b8erhJCgRbjXo3.jpg',
    overview: 'High-octane action set after the storm.',
    rating: 7.2,
  ),
  Movie(
    id: 't3',
    title: 'Black Phone 2',
    posterUrl: '$tmdb/w342/xUWUODKPIilQoFUzjHM6wKJkP3Y.jpg',
    backdropUrl: '$tmdb/w1280/xUWUODKPIilQoFUzjHM6wKJkP3Y.jpg',
    overview: 'The line is open again.',
    rating: 6.8,
  ),
  Movie(
    id: 't4',
    title: 'Chainsaw Man - Reze Arc',
    posterUrl: '$tmdb/w342/xdzLBZjCVSEsic7m7nJc4jNJZVW.jpg',
    backdropUrl: '$tmdb/w1280/xdzLBZjCVSEsic7m7nJc4jNJZVW.jpg',
    overview: 'The saga continues.',
    rating: 7.0,
  ),
  Movie(
    id: 't5',
    title: 'War of the Worlds',
    posterUrl: '$tmdb/w342/yvirUYrva23IudARHn3mMGVxWqM.jpg',
    backdropUrl: '$tmdb/w1280/yvirUYrva23IudARHn3mMGVxWqM.jpg',
    overview: 'Humanity fights back.',
    rating: 6.9,
  ),
];

const List<Movie> popular = [
  Movie(
    id: 'p1',
    title: 'Demon Slayer: Infinity Castle',
    posterUrl: '$tmdb/w342/fWVSwgjpT2D78VUh6X8UBd2rorW.jpg',
    backdropUrl: '$tmdb/w1280/fWVSwgjpT2D78VUh6X8UBd2rorW.jpg',
    overview: 'The climactic battle begins.',
    rating: 7.1,
  ),
  Movie(
    id: 'p2',
    title: 'Martin',
    posterUrl: '$tmdb/w342/bYe2ZjUhb4Kje0BpWE6kN34u2hv.jpg',
    backdropUrl: '$tmdb/w1280/bYe2ZjUhb4Kje0BpWE6kN34u2hv.jpg',
    overview: 'A tale of choices.',
    rating: 6.5,
  ),
  Movie(
    id: 'p3',
    title: 'Captain Hook - The Cursed Tides',
    posterUrl: '$tmdb/w342/bcP7FtskwsNp1ikpMQJzDPjofP5.jpg',
    backdropUrl: '$tmdb/w1280/bcP7FtskwsNp1ikpMQJzDPjofP5.jpg',
    overview: 'Pirate legend reborn.',
    rating: 7.3,
  ),
  Movie(
    id: 'p4',
    title: 'Hunting Grounds',
    posterUrl: '$tmdb/w342/cgZjpqRQt9sk6XMCwZ3B1NPAaoy.jpg',
    backdropUrl: '$tmdb/w1280/cgZjpqRQt9sk6XMCwZ3B1NPAaoy.jpg',
    overview: 'The hunter becomes hunted.',
    rating: 6.7,
  ),
  Movie(
    id: 'p5',
    title: 'Our Fault',
    posterUrl: '$tmdb/w342/yzqHt4m1SeY9FbPrfZ0C2Hi9x1s.jpg',
    backdropUrl: '$tmdb/w1280/yzqHt4m1SeY9FbPrfZ0C2Hi9x1s.jpg',
    overview: 'Love and consequences.',
    rating: 6.8,
  ),
];

const List<Movie> originals = [
  Movie(
    id: '138843',
    title: 'The Conjuring',
    posterUrl: '$tmdb/w342/7JzOmJ1fIU43I3gLHYsY8UzNzjG.jpg',
    backdropUrl: '$tmdb/w1280/7JzOmJ1fIU43I3gLHYsY8UzNzjG.jpg',
    overview: 'The Warrens face their final evil.',
    rating: 7.6,
    playUrl: 'https://vidsrc.cc/v2/embed/movie/138843',
  ),
  Movie(
    id: '354912',
    title: 'Coco',
    posterUrl: '$tmdb/w342/6Ryitt95xrO8KXuqRGm1fUuNwqF.jpg',
    backdropUrl: '$tmdb/w1280/6Ryitt95xrO8KXuqRGm1fUuNwqF.jpg',
    overview: 'A vibrant journey into family and music.',
    rating: 7.9,
    playUrl: 'https://vidsrc.cc/v2/embed/movie/354912',
  ),
  Movie(
    id: 'o3',
    title: 'The Rats: A Witcher Tale',
    posterUrl: '$tmdb/w342/5Gr4amaB1xxeYAEMOdrVutaWwgz.jpg',
    backdropUrl: '$tmdb/w1280/5Gr4amaB1xxeYAEMOdrVutaWwgz.jpg',
    overview: 'Gritty fantasy adventure.',
    rating: 7.2,
  ),
  Movie(
    id: 'o4',
    title: 'KPop Demon Hunters',
    posterUrl: '$tmdb/w342/zT7Lhw3BhJbMkRqm9Zlx2YGMsY0.jpg',
    backdropUrl: '$tmdb/w1280/zT7Lhw3BhJbMkRqm9Zlx2YGMsY0.jpg',
    overview: 'Idols vs demons.',
    rating: 7.0,
  ),
  Movie(
    id: '7451',
    title: 'xXx',
    posterUrl: '$tmdb/w342/xeEw3eLeSFmJgXZzmF2Efww0q3s.jpg',
    backdropUrl: '$tmdb/w1280/xeEw3eLeSFmJgXZzmF2Efww0q3s.jpg',
    overview: 'Extreme action icon.',
    rating: 7.5,
    playUrl: 'https://vidsrc.cc/v2/embed/movie/7451',
  ),
];

List<Movie> allMovies() => [
      ...trending,
      ...popular,
      ...originals,
    ];

Movie? findMovieById(String id) {
  try {
    return allMovies().firstWhere((m) => m.id == id);
  } catch (_) {
    return null;
  }
}
