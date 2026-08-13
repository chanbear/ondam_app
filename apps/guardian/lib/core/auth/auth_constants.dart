/// Idle timeout before the app re-locks behind the PIN gate on foreground
/// return. Guardian: 5 minutes (technical-decisions.md §1-3-A "앱 재진입
/// idle timeout" — shorter than Senior's 15 minutes since guardians check
/// the app more rhythmically and the data it shows is more sensitive to a
/// third party glancing at an unlocked phone). No settings UI exposes
/// this; it is a fixed, centralized constant per app.
const guardianIdleTimeout = Duration(minutes: 5);
