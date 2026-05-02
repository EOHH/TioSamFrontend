import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';

import '../controllers/auth_controller.dart';
import '../../../../core/widgets/custom_input.dart';
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(next.error.toString()), backgroundColor: Colors.redAccent));
      }
    });

    return AuthBackground(
      panelHeightRatio: 0.60,
      formContent: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(28, 36, 28, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('¡Bienvenido,', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900)),
            ShaderMask(
              shaderCallback: (b) => const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFFEC4899)]).createShader(b),
              child: const Text('Collector!', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900)),
            ),
            const SizedBox(height: 6),
            Text('Ingresa para continuar tus intercambios', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13)),
            const SizedBox(height: 32),

            CustomInput(controller: emailController, label: 'Correo electrónico', icon: LucideIcons.mail, keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 16),
            CustomInput(controller: passwordController, label: 'Contraseña', icon: LucideIcons.lock, isPassword: true),

            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {},
                child: Text('¿Olvidaste tu contraseña?', style: TextStyle(color: const Color(0xFFC084FC).withOpacity(0.75))),
              ),
            ),

            AuthGradientButton(
              label: 'Entrar al Gremio',
              isLoading: authState.isLoading,
              onTap: authState.isLoading ? null : () {
                FocusScope.of(context).unfocus();
                ref.read(authControllerProvider.notifier).login(emailController.text.trim(), passwordController.text.trim());
              },
            ),

            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('¿No tienes cuenta?  ', style: TextStyle(color: Colors.white.withOpacity(0.5))),
                GestureDetector(
                  onTap: () => context.push('/register'),
                  child: ShaderMask(
                    shaderCallback: (b) => const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFFEC4899)]).createShader(b),
                    child: const Text('Regístrate aquí', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}