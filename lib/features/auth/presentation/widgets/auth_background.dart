import 'dart:ui';
import 'package:flutter/material.dart';

class AuthBackground extends StatelessWidget {
  final Widget formContent;
  final double panelHeightRatio;
  final bool isRegister;

  const AuthBackground({
    super.key,
    required this.formContent,
    this.panelHeightRatio = 0.64,
    this.isRegister = false,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // 1. Fondo Radial Base
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: isRegister ? const Alignment(0.3, -0.7) : const Alignment(0, -0.6),
                radius: 1.4,
                colors: isRegister
                    ? const [Color(0xFF3A0A5E), Color(0xFF1A0238), Color(0xFF070010)]
                    : const [Color(0xFF2D0A5E), Color(0xFF16023A), Color(0xFF070010)],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),

          // 2. Orbes Mágicos
          _DecorativeOrbs(size: size, isRegister: isRegister),

          // 3. Logo Flotante
          SafeArea(
            child: SizedBox(
              height: size.height * (1 - panelHeightRatio),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: const Color(0xFF7C3AED).withOpacity(0.50), blurRadius: 28),
                          BoxShadow(color: const Color(0xFFEC4899).withOpacity(0.20), blurRadius: 44),
                        ],
                      ),
                      child: Image.asset('assets/images/app_icon_1024.png', width: isRegister ? 60 : 72),
                    ),
                    const SizedBox(height: 14),
                    ShaderMask(
                      shaderCallback: (b) => const LinearGradient(
                        colors: [Colors.white, Color(0xFFC084FC), Colors.white],
                      ).createShader(b),
                      child: const Text(
                        'TioSam',
                        style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900, letterSpacing: 4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 4. Panel Inferior con GLASSMORPHISM REAL
          Align(
            alignment: Alignment.bottomCenter,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(44)),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15), // Efecto Cristal
                child: Container(
                  width: double.infinity,
                  height: size.height * panelHeightRatio,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF1C0A35).withOpacity(0.75), // Transparente para ver los orbes
                        const Color(0xFF0B011C).withOpacity(0.90),
                      ],
                    ),
                  ),
                  child: CustomPaint(
                    painter: _TopGradientBorderPainter(isRegister: isRegister),
                    child: formContent,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Componentes Internos del Background ──

class _DecorativeOrbs extends StatelessWidget {
  final Size size;
  final bool isRegister;
  const _DecorativeOrbs({required this.size, required this.isRegister});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -60, left: isRegister ? null : -60, right: isRegister ? -60 : null,
          child: _GlowBlob(size: 220, color: const Color(0xFF7C3AED).withOpacity(0.30)),
        ),
        Positioned(
          top: 40, right: isRegister ? null : -40, left: isRegister ? -40 : null,
          child: _GlowBlob(size: 160, color: const Color(0xFFEC4899).withOpacity(0.22)),
        ),
        Positioned(
          top: size.height * 0.34, left: -20,
          child: _GlowBlob(size: 180, color: const Color(0xFF7C3AED).withOpacity(0.28)),
        ),
      ],
    );
  }
}

class _GlowBlob extends StatelessWidget {
  final double size;
  final Color color;
  const _GlowBlob({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: color, blurRadius: 80)]),
    );
  }
}

class _TopGradientBorderPainter extends CustomPainter {
  final bool isRegister;
  const _TopGradientBorderPainter({required this.isRegister});
  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndCorners(Offset.zero & size, topLeft: const Radius.circular(44), topRight: const Radius.circular(44));
    final paint = Paint()
      ..shader = LinearGradient(colors: isRegister ? [const Color(0xFFEC4899), const Color(0xFF7C3AED)] : [const Color(0xFF7C3AED), const Color(0xFFEC4899)]).createShader(Rect.fromLTWH(0, 0, size.width, 4))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    canvas.drawRRect(rrect, paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Botón CTA Reutilizable (Para no duplicarlo en Login y Register) ──
class AuthGradientButton extends StatelessWidget {
  final String label;
  final bool isLoading, isRegister;
  final VoidCallback? onTap;

  const AuthGradientButton({super.key, required this.label, required this.isLoading, this.isRegister = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = isRegister ? const [Color(0xFFEC4899), Color(0xFF7C3AED)] : const [Color(0xFF7C3AED), Color(0xFFEC4899)];
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 58, width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: LinearGradient(colors: onTap == null ? colors.map((c) => c.withOpacity(0.4)).toList() : colors),
          boxShadow: onTap != null ? [BoxShadow(color: colors.first.withOpacity(0.4), blurRadius: 24, offset: const Offset(0, 6))] : [],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Text(label, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 0.8)),
        ),
      ),
    );
  }
}