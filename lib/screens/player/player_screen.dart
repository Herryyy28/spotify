import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:just_audio/just_audio.dart';
import '../../providers/player_provider.dart';
import '../../models/song_model.dart';
import '../../core/theme/colors.dart';
import '../../widgets/lyrics_widget.dart';
import '../../widgets/dynamic_theme_builder.dart';

class PlayerScreen extends StatefulWidget {
  final Song song;
  final List<Song>? playlist;

  const PlayerScreen({super.key, required this.song, this.playlist});

  @override
  _PlayerScreenState createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  int _currentTab = 0;
  bool _isLiked = false;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final playerProvider = Provider.of<PlayerProvider>(context);
    final theme = Theme.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isLiked ? Icons.favorite : Icons.favorite_border,
              color: _isLiked ? Colors.red : null,
            ),
            onPressed: () {
              setState(() => _isLiked = !_isLiked);
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showOptionsMenu(context),
          ),
        ],
      ),
      body: DynamicThemeBuilder(
        imageUrl: widget.song.coverUrl,
        builder: (context, colors, child) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 600),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: colors,
              ),
            ),
            child: child,
          );
        },
        child: SafeArea(
          child: Column(
            children: [
              // Album Art with Animation
              Expanded(
                flex: 3,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Hero(
                      tag: 'song_art_${widget.song.id}',
                      child: Container(
                        margin: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 30,
                              offset: const Offset(0, 20),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(30),
                          child: Stack(
                            children: [
                              // Animated background
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 500),
                                child: Image.network(
                                  widget.song.coverUrl,
                                  fit: BoxFit.cover,
                                ),
                              ),

                              // Visualizer overlay when playing
                              if (playerProvider.isPlaying)
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.transparent,
                                          Colors.black.withValues(alpha: 0.5),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),

                              // Play/Pause indicator
                              if (!playerProvider.isPlaying)
                                const Center(
                                  child: CircleAvatar(
                                    radius: 40,
                                    backgroundColor: Colors.white24,
                                    child: CircleAvatar(
                                      radius: 35,
                                      backgroundColor: Colors.white,
                                      child: Icon(
                                        Icons.play_arrow,
                                        size: 40,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Song Info
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    Text(
                      widget.song.title,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.song.artist,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Metadata row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildMetaChip(
                          icon: Icons.album,
                          label: widget.song.album,
                        ),
                        const SizedBox(width: 12),
                        _buildMetaChip(
                          icon: Icons.calendar_today,
                          label: '${widget.song.releaseDate.year}',
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Progress Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    // Time indicators
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          playerProvider.currentTime,
                          style: theme.textTheme.bodySmall,
                        ),
                        Text(
                          playerProvider.totalTime,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Progress slider
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 6,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 8,
                        ),
                      ),
                      child: Slider(
                        value: playerProvider.progress.clamp(0.0, 1.0),
                        onChanged: playerProvider.seek,
                        activeColor: AppColors.primary,
                        inactiveColor: Colors.grey[300],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Playback Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Shuffle
                  IconButton(
                    iconSize: 28,
                    icon: Icon(
                      playerProvider.isShuffled
                          ? Icons.shuffle_on
                          : Icons.shuffle,
                      color: playerProvider.isShuffled
                          ? AppColors.primary
                          : Colors.grey[600],
                    ),
                    onPressed: playerProvider.toggleShuffle,
                  ),

                  const SizedBox(width: 20),

                  // Previous
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withValues(alpha: 0.1),
                    ),
                    child: IconButton(
                      iconSize: 32,
                      icon: const Icon(Icons.skip_previous),
                      color: AppColors.primary,
                      onPressed: playerProvider.previous,
                    ),
                  ),

                  const SizedBox(width: 20),

                  // Play/Pause
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.secondary],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.5),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: IconButton(
                      iconSize: 40,
                      icon: Icon(
                        playerProvider.isPlaying
                            ? Icons.pause
                            : Icons.play_arrow,
                        color: Colors.white,
                      ),
                      onPressed: playerProvider.togglePlayPause,
                    ),
                  ),

                  const SizedBox(width: 20),

                  // Next
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withValues(alpha: 0.1),
                    ),
                    child: IconButton(
                      iconSize: 32,
                      icon: const Icon(Icons.skip_next),
                      color: AppColors.primary,
                      onPressed: playerProvider.next,
                    ),
                  ),

                  const SizedBox(width: 20),

                  // Repeat
                  IconButton(
                    iconSize: 28,
                    icon: Icon(
                      playerProvider.repeatMode == LoopMode.one
                          ? Icons.repeat_one
                          : Icons.repeat,
                      color: playerProvider.repeatMode != LoopMode.off
                          ? AppColors.primary
                          : Colors.grey[600],
                    ),
                    onPressed: playerProvider.toggleRepeat,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Bottom Tabs
              Container(
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(30),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Tab bar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildTabButton(0, 'Now Playing', Icons.music_note),
                        _buildTabButton(1, 'Lyrics', Icons.lyrics),
                        _buildTabButton(2, 'Related', Icons.queue_music),
                      ],
                    ),

                    // Tab content
                    SizedBox(
                      height: 100,
                      child: IndexedStack(
                        index: _currentTab,
                        children: [
                          // Now Playing queue
                          _buildQueueList(playerProvider),

                          // Lyrics
                          LyricsWidget(
                            song: widget.song,
                            currentPosition: playerProvider.currentPosition,
                          ),

                          // Related songs
                          _buildRelatedSongs(),
                        ],
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

  Widget _buildMetaChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey[600]),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildTabButton(int index, String label, IconData icon) {
    final isSelected = _currentTab == index;

    return GestureDetector(
      onTap: () => setState(() => _currentTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: isSelected
              ? const Border(
                  bottom: BorderSide(color: AppColors.primary, width: 3),
                )
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : Colors.grey[600],
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.primary : Colors.grey[600],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQueueList(PlayerProvider playerProvider) {
    if (playerProvider.currentPlaylist.isEmpty) {
      return const Center(child: Text('Queue is empty'));
    }

    return ReorderableListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: playerProvider.currentPlaylist.length,
      onReorder: (oldIndex, newIndex) {
        playerProvider.reorderQueue(oldIndex, newIndex);
      },
      itemBuilder: (context, index) {
        final song = playerProvider.currentPlaylist[index];
        final isCurrent = index == playerProvider.currentIndex;

        return ListTile(
          key: ValueKey('${song.id}_$index'),
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              song.coverUrl,
              width: 40,
              height: 40,
              fit: BoxFit.cover,
            ),
          ),
          title: Text(
            song.title,
            style: TextStyle(
              fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
              color: isCurrent ? AppColors.primary : null,
            ),
          ),
          subtitle: Text(song.artist),
          trailing: isCurrent
              ? const Icon(Icons.play_arrow, color: AppColors.primary)
              : IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: () => playerProvider.removeFromQueue(index),
                ),
          onTap: () async {
            await playerProvider.seekToIndex(index);
          },
        );
      },
    );
  }

  Widget _buildRelatedSongs() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return ListTile(
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              'https://source.unsplash.com/random/40x40?album${index + 1}',
              width: 40,
              height: 40,
              fit: BoxFit.cover,
            ),
          ),
          title: Text('Related Song ${index + 1}'),
          subtitle: const Text('Artist Name'),
          trailing: IconButton(
            icon: const Icon(Icons.play_circle_outline),
            onPressed: () {},
          ),
        );
      },
    );
  }

  void _showOptionsMenu(BuildContext context) {
    final playerProvider = Provider.of<PlayerProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.timer_outlined, color: AppColors.primary),
                title: Text(
                  playerProvider.sleepTimerRemaining != null
                      ? 'Sleep Timer (${playerProvider.sleepTimerRemaining!.inMinutes}m remaining)'
                      : 'Sleep Timer',
                ),
                trailing: playerProvider.sleepTimerRemaining != null
                    ? const Icon(Icons.check_circle, color: AppColors.primary, size: 18)
                    : null,
                onTap: () {
                  Navigator.pop(context);
                  _showSleepTimerDialog(context, playerProvider);
                },
              ),
              ListTile(
                leading: const Icon(Icons.equalizer, color: AppColors.primary),
                title: const Text('Equalizer & Audio Quality'),
                onTap: () {
                  Navigator.pop(context);
                  _showEqualizerDialog(context, playerProvider);
                },
              ),
              ListTile(
                leading: const Icon(Icons.playlist_add),
                title: const Text('Add to Playlist'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Select a playlist in Your Library to add this track.')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.share),
                title: const Text('Share Song'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Sharing link copied for "${widget.song.title}"!')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('Song Details'),
                onTap: () {
                  Navigator.pop(context);
                  _showSongInfoDialog(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSleepTimerDialog(BuildContext context, PlayerProvider playerProvider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final options = [
      {'label': 'Turn Off Timer', 'duration': null},
      {'label': '5 minutes', 'duration': const Duration(minutes: 5)},
      {'label': '15 minutes', 'duration': const Duration(minutes: 15)},
      {'label': '30 minutes', 'duration': const Duration(minutes: 30)},
      {'label': '45 minutes', 'duration': const Duration(minutes: 45)},
      {'label': '60 minutes', 'duration': const Duration(minutes: 60)},
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.cardDark : Colors.white,
        title: Text(
          'Sleep Timer',
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: options.map((opt) {
            final dur = opt['duration'] as Duration?;
            return ListTile(
              title: Text(
                opt['label'] as String,
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
              ),
              onTap: () {
                if (dur == null) {
                  playerProvider.cancelSleepTimer();
                } else {
                  playerProvider.setSleepTimer(dur);
                }
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(dur == null ? 'Sleep timer turned off.' : 'Sleep timer set for ${dur.inMinutes} minutes.'),
                  ),
                );
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showEqualizerDialog(BuildContext context, PlayerProvider playerProvider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String selectedPreset = 'Normal';
    final presets = ['Normal (Flat)', 'Bass Boost', 'Vocal Booster', 'Acoustic', 'Workout Energy', 'Electronic / EDM'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: isDark ? AppColors.cardDark : Colors.white,
          title: Text(
            'Equalizer & Sound Effects',
            style: TextStyle(color: isDark ? Colors.white : Colors.black),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sound Preset',
                style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.black87),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: presets.map((preset) {
                  final isSel = selectedPreset == preset;
                  return ChoiceChip(
                    label: Text(preset),
                    selected: isSel,
                    selectedColor: AppColors.primary,
                    onSelected: (val) {
                      if (val) setDialogState(() => selectedPreset = preset);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Playback Speed', style: TextStyle(color: isDark ? Colors.white : Colors.black)),
                  Text('${playerProvider.speed}x', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                ],
              ),
              Slider(
                value: playerProvider.speed,
                min: 0.5,
                max: 2.0,
                divisions: 6,
                activeColor: AppColors.primary,
                onChanged: (val) => playerProvider.setSpeed(val),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  void _showSongInfoDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.cardDark : Colors.white,
        title: Text(widget.song.title, style: TextStyle(color: isDark ? Colors.white : Colors.black)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Artist: ${widget.song.artist}', style: TextStyle(color: isDark ? Colors.grey[300] : Colors.grey[800])),
            const SizedBox(height: 4),
            Text('Album: ${widget.song.album}', style: TextStyle(color: isDark ? Colors.grey[300] : Colors.grey[800])),
            const SizedBox(height: 4),
            Text('Duration: ${widget.song.duration}', style: TextStyle(color: isDark ? Colors.grey[300] : Colors.grey[800])),
            const SizedBox(height: 4),
            Text('Codec: AAC 320 kbps (High Fidelity)', style: TextStyle(color: isDark ? Colors.grey[300] : Colors.grey[800])),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}
