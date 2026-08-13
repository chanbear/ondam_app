import 'package:flutter/material.dart';
import 'package:ondam_design_system/ondam_design_system.dart';

/// Neutral placeholder shown while the router waits for `hasPinProvider`
/// (or role state) to resolve after a session is established. Never a
/// terminal destination — the router's `redirect` moves away from this
/// the instant the underlying provider settles.
class SessionLoadingPage extends StatelessWidget {
  const SessionLoadingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: AppLoading());
  }
}
