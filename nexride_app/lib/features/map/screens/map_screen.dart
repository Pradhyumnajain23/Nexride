import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:animate_do/animate_do.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/models/models.dart';
import '../../../shared/widgets/shared_widgets.dart';

/// Live bus tracking screen powered by Google Maps Flutter.
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  GoogleMapController? _mapController;
  List<BusModel> _buses = [];
  BusModel? _selectedBus;
  bool _loading = true;
  String? _etaText;
  bool _etaLoading = false;
  Timer? _refreshTimer;
  late AnimationController _markerPulse;

  // Simulated route polyline for selected bus (Bengaluru sample path)
  final List<LatLng> _sampleRoute = const [
    LatLng(12.9775, 77.5713), // Majestic
    LatLng(12.9500, 77.5845), // Lalbagh
    LatLng(12.9293, 77.5826), // Jayanagar
    LatLng(12.9165, 77.6101), // BTM Layout
    LatLng(12.9172, 77.6234), // Silk Board
    LatLng(12.9116, 77.6389), // HSR Layout
    LatLng(12.9002, 77.6762), // Sarjapur Road
    LatLng(12.8399, 77.6770), // Electronic City
  ];

  @override
  void initState() {
    super.initState();
    _markerPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _fetchBuses();
    // Auto-refresh positions every 10 seconds (simulated real-time)
    _refreshTimer = Timer.periodic(AppConstants.mapRefreshInterval, (_) {
      _fetchBuses();
      _simulateBusMovement();
    });
  }

  Future<void> _fetchBuses() async {
    try {
      final res = await ApiClient.instance.dio.get(
        '/buses/',
        queryParameters: {'status': 'active'},
      );
      if (!mounted) return;
      setState(() {
        _buses = (res.data as List).map((e) => BusModel.fromJson(e)).toList();
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Simulate small GPS movement for visual live-tracking feel.
  void _simulateBusMovement() {
    if (!mounted) return;
    final rng = Random();
    setState(() {
      _buses = _buses.map((bus) {
        if (bus.latitude == null || bus.longitude == null) return bus;
        final dlat = (rng.nextDouble() - 0.5) * 0.001; // ~55m
        final dlng = (rng.nextDouble() - 0.5) * 0.001;
        return BusModel(
          id: bus.id,
          busNumber: bus.busNumber,
          routeId: bus.routeId,
          capacity: bus.capacity,
          currentOccupancy: bus.currentOccupancy,
          latitude: bus.latitude! + dlat,
          longitude: bus.longitude! + dlng,
          speedKmh: bus.speedKmh,
          status: bus.status,
        );
      }).toList().cast<BusModel>();
    });
  }

  Future<void> _fetchEta(int busId) async {
    setState(() { _etaLoading = true; _etaText = null; });
    try {
      final res = await ApiClient.instance.dio.post('/ai/predict-eta', data: {
        'bus_id': busId,
        'stop_name': 'Destination',
      });
      if (!mounted) return;
      final mins = (res.data['estimated_minutes'] as num).toStringAsFixed(1);
      final conf = ((res.data['confidence'] as num) * 100).toStringAsFixed(0);
      setState(() { _etaText = '$mins min  •  $conf% confidence'; });
    } catch (_) {
      if (mounted) setState(() { _etaText = 'ETA unavailable'; });
    } finally {
      if (mounted) setState(() { _etaLoading = false; });
    }
  }

  Future<BitmapDescriptor> _getMarkerIcon(bool isSelected) async {
    return BitmapDescriptor.defaultMarkerWithHue(
      isSelected ? BitmapDescriptor.hueOrange : BitmapDescriptor.hueBlue
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _markerPulse.dispose();
    super.dispose();
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _updateMapStyle();
  }
  
  void _updateMapStyle() {
    // In production, load custom JSON map style from assets for Dark mode
    // For MVp, we use the default light/dark handled automatically if supported
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Set<Marker> markers = _buses
        .where((b) => b.latitude != null && b.longitude != null)
        .map((bus) {
      final isSelected = _selectedBus?.id == bus.id;
      return Marker(
        markerId: MarkerId('bus_${bus.id}'),
        position: LatLng(bus.latitude!, bus.longitude!),
        icon: isSelected
            ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange)
            : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        onTap: () {
          setState(() => _selectedBus = bus);
          _fetchEta(bus.id);
          _mapController?.animateCamera(
            CameraUpdate.newLatLngZoom(
              LatLng(bus.latitude!, bus.longitude!),
              14.5,
            ),
          );
        },
        infoWindow: InfoWindow(
          title: bus.busNumber,
          snippet: 'Speed: ${bus.speedKmh?.toStringAsFixed(1) ?? '--'} km/h',
        ),
      );
    }).toSet();
    
    // Add Route start/end/markers occasionally
    if (_selectedBus != null) {
      for (var i = 0; i < _sampleRoute.length; i++) {
        markers.add(Marker(
          markerId: MarkerId('stop_$i'),
          position: _sampleRoute[i],
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: const InfoWindow(title: 'Bus Stop'),
        ));
      }
    }

    final Set<Polyline> polylines = {};
    if (_selectedBus != null) {
      polylines.add(
        Polyline(
          polylineId: const PolylineId('route_path'),
          points: _sampleRoute,
          color: AppTheme.primary,
          width: 5,
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? AppTheme.bgDark : AppTheme.bgLight,
      body: Stack(
        children: [
          // ── Google Map ──────────────────────────────────────────────────────
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: _buses.isNotEmpty && _buses.first.latitude != null
                  ? LatLng(_buses.first.latitude!, _buses.first.longitude!)
                  : const LatLng(12.9716, 77.5946),
              zoom: 12.5,
            ),
            markers: markers,
            polylines: polylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: false,
          ),

          // ── Top Status Bar ──────────────────────────────────────────
          Positioned(
            top: 0, left: 0, right: 0,
            child: FadeInDown(
              child: Container(
                padding: EdgeInsets.fromLTRB(
                    16, MediaQuery.of(context).padding.top + 10, 16, 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: isDark
                        ? [
                            AppTheme.bgDark.withOpacity(0.95),
                            AppTheme.bgDark.withOpacity(0),
                          ]
                        : [
                            AppTheme.bgLight.withOpacity(0.95),
                            AppTheme.bgLight.withOpacity(0),
                          ],
                  ),
                ),
                child: Row(
                  children: [
                    // Live bus count pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppTheme.bgCard
                            : AppTheme.bgCardLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: isDark
                                ? AppTheme.glassBorder
                                : AppTheme.glassBorderLt),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 6)
                        ],
                      ),
                      child: Row(
                        children: [
                          AnimatedBuilder(
                            animation: _markerPulse,
                            builder: (_, __) => Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: _loading
                                    ? AppTheme.warning
                                    : Color.lerp(
                                        AppTheme.success,
                                        AppTheme.success.withOpacity(0.4),
                                        _markerPulse.value)!,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _loading
                                ? 'Loading buses...'
                                : '${_buses.length} buses live',
                            style: TextStyle(
                                color: isDark
                                    ? Colors.white
                                    : Colors.black87,
                                fontSize: 13,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),

                    const Spacer(),

                    // Google Maps logic indicator
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppTheme.bgCard
                            : AppTheme.bgCardLight,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: isDark
                                ? AppTheme.glassBorder
                                : AppTheme.glassBorderLt),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.map_rounded,
                              size: 13,
                              color: isDark
                                  ? AppTheme.primary
                                  : AppTheme.primary),
                          const SizedBox(width: 5),
                          Text(
                            'Google Maps',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Refresh button
                    GestureDetector(
                      onTap: _fetchBuses,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppTheme.bgCard
                              : AppTheme.bgCardLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: isDark
                                  ? AppTheme.glassBorder
                                  : AppTheme.glassBorderLt),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 6)
                          ],
                        ),
                        child: Icon(Icons.refresh_rounded,
                            color: isDark ? Colors.white : Colors.black87,
                            size: 20),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Selected Bus Detail Panel ────────────────────────────────
          if (_selectedBus != null)
            Positioned(
              bottom: 16, left: 16, right: 16,
              child: FadeInUp(
                duration: const Duration(milliseconds: 300),
                child: GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(11),
                            ),
                            child: const Icon(Icons.directions_bus_rounded,
                                color: AppTheme.primary, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _selectedBus!.busNumber,
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black87),
                                ),
                                Text(
                                  'Speed: ${_selectedBus!.speedKmh?.toStringAsFixed(1) ?? '--'} km/h',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: isDark
                                          ? AppTheme.textSecondary
                                          : AppTheme.textSecondaryLt),
                                ),
                              ],
                            ),
                          ),
                          CrowdBadge(level: _selectedBus!.crowdLabel),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => setState(() {
                              _selectedBus = null;
                              _etaText = null;
                            }),
                            child: Icon(Icons.close_rounded,
                                color: isDark
                                    ? AppTheme.textHint
                                    : AppTheme.textHintLt,
                                size: 20),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // ETA Row
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: AppTheme.primary.withOpacity(0.2)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.access_time_rounded,
                                color: AppTheme.primary, size: 16),
                            const SizedBox(width: 8),
                            _etaLoading
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppTheme.primary),
                                  )
                                : Text(
                                    _etaText ?? 'Calculating ETA...',
                                    style: const TextStyle(
                                        color: AppTheme.primary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13),
                                  ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Occupancy + Location chips
                      Row(
                        children: [
                          _infoChip(
                              Icons.people_rounded,
                              '${_selectedBus!.currentOccupancy}/${_selectedBus!.capacity} seats',
                              AppTheme.primary),
                          const SizedBox(width: 8),
                          _infoChip(
                              Icons.location_on_rounded,
                              '${_selectedBus!.latitude?.toStringAsFixed(4)}, '
                              '${_selectedBus!.longitude?.toStringAsFixed(4)}',
                              AppTheme.secondary),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // ── Zoom Controls ───────────────────────────────────────────
          Positioned(
            right: 16,
            top: MediaQuery.of(context).padding.top + 70,
            child: Column(
              children: [
                _mapBtn(Icons.add_rounded, () async {
                  final zoom = await _mapController?.getZoomLevel();
                  if (zoom != null) {
                    _mapController?.animateCamera(CameraUpdate.zoomTo(zoom + 1));
                  }
                }),
                const SizedBox(height: 4),
                _mapBtn(Icons.remove_rounded, () async {
                 final zoom = await _mapController?.getZoomLevel();
                  if (zoom != null) {
                    _mapController?.animateCamera(CameraUpdate.zoomTo(zoom - 1));
                  }
                }),
                const SizedBox(height: 4),
                _mapBtn(Icons.my_location_rounded, () {
                  _mapController?.animateCamera(
                    CameraUpdate.newLatLngZoom(
                      const LatLng(12.9716, 77.5946), 12.5)
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _mapBtn(IconData icon, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: isDark ? AppTheme.bgCard : AppTheme.bgCardLight,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: isDark ? AppTheme.glassBorder : AppTheme.glassBorderLt),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 6)
          ],
        ),
        child:
            Icon(icon, size: 18, color: isDark ? Colors.white : Colors.black87),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.09),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 5),
            Flexible(
              child: Text(label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}
