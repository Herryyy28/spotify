import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/song_model.dart';
import '../core/theme/colors.dart';

class LyricsWidget extends StatefulWidget {
  final Song song;

  const LyricsWidget({
    super.key,
    required this.song,
  });

  @override
  _LyricsWidgetState createState() => _LyricsWidgetState();
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

  Future<void> _fetchLyrics() async {
    if (widget.song.lyricsUrl != null) {
      try {
        final response = await http.get(Uri.parse(widget.song.lyricsUrl!));
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          setState(() {
            _lyrics = _parseLyrics(data['lyrics']);
            _isLoading = false;
          });
        } else {
          setState(() {
            _hasError = true;
            _isLoading = false;
          });
        }
      } catch (e) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  List<LyricLine> _parseLyrics(String lyrics) {
    final lines = lyrics.split('\n');
    final List<LyricLine> lyricLines = [];

    for (final line in lines) {
      // Parse timestamp format: [mm:ss.xx] lyric text
      final regex = RegExp(r'\[(\d{2}):(\d{2})\.(\d{2})\](.*)');
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
        // Lines without timestamp
        lyricLines.add(LyricLine(
          timestamp: null,
          text: line.trim(),
        ));
      }
    }

    return lyricLines;
  }

  void _onPlaybackPosition(Duration position) {
    if (_lyrics.isEmpty) return;

    int newIndex = -1;
    for (int i = 0; i < _lyrics.length; i++) {
      final lyric = _lyrics[i];
      if (lyric.timestamp != null && position >= lyric.timestamp!) {
        newIndex = i;
      } else {
        break;
      }
    }

    if (newIndex != _currentLineIndex) {
      setState(() => _currentLineIndex = newIndex);

      // Scroll to current line
      if (_currentLineIndex >= 0 && _scrollController.hasClients) {
        const itemHeight = 40.0; // Approximate height
        final scrollPosition = _currentLineIndex * itemHeight - 100;
        _scrollController.animateTo(
          scrollPosition.clamp(0, _scrollController.position.maxScrollExtent),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    }
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
      padding: const EdgeInsets.all(16),
      itemCount: _lyrics.length,
      itemBuilder: (context, index) {
        final lyric = _lyrics[index];
        final isCurrent = index == _currentLineIndex;

        return AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          style: (theme.textTheme.bodyLarge ?? const TextStyle()).copyWith(
            fontSize: isCurrent ? 20 : 16,
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
            color: isCurrent
                ? AppColors.primary
                : theme.textTheme.bodyLarge?.color,
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

class SyncedLyricsWidget extends StatefulWidget {
  final Song song;
  final Stream<Duration> positionStream;

  const SyncedLyricsWidget({
    super.key,
    required this.song,
    required this.positionStream,
  });

  @override
  _SyncedLyricsWidgetState createState() => _SyncedLyricsWidgetState();
}

class _SyncedLyricsWidgetState extends State<SyncedLyricsWidget> {
  final LyricsController _controller = LyricsController();

  @override
  void initState() {
    super.initState();
    widget.positionStream.listen((position) {
      _controller.updatePosition(position);
    });
  }

  @override
  Widget build(BuildContext context) {
    return LyricsWidget(song: widget.song);
  }
}

class LyricsController extends ChangeNotifier {
  Duration _currentPosition = Duration.zero;
  final int _currentLine = -1;

  Duration get currentPosition => _currentPosition;
  int get currentLine => _currentLine;

  void updatePosition(Duration position) {
    _currentPosition = position;
    notifyListeners();
  }
}
