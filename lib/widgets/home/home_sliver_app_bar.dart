import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/colors.dart';
import '../../providers/music_provider.dart';
import '../../providers/user_provider.dart';
import '../../screens/admin/admin_dashboard_screen.dart';
import '../../screens/home/search_screen.dart';

class HomeSliverAppBar extends StatelessWidget {
  final bool isAdmin;
  final bool isDark;
  final TabController tabController;
  final String greeting;
  final GlobalKey<ScaffoldState>? scaffoldKey;

  const HomeSliverAppBar({
    super.key,
    required this.isAdmin,
    required this.isDark,
    required this.tabController,
    required this.greeting,
    this.scaffoldKey,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SliverAppBar(
      expandedHeight: 300,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      automaticallyImplyLeading: false,
      leading: MediaQuery.of(context).size.width < 600
          ? IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.5)
                      : Colors.white.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.menu_rounded, size: 22),
              ),
              onPressed: () {
                scaffoldKey?.currentState?.openDrawer();
              },
            )
          : null,
      actions: [
        if (isAdmin)
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.teal.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.teal.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: IconButton(
              icon: const Icon(Icons.data_object),
              color: Colors.teal,
              tooltip: 'Desktop Music JSON Manager',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdminDashboardScreen(),
                ),
              ),
            ),
          ),
        // Search Button
        Container(
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: IconButton(
            icon: const Icon(Icons.search_rounded),
            color: AppColors.primary,
            tooltip: 'Search',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SearchScreen(),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          children: [
            // Animated gradient background with mesh effect
            Container(
              decoration: BoxDecoration(
                gradient: isDark
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.backgroundDark,
                          AppColors.surfaceDark,
                          AppColors.primary.withValues(alpha: 0.1),
                        ],
                      )
                    : LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.backgroundLight,
                          AppColors.surfaceLight,
                          AppColors.primary.withValues(alpha: 0.05),
                        ],
                      ),
              ),
            ),

            // Animated wave pattern overlay
            Positioned.fill(
              child: CustomPaint(
                painter: WavePainter(
                  color: AppColors.primary.withValues(alpha: 0.08),
                ),
              ),
            ),

            // Welcome message & user stats
            Positioned(
              left: 20,
              top: kToolbarHeight + 40,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Greeting
                  Text(
                    greeting,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // User name
                  Consumer<UserProvider>(
                    builder: (context, userProvider, _) {
                      final name = userProvider.profile['name'] ??
                          userProvider.user?.displayName ??
                          userProvider.user?.email?.split('@')[0] ??
                          'Music Lover';
                      return Text(
                        name,
                        style: theme.textTheme.displayMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 32,
                          height: 1.2,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // Library stats pill
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.library_music_rounded,
                          size: 18,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Consumer<HomeProvider>(
                          builder: (context, homeProvider, _) {
                            return Text(
                              '${homeProvider.totalSongs} songs • ${homeProvider.totalPlaylists} playlists',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Decorative blurred circles with glow effect
            Positioned(
              right: -50,
              top: -50,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.3),
                      AppColors.neonPurple.withValues(alpha: 0.15),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Second decorative circle
            Positioned(
              left: -30,
              bottom: -30,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.neonCyan.withValues(alpha: 0.2),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.5)
                    : Colors.white.withValues(alpha: 0.6),
                border: Border(
                  bottom: BorderSide(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.05),
                  ),
                ),
              ),
          child: TabBar(
            controller: tabController,
            indicator: const UnderlineTabIndicator(
              borderSide: BorderSide(
                color: AppColors.primary,
                width: 3,
              ),
              insets: EdgeInsets.symmetric(horizontal: 16),
            ),
            labelColor: AppColors.primary,
            unselectedLabelColor: isDark ? Colors.grey[400] : Colors.grey[600],
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
            tabs: const [
              Tab(text: 'For You'),
              Tab(text: 'New Hits'),
              Tab(text: 'Charts'),
              Tab(text: 'Genres'),
            ],
          ),
        ),
      ),
      ),
      ),
    );
  }
}

// WavePainter is now in this file for encapsulation
class WavePainter extends CustomPainter {
  final Color color;

  WavePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height * 0.7);
    
    // Create a smooth wave effect
    path.quadraticBezierTo(
      size.width * 0.25, 
      size.height * 0.6, 
      size.width * 0.5, 
      size.height * 0.75
    );
    path.quadraticBezierTo(
      size.width * 0.75, 
      size.height * 0.9, 
      size.width, 
      size.height * 0.7
    );
    
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
