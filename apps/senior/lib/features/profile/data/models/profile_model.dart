import '../../domain/entities/profile.dart';

/// DTO for a `users` row's name/age columns. `fromRow` returns `null` when
/// either column is unset (fresh user) — a valid "not set" state, not a
/// parse error, matching `RegionModel`'s pattern.
class ProfileModel {
  const ProfileModel({required this.name, required this.age});

  final String name;
  final int age;

  static ProfileModel? fromRow(Map<String, dynamic>? row) {
    if (row == null) return null;
    final name = row['name'] as String?;
    final age = row['age'] as int?;
    if (name == null || name.isEmpty || age == null) return null;
    return ProfileModel(name: name, age: age);
  }

  Profile toEntity() => Profile(name: name, age: age);
}
