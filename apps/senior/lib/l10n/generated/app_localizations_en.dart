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
  String get appTagline =>
      'A helper for reading documents and messages for seniors';

  @override
  String get splashTagline => 'A trusted daily assistant for seniors';

  @override
  String get splashStartButton => 'Get started with Ondam';

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
  String get startButton => 'Continue to setup';

  @override
  String get socialLoginDivider => 'or';

  @override
  String get googleLoginButton => 'Continue with Google';

  @override
  String get guestSignInButton => 'Continue without signing up';

  @override
  String get oauthPinSetupTitle => 'Set up a PIN';

  @override
  String get oauthPinSetupSubtitle =>
      'You\'ll use this PIN to log in from now on.';

  @override
  String get oauthPinEntryTitle => 'Enter your PIN';

  @override
  String get oauthPinEntrySubtitle => 'Enter the 4-digit PIN you set up.';

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
  String get ageDecreaseAction => 'Decrease age';

  @override
  String get ageIncreaseAction => 'Increase age';

  @override
  String get genderSectionLabel => 'Gender';

  @override
  String get genderMaleLabel => 'Male';

  @override
  String get genderFemaleLabel => 'Female';

  @override
  String get genderRequiredError =>
      'Please select a gender. It\'s needed for personalized info search.';

  @override
  String get profileSaved => 'Your profile has been saved.';

  @override
  String get profileLoadError => 'We couldn\'t load your saved info.';

  @override
  String get myRegionTitle => 'My Region';

  @override
  String get regionInputHint => 'e.g. Seoul, Gangnam-gu, Yeoksam-dong';

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
  String get publicFacilitySearchLabel => 'Find Public Facilities';

  @override
  String get publicFacilitySearchSubtitle =>
      'Look for public facilities nearby';

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
  String get linkLaunchError => 'We couldn\'t open the link.';

  @override
  String get benefitServiceDetailTitle => 'Benefit Info';

  @override
  String get benefitServiceDetailLoadError =>
      'We couldn\'t load the benefit info.';

  @override
  String get supportTargetLabel => 'Who qualifies';

  @override
  String get applyMethodLabel => 'How to apply';

  @override
  String get contactCallButton => 'Call for inquiries';

  @override
  String get viewDetailButton => 'View details';

  @override
  String get welfareCenterSearchError =>
      'Something went wrong while searching.';

  @override
  String get welfareCenterNoResults =>
      'We couldn\'t find any senior centers nearby.';

  @override
  String welfareCenterResultsSummary(String region, int count) {
    return '$count senior centers near $region';
  }

  @override
  String get callButtonTooltip => 'Call';

  @override
  String get directionsButtonLabel => 'Directions';

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

  @override
  String get riskSafeLabel => 'Safe';

  @override
  String get riskCautionLabel => 'Caution';

  @override
  String get riskDangerousLabel => 'Danger detected';

  @override
  String get analysisTypeDocumentLabel => 'Document analysis';

  @override
  String get analysisTypeMessageLabel => 'Message check';

  @override
  String get analysisResultTitle => 'Analysis Result';

  @override
  String get shareButton => 'Share';

  @override
  String get pinEntryPrompt => 'Please enter your PIN';

  @override
  String get pinForgotLink => 'Forgot your PIN?';

  @override
  String get pinResetTitle => 'Reset PIN';

  @override
  String get identityVerifyFailedTitle => 'We couldn\'t verify your identity';

  @override
  String get retryButton => 'Try again';

  @override
  String get pinNewSetupPrompt => 'Please set a new 4-digit PIN';

  @override
  String get pinMismatchError => 'The PINs don\'t match. Please start over.';

  @override
  String get pinConfirmPrompt => 'Please enter it one more time';

  @override
  String get pinSetupPrompt => 'Please set a 4-digit PIN to use';

  @override
  String get pinSetupDescription =>
      'From now on, you\'ll use this PIN to open the app.';

  @override
  String get roleSelectTitle => 'How would you like to use the app?';

  @override
  String get roleSelectSubtitle =>
      'We\'ll prepare the screens to fit your purpose.';

  @override
  String get roleAlreadyRegisteredNotice =>
      'This number is already registered with another role. If you continue, this role will be added too.';

  @override
  String get roleElderButton => 'I\'m a senior';

  @override
  String get roleGuardianButton => 'I\'m a family member (guardian)';

  @override
  String get pinKeypadClearLabel => 'Clear';

  @override
  String get guardianConnectTitle => 'Connect Guardian';

  @override
  String get qrGeneratingMessage => 'Creating the QR code';

  @override
  String get qrGenerateError =>
      'Couldn\'t create the QR code. Please try again.';

  @override
  String get qrShowGuardianPrompt => 'Show this QR code to your guardian';

  @override
  String get qrScanExplanation =>
      'When your guardian scans this QR code, a connection request will be sent.';

  @override
  String get qrExpiredMessage => 'The QR code has expired.';

  @override
  String get qrRegenerateButton => 'Create QR code again';

  @override
  String get guardianListTitle => 'Connected Guardians';

  @override
  String get guardianConnectButton => 'Connect a guardian';

  @override
  String get guardianListLoadError => 'Couldn\'t load the guardian list.';

  @override
  String get guardianListEmptyMessage =>
      'You don\'t have any connected guardians yet\nTap Connect a Guardian to show your QR code';

  @override
  String guardianRequestLabelWithId(String id) {
    return 'Guardian connection request ($id)';
  }

  @override
  String guardianConnectedLabelWithId(String id) {
    return 'Connected guardian ($id)';
  }

  @override
  String guardianConnectedSince(String date) {
    return 'Connected · $date';
  }

  @override
  String get acceptButton => 'Accept';

  @override
  String get rejectButton => 'Decline';

  @override
  String get guardianRevokeConfirmTitle => 'Disconnect this guardian?';

  @override
  String get guardianRevokeConfirmMessage =>
      'Once disconnected, this guardian will no longer be able to see your information.';

  @override
  String get guardianRevokeConfirmLabel => 'Disconnect';

  @override
  String get guardianRevokeAction => 'Disconnect';

  @override
  String get guardianStatusPending => 'Request pending';

  @override
  String get guardianStatusAccepted => 'Connected';

  @override
  String get guardianStatusRejected => 'Declined';

  @override
  String get guardianStatusRevoked => 'Disconnected';

  @override
  String get documentScanTitle => 'Scan Document';

  @override
  String get documentScanStartTitle => 'Document Analysis';

  @override
  String get documentScanStartTakePhotoButton => 'Take a photo';

  @override
  String get documentScanStartPickPhotoButton => 'Choose from library';

  @override
  String get documentScanStartTipTitle => 'Please check before you start!';

  @override
  String get documentScanStartTipLine1 =>
      'Make sure the text is clearly visible';

  @override
  String get documentScanStartTipLine2 =>
      'Bright, glare-free lighting gives more accurate results';

  @override
  String get photoLibraryUnavailableError => 'Couldn\'t load the photo.';

  @override
  String get cameraPermissionCheckError => 'Couldn\'t check camera permission.';

  @override
  String get cameraPermissionRequestMessage =>
      'To photograph and analyze documents and messages,\nplease allow camera access.';

  @override
  String get cameraPermissionRequestButton => 'Allow camera permission';

  @override
  String get cameraPermissionBlockedMessage =>
      'Camera permission is blocked.\nPlease allow it directly in device settings.';

  @override
  String get openSettingsButton => 'Open settings';

  @override
  String get scanPreviewTitle => 'Review Photos';

  @override
  String get retakeLabel => 'Retake';

  @override
  String scannedDocumentsCount(int count) {
    return '$count photos taken';
  }

  @override
  String photoCountBadge(int count) {
    return '$count';
  }

  @override
  String get addAnotherPhotoButton => 'Take another photo';

  @override
  String get analyzeButton => 'Analyze';

  @override
  String documentIndexLabel(int index) {
    return 'Document $index';
  }

  @override
  String deletePhotoAtIndexLabel(int index) {
    return 'Delete photo $index';
  }

  @override
  String documentAnalyzingProgress(int current, int total) {
    return 'Analyzing document $current/$total';
  }

  @override
  String documentsAnalyzedCount(int count) {
    return 'Analyzed $count documents';
  }

  @override
  String get noCameraAvailableError => 'No camera is available.';

  @override
  String get cameraStartError => 'Couldn\'t start the camera.';

  @override
  String get flashUnavailableError => 'Flash isn\'t available on this device.';

  @override
  String get flashOffLabel => 'Flash off';

  @override
  String get flashOnLabel => 'Flash on';

  @override
  String get flashAutoLabel => 'Flash auto';

  @override
  String get captureFailedError => 'The photo failed. Please try again.';

  @override
  String get cameraPreparingMessage => 'Preparing the camera';

  @override
  String get documentFrameGuideMessage => 'Fit the document within the frame';

  @override
  String get captureButtonLabel => 'Take photo';

  @override
  String get closeCameraButtonLabel => 'Close';

  @override
  String get noGuardianConnectedError =>
      'You don\'t have a connected guardian yet.';

  @override
  String get emergencyHelpTitle => 'Do you need help?';

  @override
  String get emergency119Label => '119 Report (Fire & Rescue)';

  @override
  String get emergency112Label => '112 Report (Police)';

  @override
  String get govComplaintLabel => '110 Consult (Government Complaints)';

  @override
  String get dasanCallCenterLabel => '120 Consult (Dasan Call Center)';

  @override
  String get cancelButton => 'Cancel';

  @override
  String get myRecordsTitle => 'My Records';

  @override
  String get analysisRecordsTabLabel => 'Analysis Records';

  @override
  String get scheduleTabLabel => 'Schedule';

  @override
  String get documentReadLabel => 'Read Document';

  @override
  String get documentReadSubtitle => 'We\'ll read documents from a photo';

  @override
  String get messageCheckLabel => 'Check Message';

  @override
  String get messageCheckSubtitle =>
      'We\'ll read messages and explain them simply';

  @override
  String get recentMessagesIntro =>
      'We\'ve pulled in your recent messages.\nTap the one you\'d like to check.';

  @override
  String get infoTabTitle => 'Info';

  @override
  String get enterMyInfoButton => 'Enter my info';

  @override
  String get benefitLoadErrorMessage =>
      'We couldn\'t load personalized benefit info.';

  @override
  String get benefitNoResultsMessage =>
      'We couldn\'t find benefit info matching your current conditions.';

  @override
  String get infoTabEmptyMessage =>
      'There\'s no information ready yet. We\'ll show you personalized info soon.';

  @override
  String get statisticsLabel => 'Statistics';

  @override
  String get usefulInfoLabel => 'Helpful Information';

  @override
  String get howToUseLabel => 'How to Use';

  @override
  String get supportTitle => 'Customer Support';

  @override
  String get localGovOfficeContactHeader => 'Local Office Contact';

  @override
  String get localGovOfficeEmptyRegionMessage =>
      'Register your region first to see your local welfare office\'s contact info.';

  @override
  String get localGovOfficeLoadError =>
      'We couldn\'t load your local welfare office info.';

  @override
  String get localGovOfficeNotFoundMessage =>
      'We couldn\'t find welfare office info for your region.';

  @override
  String get phoneNumberUnavailableMessage => 'No phone number available yet.';

  @override
  String get moreTitle => 'More';

  @override
  String get recordsLoadingMessage => 'Loading your records';

  @override
  String get recordsLoadError =>
      'Something went wrong while loading your records.';

  @override
  String get recordsEmptyMessage =>
      'You don\'t have any analyzed records yet.\nTry scanning a document or checking a message.';

  @override
  String get helpRequestLabel => 'Request Help';

  @override
  String get easyModeOnState => 'On';

  @override
  String get easyModeOffState => 'Off';

  @override
  String easyModeToggleSemanticLabel(String state) {
    return 'Easy Mode, currently $state';
  }

  @override
  String get easyModeDescription => 'Switch to bigger, simpler screens';

  @override
  String get recentRecordsTitle => 'Recent Records';

  @override
  String get todayScheduleTitle => 'Today\'s Schedule';

  @override
  String get scheduleAddTitle => 'Add Schedule';

  @override
  String get scheduleTitleFieldLabel => 'Title';

  @override
  String get scheduleTitleHint => 'e.g. Take blood pressure medicine';

  @override
  String get dateLabel => 'Date';

  @override
  String get selectedDateLabel => 'Selected date';

  @override
  String get timeLabel => 'Time';

  @override
  String get selectedTimeLabel => 'Selected time';

  @override
  String get scheduleRecurringLabel => 'Repeat daily';

  @override
  String get scheduleRecurringDesc =>
      'Repeats at the same time every day, like taking medicine.';

  @override
  String get scheduleLoadErrorMessage => 'We couldn\'t load your schedule.';

  @override
  String get scheduleEmptyMessage => 'No schedules yet.';

  @override
  String get scheduleDeleteTitle => 'Delete Schedule';

  @override
  String scheduleDeleteConfirmMessage(String title) {
    return 'Delete \"$title\"?';
  }

  @override
  String get deleteButton => 'Delete';

  @override
  String get emergencyHelpRequestLabel => 'Emergency Help (SOS)';

  @override
  String get emergencyHelpRequestSubtitle => 'Get help quickly in an emergency';

  @override
  String homeGreetingWithName(String name) {
    return 'Hello, $name!';
  }

  @override
  String get homeGreetingSubtitle => 'Have a safe and comfortable day';

  @override
  String get easyHomeHeadline => 'What can we help you with?';

  @override
  String infoGreetingWithName(String name) {
    return 'Personalized info for $name';
  }

  @override
  String get recordsFilterAllLabel => 'All';

  @override
  String get recordsFilterEmptyMessage =>
      'No records match this filter.\nTry a different filter.';

  @override
  String get moreAccountSectionTitle => 'Account';

  @override
  String get moreUsageInfoSectionTitle => 'Usage Info';

  @override
  String get smsPermissionCheckError => 'Couldn\'t check message permission.';

  @override
  String get smsPermissionRequestMessage =>
      'To check your messages and warn you about dangerous ones,\nplease allow message access.';

  @override
  String get smsPermissionRequestButton => 'Allow message permission';

  @override
  String get smsPermissionBlockedMessage =>
      'Message permission is blocked.\nPlease allow it directly in device settings.';

  @override
  String get analysisGenericError => 'Something went wrong during analysis.';

  @override
  String get unknownSenderLabel => 'Unknown number';

  @override
  String get manualMessageInputPrompt =>
      'Copy and paste a suspicious message,\nor type it in yourself.';

  @override
  String get pasteFromClipboardButton => 'Paste from clipboard';

  @override
  String get messageContentLabel => 'Message content';

  @override
  String get messageContentHint => 'Enter the message content';

  @override
  String get recentSmsLoadingMessage => 'Loading recent messages';

  @override
  String get smsLoadError => 'Couldn\'t load messages.';

  @override
  String get recentSmsEmptyMessage => 'You don\'t have any recent messages.';

  @override
  String get accessibilitySettingsTitle => 'Accessibility Settings';

  @override
  String get guardianRegisterTitle => 'Register Guardian';

  @override
  String get onboardingAccessibilityHeadline => 'Just a few settings';

  @override
  String get onboardingAccessibilityIntro =>
      'Let\'s set things up first so it\'s comfortable to use.';

  @override
  String get nextButton => 'Next';

  @override
  String get previousButton => 'Previous';

  @override
  String get confirmButton => 'Confirm';

  @override
  String get howToUseTitle => 'How to Use';

  @override
  String get howToUseDocumentTitle => 'Check for scams by reading documents';

  @override
  String get howToUseDocumentDesc =>
      'Take a photo of a bill or contract and AI will check it for anything risky.';

  @override
  String get howToUseMessageTitle => 'Check a text message';

  @override
  String get howToUseMessageDesc =>
      'Got a suspicious text? Just paste it in — we\'ll tell you right away if it\'s a scam.';

  @override
  String get howToUseVoiceTitle => 'Ask by voice';

  @override
  String get howToUseVoiceDesc =>
      'Tap the mic button at the bottom of the screen and say what you need — we\'ll take you there.';

  @override
  String get howToUseEmergencyTitle => 'Request emergency help';

  @override
  String get howToUseEmergencyDesc =>
      'In an emergency, tap the emergency help button to notify your guardian right away.';

  @override
  String get howToUseBenefitTitle => 'Check personalized info';

  @override
  String get howToUseBenefitDesc =>
      'Check benefit info matched to your age and region in the Info tab.';

  @override
  String get howToUseFacilityTitle => 'Find public facilities';

  @override
  String get howToUseFacilityDesc =>
      'We\'ll find the location and contact info of nearby senior centers or welfare offices.';

  @override
  String get howToUseRecordsTitle => 'Check your records';

  @override
  String get howToUseRecordsDesc =>
      'See all the documents and texts you\'ve checked so far in the Records tab.';

  @override
  String get onboardingProfileIntro =>
      'If you tell us, we can show you more helpful information. (Optional)';

  @override
  String get regionLabel => 'Region';

  @override
  String get skipButton => 'Skip';

  @override
  String get profileNextButton => 'Continue to guardian registration';

  @override
  String get onboardingCompleteTitle => 'All set!';

  @override
  String get onboardingCompleteSubtitle => 'You\'re ready to start using Ondam';

  @override
  String get textSizeTitle => 'Text Size';

  @override
  String get textScaleNormalLabel => 'Normal';

  @override
  String get textScaleLargeLabel => 'Large';

  @override
  String get textScaleExtraLargeLabel => 'Extra Large';

  @override
  String get textScaleNormalDesc => 'The most commonly chosen size.';

  @override
  String get textScaleLargeDesc => 'You can see it larger.';

  @override
  String get textScaleExtraLargeDesc => 'Shows it as large as possible.';

  @override
  String get voiceGuideTitle => 'Voice Guide';

  @override
  String get voiceGuideDescription =>
      'We\'ll also read the screen content aloud';

  @override
  String get voiceRateTitle => 'Voice guide speed';

  @override
  String get voiceRateNormalLabel => '1x';

  @override
  String get voiceRateFastLabel => '1.2x';

  @override
  String get voiceRateFasterLabel => '1.5x';

  @override
  String get voiceRateFastestLabel => '2x';

  @override
  String get homeVoiceGuideEasy =>
      'This is the home screen. Choose from Read Document, Check Message, Find a Senior Center, or My Records.';

  @override
  String get homeVoiceGuideNormal =>
      'This is the home screen. Choose from Read Document, Check Message, Find a Senior Center, or Emergency Help Request.';

  @override
  String get easyResultVoiceGuidePrefix => 'Here\'s your analysis result.';

  @override
  String get voiceGuideEnabledAnnouncement => 'Voice guide is now on.';

  @override
  String voiceGuideDefaultScreenText(String title) {
    return 'This is the $title screen.';
  }

  @override
  String get feeStatisticsTitle => 'Fee Statistics';

  @override
  String get feeStatisticsLoadingMessage => 'Loading fee statistics';

  @override
  String get feeStatisticsLoadError =>
      'Something went wrong while loading fee statistics.';

  @override
  String get privacyPinTitle => 'Password (PIN)';

  @override
  String get privacyPinBody =>
      'Your actual PIN, or anything that could be used to guess it, is never stored anywhere on this device. Even on the server, only an encrypted value is kept for verification only — there\'s no way for anyone else to see it.';

  @override
  String get privacyPhotoTitle => 'Document Photos';

  @override
  String get privacyPhotoBody =>
      'When you photograph a document for analysis, the original photo is deleted from the server as soon as the analysis finishes (whether it succeeds or fails). Only the analysis result remains.';

  @override
  String get privacySharedInfoTitle => 'Information Shared with Guardians';

  @override
  String get privacySharedInfoBody =>
      'Only guardians whose connection you\'ve accepted can see your analysis results. Once you disconnect, they can no longer see them.';

  @override
  String get privacyRetentionTitle => 'Retention Period for Analysis Records';

  @override
  String get privacyRetentionBody =>
      'How long the summary and original text from message/document analysis will be kept hasn\'t been decided yet. We\'ll let you know here as soon as it\'s determined.';

  @override
  String get privacyInfoTitle => 'Privacy & Data Retention';

  @override
  String get supportContactTitle => 'Support Contact';

  @override
  String get supportContactComingSoon =>
      'We\'re preparing phone and email contact information. We\'ll let you know soon.';

  @override
  String get privacyInfoDescription => 'See how your information is kept';

  @override
  String get micPermissionCheckError =>
      'Couldn\'t check microphone permission.';

  @override
  String get micPermissionRequestMessage =>
      'To use the voice assistant,\nplease allow microphone access.';

  @override
  String get micPermissionRequestButton => 'Allow microphone permission';

  @override
  String get micPermissionBlockedMessage =>
      'Microphone permission is blocked.\nPlease allow it directly in device settings.';

  @override
  String get actionChecklistTitle => 'To-Do';

  @override
  String get clarifyingQuestionsTitle => 'Have a question?';

  @override
  String get askByVoiceButton => 'Ask by voice';

  @override
  String get dateKindPaymentDue => 'Payment Due';

  @override
  String get dateKindVisit => 'Visit Date';

  @override
  String get dateKindApplicationPeriod => 'Application Period';

  @override
  String get dateKindExpiration => 'Expiration Date';

  @override
  String get dateKindReservation => 'Reservation Date';

  @override
  String get dateKindOther => 'Other Important Date';

  @override
  String get importantDatesTitle => 'Important Dates';

  @override
  String monthDayFormat(int month, int day) {
    return '$month/$day';
  }

  @override
  String get keyPointsTitle => 'Key Points';

  @override
  String analysisProgressSemanticLabel(int percent, String label) {
    return 'Analysis progress $percent percent, $label';
  }

  @override
  String get progressPreparing => 'Preparing analysis';

  @override
  String get progressSending => 'Sending your data';

  @override
  String get progressAnalyzing => 'AI is checking it';

  @override
  String get progressFinishing => 'Finishing up the results';

  @override
  String get detailsViewTitle => 'View Details';

  @override
  String get reliabilityLabel => 'Reliability';

  @override
  String get sourceTextLabel => 'Original Text';

  @override
  String get structuredFieldRiskTypeLabel => 'Risk type';

  @override
  String get riskTypeVoicePhishingLure => 'Voice phishing lure';

  @override
  String get riskTypeSmishing => 'Smishing (text scam)';

  @override
  String get riskTypeLoanScam => 'Loan scam';

  @override
  String get riskTypeImpersonationAuthority => 'Authority impersonation';

  @override
  String get riskTypeDeliveryScam => 'Delivery scam';

  @override
  String get riskTypeInvestmentScam => 'Investment scam';

  @override
  String get riskTypeRomanceScam => 'Romance scam';

  @override
  String get riskTypeOtherScam => 'Other scam';

  @override
  String get riskTypeNone => 'None';

  @override
  String get easyResultAiSummaryLabel => 'AI Summary';

  @override
  String get easyResultTypeLabel => 'Type';

  @override
  String get easyResultReplayLabel => 'Listen again';

  @override
  String get askAboutThisButton => 'Ask about this';

  @override
  String get confirmedDoneSemanticLabel => 'Marked as confirmed';

  @override
  String get confirmedDoneMessage => 'Confirmed';

  @override
  String get confirmDoneButton => 'Mark as Confirmed';

  @override
  String get featureComingSoonMessage => 'This feature isn\'t ready yet.';

  @override
  String get feeStatisticsEmptyMessage =>
      'No fee statistics yet.\nAnalyze a bill or invoice to build your statistics.';

  @override
  String get totalFeeLabel => 'Total fee';

  @override
  String get averageFeeLabel => 'Average fee';

  @override
  String get maxFeeLabel => 'Highest fee';

  @override
  String get feeRecordCountLabel => 'Bill records';

  @override
  String get monthlyToggleLabel => 'Monthly';

  @override
  String get yearlyToggleLabel => 'Yearly';

  @override
  String toggleViewSemanticLabel(String label) {
    return 'View $label';
  }

  @override
  String get monthlyTrendTitle => 'Monthly fee trend';

  @override
  String get yearlyTrendTitle => 'Yearly fee trend';

  @override
  String get noDataInPeriodMessage => 'No fee records for this period.';

  @override
  String get feeFootnote =>
      'Calculated from the amounts on analyzed bills and invoices. Records where AI couldn\'t extract an amount are excluded.';

  @override
  String get feeChartEmptyMessage => 'No fee statistics yet.';

  @override
  String get feeChartSemanticNoData => 'Fee trend chart. No data yet.';

  @override
  String feeChartSemanticSummary(String summary) {
    return 'Fee trend chart. $summary';
  }

  @override
  String monthNumberLabel(int month) {
    return '$month';
  }

  @override
  String yearNumberLabel(int year) {
    return '$year';
  }

  @override
  String feeHeroTitle(int month) {
    return 'Month $month fees';
  }

  @override
  String feeHeroLessThanLastMonth(String amount) {
    return '$amount less than last month';
  }

  @override
  String feeHeroMoreThanLastMonth(String amount) {
    return '$amount more than last month';
  }

  @override
  String get feeHeroSameAsLastMonth => 'Same as last month';

  @override
  String get recentBillsTitle => 'Recent bills';

  @override
  String countUnitLabel(int count) {
    return '$count';
  }

  @override
  String get notifSettingsTitle => 'Notification settings';

  @override
  String get dangerAlertLabel => 'Danger alerts';

  @override
  String get alwaysOnCaption => 'Always on';

  @override
  String get guardianNotifyLabel => 'Notify guardian';

  @override
  String get messageGuardianNoticeTitle => 'Your guardian has been notified';

  @override
  String get messageGuardianNoticeBody =>
      'We shared this message with your guardian';

  @override
  String get goHomeButton => 'Go home';

  @override
  String get pinDigitsInvalidMessage => 'Please enter a 4-digit PIN.';

  @override
  String get pinLockedRetryMessage =>
      'Too many attempts. Please try again later.';

  @override
  String get ageInvalidMessage => 'Please enter a valid age.';

  @override
  String get ageGenderRequiredMessage =>
      'Please enter your age and gender first.';

  @override
  String get regionRecheckMessage => 'Please check your region info again.';

  @override
  String get regionRequiredMessage => 'Please register your region first.';

  @override
  String get benefitNoLongerAvailableMessage =>
      'This benefit info is no longer available.';

  @override
  String get loginRequiredMessage => 'You need to log in.';

  @override
  String get messageContentRecheckMessage =>
      'Please check the message content again.';

  @override
  String get recurrenceTimeInvalidMessage => 'The repeat time isn\'t valid.';

  @override
  String get recurrenceTimeRequiredMessage => 'Please select a repeat time.';

  @override
  String get photoRecheckMessage => 'Please check the photo again.';

  @override
  String get genderRequiredMessage => 'Please select a gender.';

  @override
  String get requestInfoRecheckMessage =>
      'Please check the request info again.';

  @override
  String get locationPermissionRequiredMessage =>
      'Please allow location access.';

  @override
  String get locationServiceOffMessage =>
      'Location services are off. Please turn them on in settings.';

  @override
  String get smsAutoCheckUnsupportedMessage =>
      'This device doesn\'t support automatic text checking.';

  @override
  String get nameRequiredMessage => 'Please enter your name.';

  @override
  String get scheduleTitleRequiredMessage => 'Please enter a schedule title.';

  @override
  String get invalidBenefitInfoMessage => 'This is invalid benefit info.';

  @override
  String get phoneNumberMissingMessage => 'No phone number available.';

  @override
  String get regionAllFieldsRequiredMessage =>
      'Please fill in all region fields.';

  @override
  String get recentMessagesLoadErrorMessage =>
      'We couldn\'t load your recent messages.';

  @override
  String get reverseGeocodeFailedMessage =>
      'We couldn\'t turn your location into a region name.';

  @override
  String get locationCheckFailedRetryMessage =>
      'We couldn\'t check your current location. Please try again.';

  @override
  String get phoneNumberRecheckMessage =>
      'Please check your phone number again.';

  @override
  String get networkFailureDefaultMessage =>
      'Please check your network connection.';

  @override
  String get authFailureDefaultMessage => 'You need to log in.';

  @override
  String get serverFailureDefaultMessage => 'A server error occurred.';

  @override
  String get unknownFailureDefaultMessage => 'An unknown error occurred.';

  @override
  String get locationUnavailableDefaultMessage =>
      'We couldn\'t determine your current location.';

  @override
  String get welfareCenterUnavailableMessage =>
      'We don\'t offer senior center info yet.';

  @override
  String get localGovOfficeUnavailableMessage =>
      'We don\'t offer local welfare office contact info yet.';

  @override
  String get benefitServiceUnavailableMessage =>
      'We don\'t offer personalized benefit info yet.';

  @override
  String get analysisServerNotReadyMessage =>
      'The analysis server isn\'t ready yet. Please wait a moment.';

  @override
  String get pinAlreadySetMessage =>
      'A PIN is already set. If you forgot it, use PIN reset.';
}
