import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_client.dart';
import '../../../core/models/models.dart';
import '../../../shared/widgets/shared_widgets.dart';

class RouteSearchScreen extends StatefulWidget {
  const RouteSearchScreen({super.key});

  @override
  State<RouteSearchScreen> createState() => _RouteSearchScreenState();
}

class _RouteSearchScreenState extends State<RouteSearchScreen> {
  final _searchCtrl = TextEditingController();
  List<RouteModel> _routes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
    _searchCtrl.addListener(() => _fetch(query: _searchCtrl.text));
  }

  Future<void> _fetch({String query = ''}) async {
    setState(() => _loading = true);
    try {
      final res = await ApiClient.instance.dio.get(
        '/routes/',
        queryParameters: query.isNotEmpty ? {'search': query} : null,
      );
      if (!mounted) return;
      setState(() {
        _routes  = (res.data as List).map((e) => RouteModel.fromJson(e)).toList();
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.bgDark : AppTheme.bgLight,
      appBar: AppBar(
        title: Text('Route Search', style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
        backgroundColor: isDark ? AppTheme.bgDark : AppTheme.bgLight,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black87),
      ),
      body: Column(
        children: [
          // ── Search Field ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: FadeInDown(
              child: TextField(
                controller: _searchCtrl,
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                decoration: InputDecoration(
                  hintText: 'Search by name, origin, destination…',
                  prefixIcon: Icon(Icons.search_rounded, color: isDark ? AppTheme.textHint : AppTheme.textHintLt, size: 20),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear_rounded, color: isDark ? AppTheme.textHint : AppTheme.textHintLt, size: 18),
                          onPressed: () { _searchCtrl.clear(); _fetch(); },
                        )
                      : null,
                ),
              ),
            ),
          ),

          // ── Results ────────────────────────────────────────────────────
          Expanded(
            child: _loading
                ? _shimmer(isDark)
                : _routes.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off_rounded, size: 56, color: isDark ? AppTheme.textHint : AppTheme.textHintLt),
                            const SizedBox(height: 12),
                            Text('No routes found', style: TextStyle(color: isDark ? AppTheme.textSecondary : AppTheme.textSecondaryLt, fontSize: 15)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: _routes.length,
                        itemBuilder: (_, i) => FadeInUp(
                          delay: Duration(milliseconds: i * 50),
                          child: _routeCard(_routes[i], isDark),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _routeCard(RouteModel r, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        borderRadius: 18,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.primaryDark]),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(r.routeNumber,
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(r.name,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87),
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Route path
            Row(
              children: [
                Column(
                  children: [
                    Container(width: 10, height: 10,
                        decoration: BoxDecoration(
                          color: AppTheme.success,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        )),
                    Container(width: 2, height: 24, color: isDark ? AppTheme.glassBorder : AppTheme.glassBorderLt),
                    Container(width: 10, height: 10,
                        decoration: BoxDecoration(
                          color: AppTheme.error,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        )),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r.origin,
                          style: TextStyle(fontSize: 13, color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 16),
                      Text(r.destination,
                          style: TextStyle(fontSize: 13, color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(color: isDark ? AppTheme.glassBorder : AppTheme.glassBorderLt, height: 1),
            const SizedBox(height: 10),

            // Stats row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _stat(Icons.straighten_rounded, '${r.distanceKm?.toStringAsFixed(1) ?? '--'} km', 'Distance', isDark),
                Container(width: 1, height: 32, color: isDark ? AppTheme.glassBorder : AppTheme.glassBorderLt),
                _stat(Icons.schedule_rounded, '${r.estimatedDurationMin ?? '--'} min', 'Duration', isDark),
                Container(width: 1, height: 32, color: isDark ? AppTheme.glassBorder : AppTheme.glassBorderLt),
                _stat(Icons.currency_rupee_rounded, '${r.fare?.toStringAsFixed(0) ?? '--'}', 'Fare', isDark),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(IconData icon, String value, String label, bool isDark) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.primary, size: 16),
        const SizedBox(height: 3),
        Text(value, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 13, fontWeight: FontWeight.w600)),
        Text(label, style: TextStyle(color: isDark ? AppTheme.textHint : AppTheme.textHintLt, fontSize: 10)),
      ],
    );
  }

  Widget _shimmer(bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: isDark ? AppTheme.bgCard : Colors.grey.shade200,
        highlightColor: isDark ? AppTheme.bgCardLight : Colors.white,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          height: 140,
          decoration: BoxDecoration(color: isDark ? AppTheme.bgCard : Colors.white, borderRadius: BorderRadius.circular(18)),
        ),
      ),
    );
  }
}
