import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:animate_do/animate_do.dart';
import 'package:pinput/pinput.dart';
import '../providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/router/app_router.dart';
import '../../../shared/widgets/shared_widgets.dart';

class OtpScreen extends StatefulWidget {
  final String email;
  const OtpScreen({super.key, required this.email});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _pinController = TextEditingController();

  Future<void> _verify() async {
    if (_pinController.text.length < 6) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.verifyOtp(
      email: widget.email,
      otp: _pinController.text,
    );
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Email verified! Please log in.'),
          backgroundColor: AppTheme.success,
        ),
      );
      context.go(AppRoutes.login);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.error ?? 'Invalid OTP'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  Future<void> _resend() async {
    final auth = context.read<AuthProvider>();
    final ok = await auth.resendOtp(widget.email);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'OTP resent to ${widget.email}' : 'Failed to resend OTP'),
        backgroundColor: ok ? AppTheme.success : AppTheme.error,
      ),
    );
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final defaultTheme = PinTheme(
      width: 54,
      height: 58,
      textStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: isDark ? Colors.white : Colors.black87),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.bgCard : AppTheme.bgCardLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? AppTheme.glassBorder : AppTheme.glassBorderLt),
      ),
    );

    final focusedTheme = defaultTheme.copyWith(
      decoration: defaultTheme.decoration!.copyWith(
        border: Border.all(color: AppTheme.primary, width: 2),
        boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(0.3), blurRadius: 12)],
      ),
    );

    return Scaffold(
      backgroundColor: isDark ? AppTheme.bgDark : AppTheme.bgLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black87),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              FadeInDown(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
                  ),
                  child: const Icon(Icons.mark_email_read_outlined,
                      color: AppTheme.primary, size: 36),
                ),
              ),
              const SizedBox(height: 24),
              FadeInDown(
                delay: const Duration(milliseconds: 100),
                child: Text('Verify Your Email',
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : Colors.black87)),
              ),
              const SizedBox(height: 10),
              FadeInDown(
                delay: const Duration(milliseconds: 200),
                child: Text(
                  'We sent a 6-digit code to\n${widget.email}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 14,
                      color: isDark ? AppTheme.textSecondary : AppTheme.textSecondaryLt,
                      height: 1.5),
                ),
              ),
              const SizedBox(height: 40),

              // ── PIN Input ────────────────────────────────────────────────
              FadeInUp(
                delay: const Duration(milliseconds: 200),
                child: Pinput(
                  controller: _pinController,
                  length: 6,
                  defaultPinTheme: defaultTheme,
                  focusedPinTheme: focusedTheme,
                  onCompleted: (_) => _verify(),
                ),
              ),
              const SizedBox(height: 36),
              FadeInUp(
                delay: const Duration(milliseconds: 300),
                child: NexButton(
                  label: 'Verify OTP',
                  onTap: _verify,
                  loading: auth.loading,
                  icon: Icons.verified_user_outlined,
                ),
              ),
              const SizedBox(height: 24),
              FadeInUp(
                delay: const Duration(milliseconds: 400),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Didn't receive the code? ",
                        style: TextStyle(
                            color: isDark ? AppTheme.textSecondary : AppTheme.textSecondaryLt,
                            fontSize: 13)),
                    GestureDetector(
                      onTap: _resend,
                      child: const Text('Resend',
                          style: TextStyle(
                              color: AppTheme.primary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
