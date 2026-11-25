import '../../core/constants/api_constants.dart';
import '../../core/network/api_service.dart';
import '../models/film_catalogue_model.dart';

class CatalogueService {

  // ─── LISTE DU CATALOGUE ──────────────────────────────────
  static Future<List<FilmCatalogueModel>> getCatalogue() async {
    try {
      final data = await ApiService.get(ApiConstants.filmsCatalogue);
      if (data == null) return [];
      final List<FilmCatalogueModel> result = [];
      for (final e in (data as List)) {
        try {
          result.add(FilmCatalogueModel.fromJson(e));
        } catch (err) {
          print('❌ Erreur parsing film catalogue: $e → $err');
        }
      }
      return result;
    } catch (_) {
      return [];
    }
  }

  static Future<FilmCatalogueModel?> getDetail(int id) async {
    try {
      final data = await ApiService.get('${ApiConstants.filmsCatalogue}/$id');
      return FilmCatalogueModel.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  // ─── STREAMING ────────────────────────────────────────────
  static String getVideoUrl(int filmId) {
    return '${ApiConstants.baseUrl}/films/$filmId/stream';
  }

  // ─── VUES ─────────────────────────────────────────────────
  static Future<void> enregistrerVue(int id) async {
    try {
      final result = await ApiService.post('${ApiConstants.filmsCatalogue}/$id/vue', {});
      print('✅ Vue catalogue enregistrée pour id=$id — réponse: $result');
    } catch (e) {
      print('❌ Échec enregistrerVue catalogue $id : $e');
    }
  }

  // ─── FAVORIS ──────────────────────────────────────────────
  static Future<bool> isFavori(int id) async {
    try {
      final data = await ApiService.get('${ApiConstants.filmsCatalogue}/$id/favori');
      return data == true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> toggleFavori(int id) async {
    await ApiService.post('${ApiConstants.filmsCatalogue}/$id/favori', {});
    return await isFavori(id);
  }

  // ─── RECOMMANDATIONS (catalogue, basées sur tout l'historique) ──
  static Future<List<FilmCatalogueModel>> getRecommandations() async {
    try {
      final data = await ApiService.get('/recommandations/catalogue');
      if (data == null) return [];
      final List<FilmCatalogueModel> result = [];
      for (final e in (data as List)) {
        try {
          result.add(FilmCatalogueModel.fromJson(e));
        } catch (err) {
          print('❌ Erreur parsing recommandation catalogue: $e → $err');
        }
      }
      return result;
    } catch (_) {
      return [];
    }
  }

  // ─── TRAILER (films catalogue provenant de TMDB) ───────────
  // ✅ CORRIGÉ : on enregistre désormais une "vue" pour cet utilisateur
  // quand le trailer est effectivement chargé, pour que les
  // recommandations évoluent même si l'utilisateur ne regarde
  // que le trailer (sans lancer le film complet).
  static Future<String?> getTrailer(int filmId) async {
    try {
      final data = await ApiService.get('/recommandations/catalogue/$filmId/trailer');
      if (data == null || data.toString().isEmpty || data.toString() == 'null') {
        return null;
      }
      // ✅ trailer chargé avec succès → on enregistre dans l'historique
      enregistrerVue(filmId);
      return data.toString();
    } catch (e) {
      print('❌ Échec getTrailer catalogue $filmId : $e');
      return null;
    }
  }
}