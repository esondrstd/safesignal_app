class InboxEvent {
  final int? id;
  final String ephemeralId;
  final int statusCode; // 0/1/2
  final int rssi;
  final DateTime detectedAt;
  final double? receiverLat;
  final double? receiverLng;

  InboxEvent({
    this.id,
    required this.ephemeralId,
    required this.statusCode,
    required this.rssi,
    required this.detectedAt,
    this.receiverLat,
    this.receiverLng,
  });

  factory InboxEvent.fromMap(Map<String, Object?> map) {
    return InboxEvent(
      id: map['id'] as int?,
      ephemeralId: map['ephemeral_id'] as String,
      statusCode: map['status_code'] as int,
      rssi: map['rssi'] as int,
      detectedAt: DateTime.parse(map['detected_at'] as String),
      receiverLat: map['receiver_location_lat'] as double?,
      receiverLng: map['receiver_location_lng'] as double?,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'ephemeral_id': ephemeralId,
      'status_code': statusCode,
      'rssi': rssi,
      'detected_at': detectedAt.toIso8601String(),
      'receiver_location_lat': receiverLat,
      'receiver_location_lng': receiverLng,
    };
  }
}
