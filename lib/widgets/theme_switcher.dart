import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/colors.dart';
import '../../providers/theme_provider.dart';

class ThemeSwitcherWidget extends StatelessWidget {
  const ThemeSwitcherWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Appearance',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.07) : Colors.black.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
          ),
          child: Row(
            children: [
              _ThemeOption(
                icon: Icons.light_mode_rounded,
                label: 'Light',
                isSelected: themeProvider.themeMode == AppTheme.light,
                onTap: () => themeProvider.setTheme(AppTheme.light),
                isDark: isDark,
              ),
              _ThemeOption(
                icon: Icons.dark_mode_rounded,
                label: 'Dark',
                isSelected: themeProvider.themeMode == AppTheme.dark,
                onTap: () => themeProvider.setTheme(AppTheme.dark),
                isDark: isDark,
              ),
              _ThemeOption(
                icon: Icons.phone_android_rounded,
                label: 'System',
                isSelected: themeProvider.themeMode == AppTheme.system,
                onTap: () => themeProvider.setTheme(AppTheme.system),
                isDark: isDark,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;

  const _ThemeOption({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.all(2),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                    colors: [AppColors.primary, AppColors.neonPurple],
                  )
                : null,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.grey[400] : Colors.grey[600]),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? Colors.white
                      : (isDark ? Colors.grey[400] : Colors.grey[600]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
