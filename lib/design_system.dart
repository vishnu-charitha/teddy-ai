import 'dart:math' as math;
import 'package:flutter/material.dart';

// --- Premium Children's Visual Design System Tokens ---

const Color cream = Color(0xFFFFF7EA);
const Color warmWhite = Color(0xFFFFFDF9);
const Color surfaceLight = Color(0xFFF7FAFD);
const Color ink = Color(0xFF1E2843);
const Color inkSecondary = Color(0xFF6B7A99);

const Color lavender = Color(0xFFE7DEFF);
const Color lavenderDeep = Color(0xFF7E57C2);
const Color purple = Color(0xFF8B6AF6);

const Color coral = Color(0xFFFF6F59);
const Color coralLight = Color(0xFFFFECE8);
const Color orange = Color(0xFFFFA52E);
const Color gold = Color(0xFFFFBF00);
const Color goldLight = Color(0xFFFFF4D4);

const Color mint = Color(0xFFDDF5D7);
const Color mintLight = Color(0xFFEAF8EA);
const Color mintDeep = Color(0xFF2EA86E);
const Color sky = Color(0xFF8BD8F7);
const Color skyLight = Color(0xFFEAF7FD);
const Color pink = Color(0xFFFFD7E5);
const Color pinkDeep = Color(0xFFE0528D);

class TeddyDecorations {
  static BoxDecoration card({
    Color color = Colors.white,
    double radius = 24,
    Color? borderColor,
    double borderWidth = 2.0,
    double shadowOpacity = 0.08,
    Offset shadowOffset = const Offset(0, 8),
    double blurRadius = 16,
  }) =>
      BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: borderColor ?? Colors.white.withValues(alpha: 0.85),
          width: borderWidth,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D2850).withValues(alpha: shadowOpacity),
            blurRadius: blurRadius,
            offset: shadowOffset,
          ),
        ],
      );

  static BoxDecoration goldenBadge({bool unlocked = true}) => BoxDecoration(
        color: unlocked ? goldLight : const Color(0xFFF0F3F7),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: unlocked ? gold.withValues(alpha: 0.6) : Colors.white,
          width: 2.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (unlocked ? gold : Colors.black).withValues(alpha: 0.12),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      );
}

/// A delightful tactile bouncing button for children
class BouncyButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scaleDown;
  final Duration duration;

  const BouncyButton({
    super.key,
    required this.child,
    required this.onTap,
    this.scaleDown = 0.94,
    this.duration = const Duration(milliseconds: 140),
  });

  @override
  State<BouncyButton> createState() => _BouncyButtonState();
}

class _BouncyButtonState extends State<BouncyButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
      lowerBound: 0.0,
      upperBound: 1.0 - widget.scaleDown,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails _) {
    if (widget.onTap != null) _controller.forward();
  }

  void _handleTapUp(TapUpDetails _) {
    if (widget.onTap != null) {
      _controller.reverse();
      widget.onTap!();
    }
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) => Transform.scale(
            scale: 1.0 - _controller.value,
            child: child,
          ),
          child: widget.child,
        ),
      );
}

/// Lightweight, joyful celebration confetti overlay for learning accomplishments
class ConfettiOverlay extends StatefulWidget {
  final Widget child;
  final bool celebrate;

  const ConfettiOverlay({
    super.key,
    required this.child,
    this.celebrate = false,
  });

  @override
  State<ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<ConfettiOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  final List<_ConfettiParticle> _particles = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _initParticles();
    if (widget.celebrate) {
      _controller.forward(from: 0.0);
    }
  }

  void _initParticles() {
    _particles.clear();
    final colors = [gold, coral, purple, sky, mintDeep, pinkDeep, orange];
    for (int i = 0; i < 36; i++) {
      _particles.add(
        _ConfettiParticle(
          x: _random.nextDouble(),
          y: -0.1 - _random.nextDouble() * 0.3,
          vx: (_random.nextDouble() - 0.5) * 0.8,
          vy: 0.6 + _random.nextDouble() * 1.2,
          color: colors[_random.nextInt(colors.length)],
          size: 6.0 + _random.nextDouble() * 8.0,
          isStar: i % 3 == 0,
          rotation: _random.nextDouble() * math.pi * 2,
          rotSpeed: (_random.nextDouble() - 0.5) * 6,
        ),
      );
    }
  }

  @override
  void didUpdateWidget(covariant ConfettiOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.celebrate && !oldWidget.celebrate) {
      _initParticles();
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(
        children: [
          widget.child,
          if (widget.celebrate)
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) => CustomPaint(
                    painter: _ConfettiPainter(
                      progress: _controller.value,
                      particles: _particles,
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
}

class _ConfettiParticle {
  double x, y, vx, vy;
  final Color color;
  final double size;
  final bool isStar;
  double rotation;
  final double rotSpeed;

  _ConfettiParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.color,
    required this.size,
    required this.isStar,
    required this.rotation,
    required this.rotSpeed,
  });
}

class _ConfettiPainter extends CustomPainter {
  final double progress;
  final List<_ConfettiParticle> particles;

  _ConfettiPainter({required this.progress, required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1.0) return;
    final alpha = (1.0 - progress).clamp(0.0, 1.0);

    for (final p in particles) {
      final curX = (p.x + p.vx * progress) * size.width;
      final curY = (p.y + p.vy * progress) * size.height;
      final rot = p.rotation + p.rotSpeed * progress;

      canvas.save();
      canvas.translate(curX, curY);
      canvas.rotate(rot);

      final paint = Paint()
        ..color = p.color.withValues(alpha: alpha)
        ..style = PaintingStyle.fill;

      if (p.isStar) {
        _drawStar(canvas, p.size, paint);
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: Offset.zero, width: p.size, height: p.size * 0.7),
            const Radius.circular(3),
          ),
          paint,
        );
      }
      canvas.restore();
    }
  }

  void _drawStar(Canvas canvas, double size, Paint paint) {
    final path = Path();
    const points = 5;
    final outerRadius = size;
    final innerRadius = size * 0.45;

    for (int i = 0; i < points * 2; i++) {
      final r = i.isEven ? outerRadius : innerRadius;
      final angle = i * math.pi / points - math.pi / 2;
      final x = math.cos(angle) * r;
      final y = math.sin(angle) * r;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) =>
      old.progress != progress;
}

class PageFrame extends StatelessWidget {
  static VoidCallback? defaultBackAction;
  final String title;
  final Widget child;
  final bool back;
  final VoidCallback? onBack;
  final Widget? trailing;

  const PageFrame({
    super.key,
    required this.title,
    required this.child,
    this.back = true,
    this.onBack,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                if (back)
                  BouncyButton(
                    onTap: onBack ??
                        defaultBackAction ??
                        () => Navigator.maybePop(context),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: const Color(0xFFE4EDF5), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFF0D2850).withValues(alpha: 0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.arrow_back_rounded,
                          color: ink, size: 22),
                    ),
                  )
                else
                  const SizedBox(width: 44),
                Expanded(
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: ink,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                if (trailing != null) trailing! else const SizedBox(width: 44),
              ],
            ),
          ),
          Expanded(child: child),
        ],
      );
}
