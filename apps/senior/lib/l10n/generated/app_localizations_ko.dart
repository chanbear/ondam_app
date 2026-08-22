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
  String get callButtonTooltip => '전화 걸기';

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
}
