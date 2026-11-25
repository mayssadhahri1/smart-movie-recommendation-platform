import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';

class ApiService {
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<Map<String, String>> getHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<dynamic> get(String endpoint) async {
    final headers = await getHeaders();
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}$endpoint'),
      headers: headers,
    );
    return _handleResponse(response);
  }

  static Future<dynamic> post(String endpoint,
      Map<String, dynamic> body) async {
    final headers = await getHeaders();
    print('POST $endpoint body: $body');
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}$endpoint'),
      headers: headers,
      body: jsonEncode(body),
    );
    print('Response ${response.statusCode}: ${response.body}');
    return _handleResponse(response);
  }

  static Future<dynamic> delete(String endpoint) async {
    final headers = await getHeaders();
    final response = await http.delete(
      Uri.parse('${ApiConstants.baseUrl}$endpoint'),
      headers: headers,
    );
    return _handleResponse(response);
  }

  /// ✅ CORRECTIF : plusieurs endpoints (ajouterFavori, retirerFavori,
  /// toggleFavoriCatalogue...) renvoient un ResponseEntity<String> en
  /// TEXTE BRUT côté Spring (ex: "Film ajouté aux favoris"), pas du JSON.
  ///
  /// Avant : jsonDecode() plantait sur ce texte avec une FormatException,
  /// qui remontait comme une erreur réseau alors que la requête avait
  /// réussi (code 200). Ça provoquait :
  ///   - des faux messages "retiré des favoris" côté catalogue
  ///   - des faux toasts d'erreur côté favoris TMDB (alors que le favori
  ///     était bien enregistré en base, d'où sa présence dans la liste)
  ///
  /// Maintenant : on tente le JSON, et si ça échoue on retombe sur le
  /// texte brut au lieu de lever une exception.
  static dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final raw = utf8.decode(response.bodyBytes);
      if (raw.isEmpty) return null;
      try {
        return jsonDecode(raw);
      } catch (_) {
        // Réponse texte brut (String simple renvoyée par le backend)
        return raw;
      }
    } else {
      throw Exception('Erreur ${response.statusCode}: ${response.body}');
    }
  }
}