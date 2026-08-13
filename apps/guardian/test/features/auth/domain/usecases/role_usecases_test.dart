import 'package:flutter_test/flutter_test.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_guardian/features/auth/domain/usecases/add_role_usecase.dart';
import 'package:ondam_guardian/features/auth/domain/usecases/get_roles_usecase.dart';
import 'package:ondam_models/ondam_models.dart';

import '../fakes/fake_auth_repository.dart';

void main() {
  late FakeAuthRepository repository;
  late AddRoleUseCase addRole;
  late GetRolesUseCase getRoles;

  setUp(() {
    repository = FakeAuthRepository();
    addRole = AddRoleUseCase(repository);
    getRoles = GetRolesUseCase(repository);
  });

  test('addRole delegates the chosen role to the repository', () async {
    await addRole(UserRole.guardian);
    expect(repository.addRoleCalls, [UserRole.guardian]);
  });

  test('getRoles returns an empty list for a user with no role yet', () async {
    repository.getRolesResult = const Ok(<UserRole>[]);

    final result = await getRoles();

    expect((result as Ok<List<UserRole>>).value, isEmpty);
  });

  test('getRoles returns [elder] for an elder-only user', () async {
    repository.getRolesResult = const Ok([UserRole.elder]);

    final result = await getRoles();

    expect((result as Ok<List<UserRole>>).value, [UserRole.elder]);
  });

  test('getRoles returns [guardian] for a guardian-only user', () async {
    repository.getRolesResult = const Ok([UserRole.guardian]);

    final result = await getRoles();

    expect((result as Ok<List<UserRole>>).value, [UserRole.guardian]);
  });

  test('getRoles returns both roles for a same-phone dual-role user', () async {
    repository.getRolesResult = const Ok([UserRole.elder, UserRole.guardian]);

    final result = await getRoles();

    expect(
      (result as Ok<List<UserRole>>).value,
      containsAll([UserRole.elder, UserRole.guardian]),
    );
  });
}
