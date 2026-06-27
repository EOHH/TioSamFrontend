import 'package:flutter/material.dart';

class AuthBackground extends StatelessWidget {
  final Widget formContent;
  final bool isRegister;

  const AuthBackground({
    super.key,
    required this.formContent,
    this.isRegister = false,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Fondo oscuro que combina con la imagen estelar
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // 1. Imagen de Fondo Ajustada (Evita el zoom extremo)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: size.height * 0.55, // Ocupa solo el 55% de arriba para que BoxFit.cover no tenga que hacer tanto zoom
            child: ShaderMask(
              shaderCallback: (rect) {
                return const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black, Colors.black, Colors.transparent],
                  stops: [0.0, 0.8, 1.0], // Difuminado suave en la parte inferior de la imagen
                ).createShader(rect);
              },
              blendMode: BlendMode.dstIn,
              child: Image.asset(
                'assets/images/auth_bg.png',
                fit: BoxFit.cover,
                alignment: const Alignment(-0.85, 0.0), // Alineado hacia la izquierda para mostrar el logo CARD TRADE
              ),
            ),
          ),

          // 2. Formulario adaptativo (Se dibuja sobre la imagen y el fondo oscuro)
          Align(
            alignment: Alignment.bottomCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: size.height * 0.9, // Máximo 90% de la pantalla
                minHeight: size.height * 0.5, // Mínimo 50% de la pantalla para evitar huecos vacíos
              ),
              child: formContent,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Botón CTA Reutilizable (Para no duplicarlo en Login y Register) ──
class AuthGradientButton extends StatelessWidget {
  final String label;
  final bool isLoading, isRegister;
  final VoidCallback? onTap;

  const AuthGradientButton({
    super.key,
    required this.label,
    required this.isLoading,
    this.isRegister = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Gradiente cyan a morado brillante
    final colors = const [Color(0xFF00C2FF), Color(0xFF7C4DFF)];
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 58,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: LinearGradient(
            colors: onTap == null
                ? colors.map((c) => c.withOpacity(0.4)).toList()
                : colors,
          ),
          boxShadow: onTap != null
              ? [
                  BoxShadow(
                    color: colors.last.withOpacity(0.4),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  )
                ]
              : [],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 3),
                )
              : Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
        ),
      ),
    );
  }
}