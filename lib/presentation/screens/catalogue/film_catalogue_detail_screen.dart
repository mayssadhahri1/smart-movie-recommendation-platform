import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/film_catalogue_model.dart';
import '../../../data/services/catalogue_service.dart';
import 'video_player_screen.dart';

class FilmCatalogueDetailScreen extends StatefulWidget {
  final FilmCatalogueModel film;
  const FilmCatalogueDetailScreen({super.key, required this.film});

  @override
  State<FilmCatalogueDetailScreen> createState() =>
      _FilmCatalogueDetailScreenState();
}

class _FilmCatalogueDetailScreenState extends State<FilmCatalogueDetailScreen>
    with SingleTickerProviderStateMixin {
  bool _isFavori = false;
  bool _loadingFavori = true;

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

    _chargerFavori();
  }

  @override
  void dispose() {
    _favAnimController.dispose();
    super.dispose();
  }

  Future<void> _chargerFavori() async {
    final fav = await CatalogueService.isFavori(widget.film.id);
    if (mounted) {
      setState(() {
        _isFavori = fav;
        _loadingFavori = false;
      });
    }
  }

  Future<void> _toggleFavori() async {
    final etatAvant = _isFavori;
    setState(() => _loadingFavori = true);

    try {
      final nouveauStatut = await CatalogueService.toggleFavori(widget.film.id);
      _favAnimController.forward(from: 0);

      if (mounted) {
        setState(() {
          _isFavori = nouveauStatut;
          _loadingFavori = false;
        });
        _showSnack(
          nouveauStatut ? 'Film ajouté aux favoris' : 'Film retiré des favoris',
          nouveauStatut ? AppTheme.red : AppTheme.textGrey,
          nouveauStatut ? Icons.favorite_rounded : Icons.favorite_border_rounded,
        );
      }
    } catch (e) {
      // ✅ En cas d'erreur réseau/serveur, on NE CHANGE PAS l'état affiché
      // (le cœur reste tel qu'il était avant le clic) et on prévient
      // clairement l'utilisateur au lieu de lui montrer un faux statut.
      if (mounted) {
        setState(() {
          _isFavori = etatAvant;
          _loadingFavori = false;
        });
        _showSnack(
          'Impossible de mettre à jour les favoris',
          AppTheme.red,
          Icons.error_outline_rounded,
        );
      }
    }
  }

  void _showSnack(String msg, Color color, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
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
      ),
    );
  }

  void _regarder() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VideoPlayerScreen(film: widget.film),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final film = widget.film;

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
                  _buildActionButtons(film),
                  const SizedBox(height: 24),
                  _buildStats(film),
                  const SizedBox(height: 24),
                  const Text('Synopsis',
                      style: TextStyle(
                          color: AppTheme.textLight,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    film.synopsis.isNotEmpty
                        ? film.synopsis
                        : 'Aucun synopsis disponible',
                    style: TextStyle(
                        color: AppTheme.textLight.withOpacity(0.7),
                        fontSize: 14,
                        height: 1.5),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(FilmCatalogueModel film) {
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
          builder: (context, child) =>
              Transform.scale(scale: _favScaleAnim.value, child: child),
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
            onPressed: _loadingFavori ? null : _toggleFavori,
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
                ? Image.network(
              film.backdropUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _backdropPlaceholder(),
            )
                : _backdropPlaceholder(),
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
            if (film.videoDisponible)
              Positioned(
                top: 16,
                left: 60,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.red,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.play_arrow_rounded, color: Colors.white, size: 12),
                      SizedBox(width: 3),
                      Text('DISPONIBLE',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPosterAndInfo(FilmCatalogueModel film) {
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
              if (film.note.isNotEmpty)
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
                children: film.genres.take(3).map(_genreChip).toList(),
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

  Widget _buildActionButtons(FilmCatalogueModel film) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _loadingFavori ? null : _toggleFavori,
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
          child: ElevatedButton.icon(
            onPressed: film.videoDisponible ? _regarder : null,
            icon: const Icon(Icons.play_circle_fill_rounded),
            label: Text(film.videoDisponible ? 'Regarder' : 'Indisponible'),
            style: ElevatedButton.styleFrom(
              backgroundColor: film.videoDisponible ? AppTheme.blue : AppTheme.card,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppTheme.card,
              disabledForegroundColor: AppTheme.textGrey,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStats(FilmCatalogueModel film) {
    return Row(
      children: [
        _statChip(Icons.visibility_rounded, '${film.nombreVues} vues'),
        const SizedBox(width: 10),
        _statChip(Icons.favorite_rounded, '${film.nombreFavoris} favoris'),
      ],
    );
  }

  Widget _statChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppTheme.textGrey, size: 14),
          const SizedBox(width: 5),
          Text(label, style: const TextStyle(color: AppTheme.textGrey, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _backdropPlaceholder() => Container(
    color: AppTheme.primary,
    child: const Center(child: Icon(Icons.movie, color: AppTheme.red, size: 60)),
  );

  Widget _posterPlaceholder() => Container(
    color: AppTheme.primary,
    child: const Center(child: Icon(Icons.movie, color: AppTheme.red, size: 32)),
  );
}