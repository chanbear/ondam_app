import 'package:flutter/material.dart';

/// Shared loading indicator — use instead of a raw CircularProgressIndicator
/// scattered across pages.
class AppLoading extends StatelessWidget {
  const AppLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}
