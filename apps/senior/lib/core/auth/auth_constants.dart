/// Idle timeout before the app re-locks behind the PIN gate on foreground
/// return. Senior: 15 minutes (technical-decisions.md §1-3-A "앱 재진입
/// idle timeout" — longer than Guardian's 5 minutes because elderly users
/// re-open the app less rhythmically). No settings UI exposes this; it is a
/// fixed, centralized constant per app.
const seniorIdleTimeout = Duration(minutes: 15);
