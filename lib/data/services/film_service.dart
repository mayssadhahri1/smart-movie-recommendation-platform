import 'package:http/http.dart' as http;
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_service.dart';
import '../models/film_model.dart';

class FilmService {

  // ─── FILMS ───────────────────────────────────────────────
  static Future<List<FilmModel>> getTrending() async {
    final data = await ApiService.get(ApiConstants.trending);
    return (data as List).map((e) => FilmModel.fromJson(e)).toList();
  }

  static Future<List<FilmModel>> getPopular() async {
    final data = await ApiService.get(ApiConstants.popular);
    return (data as List).map((e) => FilmModel.fromJson(e)).toList();
  }

  static Future<List<FilmModel>> getTopRated() async {
    final data = await ApiService.get(ApiConstants.topRated);
    return (data as List).map((e) => FilmModel.fromJson(e)).toList();
  }

  static Future<List<FilmModel>> search(String query) async {
    final data = await ApiService.get('${ApiConstants.search}?query=$query');
    return (data as List).map((e) => FilmModel.fromJson(e)).toList();
  }

  static Future<FilmModel> getDetail(int tmdbId) async {
    final data = await ApiService.get('${ApiConstants.filmDetail}/$tmdbId');
    return FilmModel.fromJson(data);
  }

  static Future<List<dynamic>> getActeurs(int tmdbId) async {
    return await ApiService.get(
        '${ApiConstants.filmDetail}/$tmdbId/acteurs');
  }

  static Future<List<FilmModel>> getByGenre(int genreId) async {
    final data = await ApiService.get('${ApiConstants.genre}/$genreId');
    return (data as List).map((e) => FilmModel.fromJson(e)).toList();
  }

  // ─── TRAILER ─────────────────────────────────────────────
  static Future<String?> getTrailer(int tmdbId) async {
    try {
      final headers = await ApiService.getHeaders();
      final response = await http.get(
        Uri.parse(
            '${ApiConstants.baseUrl}${ApiConstants.filmDetail}/$tmdbId/trailer'),
        headers: headers,
      );
      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final key = response.body.replaceAll('"', '').trim();
        if (key == 'null' || key.isEmpty) return null;
        return key;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<dynamic> getTrailerRaw(int tmdbId) async {
    return await getTrailer(tmdbId);
  }

  // ─── FAVORIS ─────────────────────────────────────────────
  static Future<List<FilmModel>> getFavoris() async {
    try {
      final data = await ApiService.get(ApiConstants.favoris);
      if (data == null) return [];
      return (data as List).map((e) => FilmModel.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> ajouterFavori(int tmdbId) async {
    await ApiService.post('${ApiConstants.favoris}/$tmdbId', {});
  }

  static Future<void> retirerFavori(int tmdbId) async {
    await ApiService.delete('${ApiConstants.favoris}/$tmdbId');
  }

  // ─── HISTORIQUE ───────────────────────────────────────────

  static Future<List<FilmModel>> getHistorique() async {
    final data = await ApiService.get(ApiConstants.historique);
    print('📋 HISTORIQUE RAW DATA: $data');
    if (data == null) return [];

    final List<FilmModel> result = [];
    for (final e in (data as List)) {
      try {
        result.add(FilmModel.fromJson(e));
      } catch (err) {
        print('❌ Erreur parsing film historique: $e → $err');
      }
    }
    return result;
  }

  static Future<void> enregistrerConsultation(int tmdbId) async {
    final result =
    await ApiService.post('${ApiConstants.historique}/$tmdbId', {});
    print('✅ Consultation enregistrée pour tmdbId: $tmdbId — réponse: $result');
  }

  static Future<void> supprimerHistorique(int tmdbId) async {
    await ApiService.delete('${ApiConstants.historique}/$tmdbId');
  }

  static Future<void> viderHistorique() async {
    await ApiService.delete(ApiConstants.historique);
  }

  // ─── PROFIL ───────────────────────────────────────────────
  static Future<dynamic> getProfil() async {
    return await ApiService.get(ApiConstants.profil);
  }

  // ─── RECOMMANDATIONS ─────────────────────────────────────
  static Future<List<FilmModel>> getRecommandations() async {
    try {
      final data = await ApiService.get(ApiConstants.recommandations);
      if (data == null) return [];
      return (data as List).map((e) => FilmModel.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }
}