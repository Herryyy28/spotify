import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/music_provider.dart';
import '../../models/song_model.dart';
import '../../core/theme/colors.dart';

class AdminDashboardTab extends StatelessWidget {
  final bool isDark;
  final Function(int) onNavigate;
  final bool isLoadingAction;
  final Widget Function(Song, bool, {bool showActions}) buildSongTile;

  const AdminDashboardTab({
    super.key,
    required this.isDark,
    required this.onNavigate,
    required this.isLoadingAction,
    required this.buildSongTile,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeProvider>(
      builder: (context, musicProvider, _) {
        final totalSongs = musicProvider.allSongs.length;
        return SingleChildScrollView(
          key: const ValueKey('dashboard'),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF1DB954),
                      Color(0xFF1AA34A),
                      Color(0xFF15803D)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 30,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.waving_hand, color: Colors.amber, size: 28),
                        SizedBox(width: 12),
                        Text(
                          'Welcome back, Admin!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Manage your music library. Songs you add here will instantly sync to all mobile app users in real-time.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Stats row
              LayoutBuilder(
                builder: (context, constraints) {
                  final cardWidth = constraints.maxWidth > 700
                      ? (constraints.maxWidth - 48) / 4
                      : (constraints.maxWidth - 16) / 2;
                  return Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      _buildStatCard(
                          'Total Songs',
                          '$totalSongs',
                          Icons.music_note_rounded,
                          const Color(0xFF8B5CF6),
                          cardWidth,
                          isDark),
                      _buildStatCard(
                          'Firebase Songs',
                          '$totalSongs',
                          Icons.cloud_done_rounded,
                          const Color(0xFF1DB954),
                          cardWidth,
                          isDark),
                      _buildStatCard('Sync Status', 'Live', Icons.sync_rounded,
                          const Color(0xFF06B6D4), cardWidth, isDark),
                      _buildStatCard(
                          'Quality',
                          '320kbps',
                          Icons.high_quality_rounded,
                          const Color(0xFFF97316),
                          cardWidth,
                          isDark),
                    ],
                  );
                },
              ),
              const SizedBox(height: 28),

              // Quick Actions
              const Text(
                'Quick Actions',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3),
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 600;
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _buildQuickAction(
                        'Add Single Song',
                        Icons.add_rounded,
                        const Color(0xFF8B5CF6),
                        () => onNavigate(1),
                        isWide ? 220.0 : constraints.maxWidth,
                        isDark,
                      ),

                      _buildQuickAction(
                        'Manage Library',
                        Icons.library_music_rounded,
                        const Color(0xFFF97316),
                        () => onNavigate(3),
                        isWide ? 220.0 : constraints.maxWidth,
                        isDark,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 28),

              // Recent Songs
              const Text(
                'Recently Added',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3),
              ),
              const SizedBox(height: 12),
              if (musicProvider.allSongs.isEmpty)
                _buildEmptyState(isDark, 'No songs yet',
                    'Add songs manually using the Add Song tab')
              else
                ...musicProvider.allSongs
                    .take(5)
                    .map((song) => buildSongTile(song, isDark, showActions: true)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color,
      double width, bool isDark) {
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF16161E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.grey.withValues(alpha: 0.1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 14),
            Text(
              value,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : Colors.black87,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction(String label, IconData icon, Color color,
      VoidCallback onTap, double width, bool isDark) {
    return SizedBox(
      width: width,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: isLoadingAction ? null : onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF16161E) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: color.withValues(alpha: 0.2),
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    color: Colors.grey[400], size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark, String title, String subtitle) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF16161E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.grey.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: [
          Icon(Icons.library_music_outlined,
              size: 48,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.2)
                  : Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}
