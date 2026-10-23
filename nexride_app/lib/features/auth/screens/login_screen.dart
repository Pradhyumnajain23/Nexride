import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:animate_do/animate_do.dart';
import '../providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/router/app_router.dart';
import '../../../shared/widgets/shared_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool _obscure    = true;

  @override
  void dispose() { _emailCtrl.dispose(); _passCtrl.dispose(); super.dispose(); }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final auth = context.read<AuthProvider>();
    final ok   = await auth.login(email: _emailCtrl.text.trim(), password: _passCtrl.text);
    if (!mounted) return;
    if (ok) {
      context.go(AppRoutes.home);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error ?? 'Login failed'), backgroundColor: AppTheme.error),
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
                  const SizedBox(height: 48),

                  // ── Logo — Centered ───────────────────────────────────────
                  FadeInDown(
                    duration: const Duration(milliseconds: 600),
                    child: Column(
                      children: [
                        Container(
                          width: 80, height: 80,
                          decoration: BoxDecoration(
                            gradient: AppTheme.primaryGradient,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(0.4), blurRadius: 24, offset: const Offset(0, 8))],
                          ),
                          child: const Icon(Icons.directions_bus_rounded, color: Colors.white, size: 44),
                        ),
                        const SizedBox(height: 14),
                        const Text('NexRide',
                          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppTheme.primary, letterSpacing: 0.5)),
                        const SizedBox(height: 4),
                        Text('AI-Powered Transport', style: TextStyle(fontSize: 13, color: subtxt)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 36),

                  // ── Login Card ────────────────────────────────────────────
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
                          const Text('Welcome back 👋',
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          Text('Sign in to your account', style: TextStyle(fontSize: 13, color: subtxt)),
                          const SizedBox(height: 24),

                          // Email
                          TextFormField(
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) => v!.isEmpty || !v.contains('@') ? 'Enter valid email' : null,
                            decoration: const InputDecoration(
                              labelText: 'Email address',
                              prefixIcon: Icon(Icons.email_outlined, size: 20),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Password
                          TextFormField(
                            controller: _passCtrl,
                            obscureText: _obscure,
                            validator: (v) => v!.isEmpty ? 'Enter password' : null,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                              suffixIcon: IconButton(
                                icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
                                onPressed: () => setState(() => _obscure = !_obscure),
                              ),
                            ),
                          ),

                          // Forgot password
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () => context.push(AppRoutes.forgotPassword),
                              style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 4)),
                              child: const Text('Forgot password?', style: TextStyle(color: AppTheme.primary, fontSize: 13)),
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Sign In (shared PressableButton)
                          PressableButton(label: 'Sign In', loading: auth.loading, onTap: _login),
                          const SizedBox(height: 20),

                          // OR divider
                          Row(children: [
                            Expanded(child: Divider(color: border)),
                            Padding(padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text('OR', style: TextStyle(color: subtxt, fontSize: 12, fontWeight: FontWeight.w600))),
                            Expanded(child: Divider(color: border)),
                          ]),
                          const SizedBox(height: 16),

                          // Google Sign-In (shared GoogleSignInButton)
                          GoogleSignInButton(onTap: auth.loading ? null : _googleSignIn),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Sign Up link
                  FadeInUp(
                    delay: const Duration(milliseconds: 400),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Don't have an account? ", style: TextStyle(color: subtxt, fontSize: 14)),
                        GestureDetector(
                          onTap: () => context.go(AppRoutes.register),
                          child: const Text('Sign Up',
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
