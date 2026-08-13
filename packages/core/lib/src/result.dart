import 'failure.dart';

/// Explicit success/failure return type for Repository methods (see
/// api.md: "Future<Either<Failure, T>> 또는 이에 준하는 명시적 성공/실패
/// 표현"). This project has no `dartz`/`fpdart` dependency, so this is the
/// minimal equivalent — a sealed class matched with `switch`, no exceptions
/// crossing the Repository boundary.
sealed class Result<T> {
  const Result();
}

final class Ok<T> extends Result<T> {
  const Ok(this.value);

  final T value;
}

final class Err<T> extends Result<T> {
  const Err(this.failure);

  final Failure failure;
}
