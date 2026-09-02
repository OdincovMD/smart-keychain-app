import 'package:drift/drift.dart';

mixin AuditColumns on Table {
  TextColumn get id => text()();

  IntColumn get createdAtUtcMs => integer()();

  IntColumn get updatedAtUtcMs => integer()();

  IntColumn get rowRevision => integer().withDefault(const Constant(0))();

  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  IntColumn get deletedAtUtcMs => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
