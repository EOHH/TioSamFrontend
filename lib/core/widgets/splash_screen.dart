import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────
//  TioSam · Splash Screen (Bright Gamified Premium)
// ─────────────────────────────────────────────

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _mainCtrl;
  late AnimationController _glowCtrl;
  late AnimationController _particleCtrl;
  late AnimationController _loadingCtrl;

  late Animation<double> _logoFade;
  late Animation<double> _logoScale;
  late Animation<double> _titleOffsetY;
  late Animation<double> _titleFade;
  late Animation<double> _subtitleFade;
  late Animation<double> _dividerScale;
  late Animation<double> _bottomBarFade;

  late Animation<double> _glowPulse;
  late Animation<double> _shimmerPos;

  @override
  void initState() {
    super.initState();

    _mainCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400));
    _glowCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))..repeat(reverse: true);
    _particleCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 6000))..repeat();
    _loadingCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();

    final shimmerCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat();
    _shimmerPos = Tween<double>(begin: -1.5, end: 2.5).animate(
      CurvedAnimation(parent: shimmerCtrl, curve: Curves.easeInOut),
    );

    _logoFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _mainCtrl, curve: const Interval(0.00, 0.45, curve: Curves.easeOut)),
    );
    _logoScale = Tween<double>(begin: 0.55, end: 1.0).animate(
      CurvedAnimation(parent: _mainCtrl, curve: const Interval(0.00, 0.55, curve: Curves.elasticOut)),
    );
    _titleOffsetY = Tween<double>(begin: 40, end: 0).animate(
      CurvedAnimation(parent: _mainCtrl, curve: const Interval(0.38, 0.65, curve: Curves.easeOutCubic)),
    );
    _titleFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _mainCtrl, curve: const Interval(0.38, 0.65, curve: Curves.easeOut)),
    );
    _dividerScale = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _mainCtrl, curve: const Interval(0.60, 0.78, curve: Curves.easeOutCubic)),
    );
    _subtitleFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _mainCtrl, curve: const Interval(0.70, 0.88, curve: Curves.easeOut)),
    );
    _bottomBarFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _mainCtrl, curve: const Interval(0.82, 1.00, curve: Curves.easeOut)),
    );

    _glowPulse = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut),
    );

    _mainCtrl.forward();

    Timer(const Duration(milliseconds: 3200), _checkOnboardingStatus);
  }

  Future<void> _checkOnboardingStatus() async {
    if (!mounted) return;
    final prefs = await SharedPreferences.getInstance();
    final hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;

    if (mounted) {
      if (!hasSeenOnboarding) {
        context.go('/onboarding');
      } else {
        context.go('/market');
      }
    }
  }

  @override
  void dispose() {
    _mainCtrl.dispose();
    _glowCtrl.dispose();
    _particleCtrl.dispose();
    _loadingCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // 1. Fondo Bright Premium (Cielo Azul/Mágico)
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0.0, -0.25),
                radius: 1.5,
                colors: [
                  Color(0xFF00C2FF), // Cyan brillante en el centro
                  Color(0xFF1E50FF), // Azul profundo
                  Color(0xFF0B0F24), // Azul nocturno en los bordes
                ],
                stops: [0.0, 0.6, 1.0],
              ),
            ),
          ),

          // 2. Partículas Flotantes (Polvo de estrellas/Gemas)
          AnimatedBuilder(
            animation: _particleCtrl,
            builder: (_, __) => CustomPaint(
              painter: _ParticlePainter(_particleCtrl.value),
              size: size,
            ),
          ),

          // 3. Orbe de Glow detrás del logo
          Center(
            child: AnimatedBuilder(
              animation: _glowPulse,
              builder: (_, __) => Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00C2FF).withOpacity(0.4 * _glowPulse.value),
                      blurRadius: 100,
                      spreadRadius: 40,
                    ),
                    BoxShadow(
                      color: const Color(0xFF7C4DFF).withOpacity(0.3 * _glowPulse.value),
                      blurRadius: 150,
                      spreadRadius: 80,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 4. Contenido Central
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo
                AnimatedBuilder(
                  animation: Listenable.merge([_logoFade, _logoScale, _glowPulse]),
                  builder: (_, __) => Opacity(
                    opacity: _logoFade.value.clamp(0.0, 1.0),
                    child: Transform.scale(
                      scale: _logoScale.value,
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00C2FF).withOpacity(0.5 * _glowPulse.value),
                              blurRadius: 30,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Image.asset(
                          'assets/icon/app_icon_1024.png',
                          width: 110,
                          height: 110,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 36),

                // Título con Shimmer Gamificado
                AnimatedBuilder(
                  animation: Listenable.merge([_titleFade, _titleOffsetY, _shimmerPos]),
                  builder: (_, __) => Opacity(
                    opacity: _titleFade.value.clamp(0.0, 1.0),
                    child: Transform.translate(
                      offset: Offset(0, _titleOffsetY.value),
                      child: ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(
                          begin: Alignment(_shimmerPos.value - 1, 0),
                          end: Alignment(_shimmerPos.value, 0),
                          colors: const [
                            Color(0xFFFFD700), // Oro
                            Color(0xFFFFFFFF), // Blanco brillo
                            Color(0xFFFFD700), // Oro
                          ],
                          stops: const [0.0, 0.5, 1.0],
                        ).createShader(bounds),
                        child: Text(
                          'CARD TRADE',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 42,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                            height: 1.0,
                            shadows: [
                              const Shadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, 4)),
                            ]
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // Divider Decorativo Moderno
                AnimatedBuilder(
                  animation: _dividerScale,
                  builder: (_, __) => Transform.scale(
                    scaleX: _dividerScale.value,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 50,
                          height: 3,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            gradient: const LinearGradient(
                              colors: [Colors.transparent, Color(0xFF00C2FF)],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Transform.rotate(
                          angle: pi / 4,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFD700),
                              boxShadow: [
                                BoxShadow(color: const Color(0xFFFFD700).withOpacity(0.5), blurRadius: 8),
                              ]
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 50,
                          height: 3,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            gradient: const LinearGradient(
                              colors: [Color(0xFF00C2FF), Colors.transparent],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // Subtítulo Gamificado
                AnimatedBuilder(
                  animation: _subtitleFade,
                  builder: (_, __) => Opacity(
                    opacity: _subtitleFade.value.clamp(0.0, 1.0),
                    child: Text(
                      'I N T E R C A M B I A   Y   C O L E C C I O N A',
                      style: GoogleFonts.poppins(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.0,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 5. Loading Dots y Versión
          Positioned(
            bottom: 52,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: Listenable.merge([_bottomBarFade, _loadingCtrl]),
              builder: (_, __) => Opacity(
                opacity: _bottomBarFade.value.clamp(0.0, 1.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(3, (i) {
                        const phaseStep = 0.33;
                        final phase = (i * phaseStep);
                        final t = ((_loadingCtrl.value - phase + 1.0) % 1.0);
                        final scale = t < 0.5 ? 0.6 + (t / 0.5) * 0.7 : 1.3 - ((t - 0.5) / 0.5) * 0.7;
                        final opacity = t < 0.5 ? 0.3 + (t / 0.5) * 0.7 : 1.0 - ((t - 0.5) / 0.5) * 0.7;
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          child: Transform.scale(
                            scale: scale.clamp(0.6, 1.3),
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF00C2FF).withOpacity(opacity.clamp(0.0, 1.0)),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'v1.0.1 Premium',
                      style: GoogleFonts.poppins(
                        color: Colors.white.withOpacity(0.3),
                        fontSize: 10,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Column(
                      children: [
                        Text(
                          'PATROCINADOR OFICIAL',
                          style: GoogleFonts.poppins(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 9,
                            letterSpacing: 2.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [Color(0xFF00C2FF), Color(0xFF7C4DFF)],
                          ).createShader(bounds),
                          child: Text(
                            'EDICIONES TIOSAM',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 3.0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  CUSTOM PAINTER: Partículas mágicas
// ─────────────────────────────────────────────

class _ParticlePainter extends CustomPainter {
  final double progress;
  static final List<_Particle> _particles = _buildParticles();

  _ParticlePainter(this.progress);

  static List<_Particle> _buildParticles() {
    final rng = Random(42);
    return List.generate(40, (_) {
      return _Particle(
        x: rng.nextDouble(),
        yOffset: rng.nextDouble(),
        size: rng.nextDouble() * 3.0 + 1.0,
        speed: rng.nextDouble() * 0.2 + 0.05,
        baseOpacity: rng.nextDouble() * 0.5 + 0.1,
        colorSeed: rng.nextDouble(),
      );
    });
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in _particles) {
      final rawY = (p.yOffset - progress * p.speed) % 1.0;
      final y = rawY < 0 ? rawY + 1.0 : rawY;

      final breathe = 0.5 + 0.5 * sin(progress * 2 * pi + p.x * 10);
      final opacity = (p.baseOpacity * breathe).clamp(0.0, 1.0);

      // Colores: Amarillo estrella, Cyan mágico, Blanco puro
      Color color;
      if (p.colorSeed < 0.3) {
        color = const Color(0xFFFFD700);
      } else if (p.colorSeed < 0.6) {
        color = const Color(0xFF00C2FF);
      } else {
        color = Colors.white;
      }

      final paint = Paint()
        ..color = color.withOpacity(opacity)
        ..maskFilter = MaskFilter.blur(BlurStyle.solid, p.size);

      // Dibujamos estrellitas/rombos en lugar de solo círculos
      if (p.colorSeed < 0.3) {
        final path = Path();
        final center = Offset(p.x * size.width, y * size.height);
        path.moveTo(center.dx, center.dy - p.size * 2);
        path.quadraticBezierTo(center.dx, center.dy, center.dx + p.size * 2, center.dy);
        path.quadraticBezierTo(center.dx, center.dy, center.dx, center.dy + p.size * 2);
        path.quadraticBezierTo(center.dx, center.dy, center.dx - p.size * 2, center.dy);
        path.close();
        canvas.drawPath(path, paint);
      } else {
        canvas.drawCircle(Offset(p.x * size.width, y * size.height), p.size, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.progress != progress;
}

class _Particle {
  final double x, yOffset, size, speed, baseOpacity, colorSeed;
  const _Particle({required this.x, required this.yOffset, required this.size, required this.speed, required this.baseOpacity, required this.colorSeed});
}