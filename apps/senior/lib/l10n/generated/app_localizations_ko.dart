// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => '온담';

  @override
  String get settingsTitle => '설정';

  @override
  String get settingsLanguage => '언어';

  @override
  String get easyModeSectionTitle => '쉬운 모드';

  @override
  String get easyModeTitle => '쉬운 모드';

  @override
  String get easyModeSubtitle => '큰 버튼과 단순한 화면으로 바꿔드려요';

  @override
  String get accountSectionTitle => '계정';

  @override
  String get logout => '로그아웃';

  @override
  String get deleteAccount => '회원 탈퇴';

  @override
  String get deleteAccountConfirmTitle => '정말 탈퇴하시겠어요?';

  @override
  String get deleteAccountConfirmMessage =>
      '탈퇴하면 계정과 함께 저장된 모든 정보가 즉시 삭제되고 되돌릴 수 없어요.';

  @override
  String get deleteAccountConfirmLabel => '탈퇴하기';

  @override
  String get phoneStartTitle => '휴대폰 번호로 시작하기';

  @override
  String get phoneStartSubtitle => '휴대폰 번호와 비밀번호를 입력해주세요.';

  @override
  String get phoneNumberLabel => '휴대폰 번호';

  @override
  String get phoneNumberHint => '010-0000-0000';

  @override
  String get pinLabel => '비밀번호';

  @override
  String get pinHint => '4자리 숫자';

  @override
  String get startButton => '시작하기';

  @override
  String get socialLoginDivider => '또는';

  @override
  String get googleLoginButton => '구글 로그인';

  @override
  String get naverLoginButton => '네이버 로그인';

  @override
  String get kakaoLoginButton => '카카오 로그인';

  @override
  String get guestSignInButton => '회원가입 없이 사용하기';

  @override
  String get socialLoginComingSoon => '준비 중인 기능이에요';

  @override
  String get oauthPinSetupTitle => 'PIN을 새로 설정해주세요';

  @override
  String get oauthPinSetupSubtitle => '다음부터는 이 PIN으로 로그인해요.';

  @override
  String get oauthPinEntryTitle => 'PIN을 입력해주세요';

  @override
  String get oauthPinEntrySubtitle => '설정하신 4자리 PIN을 입력해주세요.';

  @override
  String get forgotPinLink => '비밀번호를 잊으셨나요?';

  @override
  String pinWrongWithCount(int count) {
    return '비밀번호가 올바르지 않아요. ($count회 실패)';
  }

  @override
  String get pinWrong => '비밀번호가 올바르지 않아요.';

  @override
  String pinLockedWithTime(String time) {
    return '너무 여러 번 틀렸어요. $time에 다시 시도해주세요.';
  }

  @override
  String get pinLockedNoTime => '너무 여러 번 틀려서 잠시 잠겼어요. 잠시 후 다시 시도해주세요.';

  @override
  String get pinNotSet => '비밀번호가 설정되어 있지 않아요.';

  @override
  String get pinInvalidFormat => '비밀번호는 4자리 숫자예요.';

  @override
  String get pinUnknownError => '확인 중 문제가 발생했어요. 다시 시도해주세요.';

  @override
  String get voiceAssistantLabel => '음성 비서';

  @override
  String get navInfo => '정보';

  @override
  String get navHome => '홈';

  @override
  String get navRecords => '기록';

  @override
  String get navMore => '더보기';

  @override
  String get profileTitle => '내 정보';

  @override
  String get nameLabel => '이름';

  @override
  String get ageLabel => '나이';

  @override
  String get profileSaved => '프로필이 저장되었어요.';

  @override
  String get profileLoadError => '저장된 정보를 불러오지 못했어요.';

  @override
  String get myRegionTitle => '내 지역';

  @override
  String get regionLoadError => '지역 정보를 불러오지 못했어요.';

  @override
  String get currentRegionLabel => '현재 지역';

  @override
  String get regionNotSetValue => '아직 등록하지 않았어요';

  @override
  String get enterRegionAction => '내 지역 입력하기';

  @override
  String get saveButton => '저장';

  @override
  String get sidoLabel => '시/도';

  @override
  String get sidoPlaceholder => '눌러서 선택해주세요';

  @override
  String get sigunguLabel => '시/군/구';

  @override
  String get dongLabel => '읍/면/동';

  @override
  String get locatingButton => '현재 위치 확인 중이에요';

  @override
  String get useCurrentLocationButton => '현재 위치로 자동 입력';

  @override
  String get locationServiceDisabledError => '위치 서비스를 켜신 뒤 다시 시도해주세요.';

  @override
  String get locationPermissionDeniedError => '기기 설정에서 위치 권한을 허용한 뒤 다시 시도해주세요.';

  @override
  String get locationPermissionRequiredError => '위치 권한을 허용해야 현재 위치를 사용할 수 있어요.';

  @override
  String get sidoRequiredError => '시/도를 선택해주세요.';

  @override
  String get regionSaved => '내 지역이 저장되었어요.';

  @override
  String get sidoPickerTitle => '시/도 선택';

  @override
  String get welfareCenterTitle => '경로당 찾기';

  @override
  String get publicFacilitySearchLabel => '공공시설 찾기';

  @override
  String get publicFacilitySearchSubtitle => '주변 공공시설을 찾아보세요';

  @override
  String get welfareCenterRegionLoadError => '내 지역 정보를 불러오지 못했어요.';

  @override
  String get welfareCenterEmptyRegionMessage => '경로당을 찾으려면 먼저 내 지역을 등록해주세요.';

  @override
  String get searchNearbyButton => '내 주변 경로당 찾기';

  @override
  String get phoneLaunchError => '전화 앱을 열 수 없어요.';

  @override
  String get welfareCenterSearchError => '경로당 검색 중 문제가 발생했어요.';

  @override
  String get welfareCenterNoResults => '근처에서 경로당을 찾지 못했어요.';

  @override
  String welfareCenterResultsSummary(String region, int count) {
    return '$region 근처 경로당 $count곳';
  }

  @override
  String get callButtonTooltip => '전화 걸기';

  @override
  String get directionsButtonLabel => '길 찾기';

  @override
  String get voiceUnavailableError => '이 기기에서는 음성 인식을 사용할 수 없어요.';

  @override
  String get voiceInitError => '음성 비서를 시작하지 못했어요.';

  @override
  String get voicePreparing => '음성 비서를 준비하고 있어요';

  @override
  String get voiceProcessing => '요청하신 내용을 확인하고 있어요';

  @override
  String get voiceIdlePrompt => '마이크를 눌러 말씀해주세요';

  @override
  String get voiceListening => '듣고 있어요';

  @override
  String get voiceStartSemanticLabel => '말하기 시작';

  @override
  String get voiceUnrecognizedAnswer =>
      '무슨 말씀인지 잘 이해하지 못했어요. \"문서 찍어줘\", \"문자 확인해줘\", \"긴급 도움\"처럼 말씀해주세요.';

  @override
  String get voiceRetryButton => '다시 말씀해주세요';

  @override
  String get riskSafeLabel => '안전';

  @override
  String get riskCautionLabel => '주의';

  @override
  String get riskDangerousLabel => '위험 감지';

  @override
  String get analysisTypeDocumentLabel => '문서 분석';

  @override
  String get analysisTypeMessageLabel => '문자 확인';

  @override
  String get analysisResultTitle => '분석 결과';

  @override
  String get shareButton => '공유';

  @override
  String get pinEntryPrompt => 'PIN을 입력해주세요';

  @override
  String get pinForgotLink => 'PIN을 잊으셨나요?';

  @override
  String get pinResetTitle => 'PIN 재설정';

  @override
  String get identityVerifyFailedTitle => '본인 확인에 실패했어요';

  @override
  String get retryButton => '다시 시도';

  @override
  String get pinNewSetupPrompt => '새로운 PIN 4자리를 정해주세요';

  @override
  String get pinMismatchError => 'PIN이 일치하지 않아요. 처음부터 다시 입력해주세요.';

  @override
  String get pinConfirmPrompt => '한 번 더 입력해주세요';

  @override
  String get pinSetupPrompt => '사용하실 PIN 4자리를 정해주세요';

  @override
  String get pinSetupDescription => '다음부터 앱을 열 때 이 PIN으로 확인해요.';

  @override
  String get roleSelectTitle => '어떤 분으로 이용하실까요?';

  @override
  String get roleSelectSubtitle => '이용 목적에 맞게 화면을 준비해드릴게요.';

  @override
  String get roleAlreadyRegisteredNotice =>
      '이 번호는 이미 다른 역할로 등록되어 있어요. 계속 진행하면 이 역할도 함께 등록돼요.';

  @override
  String get roleElderButton => '저는 어르신이에요';

  @override
  String get roleGuardianButton => '저는 가족(보호자)이에요';

  @override
  String get pinKeypadClearLabel => '지우기';

  @override
  String get guardianConnectTitle => '보호자 연결';

  @override
  String get qrGeneratingMessage => 'QR 코드를 만들고 있어요';

  @override
  String get qrGenerateError => 'QR 코드를 만들지 못했어요. 다시 시도해주세요.';

  @override
  String get qrShowGuardianPrompt => '보호자에게 이 QR을 보여주세요';

  @override
  String get qrScanExplanation => '보호자가 이 QR을 스캔하면 연결 요청이 도착합니다.';

  @override
  String get qrExpiredMessage => 'QR이 만료되었어요.';

  @override
  String get qrRegenerateButton => 'QR 다시 만들기';

  @override
  String get guardianListTitle => '연결된 보호자 목록';

  @override
  String get guardianConnectButton => '보호자 연결하기';

  @override
  String get guardianListLoadError => '보호자 목록을 불러오지 못했어요.';

  @override
  String get guardianListEmptyMessage =>
      '아직 연결된 보호자가 없습니다\n보호자 연결하기로 QR을 보여주세요';

  @override
  String guardianRequestLabelWithId(String id) {
    return '보호자 연결 요청 ($id)';
  }

  @override
  String guardianConnectedLabelWithId(String id) {
    return '연결된 보호자 ($id)';
  }

  @override
  String guardianConnectedSince(String date) {
    return '연결됨 · $date';
  }

  @override
  String get acceptButton => '수락';

  @override
  String get rejectButton => '거절';

  @override
  String get guardianRevokeConfirmTitle => '연결을 해제할까요?';

  @override
  String get guardianRevokeConfirmMessage =>
      '해제하면 이 보호자는 더 이상 회원님의 정보를 볼 수 없습니다.';

  @override
  String get guardianRevokeConfirmLabel => '해제';

  @override
  String get guardianRevokeAction => '연결 해제';

  @override
  String get guardianStatusPending => '요청 대기 중';

  @override
  String get guardianStatusAccepted => '연결됨';

  @override
  String get guardianStatusRejected => '거절함';

  @override
  String get guardianStatusRevoked => '연결 해제됨';

  @override
  String get documentScanTitle => '문서 촬영';

  @override
  String get documentScanStartTitle => '문서 분석';

  @override
  String get documentScanStartTakePhotoButton => '사진 촬영하기';

  @override
  String get documentScanStartPickPhotoButton => '사진 불러오기';

  @override
  String get documentScanStartTipTitle => '꼭 확인해 주세요!';

  @override
  String get documentScanStartTipLine1 => '문서의 글자가 선명하게 보이도록 촬영해 주세요';

  @override
  String get documentScanStartTipLine2 => '빛 반사가 적은 밝은 곳에서 촬영하면 더 정확해요';

  @override
  String get photoLibraryUnavailableError => '사진을 불러올 수 없어요.';

  @override
  String get cameraPermissionCheckError => '카메라 권한을 확인하지 못했어요.';

  @override
  String get cameraPermissionRequestMessage =>
      '문서와 문자를 촬영해 분석하려면\n카메라 접근을 허용해주세요.';

  @override
  String get cameraPermissionRequestButton => '카메라 권한 허용하기';

  @override
  String get cameraPermissionBlockedMessage =>
      '카메라 권한이 차단되어 있어요.\n기기 설정에서 직접 허용해주셔야 해요.';

  @override
  String get openSettingsButton => '설정 열기';

  @override
  String get scanPreviewTitle => '촬영 결과 확인';

  @override
  String get retakeLabel => '재촬영';

  @override
  String scannedDocumentsCount(int count) {
    return '$count장 촬영했어요';
  }

  @override
  String photoCountBadge(int count) {
    return '$count장';
  }

  @override
  String get addAnotherPhotoButton => '추가 촬영';

  @override
  String get analyzeButton => '분석하기';

  @override
  String documentIndexLabel(int index) {
    return '문서 $index';
  }

  @override
  String deletePhotoAtIndexLabel(int index) {
    return '$index번째 사진 삭제';
  }

  @override
  String documentAnalyzingProgress(int current, int total) {
    return '$current/$total 문서 분석 중';
  }

  @override
  String documentsAnalyzedCount(int count) {
    return '문서 $count건을 분석했어요';
  }

  @override
  String get noCameraAvailableError => '사용 가능한 카메라가 없어요.';

  @override
  String get cameraStartError => '카메라를 시작하지 못했어요.';

  @override
  String get flashUnavailableError => '이 기기에서는 플래시를 사용할 수 없어요.';

  @override
  String get captureFailedError => '촬영에 실패했어요. 다시 시도해주세요.';

  @override
  String get cameraPreparingMessage => '카메라를 준비하고 있어요';

  @override
  String get documentFrameGuideMessage => '문서를 화면 안에 맞춰주세요';

  @override
  String get captureButtonLabel => '촬영하기';

  @override
  String get closeCameraButtonLabel => '닫기';

  @override
  String get noGuardianConnectedError => '아직 연결된 보호자가 없어요.';

  @override
  String get emergencyHelpTitle => '도움이 필요하신가요?';

  @override
  String get emergency119Label => '119 신고하기 (소방·구급)';

  @override
  String get emergency112Label => '112 신고하기 (경찰)';

  @override
  String get govComplaintLabel => '110 상담하기 (정부민원안내)';

  @override
  String get dasanCallCenterLabel => '120 상담하기 (다산콜센터)';

  @override
  String get cancelButton => '취소';

  @override
  String get myRecordsTitle => '내 기록';

  @override
  String get documentReadLabel => '문서 읽기';

  @override
  String get documentReadSubtitle => '사진으로 문서를 읽어드려요';

  @override
  String get messageCheckLabel => '문자 확인';

  @override
  String get messageCheckSubtitle => '문자를 읽어주고 쉽게 알려드려요';

  @override
  String get recentMessagesIntro => '최근 문자를 가져왔어요.\n확인하고 싶은 문자를 눌러주세요.';

  @override
  String get infoTabTitle => '정보';

  @override
  String get infoTabEmptyMessage => '아직 준비된 정보가 없어요. 곧 맞춤 정보를 보여드릴게요.';

  @override
  String get statisticsLabel => '통계';

  @override
  String get usefulInfoLabel => '알아두면 좋은 정보';

  @override
  String get howToUseLabel => '사용 방법 안내';

  @override
  String get supportTitle => '고객 지원';

  @override
  String get moreTitle => '더보기';

  @override
  String get recordsLoadingMessage => '기록을 불러오고 있어요';

  @override
  String get recordsLoadError => '기록을 불러오는 중 문제가 발생했어요.';

  @override
  String get recordsEmptyMessage => '아직 분석한 기록이 없습니다.\n문서 찍기나 문자 보기를 이용해보세요.';

  @override
  String get helpRequestLabel => '도움 요청';

  @override
  String get easyModeOnState => '켜짐';

  @override
  String get easyModeOffState => '꺼짐';

  @override
  String easyModeToggleSemanticLabel(String state) {
    return '쉬운 모드, 현재 $state';
  }

  @override
  String get easyModeDescription => '더 크고 단순한 화면으로 보기';

  @override
  String get recentRecordsTitle => '최근 기록';

  @override
  String get todayScheduleTitle => '오늘의 일정';

  @override
  String get emergencyHelpRequestLabel => '긴급 도움 (SOS)';

  @override
  String get emergencyHelpRequestSubtitle => '위급할 때 빠르게 도움을 요청해요';

  @override
  String homeGreetingWithName(String name) {
    return '$name님, 안녕하세요!';
  }

  @override
  String get homeGreetingSubtitle => '오늘도 편안하고 안전한 하루 되세요';

  @override
  String get easyHomeHeadline => '무엇을 도와드릴까요?';

  @override
  String infoGreetingWithName(String name) {
    return '$name님을 위한 맞춤 정보예요';
  }

  @override
  String get recordsFilterAllLabel => '전체';

  @override
  String get recordsFilterEmptyMessage => '해당하는 기록이 없어요.\n다른 필터를 선택해보세요.';

  @override
  String get moreAccountSectionTitle => '계정';

  @override
  String get moreUsageInfoSectionTitle => '이용 정보';

  @override
  String get smsPermissionCheckError => '문자 권한을 확인하지 못했어요.';

  @override
  String get smsPermissionRequestMessage =>
      '받은 문자를 확인해 위험한 문자인지 알려드리려면\n문자 접근을 허용해주세요.';

  @override
  String get smsPermissionRequestButton => '문자 권한 허용하기';

  @override
  String get smsPermissionBlockedMessage =>
      '문자 권한이 차단되어 있어요.\n기기 설정에서 직접 허용해주셔야 해요.';

  @override
  String get analysisGenericError => '분석 중 문제가 발생했어요.';

  @override
  String get unknownSenderLabel => '알 수 없는 번호';

  @override
  String get manualMessageInputPrompt => '의심스러운 문자를 복사해서 붙여넣거나\n직접 입력해주세요.';

  @override
  String get pasteFromClipboardButton => '클립보드에서 붙여넣기';

  @override
  String get messageContentLabel => '문자 내용';

  @override
  String get messageContentHint => '문자 내용을 입력해주세요';

  @override
  String get recentSmsLoadingMessage => '최근 문자를 불러오고 있어요';

  @override
  String get smsLoadError => '문자를 불러오지 못했어요.';

  @override
  String get recentSmsEmptyMessage => '최근 받은 문자가 없어요.';

  @override
  String get accessibilitySettingsTitle => '접근성 설정';

  @override
  String get guardianRegisterTitle => '보호자 등록';

  @override
  String get onboardingAccessibilityHeadline => '몇 가지만 정해주세요';

  @override
  String get onboardingAccessibilityIntro => '편하게 사용하실 수 있도록 먼저 설정할게요.';

  @override
  String get nextButton => '다음';

  @override
  String get onboardingProfileIntro => '알려주시면 더 도움이 되는 정보를 보여드릴 수 있어요. (선택 입력)';

  @override
  String get regionLabel => '지역';

  @override
  String get skipButton => '건너뛰기';

  @override
  String get guardianConnectComingSoonMessage =>
      '보호자 연결은 곧 제공될 예정이에요. 준비되면 더보기 메뉴에서 언제든 연결하실 수 있어요.';

  @override
  String get saveAndStartButton => '저장하고 시작하기';

  @override
  String get textSizeTitle => '글자 크기';

  @override
  String get voiceGuideTitle => '음성 안내';

  @override
  String get voiceGuideDescription => '화면 내용을 음성으로도 안내해드려요';

  @override
  String get voiceRateTitle => '음성 안내 속도';

  @override
  String get homeVoiceGuideEasy =>
      '홈 화면이에요. 문서 읽기, 문자 확인, 경로당 찾기, 내 기록 중에서 골라주세요.';

  @override
  String get homeVoiceGuideNormal =>
      '홈 화면이에요. 문서 읽기, 문자 확인, 경로당 찾기, 긴급 도움 요청 중에서 골라주세요.';

  @override
  String get easyResultVoiceGuidePrefix => '분석 결과를 알려드릴게요.';

  @override
  String get feeStatisticsTitle => '요금 통계';

  @override
  String get feeStatisticsLoadingMessage => '요금 통계를 불러오고 있어요';

  @override
  String get feeStatisticsLoadError => '요금 통계를 불러오는 중 문제가 발생했어요.';

  @override
  String get privacyPinTitle => '비밀번호(PIN)';

  @override
  String get privacyPinBody =>
      'PIN 원문이나 이를 유추할 수 있는 값은 이 기기 어디에도 저장하지 않아요. 서버에서도 암호화된 값만 검증 전용으로 보관하고, 다른 사람이 들여다볼 수 있는 경로가 없어요.';

  @override
  String get privacyPhotoTitle => '문서 촬영 사진';

  @override
  String get privacyPhotoBody =>
      '문서를 촬영해 분석을 요청하면, 분석이 끝나는 즉시(성공하든 실패하든) 원본 사진은 서버에서 삭제돼요. 분석 결과만 남아요.';

  @override
  String get privacySharedInfoTitle => '보호자와 공유되는 정보';

  @override
  String get privacySharedInfoBody =>
      '분석 결과는 내가 연결을 수락한 보호자만 볼 수 있어요. 연결을 해제하면 더 이상 볼 수 없어요.';

  @override
  String get privacyRetentionTitle => '분석 결과 원문 보관 기간';

  @override
  String get privacyRetentionBody =>
      '문자·문서 분석 결과에 남는 요약/원문을 얼마나 오래 보관할지는 아직 정해지지 않았어요. 정해지는 대로 이 화면에 안내할게요.';

  @override
  String get privacyInfoTitle => '개인정보 보관 안내';

  @override
  String get supportContactTitle => '고객센터 연락처';

  @override
  String get supportContactComingSoon => '전화·이메일 연락처를 준비하고 있어요. 곧 안내해드릴게요.';

  @override
  String get privacyInfoDescription => '내 정보가 어떻게 보관되는지 확인해요';

  @override
  String get micPermissionCheckError => '마이크 권한을 확인하지 못했어요.';

  @override
  String get micPermissionRequestMessage => '음성 비서를 사용하려면\n마이크 접근을 허용해주세요.';

  @override
  String get micPermissionRequestButton => '마이크 권한 허용하기';

  @override
  String get micPermissionBlockedMessage =>
      '마이크 권한이 차단되어 있어요.\n기기 설정에서 직접 허용해주셔야 해요.';

  @override
  String get actionChecklistTitle => '해야 할 일';

  @override
  String get clarifyingQuestionsTitle => '궁금한 점이 있나요?';

  @override
  String get askByVoiceButton => '음성으로 물어보기';

  @override
  String get dateKindPaymentDue => '납부 기한';

  @override
  String get dateKindVisit => '방문 날짜';

  @override
  String get dateKindApplicationPeriod => '신청 기간';

  @override
  String get dateKindExpiration => '만료일';

  @override
  String get dateKindReservation => '예약 날짜';

  @override
  String get dateKindOther => '기타 중요한 날짜';

  @override
  String get importantDatesTitle => '중요한 날짜';

  @override
  String monthDayFormat(int month, int day) {
    return '$month월 $day일';
  }

  @override
  String get keyPointsTitle => '주요 내용';

  @override
  String analysisProgressSemanticLabel(int percent, String label) {
    return '분석 진행률 $percent퍼센트, $label';
  }

  @override
  String get progressPreparing => '분석을 준비하고 있어요';

  @override
  String get progressSending => '자료를 보내고 있어요';

  @override
  String get progressAnalyzing => 'AI가 확인하고 있어요';

  @override
  String get progressFinishing => '결과를 정리하고 있어요';

  @override
  String get detailsViewTitle => '상세정보 보기';

  @override
  String get reliabilityLabel => '신뢰도';

  @override
  String get sourceTextLabel => '원문';

  @override
  String get easyResultAiSummaryLabel => 'AI 요약';

  @override
  String get easyResultTypeLabel => '종류';

  @override
  String get easyResultReplayLabel => '다시 듣기';

  @override
  String get askAboutThisButton => '이 내용 물어보기';

  @override
  String get confirmedDoneSemanticLabel => '확인 완료로 표시했어요';

  @override
  String get confirmedDoneMessage => '확인 완료했어요';

  @override
  String get confirmDoneButton => '확인 완료';

  @override
  String get featureComingSoonMessage => '이 기능은 아직 준비 중이에요.';

  @override
  String get feeStatisticsEmptyMessage =>
      '아직 요금 통계가 없습니다.\n고지서나 요금서를 분석하면 통계가 만들어집니다.';

  @override
  String get totalFeeLabel => '총 요금';

  @override
  String get averageFeeLabel => '평균 요금';

  @override
  String get maxFeeLabel => '최고 요금';

  @override
  String get feeRecordCountLabel => '요금 내역';

  @override
  String get monthlyToggleLabel => '월별';

  @override
  String get yearlyToggleLabel => '연별';

  @override
  String toggleViewSemanticLabel(String label) {
    return '$label 보기';
  }

  @override
  String get monthlyTrendTitle => '월별 요금 추이';

  @override
  String get yearlyTrendTitle => '연별 요금 추이';

  @override
  String get noDataInPeriodMessage => '이 기간에는 요금 기록이 없습니다.';

  @override
  String get feeFootnote =>
      '분석된 고지서/요금서의 금액을 기준으로 계산합니다. AI가 금액을 추출하지 못한 기록은 제외됩니다.';

  @override
  String get feeChartEmptyMessage => '아직 요금 통계가 없습니다.';

  @override
  String get feeChartSemanticNoData => '요금 추이 그래프. 아직 데이터가 없습니다.';

  @override
  String feeChartSemanticSummary(String summary) {
    return '요금 추이 그래프. $summary';
  }

  @override
  String monthNumberLabel(int month) {
    return '$month월';
  }

  @override
  String yearNumberLabel(int year) {
    return '$year년';
  }

  @override
  String feeHeroTitle(int month) {
    return '$month월 요금';
  }

  @override
  String feeHeroLessThanLastMonth(String amount) {
    return '지난달보다 $amount 적어요';
  }

  @override
  String feeHeroMoreThanLastMonth(String amount) {
    return '지난달보다 $amount 많아요';
  }

  @override
  String get feeHeroSameAsLastMonth => '지난달과 같아요';

  @override
  String get recentBillsTitle => '최근 고지서';

  @override
  String countUnitLabel(int count) {
    return '$count건';
  }

  @override
  String get notifSettingsTitle => '알림 설정';

  @override
  String get dangerAlertLabel => '위험 알림';

  @override
  String get alwaysOnCaption => '항상 켜짐';

  @override
  String get guardianNotifyLabel => '보호자 알림';

  @override
  String get messageGuardianNoticeTitle => '보호자에게 알렸어요';

  @override
  String get messageGuardianNoticeBody => '문자 내용을 전달했어요';

  @override
  String get goHomeButton => '홈으로';
}
