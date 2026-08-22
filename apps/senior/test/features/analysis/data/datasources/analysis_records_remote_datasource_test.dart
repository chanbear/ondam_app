import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Supabase SDK의 fluent 쿼리 빌더는 이 코드베이스 어디서도 mock으로
/// 테스트하지 않는다(다른 feature들도 datasource는 Repository 테스트에서
/// mock으로 대체하고, datasource 자체는 직접 실행하지 않는다 — api.md).
/// 그래서 "본인 데이터만 조회하도록 설계돼 있는가"는 실행 테스트가 아니라
/// 실제 배포되는 소스 코드 자체를 읽어 검증한다(PHASE 10: "코드 레벨로
/// 확인, RLS 시뮬레이션 아님").
void main() {
  test('fetchMine()은 파라미터 없이 세션의 본인 id로만 elder_id를 필터링한다 — '
      '호출자가 다른 사람의 id를 넘길 수 있는 경로 자체가 없다', () {
    final source = File(
      'lib/features/analysis/data/datasources/analysis_records_remote_datasource.dart',
    ).readAsStringSync();

    expect(
      source,
      contains("Future<List<Map<String, dynamic>>> fetchMine() async"),
      reason: 'fetchMine은 elderId 등 외부 파라미터를 받지 않아야 한다',
    );
    expect(
      source,
      contains("final userId = _client.auth.currentUser?.id;"),
      reason: 'elder_id 필터 값은 반드시 세션의 본인 id에서만 가져와야 한다',
    );
    expect(
      source,
      contains(".eq('elder_id', userId)"),
      reason: '전체 테이블이 아니라 본인 elder_id로만 필터링해야 한다',
    );
  });

  test('confirm()은 본인 elder_id로도 함께 필터링한다(defense in depth) — '
      'RLS 하나만 믿지 않는다', () {
    final source = File(
      'lib/features/analysis/data/datasources/analysis_records_remote_datasource.dart',
    ).readAsStringSync();

    expect(
      source,
      contains("Future<void> confirm(String analysisResultId) async"),
    );
    expect(
      source,
      contains(".eq('id', analysisResultId)"),
      reason: '지정한 분석 결과 하나만 대상이어야 한다',
    );
    expect(
      source,
      contains(".eq('elder_id', userId)"),
      reason: '본인 소유 행이 아니면 RLS가 막더라도 클라이언트 코드 자체도 다른 사람의 id를 노릴 수 없어야 한다',
    );
  });
}
