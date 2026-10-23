import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:animate_do/animate_do.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/router/app_router.dart';

/// Animated splash screen — checks token and routes accordingly.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(milliseconds: 2200));
    final token = await ApiClient.instance.getToken();
    if (!mounted) return;
    if (token != null) {
      context.go(AppRoutes.home);
    } else {
      context.go(AppRoutes.login);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.bgDark : AppTheme.bgLight,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Pulsing logo
            ScaleTransition(
              scale: _pulseAnim,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: const RadialGradient(
                    colors: [AppTheme.primary, AppTheme.primaryDark],
                  ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withOpacity(0.4),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(Icons.directions_bus_rounded,
                    color: Colors.white, size: 52),
              ),
            ),
            const SizedBox(height: 28),
            FadeInUp(
              delay: const Duration(milliseconds: 400),
              child: Text(
                'NexRide',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black87,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            FadeInUp(
              delay: const Duration(milliseconds: 600),
              child: Text(
                'AI-Powered Public Transport',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? AppTheme.textSecondary : AppTheme.textSecondaryLt,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 60),
            FadeInUp(
              delay: const Duration(milliseconds: 900),
              child: SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppTheme.primary.withOpacity(0.7)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
