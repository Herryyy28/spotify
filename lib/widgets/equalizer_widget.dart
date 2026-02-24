import 'package:flutter/material.dart';
import 'dart:math' as math;

import 'package:harmony_music/core/theme/colors.dart';

class EqualizerWidget extends StatefulWidget {
  final bool isPlaying;
  final Color color;
  final int barCount;
  final double barWidth;
  final double maxHeight;

  const EqualizerWidget({
    super.key,
    this.isPlaying = true,
    this.color = Colors.white,
    this.barCount = 5,
    this.barWidth = 4,
    this.maxHeight = 20,
  });

  @override
  _EqualizerWidgetState createState() => _EqualizerWidgetState();
}

class _EqualizerWidgetState extends State<EqualizerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<double> _heights = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);

    // Initialize random heights
    for (int i = 0; i < widget.barCount; i++) {
      _heights.add(_random.nextDouble());
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        if (widget.isPlaying) {
          // Update heights randomly
          for (int i = 0; i < _heights.length; i++) {
            _heights[i] = 0.3 + _random.nextDouble() * 0.7;
          }
        }

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(widget.barCount, (index) {
            return Container(
              width: widget.barWidth,
              height: widget.isPlaying
                  ? widget.maxHeight * _heights[index]
                  : widget.maxHeight * 0.3,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: widget.color.withOpacity(
                  widget.isPlaying ? 1.0 : 0.5,
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class AnimatedEqualizer extends StatelessWidget {
  final bool isPlaying;
  final Color color;

  const AnimatedEqualizer({
    super.key,
    required this.isPlaying,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 20,
      child: Stack(
        children: [
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            left: 0,
            bottom: isPlaying ? 0 : 10,
            child: Container(
              width: 4,
              height: isPlaying ? 20 : 10,
              color: color,
            ),
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 400),
            left: 8,
            bottom: isPlaying ? 5 : 10,
            child: Container(
              width: 4,
              height: isPlaying ? 15 : 10,
              color: color,
            ),
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            left: 16,
            bottom: isPlaying ? 2 : 10,
            child: Container(
              width: 4,
              height: isPlaying ? 18 : 10,
              color: color,
            ),
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 350),
            left: 24,
            bottom: isPlaying ? 7 : 10,
            child: Container(
              width: 4,
              height: isPlaying ? 13 : 10,
              color: color,
            ),
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 250),
            left: 32,
            bottom: isPlaying ? 3 : 10,
            child: Container(
              width: 4,
              height: isPlaying ? 17 : 10,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class SpectrumVisualizer extends StatefulWidget {
  final bool isPlaying;

  const SpectrumVisualizer({
    super.key,
    required this.isPlaying,
  });

  @override
  _SpectrumVisualizerState createState() => _SpectrumVisualizerState();
}

class _SpectrumVisualizerState extends State<SpectrumVisualizer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    )..repeat();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(200, 80),
          painter: _SpectrumPainter(
            isPlaying: widget.isPlaying,
            value: _controller.value,
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class _SpectrumPainter extends CustomPainter {
  final bool isPlaying;
  final double value;

  _SpectrumPainter({
    required this.isPlaying,
    required this.value,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!isPlaying) return;

    final paint = Paint()
      ..color = AppColors.primary.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    final barWidth = size.width / 40;
    final random = math.Random(value.toInt());

    for (int i = 0; i < 40; i++) {
      final x = i * barWidth;
      final height = random.nextDouble() * size.height;

      canvas.drawRect(
        Rect.fromLTWH(
          x,
          size.height - height,
          barWidth - 2,
          height,
        ),
        paint..color = AppColors.primary.withOpacity(0.5 + height / size.height * 0.5),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SpectrumPainter oldDelegate) {
    return oldDelegate.value != value || oldDelegate.isPlaying != isPlaying;
  }
}