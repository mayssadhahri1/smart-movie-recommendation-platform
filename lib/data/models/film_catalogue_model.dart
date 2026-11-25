// lib/data/models/film_catalogue_model.dart
// Modèle pour les films uploadés par l'admin (différent de FilmModel TMDB)

class FilmCatalogueModel {
  final int id;
  final int? tmdbId;
  final String titre;
  final String synopsis;
  final String note;
  final String duree;
  final String dateSortie;
  final String? posterUrl;
  final String? backdropUrl;
  final bool videoDisponible;
  final List<String> genres;
  final int nombreVues;
  final int nombreFavoris;
  final String? raison;

  const FilmCatalogueModel({
    required this.id,
    this.tmdbId,
    required this.titre,
    required this.synopsis,
    required this.note,
    required this.duree,
    required this.dateSortie,
    this.posterUrl,
    this.backdropUrl,
    required this.videoDisponible,
    required this.genres,
    this.nombreVues = 0,
    this.nombreFavoris = 0,
    this.raison,
  });

  static String _asString(dynamic v, [String fallback = '']) =>
      v == null ? fallback : v.toString();

  static int _asInt(dynamic v, [int fallback = 0]) {
    if (v == null) return fallback;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v) ?? fallback;
    return fallback;
  }

  factory FilmCatalogueModel.fromJson(Map<String, dynamic> json) {
    return FilmCatalogueModel(
      id:              _asInt(json['id']),
      tmdbId:          json['tmdbId'] != null ? _asInt(json['tmdbId']) : null,
      titre:           _asString(json['titre']),
      synopsis:        _asString(json['synopsis']),
      note:            _asString(json['note'], '0'),
      duree:           _asString(json['duree']),
      dateSortie:      _asString(json['dateSortie']),
      posterUrl:       json['posterUrl'] as String?,
      backdropUrl:     json['backdropUrl'] as String?,
      videoDisponible: json['videoDisponible'] == true,
      genres: json['genres'] != null
          ? List<String>.from((json['genres'] as List).map((g) => g.toString()))
          : [],
      nombreVues:    _asInt(json['nombreVues']),
      nombreFavoris: _asInt(json['nombreFavoris']),
      raison: json['raison'] as String?,
    );
  }
}