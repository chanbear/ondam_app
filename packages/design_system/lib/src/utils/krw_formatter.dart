/// 원화 금액 표시 포맷터 — PHASE 37 요금 통계 화면들이 공유한다(중복 구현
/// 방지). `intl` 패키지를 새로 추가하지 않고 순수 Dart로 충분한 범위만
/// 구현한다.
library;

/// "87500" → "87,500원". 통계 카드/상세 등 정확한 금액이 필요한 곳에 쓴다.
String formatKrw(int amountKrw) {
  final digits = amountKrw.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
    buffer.write(digits[i]);
  }
  final sign = amountKrw < 0 ? '-' : '';
  return '$sign$buffer원';
}

/// "87500" → "8.8만" — 그래프 축처럼 좁은 공간에서 overflow 없이 큰 금액을
/// 보여줘야 하는 곳 전용(PHASE 37 §10 "매우 큰 금액에서도 overflow가 발생하지
/// 않도록"). 정확한 금액이 필요하면 [formatKrw]를 쓴다 — 이 함수는 요약
/// 표시용으로, 반올림된 근사값이다.
String formatKrwCompact(int amountKrw) {
  final abs = amountKrw.abs();
  final sign = amountKrw < 0 ? '-' : '';
  if (abs >= 100000000) {
    return '$sign${_trimZero(abs / 100000000)}억';
  }
  if (abs >= 10000) {
    return '$sign${_trimZero(abs / 10000)}만';
  }
  return '$sign$abs';
}

String _trimZero(double value) {
  final rounded = (value * 10).round() / 10;
  return rounded == rounded.roundToDouble()
      ? rounded.toInt().toString()
      : rounded.toString();
}
