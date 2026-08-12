import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ondam_storage/ondam_storage.dart';

/// Sensitive values only (auth tokens, ...). See technical-decisions.md §1-11.
final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

/// Non-sensitive settings only (easy mode, font size, ...).
final localStorageProvider = Provider<LocalStorageService>((ref) {
  return LocalStorageService();
});
