import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Central route table. Feature pages register their routes here instead of
/// each widget managing its own navigation.
///
/// Auth-gated routes and deep links: add a `redirect` callback here once an
/// auth provider exists — do not scatter navigation guards inside widgets.
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const _PlaceholderHomePage(),
      ),
    ],
    errorBuilder: (context, state) => const _NotFoundPage(),
  );
});

/// Minimal placeholder confirming the router/theme/state wiring works.
/// Replace with the real home feature page.
class _PlaceholderHomePage extends StatelessWidget {
  const _PlaceholderHomePage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('ondam_app')));
  }
}

class _NotFoundPage extends StatelessWidget {
  const _NotFoundPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('404 — 페이지를 찾을 수 없습니다.')));
  }
}
