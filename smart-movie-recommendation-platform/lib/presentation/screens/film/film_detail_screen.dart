import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/film_model.dart';
import '../../../data/services/film_service.dart';

class FilmDetailScreen extends StatefulWidget {
  const FilmDetailScreen({super.key});

  @override
  State<FilmDetailScreen> createState() => _FilmDetailScreenState();
}

class _FilmDetailScreenState extends State<FilmDetailScreen>
    with SingleTickerProviderStateMixin {
  bool _isFavori = false;
  bool _loadingFavori = false;
  List<dynamic> _acteurs = [];
  String? _trailerUrl;
  String? _trailerKey;
  bool _loadingDetail = true;

  List<FilmModel> _recommandations = [];
  bool _loadingRecos = true;

  int _startPosition = 0;

  late final AnimationController _favAnimController;
  late final Animation<double> _favScaleAnim;

  @override
  void initState() {
    super.initState();
    _favAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _favScaleAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.35), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.35, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _favAnimController, curve: Curves.easeOut));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDetails();
      _loadRecommandations();
    });
  }

  @override
  void dispose() {
    _favAnimController.dispose();
    super.dispose();
  }

  String? _extractYoutubeKey(String? raw) {
    if (raw == null || raw.trim().isEmpty || raw.trim() == 'null') return null;
    final s = raw.trim();
    if (s.contains('youtube.com')) {
      return Uri.parse(s).queryParameters['v'];
    }
    if (s.contains('youtu.be/')) {
      return s.split('youtu.be/').last.split('?').first.trim();
    }
    return s;
  }

  FilmModel _extractFilm(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments;
    if (args is Map) {
      _startPosition = (args['startPosition'] as int?) ?? 0;
      return args['film'] as FilmModel;
    }
    _startPosition = 0;
    return args as FilmModel;
  }

  Future<void> _loadDetails() async {
    final film = _extractFilm(context);

    try {
      await FilmService.enregistrerConsultation(film.tmdbId);
    } catch (e) {
      final msg = e.toString();
      if (mounted &&
          (msg.contains('401') || msg.toLowerCase().contains('unauthorized'))) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Session expirée : ce film ne sera pas ajouté à votre historique.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }

    try {
      final acteurs = await FilmService.getActeurs(film.tmdbId);
      final trailerRaw = await FilmService.getTrailer(film.tmdbId);
      final favoris = await FilmService.getFavoris();
      final isFav = favoris.any((f) => f.tmdbId == film.tmdbId);
      final cleanKey = _extractYoutubeKey(trailerRaw);

      if (mounted) {
        setState(() {
          _acteurs = acteurs;
          _trailerKey = cleanKey;
          _trailerUrl =
          cleanKey != null ? 'https://www.youtube.com/watch?v=$cleanKey' : null;
          _isFavori = isFav;
          _loadingDetail = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingDetail = false);
    }
  }

  Future<void> _loadRecommandations() async {
    try {
      final recos = await FilmService.getRecommandations();
      if (mounted) {
        setState(() {
          _recommandations = recos;
          _loadingRecos = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingRecos = false);
    }
  }

  Future<void> _toggleFavori(FilmModel film) async {
    final etatAvant = _isFavori;
    setState(() => _loadingFavori = true);

    try {
      if (_isFavori) {
        await FilmService.retirerFavori(film.tmdbId);
        _favAnimController.forward(from: 0);
        setState(() => _isFavori = false);
        _showSnack('Film retiré des favoris', AppTheme.textGrey,
            Icons.favorite_border_rounded);
      } else {
        await FilmService.ajouterFavori(film.tmdbId);
        _favAnimController.forward(from: 0);
        setState(() => _isFavori = true);
        _showSnack('Film ajouté aux favoris', AppTheme.red,
            Icons.favorite_rounded);
      }
    } catch (e) {
      // ✅ On ne change plus l'état affiché en cas d'erreur : avant,
      // ce catch se déclenchait à tort à cause d'un bug de parsing
      // dans ApiService (corrigé désormais), ce qui affichait un faux
      // message d'erreur alors que le favori était bien enregistré.
      if (mounted) setState(() => _isFavori = etatAvant);
      _showSnack('Impossible de mettre à jour les favoris', AppTheme.red,
          Icons.error_outline_rounded);
    } finally {
      if (mounted) setState(() => _loadingFavori = false);
    }
  }

  Future<void> _openTrailer(FilmModel film) async {
    if (_trailerKey == null) return;

    final prefs = await SharedPreferences.getInstance();
    final anciennePos = prefs.getInt('trailer_pos_${film.tmdbId}') ?? 0;
    final nouvellePos = anciennePos + 30;
    await prefs.setInt('trailer_pos_${film.tmdbId}', nouvellePos);

    final startSec = _startPosition > 0 ? _startPosition : 0;

    final youtubeApp = Uri.parse(
        'youtube://watch?v=$_trailerKey${startSec > 0 ? '&t=${startSec}s' : ''}');
    if (await canLaunchUrl(youtubeApp)) {
      await launchUrl(youtubeApp);
      return;
    }

    final webUrl = Uri.parse(
        'https://www.youtube.com/watch?v=$_trailerKey${startSec > 0 ? '&t=${startSec}s' : ''}');
    if (await canLaunchUrl(webUrl)) {
      await launchUrl(webUrl, mode: LaunchMode.externalApplication);
    } else {
      _showSnack('Impossible d\'ouvrir le trailer', AppTheme.red);
    }
  }

  void _showSnack(String msg, Color color, [IconData icon = Icons.info_outline_rounded]) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(msg)),
        ],
      ),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      duration: const Duration(seconds: 2),
    ));
  }

  String _getGenreName(String g) {
    const genres = {
      '28': 'Action', '12': 'Aventure', '16': 'Animation',
      '35': 'Comédie', '80': 'Crime', '99': 'Documentaire',
      '18': 'Drame', '10751': 'Famille', '14': 'Fantastique',
      '36': 'Histoire', '27': 'Horreur', '10402': 'Musique',
      '9648': 'Mystère', '10749': 'Romance', '878': 'Science-Fiction',
      '10770': 'Téléfilm', '53': 'Thriller', '10752': 'Guerre',
      '37': 'Western',
    };
    return genres[g] ?? g;
  }

  String _formatDuration(int seconds) {
    if (seconds < 60) return '${seconds}s';
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return s > 0 ? '${m}m ${s}s' : '${m}m';
  }

  @override
  Widget build(BuildContext context) {
    final film = _extractFilm(context);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(film),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPosterAndInfo(film),
                  const SizedBox(height: 20),
                  if (_startPosition > 0) _buildResumeBanner(),
                  _buildActionButtons(film),
                  const SizedBox(height: 24),
                  _buildSynopsis(film),
                  const SizedBox(height: 28),
                  if (!_loadingDetail && _acteurs.isNotEmpty) _buildActeurs(),
                  if (_loadingDetail) ...[
                    const SizedBox(height: 20),
                    const Center(
                        child: CircularProgressIndicator(color: AppTheme.red)),
                  ],
                  const SizedBox(height: 30),
                  _buildRecommandations(film),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(FilmModel film) {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      stretch: true,
      backgroundColor: AppTheme.primary,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black45,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 16),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        AnimatedBuilder(
          animation: _favScaleAnim,
          builder: (context, child) => Transform.scale(
            scale: _favScaleAnim.value,
            child: child,
          ),
          child: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(10),
              ),
              child: _loadingFavori
                  ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    color: AppTheme.red, strokeWidth: 2),
              )
                  : Icon(
                _isFavori ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
                color: _isFavori ? AppTheme.red : Colors.white,
                size: 20,
              ),
            ),
            onPressed: () => _toggleFavori(film),
          ),
        ),
        const SizedBox(width: 6),
      ],
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        background: Stack(
          fit: StackFit.expand,
          children: [
            film.backdropUrl != null
                ? Hero(
              tag: 'backdrop_${film.tmdbId}',
              child: Image.network(
                film.backdropUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: AppTheme.primary,
                  child: const Icon(Icons.movie, color: AppTheme.red, size: 60),
                ),
              ),
            )
                : Container(
              color: AppTheme.primary,
              child: const Icon(Icons.movie, color: AppTheme.red, size: 60),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.4, 1.0],
                  colors: [Colors.transparent, Colors.black],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPosterAndInfo(FilmModel film) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: film.posterUrl != null
              ? Image.network(
            film.posterUrl!,
            width: 110,
            height: 165,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _posterPlaceholder(),
          )
              : _posterPlaceholder(),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                film.titre,
                style: const TextStyle(
                    color: AppTheme.textLight,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    height: 1.2),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      double.tryParse(film.note)?.toStringAsFixed(1) ?? film.note,
                      style: const TextStyle(
                          color: Colors.amber,
                          fontWeight: FontWeight.bold,
                          fontSize: 13),
                    ),
                    Text(' / 10',
                        style: TextStyle(
                            color: Colors.amber.withOpacity(0.6), fontSize: 11)),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              if (film.duree.isNotEmpty)
                _infoRow(Icons.access_time_rounded, film.duree),
              if (film.dateSortie.isNotEmpty) ...[
                const SizedBox(height: 6),
                _infoRow(Icons.calendar_today_rounded, film.dateSortie),
              ],
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: film.genres.take(3).map((g) => _genreChip(_getGenreName(g))).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.textGrey, size: 14),
        const SizedBox(width: 5),
        Text(text, style: const TextStyle(color: AppTheme.textGrey, fontSize: 13)),
      ],
    );
  }

  Widget _genreChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.red.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.red.withOpacity(0.3)),
      ),
      child: Text(label,
          style: const TextStyle(
              color: AppTheme.red, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildResumeBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: AppTheme.red.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.red.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          const Icon(Icons.history_rounded, color: AppTheme.red, size: 18),
          const SizedBox(width: 8),
          Text(
            'Reprendre depuis ${_formatDuration(_startPosition)}',
            style: const TextStyle(
                color: AppTheme.red, fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(FilmModel film) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _toggleFavori(film),
            icon: Icon(_isFavori ? Icons.favorite_rounded : Icons.favorite_outline_rounded),
            label: Text(_isFavori ? 'Retirer favori' : 'Ajouter favori'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _isFavori ? AppTheme.card : AppTheme.red,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _trailerUrl != null ? () => _openTrailer(film) : null,
            icon: Icon(
              _startPosition > 0 ? Icons.play_circle_fill_rounded : Icons.play_circle_outline_rounded,
              color: _trailerUrl != null ? AppTheme.blue : AppTheme.textGrey,
            ),
            label: Text(
              _loadingDetail
                  ? 'Chargement...'
                  : _trailerUrl != null
                  ? (_startPosition > 0 ? 'Reprendre' : 'Trailer')
                  : 'Pas de trailer',
              style: TextStyle(
                  color: _trailerUrl != null ? AppTheme.blue : AppTheme.textGrey),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                  color: _trailerUrl != null ? AppTheme.blue : AppTheme.textGrey),
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSynopsis(FilmModel film) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Synopsis',
            style: TextStyle(
                color: AppTheme.textLight, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(
          film.synopsis.isNotEmpty ? film.synopsis : 'Aucun synopsis disponible',
          style: TextStyle(
              color: AppTheme.textLight.withOpacity(0.7), fontSize: 14, height: 1.5),
        ),
      ],
    );
  }

  Widget _buildActeurs() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Acteurs Principaux',
            style: TextStyle(
                color: AppTheme.textLight, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        SizedBox(
          height: 124,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _acteurs.length,
            itemBuilder: (context, index) {
              final acteur = _acteurs[index];
              return Container(
                width: 80,
                margin: const EdgeInsets.only(right: 12),
                child: Column(
                  children: [
                    ClipOval(
                      child: acteur['photo'] != null
                          ? Image.network(
                        acteur['photo'],
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _avatarPlaceholder(acteur['nom']),
                      )
                          : _avatarPlaceholder(acteur['nom']),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      acteur['nom'] ?? '',
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: AppTheme.textLight, fontSize: 10, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      acteur['personnage'] ?? '',
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppTheme.textGrey, fontSize: 9),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// ✅ Section "Recommandé pour vous" intégrée à la fiche détail.
  /// Réutilise l'endpoint de recommandations global (basé sur les genres
  /// des favoris de l'utilisateur), filtré ici pour ne pas réafficher
  /// le film actuellement consulté.
  Widget _buildRecommandations(FilmModel filmActuel) {
    if (_loadingRecos) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.red));
    }

    final recos = _recommandations
        .where((f) => f.tmdbId != filmActuel.tmdbId)
        .take(10)
        .toList();

    if (recos.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Icon(Icons.auto_awesome_rounded, color: AppTheme.red, size: 18),
            SizedBox(width: 8),
            Text('Recommandé pour vous',
                style: TextStyle(
                    color: AppTheme.textLight, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 210,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: recos.length,
            itemBuilder: (context, index) {
              final film = recos[index];
              return GestureDetector(
                onTap: () {
                  // Remplace l'écran actuel plutôt que d'empiler indéfiniment
                  Navigator.pushReplacementNamed(context, '/film', arguments: film);
                },
                child: Container(
                  width: 130,
                  margin: const EdgeInsets.only(right: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: film.posterUrl != null
                              ? Image.network(
                            film.posterUrl!,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _posterPlaceholder(),
                          )
                              : _posterPlaceholder(),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        film.titre,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: AppTheme.textLight, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, color: Colors.amber, size: 12),
                          const SizedBox(width: 3),
                          Text(
                            double.tryParse(film.note)?.toStringAsFixed(1) ?? film.note,
                            style: const TextStyle(color: AppTheme.textGrey, fontSize: 11),
                          ),
                        ],
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

  Widget _posterPlaceholder() => Container(
    color: AppTheme.primary,
    child: const Center(child: Icon(Icons.movie, color: AppTheme.red, size: 32)),
  );

  Widget _avatarPlaceholder(String? nom) {
    return Container(
      width: 60,
      height: 60,
      color: AppTheme.primary,
      child: Center(
        child: Text(
          (nom ?? 'A')[0].toUpperCase(),
          style: const TextStyle(color: AppTheme.red, fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}