import 'package:flutter/widgets.dart';

/// Attached to [GoRouter] (see `app_router.dart`) so a tapped Push
/// notification — which happens outside any widget's `BuildContext` — can
/// still push a route onto the app's navigator (used by
/// `features/notification/presentation/services/notification_navigation.dart`
/// to open `AnalysisRecordDetailPage`).
final rootNavigatorKey = GlobalKey<NavigatorState>();
