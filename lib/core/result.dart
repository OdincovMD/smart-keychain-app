import 'failure.dart';

sealed class Result<T, F extends Failure> {
  const Result();

  R fold<R>(R Function(T value) onOk, R Function(F failure) onErr) {
    return switch (this) {
      Ok<T, F>(:final value) => onOk(value),
      Err<T, F>(:final failure) => onErr(failure),
    };
  }
}

final class Ok<T, F extends Failure> extends Result<T, F> {
  const Ok(this.value);

  final T value;
}

final class Err<T, F extends Failure> extends Result<T, F> {
  const Err(this.failure);

  final F failure;
}
