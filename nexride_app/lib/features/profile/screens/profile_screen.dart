import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:animate_do/animate_do.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_notifier.dart';
import '../../../core/router/app_router.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../shared/widgets/shared_widgets.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeNotifier = context.read<ThemeNotifier>();

    return Scaffold(
      backgroundColor: isDark ? AppTheme.bgDark : AppTheme.bgLight,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 10),
              
              // ── Header ────────────────────────────────────────────────────────
              FadeInDown(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Profile', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700)),
                    IconButton(
                      icon: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
                      tooltip: 'Toggle Theme',
                      onPressed: () => themeNotifier.toggle(),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // ── Avatar & Name ───────────────────────────────────────────────
              FadeInUp(
                child: Column(
                  children: [
                    Container(
                      width: 90, height: 90,
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: AppTheme.primary.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))
                        ],
                      ),
                      child: Center(
                        child: Text(
                          user?.name.substring(0, 1).toUpperCase() ?? 'U',
                          style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(user?.name ?? 'User', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(user?.email ?? 'email@example.com', 
                      style: TextStyle(fontSize: 14, color: isDark ? AppTheme.textSecondary : AppTheme.textSecondaryLt)),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // ── Actions ───────────────────────────────────────────────────
              FadeInUp(
                delay: const Duration(milliseconds: 100),
                child: GlassCard(
                  padding: const EdgeInsets.all(0),
                  child: Column(
                    children: [
                      _ProfileTile(
                        icon: Icons.history_rounded,
                        title: 'Ticket History',
                        onTap: () => context.go(AppRoutes.tickets),
                        isDark: isDark,
                      ),
                      Divider(height: 1, color: isDark ? AppTheme.glassBorder : AppTheme.glassBorderLt),
                      _ProfileTile(
                        icon: Icons.person_outline_rounded,
                        title: 'Edit Profile (Coming Soon)',
                        onTap: () {},
                        isDark: isDark,
                      ),
                      Divider(height: 1, color: isDark ? AppTheme.glassBorder : AppTheme.glassBorderLt),
                      _ProfileTile(
                        icon: Icons.palette_outlined,
                        title: 'Appearance: ${isDark ? "Dark" : "Light"}',
                        onTap: () => themeNotifier.toggle(),
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // ── Logout ────────────────────────────────────────────────────
              FadeInUp(
                delay: const Duration(milliseconds: 200),
                child: PressableButton(
                  label: 'Log Out',
                  onTap: () async {
                    await auth.logout();
                    if (context.mounted) context.go(AppRoutes.login);
                  },
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isDark;

  const _ProfileTile({
    required this.icon,
    required this.title,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primary),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: Icon(Icons.arrow_forward_ios_rounded, size: 16, 
        color: isDark ? AppTheme.textHint : AppTheme.textHintLt),
      onTap: onTap,
    );
  }
}
