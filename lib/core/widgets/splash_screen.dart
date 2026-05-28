import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
// 🔥 IMPORTAMOS SHARED PREFERENCES
import 'package:shared_preferences/shared_preferences.dart';

// ─────────────────────────────────────────────
//  TioSam · Splash Screen  (Senior-grade)
//  Animaciones: partículas, glow, shimmer, dots
// ─────────────────────────────────────────────

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // ── Controladores ──────────────────────────
  late AnimationController _mainCtrl;    // secuencia principal
  late AnimationController _glowCtrl;    // pulso del aura del logo
  late AnimationController _particleCtrl; // partículas de fondo
  late AnimationController _loadingCtrl; // dots de carga

  // ── Animaciones de la secuencia principal ──
  late Animation<double> _logoFade;
  late Animation<double> _logoScale;
  late Animation<double> _titleOffsetY;
  late Animation<double> _titleFade;
  late Animation<double> _subtitleFade;
  late Animation<double> _dividerScale;
  late Animation<double> _bottomBarFade;

  // ── Glow pulsante ──────────────────────────
  late Animation<double> _glowPulse;

  // ── Shimmer gradient para el título ────────
  late Animation<double> _shimmerPos;

  @override
  void initState() {
    super.initState();

    // ── Duración total de la secuencia ────────
    _mainCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    // ── Glow perpetuo ─────────────────────────
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    // ── Partículas en loop ────────────────────
    _particleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 6000),
    )..repeat();

    // ── Loading dots en loop ──────────────────
    _loadingCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    // ── Shimmer loop en el título ─────────────
    final shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
    _shimmerPos = Tween<double>(begin: -1.5, end: 2.5).animate(
      CurvedAnimation(parent: shimmerCtrl, curve: Curves.easeInOut),
    );

    // ─── Intervalos de la secuencia ───────────
    _logoFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _mainCtrl,
        curve: const Interval(0.00, 0.45, curve: Curves.easeOut),
      ),
    );

    _logoScale = Tween<double>(begin: 0.55, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainCtrl,
        curve: const Interval(0.00, 0.55, curve: Curves.elasticOut),
      ),
    );

    _titleOffsetY = Tween<double>(begin: 40, end: 0).animate(
      CurvedAnimation(
        parent: _mainCtrl,
        curve: const Interval(0.38, 0.65, curve: Curves.easeOutCubic),
      ),
    );

    _titleFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _mainCtrl,
        curve: const Interval(0.38, 0.65, curve: Curves.easeOut),
      ),
    );

    _dividerScale = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _mainCtrl,
        curve: const Interval(0.60, 0.78, curve: Curves.easeOutCubic),
      ),
    );

    _subtitleFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _mainCtrl,
        curve: const Interval(0.70, 0.88, curve: Curves.easeOut),
      ),
    );

    _bottomBarFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _mainCtrl,
        curve: const Interval(0.82, 1.00, curve: Curves.easeOut),
      ),
    );

    _glowPulse = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut),
    );

    // ── Arrancar secuencia principal ──────────
    _mainCtrl.forward();

    // 🔥 LA MAGIA DEL ONBOARDING OCURRE AQUÍ 🔥
    Timer(const Duration(milliseconds: 3200), _checkOnboardingStatus);
  }

  // 👇 NUEVA FUNCIÓN: El cerebro que decide a dónde enviar al usuario
  Future<void> _checkOnboardingStatus() async {
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    // Si 'hasSeenOnboarding' no existe, devuelve false (es usuario nuevo)
    final hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;

    if (mounted) {
      if (!hasSeenOnboarding) {
        // Es nuevo -> Al Onboarding
        context.go('/onboarding');
      } else {
        // Ya lo vio -> Al flujo normal (Market)
        // Nota: El app_router se encargará automáticamente de mandarlo a /login si no tiene sesión activa
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

  // ────────────────────────────────────────────
  //  BUILD
  // ────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // ── 1. Fondo con gradiente radial profundo ──
          _buildBackground(),

          // ── 2. Partículas flotantes ──────────────────
          AnimatedBuilder(
            animation: _particleCtrl,
            builder: (_, __) => CustomPaint(
              painter: _ParticlePainter(_particleCtrl.value),
              size: size,
            ),
          ),

          // ── 3. Orbe de glow detrás del logo ──────────
          _buildGlowOrb(),

          // ── 4. Contenido central ─────────────────────
          _buildCenterContent(),

          // ── 5. Bottom: dots de carga ──────────────────
          _buildBottomBar(),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────
  //  WIDGETS INTERNOS
  // ────────────────────────────────────────────

  Widget _buildBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0.0, -0.25),
          radius: 1.6,
          colors: [
            Color(0xFF160828), // centro: morado muy oscuro
            Color(0xFF0A0115), // medio
            Color(0xFF050010), // extremo: casi negro
          ],
          stops: [0.0, 0.55, 1.0],
        ),
      ),
    );
  }

  Widget _buildGlowOrb() {
    return Center(
      child: AnimatedBuilder(
        animation: _glowPulse,
        builder: (_, __) => Container(
          width: 260,
          height: 260,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF7C3AED)
                    .withOpacity(0.18 * _glowPulse.value),
                blurRadius: 90,
                spreadRadius: 50,
              ),
              BoxShadow(
                color: const Color(0xFFEC4899)
                    .withOpacity(0.08 * _glowPulse.value),
                blurRadius: 140,
                spreadRadius: 70,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCenterContent() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Logo ──────────────────────────────────
          AnimatedBuilder(
            animation: Listenable.merge([_logoFade, _logoScale, _glowPulse]),
            builder: (_, __) => Opacity(
              opacity: _logoFade.value.clamp(0.0, 1.0),
              child: Transform.scale(
                scale: _logoScale.value,
                child: _buildLogoContainer(),
              ),
            ),
          ),

          const SizedBox(height: 36),

          // ── Nombre con shimmer ─────────────────────
          AnimatedBuilder(
            animation: Listenable.merge([_titleFade, _titleOffsetY, _shimmerPos]),
            builder: (_, __) => Opacity(
              opacity: _titleFade.value.clamp(0.0, 1.0),
              child: Transform.translate(
                offset: Offset(0, _titleOffsetY.value),
                child: _buildShimmerTitle(),
              ),
            ),
          ),

          const SizedBox(height: 14),

          // ── Divider decorativo ─────────────────────
          AnimatedBuilder(
            animation: _dividerScale,
            builder: (_, __) => Transform.scale(
              scaleX: _dividerScale.value,
              child: _buildDivider(),
            ),
          ),

          const SizedBox(height: 14),

          // ── Subtítulo ─────────────────────────────
          AnimatedBuilder(
            animation: _subtitleFade,
            builder: (_, __) => Opacity(
              opacity: _subtitleFade.value.clamp(0.0, 1.0),
              child: const Text(
                'M A R K E T P L A C E  D E  A N I M E',
                style: TextStyle(
                  color: Color(0xFF9D6EFF),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 2.8,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoContainer() {
    return AnimatedBuilder(
      animation: _glowPulse,
      builder: (_, __) => Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              const Color(0xFF7C3AED).withOpacity(0.22),
              const Color(0xFF3B0D6B).withOpacity(0.10),
              Colors.transparent,
            ],
            stops: const [0.0, 0.55, 1.0],
          ),
          border: Border.all(
            color: const Color(0xFF7C3AED)
                .withOpacity(0.25 * _glowPulse.value),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7C3AED)
                  .withOpacity(0.45 * _glowPulse.value),
              blurRadius: 28,
              spreadRadius: 4,
            ),
            BoxShadow(
              color: const Color(0xFFEC4899)
                  .withOpacity(0.18 * _glowPulse.value),
              blurRadius: 50,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Image.asset(
          'assets/icon/app_icon_1024.png',
          width: 100,
          height: 100,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  Widget _buildShimmerTitle() {
    return ShaderMask(
      shaderCallback: (bounds) => LinearGradient(
        begin: Alignment(_shimmerPos.value - 1, 0),
        end: Alignment(_shimmerPos.value, 0),
        colors: const [
          Color(0xFFE2D4FF),
          Color(0xFFFFFFFF),
          Color(0xFFC084FC),
          Color(0xFFFFFFFF),
          Color(0xFFE2D4FF),
        ],
        stops: const [0.0, 0.35, 0.5, 0.65, 1.0],
      ).createShader(bounds),
      child: const Text(
        'TioSam',
        style: TextStyle(
          color: Colors.white,
          fontSize: 42,
          fontWeight: FontWeight.w900,
          letterSpacing: 4,
          height: 1.0,
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Línea izquierda
        Container(
          width: 40,
          height: 1,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.transparent, Color(0xFF7C3AED)],
            ),
          ),
        ),
        const SizedBox(width: 10),
        // Rombo central
        Transform.rotate(
          angle: pi / 4,
          child: Container(
            width: 5,
            height: 5,
            decoration: const BoxDecoration(
              color: Color(0xFFEC4899),
            ),
          ),
        ),
        const SizedBox(width: 10),
        // Línea derecha
        Container(
          width: 40,
          height: 1,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF7C3AED), Colors.transparent],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Positioned(
      bottom: 52,
      left: 0,
      right: 0,
      child: AnimatedBuilder(
        animation: Listenable.merge([_bottomBarFade, _loadingCtrl]),
        builder: (_, __) => Opacity(
          opacity: _bottomBarFade.value.clamp(0.0, 1.0),
          child: Column(
            children: [
              // Dots de carga animados
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (i) {
                  const phaseStep = 0.33;
                  final phase = (i * phaseStep);
                  final t = ((_loadingCtrl.value - phase + 1.0) % 1.0);
                  final scale = t < 0.5
                      ? 0.6 + (t / 0.5) * 0.7
                      : 1.3 - ((t - 0.5) / 0.5) * 0.7;
                  final opacity = t < 0.5 ? 0.3 + (t / 0.5) * 0.7 : 1.0 - ((t - 0.5) / 0.5) * 0.7;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    child: Transform.scale(
                      scale: scale.clamp(0.6, 1.3),
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color.lerp(
                            const Color(0xFF4C1D95),
                            const Color(0xFFC084FC),
                            opacity.clamp(0.0, 1.0),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF7C3AED)
                                  .withOpacity(opacity.clamp(0.0, 1.0) * 0.6),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 14),
              // Versión
              Text(
                'v1.0.0',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.18),
                  fontSize: 11,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  CUSTOM PAINTER: Partículas flotantes
//  Partículas suben lentamente con opacidad
//  variable y tamaños aleatorios pero fijos.
// ─────────────────────────────────────────────

class _ParticlePainter extends CustomPainter {
  final double progress;

  // Semilla fija: siempre las mismas 30 partículas
  static final List<_Particle> _particles = _buildParticles();

  _ParticlePainter(this.progress);

  static List<_Particle> _buildParticles() {
    final rng = Random(7);
    return List.generate(30, (_) {
      return _Particle(
        x: rng.nextDouble(),
        yOffset: rng.nextDouble(),
        size: rng.nextDouble() * 2.2 + 0.4,
        speed: rng.nextDouble() * 0.18 + 0.04,
        baseOpacity: rng.nextDouble() * 0.4 + 0.08,
        colorSeed: rng.nextDouble(), // 0→violeta, 1→rosa
      );
    });
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in _particles) {
      // Posición Y: sube con el tiempo
      final rawY = (p.yOffset - progress * p.speed) % 1.0;
      final y = rawY < 0 ? rawY + 1.0 : rawY;

      // Opacidad sinusoidal para efecto de respiración
      final breathe = 0.5 + 0.5 * sin(progress * 2 * pi * 0.7 + p.x * 12);
      final opacity = (p.baseOpacity * breathe).clamp(0.0, 1.0);

      // Color interpolado entre violeta y rosa
      final color = Color.lerp(
        const Color(0xFF7C3AED),
        const Color(0xFFEC4899),
        p.colorSeed,
      )!
          .withOpacity(opacity);

      final paint = Paint()
        ..color = color
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, p.size * 0.8);

      canvas.drawCircle(
        Offset(p.x * size.width, y * size.height),
        p.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.progress != progress;
}

class _Particle {
  final double x;
  final double yOffset;
  final double size;
  final double speed;
  final double baseOpacity;
  final double colorSeed;

  const _Particle({
    required this.x,
    required this.yOffset,
    required this.size,
    required this.speed,
    required this.baseOpacity,
    required this.colorSeed,
  });
}