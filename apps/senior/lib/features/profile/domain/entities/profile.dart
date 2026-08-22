/// The elder's name/age — the two `users` columns 20260822000001 added.
/// A `null` value (inside [Ok]) is a valid "not set yet" state, matching
/// `Region`'s pattern.
class Profile {
  const Profile({required this.name, required this.age});

  final String name;
  final int age;
}
