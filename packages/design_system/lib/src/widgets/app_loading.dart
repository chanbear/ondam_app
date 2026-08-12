import 'package:flutter/material.dart';

import '../tokens/app_spacing.dart';

/// Shared loading indicator — use instead of a raw CircularProgressIndicator
/// scattered across pages.
///
/// Per ui-spec.md UI 결정 D: simple data loading passes no [message] (just
/// the spinner); an important/long-running action (e.g. document analysis)
/// passes a [message] describing what's happening, shown below the spinner.
class AppLoading extends StatelessWidget {
  const AppLoading({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final message = this.message;
    if (message == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: AppSpacing.md),
          Text(message, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
