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
  String get easyModeSectionTitle => 'Easy Mode';

  @override
  String get easyModeTitle => 'Easy Mode';

  @override
  String get easyModeSubtitle => 'Switch to bigger buttons and simpler screens';

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
  String get phoneStartSubtitle => 'Enter your phone number and password.';

  @override
  String get phoneNumberLabel => 'Phone number';

  @override
  String get phoneNumberHint => '010-0000-0000';

  @override
  String get pinLabel => 'Password';

  @override
  String get pinHint => '4-digit number';

  @override
  String get startButton => 'Get started';

  @override
  String get forgotPinLink => 'Forgot your password?';

  @override
  String pinWrongWithCount(int count) {
    return 'Incorrect password. ($count failed attempts)';
  }

  @override
  String get pinWrong => 'Incorrect password.';

  @override
  String pinLockedWithTime(String time) {
    return 'Too many attempts. Please try again at $time.';
  }

  @override
  String get pinLockedNoTime =>
      'Too many attempts. Your account is temporarily locked — please try again shortly.';

  @override
  String get pinNotSet => 'No password has been set.';

  @override
  String get pinInvalidFormat => 'Your password must be a 4-digit number.';

  @override
  String get pinUnknownError => 'Something went wrong. Please try again.';

  @override
  String get voiceAssistantLabel => 'Voice assistant';

  @override
  String get navInfo => 'Info';

  @override
  String get navHome => 'Home';

  @override
  String get navRecords => 'History';

  @override
  String get navMore => 'More';

  @override
  String get profileTitle => 'My Info';

  @override
  String get nameLabel => 'Name';

  @override
  String get ageLabel => 'Age';

  @override
  String get profileSaved => 'Your profile has been saved.';

  @override
  String get profileLoadError => 'We couldn\'t load your saved info.';

  @override
  String get myRegionTitle => 'My Region';

  @override
  String get regionLoadError => 'We couldn\'t load your region info.';

  @override
  String get currentRegionLabel => 'Current region';

  @override
  String get regionNotSetValue => 'Not registered yet';

  @override
  String get enterRegionAction => 'Enter my region';

  @override
  String get saveButton => 'Save';

  @override
  String get sidoLabel => 'Province/City';

  @override
  String get sidoPlaceholder => 'Tap to select';

  @override
  String get sigunguLabel => 'City/County/District';

  @override
  String get dongLabel => 'Town/Neighborhood';

  @override
  String get locatingButton => 'Checking your current location…';

  @override
  String get useCurrentLocationButton => 'Fill in with current location';

  @override
  String get locationServiceDisabledError =>
      'Please turn on location services and try again.';

  @override
  String get locationPermissionDeniedError =>
      'Please allow location access in device settings and try again.';

  @override
  String get locationPermissionRequiredError =>
      'You need to allow location access to use your current location.';

  @override
  String get sidoRequiredError => 'Please select a province/city.';

  @override
  String get regionSaved => 'Your region has been saved.';

  @override
  String get sidoPickerTitle => 'Select province/city';

  @override
  String get welfareCenterTitle => 'Find a Senior Center';

  @override
  String get welfareCenterRegionLoadError =>
      'We couldn\'t load your region info.';

  @override
  String get welfareCenterEmptyRegionMessage =>
      'Register your region first to find a senior center.';

  @override
  String get searchNearbyButton => 'Find senior centers near me';

  @override
  String get phoneLaunchError => 'We couldn\'t open the phone app.';

  @override
  String get welfareCenterSearchError =>
      'Something went wrong while searching.';

  @override
  String get welfareCenterNoResults =>
      'We couldn\'t find any senior centers nearby.';

  @override
  String get callButtonTooltip => 'Call';

  @override
  String get voiceUnavailableError =>
      'Voice recognition isn\'t available on this device.';

  @override
  String get voiceInitError => 'We couldn\'t start the voice assistant.';

  @override
  String get voicePreparing => 'Getting the voice assistant ready…';

  @override
  String get voiceProcessing => 'Checking what you said…';

  @override
  String get voiceIdlePrompt => 'Tap the mic and speak';

  @override
  String get voiceListening => 'Listening…';

  @override
  String get voiceStartSemanticLabel => 'Start speaking';

  @override
  String get voiceUnrecognizedAnswer =>
      'I didn\'t quite catch that. Try saying \"문서 찍어줘\" (scan document), \"문자 확인해줘\" (check message), or \"긴급 도움\" (emergency help).';

  @override
  String get voiceRetryButton => 'Please try again';
}
