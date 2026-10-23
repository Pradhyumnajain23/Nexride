import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:animate_do/animate_do.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_client.dart';
import '../../../core/models/models.dart';
import '../../../core/router/app_router.dart';
import '../../../shared/widgets/shared_widgets.dart';

class TicketScreen extends StatefulWidget {
  const TicketScreen({super.key});

  @override
  State<TicketScreen> createState() => _TicketScreenState();
}

class _TicketScreenState extends State<TicketScreen> {
  List<TicketModel> _tickets = [];
  List<RouteModel>  _routes  = [];
  bool _loading = true;
  RouteModel? _selectedRoute;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final api = ApiClient.instance.dio;
      final results = await Future.wait([
        api.get('/tickets/my'),
        api.get('/routes/'),
      ]);
      if (!mounted) return;
      setState(() {
        _tickets = (results[0].data as List).map((e) => TicketModel.fromJson(e)).toList();
        _routes  = (results[1].data as List).map((e) => RouteModel.fromJson(e)).toList();
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _buyTicket() async {
    if (_selectedRoute == null) return;
    try {
      final res = await ApiClient.instance.dio.post('/tickets/', data: {
        'route_id': _selectedRoute!.id,
      });
      if (!mounted) return;
      final ticket = TicketModel.fromJson(res.data);
      setState(() => _tickets.insert(0, ticket));
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🎫 Ticket purchased!'), backgroundColor: AppTheme.success),
      );
    } catch (e) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to purchase ticket'), backgroundColor: AppTheme.error),
      );
    }
  }

  void _showBuyDialog() {
    setState(() => _selectedRoute = _routes.isNotEmpty ? _routes.first : null);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppTheme.bgSurface : AppTheme.bgSurfaceLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Buy Ticket 🎫',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: isDark ? Colors.white : Colors.black87)),
              const SizedBox(height: 20),
              Text('Select Route', style: TextStyle(color: isDark ? AppTheme.textSecondary : AppTheme.textSecondaryLt, fontSize: 13)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.bgCard : AppTheme.bgCardLight,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: isDark ? AppTheme.glassBorder : AppTheme.glassBorderLt),
                ),
                child: DropdownButton<RouteModel>(
                  value: _selectedRoute,
                  isExpanded: true,
                  dropdownColor: isDark ? AppTheme.bgCard : AppTheme.bgCardLight,
                  underline: const SizedBox(),
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 14),
                  items: _routes.map((r) => DropdownMenuItem(
                    value: r,
                    child: Text('${r.routeNumber} — ${r.origin} → ${r.destination}',
                        overflow: TextOverflow.ellipsis),
                  )).toList(),
                  onChanged: (r) { setModalState(() => _selectedRoute = r); setState(() {}); },
                ),
              ),
              if (_selectedRoute != null) ...[
                const SizedBox(height: 12),
                GlassCard(
                  padding: const EdgeInsets.all(12),
                  borderRadius: 12,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Fare', style: TextStyle(color: isDark ? AppTheme.textSecondary : AppTheme.textSecondaryLt, fontSize: 13)),
                      Text('₹${_selectedRoute!.fare?.toStringAsFixed(0) ?? '--'}',
                          style: const TextStyle(color: AppTheme.primary, fontSize: 18, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              NexButton(label: 'Confirm Purchase', onTap: _buyTicket),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.bgDark : AppTheme.bgLight,
      appBar: AppBar(
        title: Text('My Tickets', style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
        backgroundColor: isDark ? AppTheme.bgDark : AppTheme.bgLight,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black87),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded, color: AppTheme.primary),
            onPressed: _routes.isEmpty ? null : _showBuyDialog,
          ),
        ],
      ),
      body: _loading
          ? _shimmerTickets(isDark)
          : _tickets.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.confirmation_number_outlined,
                          size: 64, color: isDark ? AppTheme.textHint : AppTheme.textHintLt),
                      const SizedBox(height: 16),
                      Text('No tickets yet',
                          style: TextStyle(color: isDark ? AppTheme.textSecondary : AppTheme.textSecondaryLt, fontSize: 16)),
                      const SizedBox(height: 24),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 60),
                        child: NexButton(label: 'Buy Ticket', onTap: _showBuyDialog),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _tickets.length,
                  itemBuilder: (_, i) => FadeInUp(
                    delay: Duration(milliseconds: i * 60),
                    child: _ticketCard(_tickets[i], isDark),
                  ),
                ),
      floatingActionButton: _tickets.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _showBuyDialog,
              backgroundColor: AppTheme.primary,
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: const Text('New Ticket', style: TextStyle(color: Colors.white)),
            )
          : null,
    );
  }

  Widget _ticketCard(TicketModel t, bool isDark) {
    final isActive = t.status == 'active';
    return GestureDetector(
      onTap: () => context.go('/tickets/${t.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: GlassCard(
          padding: const EdgeInsets.all(16),
          borderRadius: 18,
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppTheme.primary.withOpacity(0.15)
                          : (isDark ? AppTheme.textHint : AppTheme.textHintLt).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isActive ? Icons.qr_code_2_rounded : Icons.check_circle_outline_rounded,
                      color: isActive ? AppTheme.primary : (isDark ? AppTheme.textHint : AppTheme.textHintLt),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('#${t.id} — Route ${t.routeId}',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87)),
                        const SizedBox(height: 2),
                        Text(t.issuedAt.split('T').first,
                            style: TextStyle(fontSize: 12, color: isDark ? AppTheme.textSecondary : AppTheme.textSecondaryLt)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('₹${t.farePaid.toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.primary)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppTheme.success.withOpacity(0.15)
                              : (isDark ? AppTheme.textHint : AppTheme.textHintLt).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          t.status.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10, fontWeight: FontWeight.w700,
                            color: isActive ? AppTheme.success : (isDark ? AppTheme.textHint : AppTheme.textHintLt),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _shimmerTickets(bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: isDark ? AppTheme.bgCard : Colors.grey.shade200,
        highlightColor: isDark ? AppTheme.bgCardLight : Colors.white,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          height: 80,
          decoration: BoxDecoration(color: isDark ? AppTheme.bgCard : Colors.white, borderRadius: BorderRadius.circular(18)),
        ),
      ),
    );
  }
}
