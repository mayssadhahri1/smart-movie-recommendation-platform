// lib/presentation/screens/catalogue/catalogue_screen.dart
// Écran principal du catalogue des films uploadés par l'admin

import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/film_catalogue_model.dart';
import '../../../data/services/catalogue_service.dart';
import 'film_catalogue_detail_screen.dart';

class CatalogueScreen extends StatefulWidget {
  const CatalogueScreen({super.key});

  @override
  State<CatalogueScreen> createState() => _CatalogueScreenState();
}

class _CatalogueScreenState extends State<CatalogueScreen> {
  List<FilmCatalogueModel> _films = [];
  List<FilmCatalogueModel> _filtered = [];
  bool _loading = true;
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await CatalogueService.getCatalogue();
      if (mounted) {
        setState(() {
          _films    = data;
          _filtered = data;
          _loading  = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _filterSearch(String query) {
    setState(() {
      _filtered = query.isEmpty
          ? _films
          : _films
          .where((f) =>
          f.titre.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        title: const Text('🎬 Films en Ligne',
            style: TextStyle(color: AppTheme.textLight)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Padding(
            padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: TextField(
              controller: _search,
              onChanged: _filterSearch,
              style: const TextStyle(color: AppTheme.textLight),
              decoration: InputDecoration(
                hintText: 'Rechercher un film...',
                hintStyle:
                TextStyle(color: AppTheme.textGrey.withOpacity(0.6)),
                prefixIcon: const Icon(Icons.search,
                    color: AppTheme.textGrey, size: 20),
                filled: true,
                fillColor: AppTheme.card,
                contentPadding:
                const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
      body: _loading
          ? const Center(
          child: CircularProgressIndicator(color: AppTheme.red))
          : _filtered.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.movie_creation_outlined,
                size: 70,
                color: AppTheme.textGrey.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text(
              'Aucun film disponible',
              style: TextStyle(
                  color: AppTheme.textGrey.withOpacity(0.5),
                  fontSize: 16),
            ),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: _load,
        color: AppTheme.red,
        child: GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate:
          const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.62,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: _filtered.length,
          itemBuilder: (context, index) {
            return _FilmCard(
              film: _filtered[index],
              onReturn: _load, // rafraîchit vues/favoris au retour
            );
          },
        ),
      ),
    );
  }
}

// ── Carte d'un film ───────────────────────────────────────
class _FilmCard extends StatelessWidget {
  final FilmCatalogueModel film;
  final VoidCallback onReturn;
  const _FilmCard({required this.film, required this.onReturn});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // ✅ Ouvre désormais la fiche détail (synopsis, favoris, stats)
      // au lieu de sauter directement dans le lecteur vidéo.
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FilmCatalogueDetailScreen(film: film),
          ),
        ).then((_) => onReturn());
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: AppTheme.card,
          border: film.videoDisponible
              ? Border.all(color: AppTheme.red.withOpacity(0.3), width: 1)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Poster
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12)),
                    child: film.posterUrl != null
                        ? Image.network(
                      film.posterUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder(),
                    )
                        : _placeholder(),
                  ),
                  // Badge "DISPONIBLE"
                  if (film.videoDisponible)
                    Positioned(
                      top: 8, left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.red,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.play_arrow,
                                color: Colors.white, size: 10),
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
                  // Icône play au centre si disponible
                  if (film.videoDisponible)
                    Positioned.fill(
                      child: Center(
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.55),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.play_arrow,
                              color: Colors.white, size: 26),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Infos
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(film.titre,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: AppTheme.textLight,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.star, color: Colors.amber, size: 11),
                    const SizedBox(width: 3),
                    Text(
                      double.tryParse(film.note)?.toStringAsFixed(1) ??
                          film.note,
                      style: const TextStyle(
                          color: AppTheme.textGrey, fontSize: 10),
                    ),
                    const Spacer(),
                    if (film.duree.isNotEmpty)
                      Text(film.duree,
                          style: const TextStyle(
                              color: AppTheme.textGrey, fontSize: 10)),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
    color: AppTheme.primary,
    child: const Center(
      child: Icon(Icons.movie, color: AppTheme.red, size: 40),
    ),
  );
}