import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lucide_icons/lucide_icons.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // 📖 El contenido mágico de tu tutorial
  final List<Map<String, dynamic>> _onboardingData = [
    {
      "title": "Bienvenido al Gremio",
      "description": "Descubre un mercado infinito de cartas. Encuentra esa pieza única que le falta a tu vitrina.",
      "icon": LucideIcons.sparkles,
      "color": const Color(0xFF3B82F6), // Azul
    },
    {
      "title": "Intercambios Seguros",
      "description": "Haz ofertas a otros coleccionistas, negocia en el chat en tiempo real y cierra tratos justos.",
      "icon": LucideIcons.arrowRightLeft,
      "color": const Color(0xFF8B5CF6), // Morado
    },
    {
      "title": "Conviértete en PRO",
      "description": "Destaca tus publicaciones, desbloquea la corona dorada y domina el mercado como un VIP.",
      "icon": LucideIcons.crown,
      "color": const Color(0xFFF59E0B), // Ambar
    },
  ];

  // 💾 Guardamos que ya lo vio y lo mandamos al Login/Home
  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true); // Marca de memoria

    if (mounted) {
      // Reemplaza '/login' por tu ruta inicial de autenticación
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
            },
            itemCount: _onboardingData.length,
            itemBuilder: (context, index) {
              final data = _onboardingData[index];
              return _buildPage(data);
            },
          ),

          // Indicador de puntitos y Botones
          Positioned(
            bottom: 40,
            left: 24,
            right: 24,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Puntitos (Dots)
                Row(
                  children: List.generate(
                    _onboardingData.length,
                        (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.only(right: 8),
                      height: 8,
                      width: _currentPage == index ? 24 : 8,
                      decoration: BoxDecoration(
                        color: _currentPage == index
                            ? _onboardingData[_currentPage]['color']
                            : Colors.grey.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),

                // Botón Siguiente / Comenzar
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _onboardingData[_currentPage]['color'],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () {
                    if (_currentPage == _onboardingData.length - 1) {
                      _completeOnboarding();
                    } else {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.ease,
                      );
                    }
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _currentPage == _onboardingData.length - 1 ? "Comenzar" : "Siguiente",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(width: 8),
                      Icon(_currentPage == _onboardingData.length - 1 ? Icons.check : Icons.arrow_forward_rounded),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Botón "Omitir" arriba a la derecha
          if (_currentPage != _onboardingData.length - 1)
            Positioned(
              top: 50,
              right: 20,
              child: TextButton(
                onPressed: _completeOnboarding,
                child: const Text(
                  "Omitir",
                  style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPage(Map<String, dynamic> data) {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: data['color'].withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(data['icon'], size: 100, color: data['color']),
          ),
          const SizedBox(height: 60),
          Text(
            data['title'],
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -0.5),
          ),
          const SizedBox(height: 20),
          Text(
            data['description'],
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600, height: 1.5),
          ),
          const SizedBox(height: 40), // Espacio para la zona de botones
        ],
      ),
    );
  }
}