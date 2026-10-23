import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:animate_do/animate_do.dart';
import 'package:shimmer/shimmer.dart';
import 'package:dio/dio.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_notifier.dart';
import '../../../core/network/api_client.dart';
import '../../../core/models/models.dart';
import '../../../core/router/app_router.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../shared/widgets/shared_widgets.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<BusModel> _buses = [];
  List<RouteModel> _routes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final api = ApiClient.instance.dio;
      final results = await Future.wait([
        api.get('/buses/', queryParameters: {'status': 'active'}),
        api.get('/routes/'),
      ]);
      if (!mounted) return;
      setState(() {
        _buses  = (results[0].data as List).map((e) => BusModel.fromJson(e)).toList();
        _routes = (results[1].data as List).map((e) => RouteModel.fromJson(e)).toList();
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning ☀️';
    if (h < 17) return 'Good afternoon 🌤';
    return 'Good evening 🌙';
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeNotifier = context.read<ThemeNotifier>();

    return Scaffold(
      backgroundColor: isDark ? AppTheme.bgDark : AppTheme.bgLight,
      body: RefreshIndicator(
        onRefresh: _fetchData,
        color: AppTheme.primary,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── App Bar ────────────────────────────────────────────────────
            SliverAppBar(
              expandedHeight: 180,
              pinned: true,
              backgroundColor: isDark ? AppTheme.bgDark : AppTheme.primary,
              elevation: 0,
              actions: [
                IconButton(
                  icon: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded, 
                    color: Colors.white),
                  tooltip: 'Toggle Theme',
                  onPressed: () => themeNotifier.toggle(),
                ),
                const SizedBox(width: 8),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: isDark ? [
                        AppTheme.primaryDark.withOpacity(0.8),
                        AppTheme.bgDark,
                      ] : [
                        AppTheme.primary,
                        AppTheme.primary.withOpacity(0.7),
                      ],
                    ),
                  ),
                  padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.center, // Centered requirement
                    children: [
                      FadeInDown(
                        child: Text(_greeting(),
                            style: TextStyle(fontSize: 14, color: isDark ? AppTheme.textSecondary : Colors.white70)),
                      ),
                      const SizedBox(height: 4),
                      FadeInDown(
                        delay: const Duration(milliseconds: 100),
                        child: Text(
                          user?.name.split(' ').first ?? 'Traveler',
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([

                  // ── Search Bar ──────────────────────────────────────────
                  FadeInUp(
                    child: GestureDetector(
                      onTap: () => context.go(AppRoutes.routes),
                      child: Container(
                        height: 54,
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.bgCard : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: isDark ? AppTheme.glassBorder : AppTheme.glassBorderLt),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.05), blurRadius: 10, offset: const Offset(0,4))
                          ]
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Icon(Icons.search_rounded, color: isDark ? AppTheme.textHint : AppTheme.textHintLt, size: 22),
                            const SizedBox(width: 12),
                            Text('Where do you want to go?',
                                style: TextStyle(color: isDark ? AppTheme.textHint : AppTheme.textHintLt, fontSize: 15)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ── Quick Actions ───────────────────────────────────────
                  FadeInUp(
                    delay: const Duration(milliseconds: 100),
                    child: Text('Quick Actions',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: isDark ? Colors.white : Colors.black87)),
                  ),
                  const SizedBox(height: 16),
                  FadeInUp(
                    delay: const Duration(milliseconds: 150),
                    child: Row(
                      children: [
                        _quickAction(icon: Icons.confirmation_number_rounded, label: 'Ticket',
                            color: AppTheme.primary, onTap: () => context.go(AppRoutes.tickets)),
                        const SizedBox(width: 12),
                        _quickAction(icon: Icons.map_rounded, label: 'Track',
                            color: AppTheme.secondary, onTap: () => context.go(AppRoutes.map)),
                        const SizedBox(width: 12),
                        _quickAction(icon: Icons.route_rounded, label: 'Routes',
                            color: AppTheme.warning, onTap: () => context.go(AppRoutes.routes)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ── Nearby Buses ────────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      FadeInUp(
                        delay: const Duration(milliseconds: 200),
                        child: Text('Nearby Buses',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: isDark ? Colors.white : Colors.black87)),
                      ),
                      FadeInUp(
                        delay: const Duration(milliseconds: 200),
                        child: TextButton(
                          onPressed: () => context.go(AppRoutes.map),
                          child: const Text('See map', style: TextStyle(color: AppTheme.primary, fontSize: 13, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (_loading) _shimmerBus(isDark)
                  else if (_buses.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text('No active buses nearby', style: TextStyle(color: isDark ? AppTheme.textSecondary : AppTheme.textSecondaryLt)),
                      ),
                    )
                  else
                    ..._buses.take(4).toList().asMap().entries.map((e) =>
                      FadeInUp(
                        delay: Duration(milliseconds: 250 + e.key * 80),
                        child: _busCard(e.value, isDark),
                      ),
                    ),
                  const SizedBox(height: 32),

                  // ── Popular Routes ──────────────────────────────────────
                  FadeInUp(
                    delay: const Duration(milliseconds: 350),
                    child: Text('Popular Routes',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: isDark ? Colors.white : Colors.black87)),
                  ),
                  const SizedBox(height: 16),
                  ..._routes.take(3).toList().asMap().entries.map((e) =>
                    FadeInUp(
                      delay: Duration(milliseconds: 400 + e.key * 80),
                      child: _routeCard(e.value, isDark),
                    ),
                  ),
                  const SizedBox(height: 20),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 86,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(label, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _busCard(BusModel bus, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        borderRadius: 18,
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.directions_bus_rounded, color: AppTheme.primary, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(bus.busNumber,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: isDark ? Colors.white : Colors.black87)),
                  const SizedBox(height: 2),
                  Text('${bus.currentOccupancy}/${bus.capacity} passengers',
                      style: TextStyle(fontSize: 13, color: isDark ? AppTheme.textSecondary : AppTheme.textSecondaryLt)),
                ],
              ),
            ),
            CrowdBadge(level: bus.crowdLabel),
          ],
        ),
      ),
    );
  }

  Widget _routeCard(RouteModel route, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: const EdgeInsets.all(18),
        borderRadius: 18,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.secondary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(route.routeNumber,
                            style: const TextStyle(color: AppTheme.secondary, fontSize: 12, fontWeight: FontWeight.w700)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(route.name,
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: isDark ? Colors.white : Colors.black87),
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.circle, size: 8, color: AppTheme.success),
                      const SizedBox(width: 8),
                      Expanded(child: Text(route.origin,
                          style: TextStyle(fontSize: 13, color: isDark ? AppTheme.textSecondary : AppTheme.textSecondaryLt), overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded, size: 8, color: AppTheme.error),
                      const SizedBox(width: 8),
                      Expanded(child: Text(route.destination,
                          style: TextStyle(fontSize: 13, color: isDark ? AppTheme.textSecondary : AppTheme.textSecondaryLt), overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('₹${route.fare?.toStringAsFixed(0) ?? '--'}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.primary)),
                const SizedBox(height: 4),
                Text('${route.estimatedDurationMin ?? '--'} min',
                    style: TextStyle(fontSize: 12, color: isDark ? AppTheme.textSecondary : AppTheme.textSecondaryLt, fontWeight: FontWeight.w500)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _shimmerBus(bool isDark) {
    final baseColor = isDark ? AppTheme.bgCard : Colors.grey.shade200;
    final highlightColor = isDark ? AppTheme.bgCardLight : Colors.white;
    return Column(
      children: List.generate(3, (_) => Shimmer.fromColors(
        baseColor: baseColor,
        highlightColor: highlightColor,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          height: 80,
          decoration: BoxDecoration(color: baseColor, borderRadius: BorderRadius.circular(18)),
        ),
      )),
    );
  }
}
