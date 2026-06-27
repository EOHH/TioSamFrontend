import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';

class OnboardingFeature {
  final IconData icon;
  final Color color;
  final String text;

  OnboardingFeature({
    required this.icon,
    required this.color,
    required this.text,
  });
}

class OnboardingData {
  final String titlePart1;
  final String titlePart2;
  final String description;
  final String imagePath;
  final Color primaryColor;
  final List<OnboardingFeature> features;

  OnboardingData({
    required this.titlePart1,
    required this.titlePart2,
    required this.description,
    required this.imagePath,
    required this.primaryColor,
    required this.features,
  });
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingData> _pages = [
    OnboardingData(
      titlePart1: 'Bienvenido\n',
      titlePart2: 'al Gremio',
      description: 'Descubre un mercado infinito de cartas. Encuentra esa pieza única que le falta a tu vitrina.',
      imagePath: 'assets/images/onboarding_1.png',
      primaryColor: const Color(0xFF0066FF), // Azul
      features: [
        OnboardingFeature(icon: LucideIcons.sparkles, color: const Color(0xFF0066FF), text: 'Miles de cartas\npara coleccionar'),
        OnboardingFeature(icon: LucideIcons.search, color: const Color(0xFF0066FF), text: 'Encuentra\npiezas únicas'),
        OnboardingFeature(icon: LucideIcons.trophy, color: const Color(0xFF00C2FF), text: 'Completa tu\nmejor vitrina'),
      ],
    ),
    OnboardingData(
      titlePart1: 'Intercambios\n',
      titlePart2: 'Seguros',
      description: 'Haz ofertas a otros coleccionistas, negocia en el chat en tiempo real y cierra tratos justos.',
      imagePath: 'assets/images/onboarding_2.png',
      primaryColor: const Color(0xFF7C3AED), // Morado
      features: [
        OnboardingFeature(icon: LucideIcons.lock, color: const Color(0xFF7C3AED), text: 'Tratos 100%\nprotegidos'),
        OnboardingFeature(icon: LucideIcons.messageCircle, color: const Color(0xFF22C55E), text: 'Chat en tiempo\nreal'),
        OnboardingFeature(icon: LucideIcons.shieldCheck, color: const Color(0xFF0066FF), text: 'Soporte\nconfiable'),
      ],
    ),
    OnboardingData(
      titlePart1: 'Conviértete\n',
      titlePart2: 'en PRO 👑',
      description: 'Destaca tus publicaciones, desbloquea la corona dorada y domina el mercado como un VIP.',
      imagePath: 'assets/images/onboarding_3.png',
      primaryColor: const Color(0xFFFF8C00), // Naranja/Oro
      features: [
        OnboardingFeature(icon: LucideIcons.crown, color: const Color(0xFFFFB800), text: 'Destaca tus\ncartas'),
        OnboardingFeature(icon: LucideIcons.zap, color: const Color(0xFF7C3AED), text: 'Más\nvisibilidad'),
        OnboardingFeature(icon: LucideIcons.gem, color: const Color(0xFFEC4899), text: 'Beneficios\nexclusivos'),
      ],
    ),
  ];

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true);
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white, // Fondo BASE blanco para el difuminado perfecto
      body: Stack(
        children: [
          // IMAGEN DE FONDO DIFUMINADA HACIA BLANCO
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: size.height * 0.65, // Abarca el 65% de arriba
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              child: ShaderMask(
                key: ValueKey(_currentPage),
                shaderCallback: (rect) {
                  return const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black, // Color sólido en la parte superior
                      Colors.black,
                      Colors.transparent, // Transparente en la parte inferior para fundirse con el fondo blanco
                    ],
                    stops: [0.0, 0.6, 1.0], // Comienza a difuminarse al 60% de la altura de la imagen
                  ).createShader(rect);
                },
                blendMode: BlendMode.dstIn,
                child: Image.asset(
                  _pages[_currentPage].imagePath,
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                  width: double.infinity,
                  height: double.infinity,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _pages[_currentPage].primaryColor,
                            Colors.white,
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          // CONTENIDO DE TEXTO Y FEATURES EN LA PARTE INFERIOR BLANCA
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: size.height * 0.50, // El contenido ocupa el 50% de abajo (sobre un fondo que ya es blanco)
            child: PageView.builder(
              controller: _pageController,
              physics: const BouncingScrollPhysics(),
              onPageChanged: (index) => setState(() => _currentPage = index),
              itemCount: _pages.length,
              itemBuilder: (context, index) {
                final page = _pages[index];
                return Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Título Dinámico
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: GoogleFonts.poppins(fontSize: 34, fontWeight: FontWeight.w900, height: 1.1),
                          children: [
                            TextSpan(text: page.titlePart1, style: const TextStyle(color: Color(0xFF1E1E24))),
                            TextSpan(text: page.titlePart2, style: TextStyle(color: page.primaryColor)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Descripción
                      Text(
                        page.description,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade600, height: 1.5),
                      ),
                      const SizedBox(height: 30),
                      // Fila de Features (3 items)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: page.features.map((feature) {
                          return Expanded(
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(22), // Un poco más redondo para que sea más suave
                                    boxShadow: [
                                      // Sombra difuminada para el "Glow"
                                      BoxShadow(color: feature.color.withOpacity(0.15), blurRadius: 20, spreadRadius: 2, offset: const Offset(0, 8)),
                                    ],
                                    border: Border.all(
                                      color: feature.color.withOpacity(0.25), // Bordesito suave y atractivo
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Icon(feature.icon, color: feature.color, size: 28),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  feature.text,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF1E1E24)),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 80), // Espacio para los botones
                    ],
                  ),
                );
              },
            ),
          ),

          // CONTROLES INFERIORES (Paginación y Botón)
          Positioned(
            bottom: 40,
            left: 24,
            right: 24,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Indicadores (Dots)
                Row(
                  children: List.generate(
                    _pages.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.only(right: 6),
                      height: 8,
                      width: _currentPage == index ? 24 : 8,
                      decoration: BoxDecoration(
                        color: _currentPage == index ? _pages[_currentPage].primaryColor : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),

                // Botón Siguiente/Comenzar
                GestureDetector(
                  onTap: () {
                    if (_currentPage == _pages.length - 1) {
                      _completeOnboarding();
                    } else {
                      _pageController.nextPage(duration: const Duration(milliseconds: 500), curve: Curves.easeInOutCubic);
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: EdgeInsets.symmetric(
                      horizontal: _currentPage == _pages.length - 1 ? 24 : 32,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _currentPage == _pages.length - 1
                            ? [const Color(0xFFFF8C00), const Color(0xFFFF5500)] // Naranja fuego
                            : [_pages[_currentPage].primaryColor, _pages[_currentPage].primaryColor.withOpacity(0.8)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: _pages[_currentPage].primaryColor.withOpacity(0.4),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _currentPage == _pages.length - 1 ? "Comenzar 🚀" : "Siguiente",
                          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        if (_currentPage != _pages.length - 1) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                        ] else ...[
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                            child: const Icon(Icons.check_rounded, color: Color(0xFFFF5500), size: 16),
                          )
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // BOTÓN "SALTAR" (Arriba derecha)
          Positioned(
            top: 50,
            right: 20,
            child: GestureDetector(
              onTap: _completeOnboarding,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "Saltar",
                  style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}