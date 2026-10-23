import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/router/app_router.dart';

/// Bottom navigation shell — Home, Track, Tickets, Routes, Chat, Profile.
class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  static const _tabs = [
    AppRoutes.home,
    AppRoutes.map,
    AppRoutes.tickets,
    AppRoutes.routes,
    AppRoutes.chat,
    AppRoutes.profile,
  ];

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    for (int i = 0; i < _tabs.length; i++) {
      if (location.startsWith(_tabs[i])) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final idx = _currentIndex(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.bgDark : AppTheme.bgLight,
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? AppTheme.bgSurface : AppTheme.bgSurfaceLight,
          border: Border(top: BorderSide(
              color: isDark ? AppTheme.glassBorder : AppTheme.glassBorderLt,
              width: 1)),
        ),
        child: NavigationBar(
          backgroundColor: Colors.transparent,
          indicatorColor: AppTheme.primary.withOpacity(0.15),
          selectedIndex: idx,
          onDestinationSelected: (i) => context.go(_tabs[i]),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded, color: AppTheme.primary),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.map_outlined),
              selectedIcon: Icon(Icons.map_rounded, color: AppTheme.primary),
              label: 'Track',
            ),
            NavigationDestination(
              icon: Icon(Icons.confirmation_number_outlined),
              selectedIcon: Icon(Icons.confirmation_number_rounded, color: AppTheme.primary),
              label: 'Tickets',
            ),
            NavigationDestination(
              icon: Icon(Icons.route_outlined),
              selectedIcon: Icon(Icons.route_rounded, color: AppTheme.primary),
              label: 'Routes',
            ),
            NavigationDestination(
              icon: Icon(Icons.smart_toy_outlined),
              selectedIcon: Icon(Icons.smart_toy_rounded, color: AppTheme.primary),
              label: 'AI Chat',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded, color: AppTheme.primary),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
