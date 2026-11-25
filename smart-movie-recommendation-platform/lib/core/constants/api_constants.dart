class ApiConstants {
  static const String baseUrl = 'http://192.168.100.12:8081/api';
  static const String imageBaseUrl = 'https://image.tmdb.org/t/p/w500';

  // Auth
  static const String login = '/auth/login';
  static const String register = '/auth/register';

  // Films
  static const String trending = '/films/trending';
  static const String popular = '/films/popular';
  static const String topRated = '/films/top-rated';
  static const String search = '/films/search';
  static const String filmDetail = '/films';
  static const String genre = '/films/genre';
  static const String filmsCatalogue = '/films/catalogue';
  // Favoris
  static const String favoris = '/favoris';

  // Historique
  static const String historique = '/historique';

  // Profil
  static const String profil = '/profil';

  // Recommandations
  static const String recommandations = '/recommandations';
}