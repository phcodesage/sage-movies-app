class Movie {
  final String id;
  final String title;
  final String posterUrl;
  final String backdropUrl;
  final String overview;
  final double rating;
  final String mediaType;
  final String? releaseDate;
  final String? playUrl; // Optional explicit embed URL

  const Movie({
    required this.id,
    required this.title,
    required this.posterUrl,
    required this.backdropUrl,
    required this.overview,
    required this.rating,
    this.mediaType = 'movie',
    this.releaseDate,
    this.playUrl,
  });

  factory Movie.fromJson(Map<String, dynamic> json) {
    final title = json['title'] ?? json['name'] ?? 'Unknown';
    final posterPath = json['poster_path'] ?? '';
    final backdropPath = json['backdrop_path'] ?? '';
    final overview = json['overview'] ?? '';
    final rating = (json['vote_average'] ?? 0.0).toDouble();
    final mediaType = json['media_type'] ?? 'movie';
    final releaseDate = json['release_date'] ?? json['first_air_date'];

    final posterUrl = posterPath.isNotEmpty
        ? 'https://image.tmdb.org/t/p/w500$posterPath'
        : '';
    final backdropUrl = backdropPath.isNotEmpty
        ? 'https://image.tmdb.org/t/p/w1280$backdropPath'
        : '';

    return Movie(
      id: (json['id'] ?? 0).toString(),
      title: title,
      posterUrl: posterUrl,
      backdropUrl: backdropUrl,
      overview: overview,
      rating: rating,
      mediaType: mediaType,
      releaseDate: releaseDate,
      playUrl: json['embed_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': int.tryParse(id) ?? 0,
      'title': title,
      'poster_path': posterUrl,
      'backdrop_path': backdropUrl,
      'overview': overview,
      'vote_average': rating,
      'media_type': mediaType,
      'release_date': releaseDate,
      'embed_url': playUrl,
    };
  }
}
