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
  String get navHome => '홈';

  @override
  String get navNotification => '알림';

  @override
  String get navRecords => '기록';

  @override
  String get navStatistics => '통계';

  @override
  String get navMore => '더보기';

  @override
  String get noConnectedEldersMessage => '아직 연결된 어르신이 없습니다.';

  @override
  String get connectElderAction => '어르신 연결하기';

  @override
  String get recentActivityTitle => '최근 활동';

  @override
  String get upcomingScheduleTitle => '다가오는 일정';

  @override
  String get noUpcomingSchedule => '예정된 일정이 없어요.';

  @override
  String get reassuranceLoadError => '안심 상태를 불러오지 못했어요.';

  @override
  String get dangerousAlertTitle => '확인이 필요한 활동이 있어요';

  @override
  String get alertCheckRecordsDescription => '기록 탭에서 자세한 내용을 확인해주세요.';

  @override
  String get cautionAlertTitle => '주의가 필요한 활동이 있어요';

  @override
  String get safeStatusMessage => '오늘도 평안하세요.';

  @override
  String get safeStatusDescription => '아직 특별한 알림이 없어요.';

  @override
  String get recentActivityLoadError => '최근 활동을 불러오지 못했어요.';

  @override
  String get noActivityRecords => '아직 활동 기록이 없어요.';

  @override
  String get recentNotificationsTitle => '최근 알림';

  @override
  String get viewAllAction => '전체보기';

  @override
  String get noRecentNotifications => '아직 받은 알림이 없습니다.';

  @override
  String get recentNotificationsLoadError => '알림을 불러오지 못했어요.';

  @override
  String get notificationUnreadLabel => '새 알림';

  @override
  String get notificationReadLabel => '확인함';

  @override
  String get documentDetailTitle => '문서 분석 상세';

  @override
  String get messageDetailTitle => '문자 확인 상세';

  @override
  String get detailsToggleTitle => '상세정보 보기';

  @override
  String get reliabilityLabel => '신뢰도';

  @override
  String get sourceTextLabel => '원문';

  @override
  String get confirmButtonLabel => '확인 완료';

  @override
  String get confirmedBannerLabel => '확인 완료했어요';

  @override
  String get realtimeAlertsTitle => '실시간 알림';

  @override
  String get riskRecordsTitle => '위험 기록';

  @override
  String get riskRecordsLoadError => '기록을 불러오지 못했어요.';

  @override
  String get noRiskRecords => '아직 위험 기록이 없습니다.';

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
  String get connectAnotherElderAction => '다른 어르신 연결';

  @override
  String get supportTitle => '고객 지원';

  @override
  String get pinForgotTitle => 'PIN 재설정';

  @override
  String get pinForgotReauthFailedTitle => '본인 확인에 실패했어요';

  @override
  String get retryButtonLabel => '다시 시도';

  @override
  String get pinForgotNewPinTitle => '새로운 PIN 4자리를 정해주세요';

  @override
  String get pinKeypadClearLabel => '지우기';

  @override
  String get recordsLoadError => '분석 기록을 불러오지 못했어요.';

  @override
  String get recordsEmptyMessage => '아직 분석 기록이 없습니다.';

  @override
  String get statisticsLoadError => '통계를 불러오지 못했어요.';

  @override
  String get statisticsEmptyMessage => '아직 통계로 보여드릴 데이터가 없습니다.';

  @override
  String get thisMonthCountLabel => '이번 달 분석 건수';

  @override
  String get riskyThisMonthCountLabel => '위험 문자 건수';

  @override
  String countUnitLabel(int count) {
    return '$count건';
  }

  @override
  String get feeStatisticsSectionTitle => '요금 통계';

  @override
  String get billingInfoSectionTitle => '고지서 정보';

  @override
  String get billingInfoUndecidedNotice =>
      '고지서 통계 항목은 아직 결정되지 않았어요. 기록에 담긴 원본 정보만 보여드려요.';

  @override
  String get billingInfoEmptyMessage => '아직 고지서 정보가 없습니다.';

  @override
  String get trendSameAsLastMonth => '지난달과 동일해요';

  @override
  String trendIncreasedLabel(int count) {
    return '지난달보다 $count건 늘었어요';
  }

  @override
  String trendDecreasedLabel(int count) {
    return '지난달보다 $count건 줄었어요';
  }

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
  String get structuredFieldRiskTypeLabel => '위험 유형';

  @override
  String get riskTypeVoicePhishingLure => '보이스피싱 유도';

  @override
  String get riskTypeSmishing => '스미싱(문자 사기)';

  @override
  String get riskTypeLoanScam => '대출 사기';

  @override
  String get riskTypeImpersonationAuthority => '기관 사칭';

  @override
  String get riskTypeDeliveryScam => '배송 사기';

  @override
  String get riskTypeInvestmentScam => '투자 사기';

  @override
  String get riskTypeRomanceScam => '로맨스 스캠';

  @override
  String get riskTypeOtherScam => '기타 사기';

  @override
  String get riskTypeNone => '해당 없음';

  @override
  String get notificationTypeRiskyDocument => '문서에서 위험 신호가 감지됐어요';

  @override
  String get notificationTypeRiskyMessage => '문자에서 위험 신호가 감지됐어요';

  @override
  String get guardianConnectionManageTitle => '어르신 연결 관리';

  @override
  String get connectElderActionLong => '어르신 연결하기';

  @override
  String get connectionListLoadError => '연결 목록을 불러오지 못했어요.';

  @override
  String get connectionListEmptyMessage =>
      '아직 연결된 어르신이 없습니다\n어르신 연결하기로 QR을 스캔해주세요';

  @override
  String elderPlaceholderName(String id) {
    return '어르신 ($id)';
  }

  @override
  String get elderRevokeConfirmTitle => '연결을 해제할까요?';

  @override
  String get elderRevokeConfirmMessage => '해제하면 이 어르신의 정보를 더 이상 볼 수 없습니다.';

  @override
  String get elderRevokeConfirmLabel => '해제';

  @override
  String get elderRevokeAction => '연결 해제';

  @override
  String get elderLinkStatusPending => '어르신 수락 대기 중';

  @override
  String get elderLinkStatusAccepted => '연결됨';

  @override
  String get elderLinkStatusRejected => '거절됨';

  @override
  String get elderLinkStatusRevoked => '연결 해제됨';

  @override
  String get connectionRequestSendingMessage => '연결 요청을 보내고 있어요';

  @override
  String get qrScanInstructionMessage => '어르신 화면에 표시된 QR 코드를 비춰주세요';

  @override
  String get cameraPermissionRequiredMessage => '카메라 권한이 필요해요';

  @override
  String get openSettingsAction => '설정으로 이동';

  @override
  String get connectionRequestSentTitle => '연결 요청을 보냈어요';

  @override
  String get connectionRequestSentDescription => '어르신이 요청을 수락하면 연결이 완료돼요.';

  @override
  String get okButtonLabel => '확인';

  @override
  String get comingSoonMessage => '이 기능은 아직 준비 중이에요.';
}
