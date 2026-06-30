import 'dart:convert';

class OutboxEvent {
  final int? id;
  final int statusCode;          // status_code
  final DateTime createdAt;      // created_at
  final DateTime? lastAttemptAt; // last_attempt_at
  final String status;           // status (queued/sending/delivered/failed)
  final int retryCount;          // retry_count
  final String? type;            // type (emergency, relay, etc.)
  final int? parentEventId;      // parent_event_id
  final Map<String, dynamic>? content; // content (JSON)

  // ⭐ FIX: lat/lng must be nullable because BLE detections often have no GPS
  final double? lat;             
  final double? lng;             
  
  final String? address;         // address
  final String userId;           // user_id

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
    this.lat,        // ⭐ FIX: now nullable
    this.lng,        // ⭐ FIX: now nullable
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
      lat: lat ?? this.lat,      // ⭐ FIX
      lng: lng ?? this.lng,      // ⭐ FIX
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
      'lat': lat,   // ⭐ FIX: nullable
      'lng': lng,   // ⭐ FIX: nullable
      'address': address,
      'user_id': userId,
    };
  }

  factory OutboxEvent.fromMap(Map<String, Object?> map) {
    return OutboxEvent(
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
      content: map['content'] != null
          ? jsonDecode(map['content'] as String) as Map<String, dynamic>
          : null,

      // ⭐ FIX: safely handle NULL values from SQLite
      lat: map['lat'] == null ? null : (map['lat'] as num).toDouble(),
      lng: map['lng'] == null ? null : (map['lng'] as num).toDouble(),

      address: map['address'] as String?,
      userId: map['user_id'] as String,
    );
  }
}
