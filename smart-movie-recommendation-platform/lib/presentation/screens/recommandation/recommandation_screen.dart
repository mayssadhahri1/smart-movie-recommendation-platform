import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/film_model.dart';
import '../../../data/services/film_service.dart';

class RecommandationScreen extends StatefulWidget {
  const RecommandationScreen({super.key});

  @override
  State<RecommandationScreen> createState() => _RecommandationScreenState();
}

class _RecommandationScreenState extends State<RecommandationScreen> {
  List<FilmModel> recommandations = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      final data = await FilmService.getRecommandations();
      setState(() {
        recommandations = data;
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Recommandations'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.textLight),
            onPressed: _load,
          ),
        ],
      ),
      body: loading
          ? const Center(
          child: CircularProgressIndicator(color: AppTheme.red))
          : recommandations.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.recommend,
              size: 70,
              color: AppTheme.textGrey.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Aucune recommandation',
              style: TextStyle(
                color: AppTheme.textGrey.withOpacity(0.5),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ajoutez des films en favoris pour\nrecevoir des recommandations',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.textGrey.withOpacity(0.3),
                fontSize: 13,
              ),
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
            childAspectRatio: 0.55,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: recommandations.length,
          itemBuilder: (context, index) {
            final film = recommandations[index];
            return GestureDetector(
              onTap: () => Navigator.pushNamed(
                context,
                '/film',
                arguments: film,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.card,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Poster
                    Expanded(
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(12)),
                            child: film.posterUrl != null
                                ? Image.network(
                              film.posterUrl!,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _placeholder(),
                            )
                                : _placeholder(),
                          ),
                          // Badge recommandation
                          Positioned(
                            top: 8,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppTheme.red,
                                borderRadius:
                                BorderRadius.circular(6),
                              ),
                              child: const Text(
                                '⭐ Pour vous',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
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
                                  color: Colors.amber, size: 11),
                              const SizedBox(width: 3),
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
                          if (film.raison != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              film.raison!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppTheme.red,
                                fontSize: 9,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
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
    );
  }

  Widget _placeholder() {
    return Container(
      color: AppTheme.primary,
      child: const Center(
        child: Icon(Icons.movie, color: AppTheme.red, size: 40),
      ),
    );
  }
}