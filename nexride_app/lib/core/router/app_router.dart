import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/otp_screen.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/map/screens/map_screen.dart';
import '../../features/ticket/screens/ticket_screen.dart';
import '../../features/ticket/screens/ticket_detail_screen.dart';
import '../../features/route/screens/route_search_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/chat/screens/chat_screen.dart';
import '../../features/shell/main_shell.dart';

/// Named routes for type-safe navigation throughout the app.
class AppRoutes {
  static const splash         = '/';
  static const login          = '/login';
  static const register       = '/register';
  static const otp            = '/otp';
  static const forgotPassword = '/forgot-password';
  static const home           = '/home';
  static const map            = '/map';
  static const tickets        = '/tickets';
  static const ticketDetail   = '/tickets/:id';
  static const routes         = '/routes';
  static const profile        = '/profile';
  static const chat           = '/chat';
}

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.splash,
  routes: [
    GoRoute(path: AppRoutes.splash,         builder: (_, __) => const SplashScreen()),
    GoRoute(path: AppRoutes.login,          builder: (_, __) => const LoginScreen()),
    GoRoute(path: AppRoutes.register,       builder: (_, __) => const RegisterScreen()),
    GoRoute(
      path: AppRoutes.otp,
      builder: (_, state) {
        final email = state.extra as String? ?? '';
        return OtpScreen(email: email);
      },
    ),
    GoRoute(path: AppRoutes.forgotPassword, builder: (_, __) => const ForgotPasswordScreen()),

    // Main shell with bottom nav
    ShellRoute(
      builder: (context, state, child) => MainShell(child: child),
      routes: [
        GoRoute(path: AppRoutes.home,    builder: (_, __) => const HomeScreen()),
        GoRoute(path: AppRoutes.map,     builder: (_, __) => const MapScreen()),
        GoRoute(path: AppRoutes.tickets, builder: (_, __) => const TicketScreen()),
        GoRoute(
          path: AppRoutes.ticketDetail,
          builder: (_, state) {
            final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
            return TicketDetailScreen(ticketId: id);
          },
        ),
        GoRoute(path: AppRoutes.routes,  builder: (_, __) => const RouteSearchScreen()),
        GoRoute(path: AppRoutes.profile, builder: (_, __) => const ProfileScreen()),
        GoRoute(path: AppRoutes.chat,    builder: (_, __) => const ChatScreen()),
      ],
    ),
  ],
);
