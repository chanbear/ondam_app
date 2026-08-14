import '../../domain/entities/notification_item.dart';

/// DTO for a `notifications` row. Model→Entity conversion lives here
/// (api.md: domain never converts back into a Model).
class NotificationModel {
  const NotificationModel({
    required this.id,
    required this.targetUserId,
    required this.type,
    required this.payload,
    required this.sentVia,
    required this.createdAt,
    this.readAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      targetUserId: json['target_user_id'] as String,
      type: json['type'] as String,
      payload: (json['payload'] as Map?)?.cast<String, dynamic>() ?? const {},
      sentVia: json['sent_via'] as String? ?? 'push',
      createdAt: DateTime.parse(json['created_at'] as String),
      readAt: json['read_at'] == null
          ? null
          : DateTime.parse(json['read_at'] as String),
    );
  }

  final String id;
  final String targetUserId;
  final String type;
  final Map<String, dynamic> payload;
  final String sentVia;
  final DateTime createdAt;
  final DateTime? readAt;

  NotificationItem toEntity() => NotificationItem(
    id: id,
    targetUserId: targetUserId,
    type: type,
    payload: payload,
    sentVia: sentVia,
    createdAt: createdAt,
    readAt: readAt,
  );
}
