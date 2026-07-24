import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/colors.dart';
import '../../models/social_model.dart';
import '../../models/song_model.dart';
import '../../providers/social_provider.dart';
import '../../providers/player_provider.dart';
import '../../providers/listening_room_provider.dart';
import '../../providers/user_provider.dart';
import 'listen_room_screen.dart';

class SocialFeedScreen extends StatefulWidget {
  const SocialFeedScreen({super.key});

  @override
  State<SocialFeedScreen> createState() => _SocialFeedScreenState();
}

class _SocialFeedScreenState extends State<SocialFeedScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final socialProvider = Provider.of<SocialProvider>(context);

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 160,
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
                    colors: [AppColors.neonPurple, AppColors.primary],
                  ),
                ),
                child: const SafeArea(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 0, 20, 16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.people_rounded, color: Colors.white, size: 32),
                        SizedBox(height: 8),
                        Text(
                          'Social',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold),
              tabs: const [
                Tab(text: 'Friends Activity'),
                Tab(text: 'Following'),
              ],
            ),
          ),

          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                _ActivityTab(socialProvider: socialProvider, isDark: isDark),
                _FollowingTab(socialProvider: socialProvider, isDark: isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityTab extends StatelessWidget {
  final SocialProvider socialProvider;
  final bool isDark;

  const _ActivityTab({required this.socialProvider, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final playerProvider = Provider.of<PlayerProvider>(context, listen: false);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildListeningRoomCard(context, isDark),
        const SizedBox(height: 16),
        if (socialProvider.friendsActivity.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Column(
              children: [
                Icon(Icons.people_outline_rounded,
                    size: 70, color: Colors.grey.withValues(alpha: 0.4)),
                const SizedBox(height: 12),
                Text(
                  'No friend activity yet',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Follow friends to see what they are listening to!',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          )
        else
          ...socialProvider.friendsActivity.map((act) => _ActivityCard(
                activity: act,
                isDark: isDark,
                onPlay: () => playerProvider.playSong(act.song),
              )),
      ],
    );
  }

  Widget _buildListeningRoomCard(BuildContext context, bool isDark) {
    final roomProvider = Provider.of<ListeningRoomProvider>(context);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final playerProvider = Provider.of<PlayerProvider>(context, listen: false);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.neonPurple, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.equalizer, color: Colors.white, size: 28),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Shared Listening Room',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Listen together with friends in real-time',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (roomProvider.isInRoom)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.greenAccent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('LIVE ACTIVE',
                      style: TextStyle(
                          color: Colors.black,
                          fontSize: 10,
                          fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    if (roomProvider.isInRoom) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const ListenRoomScreen()),
                      );
                    } else {
                      final song = playerProvider.currentSong ??
                          Song(
                            id: 'demo_song',
                            title: 'Blinding Lights',
                            artist: 'The Weeknd',
                            album: 'After Hours',
                            duration: '3:20',
                            durationInSeconds: 200,
                            audioUrl:
                                'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
                            coverUrl:
                                'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=500&q=80',
                            releaseDate: DateTime.now(),
                          );
                      final room = await roomProvider.createRoom(
                        song,
                        userProvider.user?.displayName ?? 'Host',
                      );
                      if (room != null && context.mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const ListenRoomScreen()),
                        );
                      }
                    }
                  },
                  icon: Icon(
                      roomProvider.isInRoom ? Icons.volume_up : Icons.add_call,
                      color: AppColors.primary),
                  label: Text(
                      roomProvider.isInRoom ? 'Open Room' : 'Create Room',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showJoinDialog(context),
                  icon: const Icon(Icons.key, color: Colors.white),
                  label: const Text('Join Code',
                      style: TextStyle(color: Colors.white)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white70),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showJoinDialog(BuildContext context) {
    final controller = TextEditingController();
    final roomProvider = Provider.of<ListeningRoomProvider>(context, listen: false);
    final playerProvider = Provider.of<PlayerProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Join Listening Room'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter Room Code (e.g. ROOM-4829)',
            prefixIcon: Icon(Icons.tag),
          ),
          textCapitalization: TextCapitalization.characters,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () async {
              final code = controller.text.trim();
              if (code.isNotEmpty) {
                Navigator.pop(dialogCtx);
                final success = await roomProvider.joinRoom(code, playerProvider);
                if (context.mounted) {
                  if (success) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const ListenRoomScreen()),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text('Room "$code" not found.'),
                          backgroundColor: Colors.redAccent),
                    );
                  }
                }
              }
            },
            child: const Text('Join'),
          ),
        ],
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final UserActivity activity;
  final bool isDark;
  final VoidCallback onPlay;

  const _ActivityCard({
    required this.activity,
    required this.isDark,
    required this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    final typeIcon = switch (activity.type) {
      ActivityType.liked => Icons.favorite_rounded,
      ActivityType.shared => Icons.share_rounded,
      ActivityType.addedToPlaylist => Icons.playlist_add_rounded,
      ActivityType.played => Icons.play_arrow_rounded,
    };
    final typeColor = switch (activity.type) {
      ActivityType.liked => Colors.red,
      ActivityType.shared => AppColors.neonBlue,
      ActivityType.addedToPlaylist => AppColors.neonPurple,
      ActivityType.played => AppColors.primary,
    };

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.primary.withValues(alpha: 0.2),
            backgroundImage: activity.userAvatar != null
                ? NetworkImage(activity.userAvatar!)
                : null,
            child: activity.userAvatar == null
                ? Text(
                    activity.userName[0].toUpperCase(),
                    style: const TextStyle(
                        color: AppColors.primary, fontWeight: FontWeight.bold),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                      fontSize: 13,
                    ),
                    children: [
                      TextSpan(
                        text: activity.userName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const TextSpan(text: ' is listening to '),
                      TextSpan(
                        text: activity.song.title,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  activity.song.artist,
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(typeIcon, size: 12, color: typeColor),
                    const SizedBox(width: 4),
                    Text(
                      activity.timeAgo,
                      style: TextStyle(color: Colors.grey[500], fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Play button
          GestureDetector(
            onTap: onPlay,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: const Icon(Icons.play_arrow_rounded,
                  color: AppColors.primary, size: 22),
            ),
          ),
        ],
      ),
    );
  }
}

class _FollowingTab extends StatelessWidget {
  final SocialProvider socialProvider;
  final bool isDark;

  const _FollowingTab({required this.socialProvider, required this.isDark});

  @override
  Widget build(BuildContext context) {
    if (socialProvider.following.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_add_alt_1_rounded,
                size: 80, color: Colors.grey.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text(
              'Not following anyone',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: socialProvider.following.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final friend = socialProvider.following[i];
        return _FriendTile(friend: friend, isDark: isDark);
      },
    );
  }
}

class _FriendTile extends StatelessWidget {
  final FriendProfile friend;
  final bool isDark;

  const _FriendTile({required this.friend, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final socialProvider = Provider.of<SocialProvider>(context, listen: false);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.neonPurple.withValues(alpha: 0.2),
                backgroundImage: friend.avatarUrl != null
                    ? NetworkImage(friend.avatarUrl!)
                    : null,
                child: friend.avatarUrl == null
                    ? Text(
                        friend.name[0].toUpperCase(),
                        style: const TextStyle(
                            color: AppColors.neonPurple,
                            fontWeight: FontWeight.bold,
                            fontSize: 18),
                      )
                    : null,
              ),
              if (friend.currentlyListening != null)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: isDark ? AppColors.cardDark : Colors.white, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  friend.name,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                if (friend.currentlyListening != null)
                  Row(
                    children: [
                      const Icon(Icons.music_note_rounded,
                          size: 11, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${friend.currentlyListening!.title} · ${friend.currentlyListening!.artist}',
                          style: TextStyle(color: Colors.grey[500], fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  )
                else
                  Text(
                    '${friend.followersCount} followers',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => socialProvider.unfollowUser(friend.id),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey,
              side: BorderSide(color: Colors.grey.withValues(alpha: 0.4)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            ),
            child: const Text('Following', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
