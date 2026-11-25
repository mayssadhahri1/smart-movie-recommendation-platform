import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/film_catalogue_model.dart';
import '../../../data/models/film_model.dart';
import '../../../data/services/film_service.dart';
import '../catalogue/video_player_screen.dart';

class HistoriqueScreen extends StatefulWidget {
  const HistoriqueScreen({super.key});

  @override
  State<HistoriqueScreen> createState() => _HistoriqueScreenState();
}

class _HistoriqueScreenState extends State<HistoriqueScreen>
    with WidgetsBindingObserver {
  List<FilmModel> historique = [];
  bool loading = true;
  String? _erreur;
  Timer? _timer;
  Map<int, int> _positions = {};

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
      final data = await FilmService.getHistorique();
      final prefs = await SharedPreferences.getInstance();
      final Map<int, int> positions = {};
      for (final film in data) {
        final cle = 'trailer_pos_${film.tmdbId}';
        final pos = prefs.getInt(cle);
        debugPrint('📊 [Historique] $cle (${film.titre}) → $pos');
        if (pos != null) positions[film.tmdbId] = pos;
      }
      if (mounted) {
        setState(() {
          historique = data;
          _positions = positions;
          loading = false;
          _erreur = null;
        });
      }
    } catch (e) {
      // On affiche l'erreur réelle au lieu de montrer une liste vide
      // silencieuse — typiquement un 401 si le token a expiré après
      // déconnexion/reconnexion.
      final msg = e.toString();
      if (mounted) {
        setState(() {
          loading = false;
          _erreur = msg.contains('401') || msg.toLowerCase().contains('unauthorized')
              ? 'Session expirée. Reconnectez-vous pour voir votre historique.'
              : 'Impossible de charger l\'historique.';
        });
      }
    }
  }

  // ── Confirmation suppression d'un seul film ──────────────
  Future<void> _confirmerSuppression(FilmModel film) async {
    final confirm = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Fermer',
      barrierColor: Colors.black.withOpacity(0.6),
      transitionDuration: const Duration(milliseconds: 300),
      transitionBuilder: (ctx, anim, _, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.15),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: FadeTransition(opacity: anim, child: child),
        );
      },
      pageBuilder: (ctx, _, __) => Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 28),
          decoration: BoxDecoration(
            color: AppTheme.card,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Poster + overlay rouge
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20)),
                    child: film.backdropUrl != null
                        ? Image.network(
                      film.backdropUrl!,
                      height: 140,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 140,
                        color: AppTheme.primary,
                        child: const Icon(Icons.movie,
                            color: AppTheme.red, size: 50),
                      ),
                    )
                        : Container(
                      height: 140,
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(20)),
                      ),
                      child: const Center(
                        child: Icon(Icons.movie,
                            color: AppTheme.red, size: 50),
                      ),
                    ),
                  ),
                  // Overlay dégradé sombre
                  Container(
                    height: 140,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20)),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.75),
                        ],
                      ),
                    ),
                  ),
                  // Icône corbeille au centre
                  Positioned.fill(
                    child: Center(
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppTheme.red.withOpacity(0.15),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: AppTheme.red.withOpacity(0.5),
                              width: 1.5),
                        ),
                        child: const Icon(Icons.delete_rounded,
                            color: AppTheme.red, size: 28),
                      ),
                    ),
                  ),
                  // Titre du film en bas de l'image
                  Positioned(
                    bottom: 10,
                    left: 14,
                    right: 14,
                    child: Text(
                      film.titre,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              // Texte de confirmation
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 20, 22, 6),
                child: Column(
                  children: [
                    const Text(
                      'Supprimer de l\'historique ?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTheme.textLight,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ce film sera retiré de votre historique.\nVotre progression sera également supprimée.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTheme.textGrey.withOpacity(0.8),
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              // Boutons
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
                child: Row(
                  children: [
                    // Annuler
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          backgroundColor:
                          AppTheme.textGrey.withOpacity(0.1),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text(
                          'Annuler',
                          style: TextStyle(
                            color: AppTheme.textGrey,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Supprimer
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          backgroundColor: AppTheme.red,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.delete_rounded, size: 16),
                            SizedBox(width: 6),
                            Text(
                              'Supprimer',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (confirm == true) {
      await _supprimer(film.tmdbId);
    }
  }

  // ── Confirmation vider tout l'historique ─────────────────
  Future<void> _confirmerVider() async {
    final confirm = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Fermer',
      barrierColor: Colors.black.withOpacity(0.6),
      transitionDuration: const Duration(milliseconds: 300),
      transitionBuilder: (ctx, anim, _, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.15),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: FadeTransition(opacity: anim, child: child),
        );
      },
      pageBuilder: (ctx, _, __) => Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 28),
          decoration: BoxDecoration(
            color: AppTheme.card,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header rouge
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 28),
                decoration: BoxDecoration(
                  color: AppTheme.red.withOpacity(0.12),
                  borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
                  border: Border(
                    bottom: BorderSide(
                        color: AppTheme.red.withOpacity(0.2), width: 1),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppTheme.red.withOpacity(0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: AppTheme.red.withOpacity(0.4), width: 1.5),
                      ),
                      child: const Icon(Icons.delete_sweep_rounded,
                          color: AppTheme.red, size: 32),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Vider l\'historique',
                      style: TextStyle(
                        color: AppTheme.textLight,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // Contenu
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 20, 22, 6),
                child: Column(
                  children: [
                    // Nombre de films
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.red.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: AppTheme.red.withOpacity(0.2)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.movie_outlined,
                              color: AppTheme.red, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            '${historique.length} film${historique.length > 1 ? 's' : ''} sera${historique.length > 1 ? 'ont' : ''} supprimé${historique.length > 1 ? 's' : ''}',
                            style: const TextStyle(
                              color: AppTheme.red,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Cette action est irréversible.\nToute votre progression sera perdue.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTheme.textGrey.withOpacity(0.8),
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              // Boutons
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          backgroundColor:
                          AppTheme.textGrey.withOpacity(0.1),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text(
                          'Annuler',
                          style: TextStyle(
                            color: AppTheme.textGrey,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          backgroundColor: AppTheme.red,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.delete_sweep_rounded, size: 16),
                            SizedBox(width: 6),
                            Text(
                              'Tout vider',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (confirm == true) {
      await _viderHistorique();
    }
  }

  Future<void> _supprimer(int tmdbId) async {
    setState(() => historique.removeWhere((f) => f.tmdbId == tmdbId));
    try {
      await FilmService.supprimerHistorique(tmdbId);
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('trailer_pos_$tmdbId');
      setState(() => _positions.remove(tmdbId));
      _showSnack('Film supprimé de l\'historique', Icons.check_circle_outline);
    } catch (e) {
      _load();
      _showSnack('Erreur lors de la suppression', Icons.error_outline);
    }
  }

  Future<void> _viderHistorique() async {
    try {
      await FilmService.viderHistorique();
      final prefs = await SharedPreferences.getInstance();
      for (final film in historique) {
        await prefs.remove('trailer_pos_${film.tmdbId}');
      }
      setState(() {
        historique = [];
        _positions = {};
      });
      _showSnack('Historique vidé', Icons.check_circle_outline);
    } catch (e) {
      _showSnack('Erreur', Icons.error_outline);
    }
  }

  void _showSnack(String msg, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 10),
          Text(msg),
        ],
      ),
      backgroundColor: AppTheme.card,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      duration: const Duration(seconds: 2),
    ));
  }

  String _formatDuration(int seconds) {
    if (seconds < 60) return '${seconds}s';
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return s > 0 ? '${m}m ${s}s' : '${m}m';
  }

  void _ouvrirFilm(FilmModel film) {
    // ✅ Film catalogue (upload admin, vidéo complète) → lecteur dédié
    if (film.videoDisponible && film.filmId != null) {
      final catalogueFilm = FilmCatalogueModel(
        id: film.filmId!,
        tmdbId: film.tmdbId != 0 ? film.tmdbId : null,
        titre: film.titre,
        synopsis: film.synopsis,
        note: film.note,
        duree: film.duree,
        dateSortie: film.dateSortie,
        posterUrl: film.posterUrl,
        backdropUrl: film.backdropUrl,
        videoDisponible: true,
        genres: film.genres,
        // nombreVues / nombreFavoris omis : valeur par défaut 0,
        // non affichés dans le lecteur donc sans impact
      );
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VideoPlayerScreen(film: catalogueFilm),
        ),
      ).then((_) => _load());
      return;
    }

    // Film TMDB classique (trailer) → comportement existant
    final positionSauvegardee = _positions[film.tmdbId] ?? 0;
    Navigator.pushNamed(
      context,
      '/film',
      arguments: {
        'film': film,
        'startPosition': positionSauvegardee,
      },
    ).then((_) => _load());
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Mon Historique'),
        actions: [
          if (historique.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded, color: AppTheme.red),
              tooltip: 'Vider l\'historique',
              onPressed: _confirmerVider,
            ),
        ],
      ),
      body: loading
          ? const Center(
          child: CircularProgressIndicator(color: AppTheme.red))
          : _erreur != null
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.wifi_off_rounded,
                  size: 60,
                  color: AppTheme.red.withOpacity(0.6)),
              const SizedBox(height: 16),
              Text(_erreur!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: AppTheme.textLight, fontSize: 15)),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() => loading = true);
                  _load();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
      )
          : historique.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history,
                size: 70,
                color: AppTheme.textGrey.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text('Aucun film consulté',
                style: TextStyle(
                    color: AppTheme.textGrey.withOpacity(0.5),
                    fontSize: 16)),
            const SizedBox(height: 8),
            Text(
                'Les films que vous consultez apparaîtront ici',
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
          itemCount: historique.length,
          itemBuilder: (context, index) {
            final film = historique[index];
            final position = _positions[film.tmdbId];
            final aPosition = position != null && position > 0;

            return Dismissible(
              key: Key(film.tmdbId.toString()),
              direction: DismissDirection.endToStart,
              // Demande confirmation avant de dismiss
              confirmDismiss: (_) async {
                await _confirmerSuppression(film);
                return false; // on gère manuellement dans la dialog
              },
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: AppTheme.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.delete_rounded,
                    color: AppTheme.red, size: 28),
              ),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: AppTheme.card,
                  borderRadius: BorderRadius.circular(12),
                  border: aPosition
                      ? Border.all(
                      color: AppTheme.red.withOpacity(0.4),
                      width: 1.2)
                      : null,
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _ouvrirFilm(film),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      children: [
                        // Poster
                        ClipRRect(
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
                        const SizedBox(width: 12),

                        // Infos
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              Text(film.titre,
                                  style: const TextStyle(
                                      color: AppTheme.textLight,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14)),
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
                                Text(
                                    film.genres.take(2).join(' • '),
                                    style: const TextStyle(
                                        color: AppTheme.textGrey,
                                        fontSize: 11)),
                              ],
                              if (aPosition) ...[
                                const SizedBox(height: 8),
                                Row(children: [
                                  const Icon(
                                      Icons.play_circle_outline,
                                      color: AppTheme.red,
                                      size: 13),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Reprendre à ${_formatDuration(position!)}',
                                    style: const TextStyle(
                                        color: AppTheme.red,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ]),
                                const SizedBox(height: 4),
                                ClipRRect(
                                  borderRadius:
                                  BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: (position / 180)
                                        .clamp(0.0, 1.0),
                                    backgroundColor: AppTheme
                                        .textGrey
                                        .withOpacity(0.2),
                                    valueColor:
                                    const AlwaysStoppedAnimation<
                                        Color>(AppTheme.red),
                                    minHeight: 3,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),

                        // Bouton supprimer
                        IconButton(
                          icon: const Icon(Icons.delete_rounded,
                              color: AppTheme.red, size: 20),
                          onPressed: () =>
                              _confirmerSuppression(film),
                        ),
                      ],
                    ),
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