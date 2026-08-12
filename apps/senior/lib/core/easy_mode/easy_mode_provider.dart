import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/storage_providers.dart';

/// Easy mode state — a `core`-level, app-wide, keepAlive provider because
/// (per riverpod.md) it is shared across every screen, not just one page.
///
/// This is state-management *foundation* only: it persists to
/// LocalStorageService and restores on app start. It intentionally does not
/// render anything — the actual easy-mode UI (large buttons, simplified
/// navigation, etc.) is `home`/Phase 3 and Phase 9 work per
/// implementation-plan.md §2, not this file.
const _easyModeStorageKey = 'easy_mode_enabled';

class EasyModeNotifier extends Notifier<bool> {
  @override
  bool build() {
    _restore();
    return false;
  }

  Future<void> _restore() async {
    final stored = await ref
        .read(localStorageProvider)
        .getBool(_easyModeStorageKey);
    state = stored;
  }

  Future<void> toggle() async {
    final next = !state;
    state = next;
    await ref.read(localStorageProvider).setBool(_easyModeStorageKey, next);
  }
}

final easyModeProvider = NotifierProvider<EasyModeNotifier, bool>(
  EasyModeNotifier.new,
);
