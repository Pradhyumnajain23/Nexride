import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:animate_do/animate_do.dart';
import '../providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/router/app_router.dart';
import '../../../shared/widgets/shared_widgets.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _nameCtrl  = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool  _obscure   = true;

  @override
  void dispose() {
    _nameCtrl.dispose(); _emailCtrl.dispose();
    _phoneCtrl.dispose(); _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final auth = context.read<AuthProvider>();
    final ok   = await auth.register(
      name: _nameCtrl.text.trim(), email: _emailCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(), password: _passCtrl.text,
    );
    if (!mounted) return;
    if (ok) {
      context.go(AppRoutes.otp, extra: _emailCtrl.text.trim());
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error ?? 'Registration failed'), backgroundColor: AppTheme.error),
      );
    }
  }

  Future<void> _googleSignIn() async {
    final auth = context.read<AuthProvider>();
    final ok   = await auth.signInWithGoogle();
    if (!mounted) return;
    if (ok) {
      context.go(AppRoutes.home);
    } else if (auth.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error!), backgroundColor: AppTheme.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth   = context.watch<AuthProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg     = isDark ? AppTheme.bgGradientDark : AppTheme.bgGradientLight;
    final cardBg = isDark ? AppTheme.bgCard : Colors.white;
    final border = isDark ? AppTheme.glassBorder : AppTheme.glassBorderLt;
    final subtxt = isDark ? AppTheme.textSecondary : AppTheme.textSecondaryLt;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: bg),
        child: SafeArea(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const SizedBox(height: 40),

                  // ── Logo ──────────────────────────────────────────────────
                  FadeInDown(
                    duration: const Duration(milliseconds: 600),
                    child: Column(
                      children: [
                        Container(
                          width: 72, height: 72,
                          decoration: BoxDecoration(
                            gradient: AppTheme.primaryGradient,
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(0.35), blurRadius: 20, offset: const Offset(0, 6))],
                          ),
                          child: const Icon(Icons.directions_bus_rounded, color: Colors.white, size: 38),
                        ),
                        const SizedBox(height: 12),
                        const Text('NexRide',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppTheme.primary)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ── Register Card ─────────────────────────────────────────
                  FadeInUp(
                    delay: const Duration(milliseconds: 200),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: border),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.3 : 0.08), blurRadius: 24, offset: const Offset(0, 8))],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Create Account 🚌',
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          Text('Your smart transport journey starts here', style: TextStyle(fontSize: 13, color: subtxt)),
                          const SizedBox(height: 22),

                          // Name
                          TextFormField(
                            controller: _nameCtrl,
                            validator: (v) => v!.length < 2 ? 'Enter your name' : null,
                            decoration: const InputDecoration(
                              labelText: 'Full name',
                              prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Email
                          TextFormField(
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) => !v!.contains('@') ? 'Enter valid email' : null,
                            decoration: const InputDecoration(
                              labelText: 'Email address',
                              prefixIcon: Icon(Icons.email_outlined, size: 20),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Phone
                          TextFormField(
                            controller: _phoneCtrl,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'Phone (optional)',
                              prefixIcon: Icon(Icons.phone_outlined, size: 20),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Password
                          TextFormField(
                            controller: _passCtrl,
                            obscureText: _obscure,
                            validator: (v) => v!.length < 6 ? 'Min 6 characters' : null,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                              suffixIcon: IconButton(
                                icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
                                onPressed: () => setState(() => _obscure = !_obscure),
                              ),
                            ),
                          ),
                          const SizedBox(height: 22),

                          // Create Account button (shared PressableButton)
                          PressableButton(label: 'Create Account', loading: auth.loading, onTap: _register),
                          const SizedBox(height: 18),

                          // OR divider
                          Row(children: [
                            Expanded(child: Divider(color: border)),
                            Padding(padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text('OR', style: TextStyle(color: subtxt, fontSize: 12, fontWeight: FontWeight.w600))),
                            Expanded(child: Divider(color: border)),
                          ]),
                          const SizedBox(height: 14),

                          // Google Sign-In (shared GoogleSignInButton)
                          GoogleSignInButton(onTap: auth.loading ? null : _googleSignIn),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 22),

                  // Sign In link
                  FadeInUp(
                    delay: const Duration(milliseconds: 400),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Already have an account? ', style: TextStyle(color: subtxt, fontSize: 14)),
                        GestureDetector(
                          onTap: () => context.go(AppRoutes.login),
                          child: const Text('Sign In',
                            style: TextStyle(color: AppTheme.primary, fontSize: 14, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
