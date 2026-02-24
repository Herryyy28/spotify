import 'package:flutter/material.dart';
import '../core/theme/colors.dart';

/// Premium gradient button with animations
class PremiumButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final Gradient? gradient;
  final Color? backgroundColor;
  final Color? textColor;
  final IconData? icon;
  final double? width;
  final double height;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final bool isLoading;
  final bool enabled;

  const PremiumButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.gradient,
    this.backgroundColor,
    this.textColor,
    this.icon,
    this.width,
    this.height = 56,
    this.borderRadius = 28,
    this.padding,
    this.isLoading = false,
    this.enabled = true,
  });

  @override
  State<PremiumButton> createState() => _PremiumButtonState();
}

class _PremiumButtonState extends State<PremiumButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.enabled && !widget.isLoading) {
      _controller.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.enabled && !widget.isLoading) {
      _controller.reverse();
    }
  }

  void _handleTapCancel() {
    if (widget.enabled && !widget.isLoading) {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveGradient = widget.gradient ?? AppColors.spotifyGradient;
    final effectiveTextColor = widget.textColor ?? Colors.white;

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: widget.enabled && !widget.isLoading ? widget.onPressed : null,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: widget.width,
          height: widget.height,
          padding: widget.padding,
          decoration: BoxDecoration(
            gradient: widget.enabled ? effectiveGradient : null,
            color: widget.enabled ? widget.backgroundColor : Colors.grey[400],
            borderRadius: BorderRadius.circular(widget.borderRadius),
            boxShadow: widget.enabled
                ? [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ]
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: Center(
              child: widget.isLoading
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          effectiveTextColor,
                        ),
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (widget.icon != null) ...[
                          Icon(
                            widget.icon,
                            color: effectiveTextColor,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          widget.text,
                          style: TextStyle(
                            color: effectiveTextColor,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Outlined premium button
class OutlinedPremiumButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color? borderColor;
  final Color? textColor;
  final IconData? icon;
  final double? width;
  final double height;
  final double borderRadius;

  const OutlinedPremiumButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.borderColor,
    this.textColor,
    this.icon,
    this.width,
    this.height = 56,
    this.borderRadius = 28,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBorderColor = borderColor ?? AppColors.primary;
    final effectiveTextColor = textColor ?? AppColors.primary;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: effectiveBorderColor,
          width: 2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    color: effectiveTextColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  text,
                  style: TextStyle(
                    color: effectiveTextColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Icon button with glow effect
class GlowIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color? color;
  final double size;
  final bool showGlow;

  const GlowIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.color,
    this.size = 24,
    this.showGlow = true,
  });

  @override
  State<GlowIconButton> createState() => _GlowIconButtonState();
}

class _GlowIconButtonState extends State<GlowIconButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    if (widget.showGlow) {
      _controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1500),
      )..repeat(reverse: true);
      _glowAnimation = Tween<double>(begin: 0.3, end: 0.8).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      );
    }
  }

  @override
  void dispose() {
    if (widget.showGlow) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveColor = widget.color ?? AppColors.primary;

    return AnimatedBuilder(
      animation:
          widget.showGlow ? _glowAnimation : const AlwaysStoppedAnimation(0),
      builder: (context, child) {
        return Container(
          decoration: widget.showGlow
              ? BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: effectiveColor.withOpacity(_glowAnimation.value),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                )
              : null,
          child: IconButton(
            icon: Icon(widget.icon),
            color: effectiveColor,
            iconSize: widget.size,
            onPressed: widget.onPressed,
          ),
        );
      },
    );
  }
}
