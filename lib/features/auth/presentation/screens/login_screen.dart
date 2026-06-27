import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../controllers/auth_controller.dart';
import '../widgets/auth_background.dart';

class LoginScreen extends HookConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final emailController = useTextEditingController();
    final passwordController = useTextEditingController();

    ref.listen<AsyncValue<void>>(authControllerProvider, (_, next) {
      if (next is AsyncError) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(next.error.toString()), backgroundColor: Colors.redAccent));
      }
    });

    return AuthBackground(
      formContent: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7C4DFF).withOpacity(0.15),
              blurRadius: 25,
              offset: const Offset(0, -10),
            )
          ],
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(28, 36, 28, 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('¡Bienvenido de vuelta! 👋',
                  style: GoogleFonts.poppins(
                      color: const Color(0xFF1E1E24), fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
              const SizedBox(height: 8),
              Text('Inicia sesión para continuar intercambiando\ntus cartas favoritas.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(color: Colors.grey.shade600, fontSize: 13)),
              const SizedBox(height: 32),

              _GamifiedInput(
                controller: emailController,
                hintText: 'Correo electrónico',
                icon: LucideIcons.mail,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              _GamifiedInput(
                controller: passwordController,
                hintText: 'Contraseña',
                icon: LucideIcons.lock,
                isPassword: true,
              ),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  child: Text('¿Olvidaste tu contraseña?',
                      style: GoogleFonts.poppins(color: const Color(0xFF7C4DFF), fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ),
              const SizedBox(height: 16),

              AuthGradientButton(
                label: 'Iniciar Sesión',
                isLoading: authState.isLoading,
                onTap: authState.isLoading
                    ? null
                    : () {
                        FocusScope.of(context).unfocus();
                        ref.read(authControllerProvider.notifier).login(
                            emailController.text.trim(), passwordController.text.trim());
                      },
              ),

              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(height: 1, width: 40, color: Colors.grey.shade300),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text('o continúa con', style: GoogleFonts.poppins(color: Colors.grey.shade500, fontSize: 12)),
                  ),
                  Container(height: 1, width: 40, color: Colors.grey.shade300),
                ],
              ),
              const SizedBox(height: 20),

              // Mocked Social Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _SocialButton(iconColor: Colors.redAccent, icon: LucideIcons.mail), // Google placeholder
                  const SizedBox(width: 16),
                  _SocialButton(iconColor: Colors.blueAccent, icon: LucideIcons.facebook),
                  const SizedBox(width: 16),
                  _SocialButton(iconColor: Colors.black, icon: LucideIcons.apple),
                ],
              ),

              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('¿No tienes una cuenta? ', style: GoogleFonts.poppins(color: Colors.grey.shade600)),
                  GestureDetector(
                    onTap: () => context.push('/register'),
                    child: Text('Regístrate',
                        style: GoogleFonts.poppins(color: const Color(0xFF7C4DFF), fontWeight: FontWeight.w900)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  const _SocialButton({required this.icon, required this.iconColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Icon(icon, color: iconColor),
    );
  }
}

class _GamifiedInput extends HookWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final bool isPassword;
  final TextInputType? keyboardType;

  const _GamifiedInput({
    required this.controller,
    required this.hintText,
    required this.icon,
    this.isPassword = false,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    final focusNode = useFocusNode();
    final isFocused = useState(false);
    final isObscured = useState(isPassword);

    useEffect(() {
      void listener() => isFocused.value = focusNode.hasFocus;
      focusNode.addListener(listener);
      return () => focusNode.removeListener(listener);
    }, [focusNode]);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F8FF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isFocused.value ? const Color(0xFF00C2FF) : Colors.transparent,
          width: 2,
        ),
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        obscureText: isObscured.value,
        keyboardType: keyboardType,
        style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.black87),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: GoogleFonts.poppins(color: Colors.grey.shade500, fontWeight: FontWeight.w500),
          prefixIcon: Icon(icon, color: Colors.grey.shade500),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(isObscured.value ? LucideIcons.eye : LucideIcons.eyeOff, color: Colors.grey.shade500),
                  onPressed: () => isObscured.value = !isObscured.value,
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        ),
      ),
    );
  }
}