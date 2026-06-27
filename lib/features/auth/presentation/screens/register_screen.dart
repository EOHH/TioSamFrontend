import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../controllers/auth_controller.dart';
import '../widgets/auth_background.dart';

class RegisterScreen extends HookConsumerWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final usernameController = useTextEditingController();
    final emailController = useTextEditingController();
    final passwordController = useTextEditingController();

    ref.listen<AsyncValue<void>>(authControllerProvider, (_, next) {
      if (next is AsyncError) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(next.error.toString()), backgroundColor: Colors.redAccent));
      }
    });

    return Stack(
      children: [
        AuthBackground(
          isRegister: true,
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
                  Text('¡Crea tu cuenta! 🚀',
                      style: GoogleFonts.poppins(
                          color: const Color(0xFF1E1E24), fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                  const SizedBox(height: 8),
                  Text('Únete a miles de coleccionistas y empieza\na intercambiar cartas increíbles.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(color: Colors.grey.shade600, fontSize: 13)),
                  const SizedBox(height: 30),

                  _GamifiedInput(
                    controller: usernameController,
                    hintText: 'Nombre de usuario (Otaku Name)',
                    icon: LucideIcons.user,
                  ),
                  const SizedBox(height: 16),
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
                  const SizedBox(height: 20),

                  // Caja de seguridad
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C4DFF).withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF7C4DFF).withOpacity(0.1)),
                    ),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.shieldCheck, color: Color(0xFF7C4DFF), size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Tu cuenta está 100% segura',
                                  style: GoogleFonts.poppins(color: const Color(0xFF1E1E24), fontWeight: FontWeight.bold, fontSize: 13)),
                              Text('Usamos encriptación avanzada para proteger tu información.',
                                  style: GoogleFonts.poppins(color: Colors.grey.shade600, fontSize: 11)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  AuthGradientButton(
                    label: 'Crear Cuenta',
                    isRegister: true,
                    isLoading: authState.isLoading,
                    onTap: authState.isLoading ? null : () {
                      FocusScope.of(context).unfocus();

                      final username = usernameController.text.trim();
                      final email = emailController.text.trim().toLowerCase();
                      final password = passwordController.text.trim();

                      if (username.isEmpty || email.isEmpty || password.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Por favor, llena todos los campos.')));
                        return;
                      }

                      if (!email.contains('@')) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Formato de correo inválido.')));
                        return;
                      }

                      final blockedDomains = ['test.com', 'example.com', 'asdf.com', 'yopmail.com', 'mailinator.com', '123.com'];
                      final domain = email.split('@').last;

                      if (blockedDomains.contains(domain)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Por favor, usa un proveedor de correo válido (Gmail, Outlook, etc).'),
                              backgroundColor: Colors.orange,
                            ));
                        return;
                      }

                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Formato de correo inválido.')));
                        return;
                      }

                      ref.read(authControllerProvider.notifier).signUp(email, password, username);
                    },
                  ),

                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('¿Ya tienes una cuenta? ', style: GoogleFonts.poppins(color: Colors.grey.shade600)),
                      GestureDetector(
                        onTap: () => context.pop(),
                        child: Text('Inicia sesión',
                            style: GoogleFonts.poppins(color: const Color(0xFF7C4DFF), fontWeight: FontWeight.w900)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),

        // Botón de Volver
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(left: 12, top: 8),
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.2)),
                child: const Icon(LucideIcons.arrowLeft, color: Colors.white, size: 20),
              ),
              onPressed: () => context.pop(),
            ),
          ),
        ),
      ],
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