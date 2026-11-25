// lib/presentation/screens/catalogue/video_player_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/film_catalogue_model.dart';
import '../../../data/services/catalogue_service.dart';

class VideoPlayerScreen extends StatefulWidget {
  final FilmCatalogueModel film;
  const VideoPlayerScreen({super.key, required this.film});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _initializing = true;
  bool _error = false;
  int _savedPosition = 0;

  bool _isFavori = false;
  bool _loadingFavori = false;

  String get _cleStorage => 'video_pos_${widget.film.id}';

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
      DeviceOrientation.portraitUp,
    ]);
    _initPlayer();
    _chargerFavori();
  }

  @override
  void dispose() {
    _sauvegarderPosition();
    _videoController?.removeListener(_onVideoChange);
    _chewieController?.dispose();
    _videoController?.dispose();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  Future<Map<String, String>> _getAuthHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    return {
      if (token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Future<void> _chargerFavori() async {
    final fav = await CatalogueService.isFavori(widget.film.id);
    if (mounted) setState(() => _isFavori = fav);
  }

  Future<void> _toggleFavori() async {
    setState(() => _loadingFavori = true);
    final nouveauStatut = await CatalogueService.toggleFavori(widget.film.id);
    if (mounted) {
      setState(() {
        _isFavori = nouveauStatut;
        _loadingFavori = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isFavori ? 'Ajouté aux favoris ❤️' : 'Retiré des favoris'),
          backgroundColor: _isFavori ? AppTheme.red : Colors.grey,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _initPlayer() async {
    _chewieController?.dispose();
    _videoController?.removeListener(_onVideoChange);
    _videoController?.dispose();
    _chewieController = null;
    _videoController = null;

    try {
      final prefs = await SharedPreferences.getInstance();
      _savedPosition = prefs.getInt(_cleStorage) ?? 0;
      debugPrint('▶️ [Video] ${widget.film.titre} reprise à ${_savedPosition}s');

      final videoUrl = CatalogueService.getVideoUrl(widget.film.id);
      debugPrint('▶️ [Video] URL: $videoUrl');

      final headers = await _getAuthHeaders();

      _videoController = VideoPlayerController.networkUrl(
        Uri.parse(videoUrl),
        httpHeaders: headers,
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: false),
      );

      await _videoController!.initialize();

      if (_savedPosition > 0) {
        await _videoController!.seekTo(Duration(seconds: _savedPosition));
      }

      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: true,
        looping: false,
        allowFullScreen: true,
        allowMuting: true,
        showControls: true,
        materialProgressColors: ChewieProgressColors(
          playedColor: AppTheme.red,
          handleColor: AppTheme.red,
          bufferedColor: AppTheme.red.withOpacity(0.3),
          backgroundColor: Colors.white.withOpacity(0.2),
        ),
        placeholder: Container(color: Colors.black),
        errorBuilder: (ctx, msg) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: AppTheme.red, size: 50),
              const SizedBox(height: 12),
              Text(msg,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      );

      _videoController!.addListener(_onVideoChange);

      if (mounted) {
        setState(() {
          _initializing = false;
          _error = false;
        });
      }
      CatalogueService.enregistrerVue(widget.film.id);
    } catch (e) {
      debugPrint('❌ [Video] Erreur init: $e');
      if (mounted) {
        setState(() {
          _initializing = false;
          _error = true;
        });
      }
    }
  }

  void _onVideoChange() {
    if (_videoController == null) return;
    final value = _videoController!.value;

    if (!value.isPlaying && value.position.inSeconds > 5) {
      _sauvegarderPosition();
    }

    final duree = value.duration.inSeconds;
    final pos   = value.position.inSeconds;
    if (duree > 0 && pos >= (duree * 0.95).toInt()) {
      _effacerPosition();
    }
  }

  Future<void> _sauvegarderPosition() async {
    if (_videoController == null) return;
    try {
      final pos   = _videoController!.value.position.inSeconds;
      final duree = _videoController!.value.duration.inSeconds;
      if (pos <= 3) return;

      final prefs = await SharedPreferences.getInstance();
      if (duree > 0 && pos >= (duree * 0.95).toInt()) {
        await prefs.remove(_cleStorage);
        debugPrint('💾 [Video] Film terminé, position effacée');
      } else {
        await prefs.setInt(_cleStorage, pos);
        debugPrint('💾 [Video] Position sauvegardée: ${pos}s');
      }
    } catch (e) {
      debugPrint('❌ [Video] Erreur sauvegarde: $e');
    }
  }

  Future<void> _effacerPosition() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cleStorage);
    } catch (_) {}
  }

  String _formatDuration(int seconds) {
    if (seconds < 60) return '${seconds}s';
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return s > 0 ? '${m}m ${s}s' : '${m}m';
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (!didPop) {
          await _sauvegarderPosition();
          if (mounted) Navigator.pop(context);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Column(
            children: [

              // ── Barre top ────────────────────────────────
              Container(
                color: Colors.black,
                padding: const EdgeInsets.symmetric(
                    horizontal: 4, vertical: 4),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back,
                          color: Colors.white, size: 24),
                      onPressed: () async {
                        await _sauvegarderPosition();
                        if (mounted) Navigator.pop(context);
                      },
                    ),
                    Expanded(
                      child: Text(
                        widget.film.titre,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    if (widget.film.duree.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(widget.film.duree,
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 11)),
                      ),
                    IconButton(
                      icon: _loadingFavori
                          ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(
                            color: AppTheme.red, strokeWidth: 2),
                      )
                          : Icon(
                        _isFavori ? Icons.favorite : Icons.favorite_outline,
                        color: _isFavori ? AppTheme.red : Colors.white,
                        size: 22,
                      ),
                      onPressed: _toggleFavori,
                    ),
                  ],
                ),
              ),

              // ── Lecteur vidéo ─────────────────────────────
              Expanded(
                flex: 6,
                child: _initializing
                    ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: AppTheme.red),
                      SizedBox(height: 16),
                      Text('Chargement de la vidéo...',
                          style: TextStyle(
                              color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                )
                    : _error
                    ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            color: AppTheme.red, size: 60),
                        const SizedBox(height: 16),
                        const Text(
                          'Impossible de charger la vidéo',
                          style: TextStyle(
                              color: Colors.white, fontSize: 15),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Vérifiez votre connexion au serveur',
                          style: TextStyle(
                              color: Colors.white54, fontSize: 12),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              _initializing = true;
                              _error = false;
                            });
                            _initPlayer();
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Réessayer'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                BorderRadius.circular(10)),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                    : Chewie(controller: _chewieController!),
              ),

              // ── Infos film en bas ─────────────────────────
              Container(
                color: const Color(0xFF0D0D0D),
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_savedPosition > 0 && !_initializing && !_error)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: AppTheme.red.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: AppTheme.red.withOpacity(0.35)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.history,
                                color: AppTheme.red, size: 15),
                            const SizedBox(width: 8),
                            Text(
                              'Reprise à ${_formatDuration(_savedPosition)}',
                              style: const TextStyle(
                                  color: AppTheme.red,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12),
                            ),
                          ],
                        ),
                      ),

                    if (widget.film.synopsis.isNotEmpty)
                      Text(
                        widget.film.synopsis,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 12,
                            height: 1.4),
                      ),

                    const SizedBox(height: 6),

                    Row(
                      children: [
                        if (widget.film.note.isNotEmpty) ...[
                          const Icon(Icons.star,
                              color: Colors.amber, size: 13),
                          const SizedBox(width: 3),
                          Text(
                            double.tryParse(widget.film.note)
                                ?.toStringAsFixed(1) ??
                                widget.film.note,
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 11),
                          ),
                          const SizedBox(width: 10),
                        ],
                        ...widget.film.genres.take(3).map((g) =>
                            Container(
                              margin: const EdgeInsets.only(right: 6),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.red.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                    color: AppTheme.red.withOpacity(0.3)),
                              ),
                              child: Text(g,
                                  style: const TextStyle(
                                      color: AppTheme.red,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500)),
                            )),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}