/// NexRide data models (mirrors FastAPI Pydantic schemas)

// ── User ─────────────────────────────────────────────────────────────────────
class UserModel {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final bool isVerified;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.isVerified,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: json['id'],
    name: json['name'],
    email: json['email'],
    phone: json['phone'],
    isVerified: json['is_verified'] ?? false,
  );
}

// ── Route ─────────────────────────────────────────────────────────────────────
class RouteModel {
  final int id;
  final String routeNumber;
  final String name;
  final String origin;
  final String destination;
  final double? distanceKm;
  final int? estimatedDurationMin;
  final double? fare;
  final bool isActive;

  const RouteModel({
    required this.id,
    required this.routeNumber,
    required this.name,
    required this.origin,
    required this.destination,
    this.distanceKm,
    this.estimatedDurationMin,
    this.fare,
    required this.isActive,
  });

  factory RouteModel.fromJson(Map<String, dynamic> json) => RouteModel(
    id: json['id'],
    routeNumber: json['route_number'],
    name: json['name'],
    origin: json['origin'],
    destination: json['destination'],
    distanceKm: (json['distance_km'] as num?)?.toDouble(),
    estimatedDurationMin: json['estimated_duration_min'],
    fare: (json['fare'] as num?)?.toDouble(),
    isActive: json['is_active'] ?? true,
  );
}

// ── Bus ──────────────────────────────────────────────────────────────────────
class BusModel {
  final int id;
  final String busNumber;
  final int? routeId;
  final int capacity;
  final int currentOccupancy;
  final double? latitude;
  final double? longitude;
  final double? speedKmh;
  final String status;

  const BusModel({
    required this.id,
    required this.busNumber,
    this.routeId,
    required this.capacity,
    required this.currentOccupancy,
    this.latitude,
    this.longitude,
    this.speedKmh,
    required this.status,
  });

  double get occupancyPercent =>
      capacity > 0 ? (currentOccupancy / capacity) * 100 : 0;

  String get crowdLabel {
    if (occupancyPercent >= 75) return 'High';
    if (occupancyPercent >= 40) return 'Medium';
    return 'Low';
  }

  factory BusModel.fromJson(Map<String, dynamic> json) => BusModel(
    id: json['id'],
    busNumber: json['bus_number'],
    routeId: json['route_id'],
    capacity: json['capacity'] ?? 50,
    currentOccupancy: json['current_occupancy'] ?? 0,
    latitude: (json['latitude'] as num?)?.toDouble(),
    longitude: (json['longitude'] as num?)?.toDouble(),
    speedKmh: (json['speed_kmh'] as num?)?.toDouble(),
    status: json['status'] ?? 'active',
  );
}

// ── Ticket ───────────────────────────────────────────────────────────────────
class TicketModel {
  final int id;
  final int routeId;
  final String qrCode;
  final String? boardingStop;
  final String? alightingStop;
  final double farePaid;
  final String status;
  final String issuedAt;

  const TicketModel({
    required this.id,
    required this.routeId,
    required this.qrCode,
    this.boardingStop,
    this.alightingStop,
    required this.farePaid,
    required this.status,
    required this.issuedAt,
  });

  factory TicketModel.fromJson(Map<String, dynamic> json) => TicketModel(
    id: json['id'],
    routeId: json['route_id'],
    qrCode: json['qr_code'],
    boardingStop: json['boarding_stop'],
    alightingStop: json['alighting_stop'],
    farePaid: (json['fare_paid'] as num).toDouble(),
    status: json['status'] ?? 'active',
    issuedAt: json['issued_at'] ?? '',
  );
}
