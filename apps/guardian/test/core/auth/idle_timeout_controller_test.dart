import 'package:flutter_test/flutter_test.dart';
import 'package:ondam_guardian/core/auth/idle_timeout_controller.dart';

void main() {
  group('shouldRelock', () {
    test('does not relock if backgrounded for less than the idle timeout', () {
      final backgroundedAt = DateTime(2026, 1, 1, 12, 0);
      final now = backgroundedAt.add(const Duration(minutes: 4));

      expect(
        shouldRelock(
          backgroundedAt: backgroundedAt,
          now: now,
          idleTimeout: const Duration(minutes: 5),
        ),
        isFalse,
      );
    });

    test('relocks once the idle timeout is reached exactly', () {
      final backgroundedAt = DateTime(2026, 1, 1, 12, 0);
      final now = backgroundedAt.add(const Duration(minutes: 5));

      expect(
        shouldRelock(
          backgroundedAt: backgroundedAt,
          now: now,
          idleTimeout: const Duration(minutes: 5),
        ),
        isTrue,
      );
    });

    test('relocks if backgrounded well past the idle timeout', () {
      final backgroundedAt = DateTime(2026, 1, 1, 12, 0);
      final now = backgroundedAt.add(const Duration(hours: 1));

      expect(
        shouldRelock(
          backgroundedAt: backgroundedAt,
          now: now,
          idleTimeout: const Duration(minutes: 5),
        ),
        isTrue,
      );
    });
  });
}
