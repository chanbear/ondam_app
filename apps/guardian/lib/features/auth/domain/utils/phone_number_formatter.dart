/// Normalizes a Korean mobile number entered as digits (with or without
/// dashes/spaces) into the E.164 format Supabase Phone Auth requires
/// (`+82` + national number without the leading 0). Returns `null` if the
/// input isn't a plausible Korean mobile number.
String? toE164KoreanPhoneNumber(String input) {
  final digitsOnly = input.replaceAll(RegExp(r'[^0-9+]'), '');

  if (digitsOnly.startsWith('+82')) {
    final national = digitsOnly.substring(3);
    return _isValidNationalNumber(national) ? '+82$national' : null;
  }

  if (digitsOnly.startsWith('0')) {
    final national = digitsOnly.substring(1);
    return _isValidNationalNumber(national) ? '+82$national' : null;
  }

  return null;
}

bool _isValidNationalNumber(String national) {
  // Korean mobile numbers: 10~11(e.g. 1012345678, 01012345678 -> national
  // part 10~11), starting with 1x after the trunk 0 is stripped.
  return RegExp(r'^1[0-9]{8,9}$').hasMatch(national);
}
