import 'package:ondam_models/ondam_models.dart';
import 'package:test/test.dart';

void main() {
  test('completed는 지정하지 않으면 false로 시작한다', () {
    const item = ActionItem(id: 'a1', title: '관리비 납부');
    expect(item.completed, isFalse);
  });

  test('copyWith(completed: true)는 id/title은 유지하고 completed만 바꾼다', () {
    const item = ActionItem(id: 'a1', title: '관리비 납부');
    final checked = item.copyWith(completed: true);

    expect(checked.id, 'a1');
    expect(checked.title, '관리비 납부');
    expect(checked.completed, isTrue);
    expect(item.completed, isFalse, reason: '원본은 불변이어야 한다');
  });

  test('copyWith() 인자 없이 호출하면 기존 값을 그대로 유지한다', () {
    const item = ActionItem(id: 'a1', title: '관리비 납부', completed: true);
    final copy = item.copyWith();

    expect(copy.completed, isTrue);
  });
}
