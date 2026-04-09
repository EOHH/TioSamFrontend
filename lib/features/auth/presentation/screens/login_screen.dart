import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart'; // Añadido para navegación

import '../controllers/auth_controller.dart';
import '../../../../core/widgets/custom_input.dart';

class LoginScreen extends HookConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final emailController = useTextEditingController();
    final passwordController = useTextEditingController();

    ref.listen<AsyncValue<void>>(
      authControllerProvider,
          (previous, next) {
        if (next is AsyncError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(next.error.toString()),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      },
    );

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.boxes, size: 80, color: Theme.of(context).primaryColor),
                const SizedBox(height: 24),
                const Text("¡Bienvenido, Collector!", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text("Ingresa para continuar tus intercambios", style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
                const SizedBox(height: 32),

                CustomInput(controller: emailController, label: "Email", icon: LucideIcons.mail, keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 16),
                CustomInput(controller: passwordController, label: "Contraseña", icon: LucideIcons.lock, obscureText: true),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: authState.isLoading
                        ? null
                        : () {
                      FocusScope.of(context).unfocus();
                      ref.read(authControllerProvider.notifier).login(
                        emailController.text.trim(),
                        passwordController.text.trim(),
                      );
                    },
                    child: authState.isLoading
                        ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text("Entrar al Gremio", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),

                const SizedBox(height: 16),

                // NUEVO BOTÓN PARA IR A REGISTRO
                TextButton(
                  onPressed: () => context.push('/register'),
                  child: Text(
                    "¿No tienes cuenta? Regístrate aquí",
                    style: TextStyle(color: Theme.of(context).colorScheme.secondary),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}