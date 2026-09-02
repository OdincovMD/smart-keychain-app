import '../../core/failure.dart';

sealed class StorageFailure extends Failure {
  const StorageFailure({required this.operation, this.storageKey});

  final String operation;
  final String? storageKey;
}

final class StorageUnavailableFailure extends StorageFailure {
  const StorageUnavailableFailure({required super.operation, super.storageKey});

  @override
  String get code => 'storage.unavailable';
}

final class StorageItemNotFoundFailure extends StorageFailure {
  const StorageItemNotFoundFailure({required String storageKey})
    : super(operation: 'read', storageKey: storageKey);

  @override
  String get code => 'storage.not_found';
}
