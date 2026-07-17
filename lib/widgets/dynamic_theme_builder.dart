import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';

/// A widget that extracts dynamic colors from a network image URL using [PaletteGenerator].
/// It invokes the [builder] with the extracted colors, which will animate smoothly when wrapped
/// inside an [AnimatedContainer].
class DynamicThemeBuilder extends StatefulWidget {
  final String imageUrl;
  final Widget Function(BuildContext context, List<Color> colors, Widget? child) builder;
  final Widget? child;
  final List<Color> defaultColors;

  const DynamicThemeBuilder({
    super.key,
    required this.imageUrl,
    required this.builder,
    this.child,
    this.defaultColors = const [Color(0xFF8338EC), Color(0xFF121212)],
  });

  @override
  State<DynamicThemeBuilder> createState() => _DynamicThemeBuilderState();
}

class _DynamicThemeBuilderState extends State<DynamicThemeBuilder> {
  late List<Color> _currentColors;
  String? _lastLoadedUrl;

  @override
  void initState() {
    super.initState();
    _currentColors = widget.defaultColors;
    _updatePalette();
  }

  @override
  void didUpdateWidget(covariant DynamicThemeBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _updatePalette();
    }
  }

  Future<void> _updatePalette() async {
    final url = widget.imageUrl;
    if (url.isEmpty || url == _lastLoadedUrl) return;

    try {
      final imageProvider = NetworkImage(url);
      final paletteGenerator = await PaletteGenerator.fromImageProvider(
        imageProvider,
        maximumColorCount: 8,
      );

      final dominantColor = paletteGenerator.dominantColor?.color;
      final vibrantColor = paletteGenerator.vibrantColor?.color;
      final darkMutedColor = paletteGenerator.darkMutedColor?.color;

      if (dominantColor != null) {
        if (!mounted) return;
        setState(() {
          _lastLoadedUrl = url;
          // Mix dynamic vibrant/dominant color with a dark/muted color for background contrast
          final primary = vibrantColor ?? dominantColor;
          final secondary = darkMutedColor ?? const Color(0xFF121212);
          
          _currentColors = [
            primary.withOpacity(0.55),
            secondary.withOpacity(0.95),
          ];
        });
      }
    } catch (e) {
      debugPrint('Error generating palette for $url: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _currentColors, widget.child);
  }
}
