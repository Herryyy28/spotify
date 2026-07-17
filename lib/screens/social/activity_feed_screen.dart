import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/colors.dart';
import '../../models/social_model.dart';
import '../../providers/social_provider.dart';
import '../../providers/player_provider.dart';
import '../../providers/user_provider.dart';

class ActivityFeedScreen extends StatelessWidget {
  const ActivityFeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final socialProvider = Provider.of<SocialProvider>(context);
    final playerProvider = Provider.of<PlayerProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    final recentlyPlayed = userProvider.recentlyPlayed;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 150,
            floating: false,
            pinned: true,
            backgroundColor: Colors.transparent,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.neonBlue, AppColors.neonCyan],
                  ),
                ),
                child: const SafeArea(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 0, 20, 16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.history_rounded, color: Colors.white, size: 28),
                        SizedBox(height: 8),
                        Text(
                          'Listening Activity',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // My recent plays
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
              child: Text(
                'Your Recent Plays',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ),
          ),

          if (recentlyPlayed.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.cardDark : AppColors.cardLight,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.music_note_rounded,
                          color: Colors.grey.withValues(alpha: 0.4), size: 32),
                      const SizedBox(width: 12),
                      Text(
                        'No recent plays yet',
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) {
                  final song = recentlyPlayed[i];
                  return _ActivityListTile(
                    isDark: isDark,
                    leading: _songThumbnail(song.coverUrl),
                    title: song.title,
                    subtitle: song.artist,
                    trailing: Text(
                      _indexToTimeLabel(i),
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                    typeIcon: Icons.play_arrow_rounded,
                    typeColor: AppColors.primary,
                    onTap: () => playerProvider.playSong(song),
                  );
                },
                childCount: recentlyPlayed.take(10).length,
              ),
            ),

          // Friends activity
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 28, 16, 12),
              child: Row(
                children: [
                  Text(
                    'Friends Activity',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => socialProvider.refreshActivity(),
                    child: const Text('Refresh', style: TextStyle(color: AppColors.primary)),
                  ),
                ],
              ),
            ),
          ),

          if (socialProvider.isLoading)
            const SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              ),
            )
          else if (socialProvider.friendsActivity.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.cardDark : AppColors.cardLight,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.people_outline_rounded,
                          size: 48, color: Colors.grey.withValues(alpha: 0.4)),
                      const SizedBox(height: 12),
                      Text(
                        'Follow friends to see their activity',
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) {
                  final activity = socialProvider.friendsActivity[i];
                  final typeData = _activityTypeData(activity.type);
                  return _ActivityListTile(
                    isDark: isDark,
                    leading: _avatarWidget(activity.userAvatar, activity.userName),
                    title: '${activity.userName} • ${activity.song.title}',
                    subtitle: '${typeData.$1} · ${activity.timeAgo}',
                    trailing: GestureDetector(
                      onTap: () => playerProvider.playSong(activity.song),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.play_arrow_rounded,
                            color: AppColors.primary, size: 20),
                      ),
                    ),
                    typeIcon: typeData.$2,
                    typeColor: typeData.$3,
                    onTap: () => playerProvider.playSong(activity.song),
                  );
                },
                childCount: socialProvider.friendsActivity.length,
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _songThumbnail(String? url) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: url != null
          ? Image.network(url, width: 48, height: 48, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _defaultThumb())
          : _defaultThumb(),
    );
  }

  Widget _defaultThumb() {
    return Container(
      width: 48,
      height: 48,
      color: AppColors.cardDark,
      child: const Icon(Icons.music_note_rounded, color: AppColors.primary, size: 24),
    );
  }

  Widget _avatarWidget(String? avatarUrl, String name) {
    return CircleAvatar(
      radius: 24,
      backgroundColor: AppColors.neonPurple.withValues(alpha: 0.2),
      backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
      child: avatarUrl == null
          ? Text(name[0].toUpperCase(),
              style: const TextStyle(color: AppColors.neonPurple, fontWeight: FontWeight.bold))
          : null,
    );
  }

  String _indexToTimeLabel(int i) {
    if (i == 0) return 'Just now';
    if (i == 1) return '5 min ago';
    if (i == 2) return '12 min ago';
    return '${i * 15} min ago';
  }

  (String, IconData, Color) _activityTypeData(ActivityType type) {
    return switch (type) {
      ActivityType.liked => ('Liked', Icons.favorite_rounded, Colors.red),
      ActivityType.shared => ('Shared', Icons.share_rounded, AppColors.neonBlue),
      ActivityType.addedToPlaylist => ('Added to playlist', Icons.playlist_add_rounded, AppColors.neonPurple),
      ActivityType.played => ('Played', Icons.play_arrow_rounded, AppColors.primary),
    };
  }
}

class _ActivityListTile extends StatelessWidget {
  final bool isDark;
  final Widget leading;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final IconData typeIcon;
  final Color typeColor;
  final VoidCallback? onTap;

  const _ActivityListTile({
    required this.isDark,
    required this.leading,
    required this.title,
    required this.subtitle,
    this.trailing,
    required this.typeIcon,
    required this.typeColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.cardLight,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            leading,
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(typeIcon, size: 11, color: typeColor),
                      const SizedBox(width: 4),
                      Text(
                        subtitle,
                        style: TextStyle(color: Colors.grey[500], fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}
