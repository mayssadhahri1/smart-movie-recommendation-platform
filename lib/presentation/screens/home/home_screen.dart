import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/film_service.dart';
import '../../../data/services/catalogue_service.dart';
import '../../../data/models/film_model.dart';
import '../../../data/models/film_catalogue_model.dart';
import '../historique/historique_screen.dart';
import '../favoris/favoris_screen.dart';
import '../profil/profil_screen.dart';
import '../catalogue/catalogue_screen.dart';
import '../catalogue/film_catalogue_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          _AccueilTab(),
          CatalogueScreen(),
          _SearchTab(),
          FavorisScreen(),
          HistoriqueScreen(),
          ProfilScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        backgroundColor: AppTheme.primary,
        selectedItemColor: AppTheme.red,
        unselectedItemColor: AppTheme.textGrey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Accueil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.movie_creation_outlined),
            activeIcon: Icon(Icons.movie_creation),
            label: 'Films',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search_outlined),
            activeIcon: Icon(Icons.search),
            label: 'Recherche',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_outline),
            activeIcon: Icon(Icons.favorite),
            label: 'Favoris',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_outlined),
            activeIcon: Icon(Icons.history),
            label: 'Historique',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}

// ─── Accueil Tab ──────────────────────────────────────────
class _AccueilTab extends StatefulWidget {
  const _AccueilTab();

  @override
  State<_AccueilTab> createState() => _AccueilTabState();
}

class _AccueilTabState extends State<_AccueilTab> {
  List<FilmModel> trending = [];
  List<FilmModel> popular = [];
  List<FilmModel> recommandations = [];
  List<FilmCatalogueModel> recommandationsCatalogue = [];
  bool loading = true;
  String nom = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      nom = await AuthService.getNom();
      final t = await FilmService.getTrending();
      final p = await FilmService.getPopular();
      final r = await FilmService.getRecommandations();
      final rc = await CatalogueService.getRecommandations();
      setState(() {
        trending = t;
        popular = p;
        recommandations = r;
        recommandationsCatalogue = rc;
        loading = false;
      });
    } catch (_) {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.red),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      color: AppTheme.red,
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: AppTheme.primary,
            expandedHeight: 120,
            floating: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primary, AppTheme.dark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(20, 50, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'Bonjour, $nom 👋',
                      style: const TextStyle(
                        color: AppTheme.textLight,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'Que voulez-vous regarder ?',
                      style: TextStyle(
                        color: AppTheme.textGrey,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionTitle(title: '🔥 Tendances', films: trending),
                _CatalogueRecommendationSection(
                  title: '🎯 Films à regarder pour vous',
                  films: recommandationsCatalogue,
                ),
                _SectionTitle(
                    title: '⭐ Recommandés pour vous',
                    films: recommandations),
                _SectionTitle(title: '🎬 Populaires', films: popular),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Section films horizontale (TMDB) ─────────────────────
class _SectionTitle extends StatelessWidget {
  final String title;
  final List<FilmModel> films;

  const _SectionTitle({required this.title, required this.films});

  @override
  Widget build(BuildContext context) {
    if (films.isEmpty) return const SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          child: Text(
            title,
            style: const TextStyle(
              color: AppTheme.textLight,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: films.length,
            itemBuilder: (context, index) {
              final film = films[index];
              return GestureDetector(
                onTap: () => Navigator.pushNamed(
                  context,
                  '/film',
                  arguments: film,
                ),
                child: Container(
                  width: 120,
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: AppTheme.card,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12)),
                        child: film.posterUrl != null
                            ? Image.network(
                          film.posterUrl!,
                          height: 150,
                          width: 120,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            height: 150,
                            color: AppTheme.primary,
                            child: const Icon(Icons.movie,
                                color: AppTheme.red, size: 40),
                          ),
                        )
                            : Container(
                          height: 150,
                          color: AppTheme.primary,
                          child: const Icon(Icons.movie,
                              color: AppTheme.red, size: 40),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(6),
                        child: Text(
                          film.titre,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppTheme.textLight,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Row(
                          children: [
                            const Icon(Icons.star,
                                color: Colors.amber, size: 12),
                            const SizedBox(width: 2),
                            Text(
                              double.tryParse(film.note)
                                  ?.toStringAsFixed(1) ??
                                  film.note,
                              style: const TextStyle(
                                color: AppTheme.textGrey,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─── Section Recommandations Catalogue (streaming complet) ──
class _CatalogueRecommendationSection extends StatelessWidget {
  final String title;
  final List<FilmCatalogueModel> films;

  const _CatalogueRecommendationSection({required this.title, required this.films});

  @override
  Widget build(BuildContext context) {
    if (films.isEmpty) return const SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          child: Text(
            title,
            style: const TextStyle(
              color: AppTheme.textLight,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(
          height: 210,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: films.length,
            itemBuilder: (context, index) {
              final film = films[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FilmCatalogueDetailScreen(film: film),
                    ),
                  );
                },
                child: Container(
                  width: 130,
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: AppTheme.card,
                    border: Border.all(color: AppTheme.red.withOpacity(0.3), width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                            child: film.posterUrl != null
                                ? Image.network(
                              film.posterUrl!,
                              height: 150,
                              width: 130,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                height: 150,
                                color: AppTheme.primary,
                                child: const Icon(Icons.movie, color: AppTheme.red, size: 40),
                              ),
                            )
                                : Container(
                              height: 150,
                              color: AppTheme.primary,
                              child: const Icon(Icons.movie, color: AppTheme.red, size: 40),
                            ),
                          ),
                          Positioned(
                            top: 6,
                            left: 6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppTheme.red,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.play_arrow, color: Colors.white, size: 10),
                                  SizedBox(width: 2),
                                  Text('VOIR',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(6, 6, 6, 2),
                        child: Text(
                          film.titre,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppTheme.textLight,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (film.raison != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Text(
                            film.raison!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppTheme.red,
                              fontSize: 9,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─── Search Tab ───────────────────────────────────────────
class _SearchTab extends StatefulWidget {
  const _SearchTab();

  @override
  State<_SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<_SearchTab> {
  final _controller = TextEditingController();
  List<FilmModel> results = [];
  bool loading = false;

  Future<void> _search(String query) async {
    if (query.isEmpty) {
      setState(() => results = []);
      return;
    }
    setState(() => loading = true);
    try {
      final r = await FilmService.search(query);
      setState(() => results = r);
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        title: TextField(
          controller: _controller,
          style: const TextStyle(color: AppTheme.textLight),
          decoration: const InputDecoration(
            hintText: 'Rechercher un film...',
            hintStyle: TextStyle(color: AppTheme.textGrey),
            border: InputBorder.none,
            prefixIcon: Icon(Icons.search, color: AppTheme.textGrey),
          ),
          onChanged: _search,
        ),
      ),
      body: loading
          ? const Center(
          child: CircularProgressIndicator(color: AppTheme.red))
          : results.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search,
                size: 60,
                color: AppTheme.textGrey.withOpacity(0.3)),
            const SizedBox(height: 12),
            Text(
              'Rechercher un film',
              style: TextStyle(
                color: AppTheme.textGrey.withOpacity(0.5),
                fontSize: 16,
              ),
            ),
          ],
        ),
      )
          : GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate:
        const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.6,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: results.length,
        itemBuilder: (context, index) {
          final film = results[index];
          return GestureDetector(
            onTap: () => Navigator.pushNamed(
              context,
              '/film',
              arguments: film,
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: AppTheme.card,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12)),
                      child: film.posterUrl != null
                          ? Image.network(
                        film.posterUrl!,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            Container(
                              color: AppTheme.primary,
                              child: const Icon(Icons.movie,
                                  color: AppTheme.red,
                                  size: 40),
                            ),
                      )
                          : Container(
                        color: AppTheme.primary,
                        child: const Icon(Icons.movie,
                            color: AppTheme.red, size: 40),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          film.titre,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppTheme.textLight,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.star,
                                color: Colors.amber, size: 12),
                            const SizedBox(width: 2),
                            Text(
                              double.tryParse(film.note)
                                  ?.toStringAsFixed(1) ??
                                  film.note,
                              style: const TextStyle(
                                color: AppTheme.textGrey,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}