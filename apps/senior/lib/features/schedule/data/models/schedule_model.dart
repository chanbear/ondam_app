import 'package:ondam_models/ondam_models.dart';

/// DTO for a raw `schedules` row. `fromJson`/`toEntity()` written by hand —
/// `freezed`/`json_serializable` are not installed yet (api.md). Mirrors
/// Guardian's own `schedule` feature DTO of the same name exactly (same
/// table, same snake_case Postgrest row shape) — kept as a separate file per
/// app rather than shared, same rationale as `AnalysisResultModel`.
class ScheduleModel {
  const ScheduleModel({
    required this.id,
    required this.elderId,
    required this.title,
    required this.scheduledAt,
    required this.isRecurring,
    required this.completed,
    required this.createdAt,
    this.recurrenceHour,
    this.recurrenceMinute,
  });

  factory ScheduleModel.fromJson(Map<String, dynamic> json) {
    final recurrenceTimeRaw = json['recurrence_time'] as String?;
    final recurrenceParts = recurrenceTimeRaw?.split(':');
    return ScheduleModel(
      id: json['id'] as String,
      elderId: json['elder_id'] as String,
      title: json['title'] as String,
      scheduledAt: DateTime.parse(json['scheduled_at'] as String),
      isRecurring: json['is_recurring'] as bool,
      completed: json['completed'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      recurrenceHour: recurrenceParts != null
          ? int.parse(recurrenceParts[0])
          : null,
      recurrenceMinute: recurrenceParts != null
          ? int.parse(recurrenceParts[1])
          : null,
    );
  }

  final String id;
  final String elderId;
  final String title;
  final DateTime scheduledAt;
  final bool isRecurring;
  final bool completed;
  final DateTime createdAt;
  final int? recurrenceHour;
  final int? recurrenceMinute;

  Schedule toEntity() {
    return Schedule(
      id: id,
      elderId: elderId,
      title: title,
      scheduledAt: scheduledAt,
      isRecurring: isRecurring,
      completed: completed,
      createdAt: createdAt,
      recurrenceHour: recurrenceHour,
      recurrenceMinute: recurrenceMinute,
    );
  }
}
