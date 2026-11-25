import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/services/film_service.dart';
import '../../../data/services/auth_service.dart';

class ProfilScreen extends StatefulWidget {
  const ProfilScreen({super.key});

  @override
  State<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen> {
  Map<String, dynamic>? profil;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final p = await FilmService.getProfil();
      setState(() {
        profil = p;
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
    }
  }

  Future<void> _logout() async {
    await AuthService.logout();
    if (mounted) Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Mon Profil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppTheme.red),
            onPressed: _logout,
          ),
        ],
      ),
      body: loading
          ? const Center(
          child: CircularProgressIndicator(color: AppTheme.red))
          : profil == null
          ? const Center(
          child: Text('Erreur de chargement',
              style: TextStyle(color: AppTheme.textGrey)))
          : RefreshIndicator(
        onRefresh: _load,
        color: AppTheme.red,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // ── Avatar ──────────────────────────────
              Container(
                width: 90,
                height: 90,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.red, Color(0xFFc62828)],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    (profil!['nom'] ?? 'U')[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // ── Nom & Email ──────────────────────────
              Text(
                profil!['nom'] ?? '',
                style: const TextStyle(
                  color: AppTheme.textLight,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                profil!['email'] ?? '',
                style: const TextStyle(
                  color: AppTheme.textGrey,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 6),

              // ── Badge rôle ───────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.red.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: AppTheme.red.withOpacity(0.3)),
                ),
                child: Text(
                  profil!['role'] ?? 'CLIENT',
                  style: const TextStyle(
                    color: AppTheme.red,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ── Stats ────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: _StatBox(
                      icon: Icons.favorite,
                      color: AppTheme.red,
                      value:
                      '${profil!['totalFavoris'] ?? 0}',
                      label: 'Favoris',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatBox(
                      icon: Icons.visibility,
                      color: Colors.blue,
                      value:
                      '${profil!['totalConsultations'] ?? 0}',
                      label: 'Consultations',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ── Genres préférés ──────────────────────
              if (profil!['genresPreferes'] != null &&
                  (profil!['genresPreferes'] as List)
                      .isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.card,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '🎭 Genres Préférés',
                        style: TextStyle(
                          color: AppTheme.textLight,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: (profil!['genresPreferes']
                        as List)
                            .map((g) => Container(
                          padding:
                          const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.red
                                .withOpacity(0.15),
                            borderRadius:
                            BorderRadius.circular(
                                20),
                            border: Border.all(
                                color: AppTheme.red
                                    .withOpacity(0.3)),
                          ),
                          child: Text(
                            g.toString(),
                            style: const TextStyle(
                              color: AppTheme.red,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ))
                            .toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // ── Infos dates ──────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.card,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _InfoRow(
                      icon: Icons.calendar_today,
                      label: 'Inscription',
                      value: _formatDate(
                          profil!['dateInscription']),
                    ),
                    const Divider(
                        color: AppTheme.primary, height: 20),
                    _InfoRow(
                      icon: Icons.access_time,
                      label: 'Dernière connexion',
                      value: _formatDate(
                          profil!['derniereConnexion']),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Bouton déconnexion ───────────────────
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout,
                      color: AppTheme.red),
                  label: const Text(
                    'Se déconnecter',
                    style: TextStyle(color: AppTheme.red),
                  ),
                  style: OutlinedButton.styleFrom(
                    side:
                    const BorderSide(color: AppTheme.red),
                    padding: const EdgeInsets.symmetric(
                        vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return '—';
    try {
      final d = DateTime.parse(date.toString());
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    } catch (_) {
      return date.toString();
    }
  }
}

// ── Widgets ─────────────────────────────────────────────────

class _StatBox extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;

  const _StatBox({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
                color: AppTheme.textGrey, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.textGrey, size: 16),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
              color: AppTheme.textGrey, fontSize: 13),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            color: AppTheme.textLight,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}