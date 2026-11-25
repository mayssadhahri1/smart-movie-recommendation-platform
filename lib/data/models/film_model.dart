class FilmModel {
  final int tmdbId;
  final int? filmId;              // ✅ NOUVEAU
  final bool videoDisponible;     // ✅ NOUVEAU
  final String titre;
  final String synopsis;
  final String note;
  final String duree;
  final String dateSortie;
  final String? posterUrl;
  final String? backdropUrl;
  final List<String> genres;
  final String? trailerUrl;
  final String? raison;

  FilmModel({
    required this.tmdbId,
    this.filmId,
    this.videoDisponible = false,
    required this.titre,
    required this.synopsis,
    required this.note,
    required this.duree,
    required this.dateSortie,
    this.posterUrl,
    this.backdropUrl,
    required this.genres,
    this.trailerUrl,
    this.raison,
  });

  static String _asString(dynamic value, [String fallback = '']) {
    if (value == null) return fallback;
    return value.toString();
  }

  static int _asInt(dynamic value, [int fallback = 0]) {
    if (value == null) return fallback;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  factory FilmModel.fromJson(Map<String, dynamic> json) {
    return FilmModel(
      tmdbId: _asInt(json['tmdbId']),
      filmId: json['filmId'] != null ? _asInt(json['filmId']) : null,
      videoDisponible: json['videoDisponible'] == true,
      titre: _asString(json['titre']),
      synopsis: _asString(json['synopsis']),
      note: _asString(json['note'], '0'),
      duree: _asString(json['duree']),
      dateSortie: _asString(json['dateSortie']),
      posterUrl: json['posterUrl'] as String?,
      backdropUrl: json['backdropUrl'] as String?,
      genres: json['genres'] != null
          ? List<String>.from(
          (json['genres'] as List).map((g) => g.toString()))
          : [],
      trailerUrl: json['trailerUrl'] as String?,
      raison: json['raison'] as String?,
    );
  }
}