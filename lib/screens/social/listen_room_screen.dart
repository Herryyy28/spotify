import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme/colors.dart';
import '../../models/song_model.dart';
import '../../providers/listening_room_provider.dart';
import '../../providers/player_provider.dart';
import '../../providers/user_provider.dart';

class ListenRoomScreen extends StatefulWidget {
  const ListenRoomScreen({super.key});

  @override
  State<ListenRoomScreen> createState() => _ListenRoomScreenState();
}

class _ListenRoomScreenState extends State<ListenRoomScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _vinylController;
  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _vinylController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
  }

  @override
  void dispose() {
    _vinylController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final roomProvider = Provider.of<ListeningRoomProvider>(context);
    final playerProvider = Provider.of<PlayerProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);
    final room = roomProvider.activeRoom;

    if (room == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Listening Room')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.speaker_group, size: 80, color: AppColors.primary),
              const SizedBox(height: 16),
              const Text(
                'No Active Listening Room',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Create a new room or join a friend using a Room Code.',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () async {
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
                  await roomProvider.createRoom(
                    song,
                    userProvider.user?.displayName ?? 'Host',
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('Create Room Now'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final currentSong = room.currentSong;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.greenAccent,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  room.id,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            Text(
              'Host: ${room.hostName}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: 'Copy Room Code',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: room.id));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Copied Room Code "${room.id}" to clipboard!'),
                  backgroundColor: AppColors.primary,
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.exit_to_app, color: Colors.redAccent),
            tooltip: 'Leave Room',
            onPressed: () => _confirmLeave(context, roomProvider),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Sync status header banner
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.sync, color: AppColors.primary, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    roomProvider.isHost
                        ? '👑 You are Hosting this Live Sync Room'
                        : '⚡ Synchronized with Host Playback',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: AppColors.primary),
                  ),
                  const Spacer(),
                  const Icon(Icons.people, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text('${room.participantCount} live',
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),

            // Rotating Vinyl Disc Artwork
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      RotationTransition(
                        turns: _vinylController,
                        child: Container(
                          width: 220,
                          height: 220,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.3),
                                blurRadius: 30,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Vinyl grooves background
                              Container(
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.black87,
                                ),
                              ),
                              // Album Cover Center
                              ClipOval(
                                child: Image.network(
                                  currentSong.coverUrl,
                                  width: 130,
                                  height: 130,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    color: AppColors.cardDark,
                                    child: const Icon(Icons.music_note,
                                        size: 50, color: Colors.white),
                                  ),
                                ),
                              ),
                              // Spindle hole
                              Container(
                                width: 24,
                                height: 24,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        currentSong.title,
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        currentSong.artist,
                        style: TextStyle(
                            fontSize: 16,
                            color: isDark ? Colors.grey[400] : Colors.grey[700]),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Floating Emoji Reactions Bar
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: ['🔥', '❤️', '🎵', '👏', '🎉', '💃'].map((emoji) {
                  return GestureDetector(
                    onTap: () => roomProvider.sendReaction(emoji, isEmojiOnly: true),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.cardDark : Colors.grey[200],
                        shape: BoxShape.circle,
                      ),
                      child: Text(emoji, style: const TextStyle(fontSize: 22)),
                    ),
                  );
                }).toList(),
              ),
            ),

            // Live Chat Feed
            Container(
              height: 140,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      reverse: true,
                      padding: const EdgeInsets.all(8),
                      itemCount: roomProvider.messages.length,
                      itemBuilder: (context, index) {
                        final msg = roomProvider.messages[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: RichText(
                            text: TextSpan(
                              style: TextStyle(
                                  color: isDark ? Colors.white : Colors.black87,
                                  fontSize: 13),
                              children: [
                                TextSpan(
                                  text: '${msg.senderName}: ',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary),
                                ),
                                TextSpan(text: msg.message),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  // Chat Input Bar
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            decoration: InputDecoration(
                              hintText: 'Say something in room...',
                              isDense: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor:
                                  isDark ? Colors.black38 : Colors.white,
                            ),
                            onSubmitted: (text) => _sendMessage(roomProvider),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.send, color: AppColors.primary),
                          onPressed: () => _sendMessage(roomProvider),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _sendMessage(ListeningRoomProvider provider) {
    final text = _messageController.text.trim();
    if (text.isNotEmpty) {
      provider.sendReaction(text);
      _messageController.clear();
    }
  }

  void _confirmLeave(BuildContext context, ListeningRoomProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Listening Room?'),
        content: Text(provider.isHost
            ? 'Closing this room will disconnect all active listeners.'
            : 'Are you sure you want to exit this room?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              Navigator.pop(context);
              provider.leaveRoom();
            },
            child: const Text('Leave'),
          ),
        ],
      ),
    );
  }
}
