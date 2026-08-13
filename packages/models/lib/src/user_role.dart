/// Elder/guardian role membership. Source of truth is the `user_roles`
/// table (technical-decisions.md §1-3-A "Role 관리") — never inferred from
/// which app (Senior/Guardian) a request came from. A single phone number
/// may hold both roles at once.
enum UserRole {
  elder,
  guardian;

  /// Matches the `role` text column's `check (role in ('elder', 'guardian'))`
  /// constraint in `supabase/migrations/20260812000001_create_user_roles.sql`.
  String toDbValue() => name;

  static UserRole fromDbValue(String value) => switch (value) {
    'elder' => UserRole.elder,
    'guardian' => UserRole.guardian,
    _ => throw ArgumentError('Unknown role: $value'),
  };
}
