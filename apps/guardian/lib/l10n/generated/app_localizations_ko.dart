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
  String get phoneStartSubtitle => '이름과 휴대폰 번호를 입력해주세요.';

  @override
  String get nameLabel => '이름';

  @override
  String get phoneNumberLabel => '휴대폰 번호';

  @override
  String get phoneNumberHint => '010-0000-0000';

  @override
  String get startButton => '시작하기';

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
}
