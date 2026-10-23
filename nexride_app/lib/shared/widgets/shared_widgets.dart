import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Glass-effect card used throughout the app
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final Color? color;

  const GlassCard({super.key, required this.child, this.padding, this.borderRadius = 20, this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color ?? (isDark ? AppTheme.bgCard : Colors.white),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: isDark ? AppTheme.glassBorder : AppTheme.glassBorderLt, width: 1),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.3 : 0.07), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: child,
    );
  }
}

/// Crowd level badge chip
class CrowdBadge extends StatelessWidget {
  final String level;
  const CrowdBadge({super.key, required this.level});
  @override
  Widget build(BuildContext context) {
    final color = level == 'High' ? AppTheme.error : level == 'Medium' ? AppTheme.warning : AppTheme.success;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.people_rounded, size: 12, color: color),
        const SizedBox(width: 4),
        Text(level, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

/// Legacy NexButton (used in non-auth screens)
class NexButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool loading;
  final bool outlined;
  final IconData? icon;

  const NexButton({super.key, required this.label, this.onTap, this.loading = false, this.outlined = false, this.icon});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: outlined
          ? OutlinedButton.icon(
              onPressed: loading ? null : onTap,
              icon: icon != null ? Icon(icon, size: 18) : const SizedBox.shrink(),
              label: loading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(label),
            )
          : Container(
              decoration: BoxDecoration(
                gradient: loading ? null : AppTheme.primaryGradient,
                color: loading ? AppTheme.bgCard : null,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: loading ? null : onTap,
                  child: Center(
                    child: loading
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                            if (icon != null) ...[Icon(icon, size: 18, color: Colors.white), const SizedBox(width: 8)],
                            Text(label, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                          ]),
                  ),
                ),
              ),
            ),
    );
  }
}

/// NexTextField (legacy — used in OTP, ForgotPassword, etc.)
class NexTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscure;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;

  const NexTextField({
    super.key, required this.controller, required this.hint,
    this.prefixIcon, this.suffixIcon, this.obscure = false,
    this.keyboardType = TextInputType.text, this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 20) : null,
        suffixIcon: suffixIcon,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared Auth Buttons  (Login + Register both use these)
// ─────────────────────────────────────────────────────────────────────────────

/// Gradient primary button with scale-press animation and loading state.
class PressableButton extends StatefulWidget {
  final String label;
  final bool loading;
  final VoidCallback? onTap;
  const PressableButton({super.key, required this.label, this.loading = false, this.onTap});
  @override
  State<PressableButton> createState() => _PressableButtonState();
}

class _PressableButtonState extends State<PressableButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _scale;

  @override
  void initState() {
    super.initState();
    _ctrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 110));
    _scale = Tween<double>(begin: 1.0, end: 0.96)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }
  @override void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown:   (_) => _ctrl.forward(),
      onTapUp:     (_) { _ctrl.reverse(); widget.onTap?.call(); },
      onTapCancel: ()  => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: double.infinity, height: 54,
          decoration: BoxDecoration(
            gradient: widget.loading ? null : AppTheme.primaryGradient,
            color: widget.loading ? AppTheme.primary.withOpacity(0.5) : null,
            borderRadius: BorderRadius.circular(14),
            boxShadow: widget.loading ? [] : [
              BoxShadow(color: AppTheme.primary.withOpacity(0.35), blurRadius: 14, offset: const Offset(0, 5)),
            ],
          ),
          child: Center(
            child: widget.loading
                ? const SizedBox(width: 22, height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                : Text(widget.label,
                    style: const TextStyle(color: Colors.white, fontSize: 16,
                        fontWeight: FontWeight.w700, letterSpacing: 0.2)),
          ),
        ),
      ),
    );
  }
}

/// Google Sign-In button — adapts to system light / dark mode.
class GoogleSignInButton extends StatelessWidget {
  final VoidCallback? onTap;
  const GoogleSignInButton({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppTheme.bgCardLight : const Color(0xFFF8FAFF);
    final border  = isDark ? AppTheme.glassBorder  : AppTheme.glassBorderLt;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity, height: 52,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border, width: 1.5),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          SizedBox(width: 22, height: 22, child: CustomPaint(painter: _GoogleIconPainter())),
          const SizedBox(width: 10),
          const Text('Continue with Google', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}

class _GoogleIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const cols = [Color(0xFF4285F4), Color(0xFFEA4335), Color(0xFFFBBC05), Color(0xFF34A853)];
    final center = Offset(size.width / 2, size.height / 2);
    double start = -90;
    for (var i = 0; i < 4; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: size.width / 2),
        start * 3.14159265 / 180, 90 * 3.14159265 / 180, false,
        Paint()..color = cols[i]..style = PaintingStyle.stroke..strokeWidth = size.width * 0.45,
      );
      start += 90;
    }
  }
  @override bool shouldRepaint(_) => false;
}
