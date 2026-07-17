import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/colors.dart';
import '../../providers/player_provider.dart';

class SleepTimerDialog extends StatefulWidget {
  const SleepTimerDialog({super.key});

  @override
  State<SleepTimerDialog> createState() => _SleepTimerDialogState();
}

class _SleepTimerDialogState extends State<SleepTimerDialog> {
  int? _selectedMinutes;
  final List<int> _presets = [15, 30, 45, 60, 90];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final playerProvider = Provider.of<PlayerProvider>(context);
    final isActive = playerProvider.sleepTimerRemaining != null;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.black.withValues(alpha: 0.85)
                : Colors.white.withValues(alpha: 0.9),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),

              // Title row
              Row(
                children: [
                  const Icon(Icons.bedtime_rounded, color: AppColors.primary, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    'Sleep Timer',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const Spacer(),
                  if (isActive)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        _formatRemaining(playerProvider.sleepTimerRemaining!),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 24),

              // Active timer cancellation
              if (isActive) ...[
                _buildActiveTimerCard(isDark, playerProvider),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 12),
                Text(
                  'Change Timer',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Preset grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 2.2,
                ),
                itemCount: _presets.length,
                itemBuilder: (_, i) => _buildPresetChip(_presets[i], isDark, playerProvider),
              ),

              const SizedBox(height: 20),

              // End of song option
              _buildOptionTile(
                icon: Icons.music_note_rounded,
                label: 'After current song',
                isDark: isDark,
                onTap: () {
                  playerProvider.setSleepTimerAfterSong();
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveTimerCard(bool isDark, PlayerProvider playerProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.1),
            AppColors.neonPurple.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.timer_rounded, color: AppColors.primary, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Timer active',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'Stops in ${_formatRemaining(playerProvider.sleepTimerRemaining!)}',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: () {
              playerProvider.cancelSleepTimer();
              Navigator.pop(context);
            },
            icon: const Icon(Icons.close, size: 16),
            label: const Text('Cancel'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetChip(int minutes, bool isDark, PlayerProvider playerProvider) {
    final isSelected = _selectedMinutes == minutes;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedMinutes = minutes);
        playerProvider.setSleepTimer(Duration(minutes: minutes));
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sleep timer set for $minutes minutes'),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          gradient: isSelected ? AppColors.spotifyGradient : null,
          color: isSelected ? null : (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.transparent : Colors.grey.withValues(alpha: 0.2),
          ),
        ),
        child: Center(
          child: Text(
            minutes >= 60 ? '${minutes ~/ 60}h' : '$minutes min',
            style: TextStyle(
              color: isSelected ? Colors.white : (isDark ? Colors.white : Colors.black),
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String label,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 20),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Icon(Icons.chevron_right, color: Colors.grey[500], size: 20),
          ],
        ),
      ),
    );
  }

  String _formatRemaining(Duration d) {
    if (d.inHours > 0) {
      return '${d.inHours}h ${d.inMinutes.remainder(60).toString().padLeft(2, '0')}m';
    }
    return '${d.inMinutes}:${d.inSeconds.remainder(60).toString().padLeft(2, '0')}';
  }
}
