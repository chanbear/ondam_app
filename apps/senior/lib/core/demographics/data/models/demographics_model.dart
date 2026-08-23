import '../../domain/entities/demographics.dart';

/// DTO for a `users` row's age/gender columns. `fromRow`는 둘 다 없으면
/// `null`(완전 미입력)을 반환한다 — `RegionModel.fromRow`와 동일한 원칙.
class DemographicsModel {
  const DemographicsModel({required this.age, required this.gender});

  final int? age;
  final Gender? gender;

  static DemographicsModel? fromRow(Map<String, dynamic>? row) {
    if (row == null) return null;
    final age = row['age'] as int?;
    final gender = Gender.fromValue(row['gender'] as String?);
    if (age == null && gender == null) return null;
    return DemographicsModel(age: age, gender: gender);
  }

  Demographics toEntity() => Demographics(age: age, gender: gender);
}
