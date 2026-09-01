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
  String get appTagline => '为老年人提供的文档·短信确认助手';

  @override
  String get splashTagline => '为老年人提供的安心生活助手';

  @override
  String get splashStartButton => '开始使用온담';

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
  String get startButton => '前往设置';

  @override
  String get socialLoginDivider => '或';

  @override
  String get googleLoginButton => '使用谷歌登录';

  @override
  String get guestSignInButton => '无需注册直接使用';

  @override
  String get oauthPinSetupTitle => '请设置PIN码';

  @override
  String get oauthPinSetupSubtitle => '以后将使用此PIN码登录。';

  @override
  String get oauthPinEntryTitle => '请输入PIN码';

  @override
  String get oauthPinEntrySubtitle => '请输入您设置的4位PIN码。';

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
  String get ageDecreaseAction => '减少年龄';

  @override
  String get ageIncreaseAction => '增加年龄';

  @override
  String get genderSectionLabel => '性别';

  @override
  String get genderMaleLabel => '男';

  @override
  String get genderFemaleLabel => '女';

  @override
  String get genderRequiredError => '请选择性别。个性化信息搜索需要此项。';

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
  String get publicFacilitySearchLabel => '查找公共设施';

  @override
  String get publicFacilitySearchSubtitle => '查找附近的公共设施';

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
  String welfareCenterResultsSummary(String region, int count) {
    return '$region附近的老年活动中心$count处';
  }

  @override
  String get callButtonTooltip => '拨打电话';

  @override
  String get directionsButtonLabel => '查看路线';

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

  @override
  String get riskSafeLabel => '安全';

  @override
  String get riskCautionLabel => '注意';

  @override
  String get riskDangerousLabel => '检测到危险';

  @override
  String get analysisTypeDocumentLabel => '文件分析';

  @override
  String get analysisTypeMessageLabel => '短信核查';

  @override
  String get analysisResultTitle => '分析结果';

  @override
  String get shareButton => '分享';

  @override
  String get pinEntryPrompt => '请输入PIN码';

  @override
  String get pinForgotLink => '忘记PIN码了吗？';

  @override
  String get pinResetTitle => '重置PIN码';

  @override
  String get identityVerifyFailedTitle => '身份验证失败了';

  @override
  String get retryButton => '重试';

  @override
  String get pinNewSetupPrompt => '请设置新的4位PIN码';

  @override
  String get pinMismatchError => 'PIN码不一致，请重新输入。';

  @override
  String get pinConfirmPrompt => '请再输入一次';

  @override
  String get pinSetupPrompt => '请设置将要使用的4位PIN码';

  @override
  String get pinSetupDescription => '从下次开始，打开应用时将使用此PIN码验证。';

  @override
  String get roleSelectTitle => '您想以什么身份使用？';

  @override
  String get roleSelectSubtitle => '我们将根据使用目的为您准备相应的界面。';

  @override
  String get roleAlreadyRegisteredNotice => '此号码已以其他身份注册。继续操作将同时添加此身份。';

  @override
  String get roleElderButton => '我是老年人';

  @override
  String get roleGuardianButton => '我是家人（监护人）';

  @override
  String get pinKeypadClearLabel => '清除';

  @override
  String get guardianConnectTitle => '连接监护人';

  @override
  String get qrGeneratingMessage => '正在生成QR码';

  @override
  String get qrGenerateError => 'QR码生成失败，请重试。';

  @override
  String get qrShowGuardianPrompt => '请将此QR码展示给监护人';

  @override
  String get qrScanExplanation => '监护人扫描此QR码后，连接请求将会发送。';

  @override
  String get qrExpiredMessage => 'QR码已过期。';

  @override
  String get qrRegenerateButton => '重新生成QR码';

  @override
  String get guardianListTitle => '已连接的监护人列表';

  @override
  String get guardianConnectButton => '连接监护人';

  @override
  String get guardianListLoadError => '无法加载监护人列表。';

  @override
  String get guardianListEmptyMessage => '还没有已连接的监护人\n点击“连接监护人”显示QR码';

  @override
  String guardianRequestLabelWithId(String id) {
    return '监护人连接请求（$id）';
  }

  @override
  String guardianConnectedLabelWithId(String id) {
    return '已连接的监护人（$id）';
  }

  @override
  String guardianConnectedSince(String date) {
    return '已连接 · $date';
  }

  @override
  String get acceptButton => '接受';

  @override
  String get rejectButton => '拒绝';

  @override
  String get guardianRevokeConfirmTitle => '要解除连接吗？';

  @override
  String get guardianRevokeConfirmMessage => '解除后，此监护人将无法再查看您的信息。';

  @override
  String get guardianRevokeConfirmLabel => '解除';

  @override
  String get guardianRevokeAction => '解除连接';

  @override
  String get guardianStatusPending => '请求待处理';

  @override
  String get guardianStatusAccepted => '已连接';

  @override
  String get guardianStatusRejected => '已拒绝';

  @override
  String get guardianStatusRevoked => '已解除连接';

  @override
  String get documentScanTitle => '拍摄文件';

  @override
  String get documentScanStartTitle => '文件分析';

  @override
  String get documentScanStartTakePhotoButton => '拍照';

  @override
  String get documentScanStartPickPhotoButton => '从相册选择';

  @override
  String get documentScanStartTipTitle => '请务必确认！';

  @override
  String get documentScanStartTipLine1 => '请确保文件文字清晰可见';

  @override
  String get documentScanStartTipLine2 => '在光线充足且反光较少的地方拍摄会更准确';

  @override
  String get photoLibraryUnavailableError => '无法加载照片。';

  @override
  String get cameraPermissionCheckError => '无法确认相机权限。';

  @override
  String get cameraPermissionRequestMessage => '要拍摄并分析文件和短信，\n请允许访问相机。';

  @override
  String get cameraPermissionRequestButton => '允许相机权限';

  @override
  String get cameraPermissionBlockedMessage => '相机权限已被阻止。\n请在设备设置中直接允许。';

  @override
  String get openSettingsButton => '打开设置';

  @override
  String get scanPreviewTitle => '确认拍摄结果';

  @override
  String get retakeLabel => '重新拍摄';

  @override
  String scannedDocumentsCount(int count) {
    return '已拍摄$count张';
  }

  @override
  String photoCountBadge(int count) {
    return '$count张';
  }

  @override
  String get addAnotherPhotoButton => '追加拍摄';

  @override
  String get analyzeButton => '开始分析';

  @override
  String documentIndexLabel(int index) {
    return '文件 $index';
  }

  @override
  String deletePhotoAtIndexLabel(int index) {
    return '删除第$index张照片';
  }

  @override
  String documentAnalyzingProgress(int current, int total) {
    return '正在分析文件 $current/$total';
  }

  @override
  String documentsAnalyzedCount(int count) {
    return '已分析 $count 份文件';
  }

  @override
  String get noCameraAvailableError => '没有可用的相机。';

  @override
  String get cameraStartError => '无法启动相机。';

  @override
  String get flashUnavailableError => '此设备无法使用闪光灯。';

  @override
  String get flashOffLabel => '闪光灯关闭';

  @override
  String get flashOnLabel => '闪光灯打开';

  @override
  String get flashAutoLabel => '闪光灯自动';

  @override
  String get captureFailedError => '拍摄失败，请重试。';

  @override
  String get cameraPreparingMessage => '正在准备相机';

  @override
  String get documentFrameGuideMessage => '请将文件对准画面内';

  @override
  String get captureButtonLabel => '拍摄';

  @override
  String get closeCameraButtonLabel => '关闭';

  @override
  String get noGuardianConnectedError => '还没有已连接的监护人。';

  @override
  String get emergencyHelpTitle => '您需要帮助吗？';

  @override
  String get emergency119Label => '119报警（消防·急救）';

  @override
  String get emergency112Label => '112报警（警察）';

  @override
  String get govComplaintLabel => '110咨询（政府投诉引导）';

  @override
  String get dasanCallCenterLabel => '120咨询（多山呼叫中心）';

  @override
  String get cancelButton => '取消';

  @override
  String get myRecordsTitle => '我的记录';

  @override
  String get documentReadLabel => '阅读文件';

  @override
  String get documentReadSubtitle => '拍照即可为您读取文件';

  @override
  String get messageCheckLabel => '查看短信';

  @override
  String get messageCheckSubtitle => '为您读取短信并简单说明';

  @override
  String get recentMessagesIntro => '已获取最近的短信。\n请点击想要查看的短信。';

  @override
  String get infoTabTitle => '信息';

  @override
  String get infoTabEmptyMessage => '目前还没有准备好的信息，敬请期待个性化推荐信息。';

  @override
  String get statisticsLabel => '统计';

  @override
  String get usefulInfoLabel => '实用信息';

  @override
  String get howToUseLabel => '使用方法说明';

  @override
  String get supportTitle => '客户支持';

  @override
  String get moreTitle => '更多';

  @override
  String get recordsLoadingMessage => '正在加载记录';

  @override
  String get recordsLoadError => '加载记录时出现问题。';

  @override
  String get recordsEmptyMessage => '还没有分析记录。\n请尝试拍摄文件或查看短信。';

  @override
  String get helpRequestLabel => '请求帮助';

  @override
  String get easyModeOnState => '开启';

  @override
  String get easyModeOffState => '关闭';

  @override
  String easyModeToggleSemanticLabel(String state) {
    return '简易模式，当前$state';
  }

  @override
  String get easyModeDescription => '切换为更大更简单的界面';

  @override
  String get recentRecordsTitle => '最近记录';

  @override
  String get todayScheduleTitle => '今日日程';

  @override
  String get emergencyHelpRequestLabel => '紧急求助（SOS）';

  @override
  String get emergencyHelpRequestSubtitle => '紧急情况下快速请求帮助';

  @override
  String homeGreetingWithName(String name) {
    return '$name，您好！';
  }

  @override
  String get homeGreetingSubtitle => '祝您今天平安舒心';

  @override
  String get easyHomeHeadline => '需要什么帮助？';

  @override
  String infoGreetingWithName(String name) {
    return '为$name推荐的信息';
  }

  @override
  String get recordsFilterAllLabel => '全部';

  @override
  String get recordsFilterEmptyMessage => '没有符合条件的记录。\n请尝试其他筛选条件。';

  @override
  String get moreAccountSectionTitle => '账户';

  @override
  String get moreUsageInfoSectionTitle => '使用信息';

  @override
  String get smsPermissionCheckError => '无法确认短信权限。';

  @override
  String get smsPermissionRequestMessage => '要查看您收到的短信并判断是否为危险短信，\n请允许访问短信。';

  @override
  String get smsPermissionRequestButton => '允许短信权限';

  @override
  String get smsPermissionBlockedMessage => '短信权限已被阻止。\n请在设备设置中直接允许。';

  @override
  String get analysisGenericError => '分析过程中出现问题。';

  @override
  String get unknownSenderLabel => '未知号码';

  @override
  String get manualMessageInputPrompt => '请复制粘贴可疑短信，\n或直接手动输入。';

  @override
  String get pasteFromClipboardButton => '从剪贴板粘贴';

  @override
  String get messageContentLabel => '短信内容';

  @override
  String get messageContentHint => '请输入短信内容';

  @override
  String get recentSmsLoadingMessage => '正在加载最近短信';

  @override
  String get smsLoadError => '无法加载短信。';

  @override
  String get recentSmsEmptyMessage => '没有最近收到的短信。';

  @override
  String get accessibilitySettingsTitle => '无障碍设置';

  @override
  String get guardianRegisterTitle => '登记监护人';

  @override
  String get onboardingAccessibilityHeadline => '只需设置几项';

  @override
  String get onboardingAccessibilityIntro => '为了让您使用更方便，我们先进行一些设置。';

  @override
  String get nextButton => '下一步';

  @override
  String get onboardingProfileIntro => '告诉我们后，我们可以为您展示更有用的信息。（选填）';

  @override
  String get regionLabel => '地区';

  @override
  String get skipButton => '跳过';

  @override
  String get profileNextButton => '前往监护人注册';

  @override
  String get onboardingCompleteTitle => '设置完成！';

  @override
  String get onboardingCompleteSubtitle => '您可以开始使用온담了';

  @override
  String get textSizeTitle => '字体大小';

  @override
  String get textScaleNormalLabel => '标准';

  @override
  String get textScaleLargeLabel => '大';

  @override
  String get textScaleExtraLargeLabel => '特大';

  @override
  String get textScaleNormalDesc => '最多人选择的大小。';

  @override
  String get textScaleLargeDesc => '可以看得更大。';

  @override
  String get textScaleExtraLargeDesc => '显示最大的字体。';

  @override
  String get voiceGuideTitle => '语音引导';

  @override
  String get voiceGuideDescription => '屏幕内容也会以语音形式为您播报';

  @override
  String get voiceRateTitle => '语音提示速度';

  @override
  String get voiceRateNormalLabel => '1倍';

  @override
  String get voiceRateFastLabel => '1.2倍';

  @override
  String get voiceRateFasterLabel => '1.5倍';

  @override
  String get voiceRateFastestLabel => '2倍';

  @override
  String get homeVoiceGuideEasy => '这是首页。请从阅读文件、查看短信、查找老年活动中心、我的记录中选择。';

  @override
  String get homeVoiceGuideNormal => '这是首页。请从阅读文件、查看短信、查找老年活动中心、紧急求助中选择。';

  @override
  String get easyResultVoiceGuidePrefix => '为您播报分析结果。';

  @override
  String get feeStatisticsTitle => '费用统计';

  @override
  String get feeStatisticsLoadingMessage => '正在加载费用统计';

  @override
  String get feeStatisticsLoadError => '加载费用统计时出现问题。';

  @override
  String get privacyPinTitle => '密码（PIN码）';

  @override
  String get privacyPinBody =>
      'PIN原文或可推测出PIN的信息不会存储在本设备的任何位置。服务器上也仅保存加密后的验证专用值，没有任何途径可供他人查看。';

  @override
  String get privacyPhotoTitle => '文件拍摄照片';

  @override
  String get privacyPhotoBody =>
      '拍摄文件请求分析后，分析结束（无论成功或失败）会立即从服务器删除原始照片，仅保留分析结果。';

  @override
  String get privacySharedInfoTitle => '与监护人共享的信息';

  @override
  String get privacySharedInfoBody => '分析结果仅您接受连接的监护人可查看。解除连接后将无法再查看。';

  @override
  String get privacyRetentionTitle => '分析结果原文保留期限';

  @override
  String get privacyRetentionBody =>
      '短信·文件分析结果中留存的摘要/原文保留时长目前尚未确定，确定后将在此页面告知您。';

  @override
  String get privacyInfoTitle => '个人信息保管说明';

  @override
  String get supportContactTitle => '客服联系方式';

  @override
  String get supportContactComingSoon => '正在准备电话·邮箱联系方式，敬请期待。';

  @override
  String get privacyInfoDescription => '查看我的信息是如何保管的';

  @override
  String get micPermissionCheckError => '无法确认麦克风权限。';

  @override
  String get micPermissionRequestMessage => '要使用语音助手，\n请允许访问麦克风。';

  @override
  String get micPermissionRequestButton => '允许麦克风权限';

  @override
  String get micPermissionBlockedMessage => '麦克风权限已被阻止。\n请在设备设置中直接允许。';

  @override
  String get actionChecklistTitle => '待办事项';

  @override
  String get clarifyingQuestionsTitle => '有疑问吗？';

  @override
  String get askByVoiceButton => '语音提问';

  @override
  String get dateKindPaymentDue => '缴费期限';

  @override
  String get dateKindVisit => '访问日期';

  @override
  String get dateKindApplicationPeriod => '申请期限';

  @override
  String get dateKindExpiration => '到期日';

  @override
  String get dateKindReservation => '预约日期';

  @override
  String get dateKindOther => '其他重要日期';

  @override
  String get importantDatesTitle => '重要日期';

  @override
  String monthDayFormat(int month, int day) {
    return '$month月$day日';
  }

  @override
  String get keyPointsTitle => '主要内容';

  @override
  String analysisProgressSemanticLabel(int percent, String label) {
    return '分析进度$percent％，$label';
  }

  @override
  String get progressPreparing => '正在准备分析';

  @override
  String get progressSending => '正在发送数据';

  @override
  String get progressAnalyzing => 'AI正在检查';

  @override
  String get progressFinishing => '正在整理结果';

  @override
  String get detailsViewTitle => '查看详情';

  @override
  String get reliabilityLabel => '可信度';

  @override
  String get sourceTextLabel => '原文';

  @override
  String get structuredFieldRiskTypeLabel => '风险类型';

  @override
  String get riskTypeVoicePhishingLure => '电话诈骗诱导';

  @override
  String get riskTypeSmishing => '短信诈骗';

  @override
  String get riskTypeLoanScam => '贷款诈骗';

  @override
  String get riskTypeImpersonationAuthority => '机构冒充';

  @override
  String get riskTypeDeliveryScam => '快递诈骗';

  @override
  String get riskTypeInvestmentScam => '投资诈骗';

  @override
  String get riskTypeRomanceScam => '恋爱诈骗';

  @override
  String get riskTypeOtherScam => '其他诈骗';

  @override
  String get riskTypeNone => '无';

  @override
  String get easyResultAiSummaryLabel => 'AI摘要';

  @override
  String get easyResultTypeLabel => '种类';

  @override
  String get easyResultReplayLabel => '再听一次';

  @override
  String get askAboutThisButton => '针对此内容提问';

  @override
  String get confirmedDoneSemanticLabel => '已标记为确认完成';

  @override
  String get confirmedDoneMessage => '已确认完成';

  @override
  String get confirmDoneButton => '确认完成';

  @override
  String get featureComingSoonMessage => '此功能尚在筹备中。';

  @override
  String get feeStatisticsEmptyMessage => '尚无费用统计。\n分析账单或缴费通知单后将生成统计数据。';

  @override
  String get totalFeeLabel => '总费用';

  @override
  String get averageFeeLabel => '平均费用';

  @override
  String get maxFeeLabel => '最高费用';

  @override
  String get feeRecordCountLabel => '账单记录数';

  @override
  String get monthlyToggleLabel => '按月';

  @override
  String get yearlyToggleLabel => '按年';

  @override
  String toggleViewSemanticLabel(String label) {
    return '查看$label';
  }

  @override
  String get monthlyTrendTitle => '月度费用趋势';

  @override
  String get yearlyTrendTitle => '年度费用趋势';

  @override
  String get noDataInPeriodMessage => '该时间段内没有费用记录。';

  @override
  String get feeFootnote => '根据已分析账单/缴费通知单中的金额计算。AI未能提取金额的记录将被排除。';

  @override
  String get feeChartEmptyMessage => '尚无费用统计。';

  @override
  String get feeChartSemanticNoData => '费用趋势图。尚无数据。';

  @override
  String feeChartSemanticSummary(String summary) {
    return '费用趋势图。$summary';
  }

  @override
  String monthNumberLabel(int month) {
    return '$month月';
  }

  @override
  String yearNumberLabel(int year) {
    return '$year年';
  }

  @override
  String feeHeroTitle(int month) {
    return '$month月费用';
  }

  @override
  String feeHeroLessThanLastMonth(String amount) {
    return '比上个月少$amount';
  }

  @override
  String feeHeroMoreThanLastMonth(String amount) {
    return '比上个月多$amount';
  }

  @override
  String get feeHeroSameAsLastMonth => '与上个月相同';

  @override
  String get recentBillsTitle => '最近账单';

  @override
  String countUnitLabel(int count) {
    return '$count件';
  }

  @override
  String get notifSettingsTitle => '通知设置';

  @override
  String get dangerAlertLabel => '危险提醒';

  @override
  String get alwaysOnCaption => '始终开启';

  @override
  String get guardianNotifyLabel => '通知监护人';

  @override
  String get messageGuardianNoticeTitle => '已通知监护人';

  @override
  String get messageGuardianNoticeBody => '已把短信内容告诉监护人';

  @override
  String get goHomeButton => '回首页';
}
