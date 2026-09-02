// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $AppSettingsEntriesTable extends AppSettingsEntries
    with TableInfo<$AppSettingsEntriesTable, AppSettingsRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtUtcMsMeta = const VerificationMeta(
    'createdAtUtcMs',
  );
  @override
  late final GeneratedColumn<int> createdAtUtcMs = GeneratedColumn<int>(
    'created_at_utc_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtUtcMsMeta = const VerificationMeta(
    'updatedAtUtcMs',
  );
  @override
  late final GeneratedColumn<int> updatedAtUtcMs = GeneratedColumn<int>(
    'updated_at_utc_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rowRevisionMeta = const VerificationMeta(
    'rowRevision',
  );
  @override
  late final GeneratedColumn<int> rowRevision = GeneratedColumn<int>(
    'row_revision',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _deletedAtUtcMsMeta = const VerificationMeta(
    'deletedAtUtcMs',
  );
  @override
  late final GeneratedColumn<int> deletedAtUtcMs = GeneratedColumn<int>(
    'deleted_at_utc_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _activeSceneIdMeta = const VerificationMeta(
    'activeSceneId',
  );
  @override
  late final GeneratedColumn<String> activeSceneId = GeneratedColumn<String>(
    'active_scene_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _brightnessPermilleMeta =
      const VerificationMeta('brightnessPermille');
  @override
  late final GeneratedColumn<int> brightnessPermille = GeneratedColumn<int>(
    'brightness_permille',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(800),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAtUtcMs,
    updatedAtUtcMs,
    rowRevision,
    isDeleted,
    deletedAtUtcMs,
    activeSceneId,
    brightnessPermille,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppSettingsRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at_utc_ms')) {
      context.handle(
        _createdAtUtcMsMeta,
        createdAtUtcMs.isAcceptableOrUnknown(
          data['created_at_utc_ms']!,
          _createdAtUtcMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtUtcMsMeta);
    }
    if (data.containsKey('updated_at_utc_ms')) {
      context.handle(
        _updatedAtUtcMsMeta,
        updatedAtUtcMs.isAcceptableOrUnknown(
          data['updated_at_utc_ms']!,
          _updatedAtUtcMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_updatedAtUtcMsMeta);
    }
    if (data.containsKey('row_revision')) {
      context.handle(
        _rowRevisionMeta,
        rowRevision.isAcceptableOrUnknown(
          data['row_revision']!,
          _rowRevisionMeta,
        ),
      );
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    if (data.containsKey('deleted_at_utc_ms')) {
      context.handle(
        _deletedAtUtcMsMeta,
        deletedAtUtcMs.isAcceptableOrUnknown(
          data['deleted_at_utc_ms']!,
          _deletedAtUtcMsMeta,
        ),
      );
    }
    if (data.containsKey('active_scene_id')) {
      context.handle(
        _activeSceneIdMeta,
        activeSceneId.isAcceptableOrUnknown(
          data['active_scene_id']!,
          _activeSceneIdMeta,
        ),
      );
    }
    if (data.containsKey('brightness_permille')) {
      context.handle(
        _brightnessPermilleMeta,
        brightnessPermille.isAcceptableOrUnknown(
          data['brightness_permille']!,
          _brightnessPermilleMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AppSettingsRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSettingsRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAtUtcMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at_utc_ms'],
      )!,
      updatedAtUtcMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at_utc_ms'],
      )!,
      rowRevision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}row_revision'],
      )!,
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_deleted'],
      )!,
      deletedAtUtcMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at_utc_ms'],
      ),
      activeSceneId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}active_scene_id'],
      ),
      brightnessPermille: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}brightness_permille'],
      )!,
    );
  }

  @override
  $AppSettingsEntriesTable createAlias(String alias) {
    return $AppSettingsEntriesTable(attachedDatabase, alias);
  }

  @override
  bool get isStrict => true;
}

class AppSettingsRow extends DataClass implements Insertable<AppSettingsRow> {
  final String id;
  final int createdAtUtcMs;
  final int updatedAtUtcMs;
  final int rowRevision;
  final bool isDeleted;
  final int? deletedAtUtcMs;
  final String? activeSceneId;
  final int brightnessPermille;
  const AppSettingsRow({
    required this.id,
    required this.createdAtUtcMs,
    required this.updatedAtUtcMs,
    required this.rowRevision,
    required this.isDeleted,
    this.deletedAtUtcMs,
    this.activeSceneId,
    required this.brightnessPermille,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at_utc_ms'] = Variable<int>(createdAtUtcMs);
    map['updated_at_utc_ms'] = Variable<int>(updatedAtUtcMs);
    map['row_revision'] = Variable<int>(rowRevision);
    map['is_deleted'] = Variable<bool>(isDeleted);
    if (!nullToAbsent || deletedAtUtcMs != null) {
      map['deleted_at_utc_ms'] = Variable<int>(deletedAtUtcMs);
    }
    if (!nullToAbsent || activeSceneId != null) {
      map['active_scene_id'] = Variable<String>(activeSceneId);
    }
    map['brightness_permille'] = Variable<int>(brightnessPermille);
    return map;
  }

  AppSettingsEntriesCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsEntriesCompanion(
      id: Value(id),
      createdAtUtcMs: Value(createdAtUtcMs),
      updatedAtUtcMs: Value(updatedAtUtcMs),
      rowRevision: Value(rowRevision),
      isDeleted: Value(isDeleted),
      deletedAtUtcMs: deletedAtUtcMs == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAtUtcMs),
      activeSceneId: activeSceneId == null && nullToAbsent
          ? const Value.absent()
          : Value(activeSceneId),
      brightnessPermille: Value(brightnessPermille),
    );
  }

  factory AppSettingsRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSettingsRow(
      id: serializer.fromJson<String>(json['id']),
      createdAtUtcMs: serializer.fromJson<int>(json['createdAtUtcMs']),
      updatedAtUtcMs: serializer.fromJson<int>(json['updatedAtUtcMs']),
      rowRevision: serializer.fromJson<int>(json['rowRevision']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
      deletedAtUtcMs: serializer.fromJson<int?>(json['deletedAtUtcMs']),
      activeSceneId: serializer.fromJson<String?>(json['activeSceneId']),
      brightnessPermille: serializer.fromJson<int>(json['brightnessPermille']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAtUtcMs': serializer.toJson<int>(createdAtUtcMs),
      'updatedAtUtcMs': serializer.toJson<int>(updatedAtUtcMs),
      'rowRevision': serializer.toJson<int>(rowRevision),
      'isDeleted': serializer.toJson<bool>(isDeleted),
      'deletedAtUtcMs': serializer.toJson<int?>(deletedAtUtcMs),
      'activeSceneId': serializer.toJson<String?>(activeSceneId),
      'brightnessPermille': serializer.toJson<int>(brightnessPermille),
    };
  }

  AppSettingsRow copyWith({
    String? id,
    int? createdAtUtcMs,
    int? updatedAtUtcMs,
    int? rowRevision,
    bool? isDeleted,
    Value<int?> deletedAtUtcMs = const Value.absent(),
    Value<String?> activeSceneId = const Value.absent(),
    int? brightnessPermille,
  }) => AppSettingsRow(
    id: id ?? this.id,
    createdAtUtcMs: createdAtUtcMs ?? this.createdAtUtcMs,
    updatedAtUtcMs: updatedAtUtcMs ?? this.updatedAtUtcMs,
    rowRevision: rowRevision ?? this.rowRevision,
    isDeleted: isDeleted ?? this.isDeleted,
    deletedAtUtcMs: deletedAtUtcMs.present
        ? deletedAtUtcMs.value
        : this.deletedAtUtcMs,
    activeSceneId: activeSceneId.present
        ? activeSceneId.value
        : this.activeSceneId,
    brightnessPermille: brightnessPermille ?? this.brightnessPermille,
  );
  AppSettingsRow copyWithCompanion(AppSettingsEntriesCompanion data) {
    return AppSettingsRow(
      id: data.id.present ? data.id.value : this.id,
      createdAtUtcMs: data.createdAtUtcMs.present
          ? data.createdAtUtcMs.value
          : this.createdAtUtcMs,
      updatedAtUtcMs: data.updatedAtUtcMs.present
          ? data.updatedAtUtcMs.value
          : this.updatedAtUtcMs,
      rowRevision: data.rowRevision.present
          ? data.rowRevision.value
          : this.rowRevision,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
      deletedAtUtcMs: data.deletedAtUtcMs.present
          ? data.deletedAtUtcMs.value
          : this.deletedAtUtcMs,
      activeSceneId: data.activeSceneId.present
          ? data.activeSceneId.value
          : this.activeSceneId,
      brightnessPermille: data.brightnessPermille.present
          ? data.brightnessPermille.value
          : this.brightnessPermille,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsRow(')
          ..write('id: $id, ')
          ..write('createdAtUtcMs: $createdAtUtcMs, ')
          ..write('updatedAtUtcMs: $updatedAtUtcMs, ')
          ..write('rowRevision: $rowRevision, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('deletedAtUtcMs: $deletedAtUtcMs, ')
          ..write('activeSceneId: $activeSceneId, ')
          ..write('brightnessPermille: $brightnessPermille')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAtUtcMs,
    updatedAtUtcMs,
    rowRevision,
    isDeleted,
    deletedAtUtcMs,
    activeSceneId,
    brightnessPermille,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSettingsRow &&
          other.id == this.id &&
          other.createdAtUtcMs == this.createdAtUtcMs &&
          other.updatedAtUtcMs == this.updatedAtUtcMs &&
          other.rowRevision == this.rowRevision &&
          other.isDeleted == this.isDeleted &&
          other.deletedAtUtcMs == this.deletedAtUtcMs &&
          other.activeSceneId == this.activeSceneId &&
          other.brightnessPermille == this.brightnessPermille);
}

class AppSettingsEntriesCompanion extends UpdateCompanion<AppSettingsRow> {
  final Value<String> id;
  final Value<int> createdAtUtcMs;
  final Value<int> updatedAtUtcMs;
  final Value<int> rowRevision;
  final Value<bool> isDeleted;
  final Value<int?> deletedAtUtcMs;
  final Value<String?> activeSceneId;
  final Value<int> brightnessPermille;
  final Value<int> rowid;
  const AppSettingsEntriesCompanion({
    this.id = const Value.absent(),
    this.createdAtUtcMs = const Value.absent(),
    this.updatedAtUtcMs = const Value.absent(),
    this.rowRevision = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.deletedAtUtcMs = const Value.absent(),
    this.activeSceneId = const Value.absent(),
    this.brightnessPermille = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppSettingsEntriesCompanion.insert({
    required String id,
    required int createdAtUtcMs,
    required int updatedAtUtcMs,
    this.rowRevision = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.deletedAtUtcMs = const Value.absent(),
    this.activeSceneId = const Value.absent(),
    this.brightnessPermille = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAtUtcMs = Value(createdAtUtcMs),
       updatedAtUtcMs = Value(updatedAtUtcMs);
  static Insertable<AppSettingsRow> custom({
    Expression<String>? id,
    Expression<int>? createdAtUtcMs,
    Expression<int>? updatedAtUtcMs,
    Expression<int>? rowRevision,
    Expression<bool>? isDeleted,
    Expression<int>? deletedAtUtcMs,
    Expression<String>? activeSceneId,
    Expression<int>? brightnessPermille,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAtUtcMs != null) 'created_at_utc_ms': createdAtUtcMs,
      if (updatedAtUtcMs != null) 'updated_at_utc_ms': updatedAtUtcMs,
      if (rowRevision != null) 'row_revision': rowRevision,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (deletedAtUtcMs != null) 'deleted_at_utc_ms': deletedAtUtcMs,
      if (activeSceneId != null) 'active_scene_id': activeSceneId,
      if (brightnessPermille != null) 'brightness_permille': brightnessPermille,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppSettingsEntriesCompanion copyWith({
    Value<String>? id,
    Value<int>? createdAtUtcMs,
    Value<int>? updatedAtUtcMs,
    Value<int>? rowRevision,
    Value<bool>? isDeleted,
    Value<int?>? deletedAtUtcMs,
    Value<String?>? activeSceneId,
    Value<int>? brightnessPermille,
    Value<int>? rowid,
  }) {
    return AppSettingsEntriesCompanion(
      id: id ?? this.id,
      createdAtUtcMs: createdAtUtcMs ?? this.createdAtUtcMs,
      updatedAtUtcMs: updatedAtUtcMs ?? this.updatedAtUtcMs,
      rowRevision: rowRevision ?? this.rowRevision,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAtUtcMs: deletedAtUtcMs ?? this.deletedAtUtcMs,
      activeSceneId: activeSceneId ?? this.activeSceneId,
      brightnessPermille: brightnessPermille ?? this.brightnessPermille,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAtUtcMs.present) {
      map['created_at_utc_ms'] = Variable<int>(createdAtUtcMs.value);
    }
    if (updatedAtUtcMs.present) {
      map['updated_at_utc_ms'] = Variable<int>(updatedAtUtcMs.value);
    }
    if (rowRevision.present) {
      map['row_revision'] = Variable<int>(rowRevision.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (deletedAtUtcMs.present) {
      map['deleted_at_utc_ms'] = Variable<int>(deletedAtUtcMs.value);
    }
    if (activeSceneId.present) {
      map['active_scene_id'] = Variable<String>(activeSceneId.value);
    }
    if (brightnessPermille.present) {
      map['brightness_permille'] = Variable<int>(brightnessPermille.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsEntriesCompanion(')
          ..write('id: $id, ')
          ..write('createdAtUtcMs: $createdAtUtcMs, ')
          ..write('updatedAtUtcMs: $updatedAtUtcMs, ')
          ..write('rowRevision: $rowRevision, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('deletedAtUtcMs: $deletedAtUtcMs, ')
          ..write('activeSceneId: $activeSceneId, ')
          ..write('brightnessPermille: $brightnessPermille, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UserImageAssetsTable extends UserImageAssets
    with TableInfo<$UserImageAssetsTable, UserImageAssetRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserImageAssetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtUtcMsMeta = const VerificationMeta(
    'createdAtUtcMs',
  );
  @override
  late final GeneratedColumn<int> createdAtUtcMs = GeneratedColumn<int>(
    'created_at_utc_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtUtcMsMeta = const VerificationMeta(
    'updatedAtUtcMs',
  );
  @override
  late final GeneratedColumn<int> updatedAtUtcMs = GeneratedColumn<int>(
    'updated_at_utc_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rowRevisionMeta = const VerificationMeta(
    'rowRevision',
  );
  @override
  late final GeneratedColumn<int> rowRevision = GeneratedColumn<int>(
    'row_revision',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _deletedAtUtcMsMeta = const VerificationMeta(
    'deletedAtUtcMs',
  );
  @override
  late final GeneratedColumn<int> deletedAtUtcMs = GeneratedColumn<int>(
    'deleted_at_utc_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _originalStorageKeyMeta =
      const VerificationMeta('originalStorageKey');
  @override
  late final GeneratedColumn<String> originalStorageKey =
      GeneratedColumn<String>(
        'original_storage_key',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _previewStorageKeyMeta = const VerificationMeta(
    'previewStorageKey',
  );
  @override
  late final GeneratedColumn<String> previewStorageKey =
      GeneratedColumn<String>(
        'preview_storage_key',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _cropCenterXMeta = const VerificationMeta(
    'cropCenterX',
  );
  @override
  late final GeneratedColumn<double> cropCenterX = GeneratedColumn<double>(
    'crop_center_x',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cropCenterYMeta = const VerificationMeta(
    'cropCenterY',
  );
  @override
  late final GeneratedColumn<double> cropCenterY = GeneratedColumn<double>(
    'crop_center_y',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cropScaleMeta = const VerificationMeta(
    'cropScale',
  );
  @override
  late final GeneratedColumn<double> cropScale = GeneratedColumn<double>(
    'crop_scale',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cropRotationMeta = const VerificationMeta(
    'cropRotation',
  );
  @override
  late final GeneratedColumn<double> cropRotation = GeneratedColumn<double>(
    'crop_rotation',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAtUtcMs,
    updatedAtUtcMs,
    rowRevision,
    isDeleted,
    deletedAtUtcMs,
    originalStorageKey,
    previewStorageKey,
    cropCenterX,
    cropCenterY,
    cropScale,
    cropRotation,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_image_assets';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserImageAssetRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at_utc_ms')) {
      context.handle(
        _createdAtUtcMsMeta,
        createdAtUtcMs.isAcceptableOrUnknown(
          data['created_at_utc_ms']!,
          _createdAtUtcMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtUtcMsMeta);
    }
    if (data.containsKey('updated_at_utc_ms')) {
      context.handle(
        _updatedAtUtcMsMeta,
        updatedAtUtcMs.isAcceptableOrUnknown(
          data['updated_at_utc_ms']!,
          _updatedAtUtcMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_updatedAtUtcMsMeta);
    }
    if (data.containsKey('row_revision')) {
      context.handle(
        _rowRevisionMeta,
        rowRevision.isAcceptableOrUnknown(
          data['row_revision']!,
          _rowRevisionMeta,
        ),
      );
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    if (data.containsKey('deleted_at_utc_ms')) {
      context.handle(
        _deletedAtUtcMsMeta,
        deletedAtUtcMs.isAcceptableOrUnknown(
          data['deleted_at_utc_ms']!,
          _deletedAtUtcMsMeta,
        ),
      );
    }
    if (data.containsKey('original_storage_key')) {
      context.handle(
        _originalStorageKeyMeta,
        originalStorageKey.isAcceptableOrUnknown(
          data['original_storage_key']!,
          _originalStorageKeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_originalStorageKeyMeta);
    }
    if (data.containsKey('preview_storage_key')) {
      context.handle(
        _previewStorageKeyMeta,
        previewStorageKey.isAcceptableOrUnknown(
          data['preview_storage_key']!,
          _previewStorageKeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_previewStorageKeyMeta);
    }
    if (data.containsKey('crop_center_x')) {
      context.handle(
        _cropCenterXMeta,
        cropCenterX.isAcceptableOrUnknown(
          data['crop_center_x']!,
          _cropCenterXMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_cropCenterXMeta);
    }
    if (data.containsKey('crop_center_y')) {
      context.handle(
        _cropCenterYMeta,
        cropCenterY.isAcceptableOrUnknown(
          data['crop_center_y']!,
          _cropCenterYMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_cropCenterYMeta);
    }
    if (data.containsKey('crop_scale')) {
      context.handle(
        _cropScaleMeta,
        cropScale.isAcceptableOrUnknown(data['crop_scale']!, _cropScaleMeta),
      );
    } else if (isInserting) {
      context.missing(_cropScaleMeta);
    }
    if (data.containsKey('crop_rotation')) {
      context.handle(
        _cropRotationMeta,
        cropRotation.isAcceptableOrUnknown(
          data['crop_rotation']!,
          _cropRotationMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_cropRotationMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UserImageAssetRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserImageAssetRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAtUtcMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at_utc_ms'],
      )!,
      updatedAtUtcMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at_utc_ms'],
      )!,
      rowRevision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}row_revision'],
      )!,
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_deleted'],
      )!,
      deletedAtUtcMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at_utc_ms'],
      ),
      originalStorageKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}original_storage_key'],
      )!,
      previewStorageKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}preview_storage_key'],
      )!,
      cropCenterX: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}crop_center_x'],
      )!,
      cropCenterY: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}crop_center_y'],
      )!,
      cropScale: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}crop_scale'],
      )!,
      cropRotation: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}crop_rotation'],
      )!,
    );
  }

  @override
  $UserImageAssetsTable createAlias(String alias) {
    return $UserImageAssetsTable(attachedDatabase, alias);
  }

  @override
  bool get isStrict => true;
}

class UserImageAssetRow extends DataClass
    implements Insertable<UserImageAssetRow> {
  final String id;
  final int createdAtUtcMs;
  final int updatedAtUtcMs;
  final int rowRevision;
  final bool isDeleted;
  final int? deletedAtUtcMs;
  final String originalStorageKey;
  final String previewStorageKey;
  final double cropCenterX;
  final double cropCenterY;
  final double cropScale;
  final double cropRotation;
  const UserImageAssetRow({
    required this.id,
    required this.createdAtUtcMs,
    required this.updatedAtUtcMs,
    required this.rowRevision,
    required this.isDeleted,
    this.deletedAtUtcMs,
    required this.originalStorageKey,
    required this.previewStorageKey,
    required this.cropCenterX,
    required this.cropCenterY,
    required this.cropScale,
    required this.cropRotation,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at_utc_ms'] = Variable<int>(createdAtUtcMs);
    map['updated_at_utc_ms'] = Variable<int>(updatedAtUtcMs);
    map['row_revision'] = Variable<int>(rowRevision);
    map['is_deleted'] = Variable<bool>(isDeleted);
    if (!nullToAbsent || deletedAtUtcMs != null) {
      map['deleted_at_utc_ms'] = Variable<int>(deletedAtUtcMs);
    }
    map['original_storage_key'] = Variable<String>(originalStorageKey);
    map['preview_storage_key'] = Variable<String>(previewStorageKey);
    map['crop_center_x'] = Variable<double>(cropCenterX);
    map['crop_center_y'] = Variable<double>(cropCenterY);
    map['crop_scale'] = Variable<double>(cropScale);
    map['crop_rotation'] = Variable<double>(cropRotation);
    return map;
  }

  UserImageAssetsCompanion toCompanion(bool nullToAbsent) {
    return UserImageAssetsCompanion(
      id: Value(id),
      createdAtUtcMs: Value(createdAtUtcMs),
      updatedAtUtcMs: Value(updatedAtUtcMs),
      rowRevision: Value(rowRevision),
      isDeleted: Value(isDeleted),
      deletedAtUtcMs: deletedAtUtcMs == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAtUtcMs),
      originalStorageKey: Value(originalStorageKey),
      previewStorageKey: Value(previewStorageKey),
      cropCenterX: Value(cropCenterX),
      cropCenterY: Value(cropCenterY),
      cropScale: Value(cropScale),
      cropRotation: Value(cropRotation),
    );
  }

  factory UserImageAssetRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserImageAssetRow(
      id: serializer.fromJson<String>(json['id']),
      createdAtUtcMs: serializer.fromJson<int>(json['createdAtUtcMs']),
      updatedAtUtcMs: serializer.fromJson<int>(json['updatedAtUtcMs']),
      rowRevision: serializer.fromJson<int>(json['rowRevision']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
      deletedAtUtcMs: serializer.fromJson<int?>(json['deletedAtUtcMs']),
      originalStorageKey: serializer.fromJson<String>(
        json['originalStorageKey'],
      ),
      previewStorageKey: serializer.fromJson<String>(json['previewStorageKey']),
      cropCenterX: serializer.fromJson<double>(json['cropCenterX']),
      cropCenterY: serializer.fromJson<double>(json['cropCenterY']),
      cropScale: serializer.fromJson<double>(json['cropScale']),
      cropRotation: serializer.fromJson<double>(json['cropRotation']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAtUtcMs': serializer.toJson<int>(createdAtUtcMs),
      'updatedAtUtcMs': serializer.toJson<int>(updatedAtUtcMs),
      'rowRevision': serializer.toJson<int>(rowRevision),
      'isDeleted': serializer.toJson<bool>(isDeleted),
      'deletedAtUtcMs': serializer.toJson<int?>(deletedAtUtcMs),
      'originalStorageKey': serializer.toJson<String>(originalStorageKey),
      'previewStorageKey': serializer.toJson<String>(previewStorageKey),
      'cropCenterX': serializer.toJson<double>(cropCenterX),
      'cropCenterY': serializer.toJson<double>(cropCenterY),
      'cropScale': serializer.toJson<double>(cropScale),
      'cropRotation': serializer.toJson<double>(cropRotation),
    };
  }

  UserImageAssetRow copyWith({
    String? id,
    int? createdAtUtcMs,
    int? updatedAtUtcMs,
    int? rowRevision,
    bool? isDeleted,
    Value<int?> deletedAtUtcMs = const Value.absent(),
    String? originalStorageKey,
    String? previewStorageKey,
    double? cropCenterX,
    double? cropCenterY,
    double? cropScale,
    double? cropRotation,
  }) => UserImageAssetRow(
    id: id ?? this.id,
    createdAtUtcMs: createdAtUtcMs ?? this.createdAtUtcMs,
    updatedAtUtcMs: updatedAtUtcMs ?? this.updatedAtUtcMs,
    rowRevision: rowRevision ?? this.rowRevision,
    isDeleted: isDeleted ?? this.isDeleted,
    deletedAtUtcMs: deletedAtUtcMs.present
        ? deletedAtUtcMs.value
        : this.deletedAtUtcMs,
    originalStorageKey: originalStorageKey ?? this.originalStorageKey,
    previewStorageKey: previewStorageKey ?? this.previewStorageKey,
    cropCenterX: cropCenterX ?? this.cropCenterX,
    cropCenterY: cropCenterY ?? this.cropCenterY,
    cropScale: cropScale ?? this.cropScale,
    cropRotation: cropRotation ?? this.cropRotation,
  );
  UserImageAssetRow copyWithCompanion(UserImageAssetsCompanion data) {
    return UserImageAssetRow(
      id: data.id.present ? data.id.value : this.id,
      createdAtUtcMs: data.createdAtUtcMs.present
          ? data.createdAtUtcMs.value
          : this.createdAtUtcMs,
      updatedAtUtcMs: data.updatedAtUtcMs.present
          ? data.updatedAtUtcMs.value
          : this.updatedAtUtcMs,
      rowRevision: data.rowRevision.present
          ? data.rowRevision.value
          : this.rowRevision,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
      deletedAtUtcMs: data.deletedAtUtcMs.present
          ? data.deletedAtUtcMs.value
          : this.deletedAtUtcMs,
      originalStorageKey: data.originalStorageKey.present
          ? data.originalStorageKey.value
          : this.originalStorageKey,
      previewStorageKey: data.previewStorageKey.present
          ? data.previewStorageKey.value
          : this.previewStorageKey,
      cropCenterX: data.cropCenterX.present
          ? data.cropCenterX.value
          : this.cropCenterX,
      cropCenterY: data.cropCenterY.present
          ? data.cropCenterY.value
          : this.cropCenterY,
      cropScale: data.cropScale.present ? data.cropScale.value : this.cropScale,
      cropRotation: data.cropRotation.present
          ? data.cropRotation.value
          : this.cropRotation,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserImageAssetRow(')
          ..write('id: $id, ')
          ..write('createdAtUtcMs: $createdAtUtcMs, ')
          ..write('updatedAtUtcMs: $updatedAtUtcMs, ')
          ..write('rowRevision: $rowRevision, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('deletedAtUtcMs: $deletedAtUtcMs, ')
          ..write('originalStorageKey: $originalStorageKey, ')
          ..write('previewStorageKey: $previewStorageKey, ')
          ..write('cropCenterX: $cropCenterX, ')
          ..write('cropCenterY: $cropCenterY, ')
          ..write('cropScale: $cropScale, ')
          ..write('cropRotation: $cropRotation')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAtUtcMs,
    updatedAtUtcMs,
    rowRevision,
    isDeleted,
    deletedAtUtcMs,
    originalStorageKey,
    previewStorageKey,
    cropCenterX,
    cropCenterY,
    cropScale,
    cropRotation,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserImageAssetRow &&
          other.id == this.id &&
          other.createdAtUtcMs == this.createdAtUtcMs &&
          other.updatedAtUtcMs == this.updatedAtUtcMs &&
          other.rowRevision == this.rowRevision &&
          other.isDeleted == this.isDeleted &&
          other.deletedAtUtcMs == this.deletedAtUtcMs &&
          other.originalStorageKey == this.originalStorageKey &&
          other.previewStorageKey == this.previewStorageKey &&
          other.cropCenterX == this.cropCenterX &&
          other.cropCenterY == this.cropCenterY &&
          other.cropScale == this.cropScale &&
          other.cropRotation == this.cropRotation);
}

class UserImageAssetsCompanion extends UpdateCompanion<UserImageAssetRow> {
  final Value<String> id;
  final Value<int> createdAtUtcMs;
  final Value<int> updatedAtUtcMs;
  final Value<int> rowRevision;
  final Value<bool> isDeleted;
  final Value<int?> deletedAtUtcMs;
  final Value<String> originalStorageKey;
  final Value<String> previewStorageKey;
  final Value<double> cropCenterX;
  final Value<double> cropCenterY;
  final Value<double> cropScale;
  final Value<double> cropRotation;
  final Value<int> rowid;
  const UserImageAssetsCompanion({
    this.id = const Value.absent(),
    this.createdAtUtcMs = const Value.absent(),
    this.updatedAtUtcMs = const Value.absent(),
    this.rowRevision = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.deletedAtUtcMs = const Value.absent(),
    this.originalStorageKey = const Value.absent(),
    this.previewStorageKey = const Value.absent(),
    this.cropCenterX = const Value.absent(),
    this.cropCenterY = const Value.absent(),
    this.cropScale = const Value.absent(),
    this.cropRotation = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UserImageAssetsCompanion.insert({
    required String id,
    required int createdAtUtcMs,
    required int updatedAtUtcMs,
    this.rowRevision = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.deletedAtUtcMs = const Value.absent(),
    required String originalStorageKey,
    required String previewStorageKey,
    required double cropCenterX,
    required double cropCenterY,
    required double cropScale,
    required double cropRotation,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAtUtcMs = Value(createdAtUtcMs),
       updatedAtUtcMs = Value(updatedAtUtcMs),
       originalStorageKey = Value(originalStorageKey),
       previewStorageKey = Value(previewStorageKey),
       cropCenterX = Value(cropCenterX),
       cropCenterY = Value(cropCenterY),
       cropScale = Value(cropScale),
       cropRotation = Value(cropRotation);
  static Insertable<UserImageAssetRow> custom({
    Expression<String>? id,
    Expression<int>? createdAtUtcMs,
    Expression<int>? updatedAtUtcMs,
    Expression<int>? rowRevision,
    Expression<bool>? isDeleted,
    Expression<int>? deletedAtUtcMs,
    Expression<String>? originalStorageKey,
    Expression<String>? previewStorageKey,
    Expression<double>? cropCenterX,
    Expression<double>? cropCenterY,
    Expression<double>? cropScale,
    Expression<double>? cropRotation,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAtUtcMs != null) 'created_at_utc_ms': createdAtUtcMs,
      if (updatedAtUtcMs != null) 'updated_at_utc_ms': updatedAtUtcMs,
      if (rowRevision != null) 'row_revision': rowRevision,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (deletedAtUtcMs != null) 'deleted_at_utc_ms': deletedAtUtcMs,
      if (originalStorageKey != null)
        'original_storage_key': originalStorageKey,
      if (previewStorageKey != null) 'preview_storage_key': previewStorageKey,
      if (cropCenterX != null) 'crop_center_x': cropCenterX,
      if (cropCenterY != null) 'crop_center_y': cropCenterY,
      if (cropScale != null) 'crop_scale': cropScale,
      if (cropRotation != null) 'crop_rotation': cropRotation,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UserImageAssetsCompanion copyWith({
    Value<String>? id,
    Value<int>? createdAtUtcMs,
    Value<int>? updatedAtUtcMs,
    Value<int>? rowRevision,
    Value<bool>? isDeleted,
    Value<int?>? deletedAtUtcMs,
    Value<String>? originalStorageKey,
    Value<String>? previewStorageKey,
    Value<double>? cropCenterX,
    Value<double>? cropCenterY,
    Value<double>? cropScale,
    Value<double>? cropRotation,
    Value<int>? rowid,
  }) {
    return UserImageAssetsCompanion(
      id: id ?? this.id,
      createdAtUtcMs: createdAtUtcMs ?? this.createdAtUtcMs,
      updatedAtUtcMs: updatedAtUtcMs ?? this.updatedAtUtcMs,
      rowRevision: rowRevision ?? this.rowRevision,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAtUtcMs: deletedAtUtcMs ?? this.deletedAtUtcMs,
      originalStorageKey: originalStorageKey ?? this.originalStorageKey,
      previewStorageKey: previewStorageKey ?? this.previewStorageKey,
      cropCenterX: cropCenterX ?? this.cropCenterX,
      cropCenterY: cropCenterY ?? this.cropCenterY,
      cropScale: cropScale ?? this.cropScale,
      cropRotation: cropRotation ?? this.cropRotation,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAtUtcMs.present) {
      map['created_at_utc_ms'] = Variable<int>(createdAtUtcMs.value);
    }
    if (updatedAtUtcMs.present) {
      map['updated_at_utc_ms'] = Variable<int>(updatedAtUtcMs.value);
    }
    if (rowRevision.present) {
      map['row_revision'] = Variable<int>(rowRevision.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (deletedAtUtcMs.present) {
      map['deleted_at_utc_ms'] = Variable<int>(deletedAtUtcMs.value);
    }
    if (originalStorageKey.present) {
      map['original_storage_key'] = Variable<String>(originalStorageKey.value);
    }
    if (previewStorageKey.present) {
      map['preview_storage_key'] = Variable<String>(previewStorageKey.value);
    }
    if (cropCenterX.present) {
      map['crop_center_x'] = Variable<double>(cropCenterX.value);
    }
    if (cropCenterY.present) {
      map['crop_center_y'] = Variable<double>(cropCenterY.value);
    }
    if (cropScale.present) {
      map['crop_scale'] = Variable<double>(cropScale.value);
    }
    if (cropRotation.present) {
      map['crop_rotation'] = Variable<double>(cropRotation.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserImageAssetsCompanion(')
          ..write('id: $id, ')
          ..write('createdAtUtcMs: $createdAtUtcMs, ')
          ..write('updatedAtUtcMs: $updatedAtUtcMs, ')
          ..write('rowRevision: $rowRevision, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('deletedAtUtcMs: $deletedAtUtcMs, ')
          ..write('originalStorageKey: $originalStorageKey, ')
          ..write('previewStorageKey: $previewStorageKey, ')
          ..write('cropCenterX: $cropCenterX, ')
          ..write('cropCenterY: $cropCenterY, ')
          ..write('cropScale: $cropScale, ')
          ..write('cropRotation: $cropRotation, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $AppSettingsEntriesTable appSettingsEntries =
      $AppSettingsEntriesTable(this);
  late final $UserImageAssetsTable userImageAssets = $UserImageAssetsTable(
    this,
  );
  late final AppSettingsDao appSettingsDao = AppSettingsDao(
    this as AppDatabase,
  );
  late final UserImageAssetsDao userImageAssetsDao = UserImageAssetsDao(
    this as AppDatabase,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    appSettingsEntries,
    userImageAssets,
  ];
}

typedef $$AppSettingsEntriesTableCreateCompanionBuilder =
    AppSettingsEntriesCompanion Function({
      required String id,
      required int createdAtUtcMs,
      required int updatedAtUtcMs,
      Value<int> rowRevision,
      Value<bool> isDeleted,
      Value<int?> deletedAtUtcMs,
      Value<String?> activeSceneId,
      Value<int> brightnessPermille,
      Value<int> rowid,
    });
typedef $$AppSettingsEntriesTableUpdateCompanionBuilder =
    AppSettingsEntriesCompanion Function({
      Value<String> id,
      Value<int> createdAtUtcMs,
      Value<int> updatedAtUtcMs,
      Value<int> rowRevision,
      Value<bool> isDeleted,
      Value<int?> deletedAtUtcMs,
      Value<String?> activeSceneId,
      Value<int> brightnessPermille,
      Value<int> rowid,
    });

class $$AppSettingsEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $AppSettingsEntriesTable> {
  $$AppSettingsEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAtUtcMs => $composableBuilder(
    column: $table.createdAtUtcMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAtUtcMs => $composableBuilder(
    column: $table.updatedAtUtcMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rowRevision => $composableBuilder(
    column: $table.rowRevision,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAtUtcMs => $composableBuilder(
    column: $table.deletedAtUtcMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get activeSceneId => $composableBuilder(
    column: $table.activeSceneId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get brightnessPermille => $composableBuilder(
    column: $table.brightnessPermille,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppSettingsEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $AppSettingsEntriesTable> {
  $$AppSettingsEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAtUtcMs => $composableBuilder(
    column: $table.createdAtUtcMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAtUtcMs => $composableBuilder(
    column: $table.updatedAtUtcMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rowRevision => $composableBuilder(
    column: $table.rowRevision,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAtUtcMs => $composableBuilder(
    column: $table.deletedAtUtcMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get activeSceneId => $composableBuilder(
    column: $table.activeSceneId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get brightnessPermille => $composableBuilder(
    column: $table.brightnessPermille,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppSettingsEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppSettingsEntriesTable> {
  $$AppSettingsEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get createdAtUtcMs => $composableBuilder(
    column: $table.createdAtUtcMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get updatedAtUtcMs => $composableBuilder(
    column: $table.updatedAtUtcMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get rowRevision => $composableBuilder(
    column: $table.rowRevision,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  GeneratedColumn<int> get deletedAtUtcMs => $composableBuilder(
    column: $table.deletedAtUtcMs,
    builder: (column) => column,
  );

  GeneratedColumn<String> get activeSceneId => $composableBuilder(
    column: $table.activeSceneId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get brightnessPermille => $composableBuilder(
    column: $table.brightnessPermille,
    builder: (column) => column,
  );
}

class $$AppSettingsEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppSettingsEntriesTable,
          AppSettingsRow,
          $$AppSettingsEntriesTableFilterComposer,
          $$AppSettingsEntriesTableOrderingComposer,
          $$AppSettingsEntriesTableAnnotationComposer,
          $$AppSettingsEntriesTableCreateCompanionBuilder,
          $$AppSettingsEntriesTableUpdateCompanionBuilder,
          (
            AppSettingsRow,
            BaseReferences<
              _$AppDatabase,
              $AppSettingsEntriesTable,
              AppSettingsRow
            >,
          ),
          AppSettingsRow,
          PrefetchHooks Function()
        > {
  $$AppSettingsEntriesTableTableManager(
    _$AppDatabase db,
    $AppSettingsEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppSettingsEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppSettingsEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppSettingsEntriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> createdAtUtcMs = const Value.absent(),
                Value<int> updatedAtUtcMs = const Value.absent(),
                Value<int> rowRevision = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<int?> deletedAtUtcMs = const Value.absent(),
                Value<String?> activeSceneId = const Value.absent(),
                Value<int> brightnessPermille = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AppSettingsEntriesCompanion(
                id: id,
                createdAtUtcMs: createdAtUtcMs,
                updatedAtUtcMs: updatedAtUtcMs,
                rowRevision: rowRevision,
                isDeleted: isDeleted,
                deletedAtUtcMs: deletedAtUtcMs,
                activeSceneId: activeSceneId,
                brightnessPermille: brightnessPermille,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int createdAtUtcMs,
                required int updatedAtUtcMs,
                Value<int> rowRevision = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<int?> deletedAtUtcMs = const Value.absent(),
                Value<String?> activeSceneId = const Value.absent(),
                Value<int> brightnessPermille = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AppSettingsEntriesCompanion.insert(
                id: id,
                createdAtUtcMs: createdAtUtcMs,
                updatedAtUtcMs: updatedAtUtcMs,
                rowRevision: rowRevision,
                isDeleted: isDeleted,
                deletedAtUtcMs: deletedAtUtcMs,
                activeSceneId: activeSceneId,
                brightnessPermille: brightnessPermille,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppSettingsEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppSettingsEntriesTable,
      AppSettingsRow,
      $$AppSettingsEntriesTableFilterComposer,
      $$AppSettingsEntriesTableOrderingComposer,
      $$AppSettingsEntriesTableAnnotationComposer,
      $$AppSettingsEntriesTableCreateCompanionBuilder,
      $$AppSettingsEntriesTableUpdateCompanionBuilder,
      (
        AppSettingsRow,
        BaseReferences<_$AppDatabase, $AppSettingsEntriesTable, AppSettingsRow>,
      ),
      AppSettingsRow,
      PrefetchHooks Function()
    >;
typedef $$UserImageAssetsTableCreateCompanionBuilder =
    UserImageAssetsCompanion Function({
      required String id,
      required int createdAtUtcMs,
      required int updatedAtUtcMs,
      Value<int> rowRevision,
      Value<bool> isDeleted,
      Value<int?> deletedAtUtcMs,
      required String originalStorageKey,
      required String previewStorageKey,
      required double cropCenterX,
      required double cropCenterY,
      required double cropScale,
      required double cropRotation,
      Value<int> rowid,
    });
typedef $$UserImageAssetsTableUpdateCompanionBuilder =
    UserImageAssetsCompanion Function({
      Value<String> id,
      Value<int> createdAtUtcMs,
      Value<int> updatedAtUtcMs,
      Value<int> rowRevision,
      Value<bool> isDeleted,
      Value<int?> deletedAtUtcMs,
      Value<String> originalStorageKey,
      Value<String> previewStorageKey,
      Value<double> cropCenterX,
      Value<double> cropCenterY,
      Value<double> cropScale,
      Value<double> cropRotation,
      Value<int> rowid,
    });

class $$UserImageAssetsTableFilterComposer
    extends Composer<_$AppDatabase, $UserImageAssetsTable> {
  $$UserImageAssetsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAtUtcMs => $composableBuilder(
    column: $table.createdAtUtcMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAtUtcMs => $composableBuilder(
    column: $table.updatedAtUtcMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rowRevision => $composableBuilder(
    column: $table.rowRevision,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAtUtcMs => $composableBuilder(
    column: $table.deletedAtUtcMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get originalStorageKey => $composableBuilder(
    column: $table.originalStorageKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get previewStorageKey => $composableBuilder(
    column: $table.previewStorageKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get cropCenterX => $composableBuilder(
    column: $table.cropCenterX,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get cropCenterY => $composableBuilder(
    column: $table.cropCenterY,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get cropScale => $composableBuilder(
    column: $table.cropScale,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get cropRotation => $composableBuilder(
    column: $table.cropRotation,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UserImageAssetsTableOrderingComposer
    extends Composer<_$AppDatabase, $UserImageAssetsTable> {
  $$UserImageAssetsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAtUtcMs => $composableBuilder(
    column: $table.createdAtUtcMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAtUtcMs => $composableBuilder(
    column: $table.updatedAtUtcMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rowRevision => $composableBuilder(
    column: $table.rowRevision,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAtUtcMs => $composableBuilder(
    column: $table.deletedAtUtcMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get originalStorageKey => $composableBuilder(
    column: $table.originalStorageKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get previewStorageKey => $composableBuilder(
    column: $table.previewStorageKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get cropCenterX => $composableBuilder(
    column: $table.cropCenterX,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get cropCenterY => $composableBuilder(
    column: $table.cropCenterY,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get cropScale => $composableBuilder(
    column: $table.cropScale,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get cropRotation => $composableBuilder(
    column: $table.cropRotation,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UserImageAssetsTableAnnotationComposer
    extends Composer<_$AppDatabase, $UserImageAssetsTable> {
  $$UserImageAssetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get createdAtUtcMs => $composableBuilder(
    column: $table.createdAtUtcMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get updatedAtUtcMs => $composableBuilder(
    column: $table.updatedAtUtcMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get rowRevision => $composableBuilder(
    column: $table.rowRevision,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  GeneratedColumn<int> get deletedAtUtcMs => $composableBuilder(
    column: $table.deletedAtUtcMs,
    builder: (column) => column,
  );

  GeneratedColumn<String> get originalStorageKey => $composableBuilder(
    column: $table.originalStorageKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get previewStorageKey => $composableBuilder(
    column: $table.previewStorageKey,
    builder: (column) => column,
  );

  GeneratedColumn<double> get cropCenterX => $composableBuilder(
    column: $table.cropCenterX,
    builder: (column) => column,
  );

  GeneratedColumn<double> get cropCenterY => $composableBuilder(
    column: $table.cropCenterY,
    builder: (column) => column,
  );

  GeneratedColumn<double> get cropScale =>
      $composableBuilder(column: $table.cropScale, builder: (column) => column);

  GeneratedColumn<double> get cropRotation => $composableBuilder(
    column: $table.cropRotation,
    builder: (column) => column,
  );
}

class $$UserImageAssetsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UserImageAssetsTable,
          UserImageAssetRow,
          $$UserImageAssetsTableFilterComposer,
          $$UserImageAssetsTableOrderingComposer,
          $$UserImageAssetsTableAnnotationComposer,
          $$UserImageAssetsTableCreateCompanionBuilder,
          $$UserImageAssetsTableUpdateCompanionBuilder,
          (
            UserImageAssetRow,
            BaseReferences<
              _$AppDatabase,
              $UserImageAssetsTable,
              UserImageAssetRow
            >,
          ),
          UserImageAssetRow,
          PrefetchHooks Function()
        > {
  $$UserImageAssetsTableTableManager(
    _$AppDatabase db,
    $UserImageAssetsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserImageAssetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserImageAssetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UserImageAssetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> createdAtUtcMs = const Value.absent(),
                Value<int> updatedAtUtcMs = const Value.absent(),
                Value<int> rowRevision = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<int?> deletedAtUtcMs = const Value.absent(),
                Value<String> originalStorageKey = const Value.absent(),
                Value<String> previewStorageKey = const Value.absent(),
                Value<double> cropCenterX = const Value.absent(),
                Value<double> cropCenterY = const Value.absent(),
                Value<double> cropScale = const Value.absent(),
                Value<double> cropRotation = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UserImageAssetsCompanion(
                id: id,
                createdAtUtcMs: createdAtUtcMs,
                updatedAtUtcMs: updatedAtUtcMs,
                rowRevision: rowRevision,
                isDeleted: isDeleted,
                deletedAtUtcMs: deletedAtUtcMs,
                originalStorageKey: originalStorageKey,
                previewStorageKey: previewStorageKey,
                cropCenterX: cropCenterX,
                cropCenterY: cropCenterY,
                cropScale: cropScale,
                cropRotation: cropRotation,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int createdAtUtcMs,
                required int updatedAtUtcMs,
                Value<int> rowRevision = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<int?> deletedAtUtcMs = const Value.absent(),
                required String originalStorageKey,
                required String previewStorageKey,
                required double cropCenterX,
                required double cropCenterY,
                required double cropScale,
                required double cropRotation,
                Value<int> rowid = const Value.absent(),
              }) => UserImageAssetsCompanion.insert(
                id: id,
                createdAtUtcMs: createdAtUtcMs,
                updatedAtUtcMs: updatedAtUtcMs,
                rowRevision: rowRevision,
                isDeleted: isDeleted,
                deletedAtUtcMs: deletedAtUtcMs,
                originalStorageKey: originalStorageKey,
                previewStorageKey: previewStorageKey,
                cropCenterX: cropCenterX,
                cropCenterY: cropCenterY,
                cropScale: cropScale,
                cropRotation: cropRotation,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UserImageAssetsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UserImageAssetsTable,
      UserImageAssetRow,
      $$UserImageAssetsTableFilterComposer,
      $$UserImageAssetsTableOrderingComposer,
      $$UserImageAssetsTableAnnotationComposer,
      $$UserImageAssetsTableCreateCompanionBuilder,
      $$UserImageAssetsTableUpdateCompanionBuilder,
      (
        UserImageAssetRow,
        BaseReferences<_$AppDatabase, $UserImageAssetsTable, UserImageAssetRow>,
      ),
      UserImageAssetRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$AppSettingsEntriesTableTableManager get appSettingsEntries =>
      $$AppSettingsEntriesTableTableManager(_db, _db.appSettingsEntries);
  $$UserImageAssetsTableTableManager get userImageAssets =>
      $$UserImageAssetsTableTableManager(_db, _db.userImageAssets);
}
