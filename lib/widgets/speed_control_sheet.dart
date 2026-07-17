import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/colors.dart';
import '../../providers/player_provider.dart';

class SpeedControlSheet extends StatelessWidget {
  const SpeedControlSheet({super.key});

  static const List<double> _speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];
  static const List<String> _labels = ['0.5×', '0.75×', '1×', '1.25×', '1.5×', '1.75×', '2×'];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final playerProvider = Provider.of<PlayerProvider>(context);
    final currentSpeed = playerProvider.speed;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
          decoration: BoxDecoration(
            color: isDark ? Colors.black.withValues(alpha: 0.9) : Colors.white.withValues(alpha: 0.95),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),

              // Title
              Row(
                children: [
                  const Icon(Icons.speed_rounded, color: AppColors.primary, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    'Playback Speed',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // Speed chips grid
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: List.generate(_speeds.length, (i) {
                  final speed = _speeds[i];
                  final isSelected = (currentSpeed - speed).abs() < 0.01;
                  return GestureDetector(
                    onTap: () {
                      playerProvider.setSpeed(speed);
                      Navigator.pop(context);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 80,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? const LinearGradient(
                                colors: [AppColors.primary, AppColors.neonPurple],
                              )
                            : null,
                        color: isSelected
                            ? null
                            : (isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : Colors.black.withValues(alpha: 0.05)),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ? Colors.transparent
                              : Colors.grey.withValues(alpha: 0.25),
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          _labels[i],
                          style: TextStyle(
                            color: isSelected ? Colors.white : (isDark ? Colors.white : Colors.black),
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 28),

              // Current speed indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.play_arrow_rounded, color: AppColors.primary, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Current speed: ${currentSpeed}×',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
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
  }
}
