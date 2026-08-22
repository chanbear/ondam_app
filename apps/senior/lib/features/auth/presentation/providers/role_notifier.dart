import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_models/ondam_models.dart';

import '../../../../core/auth/auth_state_provider.dart';
import 'auth_di_providers.dart';

/// Roles currently held by the signed-in user. `build()` doubles as the
/// router-support check ("does this user have any role yet") — the role
/// selection page's redirect gate uses `hasValue && value.isNotEmpty`.
///
/// Watches `authStateChangesProvider` so it re-fetches on every sign-in/
/// sign-out (PHASE 38 — same staleness class as `hasPinProvider`'s fix: a
/// one-shot `AsyncNotifier.build()` that swallows errors into `[]` can cache
/// a wrong empty result across an entire session if that first fetch races
/// a still-settling restored session at app boot).
class RoleNotifier extends AsyncNotifier<List<UserRole>> {
  @override
  Future<List<UserRole>> build() async {
    ref.watch(authStateChangesProvider);
    final result = await ref.read(getRolesUseCaseProvider).call();
    return switch (result) {
      Ok(:final value) => value,
      Err() => const [],
    };
  }

  Future<Result<void>> addRole(UserRole role) async {
    final result = await ref.read(addRoleUseCaseProvider).call(role);
    if (result is Ok<void>) {
      ref.invalidateSelf();
    }
    return result;
  }
}

final roleNotifierProvider =
    AsyncNotifierProvider<RoleNotifier, List<UserRole>>(RoleNotifier.new);
