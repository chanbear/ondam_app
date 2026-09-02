import 'package:flutter/widgets.dart';

import '../../l10n/generated/app_localizations.dart';

/// domain/data 계층(usecase/repository/datasource)은 Flutter나 l10n에
/// 의존할 수 없어(architecture.md) `Failure.message`가 항상 한국어
/// 문자열로 고정돼 있다 — 언어를 바꿔도 이 메시지들만 안 바뀌던 문제를
/// 고치기 위한 표시 계층 헬퍼다(사용자 요청).
///
/// domain/data의 메시지 문자열 자체를 식별자처럼 사용한다 — 그 문자열이
/// 곧 이 맵의 key다. 매핑에 없는(새로 추가됐거나 오타로 어긋난) 메시지는
/// 조용히 원문(한국어) 그대로 보여준다 — 없는 메시지 때문에 화면이 깨지면
/// 안 된다.
String localizeFailureMessage(BuildContext context, String message) {
  final l10n = AppLocalizations.of(context);
  if (l10n == null) return message;
  return localizeFailureMessageWith(l10n, message);
}

/// [localizeFailureMessage]와 같은 일이지만, `context` 대신 이미 갖고 있는
/// [AppLocalizations]를 바로 쓴다 — `BuildContext`를 받지 않는 헬퍼
/// 메서드(예: 위젯의 순수 계산 함수)에서 쓴다.
String localizeFailureMessageWith(AppLocalizations l10n, String message) {
  return _messageBuilders[message]?.call(l10n) ?? message;
}

final Map<String, String Function(AppLocalizations)> _messageBuilders = {
  'PIN은 4자리 숫자로 입력해주세요.': (l10n) => l10n.pinDigitsInvalidMessage,
  'PIN이 잠겨 있습니다. 잠시 후 다시 시도해주세요.': (l10n) => l10n.pinLockedRetryMessage,
  '나이를 올바르게 입력해주세요.': (l10n) => l10n.ageInvalidMessage,
  '나이와 성별을 먼저 입력해주세요.': (l10n) => l10n.ageGenderRequiredMessage,
  '내 지역 정보를 다시 확인해주세요.': (l10n) => l10n.regionRecheckMessage,
  '내 지역을 먼저 등록해주세요.': (l10n) => l10n.regionRequiredMessage,
  '더 이상 제공되지 않는 혜택 정보예요.': (l10n) => l10n.benefitNoLongerAvailableMessage,
  '로그인이 필요해요.': (l10n) => l10n.loginRequiredMessage,
  '문자 내용을 다시 확인해주세요.': (l10n) => l10n.messageContentRecheckMessage,
  '반복 시각이 올바르지 않아요.': (l10n) => l10n.recurrenceTimeInvalidMessage,
  '반복할 시각을 선택해주세요.': (l10n) => l10n.recurrenceTimeRequiredMessage,
  '사진을 다시 확인해주세요.': (l10n) => l10n.photoRecheckMessage,
  '성별을 선택해주세요.': (l10n) => l10n.genderRequiredMessage,
  '요청 정보를 다시 확인해주세요.': (l10n) => l10n.requestInfoRecheckMessage,
  '위치 권한을 허용해주세요.': (l10n) => l10n.locationPermissionRequiredMessage,
  '위치 서비스가 꺼져 있어요. 설정에서 켜주세요.': (l10n) => l10n.locationServiceOffMessage,
  '이 기기에서는 문자 자동 확인을 지원하지 않아요.': (l10n) => l10n.smsAutoCheckUnsupportedMessage,
  '이름을 입력해주세요.': (l10n) => l10n.nameRequiredMessage,
  '일정 제목을 입력해주세요.': (l10n) => l10n.scheduleTitleRequiredMessage,
  '잘못된 혜택 정보예요.': (l10n) => l10n.invalidBenefitInfoMessage,
  '전화 앱을 열 수 없어요.': (l10n) => l10n.phoneLaunchError,
  '전화번호가 없어요.': (l10n) => l10n.phoneNumberMissingMessage,
  '지역을 모두 입력해주세요.': (l10n) => l10n.regionAllFieldsRequiredMessage,
  '최근 문자를 불러오지 못했어요.': (l10n) => l10n.recentMessagesLoadErrorMessage,
  '현재 위치를 지역명으로 바꾸지 못했어요.': (l10n) => l10n.reverseGeocodeFailedMessage,
  '현재 위치를 확인하지 못했어요. 다시 시도해주세요.': (l10n) =>
      l10n.locationCheckFailedRetryMessage,
  '휴대폰 번호를 다시 확인해주세요.': (l10n) => l10n.phoneNumberRecheckMessage,
  // packages/core Failure 기본 메시지(생성자 인자 없이 쓴 경우).
  '네트워크 연결을 확인해주세요.': (l10n) => l10n.networkFailureDefaultMessage,
  '로그인이 필요합니다.': (l10n) => l10n.authFailureDefaultMessage,
  '서버에 문제가 발생했습니다.': (l10n) => l10n.serverFailureDefaultMessage,
  '알 수 없는 오류가 발생했습니다.': (l10n) => l10n.unknownFailureDefaultMessage,
  '이 기능은 아직 준비 중이에요.': (l10n) => l10n.featureComingSoonMessage,
  '현재 위치를 확인할 수 없어요.': (l10n) => l10n.locationUnavailableDefaultMessage,
  '경로당 정보를 아직 제공하지 않아요.': (l10n) => l10n.welfareCenterUnavailableMessage,
  '관할 행정복지센터 연락처를 아직 제공하지 않아요.': (l10n) =>
      l10n.localGovOfficeUnavailableMessage,
  '맞춤 혜택 정보를 아직 제공하지 않아요.': (l10n) => l10n.benefitServiceUnavailableMessage,
  '분석 서버가 아직 준비되지 않았어요. 조금만 기다려주세요.': (l10n) =>
      l10n.analysisServerNotReadyMessage,
  '이미 PIN이 설정되어 있어요. PIN을 잊으셨다면 PIN 재설정을 이용해주세요.': (l10n) =>
      l10n.pinAlreadySetMessage,
};
