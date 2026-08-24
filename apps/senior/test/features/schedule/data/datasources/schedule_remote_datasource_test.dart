import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Supabase SDK의 fluent 쿼리 빌더는 이 코드베이스 어디서도 mock으로
/// 테스트하지 않는다(`AnalysisRecordsRemoteDataSource` test와 동일한
/// 판단) — "본인 데이터만 다루도록 설계돼 있는가"는 실행 테스트가 아니라
/// 실제 배포되는 소스 코드 자체를 읽어 검증한다.
void main() {
  late String source;

  setUpAll(() {
    source = File(
      'lib/features/schedule/data/datasources/schedule_remote_datasource.dart',
    ).readAsStringSync();
  });

  test('fetchMine()은 세션의 본인 id로만 elder_id를 필터링한다', () {
    expect(
      source,
      contains("Future<List<Map<String, dynamic>>> fetchMine() async"),
    );
    expect(source, contains("final userId = _client.auth.currentUser?.id;"));
    expect(source, contains(".eq('elder_id', userId)"));
  });

  test('create()는 elder_id를 세션의 본인 id로 채운다 — 호출자가 다른 사람의 id를 넘길 수 없다', () {
    expect(source, contains("'elder_id': userId,"));
  });

  test('toggleCompleted()는 본인 elder_id로도 함께 필터링한다(defense in depth)', () {
    expect(
      source,
      contains("Future<void> toggleCompleted(String id, bool completed) async"),
    );
    expect(source, contains(".eq('id', id)\n        .eq('elder_id', userId)"));
  });

  test('delete()는 본인 elder_id로도 함께 필터링한다(defense in depth)', () {
    expect(source, contains("Future<void> delete(String id) async"));
    expect(source, contains(".eq('id', id)\n        .eq('elder_id', userId)"));
  });
}
