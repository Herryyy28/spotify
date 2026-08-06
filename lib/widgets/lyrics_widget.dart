import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/song_model.dart';
import '../core/theme/colors.dart';

class LyricsWidget extends StatefulWidget {
  final Song song;
  final Duration? currentPosition;

  const LyricsWidget({
    super.key,
    required this.song,
    this.currentPosition,
  });

  @override
  State<LyricsWidget> createState() => _LyricsWidgetState();
}

class _LyricsWidgetState extends State<LyricsWidget> {
  List<LyricLine> _lyrics = [];
  bool _isLoading = true;
  bool _hasError = false;
  int _currentLineIndex = -1;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchLyrics();
  }

  @override
  void didUpdateWidget(covariant LyricsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.song.id != oldWidget.song.id) {
      _fetchLyrics();
    } else if (widget.currentPosition != oldWidget.currentPosition &&
        _lyrics.isNotEmpty) {
      _updateCurrentLine();
    }
  }

  void _updateCurrentLine() {
    if (widget.currentPosition == null) return;
    final position = widget.currentPosition!;
    
    int newIndex = -1;
    for (int i = 0; i < _lyrics.length; i++) {
      if (_lyrics[i].timestamp != null) {
        if (position >= _lyrics[i].timestamp!) {
          newIndex = i;
        } else {
          break; // Found the current line
        }
      }
    }

    if (newIndex != _currentLineIndex && newIndex != -1) {
      setState(() {
        _currentLineIndex = newIndex;
      });
      _scrollToCurrentLine();
    }
  }

  void _scrollToCurrentLine() {
    if (!_scrollController.hasClients || _currentLineIndex < 0) return;
    
    // Estimate item height
    const itemHeight = 40.0;
    final targetOffset = (_currentLineIndex * itemHeight) - 100.0;
    
    _scrollController.animateTo(
      targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _fetchLyrics() async {
    setState(() {
      _isLoading = true;
      _currentLineIndex = -1;
    });

    if (widget.song.lyricsUrl != null && widget.song.lyricsUrl!.isNotEmpty) {
      try {
        final response = await http.get(Uri.parse(widget.song.lyricsUrl!));
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          setState(() {
            _lyrics = _parseLyrics(data['lyrics'] ?? '');
            _isLoading = false;
            _hasError = false;
          });
          return;
        }
      } catch (e) {
        // Fallback to error state or demo lyrics
      }
    }

    // Fallback demo lyrics for preview
    setState(() {
      _lyrics = [
        LyricLine(timestamp: const Duration(seconds: 0), text: '🎵 ${widget.song.title}'),
        LyricLine(timestamp: const Duration(seconds: 5), text: 'Artist: ${widget.song.artist}'),
        LyricLine(timestamp: const Duration(seconds: 10), text: 'Album: ${widget.song.album}'),
        LyricLine(timestamp: const Duration(seconds: 15), text: '...'),
      ];
      _isLoading = false;
      _hasError = false;
    });
  }

  List<LyricLine> _parseLyrics(String lyrics) {
    final lines = lyrics.split('\n');
    final List<LyricLine> lyricLines = [];

    final regex = RegExp(r'\[(\d{2}):(\d{2})\.(\d{2})\](.*)');

    for (final line in lines) {
      final match = regex.firstMatch(line);
      if (match != null) {
        final minutes = int.parse(match.group(1)!);
        final seconds = int.parse(match.group(2)!);
        final centiseconds = int.parse(match.group(3)!);
        final text = match.group(4)!.trim();

        final timestamp = Duration(
          minutes: minutes,
          seconds: seconds,
          milliseconds: centiseconds * 10,
        );

        lyricLines.add(LyricLine(
          timestamp: timestamp,
          text: text,
        ));
      } else if (line.trim().isNotEmpty) {
        lyricLines.add(LyricLine(
          timestamp: null,
          text: line.trim(),
        ));
      }
    }
    return lyricLines;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
        ),
      );
    }

    if (_hasError || _lyrics.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lyrics,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No lyrics available',
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Lyrics for this song are not available',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 100),
      itemCount: _lyrics.length,
      itemBuilder: (context, index) {
        final lyric = _lyrics[index];
        final isCurrent = index == _currentLineIndex;

        return AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          style: (theme.textTheme.bodyLarge ?? const TextStyle()).copyWith(
            fontSize: isCurrent ? 22 : 16,
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
            color: isCurrent
                ? AppColors.primary
                : theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.5),
            height: 1.8,
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              lyric.text,
              textAlign: TextAlign.center,
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}

class LyricLine {
  final Duration? timestamp;
  final String text;

  LyricLine({
    this.timestamp,
    required this.text,
  });
}
