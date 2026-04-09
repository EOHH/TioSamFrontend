import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';

import '../controllers/auth_controller.dart';
import '../../../../core/widgets/custom_input.dart';

class RegisterScreen extends HookConsumerWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);

    final usernameController = useTextEditingController();
    final emailController = useTextEditingController();
    final passwordController = useTextEditingController();

    // Manejo de errores visual
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
      appBar: AppBar(
        title: const Text('Crear Cuenta'),
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.userPlus, size: 60, color: Theme.of(context).primaryColor),
                const SizedBox(height: 24),
                const Text(
                  "Únete al Gremio",
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 32),

                // Campo Username
                CustomInput(
                  controller: usernameController,
                  label: "Nombre de usuario (Otaku Name)",
                  icon: LucideIcons.user,
                ),
                const SizedBox(height: 16),

                // Campo Email
                CustomInput(
                  controller: emailController,
                  label: "Email",
                  icon: LucideIcons.mail,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),

                // Campo Password
                CustomInput(
                  controller: passwordController,
                  label: "Contraseña",
                  icon: LucideIcons.lock,
                  obscureText: true,
                ),
                const SizedBox(height: 24),

                // Botón de Registro
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: authState.isLoading
                        ? null
                        : () {
                      FocusScope.of(context).unfocus();
                      ref.read(authControllerProvider.notifier).signUp(
                        emailController.text.trim(),
                        passwordController.text.trim(),
                        usernameController.text.trim(),
                      );
                    },
                    child: authState.isLoading
                        ? const SizedBox(
                      height: 24, width: 24,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                        : const Text(
                      "Comenzar mi Colección",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}