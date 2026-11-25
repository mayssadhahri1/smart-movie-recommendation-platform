import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/film_model.dart';
import '../../../data/services/film_service.dart';

class FavorisScreen extends StatefulWidget {
  const FavorisScreen({super.key});

  @override
  State<FavorisScreen> createState() => _FavorisScreenState();
}

class _FavorisScreenState extends State<FavorisScreen>
    with WidgetsBindingObserver {
  List<FilmModel> favoris = [];
  bool loading = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _load();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted) _load();
    });
  }

  Future<void> _load() async {
    try {
      final f = await FilmService.getFavoris();
      if (mounted) {
        setState(() {
          favoris = f;
          loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _retirer(int tmdbId) async {
    setState(() => favoris.removeWhere((f) => f.tmdbId == tmdbId));
    try {
      await FilmService.retirerFavori(tmdbId);
      _showSnack('Retiré des favoris');
    } catch (e) {
      _load();
      _showSnack('Erreur lors de la suppression');
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppTheme.card,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Mes Favoris'),
        actions: [
          if (favoris.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: Text(
                  '${favoris.length} film${favoris.length > 1 ? 's' : ''}',
                  style: const TextStyle(
                      color: AppTheme.textGrey, fontSize: 13),
                ),
              ),
            ),
        ],
      ),
      body: loading
          ? const Center(
          child: CircularProgressIndicator(color: AppTheme.red))
          : favoris.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_outline,
                size: 70,
                color: AppTheme.textGrey.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text('Aucun favori pour le moment',
                style: TextStyle(
                    color: AppTheme.textGrey.withOpacity(0.5),
                    fontSize: 16)),
            const SizedBox(height: 8),
            Text('Ajoutez des films depuis leur page de détail',
                style: TextStyle(
                    color: AppTheme.textGrey.withOpacity(0.3),
                    fontSize: 13)),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: _load,
        color: AppTheme.red,
        child: ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: favoris.length,
          itemBuilder: (context, index) {
            final film = favoris[index];
            return Dismissible(
              key: Key(film.tmdbId.toString()),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: AppTheme.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.delete_outline,
                    color: AppTheme.red, size: 28),
              ),
              onDismissed: (_) => _retirer(film.tmdbId),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: AppTheme.card,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(10),
                  onTap: () => Navigator.pushNamed(
                    context,
                    '/film',
                    arguments: film,
                  ).then((_) => _load()),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: film.posterUrl != null
                        ? Image.network(
                      film.posterUrl!,
                      width: 50,
                      height: 70,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _placeholder(),
                    )
                        : _placeholder(),
                  ),
                  title: Text(film.titre,
                      style: const TextStyle(
                          color: AppTheme.textLight,
                          fontWeight: FontWeight.w600,
                          fontSize: 14)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Row(children: [
                        const Icon(Icons.star,
                            color: Colors.amber, size: 13),
                        const SizedBox(width: 4),
                        Text(
                            double.tryParse(film.note)
                                ?.toStringAsFixed(1) ??
                                film.note,
                            style: const TextStyle(
                                color: AppTheme.textGrey,
                                fontSize: 12)),
                      ]),
                      if (film.genres.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(film.genres.take(2).join(' • '),
                            style: const TextStyle(
                                color: AppTheme.textGrey,
                                fontSize: 11)),
                      ],
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.favorite,
                        color: AppTheme.red, size: 22),
                    onPressed: () => _retirer(film.tmdbId),
                  ),
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
      width: 50,
      height: 70,
      color: AppTheme.primary,
      child: const Icon(Icons.movie, color: AppTheme.red, size: 24),
    );
  }
}