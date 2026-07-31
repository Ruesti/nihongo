// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mining_db.dart';

// ignore_for_file: type=lint
class $WorksTable extends Works with TableInfo<$WorksTable, Work> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WorksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mediumMeta = const VerificationMeta('medium');
  @override
  late final GeneratedColumn<String> medium = GeneratedColumn<String>(
    'medium',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _languageCodeMeta = const VerificationMeta(
    'languageCode',
  );
  @override
  late final GeneratedColumn<String> languageCode = GeneratedColumn<String>(
    'language_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _addedAtMeta = const VerificationMeta(
    'addedAt',
  );
  @override
  late final GeneratedColumn<DateTime> addedAt = GeneratedColumn<DateTime>(
    'added_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    medium,
    languageCode,
    addedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'works';
  @override
  VerificationContext validateIntegrity(
    Insertable<Work> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('medium')) {
      context.handle(
        _mediumMeta,
        medium.isAcceptableOrUnknown(data['medium']!, _mediumMeta),
      );
    } else if (isInserting) {
      context.missing(_mediumMeta);
    }
    if (data.containsKey('language_code')) {
      context.handle(
        _languageCodeMeta,
        languageCode.isAcceptableOrUnknown(
          data['language_code']!,
          _languageCodeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_languageCodeMeta);
    }
    if (data.containsKey('added_at')) {
      context.handle(
        _addedAtMeta,
        addedAt.isAcceptableOrUnknown(data['added_at']!, _addedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_addedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Work map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Work(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      medium: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}medium'],
      )!,
      languageCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}language_code'],
      )!,
      addedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}added_at'],
      )!,
    );
  }

  @override
  $WorksTable createAlias(String alias) {
    return $WorksTable(attachedDatabase, alias);
  }
}

class Work extends DataClass implements Insertable<Work> {
  final String id;
  final String title;
  final String medium;
  final String languageCode;
  final DateTime addedAt;
  const Work({
    required this.id,
    required this.title,
    required this.medium,
    required this.languageCode,
    required this.addedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    map['medium'] = Variable<String>(medium);
    map['language_code'] = Variable<String>(languageCode);
    map['added_at'] = Variable<DateTime>(addedAt);
    return map;
  }

  WorksCompanion toCompanion(bool nullToAbsent) {
    return WorksCompanion(
      id: Value(id),
      title: Value(title),
      medium: Value(medium),
      languageCode: Value(languageCode),
      addedAt: Value(addedAt),
    );
  }

  factory Work.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Work(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      medium: serializer.fromJson<String>(json['medium']),
      languageCode: serializer.fromJson<String>(json['languageCode']),
      addedAt: serializer.fromJson<DateTime>(json['addedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'medium': serializer.toJson<String>(medium),
      'languageCode': serializer.toJson<String>(languageCode),
      'addedAt': serializer.toJson<DateTime>(addedAt),
    };
  }

  Work copyWith({
    String? id,
    String? title,
    String? medium,
    String? languageCode,
    DateTime? addedAt,
  }) => Work(
    id: id ?? this.id,
    title: title ?? this.title,
    medium: medium ?? this.medium,
    languageCode: languageCode ?? this.languageCode,
    addedAt: addedAt ?? this.addedAt,
  );
  Work copyWithCompanion(WorksCompanion data) {
    return Work(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      medium: data.medium.present ? data.medium.value : this.medium,
      languageCode: data.languageCode.present
          ? data.languageCode.value
          : this.languageCode,
      addedAt: data.addedAt.present ? data.addedAt.value : this.addedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Work(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('medium: $medium, ')
          ..write('languageCode: $languageCode, ')
          ..write('addedAt: $addedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, title, medium, languageCode, addedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Work &&
          other.id == this.id &&
          other.title == this.title &&
          other.medium == this.medium &&
          other.languageCode == this.languageCode &&
          other.addedAt == this.addedAt);
}

class WorksCompanion extends UpdateCompanion<Work> {
  final Value<String> id;
  final Value<String> title;
  final Value<String> medium;
  final Value<String> languageCode;
  final Value<DateTime> addedAt;
  final Value<int> rowid;
  const WorksCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.medium = const Value.absent(),
    this.languageCode = const Value.absent(),
    this.addedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WorksCompanion.insert({
    required String id,
    required String title,
    required String medium,
    required String languageCode,
    required DateTime addedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       medium = Value(medium),
       languageCode = Value(languageCode),
       addedAt = Value(addedAt);
  static Insertable<Work> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? medium,
    Expression<String>? languageCode,
    Expression<DateTime>? addedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (medium != null) 'medium': medium,
      if (languageCode != null) 'language_code': languageCode,
      if (addedAt != null) 'added_at': addedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WorksCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<String>? medium,
    Value<String>? languageCode,
    Value<DateTime>? addedAt,
    Value<int>? rowid,
  }) {
    return WorksCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      medium: medium ?? this.medium,
      languageCode: languageCode ?? this.languageCode,
      addedAt: addedAt ?? this.addedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (medium.present) {
      map['medium'] = Variable<String>(medium.value);
    }
    if (languageCode.present) {
      map['language_code'] = Variable<String>(languageCode.value);
    }
    if (addedAt.present) {
      map['added_at'] = Variable<DateTime>(addedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorksCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('medium: $medium, ')
          ..write('languageCode: $languageCode, ')
          ..write('addedAt: $addedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SourcesTable extends Sources with TableInfo<$SourcesTable, Source> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SourcesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _workIdMeta = const VerificationMeta('workId');
  @override
  late final GeneratedColumn<String> workId = GeneratedColumn<String>(
    'work_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES works (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pathMeta = const VerificationMeta('path');
  @override
  late final GeneratedColumn<String> path = GeneratedColumn<String>(
    'path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _importedAtMeta = const VerificationMeta(
    'importedAt',
  );
  @override
  late final GeneratedColumn<DateTime> importedAt = GeneratedColumn<DateTime>(
    'imported_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, workId, kind, path, importedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sources';
  @override
  VerificationContext validateIntegrity(
    Insertable<Source> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('work_id')) {
      context.handle(
        _workIdMeta,
        workId.isAcceptableOrUnknown(data['work_id']!, _workIdMeta),
      );
    } else if (isInserting) {
      context.missing(_workIdMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('path')) {
      context.handle(
        _pathMeta,
        path.isAcceptableOrUnknown(data['path']!, _pathMeta),
      );
    } else if (isInserting) {
      context.missing(_pathMeta);
    }
    if (data.containsKey('imported_at')) {
      context.handle(
        _importedAtMeta,
        importedAt.isAcceptableOrUnknown(data['imported_at']!, _importedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_importedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Source map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Source(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      workId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}work_id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      path: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}path'],
      )!,
      importedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}imported_at'],
      )!,
    );
  }

  @override
  $SourcesTable createAlias(String alias) {
    return $SourcesTable(attachedDatabase, alias);
  }
}

class Source extends DataClass implements Insertable<Source> {
  final String id;
  final String workId;
  final String kind;
  final String path;
  final DateTime importedAt;
  const Source({
    required this.id,
    required this.workId,
    required this.kind,
    required this.path,
    required this.importedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['work_id'] = Variable<String>(workId);
    map['kind'] = Variable<String>(kind);
    map['path'] = Variable<String>(path);
    map['imported_at'] = Variable<DateTime>(importedAt);
    return map;
  }

  SourcesCompanion toCompanion(bool nullToAbsent) {
    return SourcesCompanion(
      id: Value(id),
      workId: Value(workId),
      kind: Value(kind),
      path: Value(path),
      importedAt: Value(importedAt),
    );
  }

  factory Source.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Source(
      id: serializer.fromJson<String>(json['id']),
      workId: serializer.fromJson<String>(json['workId']),
      kind: serializer.fromJson<String>(json['kind']),
      path: serializer.fromJson<String>(json['path']),
      importedAt: serializer.fromJson<DateTime>(json['importedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'workId': serializer.toJson<String>(workId),
      'kind': serializer.toJson<String>(kind),
      'path': serializer.toJson<String>(path),
      'importedAt': serializer.toJson<DateTime>(importedAt),
    };
  }

  Source copyWith({
    String? id,
    String? workId,
    String? kind,
    String? path,
    DateTime? importedAt,
  }) => Source(
    id: id ?? this.id,
    workId: workId ?? this.workId,
    kind: kind ?? this.kind,
    path: path ?? this.path,
    importedAt: importedAt ?? this.importedAt,
  );
  Source copyWithCompanion(SourcesCompanion data) {
    return Source(
      id: data.id.present ? data.id.value : this.id,
      workId: data.workId.present ? data.workId.value : this.workId,
      kind: data.kind.present ? data.kind.value : this.kind,
      path: data.path.present ? data.path.value : this.path,
      importedAt: data.importedAt.present
          ? data.importedAt.value
          : this.importedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Source(')
          ..write('id: $id, ')
          ..write('workId: $workId, ')
          ..write('kind: $kind, ')
          ..write('path: $path, ')
          ..write('importedAt: $importedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, workId, kind, path, importedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Source &&
          other.id == this.id &&
          other.workId == this.workId &&
          other.kind == this.kind &&
          other.path == this.path &&
          other.importedAt == this.importedAt);
}

class SourcesCompanion extends UpdateCompanion<Source> {
  final Value<String> id;
  final Value<String> workId;
  final Value<String> kind;
  final Value<String> path;
  final Value<DateTime> importedAt;
  final Value<int> rowid;
  const SourcesCompanion({
    this.id = const Value.absent(),
    this.workId = const Value.absent(),
    this.kind = const Value.absent(),
    this.path = const Value.absent(),
    this.importedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SourcesCompanion.insert({
    required String id,
    required String workId,
    required String kind,
    required String path,
    required DateTime importedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       workId = Value(workId),
       kind = Value(kind),
       path = Value(path),
       importedAt = Value(importedAt);
  static Insertable<Source> custom({
    Expression<String>? id,
    Expression<String>? workId,
    Expression<String>? kind,
    Expression<String>? path,
    Expression<DateTime>? importedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (workId != null) 'work_id': workId,
      if (kind != null) 'kind': kind,
      if (path != null) 'path': path,
      if (importedAt != null) 'imported_at': importedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SourcesCompanion copyWith({
    Value<String>? id,
    Value<String>? workId,
    Value<String>? kind,
    Value<String>? path,
    Value<DateTime>? importedAt,
    Value<int>? rowid,
  }) {
    return SourcesCompanion(
      id: id ?? this.id,
      workId: workId ?? this.workId,
      kind: kind ?? this.kind,
      path: path ?? this.path,
      importedAt: importedAt ?? this.importedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (workId.present) {
      map['work_id'] = Variable<String>(workId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (path.present) {
      map['path'] = Variable<String>(path.value);
    }
    if (importedAt.present) {
      map['imported_at'] = Variable<DateTime>(importedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SourcesCompanion(')
          ..write('id: $id, ')
          ..write('workId: $workId, ')
          ..write('kind: $kind, ')
          ..write('path: $path, ')
          ..write('importedAt: $importedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TextSpansTable extends TextSpans
    with TableInfo<$TextSpansTable, TextSpan> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TextSpansTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _workIdMeta = const VerificationMeta('workId');
  @override
  late final GeneratedColumn<String> workId = GeneratedColumn<String>(
    'work_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES works (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _sourceIdMeta = const VerificationMeta(
    'sourceId',
  );
  @override
  late final GeneratedColumn<String> sourceId = GeneratedColumn<String>(
    'source_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES sources (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _ordinalMeta = const VerificationMeta(
    'ordinal',
  );
  @override
  late final GeneratedColumn<int> ordinal = GeneratedColumn<int>(
    'ordinal',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _anchorTypeMeta = const VerificationMeta(
    'anchorType',
  );
  @override
  late final GeneratedColumn<String> anchorType = GeneratedColumn<String>(
    'anchor_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _charStartMeta = const VerificationMeta(
    'charStart',
  );
  @override
  late final GeneratedColumn<int> charStart = GeneratedColumn<int>(
    'char_start',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _charEndMeta = const VerificationMeta(
    'charEnd',
  );
  @override
  late final GeneratedColumn<int> charEnd = GeneratedColumn<int>(
    'char_end',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tStartMsMeta = const VerificationMeta(
    'tStartMs',
  );
  @override
  late final GeneratedColumn<int> tStartMs = GeneratedColumn<int>(
    't_start_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tEndMsMeta = const VerificationMeta('tEndMs');
  @override
  late final GeneratedColumn<int> tEndMs = GeneratedColumn<int>(
    't_end_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pageIdMeta = const VerificationMeta('pageId');
  @override
  late final GeneratedColumn<String> pageId = GeneratedColumn<String>(
    'page_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rectJsonMeta = const VerificationMeta(
    'rectJson',
  );
  @override
  late final GeneratedColumn<String> rectJson = GeneratedColumn<String>(
    'rect_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    workId,
    sourceId,
    ordinal,
    content,
    anchorType,
    charStart,
    charEnd,
    tStartMs,
    tEndMs,
    pageId,
    rectJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'text_spans';
  @override
  VerificationContext validateIntegrity(
    Insertable<TextSpan> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('work_id')) {
      context.handle(
        _workIdMeta,
        workId.isAcceptableOrUnknown(data['work_id']!, _workIdMeta),
      );
    } else if (isInserting) {
      context.missing(_workIdMeta);
    }
    if (data.containsKey('source_id')) {
      context.handle(
        _sourceIdMeta,
        sourceId.isAcceptableOrUnknown(data['source_id']!, _sourceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceIdMeta);
    }
    if (data.containsKey('ordinal')) {
      context.handle(
        _ordinalMeta,
        ordinal.isAcceptableOrUnknown(data['ordinal']!, _ordinalMeta),
      );
    } else if (isInserting) {
      context.missing(_ordinalMeta);
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('anchor_type')) {
      context.handle(
        _anchorTypeMeta,
        anchorType.isAcceptableOrUnknown(data['anchor_type']!, _anchorTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_anchorTypeMeta);
    }
    if (data.containsKey('char_start')) {
      context.handle(
        _charStartMeta,
        charStart.isAcceptableOrUnknown(data['char_start']!, _charStartMeta),
      );
    }
    if (data.containsKey('char_end')) {
      context.handle(
        _charEndMeta,
        charEnd.isAcceptableOrUnknown(data['char_end']!, _charEndMeta),
      );
    }
    if (data.containsKey('t_start_ms')) {
      context.handle(
        _tStartMsMeta,
        tStartMs.isAcceptableOrUnknown(data['t_start_ms']!, _tStartMsMeta),
      );
    }
    if (data.containsKey('t_end_ms')) {
      context.handle(
        _tEndMsMeta,
        tEndMs.isAcceptableOrUnknown(data['t_end_ms']!, _tEndMsMeta),
      );
    }
    if (data.containsKey('page_id')) {
      context.handle(
        _pageIdMeta,
        pageId.isAcceptableOrUnknown(data['page_id']!, _pageIdMeta),
      );
    }
    if (data.containsKey('rect_json')) {
      context.handle(
        _rectJsonMeta,
        rectJson.isAcceptableOrUnknown(data['rect_json']!, _rectJsonMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TextSpan map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TextSpan(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      workId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}work_id'],
      )!,
      sourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_id'],
      )!,
      ordinal: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ordinal'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      anchorType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}anchor_type'],
      )!,
      charStart: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}char_start'],
      ),
      charEnd: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}char_end'],
      ),
      tStartMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}t_start_ms'],
      ),
      tEndMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}t_end_ms'],
      ),
      pageId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}page_id'],
      ),
      rectJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rect_json'],
      ),
    );
  }

  @override
  $TextSpansTable createAlias(String alias) {
    return $TextSpansTable(attachedDatabase, alias);
  }
}

class TextSpan extends DataClass implements Insertable<TextSpan> {
  final String id;
  final String workId;
  final String sourceId;
  final int ordinal;
  final String content;
  final String anchorType;
  final int? charStart;
  final int? charEnd;
  final int? tStartMs;
  final int? tEndMs;
  final String? pageId;
  final String? rectJson;
  const TextSpan({
    required this.id,
    required this.workId,
    required this.sourceId,
    required this.ordinal,
    required this.content,
    required this.anchorType,
    this.charStart,
    this.charEnd,
    this.tStartMs,
    this.tEndMs,
    this.pageId,
    this.rectJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['work_id'] = Variable<String>(workId);
    map['source_id'] = Variable<String>(sourceId);
    map['ordinal'] = Variable<int>(ordinal);
    map['content'] = Variable<String>(content);
    map['anchor_type'] = Variable<String>(anchorType);
    if (!nullToAbsent || charStart != null) {
      map['char_start'] = Variable<int>(charStart);
    }
    if (!nullToAbsent || charEnd != null) {
      map['char_end'] = Variable<int>(charEnd);
    }
    if (!nullToAbsent || tStartMs != null) {
      map['t_start_ms'] = Variable<int>(tStartMs);
    }
    if (!nullToAbsent || tEndMs != null) {
      map['t_end_ms'] = Variable<int>(tEndMs);
    }
    if (!nullToAbsent || pageId != null) {
      map['page_id'] = Variable<String>(pageId);
    }
    if (!nullToAbsent || rectJson != null) {
      map['rect_json'] = Variable<String>(rectJson);
    }
    return map;
  }

  TextSpansCompanion toCompanion(bool nullToAbsent) {
    return TextSpansCompanion(
      id: Value(id),
      workId: Value(workId),
      sourceId: Value(sourceId),
      ordinal: Value(ordinal),
      content: Value(content),
      anchorType: Value(anchorType),
      charStart: charStart == null && nullToAbsent
          ? const Value.absent()
          : Value(charStart),
      charEnd: charEnd == null && nullToAbsent
          ? const Value.absent()
          : Value(charEnd),
      tStartMs: tStartMs == null && nullToAbsent
          ? const Value.absent()
          : Value(tStartMs),
      tEndMs: tEndMs == null && nullToAbsent
          ? const Value.absent()
          : Value(tEndMs),
      pageId: pageId == null && nullToAbsent
          ? const Value.absent()
          : Value(pageId),
      rectJson: rectJson == null && nullToAbsent
          ? const Value.absent()
          : Value(rectJson),
    );
  }

  factory TextSpan.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TextSpan(
      id: serializer.fromJson<String>(json['id']),
      workId: serializer.fromJson<String>(json['workId']),
      sourceId: serializer.fromJson<String>(json['sourceId']),
      ordinal: serializer.fromJson<int>(json['ordinal']),
      content: serializer.fromJson<String>(json['content']),
      anchorType: serializer.fromJson<String>(json['anchorType']),
      charStart: serializer.fromJson<int?>(json['charStart']),
      charEnd: serializer.fromJson<int?>(json['charEnd']),
      tStartMs: serializer.fromJson<int?>(json['tStartMs']),
      tEndMs: serializer.fromJson<int?>(json['tEndMs']),
      pageId: serializer.fromJson<String?>(json['pageId']),
      rectJson: serializer.fromJson<String?>(json['rectJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'workId': serializer.toJson<String>(workId),
      'sourceId': serializer.toJson<String>(sourceId),
      'ordinal': serializer.toJson<int>(ordinal),
      'content': serializer.toJson<String>(content),
      'anchorType': serializer.toJson<String>(anchorType),
      'charStart': serializer.toJson<int?>(charStart),
      'charEnd': serializer.toJson<int?>(charEnd),
      'tStartMs': serializer.toJson<int?>(tStartMs),
      'tEndMs': serializer.toJson<int?>(tEndMs),
      'pageId': serializer.toJson<String?>(pageId),
      'rectJson': serializer.toJson<String?>(rectJson),
    };
  }

  TextSpan copyWith({
    String? id,
    String? workId,
    String? sourceId,
    int? ordinal,
    String? content,
    String? anchorType,
    Value<int?> charStart = const Value.absent(),
    Value<int?> charEnd = const Value.absent(),
    Value<int?> tStartMs = const Value.absent(),
    Value<int?> tEndMs = const Value.absent(),
    Value<String?> pageId = const Value.absent(),
    Value<String?> rectJson = const Value.absent(),
  }) => TextSpan(
    id: id ?? this.id,
    workId: workId ?? this.workId,
    sourceId: sourceId ?? this.sourceId,
    ordinal: ordinal ?? this.ordinal,
    content: content ?? this.content,
    anchorType: anchorType ?? this.anchorType,
    charStart: charStart.present ? charStart.value : this.charStart,
    charEnd: charEnd.present ? charEnd.value : this.charEnd,
    tStartMs: tStartMs.present ? tStartMs.value : this.tStartMs,
    tEndMs: tEndMs.present ? tEndMs.value : this.tEndMs,
    pageId: pageId.present ? pageId.value : this.pageId,
    rectJson: rectJson.present ? rectJson.value : this.rectJson,
  );
  TextSpan copyWithCompanion(TextSpansCompanion data) {
    return TextSpan(
      id: data.id.present ? data.id.value : this.id,
      workId: data.workId.present ? data.workId.value : this.workId,
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
      ordinal: data.ordinal.present ? data.ordinal.value : this.ordinal,
      content: data.content.present ? data.content.value : this.content,
      anchorType: data.anchorType.present
          ? data.anchorType.value
          : this.anchorType,
      charStart: data.charStart.present ? data.charStart.value : this.charStart,
      charEnd: data.charEnd.present ? data.charEnd.value : this.charEnd,
      tStartMs: data.tStartMs.present ? data.tStartMs.value : this.tStartMs,
      tEndMs: data.tEndMs.present ? data.tEndMs.value : this.tEndMs,
      pageId: data.pageId.present ? data.pageId.value : this.pageId,
      rectJson: data.rectJson.present ? data.rectJson.value : this.rectJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TextSpan(')
          ..write('id: $id, ')
          ..write('workId: $workId, ')
          ..write('sourceId: $sourceId, ')
          ..write('ordinal: $ordinal, ')
          ..write('content: $content, ')
          ..write('anchorType: $anchorType, ')
          ..write('charStart: $charStart, ')
          ..write('charEnd: $charEnd, ')
          ..write('tStartMs: $tStartMs, ')
          ..write('tEndMs: $tEndMs, ')
          ..write('pageId: $pageId, ')
          ..write('rectJson: $rectJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    workId,
    sourceId,
    ordinal,
    content,
    anchorType,
    charStart,
    charEnd,
    tStartMs,
    tEndMs,
    pageId,
    rectJson,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TextSpan &&
          other.id == this.id &&
          other.workId == this.workId &&
          other.sourceId == this.sourceId &&
          other.ordinal == this.ordinal &&
          other.content == this.content &&
          other.anchorType == this.anchorType &&
          other.charStart == this.charStart &&
          other.charEnd == this.charEnd &&
          other.tStartMs == this.tStartMs &&
          other.tEndMs == this.tEndMs &&
          other.pageId == this.pageId &&
          other.rectJson == this.rectJson);
}

class TextSpansCompanion extends UpdateCompanion<TextSpan> {
  final Value<String> id;
  final Value<String> workId;
  final Value<String> sourceId;
  final Value<int> ordinal;
  final Value<String> content;
  final Value<String> anchorType;
  final Value<int?> charStart;
  final Value<int?> charEnd;
  final Value<int?> tStartMs;
  final Value<int?> tEndMs;
  final Value<String?> pageId;
  final Value<String?> rectJson;
  final Value<int> rowid;
  const TextSpansCompanion({
    this.id = const Value.absent(),
    this.workId = const Value.absent(),
    this.sourceId = const Value.absent(),
    this.ordinal = const Value.absent(),
    this.content = const Value.absent(),
    this.anchorType = const Value.absent(),
    this.charStart = const Value.absent(),
    this.charEnd = const Value.absent(),
    this.tStartMs = const Value.absent(),
    this.tEndMs = const Value.absent(),
    this.pageId = const Value.absent(),
    this.rectJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TextSpansCompanion.insert({
    required String id,
    required String workId,
    required String sourceId,
    required int ordinal,
    required String content,
    required String anchorType,
    this.charStart = const Value.absent(),
    this.charEnd = const Value.absent(),
    this.tStartMs = const Value.absent(),
    this.tEndMs = const Value.absent(),
    this.pageId = const Value.absent(),
    this.rectJson = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       workId = Value(workId),
       sourceId = Value(sourceId),
       ordinal = Value(ordinal),
       content = Value(content),
       anchorType = Value(anchorType);
  static Insertable<TextSpan> custom({
    Expression<String>? id,
    Expression<String>? workId,
    Expression<String>? sourceId,
    Expression<int>? ordinal,
    Expression<String>? content,
    Expression<String>? anchorType,
    Expression<int>? charStart,
    Expression<int>? charEnd,
    Expression<int>? tStartMs,
    Expression<int>? tEndMs,
    Expression<String>? pageId,
    Expression<String>? rectJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (workId != null) 'work_id': workId,
      if (sourceId != null) 'source_id': sourceId,
      if (ordinal != null) 'ordinal': ordinal,
      if (content != null) 'content': content,
      if (anchorType != null) 'anchor_type': anchorType,
      if (charStart != null) 'char_start': charStart,
      if (charEnd != null) 'char_end': charEnd,
      if (tStartMs != null) 't_start_ms': tStartMs,
      if (tEndMs != null) 't_end_ms': tEndMs,
      if (pageId != null) 'page_id': pageId,
      if (rectJson != null) 'rect_json': rectJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TextSpansCompanion copyWith({
    Value<String>? id,
    Value<String>? workId,
    Value<String>? sourceId,
    Value<int>? ordinal,
    Value<String>? content,
    Value<String>? anchorType,
    Value<int?>? charStart,
    Value<int?>? charEnd,
    Value<int?>? tStartMs,
    Value<int?>? tEndMs,
    Value<String?>? pageId,
    Value<String?>? rectJson,
    Value<int>? rowid,
  }) {
    return TextSpansCompanion(
      id: id ?? this.id,
      workId: workId ?? this.workId,
      sourceId: sourceId ?? this.sourceId,
      ordinal: ordinal ?? this.ordinal,
      content: content ?? this.content,
      anchorType: anchorType ?? this.anchorType,
      charStart: charStart ?? this.charStart,
      charEnd: charEnd ?? this.charEnd,
      tStartMs: tStartMs ?? this.tStartMs,
      tEndMs: tEndMs ?? this.tEndMs,
      pageId: pageId ?? this.pageId,
      rectJson: rectJson ?? this.rectJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (workId.present) {
      map['work_id'] = Variable<String>(workId.value);
    }
    if (sourceId.present) {
      map['source_id'] = Variable<String>(sourceId.value);
    }
    if (ordinal.present) {
      map['ordinal'] = Variable<int>(ordinal.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (anchorType.present) {
      map['anchor_type'] = Variable<String>(anchorType.value);
    }
    if (charStart.present) {
      map['char_start'] = Variable<int>(charStart.value);
    }
    if (charEnd.present) {
      map['char_end'] = Variable<int>(charEnd.value);
    }
    if (tStartMs.present) {
      map['t_start_ms'] = Variable<int>(tStartMs.value);
    }
    if (tEndMs.present) {
      map['t_end_ms'] = Variable<int>(tEndMs.value);
    }
    if (pageId.present) {
      map['page_id'] = Variable<String>(pageId.value);
    }
    if (rectJson.present) {
      map['rect_json'] = Variable<String>(rectJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TextSpansCompanion(')
          ..write('id: $id, ')
          ..write('workId: $workId, ')
          ..write('sourceId: $sourceId, ')
          ..write('ordinal: $ordinal, ')
          ..write('content: $content, ')
          ..write('anchorType: $anchorType, ')
          ..write('charStart: $charStart, ')
          ..write('charEnd: $charEnd, ')
          ..write('tStartMs: $tStartMs, ')
          ..write('tEndMs: $tEndMs, ')
          ..write('pageId: $pageId, ')
          ..write('rectJson: $rectJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TokenOccurrencesTable extends TokenOccurrences
    with TableInfo<$TokenOccurrencesTable, TokenOccurrence> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TokenOccurrencesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _textSpanIdMeta = const VerificationMeta(
    'textSpanId',
  );
  @override
  late final GeneratedColumn<String> textSpanId = GeneratedColumn<String>(
    'text_span_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES text_spans (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _lemmaMeta = const VerificationMeta('lemma');
  @override
  late final GeneratedColumn<String> lemma = GeneratedColumn<String>(
    'lemma',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _surfaceMeta = const VerificationMeta(
    'surface',
  );
  @override
  late final GeneratedColumn<String> surface = GeneratedColumn<String>(
    'surface',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _readingMeta = const VerificationMeta(
    'reading',
  );
  @override
  late final GeneratedColumn<String> reading = GeneratedColumn<String>(
    'reading',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _posMeta = const VerificationMeta('pos');
  @override
  late final GeneratedColumn<String> pos = GeneratedColumn<String>(
    'pos',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _charStartMeta = const VerificationMeta(
    'charStart',
  );
  @override
  late final GeneratedColumn<int> charStart = GeneratedColumn<int>(
    'char_start',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _charEndMeta = const VerificationMeta(
    'charEnd',
  );
  @override
  late final GeneratedColumn<int> charEnd = GeneratedColumn<int>(
    'char_end',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    textSpanId,
    lemma,
    surface,
    reading,
    pos,
    charStart,
    charEnd,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'token_occurrences';
  @override
  VerificationContext validateIntegrity(
    Insertable<TokenOccurrence> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('text_span_id')) {
      context.handle(
        _textSpanIdMeta,
        textSpanId.isAcceptableOrUnknown(
          data['text_span_id']!,
          _textSpanIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_textSpanIdMeta);
    }
    if (data.containsKey('lemma')) {
      context.handle(
        _lemmaMeta,
        lemma.isAcceptableOrUnknown(data['lemma']!, _lemmaMeta),
      );
    } else if (isInserting) {
      context.missing(_lemmaMeta);
    }
    if (data.containsKey('surface')) {
      context.handle(
        _surfaceMeta,
        surface.isAcceptableOrUnknown(data['surface']!, _surfaceMeta),
      );
    } else if (isInserting) {
      context.missing(_surfaceMeta);
    }
    if (data.containsKey('reading')) {
      context.handle(
        _readingMeta,
        reading.isAcceptableOrUnknown(data['reading']!, _readingMeta),
      );
    }
    if (data.containsKey('pos')) {
      context.handle(
        _posMeta,
        pos.isAcceptableOrUnknown(data['pos']!, _posMeta),
      );
    } else if (isInserting) {
      context.missing(_posMeta);
    }
    if (data.containsKey('char_start')) {
      context.handle(
        _charStartMeta,
        charStart.isAcceptableOrUnknown(data['char_start']!, _charStartMeta),
      );
    } else if (isInserting) {
      context.missing(_charStartMeta);
    }
    if (data.containsKey('char_end')) {
      context.handle(
        _charEndMeta,
        charEnd.isAcceptableOrUnknown(data['char_end']!, _charEndMeta),
      );
    } else if (isInserting) {
      context.missing(_charEndMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TokenOccurrence map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TokenOccurrence(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      textSpanId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}text_span_id'],
      )!,
      lemma: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lemma'],
      )!,
      surface: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}surface'],
      )!,
      reading: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reading'],
      ),
      pos: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pos'],
      )!,
      charStart: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}char_start'],
      )!,
      charEnd: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}char_end'],
      )!,
    );
  }

  @override
  $TokenOccurrencesTable createAlias(String alias) {
    return $TokenOccurrencesTable(attachedDatabase, alias);
  }
}

class TokenOccurrence extends DataClass implements Insertable<TokenOccurrence> {
  final String id;
  final String textSpanId;
  final String lemma;
  final String surface;
  final String? reading;
  final String pos;
  final int charStart;
  final int charEnd;
  const TokenOccurrence({
    required this.id,
    required this.textSpanId,
    required this.lemma,
    required this.surface,
    this.reading,
    required this.pos,
    required this.charStart,
    required this.charEnd,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['text_span_id'] = Variable<String>(textSpanId);
    map['lemma'] = Variable<String>(lemma);
    map['surface'] = Variable<String>(surface);
    if (!nullToAbsent || reading != null) {
      map['reading'] = Variable<String>(reading);
    }
    map['pos'] = Variable<String>(pos);
    map['char_start'] = Variable<int>(charStart);
    map['char_end'] = Variable<int>(charEnd);
    return map;
  }

  TokenOccurrencesCompanion toCompanion(bool nullToAbsent) {
    return TokenOccurrencesCompanion(
      id: Value(id),
      textSpanId: Value(textSpanId),
      lemma: Value(lemma),
      surface: Value(surface),
      reading: reading == null && nullToAbsent
          ? const Value.absent()
          : Value(reading),
      pos: Value(pos),
      charStart: Value(charStart),
      charEnd: Value(charEnd),
    );
  }

  factory TokenOccurrence.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TokenOccurrence(
      id: serializer.fromJson<String>(json['id']),
      textSpanId: serializer.fromJson<String>(json['textSpanId']),
      lemma: serializer.fromJson<String>(json['lemma']),
      surface: serializer.fromJson<String>(json['surface']),
      reading: serializer.fromJson<String?>(json['reading']),
      pos: serializer.fromJson<String>(json['pos']),
      charStart: serializer.fromJson<int>(json['charStart']),
      charEnd: serializer.fromJson<int>(json['charEnd']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'textSpanId': serializer.toJson<String>(textSpanId),
      'lemma': serializer.toJson<String>(lemma),
      'surface': serializer.toJson<String>(surface),
      'reading': serializer.toJson<String?>(reading),
      'pos': serializer.toJson<String>(pos),
      'charStart': serializer.toJson<int>(charStart),
      'charEnd': serializer.toJson<int>(charEnd),
    };
  }

  TokenOccurrence copyWith({
    String? id,
    String? textSpanId,
    String? lemma,
    String? surface,
    Value<String?> reading = const Value.absent(),
    String? pos,
    int? charStart,
    int? charEnd,
  }) => TokenOccurrence(
    id: id ?? this.id,
    textSpanId: textSpanId ?? this.textSpanId,
    lemma: lemma ?? this.lemma,
    surface: surface ?? this.surface,
    reading: reading.present ? reading.value : this.reading,
    pos: pos ?? this.pos,
    charStart: charStart ?? this.charStart,
    charEnd: charEnd ?? this.charEnd,
  );
  TokenOccurrence copyWithCompanion(TokenOccurrencesCompanion data) {
    return TokenOccurrence(
      id: data.id.present ? data.id.value : this.id,
      textSpanId: data.textSpanId.present
          ? data.textSpanId.value
          : this.textSpanId,
      lemma: data.lemma.present ? data.lemma.value : this.lemma,
      surface: data.surface.present ? data.surface.value : this.surface,
      reading: data.reading.present ? data.reading.value : this.reading,
      pos: data.pos.present ? data.pos.value : this.pos,
      charStart: data.charStart.present ? data.charStart.value : this.charStart,
      charEnd: data.charEnd.present ? data.charEnd.value : this.charEnd,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TokenOccurrence(')
          ..write('id: $id, ')
          ..write('textSpanId: $textSpanId, ')
          ..write('lemma: $lemma, ')
          ..write('surface: $surface, ')
          ..write('reading: $reading, ')
          ..write('pos: $pos, ')
          ..write('charStart: $charStart, ')
          ..write('charEnd: $charEnd')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    textSpanId,
    lemma,
    surface,
    reading,
    pos,
    charStart,
    charEnd,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TokenOccurrence &&
          other.id == this.id &&
          other.textSpanId == this.textSpanId &&
          other.lemma == this.lemma &&
          other.surface == this.surface &&
          other.reading == this.reading &&
          other.pos == this.pos &&
          other.charStart == this.charStart &&
          other.charEnd == this.charEnd);
}

class TokenOccurrencesCompanion extends UpdateCompanion<TokenOccurrence> {
  final Value<String> id;
  final Value<String> textSpanId;
  final Value<String> lemma;
  final Value<String> surface;
  final Value<String?> reading;
  final Value<String> pos;
  final Value<int> charStart;
  final Value<int> charEnd;
  final Value<int> rowid;
  const TokenOccurrencesCompanion({
    this.id = const Value.absent(),
    this.textSpanId = const Value.absent(),
    this.lemma = const Value.absent(),
    this.surface = const Value.absent(),
    this.reading = const Value.absent(),
    this.pos = const Value.absent(),
    this.charStart = const Value.absent(),
    this.charEnd = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TokenOccurrencesCompanion.insert({
    required String id,
    required String textSpanId,
    required String lemma,
    required String surface,
    this.reading = const Value.absent(),
    required String pos,
    required int charStart,
    required int charEnd,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       textSpanId = Value(textSpanId),
       lemma = Value(lemma),
       surface = Value(surface),
       pos = Value(pos),
       charStart = Value(charStart),
       charEnd = Value(charEnd);
  static Insertable<TokenOccurrence> custom({
    Expression<String>? id,
    Expression<String>? textSpanId,
    Expression<String>? lemma,
    Expression<String>? surface,
    Expression<String>? reading,
    Expression<String>? pos,
    Expression<int>? charStart,
    Expression<int>? charEnd,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (textSpanId != null) 'text_span_id': textSpanId,
      if (lemma != null) 'lemma': lemma,
      if (surface != null) 'surface': surface,
      if (reading != null) 'reading': reading,
      if (pos != null) 'pos': pos,
      if (charStart != null) 'char_start': charStart,
      if (charEnd != null) 'char_end': charEnd,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TokenOccurrencesCompanion copyWith({
    Value<String>? id,
    Value<String>? textSpanId,
    Value<String>? lemma,
    Value<String>? surface,
    Value<String?>? reading,
    Value<String>? pos,
    Value<int>? charStart,
    Value<int>? charEnd,
    Value<int>? rowid,
  }) {
    return TokenOccurrencesCompanion(
      id: id ?? this.id,
      textSpanId: textSpanId ?? this.textSpanId,
      lemma: lemma ?? this.lemma,
      surface: surface ?? this.surface,
      reading: reading ?? this.reading,
      pos: pos ?? this.pos,
      charStart: charStart ?? this.charStart,
      charEnd: charEnd ?? this.charEnd,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (textSpanId.present) {
      map['text_span_id'] = Variable<String>(textSpanId.value);
    }
    if (lemma.present) {
      map['lemma'] = Variable<String>(lemma.value);
    }
    if (surface.present) {
      map['surface'] = Variable<String>(surface.value);
    }
    if (reading.present) {
      map['reading'] = Variable<String>(reading.value);
    }
    if (pos.present) {
      map['pos'] = Variable<String>(pos.value);
    }
    if (charStart.present) {
      map['char_start'] = Variable<int>(charStart.value);
    }
    if (charEnd.present) {
      map['char_end'] = Variable<int>(charEnd.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TokenOccurrencesCompanion(')
          ..write('id: $id, ')
          ..write('textSpanId: $textSpanId, ')
          ..write('lemma: $lemma, ')
          ..write('surface: $surface, ')
          ..write('reading: $reading, ')
          ..write('pos: $pos, ')
          ..write('charStart: $charStart, ')
          ..write('charEnd: $charEnd, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $VocabItemsTable extends VocabItems
    with TableInfo<$VocabItemsTable, VocabItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VocabItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _languageCodeMeta = const VerificationMeta(
    'languageCode',
  );
  @override
  late final GeneratedColumn<String> languageCode = GeneratedColumn<String>(
    'language_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lemmaMeta = const VerificationMeta('lemma');
  @override
  late final GeneratedColumn<String> lemma = GeneratedColumn<String>(
    'lemma',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _posMeta = const VerificationMeta('pos');
  @override
  late final GeneratedColumn<String> pos = GeneratedColumn<String>(
    'pos',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    languageCode,
    lemma,
    pos,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'vocab_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<VocabItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('language_code')) {
      context.handle(
        _languageCodeMeta,
        languageCode.isAcceptableOrUnknown(
          data['language_code']!,
          _languageCodeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_languageCodeMeta);
    }
    if (data.containsKey('lemma')) {
      context.handle(
        _lemmaMeta,
        lemma.isAcceptableOrUnknown(data['lemma']!, _lemmaMeta),
      );
    } else if (isInserting) {
      context.missing(_lemmaMeta);
    }
    if (data.containsKey('pos')) {
      context.handle(
        _posMeta,
        pos.isAcceptableOrUnknown(data['pos']!, _posMeta),
      );
    } else if (isInserting) {
      context.missing(_posMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {languageCode, lemma, pos},
  ];
  @override
  VocabItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VocabItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      languageCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}language_code'],
      )!,
      lemma: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lemma'],
      )!,
      pos: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pos'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $VocabItemsTable createAlias(String alias) {
    return $VocabItemsTable(attachedDatabase, alias);
  }
}

class VocabItem extends DataClass implements Insertable<VocabItem> {
  final String id;
  final String languageCode;
  final String lemma;
  final String pos;
  final DateTime createdAt;
  const VocabItem({
    required this.id,
    required this.languageCode,
    required this.lemma,
    required this.pos,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['language_code'] = Variable<String>(languageCode);
    map['lemma'] = Variable<String>(lemma);
    map['pos'] = Variable<String>(pos);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  VocabItemsCompanion toCompanion(bool nullToAbsent) {
    return VocabItemsCompanion(
      id: Value(id),
      languageCode: Value(languageCode),
      lemma: Value(lemma),
      pos: Value(pos),
      createdAt: Value(createdAt),
    );
  }

  factory VocabItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VocabItem(
      id: serializer.fromJson<String>(json['id']),
      languageCode: serializer.fromJson<String>(json['languageCode']),
      lemma: serializer.fromJson<String>(json['lemma']),
      pos: serializer.fromJson<String>(json['pos']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'languageCode': serializer.toJson<String>(languageCode),
      'lemma': serializer.toJson<String>(lemma),
      'pos': serializer.toJson<String>(pos),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  VocabItem copyWith({
    String? id,
    String? languageCode,
    String? lemma,
    String? pos,
    DateTime? createdAt,
  }) => VocabItem(
    id: id ?? this.id,
    languageCode: languageCode ?? this.languageCode,
    lemma: lemma ?? this.lemma,
    pos: pos ?? this.pos,
    createdAt: createdAt ?? this.createdAt,
  );
  VocabItem copyWithCompanion(VocabItemsCompanion data) {
    return VocabItem(
      id: data.id.present ? data.id.value : this.id,
      languageCode: data.languageCode.present
          ? data.languageCode.value
          : this.languageCode,
      lemma: data.lemma.present ? data.lemma.value : this.lemma,
      pos: data.pos.present ? data.pos.value : this.pos,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VocabItem(')
          ..write('id: $id, ')
          ..write('languageCode: $languageCode, ')
          ..write('lemma: $lemma, ')
          ..write('pos: $pos, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, languageCode, lemma, pos, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VocabItem &&
          other.id == this.id &&
          other.languageCode == this.languageCode &&
          other.lemma == this.lemma &&
          other.pos == this.pos &&
          other.createdAt == this.createdAt);
}

class VocabItemsCompanion extends UpdateCompanion<VocabItem> {
  final Value<String> id;
  final Value<String> languageCode;
  final Value<String> lemma;
  final Value<String> pos;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const VocabItemsCompanion({
    this.id = const Value.absent(),
    this.languageCode = const Value.absent(),
    this.lemma = const Value.absent(),
    this.pos = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VocabItemsCompanion.insert({
    required String id,
    required String languageCode,
    required String lemma,
    required String pos,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       languageCode = Value(languageCode),
       lemma = Value(lemma),
       pos = Value(pos),
       createdAt = Value(createdAt);
  static Insertable<VocabItem> custom({
    Expression<String>? id,
    Expression<String>? languageCode,
    Expression<String>? lemma,
    Expression<String>? pos,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (languageCode != null) 'language_code': languageCode,
      if (lemma != null) 'lemma': lemma,
      if (pos != null) 'pos': pos,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  VocabItemsCompanion copyWith({
    Value<String>? id,
    Value<String>? languageCode,
    Value<String>? lemma,
    Value<String>? pos,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return VocabItemsCompanion(
      id: id ?? this.id,
      languageCode: languageCode ?? this.languageCode,
      lemma: lemma ?? this.lemma,
      pos: pos ?? this.pos,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (languageCode.present) {
      map['language_code'] = Variable<String>(languageCode.value);
    }
    if (lemma.present) {
      map['lemma'] = Variable<String>(lemma.value);
    }
    if (pos.present) {
      map['pos'] = Variable<String>(pos.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VocabItemsCompanion(')
          ..write('id: $id, ')
          ..write('languageCode: $languageCode, ')
          ..write('lemma: $lemma, ')
          ..write('pos: $pos, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CardsTable extends Cards with TableInfo<$CardsTable, Card> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CardsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _vocabItemIdMeta = const VerificationMeta(
    'vocabItemId',
  );
  @override
  late final GeneratedColumn<String> vocabItemId = GeneratedColumn<String>(
    'vocab_item_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'UNIQUE REFERENCES vocab_items (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _contextTextSpanIdMeta = const VerificationMeta(
    'contextTextSpanId',
  );
  @override
  late final GeneratedColumn<String> contextTextSpanId =
      GeneratedColumn<String>(
        'context_text_span_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES text_spans (id)',
        ),
      );
  static const VerificationMeta _stateMeta = const VerificationMeta('state');
  @override
  late final GeneratedColumn<String> state = GeneratedColumn<String>(
    'state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('newState'),
  );
  static const VerificationMeta _stabilityMeta = const VerificationMeta(
    'stability',
  );
  @override
  late final GeneratedColumn<double> stability = GeneratedColumn<double>(
    'stability',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _difficultyMeta = const VerificationMeta(
    'difficulty',
  );
  @override
  late final GeneratedColumn<double> difficulty = GeneratedColumn<double>(
    'difficulty',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _elapsedDaysMeta = const VerificationMeta(
    'elapsedDays',
  );
  @override
  late final GeneratedColumn<int> elapsedDays = GeneratedColumn<int>(
    'elapsed_days',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _scheduledDaysMeta = const VerificationMeta(
    'scheduledDays',
  );
  @override
  late final GeneratedColumn<int> scheduledDays = GeneratedColumn<int>(
    'scheduled_days',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _repsMeta = const VerificationMeta('reps');
  @override
  late final GeneratedColumn<int> reps = GeneratedColumn<int>(
    'reps',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lapsesMeta = const VerificationMeta('lapses');
  @override
  late final GeneratedColumn<int> lapses = GeneratedColumn<int>(
    'lapses',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _dueMeta = const VerificationMeta('due');
  @override
  late final GeneratedColumn<DateTime> due = GeneratedColumn<DateTime>(
    'due',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastReviewMeta = const VerificationMeta(
    'lastReview',
  );
  @override
  late final GeneratedColumn<DateTime> lastReview = GeneratedColumn<DateTime>(
    'last_review',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    vocabItemId,
    contextTextSpanId,
    state,
    stability,
    difficulty,
    elapsedDays,
    scheduledDays,
    reps,
    lapses,
    due,
    lastReview,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cards';
  @override
  VerificationContext validateIntegrity(
    Insertable<Card> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('vocab_item_id')) {
      context.handle(
        _vocabItemIdMeta,
        vocabItemId.isAcceptableOrUnknown(
          data['vocab_item_id']!,
          _vocabItemIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_vocabItemIdMeta);
    }
    if (data.containsKey('context_text_span_id')) {
      context.handle(
        _contextTextSpanIdMeta,
        contextTextSpanId.isAcceptableOrUnknown(
          data['context_text_span_id']!,
          _contextTextSpanIdMeta,
        ),
      );
    }
    if (data.containsKey('state')) {
      context.handle(
        _stateMeta,
        state.isAcceptableOrUnknown(data['state']!, _stateMeta),
      );
    }
    if (data.containsKey('stability')) {
      context.handle(
        _stabilityMeta,
        stability.isAcceptableOrUnknown(data['stability']!, _stabilityMeta),
      );
    }
    if (data.containsKey('difficulty')) {
      context.handle(
        _difficultyMeta,
        difficulty.isAcceptableOrUnknown(data['difficulty']!, _difficultyMeta),
      );
    }
    if (data.containsKey('elapsed_days')) {
      context.handle(
        _elapsedDaysMeta,
        elapsedDays.isAcceptableOrUnknown(
          data['elapsed_days']!,
          _elapsedDaysMeta,
        ),
      );
    }
    if (data.containsKey('scheduled_days')) {
      context.handle(
        _scheduledDaysMeta,
        scheduledDays.isAcceptableOrUnknown(
          data['scheduled_days']!,
          _scheduledDaysMeta,
        ),
      );
    }
    if (data.containsKey('reps')) {
      context.handle(
        _repsMeta,
        reps.isAcceptableOrUnknown(data['reps']!, _repsMeta),
      );
    }
    if (data.containsKey('lapses')) {
      context.handle(
        _lapsesMeta,
        lapses.isAcceptableOrUnknown(data['lapses']!, _lapsesMeta),
      );
    }
    if (data.containsKey('due')) {
      context.handle(
        _dueMeta,
        due.isAcceptableOrUnknown(data['due']!, _dueMeta),
      );
    } else if (isInserting) {
      context.missing(_dueMeta);
    }
    if (data.containsKey('last_review')) {
      context.handle(
        _lastReviewMeta,
        lastReview.isAcceptableOrUnknown(data['last_review']!, _lastReviewMeta),
      );
    } else if (isInserting) {
      context.missing(_lastReviewMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Card map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Card(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      vocabItemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}vocab_item_id'],
      )!,
      contextTextSpanId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}context_text_span_id'],
      ),
      state: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}state'],
      )!,
      stability: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}stability'],
      )!,
      difficulty: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}difficulty'],
      )!,
      elapsedDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}elapsed_days'],
      )!,
      scheduledDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}scheduled_days'],
      )!,
      reps: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reps'],
      )!,
      lapses: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}lapses'],
      )!,
      due: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}due'],
      )!,
      lastReview: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_review'],
      )!,
    );
  }

  @override
  $CardsTable createAlias(String alias) {
    return $CardsTable(attachedDatabase, alias);
  }
}

class Card extends DataClass implements Insertable<Card> {
  final String id;
  final String vocabItemId;
  final String? contextTextSpanId;
  final String state;
  final double stability;
  final double difficulty;
  final int elapsedDays;
  final int scheduledDays;
  final int reps;
  final int lapses;
  final DateTime due;
  final DateTime lastReview;
  const Card({
    required this.id,
    required this.vocabItemId,
    this.contextTextSpanId,
    required this.state,
    required this.stability,
    required this.difficulty,
    required this.elapsedDays,
    required this.scheduledDays,
    required this.reps,
    required this.lapses,
    required this.due,
    required this.lastReview,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['vocab_item_id'] = Variable<String>(vocabItemId);
    if (!nullToAbsent || contextTextSpanId != null) {
      map['context_text_span_id'] = Variable<String>(contextTextSpanId);
    }
    map['state'] = Variable<String>(state);
    map['stability'] = Variable<double>(stability);
    map['difficulty'] = Variable<double>(difficulty);
    map['elapsed_days'] = Variable<int>(elapsedDays);
    map['scheduled_days'] = Variable<int>(scheduledDays);
    map['reps'] = Variable<int>(reps);
    map['lapses'] = Variable<int>(lapses);
    map['due'] = Variable<DateTime>(due);
    map['last_review'] = Variable<DateTime>(lastReview);
    return map;
  }

  CardsCompanion toCompanion(bool nullToAbsent) {
    return CardsCompanion(
      id: Value(id),
      vocabItemId: Value(vocabItemId),
      contextTextSpanId: contextTextSpanId == null && nullToAbsent
          ? const Value.absent()
          : Value(contextTextSpanId),
      state: Value(state),
      stability: Value(stability),
      difficulty: Value(difficulty),
      elapsedDays: Value(elapsedDays),
      scheduledDays: Value(scheduledDays),
      reps: Value(reps),
      lapses: Value(lapses),
      due: Value(due),
      lastReview: Value(lastReview),
    );
  }

  factory Card.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Card(
      id: serializer.fromJson<String>(json['id']),
      vocabItemId: serializer.fromJson<String>(json['vocabItemId']),
      contextTextSpanId: serializer.fromJson<String?>(
        json['contextTextSpanId'],
      ),
      state: serializer.fromJson<String>(json['state']),
      stability: serializer.fromJson<double>(json['stability']),
      difficulty: serializer.fromJson<double>(json['difficulty']),
      elapsedDays: serializer.fromJson<int>(json['elapsedDays']),
      scheduledDays: serializer.fromJson<int>(json['scheduledDays']),
      reps: serializer.fromJson<int>(json['reps']),
      lapses: serializer.fromJson<int>(json['lapses']),
      due: serializer.fromJson<DateTime>(json['due']),
      lastReview: serializer.fromJson<DateTime>(json['lastReview']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'vocabItemId': serializer.toJson<String>(vocabItemId),
      'contextTextSpanId': serializer.toJson<String?>(contextTextSpanId),
      'state': serializer.toJson<String>(state),
      'stability': serializer.toJson<double>(stability),
      'difficulty': serializer.toJson<double>(difficulty),
      'elapsedDays': serializer.toJson<int>(elapsedDays),
      'scheduledDays': serializer.toJson<int>(scheduledDays),
      'reps': serializer.toJson<int>(reps),
      'lapses': serializer.toJson<int>(lapses),
      'due': serializer.toJson<DateTime>(due),
      'lastReview': serializer.toJson<DateTime>(lastReview),
    };
  }

  Card copyWith({
    String? id,
    String? vocabItemId,
    Value<String?> contextTextSpanId = const Value.absent(),
    String? state,
    double? stability,
    double? difficulty,
    int? elapsedDays,
    int? scheduledDays,
    int? reps,
    int? lapses,
    DateTime? due,
    DateTime? lastReview,
  }) => Card(
    id: id ?? this.id,
    vocabItemId: vocabItemId ?? this.vocabItemId,
    contextTextSpanId: contextTextSpanId.present
        ? contextTextSpanId.value
        : this.contextTextSpanId,
    state: state ?? this.state,
    stability: stability ?? this.stability,
    difficulty: difficulty ?? this.difficulty,
    elapsedDays: elapsedDays ?? this.elapsedDays,
    scheduledDays: scheduledDays ?? this.scheduledDays,
    reps: reps ?? this.reps,
    lapses: lapses ?? this.lapses,
    due: due ?? this.due,
    lastReview: lastReview ?? this.lastReview,
  );
  Card copyWithCompanion(CardsCompanion data) {
    return Card(
      id: data.id.present ? data.id.value : this.id,
      vocabItemId: data.vocabItemId.present
          ? data.vocabItemId.value
          : this.vocabItemId,
      contextTextSpanId: data.contextTextSpanId.present
          ? data.contextTextSpanId.value
          : this.contextTextSpanId,
      state: data.state.present ? data.state.value : this.state,
      stability: data.stability.present ? data.stability.value : this.stability,
      difficulty: data.difficulty.present
          ? data.difficulty.value
          : this.difficulty,
      elapsedDays: data.elapsedDays.present
          ? data.elapsedDays.value
          : this.elapsedDays,
      scheduledDays: data.scheduledDays.present
          ? data.scheduledDays.value
          : this.scheduledDays,
      reps: data.reps.present ? data.reps.value : this.reps,
      lapses: data.lapses.present ? data.lapses.value : this.lapses,
      due: data.due.present ? data.due.value : this.due,
      lastReview: data.lastReview.present
          ? data.lastReview.value
          : this.lastReview,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Card(')
          ..write('id: $id, ')
          ..write('vocabItemId: $vocabItemId, ')
          ..write('contextTextSpanId: $contextTextSpanId, ')
          ..write('state: $state, ')
          ..write('stability: $stability, ')
          ..write('difficulty: $difficulty, ')
          ..write('elapsedDays: $elapsedDays, ')
          ..write('scheduledDays: $scheduledDays, ')
          ..write('reps: $reps, ')
          ..write('lapses: $lapses, ')
          ..write('due: $due, ')
          ..write('lastReview: $lastReview')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    vocabItemId,
    contextTextSpanId,
    state,
    stability,
    difficulty,
    elapsedDays,
    scheduledDays,
    reps,
    lapses,
    due,
    lastReview,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Card &&
          other.id == this.id &&
          other.vocabItemId == this.vocabItemId &&
          other.contextTextSpanId == this.contextTextSpanId &&
          other.state == this.state &&
          other.stability == this.stability &&
          other.difficulty == this.difficulty &&
          other.elapsedDays == this.elapsedDays &&
          other.scheduledDays == this.scheduledDays &&
          other.reps == this.reps &&
          other.lapses == this.lapses &&
          other.due == this.due &&
          other.lastReview == this.lastReview);
}

class CardsCompanion extends UpdateCompanion<Card> {
  final Value<String> id;
  final Value<String> vocabItemId;
  final Value<String?> contextTextSpanId;
  final Value<String> state;
  final Value<double> stability;
  final Value<double> difficulty;
  final Value<int> elapsedDays;
  final Value<int> scheduledDays;
  final Value<int> reps;
  final Value<int> lapses;
  final Value<DateTime> due;
  final Value<DateTime> lastReview;
  final Value<int> rowid;
  const CardsCompanion({
    this.id = const Value.absent(),
    this.vocabItemId = const Value.absent(),
    this.contextTextSpanId = const Value.absent(),
    this.state = const Value.absent(),
    this.stability = const Value.absent(),
    this.difficulty = const Value.absent(),
    this.elapsedDays = const Value.absent(),
    this.scheduledDays = const Value.absent(),
    this.reps = const Value.absent(),
    this.lapses = const Value.absent(),
    this.due = const Value.absent(),
    this.lastReview = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CardsCompanion.insert({
    required String id,
    required String vocabItemId,
    this.contextTextSpanId = const Value.absent(),
    this.state = const Value.absent(),
    this.stability = const Value.absent(),
    this.difficulty = const Value.absent(),
    this.elapsedDays = const Value.absent(),
    this.scheduledDays = const Value.absent(),
    this.reps = const Value.absent(),
    this.lapses = const Value.absent(),
    required DateTime due,
    required DateTime lastReview,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       vocabItemId = Value(vocabItemId),
       due = Value(due),
       lastReview = Value(lastReview);
  static Insertable<Card> custom({
    Expression<String>? id,
    Expression<String>? vocabItemId,
    Expression<String>? contextTextSpanId,
    Expression<String>? state,
    Expression<double>? stability,
    Expression<double>? difficulty,
    Expression<int>? elapsedDays,
    Expression<int>? scheduledDays,
    Expression<int>? reps,
    Expression<int>? lapses,
    Expression<DateTime>? due,
    Expression<DateTime>? lastReview,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (vocabItemId != null) 'vocab_item_id': vocabItemId,
      if (contextTextSpanId != null) 'context_text_span_id': contextTextSpanId,
      if (state != null) 'state': state,
      if (stability != null) 'stability': stability,
      if (difficulty != null) 'difficulty': difficulty,
      if (elapsedDays != null) 'elapsed_days': elapsedDays,
      if (scheduledDays != null) 'scheduled_days': scheduledDays,
      if (reps != null) 'reps': reps,
      if (lapses != null) 'lapses': lapses,
      if (due != null) 'due': due,
      if (lastReview != null) 'last_review': lastReview,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CardsCompanion copyWith({
    Value<String>? id,
    Value<String>? vocabItemId,
    Value<String?>? contextTextSpanId,
    Value<String>? state,
    Value<double>? stability,
    Value<double>? difficulty,
    Value<int>? elapsedDays,
    Value<int>? scheduledDays,
    Value<int>? reps,
    Value<int>? lapses,
    Value<DateTime>? due,
    Value<DateTime>? lastReview,
    Value<int>? rowid,
  }) {
    return CardsCompanion(
      id: id ?? this.id,
      vocabItemId: vocabItemId ?? this.vocabItemId,
      contextTextSpanId: contextTextSpanId ?? this.contextTextSpanId,
      state: state ?? this.state,
      stability: stability ?? this.stability,
      difficulty: difficulty ?? this.difficulty,
      elapsedDays: elapsedDays ?? this.elapsedDays,
      scheduledDays: scheduledDays ?? this.scheduledDays,
      reps: reps ?? this.reps,
      lapses: lapses ?? this.lapses,
      due: due ?? this.due,
      lastReview: lastReview ?? this.lastReview,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (vocabItemId.present) {
      map['vocab_item_id'] = Variable<String>(vocabItemId.value);
    }
    if (contextTextSpanId.present) {
      map['context_text_span_id'] = Variable<String>(contextTextSpanId.value);
    }
    if (state.present) {
      map['state'] = Variable<String>(state.value);
    }
    if (stability.present) {
      map['stability'] = Variable<double>(stability.value);
    }
    if (difficulty.present) {
      map['difficulty'] = Variable<double>(difficulty.value);
    }
    if (elapsedDays.present) {
      map['elapsed_days'] = Variable<int>(elapsedDays.value);
    }
    if (scheduledDays.present) {
      map['scheduled_days'] = Variable<int>(scheduledDays.value);
    }
    if (reps.present) {
      map['reps'] = Variable<int>(reps.value);
    }
    if (lapses.present) {
      map['lapses'] = Variable<int>(lapses.value);
    }
    if (due.present) {
      map['due'] = Variable<DateTime>(due.value);
    }
    if (lastReview.present) {
      map['last_review'] = Variable<DateTime>(lastReview.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CardsCompanion(')
          ..write('id: $id, ')
          ..write('vocabItemId: $vocabItemId, ')
          ..write('contextTextSpanId: $contextTextSpanId, ')
          ..write('state: $state, ')
          ..write('stability: $stability, ')
          ..write('difficulty: $difficulty, ')
          ..write('elapsedDays: $elapsedDays, ')
          ..write('scheduledDays: $scheduledDays, ')
          ..write('reps: $reps, ')
          ..write('lapses: $lapses, ')
          ..write('due: $due, ')
          ..write('lastReview: $lastReview, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ReviewLogsTable extends ReviewLogs
    with TableInfo<$ReviewLogsTable, ReviewLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReviewLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cardIdMeta = const VerificationMeta('cardId');
  @override
  late final GeneratedColumn<String> cardId = GeneratedColumn<String>(
    'card_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES cards (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _ratingMeta = const VerificationMeta('rating');
  @override
  late final GeneratedColumn<String> rating = GeneratedColumn<String>(
    'rating',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reviewDateTimeMeta = const VerificationMeta(
    'reviewDateTime',
  );
  @override
  late final GeneratedColumn<DateTime> reviewDateTime =
      GeneratedColumn<DateTime>(
        'review_date_time',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _reviewDurationMsMeta = const VerificationMeta(
    'reviewDurationMs',
  );
  @override
  late final GeneratedColumn<int> reviewDurationMs = GeneratedColumn<int>(
    'review_duration_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _stabilityBeforeMeta = const VerificationMeta(
    'stabilityBefore',
  );
  @override
  late final GeneratedColumn<double> stabilityBefore = GeneratedColumn<double>(
    'stability_before',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _stabilityAfterMeta = const VerificationMeta(
    'stabilityAfter',
  );
  @override
  late final GeneratedColumn<double> stabilityAfter = GeneratedColumn<double>(
    'stability_after',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    cardId,
    rating,
    reviewDateTime,
    reviewDurationMs,
    stabilityBefore,
    stabilityAfter,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'review_logs';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReviewLog> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('card_id')) {
      context.handle(
        _cardIdMeta,
        cardId.isAcceptableOrUnknown(data['card_id']!, _cardIdMeta),
      );
    } else if (isInserting) {
      context.missing(_cardIdMeta);
    }
    if (data.containsKey('rating')) {
      context.handle(
        _ratingMeta,
        rating.isAcceptableOrUnknown(data['rating']!, _ratingMeta),
      );
    } else if (isInserting) {
      context.missing(_ratingMeta);
    }
    if (data.containsKey('review_date_time')) {
      context.handle(
        _reviewDateTimeMeta,
        reviewDateTime.isAcceptableOrUnknown(
          data['review_date_time']!,
          _reviewDateTimeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_reviewDateTimeMeta);
    }
    if (data.containsKey('review_duration_ms')) {
      context.handle(
        _reviewDurationMsMeta,
        reviewDurationMs.isAcceptableOrUnknown(
          data['review_duration_ms']!,
          _reviewDurationMsMeta,
        ),
      );
    }
    if (data.containsKey('stability_before')) {
      context.handle(
        _stabilityBeforeMeta,
        stabilityBefore.isAcceptableOrUnknown(
          data['stability_before']!,
          _stabilityBeforeMeta,
        ),
      );
    }
    if (data.containsKey('stability_after')) {
      context.handle(
        _stabilityAfterMeta,
        stabilityAfter.isAcceptableOrUnknown(
          data['stability_after']!,
          _stabilityAfterMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReviewLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReviewLog(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      cardId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}card_id'],
      )!,
      rating: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rating'],
      )!,
      reviewDateTime: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}review_date_time'],
      )!,
      reviewDurationMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}review_duration_ms'],
      ),
      stabilityBefore: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}stability_before'],
      ),
      stabilityAfter: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}stability_after'],
      ),
    );
  }

  @override
  $ReviewLogsTable createAlias(String alias) {
    return $ReviewLogsTable(attachedDatabase, alias);
  }
}

class ReviewLog extends DataClass implements Insertable<ReviewLog> {
  final String id;
  final String cardId;
  final String rating;
  final DateTime reviewDateTime;
  final int? reviewDurationMs;
  final double? stabilityBefore;
  final double? stabilityAfter;
  const ReviewLog({
    required this.id,
    required this.cardId,
    required this.rating,
    required this.reviewDateTime,
    this.reviewDurationMs,
    this.stabilityBefore,
    this.stabilityAfter,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['card_id'] = Variable<String>(cardId);
    map['rating'] = Variable<String>(rating);
    map['review_date_time'] = Variable<DateTime>(reviewDateTime);
    if (!nullToAbsent || reviewDurationMs != null) {
      map['review_duration_ms'] = Variable<int>(reviewDurationMs);
    }
    if (!nullToAbsent || stabilityBefore != null) {
      map['stability_before'] = Variable<double>(stabilityBefore);
    }
    if (!nullToAbsent || stabilityAfter != null) {
      map['stability_after'] = Variable<double>(stabilityAfter);
    }
    return map;
  }

  ReviewLogsCompanion toCompanion(bool nullToAbsent) {
    return ReviewLogsCompanion(
      id: Value(id),
      cardId: Value(cardId),
      rating: Value(rating),
      reviewDateTime: Value(reviewDateTime),
      reviewDurationMs: reviewDurationMs == null && nullToAbsent
          ? const Value.absent()
          : Value(reviewDurationMs),
      stabilityBefore: stabilityBefore == null && nullToAbsent
          ? const Value.absent()
          : Value(stabilityBefore),
      stabilityAfter: stabilityAfter == null && nullToAbsent
          ? const Value.absent()
          : Value(stabilityAfter),
    );
  }

  factory ReviewLog.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReviewLog(
      id: serializer.fromJson<String>(json['id']),
      cardId: serializer.fromJson<String>(json['cardId']),
      rating: serializer.fromJson<String>(json['rating']),
      reviewDateTime: serializer.fromJson<DateTime>(json['reviewDateTime']),
      reviewDurationMs: serializer.fromJson<int?>(json['reviewDurationMs']),
      stabilityBefore: serializer.fromJson<double?>(json['stabilityBefore']),
      stabilityAfter: serializer.fromJson<double?>(json['stabilityAfter']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'cardId': serializer.toJson<String>(cardId),
      'rating': serializer.toJson<String>(rating),
      'reviewDateTime': serializer.toJson<DateTime>(reviewDateTime),
      'reviewDurationMs': serializer.toJson<int?>(reviewDurationMs),
      'stabilityBefore': serializer.toJson<double?>(stabilityBefore),
      'stabilityAfter': serializer.toJson<double?>(stabilityAfter),
    };
  }

  ReviewLog copyWith({
    String? id,
    String? cardId,
    String? rating,
    DateTime? reviewDateTime,
    Value<int?> reviewDurationMs = const Value.absent(),
    Value<double?> stabilityBefore = const Value.absent(),
    Value<double?> stabilityAfter = const Value.absent(),
  }) => ReviewLog(
    id: id ?? this.id,
    cardId: cardId ?? this.cardId,
    rating: rating ?? this.rating,
    reviewDateTime: reviewDateTime ?? this.reviewDateTime,
    reviewDurationMs: reviewDurationMs.present
        ? reviewDurationMs.value
        : this.reviewDurationMs,
    stabilityBefore: stabilityBefore.present
        ? stabilityBefore.value
        : this.stabilityBefore,
    stabilityAfter: stabilityAfter.present
        ? stabilityAfter.value
        : this.stabilityAfter,
  );
  ReviewLog copyWithCompanion(ReviewLogsCompanion data) {
    return ReviewLog(
      id: data.id.present ? data.id.value : this.id,
      cardId: data.cardId.present ? data.cardId.value : this.cardId,
      rating: data.rating.present ? data.rating.value : this.rating,
      reviewDateTime: data.reviewDateTime.present
          ? data.reviewDateTime.value
          : this.reviewDateTime,
      reviewDurationMs: data.reviewDurationMs.present
          ? data.reviewDurationMs.value
          : this.reviewDurationMs,
      stabilityBefore: data.stabilityBefore.present
          ? data.stabilityBefore.value
          : this.stabilityBefore,
      stabilityAfter: data.stabilityAfter.present
          ? data.stabilityAfter.value
          : this.stabilityAfter,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReviewLog(')
          ..write('id: $id, ')
          ..write('cardId: $cardId, ')
          ..write('rating: $rating, ')
          ..write('reviewDateTime: $reviewDateTime, ')
          ..write('reviewDurationMs: $reviewDurationMs, ')
          ..write('stabilityBefore: $stabilityBefore, ')
          ..write('stabilityAfter: $stabilityAfter')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    cardId,
    rating,
    reviewDateTime,
    reviewDurationMs,
    stabilityBefore,
    stabilityAfter,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReviewLog &&
          other.id == this.id &&
          other.cardId == this.cardId &&
          other.rating == this.rating &&
          other.reviewDateTime == this.reviewDateTime &&
          other.reviewDurationMs == this.reviewDurationMs &&
          other.stabilityBefore == this.stabilityBefore &&
          other.stabilityAfter == this.stabilityAfter);
}

class ReviewLogsCompanion extends UpdateCompanion<ReviewLog> {
  final Value<String> id;
  final Value<String> cardId;
  final Value<String> rating;
  final Value<DateTime> reviewDateTime;
  final Value<int?> reviewDurationMs;
  final Value<double?> stabilityBefore;
  final Value<double?> stabilityAfter;
  final Value<int> rowid;
  const ReviewLogsCompanion({
    this.id = const Value.absent(),
    this.cardId = const Value.absent(),
    this.rating = const Value.absent(),
    this.reviewDateTime = const Value.absent(),
    this.reviewDurationMs = const Value.absent(),
    this.stabilityBefore = const Value.absent(),
    this.stabilityAfter = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReviewLogsCompanion.insert({
    required String id,
    required String cardId,
    required String rating,
    required DateTime reviewDateTime,
    this.reviewDurationMs = const Value.absent(),
    this.stabilityBefore = const Value.absent(),
    this.stabilityAfter = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       cardId = Value(cardId),
       rating = Value(rating),
       reviewDateTime = Value(reviewDateTime);
  static Insertable<ReviewLog> custom({
    Expression<String>? id,
    Expression<String>? cardId,
    Expression<String>? rating,
    Expression<DateTime>? reviewDateTime,
    Expression<int>? reviewDurationMs,
    Expression<double>? stabilityBefore,
    Expression<double>? stabilityAfter,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (cardId != null) 'card_id': cardId,
      if (rating != null) 'rating': rating,
      if (reviewDateTime != null) 'review_date_time': reviewDateTime,
      if (reviewDurationMs != null) 'review_duration_ms': reviewDurationMs,
      if (stabilityBefore != null) 'stability_before': stabilityBefore,
      if (stabilityAfter != null) 'stability_after': stabilityAfter,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReviewLogsCompanion copyWith({
    Value<String>? id,
    Value<String>? cardId,
    Value<String>? rating,
    Value<DateTime>? reviewDateTime,
    Value<int?>? reviewDurationMs,
    Value<double?>? stabilityBefore,
    Value<double?>? stabilityAfter,
    Value<int>? rowid,
  }) {
    return ReviewLogsCompanion(
      id: id ?? this.id,
      cardId: cardId ?? this.cardId,
      rating: rating ?? this.rating,
      reviewDateTime: reviewDateTime ?? this.reviewDateTime,
      reviewDurationMs: reviewDurationMs ?? this.reviewDurationMs,
      stabilityBefore: stabilityBefore ?? this.stabilityBefore,
      stabilityAfter: stabilityAfter ?? this.stabilityAfter,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (cardId.present) {
      map['card_id'] = Variable<String>(cardId.value);
    }
    if (rating.present) {
      map['rating'] = Variable<String>(rating.value);
    }
    if (reviewDateTime.present) {
      map['review_date_time'] = Variable<DateTime>(reviewDateTime.value);
    }
    if (reviewDurationMs.present) {
      map['review_duration_ms'] = Variable<int>(reviewDurationMs.value);
    }
    if (stabilityBefore.present) {
      map['stability_before'] = Variable<double>(stabilityBefore.value);
    }
    if (stabilityAfter.present) {
      map['stability_after'] = Variable<double>(stabilityAfter.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReviewLogsCompanion(')
          ..write('id: $id, ')
          ..write('cardId: $cardId, ')
          ..write('rating: $rating, ')
          ..write('reviewDateTime: $reviewDateTime, ')
          ..write('reviewDurationMs: $reviewDurationMs, ')
          ..write('stabilityBefore: $stabilityBefore, ')
          ..write('stabilityAfter: $stabilityAfter, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MediaBlobsTable extends MediaBlobs
    with TableInfo<$MediaBlobsTable, MediaBlob> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MediaBlobsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pathMeta = const VerificationMeta('path');
  @override
  late final GeneratedColumn<String> path = GeneratedColumn<String>(
    'path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentHashMeta = const VerificationMeta(
    'contentHash',
  );
  @override
  late final GeneratedColumn<String> contentHash = GeneratedColumn<String>(
    'content_hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, kind, path, contentHash];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'media_blobs';
  @override
  VerificationContext validateIntegrity(
    Insertable<MediaBlob> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('path')) {
      context.handle(
        _pathMeta,
        path.isAcceptableOrUnknown(data['path']!, _pathMeta),
      );
    } else if (isInserting) {
      context.missing(_pathMeta);
    }
    if (data.containsKey('content_hash')) {
      context.handle(
        _contentHashMeta,
        contentHash.isAcceptableOrUnknown(
          data['content_hash']!,
          _contentHashMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_contentHashMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MediaBlob map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MediaBlob(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      path: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}path'],
      )!,
      contentHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content_hash'],
      )!,
    );
  }

  @override
  $MediaBlobsTable createAlias(String alias) {
    return $MediaBlobsTable(attachedDatabase, alias);
  }
}

class MediaBlob extends DataClass implements Insertable<MediaBlob> {
  final String id;
  final String kind;
  final String path;
  final String contentHash;
  const MediaBlob({
    required this.id,
    required this.kind,
    required this.path,
    required this.contentHash,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['kind'] = Variable<String>(kind);
    map['path'] = Variable<String>(path);
    map['content_hash'] = Variable<String>(contentHash);
    return map;
  }

  MediaBlobsCompanion toCompanion(bool nullToAbsent) {
    return MediaBlobsCompanion(
      id: Value(id),
      kind: Value(kind),
      path: Value(path),
      contentHash: Value(contentHash),
    );
  }

  factory MediaBlob.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MediaBlob(
      id: serializer.fromJson<String>(json['id']),
      kind: serializer.fromJson<String>(json['kind']),
      path: serializer.fromJson<String>(json['path']),
      contentHash: serializer.fromJson<String>(json['contentHash']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'kind': serializer.toJson<String>(kind),
      'path': serializer.toJson<String>(path),
      'contentHash': serializer.toJson<String>(contentHash),
    };
  }

  MediaBlob copyWith({
    String? id,
    String? kind,
    String? path,
    String? contentHash,
  }) => MediaBlob(
    id: id ?? this.id,
    kind: kind ?? this.kind,
    path: path ?? this.path,
    contentHash: contentHash ?? this.contentHash,
  );
  MediaBlob copyWithCompanion(MediaBlobsCompanion data) {
    return MediaBlob(
      id: data.id.present ? data.id.value : this.id,
      kind: data.kind.present ? data.kind.value : this.kind,
      path: data.path.present ? data.path.value : this.path,
      contentHash: data.contentHash.present
          ? data.contentHash.value
          : this.contentHash,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MediaBlob(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('path: $path, ')
          ..write('contentHash: $contentHash')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, kind, path, contentHash);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MediaBlob &&
          other.id == this.id &&
          other.kind == this.kind &&
          other.path == this.path &&
          other.contentHash == this.contentHash);
}

class MediaBlobsCompanion extends UpdateCompanion<MediaBlob> {
  final Value<String> id;
  final Value<String> kind;
  final Value<String> path;
  final Value<String> contentHash;
  final Value<int> rowid;
  const MediaBlobsCompanion({
    this.id = const Value.absent(),
    this.kind = const Value.absent(),
    this.path = const Value.absent(),
    this.contentHash = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MediaBlobsCompanion.insert({
    required String id,
    required String kind,
    required String path,
    required String contentHash,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       kind = Value(kind),
       path = Value(path),
       contentHash = Value(contentHash);
  static Insertable<MediaBlob> custom({
    Expression<String>? id,
    Expression<String>? kind,
    Expression<String>? path,
    Expression<String>? contentHash,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (kind != null) 'kind': kind,
      if (path != null) 'path': path,
      if (contentHash != null) 'content_hash': contentHash,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MediaBlobsCompanion copyWith({
    Value<String>? id,
    Value<String>? kind,
    Value<String>? path,
    Value<String>? contentHash,
    Value<int>? rowid,
  }) {
    return MediaBlobsCompanion(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      path: path ?? this.path,
      contentHash: contentHash ?? this.contentHash,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (path.present) {
      map['path'] = Variable<String>(path.value);
    }
    if (contentHash.present) {
      map['content_hash'] = Variable<String>(contentHash.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MediaBlobsCompanion(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('path: $path, ')
          ..write('contentHash: $contentHash, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LanguagePacksTable extends LanguagePacks
    with TableInfo<$LanguagePacksTable, LanguagePackRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LanguagePacksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  @override
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
    'code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hasReadingsMeta = const VerificationMeta(
    'hasReadings',
  );
  @override
  late final GeneratedColumn<bool> hasReadings = GeneratedColumn<bool>(
    'has_readings',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("has_readings" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [code, name, hasReadings];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'language_packs';
  @override
  VerificationContext validateIntegrity(
    Insertable<LanguagePackRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('code')) {
      context.handle(
        _codeMeta,
        code.isAcceptableOrUnknown(data['code']!, _codeMeta),
      );
    } else if (isInserting) {
      context.missing(_codeMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('has_readings')) {
      context.handle(
        _hasReadingsMeta,
        hasReadings.isAcceptableOrUnknown(
          data['has_readings']!,
          _hasReadingsMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {code};
  @override
  LanguagePackRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LanguagePackRow(
      code: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}code'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      hasReadings: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}has_readings'],
      )!,
    );
  }

  @override
  $LanguagePacksTable createAlias(String alias) {
    return $LanguagePacksTable(attachedDatabase, alias);
  }
}

class LanguagePackRow extends DataClass implements Insertable<LanguagePackRow> {
  final String code;
  final String name;
  final bool hasReadings;
  const LanguagePackRow({
    required this.code,
    required this.name,
    required this.hasReadings,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['code'] = Variable<String>(code);
    map['name'] = Variable<String>(name);
    map['has_readings'] = Variable<bool>(hasReadings);
    return map;
  }

  LanguagePacksCompanion toCompanion(bool nullToAbsent) {
    return LanguagePacksCompanion(
      code: Value(code),
      name: Value(name),
      hasReadings: Value(hasReadings),
    );
  }

  factory LanguagePackRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LanguagePackRow(
      code: serializer.fromJson<String>(json['code']),
      name: serializer.fromJson<String>(json['name']),
      hasReadings: serializer.fromJson<bool>(json['hasReadings']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'code': serializer.toJson<String>(code),
      'name': serializer.toJson<String>(name),
      'hasReadings': serializer.toJson<bool>(hasReadings),
    };
  }

  LanguagePackRow copyWith({String? code, String? name, bool? hasReadings}) =>
      LanguagePackRow(
        code: code ?? this.code,
        name: name ?? this.name,
        hasReadings: hasReadings ?? this.hasReadings,
      );
  LanguagePackRow copyWithCompanion(LanguagePacksCompanion data) {
    return LanguagePackRow(
      code: data.code.present ? data.code.value : this.code,
      name: data.name.present ? data.name.value : this.name,
      hasReadings: data.hasReadings.present
          ? data.hasReadings.value
          : this.hasReadings,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LanguagePackRow(')
          ..write('code: $code, ')
          ..write('name: $name, ')
          ..write('hasReadings: $hasReadings')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(code, name, hasReadings);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LanguagePackRow &&
          other.code == this.code &&
          other.name == this.name &&
          other.hasReadings == this.hasReadings);
}

class LanguagePacksCompanion extends UpdateCompanion<LanguagePackRow> {
  final Value<String> code;
  final Value<String> name;
  final Value<bool> hasReadings;
  final Value<int> rowid;
  const LanguagePacksCompanion({
    this.code = const Value.absent(),
    this.name = const Value.absent(),
    this.hasReadings = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LanguagePacksCompanion.insert({
    required String code,
    required String name,
    this.hasReadings = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : code = Value(code),
       name = Value(name);
  static Insertable<LanguagePackRow> custom({
    Expression<String>? code,
    Expression<String>? name,
    Expression<bool>? hasReadings,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (code != null) 'code': code,
      if (name != null) 'name': name,
      if (hasReadings != null) 'has_readings': hasReadings,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LanguagePacksCompanion copyWith({
    Value<String>? code,
    Value<String>? name,
    Value<bool>? hasReadings,
    Value<int>? rowid,
  }) {
    return LanguagePacksCompanion(
      code: code ?? this.code,
      name: name ?? this.name,
      hasReadings: hasReadings ?? this.hasReadings,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (hasReadings.present) {
      map['has_readings'] = Variable<bool>(hasReadings.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LanguagePacksCompanion(')
          ..write('code: $code, ')
          ..write('name: $name, ')
          ..write('hasReadings: $hasReadings, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ReadingSessionsTable extends ReadingSessions
    with TableInfo<$ReadingSessionsTable, ReadingSession> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReadingSessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _workIdMeta = const VerificationMeta('workId');
  @override
  late final GeneratedColumn<String> workId = GeneratedColumn<String>(
    'work_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES works (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endedAtMeta = const VerificationMeta(
    'endedAt',
  );
  @override
  late final GeneratedColumn<DateTime> endedAt = GeneratedColumn<DateTime>(
    'ended_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _spanStartOrdinalMeta = const VerificationMeta(
    'spanStartOrdinal',
  );
  @override
  late final GeneratedColumn<int> spanStartOrdinal = GeneratedColumn<int>(
    'span_start_ordinal',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _spanEndOrdinalMeta = const VerificationMeta(
    'spanEndOrdinal',
  );
  @override
  late final GeneratedColumn<int> spanEndOrdinal = GeneratedColumn<int>(
    'span_end_ordinal',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    workId,
    startedAt,
    endedAt,
    spanStartOrdinal,
    spanEndOrdinal,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reading_sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReadingSession> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('work_id')) {
      context.handle(
        _workIdMeta,
        workId.isAcceptableOrUnknown(data['work_id']!, _workIdMeta),
      );
    } else if (isInserting) {
      context.missing(_workIdMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('ended_at')) {
      context.handle(
        _endedAtMeta,
        endedAt.isAcceptableOrUnknown(data['ended_at']!, _endedAtMeta),
      );
    }
    if (data.containsKey('span_start_ordinal')) {
      context.handle(
        _spanStartOrdinalMeta,
        spanStartOrdinal.isAcceptableOrUnknown(
          data['span_start_ordinal']!,
          _spanStartOrdinalMeta,
        ),
      );
    }
    if (data.containsKey('span_end_ordinal')) {
      context.handle(
        _spanEndOrdinalMeta,
        spanEndOrdinal.isAcceptableOrUnknown(
          data['span_end_ordinal']!,
          _spanEndOrdinalMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReadingSession map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReadingSession(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      workId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}work_id'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      endedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}ended_at'],
      ),
      spanStartOrdinal: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}span_start_ordinal'],
      ),
      spanEndOrdinal: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}span_end_ordinal'],
      ),
    );
  }

  @override
  $ReadingSessionsTable createAlias(String alias) {
    return $ReadingSessionsTable(attachedDatabase, alias);
  }
}

class ReadingSession extends DataClass implements Insertable<ReadingSession> {
  final String id;
  final String workId;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int? spanStartOrdinal;
  final int? spanEndOrdinal;
  const ReadingSession({
    required this.id,
    required this.workId,
    required this.startedAt,
    this.endedAt,
    this.spanStartOrdinal,
    this.spanEndOrdinal,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['work_id'] = Variable<String>(workId);
    map['started_at'] = Variable<DateTime>(startedAt);
    if (!nullToAbsent || endedAt != null) {
      map['ended_at'] = Variable<DateTime>(endedAt);
    }
    if (!nullToAbsent || spanStartOrdinal != null) {
      map['span_start_ordinal'] = Variable<int>(spanStartOrdinal);
    }
    if (!nullToAbsent || spanEndOrdinal != null) {
      map['span_end_ordinal'] = Variable<int>(spanEndOrdinal);
    }
    return map;
  }

  ReadingSessionsCompanion toCompanion(bool nullToAbsent) {
    return ReadingSessionsCompanion(
      id: Value(id),
      workId: Value(workId),
      startedAt: Value(startedAt),
      endedAt: endedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(endedAt),
      spanStartOrdinal: spanStartOrdinal == null && nullToAbsent
          ? const Value.absent()
          : Value(spanStartOrdinal),
      spanEndOrdinal: spanEndOrdinal == null && nullToAbsent
          ? const Value.absent()
          : Value(spanEndOrdinal),
    );
  }

  factory ReadingSession.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReadingSession(
      id: serializer.fromJson<String>(json['id']),
      workId: serializer.fromJson<String>(json['workId']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      endedAt: serializer.fromJson<DateTime?>(json['endedAt']),
      spanStartOrdinal: serializer.fromJson<int?>(json['spanStartOrdinal']),
      spanEndOrdinal: serializer.fromJson<int?>(json['spanEndOrdinal']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'workId': serializer.toJson<String>(workId),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'endedAt': serializer.toJson<DateTime?>(endedAt),
      'spanStartOrdinal': serializer.toJson<int?>(spanStartOrdinal),
      'spanEndOrdinal': serializer.toJson<int?>(spanEndOrdinal),
    };
  }

  ReadingSession copyWith({
    String? id,
    String? workId,
    DateTime? startedAt,
    Value<DateTime?> endedAt = const Value.absent(),
    Value<int?> spanStartOrdinal = const Value.absent(),
    Value<int?> spanEndOrdinal = const Value.absent(),
  }) => ReadingSession(
    id: id ?? this.id,
    workId: workId ?? this.workId,
    startedAt: startedAt ?? this.startedAt,
    endedAt: endedAt.present ? endedAt.value : this.endedAt,
    spanStartOrdinal: spanStartOrdinal.present
        ? spanStartOrdinal.value
        : this.spanStartOrdinal,
    spanEndOrdinal: spanEndOrdinal.present
        ? spanEndOrdinal.value
        : this.spanEndOrdinal,
  );
  ReadingSession copyWithCompanion(ReadingSessionsCompanion data) {
    return ReadingSession(
      id: data.id.present ? data.id.value : this.id,
      workId: data.workId.present ? data.workId.value : this.workId,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      endedAt: data.endedAt.present ? data.endedAt.value : this.endedAt,
      spanStartOrdinal: data.spanStartOrdinal.present
          ? data.spanStartOrdinal.value
          : this.spanStartOrdinal,
      spanEndOrdinal: data.spanEndOrdinal.present
          ? data.spanEndOrdinal.value
          : this.spanEndOrdinal,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReadingSession(')
          ..write('id: $id, ')
          ..write('workId: $workId, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('spanStartOrdinal: $spanStartOrdinal, ')
          ..write('spanEndOrdinal: $spanEndOrdinal')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    workId,
    startedAt,
    endedAt,
    spanStartOrdinal,
    spanEndOrdinal,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReadingSession &&
          other.id == this.id &&
          other.workId == this.workId &&
          other.startedAt == this.startedAt &&
          other.endedAt == this.endedAt &&
          other.spanStartOrdinal == this.spanStartOrdinal &&
          other.spanEndOrdinal == this.spanEndOrdinal);
}

class ReadingSessionsCompanion extends UpdateCompanion<ReadingSession> {
  final Value<String> id;
  final Value<String> workId;
  final Value<DateTime> startedAt;
  final Value<DateTime?> endedAt;
  final Value<int?> spanStartOrdinal;
  final Value<int?> spanEndOrdinal;
  final Value<int> rowid;
  const ReadingSessionsCompanion({
    this.id = const Value.absent(),
    this.workId = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.spanStartOrdinal = const Value.absent(),
    this.spanEndOrdinal = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReadingSessionsCompanion.insert({
    required String id,
    required String workId,
    required DateTime startedAt,
    this.endedAt = const Value.absent(),
    this.spanStartOrdinal = const Value.absent(),
    this.spanEndOrdinal = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       workId = Value(workId),
       startedAt = Value(startedAt);
  static Insertable<ReadingSession> custom({
    Expression<String>? id,
    Expression<String>? workId,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? endedAt,
    Expression<int>? spanStartOrdinal,
    Expression<int>? spanEndOrdinal,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (workId != null) 'work_id': workId,
      if (startedAt != null) 'started_at': startedAt,
      if (endedAt != null) 'ended_at': endedAt,
      if (spanStartOrdinal != null) 'span_start_ordinal': spanStartOrdinal,
      if (spanEndOrdinal != null) 'span_end_ordinal': spanEndOrdinal,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReadingSessionsCompanion copyWith({
    Value<String>? id,
    Value<String>? workId,
    Value<DateTime>? startedAt,
    Value<DateTime?>? endedAt,
    Value<int?>? spanStartOrdinal,
    Value<int?>? spanEndOrdinal,
    Value<int>? rowid,
  }) {
    return ReadingSessionsCompanion(
      id: id ?? this.id,
      workId: workId ?? this.workId,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      spanStartOrdinal: spanStartOrdinal ?? this.spanStartOrdinal,
      spanEndOrdinal: spanEndOrdinal ?? this.spanEndOrdinal,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (workId.present) {
      map['work_id'] = Variable<String>(workId.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (endedAt.present) {
      map['ended_at'] = Variable<DateTime>(endedAt.value);
    }
    if (spanStartOrdinal.present) {
      map['span_start_ordinal'] = Variable<int>(spanStartOrdinal.value);
    }
    if (spanEndOrdinal.present) {
      map['span_end_ordinal'] = Variable<int>(spanEndOrdinal.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReadingSessionsCompanion(')
          ..write('id: $id, ')
          ..write('workId: $workId, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('spanStartOrdinal: $spanStartOrdinal, ')
          ..write('spanEndOrdinal: $spanEndOrdinal, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PassageSnapshotsTable extends PassageSnapshots
    with TableInfo<$PassageSnapshotsTable, PassageSnapshot> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PassageSnapshotsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _workIdMeta = const VerificationMeta('workId');
  @override
  late final GeneratedColumn<String> workId = GeneratedColumn<String>(
    'work_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES works (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _passageRefMeta = const VerificationMeta(
    'passageRef',
  );
  @override
  late final GeneratedColumn<String> passageRef = GeneratedColumn<String>(
    'passage_ref',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tsMeta = const VerificationMeta('ts');
  @override
  late final GeneratedColumn<DateTime> ts = GeneratedColumn<DateTime>(
    'ts',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _unknownRatioMeta = const VerificationMeta(
    'unknownRatio',
  );
  @override
  late final GeneratedColumn<double> unknownRatio = GeneratedColumn<double>(
    'unknown_ratio',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dwellMsMeta = const VerificationMeta(
    'dwellMs',
  );
  @override
  late final GeneratedColumn<int> dwellMs = GeneratedColumn<int>(
    'dwell_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lookupCountMeta = const VerificationMeta(
    'lookupCount',
  );
  @override
  late final GeneratedColumn<int> lookupCount = GeneratedColumn<int>(
    'lookup_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _miningEventsCountMeta = const VerificationMeta(
    'miningEventsCount',
  );
  @override
  late final GeneratedColumn<int> miningEventsCount = GeneratedColumn<int>(
    'mining_events_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    workId,
    passageRef,
    ts,
    unknownRatio,
    dwellMs,
    lookupCount,
    miningEventsCount,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'passage_snapshots';
  @override
  VerificationContext validateIntegrity(
    Insertable<PassageSnapshot> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('work_id')) {
      context.handle(
        _workIdMeta,
        workId.isAcceptableOrUnknown(data['work_id']!, _workIdMeta),
      );
    } else if (isInserting) {
      context.missing(_workIdMeta);
    }
    if (data.containsKey('passage_ref')) {
      context.handle(
        _passageRefMeta,
        passageRef.isAcceptableOrUnknown(data['passage_ref']!, _passageRefMeta),
      );
    } else if (isInserting) {
      context.missing(_passageRefMeta);
    }
    if (data.containsKey('ts')) {
      context.handle(_tsMeta, ts.isAcceptableOrUnknown(data['ts']!, _tsMeta));
    } else if (isInserting) {
      context.missing(_tsMeta);
    }
    if (data.containsKey('unknown_ratio')) {
      context.handle(
        _unknownRatioMeta,
        unknownRatio.isAcceptableOrUnknown(
          data['unknown_ratio']!,
          _unknownRatioMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_unknownRatioMeta);
    }
    if (data.containsKey('dwell_ms')) {
      context.handle(
        _dwellMsMeta,
        dwellMs.isAcceptableOrUnknown(data['dwell_ms']!, _dwellMsMeta),
      );
    }
    if (data.containsKey('lookup_count')) {
      context.handle(
        _lookupCountMeta,
        lookupCount.isAcceptableOrUnknown(
          data['lookup_count']!,
          _lookupCountMeta,
        ),
      );
    }
    if (data.containsKey('mining_events_count')) {
      context.handle(
        _miningEventsCountMeta,
        miningEventsCount.isAcceptableOrUnknown(
          data['mining_events_count']!,
          _miningEventsCountMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PassageSnapshot map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PassageSnapshot(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      workId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}work_id'],
      )!,
      passageRef: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}passage_ref'],
      )!,
      ts: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}ts'],
      )!,
      unknownRatio: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}unknown_ratio'],
      )!,
      dwellMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}dwell_ms'],
      ),
      lookupCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}lookup_count'],
      )!,
      miningEventsCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}mining_events_count'],
      )!,
    );
  }

  @override
  $PassageSnapshotsTable createAlias(String alias) {
    return $PassageSnapshotsTable(attachedDatabase, alias);
  }
}

class PassageSnapshot extends DataClass implements Insertable<PassageSnapshot> {
  final String id;
  final String workId;
  final String passageRef;
  final DateTime ts;
  final double unknownRatio;
  final int? dwellMs;
  final int lookupCount;
  final int miningEventsCount;
  const PassageSnapshot({
    required this.id,
    required this.workId,
    required this.passageRef,
    required this.ts,
    required this.unknownRatio,
    this.dwellMs,
    required this.lookupCount,
    required this.miningEventsCount,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['work_id'] = Variable<String>(workId);
    map['passage_ref'] = Variable<String>(passageRef);
    map['ts'] = Variable<DateTime>(ts);
    map['unknown_ratio'] = Variable<double>(unknownRatio);
    if (!nullToAbsent || dwellMs != null) {
      map['dwell_ms'] = Variable<int>(dwellMs);
    }
    map['lookup_count'] = Variable<int>(lookupCount);
    map['mining_events_count'] = Variable<int>(miningEventsCount);
    return map;
  }

  PassageSnapshotsCompanion toCompanion(bool nullToAbsent) {
    return PassageSnapshotsCompanion(
      id: Value(id),
      workId: Value(workId),
      passageRef: Value(passageRef),
      ts: Value(ts),
      unknownRatio: Value(unknownRatio),
      dwellMs: dwellMs == null && nullToAbsent
          ? const Value.absent()
          : Value(dwellMs),
      lookupCount: Value(lookupCount),
      miningEventsCount: Value(miningEventsCount),
    );
  }

  factory PassageSnapshot.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PassageSnapshot(
      id: serializer.fromJson<String>(json['id']),
      workId: serializer.fromJson<String>(json['workId']),
      passageRef: serializer.fromJson<String>(json['passageRef']),
      ts: serializer.fromJson<DateTime>(json['ts']),
      unknownRatio: serializer.fromJson<double>(json['unknownRatio']),
      dwellMs: serializer.fromJson<int?>(json['dwellMs']),
      lookupCount: serializer.fromJson<int>(json['lookupCount']),
      miningEventsCount: serializer.fromJson<int>(json['miningEventsCount']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'workId': serializer.toJson<String>(workId),
      'passageRef': serializer.toJson<String>(passageRef),
      'ts': serializer.toJson<DateTime>(ts),
      'unknownRatio': serializer.toJson<double>(unknownRatio),
      'dwellMs': serializer.toJson<int?>(dwellMs),
      'lookupCount': serializer.toJson<int>(lookupCount),
      'miningEventsCount': serializer.toJson<int>(miningEventsCount),
    };
  }

  PassageSnapshot copyWith({
    String? id,
    String? workId,
    String? passageRef,
    DateTime? ts,
    double? unknownRatio,
    Value<int?> dwellMs = const Value.absent(),
    int? lookupCount,
    int? miningEventsCount,
  }) => PassageSnapshot(
    id: id ?? this.id,
    workId: workId ?? this.workId,
    passageRef: passageRef ?? this.passageRef,
    ts: ts ?? this.ts,
    unknownRatio: unknownRatio ?? this.unknownRatio,
    dwellMs: dwellMs.present ? dwellMs.value : this.dwellMs,
    lookupCount: lookupCount ?? this.lookupCount,
    miningEventsCount: miningEventsCount ?? this.miningEventsCount,
  );
  PassageSnapshot copyWithCompanion(PassageSnapshotsCompanion data) {
    return PassageSnapshot(
      id: data.id.present ? data.id.value : this.id,
      workId: data.workId.present ? data.workId.value : this.workId,
      passageRef: data.passageRef.present
          ? data.passageRef.value
          : this.passageRef,
      ts: data.ts.present ? data.ts.value : this.ts,
      unknownRatio: data.unknownRatio.present
          ? data.unknownRatio.value
          : this.unknownRatio,
      dwellMs: data.dwellMs.present ? data.dwellMs.value : this.dwellMs,
      lookupCount: data.lookupCount.present
          ? data.lookupCount.value
          : this.lookupCount,
      miningEventsCount: data.miningEventsCount.present
          ? data.miningEventsCount.value
          : this.miningEventsCount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PassageSnapshot(')
          ..write('id: $id, ')
          ..write('workId: $workId, ')
          ..write('passageRef: $passageRef, ')
          ..write('ts: $ts, ')
          ..write('unknownRatio: $unknownRatio, ')
          ..write('dwellMs: $dwellMs, ')
          ..write('lookupCount: $lookupCount, ')
          ..write('miningEventsCount: $miningEventsCount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    workId,
    passageRef,
    ts,
    unknownRatio,
    dwellMs,
    lookupCount,
    miningEventsCount,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PassageSnapshot &&
          other.id == this.id &&
          other.workId == this.workId &&
          other.passageRef == this.passageRef &&
          other.ts == this.ts &&
          other.unknownRatio == this.unknownRatio &&
          other.dwellMs == this.dwellMs &&
          other.lookupCount == this.lookupCount &&
          other.miningEventsCount == this.miningEventsCount);
}

class PassageSnapshotsCompanion extends UpdateCompanion<PassageSnapshot> {
  final Value<String> id;
  final Value<String> workId;
  final Value<String> passageRef;
  final Value<DateTime> ts;
  final Value<double> unknownRatio;
  final Value<int?> dwellMs;
  final Value<int> lookupCount;
  final Value<int> miningEventsCount;
  final Value<int> rowid;
  const PassageSnapshotsCompanion({
    this.id = const Value.absent(),
    this.workId = const Value.absent(),
    this.passageRef = const Value.absent(),
    this.ts = const Value.absent(),
    this.unknownRatio = const Value.absent(),
    this.dwellMs = const Value.absent(),
    this.lookupCount = const Value.absent(),
    this.miningEventsCount = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PassageSnapshotsCompanion.insert({
    required String id,
    required String workId,
    required String passageRef,
    required DateTime ts,
    required double unknownRatio,
    this.dwellMs = const Value.absent(),
    this.lookupCount = const Value.absent(),
    this.miningEventsCount = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       workId = Value(workId),
       passageRef = Value(passageRef),
       ts = Value(ts),
       unknownRatio = Value(unknownRatio);
  static Insertable<PassageSnapshot> custom({
    Expression<String>? id,
    Expression<String>? workId,
    Expression<String>? passageRef,
    Expression<DateTime>? ts,
    Expression<double>? unknownRatio,
    Expression<int>? dwellMs,
    Expression<int>? lookupCount,
    Expression<int>? miningEventsCount,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (workId != null) 'work_id': workId,
      if (passageRef != null) 'passage_ref': passageRef,
      if (ts != null) 'ts': ts,
      if (unknownRatio != null) 'unknown_ratio': unknownRatio,
      if (dwellMs != null) 'dwell_ms': dwellMs,
      if (lookupCount != null) 'lookup_count': lookupCount,
      if (miningEventsCount != null) 'mining_events_count': miningEventsCount,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PassageSnapshotsCompanion copyWith({
    Value<String>? id,
    Value<String>? workId,
    Value<String>? passageRef,
    Value<DateTime>? ts,
    Value<double>? unknownRatio,
    Value<int?>? dwellMs,
    Value<int>? lookupCount,
    Value<int>? miningEventsCount,
    Value<int>? rowid,
  }) {
    return PassageSnapshotsCompanion(
      id: id ?? this.id,
      workId: workId ?? this.workId,
      passageRef: passageRef ?? this.passageRef,
      ts: ts ?? this.ts,
      unknownRatio: unknownRatio ?? this.unknownRatio,
      dwellMs: dwellMs ?? this.dwellMs,
      lookupCount: lookupCount ?? this.lookupCount,
      miningEventsCount: miningEventsCount ?? this.miningEventsCount,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (workId.present) {
      map['work_id'] = Variable<String>(workId.value);
    }
    if (passageRef.present) {
      map['passage_ref'] = Variable<String>(passageRef.value);
    }
    if (ts.present) {
      map['ts'] = Variable<DateTime>(ts.value);
    }
    if (unknownRatio.present) {
      map['unknown_ratio'] = Variable<double>(unknownRatio.value);
    }
    if (dwellMs.present) {
      map['dwell_ms'] = Variable<int>(dwellMs.value);
    }
    if (lookupCount.present) {
      map['lookup_count'] = Variable<int>(lookupCount.value);
    }
    if (miningEventsCount.present) {
      map['mining_events_count'] = Variable<int>(miningEventsCount.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PassageSnapshotsCompanion(')
          ..write('id: $id, ')
          ..write('workId: $workId, ')
          ..write('passageRef: $passageRef, ')
          ..write('ts: $ts, ')
          ..write('unknownRatio: $unknownRatio, ')
          ..write('dwellMs: $dwellMs, ')
          ..write('lookupCount: $lookupCount, ')
          ..write('miningEventsCount: $miningEventsCount, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ObservationsTable extends Observations
    with TableInfo<$ObservationsTable, Observation> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ObservationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _factsJsonMeta = const VerificationMeta(
    'factsJson',
  );
  @override
  late final GeneratedColumn<String> factsJson = GeneratedColumn<String>(
    'facts_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, kind, factsJson, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'observations';
  @override
  VerificationContext validateIntegrity(
    Insertable<Observation> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('facts_json')) {
      context.handle(
        _factsJsonMeta,
        factsJson.isAcceptableOrUnknown(data['facts_json']!, _factsJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_factsJsonMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Observation map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Observation(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      factsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}facts_json'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $ObservationsTable createAlias(String alias) {
    return $ObservationsTable(attachedDatabase, alias);
  }
}

class Observation extends DataClass implements Insertable<Observation> {
  final String id;
  final String kind;
  final String factsJson;
  final DateTime createdAt;
  const Observation({
    required this.id,
    required this.kind,
    required this.factsJson,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['kind'] = Variable<String>(kind);
    map['facts_json'] = Variable<String>(factsJson);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ObservationsCompanion toCompanion(bool nullToAbsent) {
    return ObservationsCompanion(
      id: Value(id),
      kind: Value(kind),
      factsJson: Value(factsJson),
      createdAt: Value(createdAt),
    );
  }

  factory Observation.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Observation(
      id: serializer.fromJson<String>(json['id']),
      kind: serializer.fromJson<String>(json['kind']),
      factsJson: serializer.fromJson<String>(json['factsJson']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'kind': serializer.toJson<String>(kind),
      'factsJson': serializer.toJson<String>(factsJson),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Observation copyWith({
    String? id,
    String? kind,
    String? factsJson,
    DateTime? createdAt,
  }) => Observation(
    id: id ?? this.id,
    kind: kind ?? this.kind,
    factsJson: factsJson ?? this.factsJson,
    createdAt: createdAt ?? this.createdAt,
  );
  Observation copyWithCompanion(ObservationsCompanion data) {
    return Observation(
      id: data.id.present ? data.id.value : this.id,
      kind: data.kind.present ? data.kind.value : this.kind,
      factsJson: data.factsJson.present ? data.factsJson.value : this.factsJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Observation(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('factsJson: $factsJson, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, kind, factsJson, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Observation &&
          other.id == this.id &&
          other.kind == this.kind &&
          other.factsJson == this.factsJson &&
          other.createdAt == this.createdAt);
}

class ObservationsCompanion extends UpdateCompanion<Observation> {
  final Value<String> id;
  final Value<String> kind;
  final Value<String> factsJson;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const ObservationsCompanion({
    this.id = const Value.absent(),
    this.kind = const Value.absent(),
    this.factsJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ObservationsCompanion.insert({
    required String id,
    required String kind,
    required String factsJson,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       kind = Value(kind),
       factsJson = Value(factsJson),
       createdAt = Value(createdAt);
  static Insertable<Observation> custom({
    Expression<String>? id,
    Expression<String>? kind,
    Expression<String>? factsJson,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (kind != null) 'kind': kind,
      if (factsJson != null) 'facts_json': factsJson,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ObservationsCompanion copyWith({
    Value<String>? id,
    Value<String>? kind,
    Value<String>? factsJson,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return ObservationsCompanion(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      factsJson: factsJson ?? this.factsJson,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (factsJson.present) {
      map['facts_json'] = Variable<String>(factsJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ObservationsCompanion(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('factsJson: $factsJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$MiningDb extends GeneratedDatabase {
  _$MiningDb(QueryExecutor e) : super(e);
  $MiningDbManager get managers => $MiningDbManager(this);
  late final $WorksTable works = $WorksTable(this);
  late final $SourcesTable sources = $SourcesTable(this);
  late final $TextSpansTable textSpans = $TextSpansTable(this);
  late final $TokenOccurrencesTable tokenOccurrences = $TokenOccurrencesTable(
    this,
  );
  late final $VocabItemsTable vocabItems = $VocabItemsTable(this);
  late final $CardsTable cards = $CardsTable(this);
  late final $ReviewLogsTable reviewLogs = $ReviewLogsTable(this);
  late final $MediaBlobsTable mediaBlobs = $MediaBlobsTable(this);
  late final $LanguagePacksTable languagePacks = $LanguagePacksTable(this);
  late final $ReadingSessionsTable readingSessions = $ReadingSessionsTable(
    this,
  );
  late final $PassageSnapshotsTable passageSnapshots = $PassageSnapshotsTable(
    this,
  );
  late final $ObservationsTable observations = $ObservationsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    works,
    sources,
    textSpans,
    tokenOccurrences,
    vocabItems,
    cards,
    reviewLogs,
    mediaBlobs,
    languagePacks,
    readingSessions,
    passageSnapshots,
    observations,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'works',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('sources', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'works',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('text_spans', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'sources',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('text_spans', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'text_spans',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('token_occurrences', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'vocab_items',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('cards', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'cards',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('review_logs', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'works',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('reading_sessions', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'works',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('passage_snapshots', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$WorksTableCreateCompanionBuilder =
    WorksCompanion Function({
      required String id,
      required String title,
      required String medium,
      required String languageCode,
      required DateTime addedAt,
      Value<int> rowid,
    });
typedef $$WorksTableUpdateCompanionBuilder =
    WorksCompanion Function({
      Value<String> id,
      Value<String> title,
      Value<String> medium,
      Value<String> languageCode,
      Value<DateTime> addedAt,
      Value<int> rowid,
    });

final class $$WorksTableReferences
    extends BaseReferences<_$MiningDb, $WorksTable, Work> {
  $$WorksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$SourcesTable, List<Source>> _sourcesRefsTable(
    _$MiningDb db,
  ) => MultiTypedResultKey.fromTable(
    db.sources,
    aliasName: $_aliasNameGenerator(db.works.id, db.sources.workId),
  );

  $$SourcesTableProcessedTableManager get sourcesRefs {
    final manager = $$SourcesTableTableManager(
      $_db,
      $_db.sources,
    ).filter((f) => f.workId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_sourcesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$TextSpansTable, List<TextSpan>>
  _textSpansRefsTable(_$MiningDb db) => MultiTypedResultKey.fromTable(
    db.textSpans,
    aliasName: $_aliasNameGenerator(db.works.id, db.textSpans.workId),
  );

  $$TextSpansTableProcessedTableManager get textSpansRefs {
    final manager = $$TextSpansTableTableManager(
      $_db,
      $_db.textSpans,
    ).filter((f) => f.workId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_textSpansRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ReadingSessionsTable, List<ReadingSession>>
  _readingSessionsRefsTable(_$MiningDb db) => MultiTypedResultKey.fromTable(
    db.readingSessions,
    aliasName: $_aliasNameGenerator(db.works.id, db.readingSessions.workId),
  );

  $$ReadingSessionsTableProcessedTableManager get readingSessionsRefs {
    final manager = $$ReadingSessionsTableTableManager(
      $_db,
      $_db.readingSessions,
    ).filter((f) => f.workId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _readingSessionsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$PassageSnapshotsTable, List<PassageSnapshot>>
  _passageSnapshotsRefsTable(_$MiningDb db) => MultiTypedResultKey.fromTable(
    db.passageSnapshots,
    aliasName: $_aliasNameGenerator(db.works.id, db.passageSnapshots.workId),
  );

  $$PassageSnapshotsTableProcessedTableManager get passageSnapshotsRefs {
    final manager = $$PassageSnapshotsTableTableManager(
      $_db,
      $_db.passageSnapshots,
    ).filter((f) => f.workId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _passageSnapshotsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$WorksTableFilterComposer extends Composer<_$MiningDb, $WorksTable> {
  $$WorksTableFilterComposer({
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

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get medium => $composableBuilder(
    column: $table.medium,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get languageCode => $composableBuilder(
    column: $table.languageCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> sourcesRefs(
    Expression<bool> Function($$SourcesTableFilterComposer f) f,
  ) {
    final $$SourcesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.sources,
      getReferencedColumn: (t) => t.workId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SourcesTableFilterComposer(
            $db: $db,
            $table: $db.sources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> textSpansRefs(
    Expression<bool> Function($$TextSpansTableFilterComposer f) f,
  ) {
    final $$TextSpansTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.textSpans,
      getReferencedColumn: (t) => t.workId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TextSpansTableFilterComposer(
            $db: $db,
            $table: $db.textSpans,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> readingSessionsRefs(
    Expression<bool> Function($$ReadingSessionsTableFilterComposer f) f,
  ) {
    final $$ReadingSessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.readingSessions,
      getReferencedColumn: (t) => t.workId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReadingSessionsTableFilterComposer(
            $db: $db,
            $table: $db.readingSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> passageSnapshotsRefs(
    Expression<bool> Function($$PassageSnapshotsTableFilterComposer f) f,
  ) {
    final $$PassageSnapshotsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.passageSnapshots,
      getReferencedColumn: (t) => t.workId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PassageSnapshotsTableFilterComposer(
            $db: $db,
            $table: $db.passageSnapshots,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$WorksTableOrderingComposer extends Composer<_$MiningDb, $WorksTable> {
  $$WorksTableOrderingComposer({
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

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get medium => $composableBuilder(
    column: $table.medium,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get languageCode => $composableBuilder(
    column: $table.languageCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WorksTableAnnotationComposer extends Composer<_$MiningDb, $WorksTable> {
  $$WorksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get medium =>
      $composableBuilder(column: $table.medium, builder: (column) => column);

  GeneratedColumn<String> get languageCode => $composableBuilder(
    column: $table.languageCode,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get addedAt =>
      $composableBuilder(column: $table.addedAt, builder: (column) => column);

  Expression<T> sourcesRefs<T extends Object>(
    Expression<T> Function($$SourcesTableAnnotationComposer a) f,
  ) {
    final $$SourcesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.sources,
      getReferencedColumn: (t) => t.workId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SourcesTableAnnotationComposer(
            $db: $db,
            $table: $db.sources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> textSpansRefs<T extends Object>(
    Expression<T> Function($$TextSpansTableAnnotationComposer a) f,
  ) {
    final $$TextSpansTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.textSpans,
      getReferencedColumn: (t) => t.workId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TextSpansTableAnnotationComposer(
            $db: $db,
            $table: $db.textSpans,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> readingSessionsRefs<T extends Object>(
    Expression<T> Function($$ReadingSessionsTableAnnotationComposer a) f,
  ) {
    final $$ReadingSessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.readingSessions,
      getReferencedColumn: (t) => t.workId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReadingSessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.readingSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> passageSnapshotsRefs<T extends Object>(
    Expression<T> Function($$PassageSnapshotsTableAnnotationComposer a) f,
  ) {
    final $$PassageSnapshotsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.passageSnapshots,
      getReferencedColumn: (t) => t.workId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PassageSnapshotsTableAnnotationComposer(
            $db: $db,
            $table: $db.passageSnapshots,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$WorksTableTableManager
    extends
        RootTableManager<
          _$MiningDb,
          $WorksTable,
          Work,
          $$WorksTableFilterComposer,
          $$WorksTableOrderingComposer,
          $$WorksTableAnnotationComposer,
          $$WorksTableCreateCompanionBuilder,
          $$WorksTableUpdateCompanionBuilder,
          (Work, $$WorksTableReferences),
          Work,
          PrefetchHooks Function({
            bool sourcesRefs,
            bool textSpansRefs,
            bool readingSessionsRefs,
            bool passageSnapshotsRefs,
          })
        > {
  $$WorksTableTableManager(_$MiningDb db, $WorksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WorksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WorksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WorksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> medium = const Value.absent(),
                Value<String> languageCode = const Value.absent(),
                Value<DateTime> addedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WorksCompanion(
                id: id,
                title: title,
                medium: medium,
                languageCode: languageCode,
                addedAt: addedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String title,
                required String medium,
                required String languageCode,
                required DateTime addedAt,
                Value<int> rowid = const Value.absent(),
              }) => WorksCompanion.insert(
                id: id,
                title: title,
                medium: medium,
                languageCode: languageCode,
                addedAt: addedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$WorksTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                sourcesRefs = false,
                textSpansRefs = false,
                readingSessionsRefs = false,
                passageSnapshotsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (sourcesRefs) db.sources,
                    if (textSpansRefs) db.textSpans,
                    if (readingSessionsRefs) db.readingSessions,
                    if (passageSnapshotsRefs) db.passageSnapshots,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (sourcesRefs)
                        await $_getPrefetchedData<Work, $WorksTable, Source>(
                          currentTable: table,
                          referencedTable: $$WorksTableReferences
                              ._sourcesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$WorksTableReferences(db, table, p0).sourcesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.workId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (textSpansRefs)
                        await $_getPrefetchedData<Work, $WorksTable, TextSpan>(
                          currentTable: table,
                          referencedTable: $$WorksTableReferences
                              ._textSpansRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$WorksTableReferences(
                                db,
                                table,
                                p0,
                              ).textSpansRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.workId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (readingSessionsRefs)
                        await $_getPrefetchedData<
                          Work,
                          $WorksTable,
                          ReadingSession
                        >(
                          currentTable: table,
                          referencedTable: $$WorksTableReferences
                              ._readingSessionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$WorksTableReferences(
                                db,
                                table,
                                p0,
                              ).readingSessionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.workId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (passageSnapshotsRefs)
                        await $_getPrefetchedData<
                          Work,
                          $WorksTable,
                          PassageSnapshot
                        >(
                          currentTable: table,
                          referencedTable: $$WorksTableReferences
                              ._passageSnapshotsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$WorksTableReferences(
                                db,
                                table,
                                p0,
                              ).passageSnapshotsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.workId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$WorksTableProcessedTableManager =
    ProcessedTableManager<
      _$MiningDb,
      $WorksTable,
      Work,
      $$WorksTableFilterComposer,
      $$WorksTableOrderingComposer,
      $$WorksTableAnnotationComposer,
      $$WorksTableCreateCompanionBuilder,
      $$WorksTableUpdateCompanionBuilder,
      (Work, $$WorksTableReferences),
      Work,
      PrefetchHooks Function({
        bool sourcesRefs,
        bool textSpansRefs,
        bool readingSessionsRefs,
        bool passageSnapshotsRefs,
      })
    >;
typedef $$SourcesTableCreateCompanionBuilder =
    SourcesCompanion Function({
      required String id,
      required String workId,
      required String kind,
      required String path,
      required DateTime importedAt,
      Value<int> rowid,
    });
typedef $$SourcesTableUpdateCompanionBuilder =
    SourcesCompanion Function({
      Value<String> id,
      Value<String> workId,
      Value<String> kind,
      Value<String> path,
      Value<DateTime> importedAt,
      Value<int> rowid,
    });

final class $$SourcesTableReferences
    extends BaseReferences<_$MiningDb, $SourcesTable, Source> {
  $$SourcesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $WorksTable _workIdTable(_$MiningDb db) => db.works.createAlias(
    $_aliasNameGenerator(db.sources.workId, db.works.id),
  );

  $$WorksTableProcessedTableManager get workId {
    final $_column = $_itemColumn<String>('work_id')!;

    final manager = $$WorksTableTableManager(
      $_db,
      $_db.works,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_workIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$TextSpansTable, List<TextSpan>>
  _textSpansRefsTable(_$MiningDb db) => MultiTypedResultKey.fromTable(
    db.textSpans,
    aliasName: $_aliasNameGenerator(db.sources.id, db.textSpans.sourceId),
  );

  $$TextSpansTableProcessedTableManager get textSpansRefs {
    final manager = $$TextSpansTableTableManager(
      $_db,
      $_db.textSpans,
    ).filter((f) => f.sourceId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_textSpansRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$SourcesTableFilterComposer extends Composer<_$MiningDb, $SourcesTable> {
  $$SourcesTableFilterComposer({
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

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get importedAt => $composableBuilder(
    column: $table.importedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$WorksTableFilterComposer get workId {
    final $$WorksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workId,
      referencedTable: $db.works,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorksTableFilterComposer(
            $db: $db,
            $table: $db.works,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> textSpansRefs(
    Expression<bool> Function($$TextSpansTableFilterComposer f) f,
  ) {
    final $$TextSpansTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.textSpans,
      getReferencedColumn: (t) => t.sourceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TextSpansTableFilterComposer(
            $db: $db,
            $table: $db.textSpans,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SourcesTableOrderingComposer
    extends Composer<_$MiningDb, $SourcesTable> {
  $$SourcesTableOrderingComposer({
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

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get importedAt => $composableBuilder(
    column: $table.importedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$WorksTableOrderingComposer get workId {
    final $$WorksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workId,
      referencedTable: $db.works,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorksTableOrderingComposer(
            $db: $db,
            $table: $db.works,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SourcesTableAnnotationComposer
    extends Composer<_$MiningDb, $SourcesTable> {
  $$SourcesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get path =>
      $composableBuilder(column: $table.path, builder: (column) => column);

  GeneratedColumn<DateTime> get importedAt => $composableBuilder(
    column: $table.importedAt,
    builder: (column) => column,
  );

  $$WorksTableAnnotationComposer get workId {
    final $$WorksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workId,
      referencedTable: $db.works,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorksTableAnnotationComposer(
            $db: $db,
            $table: $db.works,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> textSpansRefs<T extends Object>(
    Expression<T> Function($$TextSpansTableAnnotationComposer a) f,
  ) {
    final $$TextSpansTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.textSpans,
      getReferencedColumn: (t) => t.sourceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TextSpansTableAnnotationComposer(
            $db: $db,
            $table: $db.textSpans,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SourcesTableTableManager
    extends
        RootTableManager<
          _$MiningDb,
          $SourcesTable,
          Source,
          $$SourcesTableFilterComposer,
          $$SourcesTableOrderingComposer,
          $$SourcesTableAnnotationComposer,
          $$SourcesTableCreateCompanionBuilder,
          $$SourcesTableUpdateCompanionBuilder,
          (Source, $$SourcesTableReferences),
          Source,
          PrefetchHooks Function({bool workId, bool textSpansRefs})
        > {
  $$SourcesTableTableManager(_$MiningDb db, $SourcesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SourcesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SourcesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SourcesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> workId = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> path = const Value.absent(),
                Value<DateTime> importedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SourcesCompanion(
                id: id,
                workId: workId,
                kind: kind,
                path: path,
                importedAt: importedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String workId,
                required String kind,
                required String path,
                required DateTime importedAt,
                Value<int> rowid = const Value.absent(),
              }) => SourcesCompanion.insert(
                id: id,
                workId: workId,
                kind: kind,
                path: path,
                importedAt: importedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$SourcesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({workId = false, textSpansRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (textSpansRefs) db.textSpans],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (workId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.workId,
                                referencedTable: $$SourcesTableReferences
                                    ._workIdTable(db),
                                referencedColumn: $$SourcesTableReferences
                                    ._workIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (textSpansRefs)
                    await $_getPrefetchedData<Source, $SourcesTable, TextSpan>(
                      currentTable: table,
                      referencedTable: $$SourcesTableReferences
                          ._textSpansRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$SourcesTableReferences(db, table, p0).textSpansRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.sourceId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$SourcesTableProcessedTableManager =
    ProcessedTableManager<
      _$MiningDb,
      $SourcesTable,
      Source,
      $$SourcesTableFilterComposer,
      $$SourcesTableOrderingComposer,
      $$SourcesTableAnnotationComposer,
      $$SourcesTableCreateCompanionBuilder,
      $$SourcesTableUpdateCompanionBuilder,
      (Source, $$SourcesTableReferences),
      Source,
      PrefetchHooks Function({bool workId, bool textSpansRefs})
    >;
typedef $$TextSpansTableCreateCompanionBuilder =
    TextSpansCompanion Function({
      required String id,
      required String workId,
      required String sourceId,
      required int ordinal,
      required String content,
      required String anchorType,
      Value<int?> charStart,
      Value<int?> charEnd,
      Value<int?> tStartMs,
      Value<int?> tEndMs,
      Value<String?> pageId,
      Value<String?> rectJson,
      Value<int> rowid,
    });
typedef $$TextSpansTableUpdateCompanionBuilder =
    TextSpansCompanion Function({
      Value<String> id,
      Value<String> workId,
      Value<String> sourceId,
      Value<int> ordinal,
      Value<String> content,
      Value<String> anchorType,
      Value<int?> charStart,
      Value<int?> charEnd,
      Value<int?> tStartMs,
      Value<int?> tEndMs,
      Value<String?> pageId,
      Value<String?> rectJson,
      Value<int> rowid,
    });

final class $$TextSpansTableReferences
    extends BaseReferences<_$MiningDb, $TextSpansTable, TextSpan> {
  $$TextSpansTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $WorksTable _workIdTable(_$MiningDb db) => db.works.createAlias(
    $_aliasNameGenerator(db.textSpans.workId, db.works.id),
  );

  $$WorksTableProcessedTableManager get workId {
    final $_column = $_itemColumn<String>('work_id')!;

    final manager = $$WorksTableTableManager(
      $_db,
      $_db.works,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_workIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $SourcesTable _sourceIdTable(_$MiningDb db) => db.sources.createAlias(
    $_aliasNameGenerator(db.textSpans.sourceId, db.sources.id),
  );

  $$SourcesTableProcessedTableManager get sourceId {
    final $_column = $_itemColumn<String>('source_id')!;

    final manager = $$SourcesTableTableManager(
      $_db,
      $_db.sources,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sourceIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$TokenOccurrencesTable, List<TokenOccurrence>>
  _tokenOccurrencesRefsTable(_$MiningDb db) => MultiTypedResultKey.fromTable(
    db.tokenOccurrences,
    aliasName: $_aliasNameGenerator(
      db.textSpans.id,
      db.tokenOccurrences.textSpanId,
    ),
  );

  $$TokenOccurrencesTableProcessedTableManager get tokenOccurrencesRefs {
    final manager = $$TokenOccurrencesTableTableManager(
      $_db,
      $_db.tokenOccurrences,
    ).filter((f) => f.textSpanId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _tokenOccurrencesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$CardsTable, List<Card>> _cardsRefsTable(
    _$MiningDb db,
  ) => MultiTypedResultKey.fromTable(
    db.cards,
    aliasName: $_aliasNameGenerator(
      db.textSpans.id,
      db.cards.contextTextSpanId,
    ),
  );

  $$CardsTableProcessedTableManager get cardsRefs {
    final manager = $$CardsTableTableManager($_db, $_db.cards).filter(
      (f) => f.contextTextSpanId.id.sqlEquals($_itemColumn<String>('id')!),
    );

    final cache = $_typedResult.readTableOrNull(_cardsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$TextSpansTableFilterComposer
    extends Composer<_$MiningDb, $TextSpansTable> {
  $$TextSpansTableFilterComposer({
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

  ColumnFilters<int> get ordinal => $composableBuilder(
    column: $table.ordinal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get anchorType => $composableBuilder(
    column: $table.anchorType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get charStart => $composableBuilder(
    column: $table.charStart,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get charEnd => $composableBuilder(
    column: $table.charEnd,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tStartMs => $composableBuilder(
    column: $table.tStartMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tEndMs => $composableBuilder(
    column: $table.tEndMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pageId => $composableBuilder(
    column: $table.pageId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rectJson => $composableBuilder(
    column: $table.rectJson,
    builder: (column) => ColumnFilters(column),
  );

  $$WorksTableFilterComposer get workId {
    final $$WorksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workId,
      referencedTable: $db.works,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorksTableFilterComposer(
            $db: $db,
            $table: $db.works,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$SourcesTableFilterComposer get sourceId {
    final $$SourcesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceId,
      referencedTable: $db.sources,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SourcesTableFilterComposer(
            $db: $db,
            $table: $db.sources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> tokenOccurrencesRefs(
    Expression<bool> Function($$TokenOccurrencesTableFilterComposer f) f,
  ) {
    final $$TokenOccurrencesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.tokenOccurrences,
      getReferencedColumn: (t) => t.textSpanId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TokenOccurrencesTableFilterComposer(
            $db: $db,
            $table: $db.tokenOccurrences,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> cardsRefs(
    Expression<bool> Function($$CardsTableFilterComposer f) f,
  ) {
    final $$CardsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.cards,
      getReferencedColumn: (t) => t.contextTextSpanId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CardsTableFilterComposer(
            $db: $db,
            $table: $db.cards,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TextSpansTableOrderingComposer
    extends Composer<_$MiningDb, $TextSpansTable> {
  $$TextSpansTableOrderingComposer({
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

  ColumnOrderings<int> get ordinal => $composableBuilder(
    column: $table.ordinal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get anchorType => $composableBuilder(
    column: $table.anchorType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get charStart => $composableBuilder(
    column: $table.charStart,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get charEnd => $composableBuilder(
    column: $table.charEnd,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tStartMs => $composableBuilder(
    column: $table.tStartMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tEndMs => $composableBuilder(
    column: $table.tEndMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pageId => $composableBuilder(
    column: $table.pageId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rectJson => $composableBuilder(
    column: $table.rectJson,
    builder: (column) => ColumnOrderings(column),
  );

  $$WorksTableOrderingComposer get workId {
    final $$WorksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workId,
      referencedTable: $db.works,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorksTableOrderingComposer(
            $db: $db,
            $table: $db.works,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$SourcesTableOrderingComposer get sourceId {
    final $$SourcesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceId,
      referencedTable: $db.sources,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SourcesTableOrderingComposer(
            $db: $db,
            $table: $db.sources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TextSpansTableAnnotationComposer
    extends Composer<_$MiningDb, $TextSpansTable> {
  $$TextSpansTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get ordinal =>
      $composableBuilder(column: $table.ordinal, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<String> get anchorType => $composableBuilder(
    column: $table.anchorType,
    builder: (column) => column,
  );

  GeneratedColumn<int> get charStart =>
      $composableBuilder(column: $table.charStart, builder: (column) => column);

  GeneratedColumn<int> get charEnd =>
      $composableBuilder(column: $table.charEnd, builder: (column) => column);

  GeneratedColumn<int> get tStartMs =>
      $composableBuilder(column: $table.tStartMs, builder: (column) => column);

  GeneratedColumn<int> get tEndMs =>
      $composableBuilder(column: $table.tEndMs, builder: (column) => column);

  GeneratedColumn<String> get pageId =>
      $composableBuilder(column: $table.pageId, builder: (column) => column);

  GeneratedColumn<String> get rectJson =>
      $composableBuilder(column: $table.rectJson, builder: (column) => column);

  $$WorksTableAnnotationComposer get workId {
    final $$WorksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workId,
      referencedTable: $db.works,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorksTableAnnotationComposer(
            $db: $db,
            $table: $db.works,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$SourcesTableAnnotationComposer get sourceId {
    final $$SourcesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceId,
      referencedTable: $db.sources,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SourcesTableAnnotationComposer(
            $db: $db,
            $table: $db.sources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> tokenOccurrencesRefs<T extends Object>(
    Expression<T> Function($$TokenOccurrencesTableAnnotationComposer a) f,
  ) {
    final $$TokenOccurrencesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.tokenOccurrences,
      getReferencedColumn: (t) => t.textSpanId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TokenOccurrencesTableAnnotationComposer(
            $db: $db,
            $table: $db.tokenOccurrences,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> cardsRefs<T extends Object>(
    Expression<T> Function($$CardsTableAnnotationComposer a) f,
  ) {
    final $$CardsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.cards,
      getReferencedColumn: (t) => t.contextTextSpanId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CardsTableAnnotationComposer(
            $db: $db,
            $table: $db.cards,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TextSpansTableTableManager
    extends
        RootTableManager<
          _$MiningDb,
          $TextSpansTable,
          TextSpan,
          $$TextSpansTableFilterComposer,
          $$TextSpansTableOrderingComposer,
          $$TextSpansTableAnnotationComposer,
          $$TextSpansTableCreateCompanionBuilder,
          $$TextSpansTableUpdateCompanionBuilder,
          (TextSpan, $$TextSpansTableReferences),
          TextSpan,
          PrefetchHooks Function({
            bool workId,
            bool sourceId,
            bool tokenOccurrencesRefs,
            bool cardsRefs,
          })
        > {
  $$TextSpansTableTableManager(_$MiningDb db, $TextSpansTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TextSpansTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TextSpansTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TextSpansTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> workId = const Value.absent(),
                Value<String> sourceId = const Value.absent(),
                Value<int> ordinal = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<String> anchorType = const Value.absent(),
                Value<int?> charStart = const Value.absent(),
                Value<int?> charEnd = const Value.absent(),
                Value<int?> tStartMs = const Value.absent(),
                Value<int?> tEndMs = const Value.absent(),
                Value<String?> pageId = const Value.absent(),
                Value<String?> rectJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TextSpansCompanion(
                id: id,
                workId: workId,
                sourceId: sourceId,
                ordinal: ordinal,
                content: content,
                anchorType: anchorType,
                charStart: charStart,
                charEnd: charEnd,
                tStartMs: tStartMs,
                tEndMs: tEndMs,
                pageId: pageId,
                rectJson: rectJson,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String workId,
                required String sourceId,
                required int ordinal,
                required String content,
                required String anchorType,
                Value<int?> charStart = const Value.absent(),
                Value<int?> charEnd = const Value.absent(),
                Value<int?> tStartMs = const Value.absent(),
                Value<int?> tEndMs = const Value.absent(),
                Value<String?> pageId = const Value.absent(),
                Value<String?> rectJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TextSpansCompanion.insert(
                id: id,
                workId: workId,
                sourceId: sourceId,
                ordinal: ordinal,
                content: content,
                anchorType: anchorType,
                charStart: charStart,
                charEnd: charEnd,
                tStartMs: tStartMs,
                tEndMs: tEndMs,
                pageId: pageId,
                rectJson: rectJson,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$TextSpansTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                workId = false,
                sourceId = false,
                tokenOccurrencesRefs = false,
                cardsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (tokenOccurrencesRefs) db.tokenOccurrences,
                    if (cardsRefs) db.cards,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (workId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.workId,
                                    referencedTable: $$TextSpansTableReferences
                                        ._workIdTable(db),
                                    referencedColumn: $$TextSpansTableReferences
                                        ._workIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }
                        if (sourceId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.sourceId,
                                    referencedTable: $$TextSpansTableReferences
                                        ._sourceIdTable(db),
                                    referencedColumn: $$TextSpansTableReferences
                                        ._sourceIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (tokenOccurrencesRefs)
                        await $_getPrefetchedData<
                          TextSpan,
                          $TextSpansTable,
                          TokenOccurrence
                        >(
                          currentTable: table,
                          referencedTable: $$TextSpansTableReferences
                              ._tokenOccurrencesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TextSpansTableReferences(
                                db,
                                table,
                                p0,
                              ).tokenOccurrencesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.textSpanId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (cardsRefs)
                        await $_getPrefetchedData<
                          TextSpan,
                          $TextSpansTable,
                          Card
                        >(
                          currentTable: table,
                          referencedTable: $$TextSpansTableReferences
                              ._cardsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TextSpansTableReferences(
                                db,
                                table,
                                p0,
                              ).cardsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.contextTextSpanId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$TextSpansTableProcessedTableManager =
    ProcessedTableManager<
      _$MiningDb,
      $TextSpansTable,
      TextSpan,
      $$TextSpansTableFilterComposer,
      $$TextSpansTableOrderingComposer,
      $$TextSpansTableAnnotationComposer,
      $$TextSpansTableCreateCompanionBuilder,
      $$TextSpansTableUpdateCompanionBuilder,
      (TextSpan, $$TextSpansTableReferences),
      TextSpan,
      PrefetchHooks Function({
        bool workId,
        bool sourceId,
        bool tokenOccurrencesRefs,
        bool cardsRefs,
      })
    >;
typedef $$TokenOccurrencesTableCreateCompanionBuilder =
    TokenOccurrencesCompanion Function({
      required String id,
      required String textSpanId,
      required String lemma,
      required String surface,
      Value<String?> reading,
      required String pos,
      required int charStart,
      required int charEnd,
      Value<int> rowid,
    });
typedef $$TokenOccurrencesTableUpdateCompanionBuilder =
    TokenOccurrencesCompanion Function({
      Value<String> id,
      Value<String> textSpanId,
      Value<String> lemma,
      Value<String> surface,
      Value<String?> reading,
      Value<String> pos,
      Value<int> charStart,
      Value<int> charEnd,
      Value<int> rowid,
    });

final class $$TokenOccurrencesTableReferences
    extends
        BaseReferences<_$MiningDb, $TokenOccurrencesTable, TokenOccurrence> {
  $$TokenOccurrencesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $TextSpansTable _textSpanIdTable(_$MiningDb db) =>
      db.textSpans.createAlias(
        $_aliasNameGenerator(db.tokenOccurrences.textSpanId, db.textSpans.id),
      );

  $$TextSpansTableProcessedTableManager get textSpanId {
    final $_column = $_itemColumn<String>('text_span_id')!;

    final manager = $$TextSpansTableTableManager(
      $_db,
      $_db.textSpans,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_textSpanIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$TokenOccurrencesTableFilterComposer
    extends Composer<_$MiningDb, $TokenOccurrencesTable> {
  $$TokenOccurrencesTableFilterComposer({
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

  ColumnFilters<String> get lemma => $composableBuilder(
    column: $table.lemma,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get surface => $composableBuilder(
    column: $table.surface,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reading => $composableBuilder(
    column: $table.reading,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pos => $composableBuilder(
    column: $table.pos,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get charStart => $composableBuilder(
    column: $table.charStart,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get charEnd => $composableBuilder(
    column: $table.charEnd,
    builder: (column) => ColumnFilters(column),
  );

  $$TextSpansTableFilterComposer get textSpanId {
    final $$TextSpansTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.textSpanId,
      referencedTable: $db.textSpans,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TextSpansTableFilterComposer(
            $db: $db,
            $table: $db.textSpans,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TokenOccurrencesTableOrderingComposer
    extends Composer<_$MiningDb, $TokenOccurrencesTable> {
  $$TokenOccurrencesTableOrderingComposer({
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

  ColumnOrderings<String> get lemma => $composableBuilder(
    column: $table.lemma,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get surface => $composableBuilder(
    column: $table.surface,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reading => $composableBuilder(
    column: $table.reading,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pos => $composableBuilder(
    column: $table.pos,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get charStart => $composableBuilder(
    column: $table.charStart,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get charEnd => $composableBuilder(
    column: $table.charEnd,
    builder: (column) => ColumnOrderings(column),
  );

  $$TextSpansTableOrderingComposer get textSpanId {
    final $$TextSpansTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.textSpanId,
      referencedTable: $db.textSpans,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TextSpansTableOrderingComposer(
            $db: $db,
            $table: $db.textSpans,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TokenOccurrencesTableAnnotationComposer
    extends Composer<_$MiningDb, $TokenOccurrencesTable> {
  $$TokenOccurrencesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get lemma =>
      $composableBuilder(column: $table.lemma, builder: (column) => column);

  GeneratedColumn<String> get surface =>
      $composableBuilder(column: $table.surface, builder: (column) => column);

  GeneratedColumn<String> get reading =>
      $composableBuilder(column: $table.reading, builder: (column) => column);

  GeneratedColumn<String> get pos =>
      $composableBuilder(column: $table.pos, builder: (column) => column);

  GeneratedColumn<int> get charStart =>
      $composableBuilder(column: $table.charStart, builder: (column) => column);

  GeneratedColumn<int> get charEnd =>
      $composableBuilder(column: $table.charEnd, builder: (column) => column);

  $$TextSpansTableAnnotationComposer get textSpanId {
    final $$TextSpansTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.textSpanId,
      referencedTable: $db.textSpans,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TextSpansTableAnnotationComposer(
            $db: $db,
            $table: $db.textSpans,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TokenOccurrencesTableTableManager
    extends
        RootTableManager<
          _$MiningDb,
          $TokenOccurrencesTable,
          TokenOccurrence,
          $$TokenOccurrencesTableFilterComposer,
          $$TokenOccurrencesTableOrderingComposer,
          $$TokenOccurrencesTableAnnotationComposer,
          $$TokenOccurrencesTableCreateCompanionBuilder,
          $$TokenOccurrencesTableUpdateCompanionBuilder,
          (TokenOccurrence, $$TokenOccurrencesTableReferences),
          TokenOccurrence,
          PrefetchHooks Function({bool textSpanId})
        > {
  $$TokenOccurrencesTableTableManager(
    _$MiningDb db,
    $TokenOccurrencesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TokenOccurrencesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TokenOccurrencesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TokenOccurrencesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> textSpanId = const Value.absent(),
                Value<String> lemma = const Value.absent(),
                Value<String> surface = const Value.absent(),
                Value<String?> reading = const Value.absent(),
                Value<String> pos = const Value.absent(),
                Value<int> charStart = const Value.absent(),
                Value<int> charEnd = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TokenOccurrencesCompanion(
                id: id,
                textSpanId: textSpanId,
                lemma: lemma,
                surface: surface,
                reading: reading,
                pos: pos,
                charStart: charStart,
                charEnd: charEnd,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String textSpanId,
                required String lemma,
                required String surface,
                Value<String?> reading = const Value.absent(),
                required String pos,
                required int charStart,
                required int charEnd,
                Value<int> rowid = const Value.absent(),
              }) => TokenOccurrencesCompanion.insert(
                id: id,
                textSpanId: textSpanId,
                lemma: lemma,
                surface: surface,
                reading: reading,
                pos: pos,
                charStart: charStart,
                charEnd: charEnd,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$TokenOccurrencesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({textSpanId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (textSpanId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.textSpanId,
                                referencedTable:
                                    $$TokenOccurrencesTableReferences
                                        ._textSpanIdTable(db),
                                referencedColumn:
                                    $$TokenOccurrencesTableReferences
                                        ._textSpanIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$TokenOccurrencesTableProcessedTableManager =
    ProcessedTableManager<
      _$MiningDb,
      $TokenOccurrencesTable,
      TokenOccurrence,
      $$TokenOccurrencesTableFilterComposer,
      $$TokenOccurrencesTableOrderingComposer,
      $$TokenOccurrencesTableAnnotationComposer,
      $$TokenOccurrencesTableCreateCompanionBuilder,
      $$TokenOccurrencesTableUpdateCompanionBuilder,
      (TokenOccurrence, $$TokenOccurrencesTableReferences),
      TokenOccurrence,
      PrefetchHooks Function({bool textSpanId})
    >;
typedef $$VocabItemsTableCreateCompanionBuilder =
    VocabItemsCompanion Function({
      required String id,
      required String languageCode,
      required String lemma,
      required String pos,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$VocabItemsTableUpdateCompanionBuilder =
    VocabItemsCompanion Function({
      Value<String> id,
      Value<String> languageCode,
      Value<String> lemma,
      Value<String> pos,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$VocabItemsTableReferences
    extends BaseReferences<_$MiningDb, $VocabItemsTable, VocabItem> {
  $$VocabItemsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$CardsTable, List<Card>> _cardsRefsTable(
    _$MiningDb db,
  ) => MultiTypedResultKey.fromTable(
    db.cards,
    aliasName: $_aliasNameGenerator(db.vocabItems.id, db.cards.vocabItemId),
  );

  $$CardsTableProcessedTableManager get cardsRefs {
    final manager = $$CardsTableTableManager(
      $_db,
      $_db.cards,
    ).filter((f) => f.vocabItemId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_cardsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$VocabItemsTableFilterComposer
    extends Composer<_$MiningDb, $VocabItemsTable> {
  $$VocabItemsTableFilterComposer({
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

  ColumnFilters<String> get languageCode => $composableBuilder(
    column: $table.languageCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lemma => $composableBuilder(
    column: $table.lemma,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pos => $composableBuilder(
    column: $table.pos,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> cardsRefs(
    Expression<bool> Function($$CardsTableFilterComposer f) f,
  ) {
    final $$CardsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.cards,
      getReferencedColumn: (t) => t.vocabItemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CardsTableFilterComposer(
            $db: $db,
            $table: $db.cards,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$VocabItemsTableOrderingComposer
    extends Composer<_$MiningDb, $VocabItemsTable> {
  $$VocabItemsTableOrderingComposer({
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

  ColumnOrderings<String> get languageCode => $composableBuilder(
    column: $table.languageCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lemma => $composableBuilder(
    column: $table.lemma,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pos => $composableBuilder(
    column: $table.pos,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$VocabItemsTableAnnotationComposer
    extends Composer<_$MiningDb, $VocabItemsTable> {
  $$VocabItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get languageCode => $composableBuilder(
    column: $table.languageCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lemma =>
      $composableBuilder(column: $table.lemma, builder: (column) => column);

  GeneratedColumn<String> get pos =>
      $composableBuilder(column: $table.pos, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> cardsRefs<T extends Object>(
    Expression<T> Function($$CardsTableAnnotationComposer a) f,
  ) {
    final $$CardsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.cards,
      getReferencedColumn: (t) => t.vocabItemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CardsTableAnnotationComposer(
            $db: $db,
            $table: $db.cards,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$VocabItemsTableTableManager
    extends
        RootTableManager<
          _$MiningDb,
          $VocabItemsTable,
          VocabItem,
          $$VocabItemsTableFilterComposer,
          $$VocabItemsTableOrderingComposer,
          $$VocabItemsTableAnnotationComposer,
          $$VocabItemsTableCreateCompanionBuilder,
          $$VocabItemsTableUpdateCompanionBuilder,
          (VocabItem, $$VocabItemsTableReferences),
          VocabItem,
          PrefetchHooks Function({bool cardsRefs})
        > {
  $$VocabItemsTableTableManager(_$MiningDb db, $VocabItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VocabItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VocabItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VocabItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> languageCode = const Value.absent(),
                Value<String> lemma = const Value.absent(),
                Value<String> pos = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VocabItemsCompanion(
                id: id,
                languageCode: languageCode,
                lemma: lemma,
                pos: pos,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String languageCode,
                required String lemma,
                required String pos,
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => VocabItemsCompanion.insert(
                id: id,
                languageCode: languageCode,
                lemma: lemma,
                pos: pos,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$VocabItemsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({cardsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (cardsRefs) db.cards],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (cardsRefs)
                    await $_getPrefetchedData<
                      VocabItem,
                      $VocabItemsTable,
                      Card
                    >(
                      currentTable: table,
                      referencedTable: $$VocabItemsTableReferences
                          ._cardsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$VocabItemsTableReferences(db, table, p0).cardsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.vocabItemId == item.id,
                          ),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$VocabItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$MiningDb,
      $VocabItemsTable,
      VocabItem,
      $$VocabItemsTableFilterComposer,
      $$VocabItemsTableOrderingComposer,
      $$VocabItemsTableAnnotationComposer,
      $$VocabItemsTableCreateCompanionBuilder,
      $$VocabItemsTableUpdateCompanionBuilder,
      (VocabItem, $$VocabItemsTableReferences),
      VocabItem,
      PrefetchHooks Function({bool cardsRefs})
    >;
typedef $$CardsTableCreateCompanionBuilder =
    CardsCompanion Function({
      required String id,
      required String vocabItemId,
      Value<String?> contextTextSpanId,
      Value<String> state,
      Value<double> stability,
      Value<double> difficulty,
      Value<int> elapsedDays,
      Value<int> scheduledDays,
      Value<int> reps,
      Value<int> lapses,
      required DateTime due,
      required DateTime lastReview,
      Value<int> rowid,
    });
typedef $$CardsTableUpdateCompanionBuilder =
    CardsCompanion Function({
      Value<String> id,
      Value<String> vocabItemId,
      Value<String?> contextTextSpanId,
      Value<String> state,
      Value<double> stability,
      Value<double> difficulty,
      Value<int> elapsedDays,
      Value<int> scheduledDays,
      Value<int> reps,
      Value<int> lapses,
      Value<DateTime> due,
      Value<DateTime> lastReview,
      Value<int> rowid,
    });

final class $$CardsTableReferences
    extends BaseReferences<_$MiningDb, $CardsTable, Card> {
  $$CardsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $VocabItemsTable _vocabItemIdTable(_$MiningDb db) =>
      db.vocabItems.createAlias(
        $_aliasNameGenerator(db.cards.vocabItemId, db.vocabItems.id),
      );

  $$VocabItemsTableProcessedTableManager get vocabItemId {
    final $_column = $_itemColumn<String>('vocab_item_id')!;

    final manager = $$VocabItemsTableTableManager(
      $_db,
      $_db.vocabItems,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_vocabItemIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $TextSpansTable _contextTextSpanIdTable(_$MiningDb db) =>
      db.textSpans.createAlias(
        $_aliasNameGenerator(db.cards.contextTextSpanId, db.textSpans.id),
      );

  $$TextSpansTableProcessedTableManager? get contextTextSpanId {
    final $_column = $_itemColumn<String>('context_text_span_id');
    if ($_column == null) return null;
    final manager = $$TextSpansTableTableManager(
      $_db,
      $_db.textSpans,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_contextTextSpanIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$ReviewLogsTable, List<ReviewLog>>
  _reviewLogsRefsTable(_$MiningDb db) => MultiTypedResultKey.fromTable(
    db.reviewLogs,
    aliasName: $_aliasNameGenerator(db.cards.id, db.reviewLogs.cardId),
  );

  $$ReviewLogsTableProcessedTableManager get reviewLogsRefs {
    final manager = $$ReviewLogsTableTableManager(
      $_db,
      $_db.reviewLogs,
    ).filter((f) => f.cardId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_reviewLogsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CardsTableFilterComposer extends Composer<_$MiningDb, $CardsTable> {
  $$CardsTableFilterComposer({
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

  ColumnFilters<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get stability => $composableBuilder(
    column: $table.stability,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get elapsedDays => $composableBuilder(
    column: $table.elapsedDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get scheduledDays => $composableBuilder(
    column: $table.scheduledDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reps => $composableBuilder(
    column: $table.reps,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lapses => $composableBuilder(
    column: $table.lapses,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get due => $composableBuilder(
    column: $table.due,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastReview => $composableBuilder(
    column: $table.lastReview,
    builder: (column) => ColumnFilters(column),
  );

  $$VocabItemsTableFilterComposer get vocabItemId {
    final $$VocabItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.vocabItemId,
      referencedTable: $db.vocabItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VocabItemsTableFilterComposer(
            $db: $db,
            $table: $db.vocabItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TextSpansTableFilterComposer get contextTextSpanId {
    final $$TextSpansTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.contextTextSpanId,
      referencedTable: $db.textSpans,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TextSpansTableFilterComposer(
            $db: $db,
            $table: $db.textSpans,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> reviewLogsRefs(
    Expression<bool> Function($$ReviewLogsTableFilterComposer f) f,
  ) {
    final $$ReviewLogsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.reviewLogs,
      getReferencedColumn: (t) => t.cardId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReviewLogsTableFilterComposer(
            $db: $db,
            $table: $db.reviewLogs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CardsTableOrderingComposer extends Composer<_$MiningDb, $CardsTable> {
  $$CardsTableOrderingComposer({
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

  ColumnOrderings<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get stability => $composableBuilder(
    column: $table.stability,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get elapsedDays => $composableBuilder(
    column: $table.elapsedDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get scheduledDays => $composableBuilder(
    column: $table.scheduledDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reps => $composableBuilder(
    column: $table.reps,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lapses => $composableBuilder(
    column: $table.lapses,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get due => $composableBuilder(
    column: $table.due,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastReview => $composableBuilder(
    column: $table.lastReview,
    builder: (column) => ColumnOrderings(column),
  );

  $$VocabItemsTableOrderingComposer get vocabItemId {
    final $$VocabItemsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.vocabItemId,
      referencedTable: $db.vocabItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VocabItemsTableOrderingComposer(
            $db: $db,
            $table: $db.vocabItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TextSpansTableOrderingComposer get contextTextSpanId {
    final $$TextSpansTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.contextTextSpanId,
      referencedTable: $db.textSpans,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TextSpansTableOrderingComposer(
            $db: $db,
            $table: $db.textSpans,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CardsTableAnnotationComposer extends Composer<_$MiningDb, $CardsTable> {
  $$CardsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<double> get stability =>
      $composableBuilder(column: $table.stability, builder: (column) => column);

  GeneratedColumn<double> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => column,
  );

  GeneratedColumn<int> get elapsedDays => $composableBuilder(
    column: $table.elapsedDays,
    builder: (column) => column,
  );

  GeneratedColumn<int> get scheduledDays => $composableBuilder(
    column: $table.scheduledDays,
    builder: (column) => column,
  );

  GeneratedColumn<int> get reps =>
      $composableBuilder(column: $table.reps, builder: (column) => column);

  GeneratedColumn<int> get lapses =>
      $composableBuilder(column: $table.lapses, builder: (column) => column);

  GeneratedColumn<DateTime> get due =>
      $composableBuilder(column: $table.due, builder: (column) => column);

  GeneratedColumn<DateTime> get lastReview => $composableBuilder(
    column: $table.lastReview,
    builder: (column) => column,
  );

  $$VocabItemsTableAnnotationComposer get vocabItemId {
    final $$VocabItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.vocabItemId,
      referencedTable: $db.vocabItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VocabItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.vocabItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TextSpansTableAnnotationComposer get contextTextSpanId {
    final $$TextSpansTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.contextTextSpanId,
      referencedTable: $db.textSpans,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TextSpansTableAnnotationComposer(
            $db: $db,
            $table: $db.textSpans,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> reviewLogsRefs<T extends Object>(
    Expression<T> Function($$ReviewLogsTableAnnotationComposer a) f,
  ) {
    final $$ReviewLogsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.reviewLogs,
      getReferencedColumn: (t) => t.cardId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReviewLogsTableAnnotationComposer(
            $db: $db,
            $table: $db.reviewLogs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CardsTableTableManager
    extends
        RootTableManager<
          _$MiningDb,
          $CardsTable,
          Card,
          $$CardsTableFilterComposer,
          $$CardsTableOrderingComposer,
          $$CardsTableAnnotationComposer,
          $$CardsTableCreateCompanionBuilder,
          $$CardsTableUpdateCompanionBuilder,
          (Card, $$CardsTableReferences),
          Card,
          PrefetchHooks Function({
            bool vocabItemId,
            bool contextTextSpanId,
            bool reviewLogsRefs,
          })
        > {
  $$CardsTableTableManager(_$MiningDb db, $CardsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CardsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CardsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CardsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> vocabItemId = const Value.absent(),
                Value<String?> contextTextSpanId = const Value.absent(),
                Value<String> state = const Value.absent(),
                Value<double> stability = const Value.absent(),
                Value<double> difficulty = const Value.absent(),
                Value<int> elapsedDays = const Value.absent(),
                Value<int> scheduledDays = const Value.absent(),
                Value<int> reps = const Value.absent(),
                Value<int> lapses = const Value.absent(),
                Value<DateTime> due = const Value.absent(),
                Value<DateTime> lastReview = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CardsCompanion(
                id: id,
                vocabItemId: vocabItemId,
                contextTextSpanId: contextTextSpanId,
                state: state,
                stability: stability,
                difficulty: difficulty,
                elapsedDays: elapsedDays,
                scheduledDays: scheduledDays,
                reps: reps,
                lapses: lapses,
                due: due,
                lastReview: lastReview,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String vocabItemId,
                Value<String?> contextTextSpanId = const Value.absent(),
                Value<String> state = const Value.absent(),
                Value<double> stability = const Value.absent(),
                Value<double> difficulty = const Value.absent(),
                Value<int> elapsedDays = const Value.absent(),
                Value<int> scheduledDays = const Value.absent(),
                Value<int> reps = const Value.absent(),
                Value<int> lapses = const Value.absent(),
                required DateTime due,
                required DateTime lastReview,
                Value<int> rowid = const Value.absent(),
              }) => CardsCompanion.insert(
                id: id,
                vocabItemId: vocabItemId,
                contextTextSpanId: contextTextSpanId,
                state: state,
                stability: stability,
                difficulty: difficulty,
                elapsedDays: elapsedDays,
                scheduledDays: scheduledDays,
                reps: reps,
                lapses: lapses,
                due: due,
                lastReview: lastReview,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$CardsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                vocabItemId = false,
                contextTextSpanId = false,
                reviewLogsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [if (reviewLogsRefs) db.reviewLogs],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (vocabItemId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.vocabItemId,
                                    referencedTable: $$CardsTableReferences
                                        ._vocabItemIdTable(db),
                                    referencedColumn: $$CardsTableReferences
                                        ._vocabItemIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }
                        if (contextTextSpanId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.contextTextSpanId,
                                    referencedTable: $$CardsTableReferences
                                        ._contextTextSpanIdTable(db),
                                    referencedColumn: $$CardsTableReferences
                                        ._contextTextSpanIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (reviewLogsRefs)
                        await $_getPrefetchedData<Card, $CardsTable, ReviewLog>(
                          currentTable: table,
                          referencedTable: $$CardsTableReferences
                              ._reviewLogsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CardsTableReferences(
                                db,
                                table,
                                p0,
                              ).reviewLogsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.cardId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$CardsTableProcessedTableManager =
    ProcessedTableManager<
      _$MiningDb,
      $CardsTable,
      Card,
      $$CardsTableFilterComposer,
      $$CardsTableOrderingComposer,
      $$CardsTableAnnotationComposer,
      $$CardsTableCreateCompanionBuilder,
      $$CardsTableUpdateCompanionBuilder,
      (Card, $$CardsTableReferences),
      Card,
      PrefetchHooks Function({
        bool vocabItemId,
        bool contextTextSpanId,
        bool reviewLogsRefs,
      })
    >;
typedef $$ReviewLogsTableCreateCompanionBuilder =
    ReviewLogsCompanion Function({
      required String id,
      required String cardId,
      required String rating,
      required DateTime reviewDateTime,
      Value<int?> reviewDurationMs,
      Value<double?> stabilityBefore,
      Value<double?> stabilityAfter,
      Value<int> rowid,
    });
typedef $$ReviewLogsTableUpdateCompanionBuilder =
    ReviewLogsCompanion Function({
      Value<String> id,
      Value<String> cardId,
      Value<String> rating,
      Value<DateTime> reviewDateTime,
      Value<int?> reviewDurationMs,
      Value<double?> stabilityBefore,
      Value<double?> stabilityAfter,
      Value<int> rowid,
    });

final class $$ReviewLogsTableReferences
    extends BaseReferences<_$MiningDb, $ReviewLogsTable, ReviewLog> {
  $$ReviewLogsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CardsTable _cardIdTable(_$MiningDb db) => db.cards.createAlias(
    $_aliasNameGenerator(db.reviewLogs.cardId, db.cards.id),
  );

  $$CardsTableProcessedTableManager get cardId {
    final $_column = $_itemColumn<String>('card_id')!;

    final manager = $$CardsTableTableManager(
      $_db,
      $_db.cards,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_cardIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ReviewLogsTableFilterComposer
    extends Composer<_$MiningDb, $ReviewLogsTable> {
  $$ReviewLogsTableFilterComposer({
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

  ColumnFilters<String> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get reviewDateTime => $composableBuilder(
    column: $table.reviewDateTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reviewDurationMs => $composableBuilder(
    column: $table.reviewDurationMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get stabilityBefore => $composableBuilder(
    column: $table.stabilityBefore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get stabilityAfter => $composableBuilder(
    column: $table.stabilityAfter,
    builder: (column) => ColumnFilters(column),
  );

  $$CardsTableFilterComposer get cardId {
    final $$CardsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cardId,
      referencedTable: $db.cards,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CardsTableFilterComposer(
            $db: $db,
            $table: $db.cards,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReviewLogsTableOrderingComposer
    extends Composer<_$MiningDb, $ReviewLogsTable> {
  $$ReviewLogsTableOrderingComposer({
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

  ColumnOrderings<String> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get reviewDateTime => $composableBuilder(
    column: $table.reviewDateTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reviewDurationMs => $composableBuilder(
    column: $table.reviewDurationMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get stabilityBefore => $composableBuilder(
    column: $table.stabilityBefore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get stabilityAfter => $composableBuilder(
    column: $table.stabilityAfter,
    builder: (column) => ColumnOrderings(column),
  );

  $$CardsTableOrderingComposer get cardId {
    final $$CardsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cardId,
      referencedTable: $db.cards,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CardsTableOrderingComposer(
            $db: $db,
            $table: $db.cards,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReviewLogsTableAnnotationComposer
    extends Composer<_$MiningDb, $ReviewLogsTable> {
  $$ReviewLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get rating =>
      $composableBuilder(column: $table.rating, builder: (column) => column);

  GeneratedColumn<DateTime> get reviewDateTime => $composableBuilder(
    column: $table.reviewDateTime,
    builder: (column) => column,
  );

  GeneratedColumn<int> get reviewDurationMs => $composableBuilder(
    column: $table.reviewDurationMs,
    builder: (column) => column,
  );

  GeneratedColumn<double> get stabilityBefore => $composableBuilder(
    column: $table.stabilityBefore,
    builder: (column) => column,
  );

  GeneratedColumn<double> get stabilityAfter => $composableBuilder(
    column: $table.stabilityAfter,
    builder: (column) => column,
  );

  $$CardsTableAnnotationComposer get cardId {
    final $$CardsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cardId,
      referencedTable: $db.cards,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CardsTableAnnotationComposer(
            $db: $db,
            $table: $db.cards,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReviewLogsTableTableManager
    extends
        RootTableManager<
          _$MiningDb,
          $ReviewLogsTable,
          ReviewLog,
          $$ReviewLogsTableFilterComposer,
          $$ReviewLogsTableOrderingComposer,
          $$ReviewLogsTableAnnotationComposer,
          $$ReviewLogsTableCreateCompanionBuilder,
          $$ReviewLogsTableUpdateCompanionBuilder,
          (ReviewLog, $$ReviewLogsTableReferences),
          ReviewLog,
          PrefetchHooks Function({bool cardId})
        > {
  $$ReviewLogsTableTableManager(_$MiningDb db, $ReviewLogsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReviewLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReviewLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReviewLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> cardId = const Value.absent(),
                Value<String> rating = const Value.absent(),
                Value<DateTime> reviewDateTime = const Value.absent(),
                Value<int?> reviewDurationMs = const Value.absent(),
                Value<double?> stabilityBefore = const Value.absent(),
                Value<double?> stabilityAfter = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReviewLogsCompanion(
                id: id,
                cardId: cardId,
                rating: rating,
                reviewDateTime: reviewDateTime,
                reviewDurationMs: reviewDurationMs,
                stabilityBefore: stabilityBefore,
                stabilityAfter: stabilityAfter,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String cardId,
                required String rating,
                required DateTime reviewDateTime,
                Value<int?> reviewDurationMs = const Value.absent(),
                Value<double?> stabilityBefore = const Value.absent(),
                Value<double?> stabilityAfter = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReviewLogsCompanion.insert(
                id: id,
                cardId: cardId,
                rating: rating,
                reviewDateTime: reviewDateTime,
                reviewDurationMs: reviewDurationMs,
                stabilityBefore: stabilityBefore,
                stabilityAfter: stabilityAfter,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ReviewLogsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({cardId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (cardId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.cardId,
                                referencedTable: $$ReviewLogsTableReferences
                                    ._cardIdTable(db),
                                referencedColumn: $$ReviewLogsTableReferences
                                    ._cardIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ReviewLogsTableProcessedTableManager =
    ProcessedTableManager<
      _$MiningDb,
      $ReviewLogsTable,
      ReviewLog,
      $$ReviewLogsTableFilterComposer,
      $$ReviewLogsTableOrderingComposer,
      $$ReviewLogsTableAnnotationComposer,
      $$ReviewLogsTableCreateCompanionBuilder,
      $$ReviewLogsTableUpdateCompanionBuilder,
      (ReviewLog, $$ReviewLogsTableReferences),
      ReviewLog,
      PrefetchHooks Function({bool cardId})
    >;
typedef $$MediaBlobsTableCreateCompanionBuilder =
    MediaBlobsCompanion Function({
      required String id,
      required String kind,
      required String path,
      required String contentHash,
      Value<int> rowid,
    });
typedef $$MediaBlobsTableUpdateCompanionBuilder =
    MediaBlobsCompanion Function({
      Value<String> id,
      Value<String> kind,
      Value<String> path,
      Value<String> contentHash,
      Value<int> rowid,
    });

class $$MediaBlobsTableFilterComposer
    extends Composer<_$MiningDb, $MediaBlobsTable> {
  $$MediaBlobsTableFilterComposer({
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

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contentHash => $composableBuilder(
    column: $table.contentHash,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MediaBlobsTableOrderingComposer
    extends Composer<_$MiningDb, $MediaBlobsTable> {
  $$MediaBlobsTableOrderingComposer({
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

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contentHash => $composableBuilder(
    column: $table.contentHash,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MediaBlobsTableAnnotationComposer
    extends Composer<_$MiningDb, $MediaBlobsTable> {
  $$MediaBlobsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get path =>
      $composableBuilder(column: $table.path, builder: (column) => column);

  GeneratedColumn<String> get contentHash => $composableBuilder(
    column: $table.contentHash,
    builder: (column) => column,
  );
}

class $$MediaBlobsTableTableManager
    extends
        RootTableManager<
          _$MiningDb,
          $MediaBlobsTable,
          MediaBlob,
          $$MediaBlobsTableFilterComposer,
          $$MediaBlobsTableOrderingComposer,
          $$MediaBlobsTableAnnotationComposer,
          $$MediaBlobsTableCreateCompanionBuilder,
          $$MediaBlobsTableUpdateCompanionBuilder,
          (MediaBlob, BaseReferences<_$MiningDb, $MediaBlobsTable, MediaBlob>),
          MediaBlob,
          PrefetchHooks Function()
        > {
  $$MediaBlobsTableTableManager(_$MiningDb db, $MediaBlobsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MediaBlobsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MediaBlobsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MediaBlobsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> path = const Value.absent(),
                Value<String> contentHash = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MediaBlobsCompanion(
                id: id,
                kind: kind,
                path: path,
                contentHash: contentHash,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String kind,
                required String path,
                required String contentHash,
                Value<int> rowid = const Value.absent(),
              }) => MediaBlobsCompanion.insert(
                id: id,
                kind: kind,
                path: path,
                contentHash: contentHash,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MediaBlobsTableProcessedTableManager =
    ProcessedTableManager<
      _$MiningDb,
      $MediaBlobsTable,
      MediaBlob,
      $$MediaBlobsTableFilterComposer,
      $$MediaBlobsTableOrderingComposer,
      $$MediaBlobsTableAnnotationComposer,
      $$MediaBlobsTableCreateCompanionBuilder,
      $$MediaBlobsTableUpdateCompanionBuilder,
      (MediaBlob, BaseReferences<_$MiningDb, $MediaBlobsTable, MediaBlob>),
      MediaBlob,
      PrefetchHooks Function()
    >;
typedef $$LanguagePacksTableCreateCompanionBuilder =
    LanguagePacksCompanion Function({
      required String code,
      required String name,
      Value<bool> hasReadings,
      Value<int> rowid,
    });
typedef $$LanguagePacksTableUpdateCompanionBuilder =
    LanguagePacksCompanion Function({
      Value<String> code,
      Value<String> name,
      Value<bool> hasReadings,
      Value<int> rowid,
    });

class $$LanguagePacksTableFilterComposer
    extends Composer<_$MiningDb, $LanguagePacksTable> {
  $$LanguagePacksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get hasReadings => $composableBuilder(
    column: $table.hasReadings,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LanguagePacksTableOrderingComposer
    extends Composer<_$MiningDb, $LanguagePacksTable> {
  $$LanguagePacksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get hasReadings => $composableBuilder(
    column: $table.hasReadings,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LanguagePacksTableAnnotationComposer
    extends Composer<_$MiningDb, $LanguagePacksTable> {
  $$LanguagePacksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get code =>
      $composableBuilder(column: $table.code, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<bool> get hasReadings => $composableBuilder(
    column: $table.hasReadings,
    builder: (column) => column,
  );
}

class $$LanguagePacksTableTableManager
    extends
        RootTableManager<
          _$MiningDb,
          $LanguagePacksTable,
          LanguagePackRow,
          $$LanguagePacksTableFilterComposer,
          $$LanguagePacksTableOrderingComposer,
          $$LanguagePacksTableAnnotationComposer,
          $$LanguagePacksTableCreateCompanionBuilder,
          $$LanguagePacksTableUpdateCompanionBuilder,
          (
            LanguagePackRow,
            BaseReferences<_$MiningDb, $LanguagePacksTable, LanguagePackRow>,
          ),
          LanguagePackRow,
          PrefetchHooks Function()
        > {
  $$LanguagePacksTableTableManager(_$MiningDb db, $LanguagePacksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LanguagePacksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LanguagePacksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LanguagePacksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> code = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<bool> hasReadings = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LanguagePacksCompanion(
                code: code,
                name: name,
                hasReadings: hasReadings,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String code,
                required String name,
                Value<bool> hasReadings = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LanguagePacksCompanion.insert(
                code: code,
                name: name,
                hasReadings: hasReadings,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LanguagePacksTableProcessedTableManager =
    ProcessedTableManager<
      _$MiningDb,
      $LanguagePacksTable,
      LanguagePackRow,
      $$LanguagePacksTableFilterComposer,
      $$LanguagePacksTableOrderingComposer,
      $$LanguagePacksTableAnnotationComposer,
      $$LanguagePacksTableCreateCompanionBuilder,
      $$LanguagePacksTableUpdateCompanionBuilder,
      (
        LanguagePackRow,
        BaseReferences<_$MiningDb, $LanguagePacksTable, LanguagePackRow>,
      ),
      LanguagePackRow,
      PrefetchHooks Function()
    >;
typedef $$ReadingSessionsTableCreateCompanionBuilder =
    ReadingSessionsCompanion Function({
      required String id,
      required String workId,
      required DateTime startedAt,
      Value<DateTime?> endedAt,
      Value<int?> spanStartOrdinal,
      Value<int?> spanEndOrdinal,
      Value<int> rowid,
    });
typedef $$ReadingSessionsTableUpdateCompanionBuilder =
    ReadingSessionsCompanion Function({
      Value<String> id,
      Value<String> workId,
      Value<DateTime> startedAt,
      Value<DateTime?> endedAt,
      Value<int?> spanStartOrdinal,
      Value<int?> spanEndOrdinal,
      Value<int> rowid,
    });

final class $$ReadingSessionsTableReferences
    extends BaseReferences<_$MiningDb, $ReadingSessionsTable, ReadingSession> {
  $$ReadingSessionsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $WorksTable _workIdTable(_$MiningDb db) => db.works.createAlias(
    $_aliasNameGenerator(db.readingSessions.workId, db.works.id),
  );

  $$WorksTableProcessedTableManager get workId {
    final $_column = $_itemColumn<String>('work_id')!;

    final manager = $$WorksTableTableManager(
      $_db,
      $_db.works,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_workIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ReadingSessionsTableFilterComposer
    extends Composer<_$MiningDb, $ReadingSessionsTable> {
  $$ReadingSessionsTableFilterComposer({
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

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get spanStartOrdinal => $composableBuilder(
    column: $table.spanStartOrdinal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get spanEndOrdinal => $composableBuilder(
    column: $table.spanEndOrdinal,
    builder: (column) => ColumnFilters(column),
  );

  $$WorksTableFilterComposer get workId {
    final $$WorksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workId,
      referencedTable: $db.works,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorksTableFilterComposer(
            $db: $db,
            $table: $db.works,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReadingSessionsTableOrderingComposer
    extends Composer<_$MiningDb, $ReadingSessionsTable> {
  $$ReadingSessionsTableOrderingComposer({
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

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get spanStartOrdinal => $composableBuilder(
    column: $table.spanStartOrdinal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get spanEndOrdinal => $composableBuilder(
    column: $table.spanEndOrdinal,
    builder: (column) => ColumnOrderings(column),
  );

  $$WorksTableOrderingComposer get workId {
    final $$WorksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workId,
      referencedTable: $db.works,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorksTableOrderingComposer(
            $db: $db,
            $table: $db.works,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReadingSessionsTableAnnotationComposer
    extends Composer<_$MiningDb, $ReadingSessionsTable> {
  $$ReadingSessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get endedAt =>
      $composableBuilder(column: $table.endedAt, builder: (column) => column);

  GeneratedColumn<int> get spanStartOrdinal => $composableBuilder(
    column: $table.spanStartOrdinal,
    builder: (column) => column,
  );

  GeneratedColumn<int> get spanEndOrdinal => $composableBuilder(
    column: $table.spanEndOrdinal,
    builder: (column) => column,
  );

  $$WorksTableAnnotationComposer get workId {
    final $$WorksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workId,
      referencedTable: $db.works,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorksTableAnnotationComposer(
            $db: $db,
            $table: $db.works,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReadingSessionsTableTableManager
    extends
        RootTableManager<
          _$MiningDb,
          $ReadingSessionsTable,
          ReadingSession,
          $$ReadingSessionsTableFilterComposer,
          $$ReadingSessionsTableOrderingComposer,
          $$ReadingSessionsTableAnnotationComposer,
          $$ReadingSessionsTableCreateCompanionBuilder,
          $$ReadingSessionsTableUpdateCompanionBuilder,
          (ReadingSession, $$ReadingSessionsTableReferences),
          ReadingSession,
          PrefetchHooks Function({bool workId})
        > {
  $$ReadingSessionsTableTableManager(_$MiningDb db, $ReadingSessionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReadingSessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReadingSessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReadingSessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> workId = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime?> endedAt = const Value.absent(),
                Value<int?> spanStartOrdinal = const Value.absent(),
                Value<int?> spanEndOrdinal = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReadingSessionsCompanion(
                id: id,
                workId: workId,
                startedAt: startedAt,
                endedAt: endedAt,
                spanStartOrdinal: spanStartOrdinal,
                spanEndOrdinal: spanEndOrdinal,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String workId,
                required DateTime startedAt,
                Value<DateTime?> endedAt = const Value.absent(),
                Value<int?> spanStartOrdinal = const Value.absent(),
                Value<int?> spanEndOrdinal = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReadingSessionsCompanion.insert(
                id: id,
                workId: workId,
                startedAt: startedAt,
                endedAt: endedAt,
                spanStartOrdinal: spanStartOrdinal,
                spanEndOrdinal: spanEndOrdinal,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ReadingSessionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({workId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (workId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.workId,
                                referencedTable:
                                    $$ReadingSessionsTableReferences
                                        ._workIdTable(db),
                                referencedColumn:
                                    $$ReadingSessionsTableReferences
                                        ._workIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ReadingSessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$MiningDb,
      $ReadingSessionsTable,
      ReadingSession,
      $$ReadingSessionsTableFilterComposer,
      $$ReadingSessionsTableOrderingComposer,
      $$ReadingSessionsTableAnnotationComposer,
      $$ReadingSessionsTableCreateCompanionBuilder,
      $$ReadingSessionsTableUpdateCompanionBuilder,
      (ReadingSession, $$ReadingSessionsTableReferences),
      ReadingSession,
      PrefetchHooks Function({bool workId})
    >;
typedef $$PassageSnapshotsTableCreateCompanionBuilder =
    PassageSnapshotsCompanion Function({
      required String id,
      required String workId,
      required String passageRef,
      required DateTime ts,
      required double unknownRatio,
      Value<int?> dwellMs,
      Value<int> lookupCount,
      Value<int> miningEventsCount,
      Value<int> rowid,
    });
typedef $$PassageSnapshotsTableUpdateCompanionBuilder =
    PassageSnapshotsCompanion Function({
      Value<String> id,
      Value<String> workId,
      Value<String> passageRef,
      Value<DateTime> ts,
      Value<double> unknownRatio,
      Value<int?> dwellMs,
      Value<int> lookupCount,
      Value<int> miningEventsCount,
      Value<int> rowid,
    });

final class $$PassageSnapshotsTableReferences
    extends
        BaseReferences<_$MiningDb, $PassageSnapshotsTable, PassageSnapshot> {
  $$PassageSnapshotsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $WorksTable _workIdTable(_$MiningDb db) => db.works.createAlias(
    $_aliasNameGenerator(db.passageSnapshots.workId, db.works.id),
  );

  $$WorksTableProcessedTableManager get workId {
    final $_column = $_itemColumn<String>('work_id')!;

    final manager = $$WorksTableTableManager(
      $_db,
      $_db.works,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_workIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PassageSnapshotsTableFilterComposer
    extends Composer<_$MiningDb, $PassageSnapshotsTable> {
  $$PassageSnapshotsTableFilterComposer({
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

  ColumnFilters<String> get passageRef => $composableBuilder(
    column: $table.passageRef,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get ts => $composableBuilder(
    column: $table.ts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get unknownRatio => $composableBuilder(
    column: $table.unknownRatio,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dwellMs => $composableBuilder(
    column: $table.dwellMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lookupCount => $composableBuilder(
    column: $table.lookupCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get miningEventsCount => $composableBuilder(
    column: $table.miningEventsCount,
    builder: (column) => ColumnFilters(column),
  );

  $$WorksTableFilterComposer get workId {
    final $$WorksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workId,
      referencedTable: $db.works,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorksTableFilterComposer(
            $db: $db,
            $table: $db.works,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PassageSnapshotsTableOrderingComposer
    extends Composer<_$MiningDb, $PassageSnapshotsTable> {
  $$PassageSnapshotsTableOrderingComposer({
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

  ColumnOrderings<String> get passageRef => $composableBuilder(
    column: $table.passageRef,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get ts => $composableBuilder(
    column: $table.ts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get unknownRatio => $composableBuilder(
    column: $table.unknownRatio,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dwellMs => $composableBuilder(
    column: $table.dwellMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lookupCount => $composableBuilder(
    column: $table.lookupCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get miningEventsCount => $composableBuilder(
    column: $table.miningEventsCount,
    builder: (column) => ColumnOrderings(column),
  );

  $$WorksTableOrderingComposer get workId {
    final $$WorksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workId,
      referencedTable: $db.works,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorksTableOrderingComposer(
            $db: $db,
            $table: $db.works,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PassageSnapshotsTableAnnotationComposer
    extends Composer<_$MiningDb, $PassageSnapshotsTable> {
  $$PassageSnapshotsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get passageRef => $composableBuilder(
    column: $table.passageRef,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get ts =>
      $composableBuilder(column: $table.ts, builder: (column) => column);

  GeneratedColumn<double> get unknownRatio => $composableBuilder(
    column: $table.unknownRatio,
    builder: (column) => column,
  );

  GeneratedColumn<int> get dwellMs =>
      $composableBuilder(column: $table.dwellMs, builder: (column) => column);

  GeneratedColumn<int> get lookupCount => $composableBuilder(
    column: $table.lookupCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get miningEventsCount => $composableBuilder(
    column: $table.miningEventsCount,
    builder: (column) => column,
  );

  $$WorksTableAnnotationComposer get workId {
    final $$WorksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workId,
      referencedTable: $db.works,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorksTableAnnotationComposer(
            $db: $db,
            $table: $db.works,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PassageSnapshotsTableTableManager
    extends
        RootTableManager<
          _$MiningDb,
          $PassageSnapshotsTable,
          PassageSnapshot,
          $$PassageSnapshotsTableFilterComposer,
          $$PassageSnapshotsTableOrderingComposer,
          $$PassageSnapshotsTableAnnotationComposer,
          $$PassageSnapshotsTableCreateCompanionBuilder,
          $$PassageSnapshotsTableUpdateCompanionBuilder,
          (PassageSnapshot, $$PassageSnapshotsTableReferences),
          PassageSnapshot,
          PrefetchHooks Function({bool workId})
        > {
  $$PassageSnapshotsTableTableManager(
    _$MiningDb db,
    $PassageSnapshotsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PassageSnapshotsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PassageSnapshotsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PassageSnapshotsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> workId = const Value.absent(),
                Value<String> passageRef = const Value.absent(),
                Value<DateTime> ts = const Value.absent(),
                Value<double> unknownRatio = const Value.absent(),
                Value<int?> dwellMs = const Value.absent(),
                Value<int> lookupCount = const Value.absent(),
                Value<int> miningEventsCount = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PassageSnapshotsCompanion(
                id: id,
                workId: workId,
                passageRef: passageRef,
                ts: ts,
                unknownRatio: unknownRatio,
                dwellMs: dwellMs,
                lookupCount: lookupCount,
                miningEventsCount: miningEventsCount,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String workId,
                required String passageRef,
                required DateTime ts,
                required double unknownRatio,
                Value<int?> dwellMs = const Value.absent(),
                Value<int> lookupCount = const Value.absent(),
                Value<int> miningEventsCount = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PassageSnapshotsCompanion.insert(
                id: id,
                workId: workId,
                passageRef: passageRef,
                ts: ts,
                unknownRatio: unknownRatio,
                dwellMs: dwellMs,
                lookupCount: lookupCount,
                miningEventsCount: miningEventsCount,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PassageSnapshotsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({workId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (workId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.workId,
                                referencedTable:
                                    $$PassageSnapshotsTableReferences
                                        ._workIdTable(db),
                                referencedColumn:
                                    $$PassageSnapshotsTableReferences
                                        ._workIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$PassageSnapshotsTableProcessedTableManager =
    ProcessedTableManager<
      _$MiningDb,
      $PassageSnapshotsTable,
      PassageSnapshot,
      $$PassageSnapshotsTableFilterComposer,
      $$PassageSnapshotsTableOrderingComposer,
      $$PassageSnapshotsTableAnnotationComposer,
      $$PassageSnapshotsTableCreateCompanionBuilder,
      $$PassageSnapshotsTableUpdateCompanionBuilder,
      (PassageSnapshot, $$PassageSnapshotsTableReferences),
      PassageSnapshot,
      PrefetchHooks Function({bool workId})
    >;
typedef $$ObservationsTableCreateCompanionBuilder =
    ObservationsCompanion Function({
      required String id,
      required String kind,
      required String factsJson,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$ObservationsTableUpdateCompanionBuilder =
    ObservationsCompanion Function({
      Value<String> id,
      Value<String> kind,
      Value<String> factsJson,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$ObservationsTableFilterComposer
    extends Composer<_$MiningDb, $ObservationsTable> {
  $$ObservationsTableFilterComposer({
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

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get factsJson => $composableBuilder(
    column: $table.factsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ObservationsTableOrderingComposer
    extends Composer<_$MiningDb, $ObservationsTable> {
  $$ObservationsTableOrderingComposer({
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

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get factsJson => $composableBuilder(
    column: $table.factsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ObservationsTableAnnotationComposer
    extends Composer<_$MiningDb, $ObservationsTable> {
  $$ObservationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get factsJson =>
      $composableBuilder(column: $table.factsJson, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$ObservationsTableTableManager
    extends
        RootTableManager<
          _$MiningDb,
          $ObservationsTable,
          Observation,
          $$ObservationsTableFilterComposer,
          $$ObservationsTableOrderingComposer,
          $$ObservationsTableAnnotationComposer,
          $$ObservationsTableCreateCompanionBuilder,
          $$ObservationsTableUpdateCompanionBuilder,
          (
            Observation,
            BaseReferences<_$MiningDb, $ObservationsTable, Observation>,
          ),
          Observation,
          PrefetchHooks Function()
        > {
  $$ObservationsTableTableManager(_$MiningDb db, $ObservationsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ObservationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ObservationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ObservationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> factsJson = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ObservationsCompanion(
                id: id,
                kind: kind,
                factsJson: factsJson,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String kind,
                required String factsJson,
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => ObservationsCompanion.insert(
                id: id,
                kind: kind,
                factsJson: factsJson,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ObservationsTableProcessedTableManager =
    ProcessedTableManager<
      _$MiningDb,
      $ObservationsTable,
      Observation,
      $$ObservationsTableFilterComposer,
      $$ObservationsTableOrderingComposer,
      $$ObservationsTableAnnotationComposer,
      $$ObservationsTableCreateCompanionBuilder,
      $$ObservationsTableUpdateCompanionBuilder,
      (
        Observation,
        BaseReferences<_$MiningDb, $ObservationsTable, Observation>,
      ),
      Observation,
      PrefetchHooks Function()
    >;

class $MiningDbManager {
  final _$MiningDb _db;
  $MiningDbManager(this._db);
  $$WorksTableTableManager get works =>
      $$WorksTableTableManager(_db, _db.works);
  $$SourcesTableTableManager get sources =>
      $$SourcesTableTableManager(_db, _db.sources);
  $$TextSpansTableTableManager get textSpans =>
      $$TextSpansTableTableManager(_db, _db.textSpans);
  $$TokenOccurrencesTableTableManager get tokenOccurrences =>
      $$TokenOccurrencesTableTableManager(_db, _db.tokenOccurrences);
  $$VocabItemsTableTableManager get vocabItems =>
      $$VocabItemsTableTableManager(_db, _db.vocabItems);
  $$CardsTableTableManager get cards =>
      $$CardsTableTableManager(_db, _db.cards);
  $$ReviewLogsTableTableManager get reviewLogs =>
      $$ReviewLogsTableTableManager(_db, _db.reviewLogs);
  $$MediaBlobsTableTableManager get mediaBlobs =>
      $$MediaBlobsTableTableManager(_db, _db.mediaBlobs);
  $$LanguagePacksTableTableManager get languagePacks =>
      $$LanguagePacksTableTableManager(_db, _db.languagePacks);
  $$ReadingSessionsTableTableManager get readingSessions =>
      $$ReadingSessionsTableTableManager(_db, _db.readingSessions);
  $$PassageSnapshotsTableTableManager get passageSnapshots =>
      $$PassageSnapshotsTableTableManager(_db, _db.passageSnapshots);
  $$ObservationsTableTableManager get observations =>
      $$ObservationsTableTableManager(_db, _db.observations);
}
