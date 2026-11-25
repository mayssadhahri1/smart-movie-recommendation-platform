import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_service.dart';
import '../models/user_model.dart';

class AuthService {

  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  static Future<UserModel> login(String email, String motPasse) async {
    final data = await ApiService.post(ApiConstants.login, {
      'email': email,
      'motPasse': motPasse,
    });
    final user = UserModel.fromJson(data);
    await _saveUser(user);
    return user;
  }

  static Future<UserModel> register(
      String nom, String email, String motPasse) async {
    final data = await ApiService.post(ApiConstants.register, {
      'nom': nom,
      'email': email,
      'motPasse': motPasse,
    });
    final user = UserModel.fromJson(data);
    await _saveUser(user);
    return user;
  }

  // ─── GOOGLE SIGN-IN ────────────────────────────────────────
  static Future<UserModel> loginWithGoogle() async {
    // Déconnecte d'abord pour forcer le sélecteur de compte
    await _googleSignIn.signOut();

    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw Exception('Connexion annulée');
    }

    final googleAuth = await googleUser.authentication;
    final idToken = googleAuth.idToken;

    if (idToken == null) {
      throw Exception('Token Google introuvable');
    }

    final data = await ApiService.post('/auth/google', {'idToken': idToken});
    final user = UserModel.fromJson(data);
    await _saveUser(user);
    return user;
  }

  static Future<void> _saveUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', user.token);
    await prefs.setString('nom', user.nom);
    await prefs.setString('email', user.email);
    await prefs.setInt('userId', user.id);
    await prefs.setString('role', user.role);
    print('Token saved: ${user.token}');
    print('Nom saved: ${user.nom}');
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    print('Token check: $token');
    return token != null && token.isNotEmpty;
  }

  static Future<String> getNom() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('nom') ?? '';
  }

  static Future<String> getEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('email') ?? '';
  }

  // Clés liées à l'authentification uniquement. Si tu ajoutes d'autres
  // clés "de session" plus tard (ex: 'favorisCache'), ajoute-les ici.
  static const List<String> _authKeys = [
    'token',
    'nom',
    'email',
    'userId',
    'role',
  ];

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    // Avant : prefs.clear() effaçait TOUT, y compris les positions de
    // lecture des trailers (trailer_pos_*), qui n'ont rien à voir avec
    // l'authentification. C'est pour ça qu'elles redevenaient null
    // après une reconnexion.
    // Maintenant : on ne supprime que les clés d'auth, le reste
    // (préférences locales comme les positions de trailer) survit.
    for (final key in _authKeys) {
      await prefs.remove(key);
    }
    await _googleSignIn.signOut();
  }
}