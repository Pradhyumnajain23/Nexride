import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:animate_do/animate_do.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_client.dart';
import '../../../core/models/models.dart';
import '../../../shared/widgets/shared_widgets.dart';

class TicketDetailScreen extends StatefulWidget {
  final int ticketId;
  const TicketDetailScreen({super.key, required this.ticketId});

  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  TicketModel? _ticket;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchTicket();
  }

  Future<void> _fetchTicket() async {
    try {
      final res = await ApiClient.instance.dio.get('/tickets/${widget.ticketId}');
      if (!mounted) return;
      setState(() {
        _ticket = TicketModel.fromJson(res.data);
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.bgDark : AppTheme.bgLight,
      appBar: AppBar(
        title: Text('Ticket #${widget.ticketId}', style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
        backgroundColor: isDark ? AppTheme.bgDark : AppTheme.bgLight,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black87),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : _ticket == null
              ? Center(child: Text('Ticket not found', style: TextStyle(color: isDark ? AppTheme.textSecondary : AppTheme.textSecondaryLt)))
              : _buildTicket(isDark),
    );
  }

  Widget _buildTicket(bool isDark) {
    final t = _ticket!;
    final isActive = t.status == 'active';
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // ── Ticket Card ───────────────────────────────────────────────
          FadeInDown(
            child: GlassCard(
              padding: const EdgeInsets.all(0),
              borderRadius: 24,
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isActive
                            ? [AppTheme.primary, AppTheme.primaryDark]
                            : [isDark ? AppTheme.textHint : AppTheme.textHintLt, isDark ? AppTheme.bgCardLight : Colors.grey.shade400],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.directions_bus_rounded, color: Colors.white, size: 28),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('NexRide Ticket',
                                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                            Text('Route ${t.routeId}',
                                style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13)),
                          ],
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(t.status.toUpperCase(),
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  ),

                  //Dashed divider
                  _DashedDivider(isDark: isDark),

                  // QR Code
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                               BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
                            ],
                          ),
                          child: QrImageView(
                            data: t.qrCode,
                            version: QrVersions.auto,
                            size: 180,
                            backgroundColor: Colors.white,
                            dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Colors.black),
                            eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Colors.black),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(t.qrCode,
                            style: TextStyle(fontSize: 10, color: isDark ? AppTheme.textHint : AppTheme.textHintLt, letterSpacing: 1),
                            textAlign: TextAlign.center),
                      ],
                    ),
                  ),

                  // Info grid
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: Column(
                      children: [
                        _infoRow('Fare Paid', '₹${t.farePaid.toStringAsFixed(0)}', isDark),
                        _infoRow('Boarding', t.boardingStop ?? 'Any stop', isDark),
                        _infoRow('Alighting', t.alightingStop ?? 'Any stop', isDark),
                        _infoRow('Issued', t.issuedAt.split('T').first, isDark),
                        _infoRow('Status', t.status.toUpperCase(), isDark,
                            valueColor: isActive ? AppTheme.success : (isDark ? AppTheme.textHint : AppTheme.textHintLt)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          FadeInUp(
            delay: const Duration(milliseconds: 200),
            child: Text(
              'Show this QR code to the conductor for boarding.',
              style: TextStyle(color: isDark ? AppTheme.textSecondary : AppTheme.textSecondaryLt, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, bool isDark, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: isDark ? AppTheme.textSecondary : AppTheme.textSecondaryLt, fontSize: 13)),
          Text(value,
              style: TextStyle(
                color: valueColor ?? (isDark ? Colors.white : Colors.black87),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              )),
        ],
      ),
    );
  }
}

class _DashedDivider extends StatelessWidget {
  final bool isDark;
  const _DashedDivider({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 20, height: 20,
            decoration: BoxDecoration(color: isDark ? AppTheme.bgDark : AppTheme.bgLight, shape: BoxShape.circle)),
        Expanded(
          child: LayoutBuilder(builder: (_, constr) {
            final count = (constr.maxWidth / 10).floor();
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(count, (_) =>
                  Container(width: 5, height: 1, color: isDark ? AppTheme.glassBorder : AppTheme.glassBorderLt)),
            );
          }),
        ),
        Container(width: 20, height: 20,
            decoration: BoxDecoration(color: isDark ? AppTheme.bgDark : AppTheme.bgLight, shape: BoxShape.circle)),
      ],
    );
  }
}
