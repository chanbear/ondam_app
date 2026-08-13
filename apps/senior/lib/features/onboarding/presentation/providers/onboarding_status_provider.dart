import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/storage_providers.dart';

const _onboardingCompletedKey = 'onboarding_completed';

/// Whether the user has been through the onboarding flow at least once.
/// `null` = not checked yet, `false`/`true` after the first read. This is a
/// client-side nudge (Home checks it and pushes to onboarding once), NOT a
/// router redirect gate — Phase 2's auth `redirect` logic is not touched by
/// this Phase 3 round.
class OnboardingStatusNotifier extends Notifier<bool?> {
  @override
  bool? build() {
    _restore();
    return null;
  }

  Future<void> _restore() async {
    state = await ref
        .read(localStorageProvider)
        .getBool(_onboardingCompletedKey);
  }

  Future<void> markCompleted() async {
    state = true;
    await ref.read(localStorageProvider).setBool(_onboardingCompletedKey, true);
  }
}

final onboardingStatusProvider =
    NotifierProvider<OnboardingStatusNotifier, bool?>(
      OnboardingStatusNotifier.new,
    );
