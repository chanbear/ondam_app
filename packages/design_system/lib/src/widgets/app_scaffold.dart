import 'package:flutter/material.dart';

import '../tokens/app_spacing.dart';
import 'app_header.dart';

/// Shared screen shell — `Scaffold` + `SafeArea` + consistent screen padding
/// + optional `AppHeader`, so screens stop repeating this boilerplate
/// (ui-component-spec.md AppScaffold). Business logic never lives here —
/// this is composition only, same as `app/app.dart`.
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    this.title,
    this.onBack,
    this.backLabel,
    this.headerActions = const [],
    required this.body,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.scrollable = false,
  });

  final String? title;
  final VoidCallback? onBack;
  // null이면 AppHeader가 텍스트 없이 화살표 아이콘만 그린다 — AppHeader의
  // backLabel 문서 주석 참고(2026-08-31 실기기 다국어 버그 수정).
  final String? backLabel;
  final List<Widget> headerActions;
  final Widget body;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final EdgeInsetsGeometry padding;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final content = Padding(padding: padding, child: body);

    return Scaffold(
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      body: SafeArea(
        child: Column(
          children: [
            if (title != null)
              AppHeader(
                title: title!,
                onBack: onBack,
                backLabel: backLabel,
                actions: headerActions,
              ),
            Expanded(
              child: scrollable
                  ? SingleChildScrollView(child: content)
                  : content,
            ),
          ],
        ),
      ),
    );
  }
}
