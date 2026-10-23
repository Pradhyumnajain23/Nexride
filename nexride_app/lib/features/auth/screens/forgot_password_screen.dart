import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:animate_do/animate_do.dart';
import 'package:pinput/pinput.dart';
import '../providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/router/app_router.dart';
import '../../../shared/widgets/shared_widgets.dart';

/// 3-step Forgot Password flow:
///   Step 1 → Enter email → send OTP via Gmail SMTP
///   Step 2 → Enter 6-digit OTP
///   Step 3 → Enter new password → update DB → go to login
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  int _step = 1; // 1 = email, 2 = otp, 3 = new password

  // Controllers
  final _emailCtrl    = TextEditingController();
  final _otpCtrl      = TextEditingController();
  final _newPassCtrl  = TextEditingController();
  final _confirmCtrl  = TextEditingController();
  bool  _obscureNew   = true;
  bool  _obscureConf  = true;
  bool  _loading      = false;

  String _otp = '';

  @override
  void dispose() {
    _emailCtrl.dispose(); _otpCtrl.dispose();
    _newPassCtrl.dispose(); _confirmCtrl.dispose();
    super.dispose();
  }

  // ── Step 1: Send OTP ─────────────────────────────────────────────────────
  Future<void> _sendOtp() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _snack('Enter a valid email address', isError: true);
      return;
    }
    setState(() => _loading = true);
    final ok = await context.read<AuthProvider>().forgotPassword(email);
    if (!mounted) return;
    setState(() => _loading = false);
    if (ok) {
      _snack('OTP sent to $email — check your inbox 📧');
      setState(() => _step = 2);
    } else {
      _snack(context.read<AuthProvider>().error ?? 'Failed to send OTP', isError: true);
    }
  }

  // ── Step 2: Verify OTP (client-side — actual verify happens at reset) ────
  void _verifyOtp() {
    if (_otp.length < 6) {
      _snack('Enter the 6-digit OTP from your email', isError: true);
      return;
    }
    setState(() => _step = 3);
  }

  // ── Step 3: Reset password ───────────────────────────────────────────────
  Future<void> _resetPassword() async {
    final newPass = _newPassCtrl.text;
    final confirm = _confirmCtrl.text;
    if (newPass.length < 6) {
      _snack('Password must be at least 6 characters', isError: true);
      return;
    }
    if (newPass != confirm) {
      _snack('Passwords do not match', isError: true);
      return;
    }
    setState(() => _loading = true);
    final ok = await context.read<AuthProvider>().resetPassword(
      email: _emailCtrl.text.trim(),
      otp: _otp,
      newPassword: newPass,
    );
    if (!mounted) return;
    setState(() => _loading = false);
    if (ok) {
      _showSuccessDialog();
    } else {
      final err = context.read<AuthProvider>().error ?? 'Invalid or expired OTP';
      _snack(err, isError: true);
      // If OTP was wrong, go back to OTP step
      if (err.contains('OTP')) setState(() => _step = 2);
    }
  }

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppTheme.error : AppTheme.success,
    ));
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? AppTheme.bgCard : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(color: AppTheme.success.withOpacity(0.15), shape: BoxShape.circle),
              child: const Icon(Icons.check_rounded, color: AppTheme.success, size: 34),
            ),
            const SizedBox(height: 16),
            const Text('Password Updated!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center),
            const SizedBox(height: 8),
            const Text('Your password has been reset successfully.\nPlease sign in with your new password.',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              textAlign: TextAlign.center),
            const SizedBox(height: 20),
            PressableButton(
              label: 'Go to Sign In',
              onTap: () {
                Navigator.of(context).pop();
                context.go(AppRoutes.login);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg     = isDark ? AppTheme.bgGradientDark : AppTheme.bgGradientLight;
    final cardBg = isDark ? AppTheme.bgCard : Colors.white;
    final border = isDark ? AppTheme.glassBorder : AppTheme.glassBorderLt;
    final subtxt = isDark ? AppTheme.textSecondary : AppTheme.textSecondaryLt;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: bg),
        child: SafeArea(
          child: Column(
            children: [
              // ── Top bar ──────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_rounded),
                      onPressed: () {
                        if (_step > 1) {
                          setState(() => _step--);
                        } else {
                          context.pop();
                        }
                      },
                    ),
                    // Step indicator
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(3, (i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: _step == i + 1 ? 24 : 8,
                          height: 8,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            color: _step >= i + 1 ? AppTheme.primary : (isDark ? AppTheme.glassBorder : AppTheme.glassBorderLt),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        )),
                      ),
                    ),
                    const SizedBox(width: 48), // balance
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),

                      // ── Icon ─────────────────────────────────────────────
                      FadeInDown(
                        key: ValueKey(_step),
                        child: Container(
                          width: 72, height: 72,
                          decoration: BoxDecoration(
                            gradient: AppTheme.primaryGradient,
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(0.35), blurRadius: 20, offset: const Offset(0, 6))],
                          ),
                          child: Icon(_stepIcon, color: Colors.white, size: 36),
                        ),
                      ),
                      const SizedBox(height: 20),

                      FadeInUp(
                        key: ValueKey('title$_step'),
                        child: Column(
                          children: [
                            Text(_stepTitle,
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                              textAlign: TextAlign.center),
                            const SizedBox(height: 6),
                            Text(_stepSubtitle,
                              style: TextStyle(fontSize: 13, color: subtxt),
                              textAlign: TextAlign.center),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      // ── Card with step content ────────────────────────────
                      FadeInUp(
                        key: ValueKey('card$_step'),
                        delay: const Duration(milliseconds: 100),
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: border),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.3 : 0.07), blurRadius: 24, offset: const Offset(0, 8))],
                          ),
                          child: _buildStep(isDark, subtxt, border),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep(bool isDark, Color subtxt, Color border) {
    switch (_step) {
      case 1: return _buildEmailStep(subtxt);
      case 2: return _buildOtpStep(isDark, subtxt);
      case 3: return _buildPasswordStep(subtxt);
      default: return const SizedBox();
    }
  }

  // ── Step 1: Email ─────────────────────────────────────────────────────────
  Widget _buildEmailStep(Color subtxt) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Email address',
            prefixIcon: Icon(Icons.email_outlined, size: 20),
          ),
        ),
        const SizedBox(height: 20),
        PressableButton(label: 'Send OTP', loading: _loading, onTap: _sendOtp),
      ],
    );
  }

  // ── Step 2: OTP ───────────────────────────────────────────────────────────
  Widget _buildOtpStep(bool isDark, Color subtxt) {
    final pinTheme = PinTheme(
      width: 48, height: 56,
      textStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppTheme.primary),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.bgCardLight : const Color(0xFFF0F4FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? AppTheme.glassBorder : AppTheme.glassBorderLt),
      ),
    );

    return Column(
      children: [
        Text('Check your email for a 6-digit code sent to\n${_emailCtrl.text.trim()}',
          style: TextStyle(fontSize: 13, color: subtxt),
          textAlign: TextAlign.center),
        const SizedBox(height: 24),
        Pinput(
          length: 6,
          controller: _otpCtrl,
          defaultPinTheme: pinTheme,
          focusedPinTheme: pinTheme.copyWith(
            decoration: pinTheme.decoration!.copyWith(
              border: Border.all(color: AppTheme.primary, width: 2),
            ),
          ),
          onChanged: (v) => _otp = v,
          onCompleted: (v) { _otp = v; },
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: _loading ? null : _sendOtp,
          child: const Text('Resend OTP', style: TextStyle(color: AppTheme.primary, fontSize: 13)),
        ),
        const SizedBox(height: 8),
        PressableButton(label: 'Verify OTP', loading: _loading, onTap: _verifyOtp),
      ],
    );
  }

  // ── Step 3: New Password ──────────────────────────────────────────────────
  Widget _buildPasswordStep(Color subtxt) {
    return Column(
      children: [
        TextFormField(
          controller: _newPassCtrl,
          obscureText: _obscureNew,
          decoration: InputDecoration(
            labelText: 'New password',
            prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
            suffixIcon: IconButton(
              icon: Icon(_obscureNew ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
              onPressed: () => setState(() => _obscureNew = !_obscureNew),
            ),
          ),
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _confirmCtrl,
          obscureText: _obscureConf,
          decoration: InputDecoration(
            labelText: 'Confirm new password',
            prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
            suffixIcon: IconButton(
              icon: Icon(_obscureConf ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
              onPressed: () => setState(() => _obscureConf = !_obscureConf),
            ),
          ),
        ),
        const SizedBox(height: 20),
        PressableButton(label: 'Reset Password', loading: _loading, onTap: _resetPassword),
      ],
    );
  }

  IconData get _stepIcon {
    switch (_step) {
      case 1: return Icons.email_outlined;
      case 2: return Icons.pin_outlined;
      case 3: return Icons.lock_reset_rounded;
      default: return Icons.lock_outline_rounded;
    }
  }

  String get _stepTitle {
    switch (_step) {
      case 1: return 'Forgot Password?';
      case 2: return 'Enter OTP';
      case 3: return 'Set New Password';
      default: return '';
    }
  }

  String get _stepSubtitle {
    switch (_step) {
      case 1: return 'Enter your email and we\'ll send\na 6-digit OTP to reset your password.';
      case 2: return 'We sent a 6-digit code to your email.\nEnter it below to continue.';
      case 3: return 'Choose a strong new password\nfor your NexRide account.';
      default: return '';
    }
  }
}
