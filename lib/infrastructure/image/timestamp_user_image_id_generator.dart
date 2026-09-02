import '../../domain/image/user_image_id_generator.dart';

final class TimestampUserImageIdGenerator implements UserImageIdGenerator {
  int _sequence = 0;

  @override
  String next(DateTime createdAt) {
    final sequence = _sequence++;
    return '${createdAt.toUtc().microsecondsSinceEpoch}-$sequence';
  }
}
