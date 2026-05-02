import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';

import '../controllers/auth_controller.dart';
import '../../../../core/widgets/custom_input.dart';
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(next.error.toString()), backgroundColor: Colors.redAccent));
      }
    });

    return Stack(
      children: [
        AuthBackground(
          isRegister: true,
          panelHeightRatio: 0.70, // Más alto porque tiene 3 inputs
          formContent: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(28, 36, 28, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Únete al', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900)),
                ShaderMask(
                  shaderCallback: (b) => const LinearGradient(colors: [Color(0xFFEC4899), Color(0xFF7C3AED)]).createShader(b),
                  child: const Text('Gremio!', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900)),
                ),
                const SizedBox(height: 6),
                Text('Prepara tu mazo para intercambiar', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13)),
                const SizedBox(height: 30),

                CustomInput(controller: usernameController, label: 'Nombre de usuario (Otaku Name)', icon: LucideIcons.user),
                const SizedBox(height: 16),
                CustomInput(controller: emailController, label: 'Correo electrónico', icon: LucideIcons.mail, keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 16),
                CustomInput(controller: passwordController, label: 'Contraseña', icon: LucideIcons.lock, isPassword: true),
                const SizedBox(height: 30),

                AuthGradientButton(
                  label: 'Comenzar mi Colección',
                  isRegister: true, // Invierte el color
                  isLoading: authState.isLoading,
                  onTap: authState.isLoading ? null : () {
                    FocusScope.of(context).unfocus();
                    ref.read(authControllerProvider.notifier).signUp(
                        emailController.text.trim(), passwordController.text.trim(), usernameController.text.trim()
                    );
                  },
                ),
              ],
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
                decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.1)),
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