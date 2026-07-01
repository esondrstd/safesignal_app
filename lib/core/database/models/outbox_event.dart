import 'dart:convert';

class OutboxEvent {
  final int? id;

  // Emergency severity: 2=Critical, 1=Non-Urgent, 0=Safe
  final int statusCode;

  final DateTime createdAt;
  final DateTime? lastAttemptAt;

  // queued, sending, delivered, failed
  final String status;

  final int retryCount;

  // emergency, relay, status
  final String? type;

  // Hop-chain parent (NOT used for emergency metadata)
  final int? parentEventId;

  // JSON payload for mesh relay logic (stored in TEXT "content")
  final Map<String, dynamic>? content;

  // Emergency category (Medical, Fire, Flood, etc.)
  final String? emergencyCategory;

  // lat/lng are NOT NULL in schema → non-nullable here
  final double lat;
  final double lng;

  final String? address;

  final String userId;

  OutboxEvent({
    this.id,
    required this.statusCode,
    required this.createdAt,
    this.lastAttemptAt,
    required this.status,
    this.retryCount = 0,
    this.type,
    this.parentEventId,
    this.content,
    this.emergencyCategory,
    required this.lat,
    required this.lng,
    this.address,
    required this.userId,
  });

  OutboxEvent copyWith({
    int? id,
    int? statusCode,
    DateTime? createdAt,
    DateTime? lastAttemptAt,
    String? status,
    int? retryCount,
    String? type,
    int? parentEventId,
    Map<String, dynamic>? content,
    String? emergencyCategory,
    double? lat,
    double? lng,
    String? address,
    String? userId,
  }) {
    return OutboxEvent(
      id: id ?? this.id,
      statusCode: statusCode ?? this.statusCode,
      createdAt: createdAt ?? this.createdAt,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
      status: status ?? this.status,
      retryCount: retryCount ?? this.retryCount,
      type: type ?? this.type,
      parentEventId: parentEventId ?? this.parentEventId,
      content: content ?? this.content,
      emergencyCategory: emergencyCategory ?? this.emergencyCategory,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      address: address ?? this.address,
      userId: userId ?? this.userId,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'status_code': statusCode,
      'created_at': createdAt.toIso8601String(),
      'last_attempt_at': lastAttemptAt?.toIso8601String(),
      'status': status,
      'retry_count': retryCount,
      'type': type,
      'parent_event_id': parentEventId,
      'content': content != null ? jsonEncode(content) : null,
      'lat': lat,
      'lng': lng,
      'address': address,
      'user_id': userId,
      'emergency_category': emergencyCategory,
    };
  }

  factory OutboxEvent.fromMap(Map<String, Object?> map) {
    final e = OutboxEvent(
      id: map['id'] as int?,
      statusCode: map['status_code'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
      lastAttemptAt: map['last_attempt_at'] != null
          ? DateTime.parse(map['last_attempt_at'] as String)
          : null,
      status: map['status'] as String,
      retryCount: (map['retry_count'] as int?) ?? 0,
      type: map['type'] as String?,
      parentEventId: map['parent_event_id'] as int?,

      content: (() {
        final raw = map['content'];
        if (raw == null) return null;

        if (raw is Map) {
          return Map<String, dynamic>.from(raw);
        }

        if (raw is String) {
          try {
            return jsonDecode(raw) as Map<String, dynamic>;
          } catch (_) {
            return null;
          }
        }

        return null;
      })(),

      lat: (map['lat'] as num).toDouble(),
      lng: (map['lng'] as num).toDouble(),
      address: map['address'] as String?,
      userId: map['user_id'] as String? ?? '',
      emergencyCategory: map['emergency_category'] as String?,
    );

    // ⭐ Tripwire: catch nulls at the exact moment they enter the system
    debugTripwire(e, source: "fromMap");

    return e;
  }
}

void debugTripwire(OutboxEvent e, {String? source}) {
  final prefix = source != null ? "[$source]" : "[OutboxEvent]";

  if (e.id == null) print("$prefix id is NULL");
  if (e.userId.isEmpty) print("$prefix userId is EMPTY");
  if (e.lat.isNaN) print("$prefix lat is NaN");
  if (e.lng.isNaN) print("$prefix lng is NaN");
  if (e.content == null) print("$prefix content is NULL");
  if (e.content?['hop'] == null) print("$prefix hop is NULL");
  if (e.content?['ephemeralId'] == null) print("$prefix ephId is NULL");
}

