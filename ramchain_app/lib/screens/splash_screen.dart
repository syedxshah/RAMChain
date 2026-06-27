import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const SplashScreen({super.key, required this.onComplete});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _blobCtrl;
  late AnimationController _introCtrl;
  late AnimationController _exitCtrl;

  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;
  late Animation<double> _blurAnim;
  late Animation<double> _exitFade;

  @override
  void initState() {
    super.initState();

    // Infinite slow blob rotation
    _blobCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 12))
      ..repeat();

    // Intro sequence (logo scale, fade, text reveal)
    _introCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2400));

    // Exit sequence
    _exitCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));

    _scaleAnim = TweenSequence([
      TweenSequenceItem(
          tween: Tween<double>(begin: 0.8, end: 1.05)
              .chain(CurveTween(curve: Curves.easeOutCubic)),
          weight: 60),
      TweenSequenceItem(
          tween: Tween<double>(begin: 1.05, end: 1.0)
              .chain(CurveTween(curve: Curves.easeInOutSine)),
          weight: 40),
    ]).animate(_introCtrl);

    _fadeAnim = CurvedAnimation(
        parent: _introCtrl,
        curve: const Interval(0.1, 0.7, curve: Curves.easeOut));

    _blurAnim = Tween<double>(begin: 20.0, end: 0.0).animate(
      CurvedAnimation(
          parent: _introCtrl,
          curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic)),
    );

    _exitFade = Tween<double>(begin: 1.0, end: 0.0).animate(
        CurvedAnimation(parent: _exitCtrl, curve: Curves.easeInOut));

    // Start intro
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _introCtrl.forward();
    });

    // Exit after ~4s total
    Future.delayed(const Duration(milliseconds: 3800), () async {
      if (mounted) {
        await _exitCtrl.forward();
        widget.onComplete();
      }
    });
  }

  @override
  void dispose() {
    _blobCtrl.dispose();
    _introCtrl.dispose();
    _exitCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _exitCtrl,
      builder: (_, child) => FadeTransition(opacity: _exitFade, child: child),
      child: Scaffold(
        backgroundColor: const Color(0xFF07070F), // ultra dark background
        body: Stack(
          alignment: Alignment.center,
          children: [
            // ── Cinematic Ambient Orbs ──
            AnimatedBuilder(
              animation: _blobCtrl,
              builder: (_, __) => _AmbientBlobs(progress: _blobCtrl.value),
            ),
            
            // ── Glass Overlay ──
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: Container(color: Colors.black.withValues(alpha: 0.2)),
            ),

            // ── Grid Overlay (Tech feel) ──
            CustomPaint(
              size: Size.infinite,
              painter: _GridPainter(),
            ),

            // ── Main Content (Logo & Text) ──
            AnimatedBuilder(
              animation: _introCtrl,
              builder: (_, child) {
                return FadeTransition(
                  opacity: _fadeAnim,
                  child: Transform.scale(
                    scale: _scaleAnim.value,
                    child: ImageFilterWidget(
                      sigma: _blurAnim.value,
                      child: child!,
                    ),
                  ),
                );
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 3D Glass Logo
                  const _GlassLogo(),
                  const SizedBox(height: 32),
                  // Title
                  const Text(
                    'RAMChain',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 42,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                      shadows: [
                        Shadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, 4)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Subtitle
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: const Text(
                      'IN-MEMORY DATABASE',
                      style: TextStyle(
                        color: Color(0xFF00F5A0),
                        fontSize: 10,
                        letterSpacing: 6,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 60),
                  // Cinematic Loading Bar
                  const _CinematicLoader(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Cinematic Ambient Blobs ──────────────────────────────────────────────────

class _AmbientBlobs extends StatelessWidget {
  final double progress;
  const _AmbientBlobs({required this.progress});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final w = size.width;
    final h = size.height;

    // Movement paths
    final p1x = w / 2 + cos(progress * 2 * pi) * (w * 0.3);
    final p1y = h / 2 + sin(progress * 2 * pi) * (h * 0.2);

    final p2x = w / 2 + sin(progress * 2 * pi + pi) * (w * 0.4);
    final p2y = h / 2 + cos(progress * 2 * pi + pi) * (h * 0.3);

    final p3x = w / 2 + cos(progress * 4 * pi) * (w * 0.2);
    final p3y = h / 2 + sin(progress * 4 * pi) * (h * 0.4);

    return Stack(
      children: [
        Positioned(
          left: p1x - 200, top: p1y - 200,
          child: _Blob(color: const Color(0xFF7B61FF), size: 400),
        ),
        Positioned(
          left: p2x - 250, top: p2y - 250,
          child: _Blob(color: const Color(0xFFFF3CAC), size: 500),
        ),
        Positioned(
          left: p3x - 150, top: p3y - 150,
          child: _Blob(color: const Color(0xFF00D9F5), size: 300),
        ),
      ],
    );
  }
}

class _Blob extends StatelessWidget {
  final Color color;
  final double size;
  const _Blob({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.4),
      ),
    );
  }
}

// ── Grid Background ───────────────────────────────────────────────────────────

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.02)
      ..strokeWidth = 1.0;

    const spacing = 40.0;
    
    // Draw vertical lines
    for (double x = 0; x <= size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    
    // Draw horizontal lines
    for (double y = 0; y <= size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Vignette
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final gradient = RadialGradient(
      center: Alignment.center,
      radius: 1.0,
      colors: [Colors.transparent, const Color(0xFF07070F).withValues(alpha: 0.8)],
      stops: const [0.4, 1.0],
    );
    canvas.drawRect(rect, Paint()..shader = gradient.createShader(rect));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── 3D Glass Logo ─────────────────────────────────────────────────────────────

class _GlassLogo extends StatelessWidget {
  const _GlassLogo();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer glow
        Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF7B61FF).withValues(alpha: 0.4),
                blurRadius: 40,
                spreadRadius: 5,
              ),
            ],
          ),
        ),
        // Glass Morphism Circle
        ClipOval(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.2),
                    Colors.white.withValues(alpha: 0.05),
                  ],
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.memory_rounded,
                size: 56,
                color: Colors.white,
              ),
            ),
          ),
        ),
        // Premium Specular Highlight
        Positioned(
          top: 15,
          left: 30,
          child: Container(
            width: 40,
            height: 20,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: LinearGradient(
                colors: [
                  Colors.white.withValues(alpha: 0.5),
                  Colors.transparent,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Cinematic Loading Bar ─────────────────────────────────────────────────────

class _CinematicLoader extends StatefulWidget {
  const _CinematicLoader();

  @override
  State<_CinematicLoader> createState() => _CinematicLoaderState();
}

class _CinematicLoaderState extends State<_CinematicLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2500))
      ..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) {
            return Container(
              width: 200,
              height: 2,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(1),
              ),
              alignment: Alignment.centerLeft,
              child: Container(
                width: 200 * Curves.easeInOutCubic.transform(_ctrl.value),
                height: 2,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(1),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7B61FF), Color(0xFF00F5A0)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00F5A0).withValues(alpha: 0.6),
                      blurRadius: 6,
                    )
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) => Opacity(
            opacity: _ctrl.value > 0.8 ? 1.0 : (_ctrl.value + 0.2).clamp(0.0, 1.0),
            child: Text(
              _ctrl.value == 1.0 ? 'SYSTEM READY' : 'INITIALIZING CORE...',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 9,
                letterSpacing: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Utility ───────────────────────────────────────────────────────────────────

class ImageFilterWidget extends StatelessWidget {
  final double sigma;
  final Widget child;

  const ImageFilterWidget({super.key, required this.sigma, required this.child});

  @override
  Widget build(BuildContext context) {
    if (sigma <= 0.0) return child;
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
      child: child,
    );
  }
}
