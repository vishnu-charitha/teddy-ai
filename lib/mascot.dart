import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:teddy_ai/audio_voice_service.dart';

/// A rich, adorable vector-drawn animated Teddy Bear mascot
class TeddyMascot extends StatefulWidget {
  final AnimationController bob;
  final double size;
  final bool waving;
  final bool interactive;
  final VoidCallback? onTap;

  /// Optional speaking state listenable or override. If null, listens to AudioVoiceService().isSpeaking
  final ValueListenable<bool>? isSpeakingListenable;
  final bool? isSpeaking;

  const TeddyMascot({
    super.key,
    required this.bob,
    this.size = 140,
    this.waving = false,
    this.interactive = true,
    this.onTap,
    this.isSpeakingListenable,
    this.isSpeaking,
  });

  @override
  State<TeddyMascot> createState() => _TeddyMascotState();
}

class _TeddyMascotState extends State<TeddyMascot>
    with TickerProviderStateMixin {
  late final AnimationController _tapController;
  late final AnimationController _mouthController;
  late final Animation<double> _mouthAnimation;

  bool _showHeart = false;
  VoidCallback? _audioListener;

  @override
  void initState() {
    super.initState();
    _tapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    // Mouth animation controller oscillating between 0.0 (closed), 0.5 (slightly open), and 1.0 (wide open)
    _mouthController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );

    _mouthAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 0.55)
            .chain(CurveTween(curve: Curves.easeOutQuad)),
        weight: 35.0,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.55, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOutQuad)),
        weight: 35.0,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeInQuad)),
        weight: 30.0,
      ),
    ]).animate(_mouthController);

    _setupSpeakingListener();
  }

  void _setupSpeakingListener() {
    if (widget.isSpeaking != null) {
      _updateSpeakingAnimation(widget.isSpeaking!);
      return;
    }

    if (widget.isSpeakingListenable != null) {
      _audioListener = () {
        if (mounted) {
          _updateSpeakingAnimation(widget.isSpeakingListenable!.value);
        }
      };
      widget.isSpeakingListenable!.addListener(_audioListener!);
      _updateSpeakingAnimation(widget.isSpeakingListenable!.value);
      return;
    }

    // Default to AudioVoiceService singleton
    _audioListener = () {
      if (mounted) {
        _updateSpeakingAnimation(AudioVoiceService().isSpeaking);
      }
    };
    AudioVoiceService().addListener(_audioListener!);
    _updateSpeakingAnimation(AudioVoiceService().isSpeaking);
  }

  void _removeSpeakingListener() {
    if (_audioListener != null) {
      if (widget.isSpeakingListenable != null) {
        widget.isSpeakingListenable!.removeListener(_audioListener!);
      } else {
        AudioVoiceService().removeListener(_audioListener!);
      }
      _audioListener = null;
    }
  }

  void _updateSpeakingAnimation(bool isSpeaking) {
    if (isSpeaking) {
      if (!_mouthController.isAnimating) {
        _mouthController.repeat(reverse: false);
      }
    } else {
      if (_mouthController.isAnimating || _mouthController.value > 0.0) {
        _mouthController.animateTo(0.0,
            duration: const Duration(milliseconds: 140), curve: Curves.easeIn);
      }
    }
  }

  @override
  void didUpdateWidget(covariant TeddyMascot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isSpeaking != widget.isSpeaking) {
      if (widget.isSpeaking != null) {
        _updateSpeakingAnimation(widget.isSpeaking!);
      }
    }
    if (oldWidget.isSpeakingListenable != widget.isSpeakingListenable) {
      _removeSpeakingListener();
      _setupSpeakingListener();
    }
  }

  @override
  void dispose() {
    _removeSpeakingListener();
    _mouthController.dispose();
    _tapController.dispose();
    super.dispose();
  }

  void _onTap() {
    if (!widget.interactive) return;
    setState(() => _showHeart = true);
    _tapController.forward(from: 0.0).then((_) {
      if (mounted) setState(() => _showHeart = false);
    });
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: _onTap,
        child: AnimatedBuilder(
          animation:
              Listenable.merge([widget.bob, _tapController, _mouthAnimation]),
          builder: (context, _) {
            final bobVal = widget.bob.value;
            final tapVal = _tapController.value;
            final mouthVal = _mouthAnimation.value;
            final floatOffset = math.sin(bobVal * math.pi) * 8.0;
            final tiltAngle = math.sin(bobVal * math.pi * 2) * 0.04;
            final tapScale = 1.0 + math.sin(tapVal * math.pi) * 0.12;

            return Stack(
              alignment: Alignment.center,
              children: [
                Transform.translate(
                  offset: Offset(0, floatOffset),
                  child: Transform.rotate(
                    angle: tiltAngle,
                    child: Transform.scale(
                      scale: tapScale,
                      child: CustomPaint(
                        size: Size(widget.size, widget.size),
                        painter: _TeddyPainter(
                          bob: bobVal,
                          waving: widget.waving,
                          mouthOpenAmount: mouthVal,
                        ),
                      ),
                    ),
                  ),
                ),
                if (_showHeart)
                  Positioned(
                    top: widget.size * 0.05 - tapVal * 28,
                    right: widget.size * 0.18,
                    child: Opacity(
                      opacity: (1.0 - tapVal).clamp(0.0, 1.0),
                      child:
                          const Text('✨ ❤️ ✨', style: TextStyle(fontSize: 16)),
                    ),
                  ),
              ],
            );
          },
        ),
      );
}

class _TeddyPainter extends CustomPainter {
  final double bob;
  final bool waving;
  final double mouthOpenAmount;

  _TeddyPainter({
    required this.bob,
    required this.waving,
    this.mouthOpenAmount = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h / 2;

    // Warm palette
    const furDark = Color(0xFFD67F33);
    const furBase = Color(0xFFE89848);
    const furLight = Color(0xFFFFB86B);
    const furCream = Color(0xFFFFF2D9);
    final blush = const Color(0xFFFF8B94).withValues(alpha: 0.45);
    const eyeColor = Color(0xFF231C16);

    // Drop shadow under mascot
    final shadowPaint = Paint()
      ..color = const Color(0xFF3B271A).withValues(alpha: 0.14)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx, h * 0.94), width: w * 0.65, height: h * 0.14),
      shadowPaint,
    );

    // Body
    final bodyCenter = Offset(cx, cy + h * 0.22);
    final bodyRect =
        Rect.fromCenter(center: bodyCenter, width: w * 0.62, height: h * 0.52);

    final bodyPaint = Paint()
      ..shader = const RadialGradient(
        colors: [furLight, furBase, furDark],
        center: Alignment(-0.2, -0.3),
        radius: 0.9,
      ).createShader(bodyRect);
    canvas.drawOval(bodyRect, bodyPaint);

    // Tummy patch
    final tummyRect = Rect.fromCenter(
        center: Offset(cx, cy + h * 0.24), width: w * 0.38, height: h * 0.34);
    final tummyPaint = Paint()..color = furCream;
    canvas.drawOval(tummyRect, tummyPaint);

    // Cute belly button/stitch
    final stitchPaint = Paint()
      ..color = furDark.withValues(alpha: 0.6)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(cx - 4, cy + h * 0.28),
      Offset(cx + 4, cy + h * 0.28),
      stitchPaint,
    );
    canvas.drawLine(
      Offset(cx, cy + h * 0.28 - 4),
      Offset(cx, cy + h * 0.28 + 4),
      stitchPaint,
    );

    // Paws / Feet (Sitting)
    final footRadius = w * 0.14;
    for (final dir in [-1, 1]) {
      final footCenter = Offset(cx + dir * w * 0.26, cy + h * 0.40);
      final footRect = Rect.fromCenter(
          center: footCenter, width: footRadius * 2, height: footRadius * 1.8);

      final footPaint = Paint()
        ..shader = RadialGradient(
          colors: const [furLight, furBase, furDark],
          center: Alignment(dir * -0.2, -0.3),
        ).createShader(footRect);
      canvas.drawOval(footRect, footPaint);

      // Foot pad
      final padPaint = Paint()..color = furCream;
      canvas.drawOval(
        Rect.fromCenter(
            center: footCenter + Offset(0, footRadius * 0.08),
            width: footRadius * 1.1,
            height: footRadius * 0.95),
        padPaint,
      );
      // 3 toe dots
      for (int t = -1; t <= 1; t++) {
        canvas.drawCircle(
          footCenter + Offset(t * 6.0, -footRadius * 0.45),
          3.2,
          padPaint,
        );
      }
    }

    // Arms / Hands
    final armRadius = w * 0.12;
    // Left hand
    final leftHand = Offset(cx - w * 0.28, cy + h * 0.18);
    canvas.drawCircle(leftHand, armRadius, bodyPaint);
    canvas.drawCircle(leftHand, armRadius * 0.55, Paint()..color = furCream);

    // Right hand (waves if waving)
    final waveOffset = waving ? math.sin(bob * math.pi * 3) * 6.0 : 0.0;
    final rightHand =
        Offset(cx + w * 0.28, cy + h * 0.18 - (waving ? 14 : 0) + waveOffset);
    canvas.drawCircle(rightHand, armRadius, bodyPaint);
    canvas.drawCircle(rightHand, armRadius * 0.55, Paint()..color = furCream);

    // Ears
    final earRadius = w * 0.15;
    final earY = cy - h * 0.22;
    for (final dir in [-1, 1]) {
      final earCenter = Offset(cx + dir * w * 0.28, earY);
      final earRect = Rect.fromCircle(center: earCenter, radius: earRadius);

      final earPaint = Paint()
        ..shader = RadialGradient(
          colors: const [furLight, furBase, furDark],
          center: Alignment(dir * -0.2, -0.2),
        ).createShader(earRect);
      canvas.drawCircle(earCenter, earRadius, earPaint);

      // Inner ear
      final innerEarCenter = Offset(cx + dir * w * 0.26, earY + 3);
      canvas.drawCircle(
          innerEarCenter, earRadius * 0.58, Paint()..color = furCream);
    }

    // Head
    final headCenter = Offset(cx, cy - h * 0.05);
    final headRect =
        Rect.fromCenter(center: headCenter, width: w * 0.72, height: h * 0.64);
    final headPaint = Paint()
      ..shader = const RadialGradient(
        colors: [furLight, furBase, furDark],
        center: Alignment(-0.2, -0.3),
        radius: 0.9,
      ).createShader(headRect);
    canvas.drawOval(headRect, headPaint);

    // Cute cheeks / blush
    final cheekY = headCenter.dy + h * 0.08;
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx - w * 0.23, cheekY), width: 22, height: 14),
      Paint()..color = blush,
    );
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx + w * 0.23, cheekY), width: 22, height: 14),
      Paint()..color = blush,
    );

    // Snout / Muzzle
    final snoutCenter = Offset(cx, headCenter.dy + h * 0.09);
    final snoutRect =
        Rect.fromCenter(center: snoutCenter, width: w * 0.36, height: h * 0.26);
    canvas.drawOval(snoutRect, Paint()..color = furCream);

    // Cute soft nose
    final noseCenter = Offset(cx, snoutCenter.dy - 6);
    final nosePath = Path();
    nosePath.moveTo(noseCenter.dx - 10, noseCenter.dy - 3);
    nosePath.quadraticBezierTo(noseCenter.dx, noseCenter.dy - 7,
        noseCenter.dx + 10, noseCenter.dy - 3);
    nosePath.quadraticBezierTo(noseCenter.dx, noseCenter.dy + 8,
        noseCenter.dx - 10, noseCenter.dy - 3);
    nosePath.close();
    canvas.drawPath(nosePath, Paint()..color = eyeColor);

    // Little white shine on nose
    canvas.drawCircle(
        noseCenter + const Offset(-2, -2), 2.2, Paint()..color = Colors.white);

    // Happy smiling mouth with lip animation (closed, slightly open, wide open)
    final mouthPaint = Paint()
      ..color = eyeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;

    final mouthY = snoutCenter.dy + 3;
    canvas.drawLine(
        Offset(cx, noseCenter.dy + 4), Offset(cx, mouthY + 2), mouthPaint);

    final open = mouthOpenAmount.clamp(0.0, 1.0);

    if (open > 0.05) {
      // Animated mouth cavity (State 2: slightly open to State 3: wide open)
      final mouthWidth = 14.0 + open * 10.0;
      final mouthHeight = open * 14.0;
      final mouthTop = mouthY + 2.0;

      final cavityPath = Path()
        ..moveTo(cx - mouthWidth / 2, mouthTop)
        ..quadraticBezierTo(
            cx, mouthTop + mouthHeight * 1.25, cx + mouthWidth / 2, mouthTop)
        ..quadraticBezierTo(cx, mouthTop - 1.0, cx - mouthWidth / 2, mouthTop)
        ..close();

      // Deep friendly berry/warm inside mouth
      canvas.drawPath(
        cavityPath,
        Paint()
          ..color = const Color(0xFF6B1D2F)
          ..style = PaintingStyle.fill,
      );

      // Cute warm pink tongue
      final tonguePath = Path()
        ..moveTo(cx - mouthWidth * 0.32, mouthTop + mouthHeight * 0.6)
        ..quadraticBezierTo(cx, mouthTop + mouthHeight * 1.2,
            cx + mouthWidth * 0.32, mouthTop + mouthHeight * 0.6)
        ..close();

      canvas.drawPath(
        tonguePath,
        Paint()
          ..color = const Color(0xFFFF7E92)
          ..style = PaintingStyle.fill,
      );

      // Cavity outline for soft crisp definition
      canvas.drawPath(
        cavityPath,
        Paint()
          ..color = eyeColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2,
      );

      // Lip corners maintaining the cute smile shape
      final leftCorner = Path()
        ..moveTo(cx - mouthWidth / 2, mouthTop)
        ..quadraticBezierTo(cx - mouthWidth / 2 - 4, mouthTop - 2,
            cx - mouthWidth / 2 - 6, mouthTop - 4);
      canvas.drawPath(leftCorner, mouthPaint);

      final rightCorner = Path()
        ..moveTo(cx + mouthWidth / 2, mouthTop)
        ..quadraticBezierTo(cx + mouthWidth / 2 + 4, mouthTop - 2,
            cx + mouthWidth / 2 + 6, mouthTop - 4);
      canvas.drawPath(rightCorner, mouthPaint);
    } else {
      // Normal cute closed smiling mouth (State 1)
      final leftSmile = Path()
        ..moveTo(cx, mouthY + 2)
        ..quadraticBezierTo(cx - 8, mouthY + 9, cx - 14, mouthY + 4);
      canvas.drawPath(leftSmile, mouthPaint);

      final rightSmile = Path()
        ..moveTo(cx, mouthY + 2)
        ..quadraticBezierTo(cx + 8, mouthY + 9, cx + 14, mouthY + 4);
      canvas.drawPath(rightSmile, mouthPaint);
    }

    // Sparkling Eyes
    final eyeY = headCenter.dy + 1;
    for (final dir in [-1, 1]) {
      final eyeCenter = Offset(cx + dir * w * 0.16, eyeY);

      // Eye base
      canvas.drawCircle(eyeCenter, 8.5, Paint()..color = eyeColor);

      // Big sparkle highlight
      canvas.drawCircle(
        eyeCenter + const Offset(-2.5, -2.5),
        3.2,
        Paint()..color = Colors.white,
      );
      // Small sparkle highlight
      canvas.drawCircle(
        eyeCenter + const Offset(2.5, 2.5),
        1.4,
        Paint()..color = Colors.white,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TeddyPainter old) =>
      old.bob != bob ||
      old.waving != waving ||
      old.mouthOpenAmount != mouthOpenAmount;
}

/// Backward compatibility drop-in widget matching previous interface
class FloatyTeddy extends StatelessWidget {
  final AnimationController bob;
  final double size;
  final bool waving;

  const FloatyTeddy({
    super.key,
    required this.bob,
    this.size = 132,
    this.waving = false,
  });

  @override
  Widget build(BuildContext context) => TeddyMascot(
        bob: bob,
        size: size,
        waving: waving,
      );
}

/// Companion animal badge / avatar representation for children's age cards
class CompanionAvatar extends StatelessWidget {
  final String emoji;
  final Color bg;
  final double size;

  const CompanionAvatar({
    super.key,
    required this.emoji,
    required this.bg,
    this.size = 52,
  });

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: bg,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2.2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0D2850).withValues(alpha: 0.10),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          emoji,
          style: TextStyle(fontSize: size * 0.55),
        ),
      );
}
