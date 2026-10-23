import 'package:flutter/foundation.dart' show kIsWeb;

class AppConstants {
  AppConstants._();

  // ── API ────────────────────────────────────────────────────────────────────
  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:8000';
    // LAN IP of the dev machine — Android physical device connects over Wi-Fi
    return 'http://10.120.141.223:8000';
  }

  // ── Mapbox (fallback) ────────────────────────────────────────────────────
 



static const String mapboxAccessToken =
    String.fromEnvironment('MAPBOX_ACCESS_TOKEN');

  static const String mapboxStyleUrlDark =
      'https://api.mapbox.com/styles/v1/mapbox/dark-v11/tiles/256/{z}/{x}/{y}@2x'
      '?access_token=$mapboxAccessToken';

  static const String mapboxStyleUrlLight =
      'https://api.mapbox.com/styles/v1/mapbox/light-v11/tiles/256/{z}/{x}/{y}@2x'
      '?access_token=$mapboxAccessToken';

  // ── MapmyIndia (Mappls) REST Tiles ───────────────────────────────────────
  // Get your free API key at: https://apis.mappls.com/console/
  static const String mapplsApiKey = 'YOUR_MAPPLS_API_KEY';

  // Standard raster tile — works with flutter_map TileLayer
  static const String mapplsTileUrl =
      'https://apis.mappls.com/advancedmaps/v1/$mapplsApiKey/still_lite/{z}/{x}/{y}.png';

  /// Returns Mappls tile URL if key is set, else falls back to Mapbox.
  static String mapTileUrl({bool dark = false}) {
    if (mapplsApiKey != 'YOUR_MAPPLS_API_KEY') return mapplsTileUrl;
    return dark ? mapboxStyleUrlDark : mapboxStyleUrlLight;
  }

  // ── Storage Keys ──────────────────────────────────────────────────────────
  static const String tokenKey = 'nexride_access_token';
  static const String userKey  = 'nexride_user';

  // ── Timing ────────────────────────────────────────────────────────────────
  static const int otpLength = 6;
  static const Duration connectTimeout  = Duration(seconds: 20); // generous timeout
  static const Duration receiveTimeout  = Duration(seconds: 20);
  static const Duration snackbarDuration   = Duration(seconds: 3);
  static const Duration animationDuration  = Duration(milliseconds: 350);
  static const Duration mapRefreshInterval = Duration(seconds: 10);
}
