import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/app_theme.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/auth/register_screen.dart';
import 'presentation/screens/home/home_screen.dart';
import 'presentation/screens/film/film_detail_screen.dart';
import 'presentation/screens/historique/historique_screen.dart';
import 'presentation/screens/recommandation/recommandation_screen.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');
  runApp(SmartMovieApp(isLoggedIn: token != null));
}

class SmartMovieApp extends StatelessWidget {
  final bool isLoggedIn;
  const SmartMovieApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Movie',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      initialRoute: isLoggedIn ? '/home' : '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const HomeScreen(),
        '/film': (context) => const FilmDetailScreen(),
        '/historique': (context) => const HistoriqueScreen(),
        '/recommandations': (context) => const RecommandationScreen(),

      },
    );
  }
}

