import 'dart:math';
import 'package:flutter/material.dart';
import '../models/ram_model.dart';

class RamCircleGauge extends StatefulWidget {
  final RamStats stats;
  const RamCircleGauge({super.key, required this.stats});
  @override
  State<RamCircleGauge> createState() => _RamCircleGaugeState();
}

class _RamCircleGaugeState extends State<RamCircleGauge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(RamCircleGauge old) {
    super.didUpdateWidget(old);
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (_, _) => SizedBox(
        width: 240,
        height: 240,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Outer glow ring
            Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF3CAC).withValues(alpha: 0.12),
                    blurRadius: 40,
                    spreadRadius: 8,
                  ),
                  BoxShadow(
                    color: const Color(0xFF7B61FF).withValues(alpha: 0.08),
                    blurRadius: 60,
                    spreadRadius: 12,
                  ),
                ],
              ),
            ),
            // The actual painted arcs
            CustomPaint(
              size: const Size(240, 240),
              painter: _GaugePainter(
                usedPercent: widget.stats.usedPercent * _animation.value,
                remainingPercent:
                    widget.stats.remainingPercent * _animation.value,
              ),
            ),
            // Center content
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${(widget.stats.usedPercent * _animation.value * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -1,
                  ),
                ),
                const Text(
                  'USED',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 10,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: 40,
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.white.withValues(alpha: 0.3),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '${widget.stats.usedRam.toStringAsFixed(6)} MB',
                  style: const TextStyle(
                    color: Color(0xFFFF3CAC),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '/ ${widget.stats.totalRam.toStringAsFixed(2)} MB',
                  style: const TextStyle(color: Colors.white30, fontSize: 10),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double usedPercent;
  final double remainingPercent;

  _GaugePainter({required this.usedPercent, required this.remainingPercent});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = min(size.width, size.height) / 2 - 8;
    final innerRadius = outerRadius - 20;
    const startAngle = -pi * 0.75;
    const sweepFull = pi * 1.5;

    // ── Track (background ring) ──
    final trackPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: outerRadius),
      startAngle,
      sweepFull,
      false,
      trackPaint,
    );

    // ── Used arc ──
    if (usedPercent > 0.001) {
      final usedPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 20
        ..strokeCap = StrokeCap.round
        ..shader = SweepGradient(
          startAngle: startAngle,
          endAngle: startAngle + sweepFull,
          colors: const [
            Color(0xFFFF6B35),
            Color(0xFFFF3CAC),
            Color(0xFF7B61FF),
          ],
          stops: const [0.0, 0.5, 1.0],
          tileMode: TileMode.clamp,
        ).createShader(Rect.fromCircle(center: center, radius: outerRadius));

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: outerRadius),
        startAngle,
        sweepFull * usedPercent,
        false,
        usedPaint,
      );

      // Glow effect on used arc tip
      final glowAngle = startAngle + sweepFull * usedPercent;
      final glowX = center.dx + outerRadius * cos(glowAngle);
      final glowY = center.dy + outerRadius * sin(glowAngle);
      final glowPaint = Paint()
        ..color = const Color(0xFFFF3CAC).withValues(alpha: 0.6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(Offset(glowX, glowY), 10, glowPaint);
      canvas.drawCircle(Offset(glowX, glowY), 5, Paint()..color = Colors.white);
    }

    // ── Remaining arc (inner, thinner) ──
    if (remainingPercent > 0.001) {
      final remPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round
        ..shader = SweepGradient(
          startAngle: startAngle + sweepFull * usedPercent,
          endAngle: startAngle + sweepFull,
          colors: const [Color(0xFF00F5A0), Color(0xFF00D9F5)],
          tileMode: TileMode.clamp,
        ).createShader(Rect.fromCircle(center: center, radius: innerRadius));

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: innerRadius),
        startAngle + sweepFull * usedPercent,
        sweepFull * remainingPercent,
        false,
        remPaint,
      );
    }

    // ── Tick marks ──
    _drawTicks(canvas, center, outerRadius + 14, size);
  }

  void _drawTicks(Canvas canvas, Offset center, double r, Size size) {
    const tickCount = 24;
    const sweepFull = pi * 1.5;
    const startAngle = -pi * 0.75;
    final tickPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i <= tickCount; i++) {
      final angle = startAngle + (sweepFull / tickCount) * i;
      final inner = r - 5;
      final outer = r;
      canvas.drawLine(
        Offset(center.dx + inner * cos(angle), center.dy + inner * sin(angle)),
        Offset(center.dx + outer * cos(angle), center.dy + outer * sin(angle)),
        tickPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_GaugePainter old) =>
      old.usedPercent != usedPercent ||
      old.remainingPercent != remainingPercent;
}
