import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';
import '../providers/theme_provider.dart';
import '../core/theme/colors.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool automaticallyImplyLeading;
  final bool showThemeToggle;
  final bool showSearch;
  final VoidCallback? onSearchTap;

  const CustomAppBar({
    super.key,
    required this.title,
    this.actions,
    this.automaticallyImplyLeading = true,
    this.showThemeToggle = false,
    this.showSearch = false,
    this.onSearchTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode(context);

    return AppBar(
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      centerTitle: false,
      automaticallyImplyLeading: automaticallyImplyLeading,
      actions: [
        if (showSearch)
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: onSearchTap ?? () {
              Navigator.pushNamed(context, '/search');
            },
          ),
        if (showThemeToggle)
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode : Icons.dark_mode,
            ),
            onPressed: () => themeProvider.toggleTheme(),
          ),
        if (actions != null) ...actions!,
      ],
    );
  }
}

class AnimatedAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String title;
  final double scrollOffset;
  final List<Widget>? actions;
  final Widget? flexibleSpace;
  final double expandedHeight;

  const AnimatedAppBar({
    super.key,
    required this.title,
    required this.scrollOffset,
    this.actions,
    this.flexibleSpace,
    this.expandedHeight = 200,
  });

  @override
  Size get preferredSize => Size.fromHeight(expandedHeight);

  @override
  _AnimatedAppBarState createState() => _AnimatedAppBarState();
}

class _AnimatedAppBarState extends State<AnimatedAppBar> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SliverAppBar(
      expandedHeight: widget.expandedHeight,
      floating: false,
      pinned: true,
      elevation: widget.scrollOffset > 50 ? 4 : 0,
      backgroundColor: isDark
          ? AppColors.surfaceDark
          : AppColors.surfaceLight,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
        title: AnimatedOpacity(
          opacity: widget.scrollOffset > 100 ? 1 : 0,
          duration: const Duration(milliseconds: 200),
          child: Text(
            widget.title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        background: widget.flexibleSpace,
      ),
      actions: widget.actions,
    );
  }
}

class MiniPlayerAppBar extends StatelessWidget implements PreferredSizeWidget {
  const MiniPlayerAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(80);

  @override
  Widget build(BuildContext context) {
    final playerProvider = Provider.of<PlayerProvider>(context);
    final currentSong = playerProvider.currentSong;

    if (currentSong == null) return const SizedBox.shrink();

    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.pushNamed(context, '/player');
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    currentSong.coverUrl,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        currentSong.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        currentSong.artist,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    playerProvider.isPlaying ? Icons.pause : Icons.play_arrow,
                    color: AppColors.primary,
                  ),
                  onPressed: playerProvider.togglePlayPause,
                ),
                IconButton(
                  icon: const Icon(
                    Icons.skip_next,
                    color: AppColors.primary,
                  ),
                  onPressed: playerProvider.next,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}