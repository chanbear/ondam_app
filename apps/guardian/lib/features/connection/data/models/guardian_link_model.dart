import 'package:ondam_models/ondam_models.dart';

/// DTO for a `guardian_links` row. `fromJson`/`toEntity()` written by hand —
/// `freezed`/`json_serializable` are not installed yet (api.md).
class GuardianLinkModel {
  const GuardianLinkModel({
    required this.id,
    required this.elderId,
    required this.guardianId,
    required this.status,
    required this.createdAt,
    this.respondedAt,
  });

  factory GuardianLinkModel.fromJson(Map<String, dynamic> json) {
    return GuardianLinkModel(
      id: json['id'] as String,
      elderId: json['elder_id'] as String,
      guardianId: json['guardian_id'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      respondedAt: json['responded_at'] != null
          ? DateTime.parse(json['responded_at'] as String)
          : null,
    );
  }

  final String id;
  final String elderId;
  final String guardianId;
  final String status;
  final DateTime createdAt;
  final DateTime? respondedAt;

  GuardianLink toEntity() {
    return GuardianLink(
      id: id,
      elderId: elderId,
      guardianId: guardianId,
      status: GuardianLinkStatus.fromDbValue(status),
      createdAt: createdAt,
      respondedAt: respondedAt,
    );
  }
}
