import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';
import '../../models/playlist_model.dart';

class PlaylistScreen extends StatelessWidget {
  final Playlist? playlist;

  const PlaylistScreen({super.key, this.playlist});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: Center(
        child: Text(
          'Playlist Screen',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontSize: 24,
          ),
        ),
      ),
    );
  }
}
