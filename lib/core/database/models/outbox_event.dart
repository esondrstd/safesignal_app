import 'dart:convert';

class OutboxEvent {
  final int? id;

  final int statusCode;
  final DateTime createdAt;
  final DateTime? lastAttemptAt;

  final String status;
  final int retryCount;

  final String? type;
  final int? parentEventId;

  final Map<String, dynamic>? content;

  final String? emergencyCategory;

  final double lat;
  final double lng;

  final String? address;

  final String userId;

  const OutboxEvent({
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
      'content': content == null ? null : jsonEncode(content),
      'lat': lat,
      'lng': lng,
      'address': address,
      'user_id': userId,
      'emergency_category': emergencyCategory,
    };
  }

  factory OutboxEvent.fromMap(Map<String, Object?> map) {
    int? safeInt(Object? v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is String) return int.tryParse(v);
      return null;
    }

    double safeDouble(Object? v) {
      if (v == null) return 0.0;
      if (v is double) return v;
      if (v is int) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0.0;
      return 0.0;
    }

    Map<String, dynamic>? safeContent(Object? raw) {
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
    }

    return OutboxEvent(
      id: safeInt(map['id']),
      statusCode: safeInt(map['status_code']) ?? 0,
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ??
          DateTime.now(),
      lastAttemptAt: map['last_attempt_at'] != null
          ? DateTime.tryParse(map['last_attempt_at'].toString())
          : null,
      status: map['status']?.toString() ?? 'queued',
      retryCount: safeInt(map['retry_count']) ?? 0,
      type: map['type']?.toString(),
      parentEventId: safeInt(map['parent_event_id']),
      content: safeContent(map['content']),
      lat: safeDouble(map['lat']),
      lng: safeDouble(map['lng']),
      address: map['address']?.toString(),
      userId: map['user_id']?.toString() ?? '',
      emergencyCategory: map['emergency_category']?.toString(),
    );
  }
}