// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => '온담';

  @override
  String get settingsTitle => '设置';

  @override
  String get settingsLanguage => '语言';

  @override
  String get easyModeSectionTitle => '简易模式';

  @override
  String get easyModeTitle => '简易模式';

  @override
  String get easyModeSubtitle => '切换为更大的按钮和更简洁的界面';

  @override
  String get accountSectionTitle => '账户';

  @override
  String get logout => '退出登录';

  @override
  String get deleteAccount => '注销账户';

  @override
  String get deleteAccountConfirmTitle => '确定要注销账户吗？';

  @override
  String get deleteAccountConfirmMessage => '注销后，账户及保存的所有信息将立即删除，且无法恢复。';

  @override
  String get deleteAccountConfirmLabel => '注销';

  @override
  String get phoneStartTitle => '使用手机号码开始';

  @override
  String get phoneStartSubtitle => '请输入手机号码和密码。';

  @override
  String get phoneNumberLabel => '手机号码';

  @override
  String get phoneNumberHint => '010-0000-0000';

  @override
  String get pinLabel => '密码';

  @override
  String get pinHint => '4位数字';

  @override
  String get startButton => '开始';

  @override
  String get forgotPinLink => '忘记密码了吗？';

  @override
  String pinWrongWithCount(int count) {
    return '密码不正确。（已失败$count次）';
  }

  @override
  String get pinWrong => '密码不正确。';

  @override
  String pinLockedWithTime(String time) {
    return '尝试次数过多。请在$time后重试。';
  }

  @override
  String get pinLockedNoTime => '尝试次数过多，账户已暂时锁定。请稍后重试。';

  @override
  String get pinNotSet => '尚未设置密码。';

  @override
  String get pinInvalidFormat => '密码必须是4位数字。';

  @override
  String get pinUnknownError => '确认时出现问题。请重试。';

  @override
  String get voiceAssistantLabel => '语音助手';

  @override
  String get navInfo => '信息';

  @override
  String get navHome => '首页';

  @override
  String get navRecords => '记录';

  @override
  String get navMore => '更多';

  @override
  String get profileTitle => '我的信息';

  @override
  String get nameLabel => '姓名';

  @override
  String get ageLabel => '年龄';

  @override
  String get profileSaved => '个人资料已保存。';

  @override
  String get profileLoadError => '无法加载已保存的信息。';

  @override
  String get myRegionTitle => '我的地区';

  @override
  String get regionLoadError => '无法加载地区信息。';

  @override
  String get currentRegionLabel => '当前地区';

  @override
  String get regionNotSetValue => '尚未登记';

  @override
  String get enterRegionAction => '输入我的地区';

  @override
  String get saveButton => '保存';

  @override
  String get sidoLabel => '省/市';

  @override
  String get sidoPlaceholder => '点击选择';

  @override
  String get sigunguLabel => '市/郡/区';

  @override
  String get dongLabel => '邑/面/洞';

  @override
  String get locatingButton => '正在确认当前位置…';

  @override
  String get useCurrentLocationButton => '使用当前位置自动填写';

  @override
  String get locationServiceDisabledError => '请开启定位服务后重试。';

  @override
  String get locationPermissionDeniedError => '请在设备设置中允许位置权限后重试。';

  @override
  String get locationPermissionRequiredError => '需要允许位置权限才能使用当前位置。';

  @override
  String get sidoRequiredError => '请选择省/市。';

  @override
  String get regionSaved => '我的地区已保存。';

  @override
  String get sidoPickerTitle => '选择省/市';

  @override
  String get welfareCenterTitle => '查找老年活动中心';

  @override
  String get welfareCenterRegionLoadError => '无法加载我的地区信息。';

  @override
  String get welfareCenterEmptyRegionMessage => '要查找老年活动中心，请先登记您的地区。';

  @override
  String get searchNearbyButton => '查找附近的老年活动中心';

  @override
  String get phoneLaunchError => '无法打开电话应用。';

  @override
  String get welfareCenterSearchError => '搜索时发生问题。';

  @override
  String get welfareCenterNoResults => '附近未找到老年活动中心。';

  @override
  String get callButtonTooltip => '拨打电话';

  @override
  String get voiceUnavailableError => '此设备无法使用语音识别。';

  @override
  String get voiceInitError => '无法启动语音助手。';

  @override
  String get voicePreparing => '正在准备语音助手…';

  @override
  String get voiceProcessing => '正在确认您的请求…';

  @override
  String get voiceIdlePrompt => '点击麦克风开始说话';

  @override
  String get voiceListening => '正在聆听…';

  @override
  String get voiceStartSemanticLabel => '开始说话';

  @override
  String get voiceUnrecognizedAnswer =>
      '没能听清楚您说的话。请尝试说\"문서 찍어줘\"（拍摄文件）、\"문자 확인해줘\"（查看短信）或\"긴급 도움\"（紧急帮助）。';

  @override
  String get voiceRetryButton => '请再说一次';
}
