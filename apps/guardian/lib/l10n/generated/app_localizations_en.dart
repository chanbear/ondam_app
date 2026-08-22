// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Ondam';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get accountSectionTitle => 'Account';

  @override
  String get logout => 'Log out';

  @override
  String get deleteAccount => 'Delete account';

  @override
  String get deleteAccountConfirmTitle => 'Delete your account?';

  @override
  String get deleteAccountConfirmMessage =>
      'Deleting your account permanently removes it and all saved information right away. This cannot be undone.';

  @override
  String get deleteAccountConfirmLabel => 'Delete';

  @override
  String get phoneStartTitle => 'Get started with your phone number';

  @override
  String get phoneStartSubtitle => 'Enter your name and phone number.';

  @override
  String get nameLabel => 'Name';

  @override
  String get phoneNumberLabel => 'Phone number';

  @override
  String get phoneNumberHint => '010-0000-0000';

  @override
  String get startButton => 'Get started';

  @override
  String get navHome => 'Home';

  @override
  String get navNotification => 'Alerts';

  @override
  String get navRecords => 'History';

  @override
  String get navStatistics => 'Stats';

  @override
  String get navMore => 'More';

  @override
  String get noConnectedEldersMessage => 'No elders connected yet.';

  @override
  String get connectElderAction => 'Connect with an elder';

  @override
  String get recentActivityTitle => 'Recent activity';

  @override
  String get upcomingScheduleTitle => 'Upcoming schedule';

  @override
  String get noUpcomingSchedule => 'No upcoming schedule.';

  @override
  String get reassuranceLoadError => 'We couldn\'t load the status.';

  @override
  String get dangerousAlertTitle =>
      'There\'s activity that needs your attention';

  @override
  String get alertCheckRecordsDescription =>
      'Check the History tab for details.';

  @override
  String get cautionAlertTitle => 'There\'s activity that needs some caution';

  @override
  String get safeStatusMessage => 'Everything looks fine today.';

  @override
  String get safeStatusDescription => 'No special alerts yet.';

  @override
  String get recentActivityLoadError => 'We couldn\'t load recent activity.';

  @override
  String get noActivityRecords => 'No activity records yet.';
}
