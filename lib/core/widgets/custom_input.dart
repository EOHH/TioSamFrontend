import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lucide_icons/lucide_icons.dart';

class CustomInput extends HookWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool isPassword;
  final TextInputType? keyboardType;

  const CustomInput({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.isPassword = false,
    this.keyboardType,
  });

  static const _violet = Color(0xFF7C3AED);
  static const _pink   = Color(0xFFEC4899);
  static const _lilac  = Color(0xFFC084FC);

  @override
  Widget build(BuildContext context) {
    final obscureText = useState(isPassword);
    final focusNode   = useFocusNode();
    final isFocused   = useState(false);

    useEffect(() {
      void listener() => isFocused.value = focusNode.hasFocus;
      focusNode.addListener(listener);
      return () => focusNode.removeListener(listener);
    }, [focusNode]);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: isFocused.value
            ? [
          BoxShadow(color: _violet.withOpacity(0.30), blurRadius: 20, offset: const Offset(0, 4)),
          BoxShadow(color: _pink.withOpacity(0.12), blurRadius: 32, spreadRadius: 2),
        ]
            : [
          BoxShadow(color: Colors.black.withOpacity(0.20), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: _GradientBorderContainer(
        isFocused: isFocused.value,
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          obscureText: obscureText.value,
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.white, fontSize: 15.5, letterSpacing: 0.3),
          cursorColor: _lilac,
          decoration: InputDecoration(
            hintText: label,
            hintStyle: TextStyle(color: Colors.white.withOpacity(isFocused.value ? 0.35 : 0.28), fontSize: 14.5),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 18, right: 12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                child: ShaderMask(
                  blendMode: BlendMode.srcIn,
                  shaderCallback: (bounds) => LinearGradient(
                    colors: isFocused.value ? [_violet, _pink] : [Colors.white30, Colors.white30],
                  ).createShader(bounds),
                  child: Icon(icon, size: 20),
                ),
              ),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 54, minHeight: 56),
            suffixIcon: isPassword
                ? _EyeToggle(
              isObscured: obscureText.value,
              isFocused: isFocused.value,
              onTap: () => obscureText.value = !obscureText.value,
            )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 19, horizontal: 4),
          ),
        ),
      ),
    );
  }
}

class _GradientBorderContainer extends StatelessWidget {
  final bool isFocused;
  final Widget child;

  const _GradientBorderContainer({required this.isFocused, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: isFocused
              ? [const Color(0xFF7C3AED).withOpacity(0.15), const Color(0xFFEC4899).withOpacity(0.05)]
              : [Colors.white.withOpacity(0.04), Colors.white.withOpacity(0.01)],
        ),
      ),
      child: CustomPaint(
        painter: _GradientBorderPainter(isFocused: isFocused),
        child: child,
      ),
    );
  }
}

class _GradientBorderPainter extends CustomPainter {
  final bool isFocused;
  const _GradientBorderPainter({required this.isFocused});

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(18));
    final gradient = isFocused
        ? const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFFEC4899)])
        : LinearGradient(colors: [Colors.white.withOpacity(0.15), Colors.white.withOpacity(0.05)]);

    final paint = Paint()
      ..shader = gradient.createShader(Offset.zero & size)
      ..style = PaintingStyle.stroke
      ..strokeWidth = isFocused ? 1.6 : 1.0;
    canvas.drawRRect(rrect, paint);
  }
  @override
  bool shouldRepaint(_GradientBorderPainter old) => old.isFocused != isFocused;
}

class _EyeToggle extends StatelessWidget {
  final bool isObscured, isFocused;
  final VoidCallback onTap;
  const _EyeToggle({required this.isObscured, required this.isFocused, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: ShaderMask(
        blendMode: BlendMode.srcIn,
        shaderCallback: (bounds) => LinearGradient(
          colors: isFocused ? [const Color(0xFF7C3AED), const Color(0xFFEC4899)] : [Colors.white54, Colors.white54],
        ).createShader(bounds),
        child: Icon(isObscured ? LucideIcons.eyeOff : LucideIcons.eye, size: 19),
      ),
    );
  }
}