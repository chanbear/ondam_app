/// 어르신의 나이/성별 — `profile`(입력)과 `info`(맞춤 혜택 정보 검색 조건
/// 읽기) feature가 함께 구독하는 공유 상태이므로 `core/location`의
/// `Region`과 동일한 이유로 core에 둔다.
enum Gender {
  male('male'),
  female('female');

  const Gender(this.value);

  /// DB 컬럼 값이자 Edge Function 요청 바디에 실리는 wire value.
  final String value;

  static Gender? fromValue(String? raw) => switch (raw) {
    'male' => Gender.male,
    'female' => Gender.female,
    _ => null,
  };
}

class Demographics {
  const Demographics({required this.age, required this.gender});

  final int? age;
  final Gender? gender;

  /// 둘 다 입력됐을 때만 "완전하다" — `features/info`가 검색 조건으로
  /// 쓸 수 있는지 판단하는 기준이다.
  bool get isComplete => age != null && gender != null;

  @override
  bool operator ==(Object other) {
    return other is Demographics && other.age == age && other.gender == gender;
  }

  @override
  int get hashCode => Object.hash(age, gender);
}
