import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/music_provider.dart';
import '../../models/song_model.dart';
import '../common/app_empty_state.dart';

class AdminLibraryTab extends StatelessWidget {
  final bool isDark;
  final Widget Function(Song, bool, {bool showActions}) buildSongTile;

  const AdminLibraryTab({
    super.key,
    required this.isDark,
    required this.buildSongTile,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeProvider>(
      builder: (context, musicProvider, _) {
        final allSongs = musicProvider.allSongs;
        return Column(
          key: const ValueKey('all_songs'),
          children: [
            Expanded(
              child: allSongs.isEmpty
                  ? const Center(
                      child: AppEmptyState(
                        title: 'No songs in library',
                        subtitle: 'Add songs from Dashboard or Import page',
                        icon: Icons.music_off_rounded,
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(24),
                      itemCount: allSongs.length,
                      itemBuilder: (context, index) => buildSongTile(
                        allSongs[index],
                        isDark,
                        showActions: true,
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

}
