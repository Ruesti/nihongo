// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'learning_db.dart';

// ignore_for_file: type=lint
class $ConceptsTable extends Concepts with TableInfo<$ConceptsTable, Concept> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ConceptsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _glossKeyMeta = const VerificationMeta(
    'glossKey',
  );
  @override
  late final GeneratedColumn<String> glossKey = GeneratedColumn<String>(
    'gloss_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _partOfSpeechMeta = const VerificationMeta(
    'partOfSpeech',
  );
  @override
  late final GeneratedColumn<String> partOfSpeech = GeneratedColumn<String>(
    'part_of_speech',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _defaultAssetTypeMeta = const VerificationMeta(
    'defaultAssetType',
  );
  @override
  late final GeneratedColumn<String> defaultAssetType = GeneratedColumn<String>(
    'default_asset_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('none'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    glossKey,
    partOfSpeech,
    defaultAssetType,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'concepts';
  @override
  VerificationContext validateIntegrity(
    Insertable<Concept> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('gloss_key')) {
      context.handle(
        _glossKeyMeta,
        glossKey.isAcceptableOrUnknown(data['gloss_key']!, _glossKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_glossKeyMeta);
    }
    if (data.containsKey('part_of_speech')) {
      context.handle(
        _partOfSpeechMeta,
        partOfSpeech.isAcceptableOrUnknown(
          data['part_of_speech']!,
          _partOfSpeechMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_partOfSpeechMeta);
    }
    if (data.containsKey('default_asset_type')) {
      context.handle(
        _defaultAssetTypeMeta,
        defaultAssetType.isAcceptableOrUnknown(
          data['default_asset_type']!,
          _defaultAssetTypeMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Concept map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Concept(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      glossKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}gloss_key'],
      )!,
      partOfSpeech: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}part_of_speech'],
      )!,
      defaultAssetType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}default_asset_type'],
      )!,
    );
  }

  @override
  $ConceptsTable createAlias(String alias) {
    return $ConceptsTable(attachedDatabase, alias);
  }
}

class Concept extends DataClass implements Insertable<Concept> {
  final String id;
  final String glossKey;
  final String partOfSpeech;
  final String defaultAssetType;
  const Concept({
    required this.id,
    required this.glossKey,
    required this.partOfSpeech,
    required this.defaultAssetType,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['gloss_key'] = Variable<String>(glossKey);
    map['part_of_speech'] = Variable<String>(partOfSpeech);
    map['default_asset_type'] = Variable<String>(defaultAssetType);
    return map;
  }

  ConceptsCompanion toCompanion(bool nullToAbsent) {
    return ConceptsCompanion(
      id: Value(id),
      glossKey: Value(glossKey),
      partOfSpeech: Value(partOfSpeech),
      defaultAssetType: Value(defaultAssetType),
    );
  }

  factory Concept.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Concept(
      id: serializer.fromJson<String>(json['id']),
      glossKey: serializer.fromJson<String>(json['glossKey']),
      partOfSpeech: serializer.fromJson<String>(json['partOfSpeech']),
      defaultAssetType: serializer.fromJson<String>(json['defaultAssetType']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'glossKey': serializer.toJson<String>(glossKey),
      'partOfSpeech': serializer.toJson<String>(partOfSpeech),
      'defaultAssetType': serializer.toJson<String>(defaultAssetType),
    };
  }

  Concept copyWith({
    String? id,
    String? glossKey,
    String? partOfSpeech,
    String? defaultAssetType,
  }) => Concept(
    id: id ?? this.id,
    glossKey: glossKey ?? this.glossKey,
    partOfSpeech: partOfSpeech ?? this.partOfSpeech,
    defaultAssetType: defaultAssetType ?? this.defaultAssetType,
  );
  Concept copyWithCompanion(ConceptsCompanion data) {
    return Concept(
      id: data.id.present ? data.id.value : this.id,
      glossKey: data.glossKey.present ? data.glossKey.value : this.glossKey,
      partOfSpeech: data.partOfSpeech.present
          ? data.partOfSpeech.value
          : this.partOfSpeech,
      defaultAssetType: data.defaultAssetType.present
          ? data.defaultAssetType.value
          : this.defaultAssetType,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Concept(')
          ..write('id: $id, ')
          ..write('glossKey: $glossKey, ')
          ..write('partOfSpeech: $partOfSpeech, ')
          ..write('defaultAssetType: $defaultAssetType')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, glossKey, partOfSpeech, defaultAssetType);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Concept &&
          other.id == this.id &&
          other.glossKey == this.glossKey &&
          other.partOfSpeech == this.partOfSpeech &&
          other.defaultAssetType == this.defaultAssetType);
}

class ConceptsCompanion extends UpdateCompanion<Concept> {
  final Value<String> id;
  final Value<String> glossKey;
  final Value<String> partOfSpeech;
  final Value<String> defaultAssetType;
  final Value<int> rowid;
  const ConceptsCompanion({
    this.id = const Value.absent(),
    this.glossKey = const Value.absent(),
    this.partOfSpeech = const Value.absent(),
    this.defaultAssetType = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ConceptsCompanion.insert({
    required String id,
    required String glossKey,
    required String partOfSpeech,
    this.defaultAssetType = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       glossKey = Value(glossKey),
       partOfSpeech = Value(partOfSpeech);
  static Insertable<Concept> custom({
    Expression<String>? id,
    Expression<String>? glossKey,
    Expression<String>? partOfSpeech,
    Expression<String>? defaultAssetType,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (glossKey != null) 'gloss_key': glossKey,
      if (partOfSpeech != null) 'part_of_speech': partOfSpeech,
      if (defaultAssetType != null) 'default_asset_type': defaultAssetType,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ConceptsCompanion copyWith({
    Value<String>? id,
    Value<String>? glossKey,
    Value<String>? partOfSpeech,
    Value<String>? defaultAssetType,
    Value<int>? rowid,
  }) {
    return ConceptsCompanion(
      id: id ?? this.id,
      glossKey: glossKey ?? this.glossKey,
      partOfSpeech: partOfSpeech ?? this.partOfSpeech,
      defaultAssetType: defaultAssetType ?? this.defaultAssetType,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (glossKey.present) {
      map['gloss_key'] = Variable<String>(glossKey.value);
    }
    if (partOfSpeech.present) {
      map['part_of_speech'] = Variable<String>(partOfSpeech.value);
    }
    if (defaultAssetType.present) {
      map['default_asset_type'] = Variable<String>(defaultAssetType.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ConceptsCompanion(')
          ..write('id: $id, ')
          ..write('glossKey: $glossKey, ')
          ..write('partOfSpeech: $partOfSpeech, ')
          ..write('defaultAssetType: $defaultAssetType, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AssetsTable extends Assets with TableInfo<$AssetsTable, Asset> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AssetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _conceptIdMeta = const VerificationMeta(
    'conceptId',
  );
  @override
  late final GeneratedColumn<String> conceptId = GeneratedColumn<String>(
    'concept_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES concepts (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
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
  @override
  List<GeneratedColumn> get $columns => [id, conceptId, type, path];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'assets';
  @override
  VerificationContext validateIntegrity(
    Insertable<Asset> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('concept_id')) {
      context.handle(
        _conceptIdMeta,
        conceptId.isAcceptableOrUnknown(data['concept_id']!, _conceptIdMeta),
      );
    } else if (isInserting) {
      context.missing(_conceptIdMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('path')) {
      context.handle(
        _pathMeta,
        path.isAcceptableOrUnknown(data['path']!, _pathMeta),
      );
    } else if (isInserting) {
      context.missing(_pathMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Asset map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Asset(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      conceptId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}concept_id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      path: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}path'],
      )!,
    );
  }

  @override
  $AssetsTable createAlias(String alias) {
    return $AssetsTable(attachedDatabase, alias);
  }
}

class Asset extends DataClass implements Insertable<Asset> {
  final String id;
  final String conceptId;
  final String type;
  final String path;
  const Asset({
    required this.id,
    required this.conceptId,
    required this.type,
    required this.path,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['concept_id'] = Variable<String>(conceptId);
    map['type'] = Variable<String>(type);
    map['path'] = Variable<String>(path);
    return map;
  }

  AssetsCompanion toCompanion(bool nullToAbsent) {
    return AssetsCompanion(
      id: Value(id),
      conceptId: Value(conceptId),
      type: Value(type),
      path: Value(path),
    );
  }

  factory Asset.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Asset(
      id: serializer.fromJson<String>(json['id']),
      conceptId: serializer.fromJson<String>(json['conceptId']),
      type: serializer.fromJson<String>(json['type']),
      path: serializer.fromJson<String>(json['path']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'conceptId': serializer.toJson<String>(conceptId),
      'type': serializer.toJson<String>(type),
      'path': serializer.toJson<String>(path),
    };
  }

  Asset copyWith({String? id, String? conceptId, String? type, String? path}) =>
      Asset(
        id: id ?? this.id,
        conceptId: conceptId ?? this.conceptId,
        type: type ?? this.type,
        path: path ?? this.path,
      );
  Asset copyWithCompanion(AssetsCompanion data) {
    return Asset(
      id: data.id.present ? data.id.value : this.id,
      conceptId: data.conceptId.present ? data.conceptId.value : this.conceptId,
      type: data.type.present ? data.type.value : this.type,
      path: data.path.present ? data.path.value : this.path,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Asset(')
          ..write('id: $id, ')
          ..write('conceptId: $conceptId, ')
          ..write('type: $type, ')
          ..write('path: $path')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, conceptId, type, path);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Asset &&
          other.id == this.id &&
          other.conceptId == this.conceptId &&
          other.type == this.type &&
          other.path == this.path);
}

class AssetsCompanion extends UpdateCompanion<Asset> {
  final Value<String> id;
  final Value<String> conceptId;
  final Value<String> type;
  final Value<String> path;
  final Value<int> rowid;
  const AssetsCompanion({
    this.id = const Value.absent(),
    this.conceptId = const Value.absent(),
    this.type = const Value.absent(),
    this.path = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AssetsCompanion.insert({
    required String id,
    required String conceptId,
    required String type,
    required String path,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       conceptId = Value(conceptId),
       type = Value(type),
       path = Value(path);
  static Insertable<Asset> custom({
    Expression<String>? id,
    Expression<String>? conceptId,
    Expression<String>? type,
    Expression<String>? path,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (conceptId != null) 'concept_id': conceptId,
      if (type != null) 'type': type,
      if (path != null) 'path': path,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AssetsCompanion copyWith({
    Value<String>? id,
    Value<String>? conceptId,
    Value<String>? type,
    Value<String>? path,
    Value<int>? rowid,
  }) {
    return AssetsCompanion(
      id: id ?? this.id,
      conceptId: conceptId ?? this.conceptId,
      type: type ?? this.type,
      path: path ?? this.path,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (conceptId.present) {
      map['concept_id'] = Variable<String>(conceptId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (path.present) {
      map['path'] = Variable<String>(path.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AssetsCompanion(')
          ..write('id: $id, ')
          ..write('conceptId: $conceptId, ')
          ..write('type: $type, ')
          ..write('path: $path, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ScriptProfilesTable extends ScriptProfiles
    with TableInfo<$ScriptProfilesTable, ScriptProfileRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ScriptProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scriptTypeMeta = const VerificationMeta(
    'scriptType',
  );
  @override
  late final GeneratedColumn<String> scriptType = GeneratedColumn<String>(
    'script_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _directionMeta = const VerificationMeta(
    'direction',
  );
  @override
  late final GeneratedColumn<String> direction = GeneratedColumn<String>(
    'direction',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('ltr'),
  );
  static const VerificationMeta _decomposabilityMeta = const VerificationMeta(
    'decomposability',
  );
  @override
  late final GeneratedColumn<String> decomposability = GeneratedColumn<String>(
    'decomposability',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _positionalFormsMeta = const VerificationMeta(
    'positionalForms',
  );
  @override
  late final GeneratedColumn<bool> positionalForms = GeneratedColumn<bool>(
    'positional_forms',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("positional_forms" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _toneSystemMeta = const VerificationMeta(
    'toneSystem',
  );
  @override
  late final GeneratedColumn<String> toneSystem = GeneratedColumn<String>(
    'tone_system',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('none'),
  );
  static const VerificationMeta _needsScriptTrackMeta = const VerificationMeta(
    'needsScriptTrack',
  );
  @override
  late final GeneratedColumn<bool> needsScriptTrack = GeneratedColumn<bool>(
    'needs_script_track',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("needs_script_track" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _transliterationMeta = const VerificationMeta(
    'transliteration',
  );
  @override
  late final GeneratedColumn<String> transliteration = GeneratedColumn<String>(
    'transliteration',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('none'),
  );
  static const VerificationMeta _inputMethodsJsonMeta = const VerificationMeta(
    'inputMethodsJson',
  );
  @override
  late final GeneratedColumn<String> inputMethodsJson = GeneratedColumn<String>(
    'input_methods_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('["keyboard"]'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    scriptType,
    direction,
    decomposability,
    positionalForms,
    toneSystem,
    needsScriptTrack,
    transliteration,
    inputMethodsJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'script_profiles';
  @override
  VerificationContext validateIntegrity(
    Insertable<ScriptProfileRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('script_type')) {
      context.handle(
        _scriptTypeMeta,
        scriptType.isAcceptableOrUnknown(data['script_type']!, _scriptTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_scriptTypeMeta);
    }
    if (data.containsKey('direction')) {
      context.handle(
        _directionMeta,
        direction.isAcceptableOrUnknown(data['direction']!, _directionMeta),
      );
    }
    if (data.containsKey('decomposability')) {
      context.handle(
        _decomposabilityMeta,
        decomposability.isAcceptableOrUnknown(
          data['decomposability']!,
          _decomposabilityMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_decomposabilityMeta);
    }
    if (data.containsKey('positional_forms')) {
      context.handle(
        _positionalFormsMeta,
        positionalForms.isAcceptableOrUnknown(
          data['positional_forms']!,
          _positionalFormsMeta,
        ),
      );
    }
    if (data.containsKey('tone_system')) {
      context.handle(
        _toneSystemMeta,
        toneSystem.isAcceptableOrUnknown(data['tone_system']!, _toneSystemMeta),
      );
    }
    if (data.containsKey('needs_script_track')) {
      context.handle(
        _needsScriptTrackMeta,
        needsScriptTrack.isAcceptableOrUnknown(
          data['needs_script_track']!,
          _needsScriptTrackMeta,
        ),
      );
    }
    if (data.containsKey('transliteration')) {
      context.handle(
        _transliterationMeta,
        transliteration.isAcceptableOrUnknown(
          data['transliteration']!,
          _transliterationMeta,
        ),
      );
    }
    if (data.containsKey('input_methods_json')) {
      context.handle(
        _inputMethodsJsonMeta,
        inputMethodsJson.isAcceptableOrUnknown(
          data['input_methods_json']!,
          _inputMethodsJsonMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ScriptProfileRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ScriptProfileRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      scriptType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}script_type'],
      )!,
      direction: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}direction'],
      )!,
      decomposability: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}decomposability'],
      )!,
      positionalForms: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}positional_forms'],
      )!,
      toneSystem: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tone_system'],
      )!,
      needsScriptTrack: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}needs_script_track'],
      )!,
      transliteration: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}transliteration'],
      )!,
      inputMethodsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}input_methods_json'],
      )!,
    );
  }

  @override
  $ScriptProfilesTable createAlias(String alias) {
    return $ScriptProfilesTable(attachedDatabase, alias);
  }
}

class ScriptProfileRow extends DataClass
    implements Insertable<ScriptProfileRow> {
  final String id;
  final String scriptType;
  final String direction;
  final String decomposability;
  final bool positionalForms;
  final String toneSystem;
  final bool needsScriptTrack;
  final String transliteration;
  final String inputMethodsJson;
  const ScriptProfileRow({
    required this.id,
    required this.scriptType,
    required this.direction,
    required this.decomposability,
    required this.positionalForms,
    required this.toneSystem,
    required this.needsScriptTrack,
    required this.transliteration,
    required this.inputMethodsJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['script_type'] = Variable<String>(scriptType);
    map['direction'] = Variable<String>(direction);
    map['decomposability'] = Variable<String>(decomposability);
    map['positional_forms'] = Variable<bool>(positionalForms);
    map['tone_system'] = Variable<String>(toneSystem);
    map['needs_script_track'] = Variable<bool>(needsScriptTrack);
    map['transliteration'] = Variable<String>(transliteration);
    map['input_methods_json'] = Variable<String>(inputMethodsJson);
    return map;
  }

  ScriptProfilesCompanion toCompanion(bool nullToAbsent) {
    return ScriptProfilesCompanion(
      id: Value(id),
      scriptType: Value(scriptType),
      direction: Value(direction),
      decomposability: Value(decomposability),
      positionalForms: Value(positionalForms),
      toneSystem: Value(toneSystem),
      needsScriptTrack: Value(needsScriptTrack),
      transliteration: Value(transliteration),
      inputMethodsJson: Value(inputMethodsJson),
    );
  }

  factory ScriptProfileRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ScriptProfileRow(
      id: serializer.fromJson<String>(json['id']),
      scriptType: serializer.fromJson<String>(json['scriptType']),
      direction: serializer.fromJson<String>(json['direction']),
      decomposability: serializer.fromJson<String>(json['decomposability']),
      positionalForms: serializer.fromJson<bool>(json['positionalForms']),
      toneSystem: serializer.fromJson<String>(json['toneSystem']),
      needsScriptTrack: serializer.fromJson<bool>(json['needsScriptTrack']),
      transliteration: serializer.fromJson<String>(json['transliteration']),
      inputMethodsJson: serializer.fromJson<String>(json['inputMethodsJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'scriptType': serializer.toJson<String>(scriptType),
      'direction': serializer.toJson<String>(direction),
      'decomposability': serializer.toJson<String>(decomposability),
      'positionalForms': serializer.toJson<bool>(positionalForms),
      'toneSystem': serializer.toJson<String>(toneSystem),
      'needsScriptTrack': serializer.toJson<bool>(needsScriptTrack),
      'transliteration': serializer.toJson<String>(transliteration),
      'inputMethodsJson': serializer.toJson<String>(inputMethodsJson),
    };
  }

  ScriptProfileRow copyWith({
    String? id,
    String? scriptType,
    String? direction,
    String? decomposability,
    bool? positionalForms,
    String? toneSystem,
    bool? needsScriptTrack,
    String? transliteration,
    String? inputMethodsJson,
  }) => ScriptProfileRow(
    id: id ?? this.id,
    scriptType: scriptType ?? this.scriptType,
    direction: direction ?? this.direction,
    decomposability: decomposability ?? this.decomposability,
    positionalForms: positionalForms ?? this.positionalForms,
    toneSystem: toneSystem ?? this.toneSystem,
    needsScriptTrack: needsScriptTrack ?? this.needsScriptTrack,
    transliteration: transliteration ?? this.transliteration,
    inputMethodsJson: inputMethodsJson ?? this.inputMethodsJson,
  );
  ScriptProfileRow copyWithCompanion(ScriptProfilesCompanion data) {
    return ScriptProfileRow(
      id: data.id.present ? data.id.value : this.id,
      scriptType: data.scriptType.present
          ? data.scriptType.value
          : this.scriptType,
      direction: data.direction.present ? data.direction.value : this.direction,
      decomposability: data.decomposability.present
          ? data.decomposability.value
          : this.decomposability,
      positionalForms: data.positionalForms.present
          ? data.positionalForms.value
          : this.positionalForms,
      toneSystem: data.toneSystem.present
          ? data.toneSystem.value
          : this.toneSystem,
      needsScriptTrack: data.needsScriptTrack.present
          ? data.needsScriptTrack.value
          : this.needsScriptTrack,
      transliteration: data.transliteration.present
          ? data.transliteration.value
          : this.transliteration,
      inputMethodsJson: data.inputMethodsJson.present
          ? data.inputMethodsJson.value
          : this.inputMethodsJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ScriptProfileRow(')
          ..write('id: $id, ')
          ..write('scriptType: $scriptType, ')
          ..write('direction: $direction, ')
          ..write('decomposability: $decomposability, ')
          ..write('positionalForms: $positionalForms, ')
          ..write('toneSystem: $toneSystem, ')
          ..write('needsScriptTrack: $needsScriptTrack, ')
          ..write('transliteration: $transliteration, ')
          ..write('inputMethodsJson: $inputMethodsJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    scriptType,
    direction,
    decomposability,
    positionalForms,
    toneSystem,
    needsScriptTrack,
    transliteration,
    inputMethodsJson,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ScriptProfileRow &&
          other.id == this.id &&
          other.scriptType == this.scriptType &&
          other.direction == this.direction &&
          other.decomposability == this.decomposability &&
          other.positionalForms == this.positionalForms &&
          other.toneSystem == this.toneSystem &&
          other.needsScriptTrack == this.needsScriptTrack &&
          other.transliteration == this.transliteration &&
          other.inputMethodsJson == this.inputMethodsJson);
}

class ScriptProfilesCompanion extends UpdateCompanion<ScriptProfileRow> {
  final Value<String> id;
  final Value<String> scriptType;
  final Value<String> direction;
  final Value<String> decomposability;
  final Value<bool> positionalForms;
  final Value<String> toneSystem;
  final Value<bool> needsScriptTrack;
  final Value<String> transliteration;
  final Value<String> inputMethodsJson;
  final Value<int> rowid;
  const ScriptProfilesCompanion({
    this.id = const Value.absent(),
    this.scriptType = const Value.absent(),
    this.direction = const Value.absent(),
    this.decomposability = const Value.absent(),
    this.positionalForms = const Value.absent(),
    this.toneSystem = const Value.absent(),
    this.needsScriptTrack = const Value.absent(),
    this.transliteration = const Value.absent(),
    this.inputMethodsJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ScriptProfilesCompanion.insert({
    required String id,
    required String scriptType,
    this.direction = const Value.absent(),
    required String decomposability,
    this.positionalForms = const Value.absent(),
    this.toneSystem = const Value.absent(),
    this.needsScriptTrack = const Value.absent(),
    this.transliteration = const Value.absent(),
    this.inputMethodsJson = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       scriptType = Value(scriptType),
       decomposability = Value(decomposability);
  static Insertable<ScriptProfileRow> custom({
    Expression<String>? id,
    Expression<String>? scriptType,
    Expression<String>? direction,
    Expression<String>? decomposability,
    Expression<bool>? positionalForms,
    Expression<String>? toneSystem,
    Expression<bool>? needsScriptTrack,
    Expression<String>? transliteration,
    Expression<String>? inputMethodsJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (scriptType != null) 'script_type': scriptType,
      if (direction != null) 'direction': direction,
      if (decomposability != null) 'decomposability': decomposability,
      if (positionalForms != null) 'positional_forms': positionalForms,
      if (toneSystem != null) 'tone_system': toneSystem,
      if (needsScriptTrack != null) 'needs_script_track': needsScriptTrack,
      if (transliteration != null) 'transliteration': transliteration,
      if (inputMethodsJson != null) 'input_methods_json': inputMethodsJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ScriptProfilesCompanion copyWith({
    Value<String>? id,
    Value<String>? scriptType,
    Value<String>? direction,
    Value<String>? decomposability,
    Value<bool>? positionalForms,
    Value<String>? toneSystem,
    Value<bool>? needsScriptTrack,
    Value<String>? transliteration,
    Value<String>? inputMethodsJson,
    Value<int>? rowid,
  }) {
    return ScriptProfilesCompanion(
      id: id ?? this.id,
      scriptType: scriptType ?? this.scriptType,
      direction: direction ?? this.direction,
      decomposability: decomposability ?? this.decomposability,
      positionalForms: positionalForms ?? this.positionalForms,
      toneSystem: toneSystem ?? this.toneSystem,
      needsScriptTrack: needsScriptTrack ?? this.needsScriptTrack,
      transliteration: transliteration ?? this.transliteration,
      inputMethodsJson: inputMethodsJson ?? this.inputMethodsJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (scriptType.present) {
      map['script_type'] = Variable<String>(scriptType.value);
    }
    if (direction.present) {
      map['direction'] = Variable<String>(direction.value);
    }
    if (decomposability.present) {
      map['decomposability'] = Variable<String>(decomposability.value);
    }
    if (positionalForms.present) {
      map['positional_forms'] = Variable<bool>(positionalForms.value);
    }
    if (toneSystem.present) {
      map['tone_system'] = Variable<String>(toneSystem.value);
    }
    if (needsScriptTrack.present) {
      map['needs_script_track'] = Variable<bool>(needsScriptTrack.value);
    }
    if (transliteration.present) {
      map['transliteration'] = Variable<String>(transliteration.value);
    }
    if (inputMethodsJson.present) {
      map['input_methods_json'] = Variable<String>(inputMethodsJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ScriptProfilesCompanion(')
          ..write('id: $id, ')
          ..write('scriptType: $scriptType, ')
          ..write('direction: $direction, ')
          ..write('decomposability: $decomposability, ')
          ..write('positionalForms: $positionalForms, ')
          ..write('toneSystem: $toneSystem, ')
          ..write('needsScriptTrack: $needsScriptTrack, ')
          ..write('transliteration: $transliteration, ')
          ..write('inputMethodsJson: $inputMethodsJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LanguagesTable extends Languages
    with TableInfo<$LanguagesTable, Language> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LanguagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
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
  static const VerificationMeta _scriptProfileIdMeta = const VerificationMeta(
    'scriptProfileId',
  );
  @override
  late final GeneratedColumn<String> scriptProfileId = GeneratedColumn<String>(
    'script_profile_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES script_profiles (id)',
    ),
  );
  static const VerificationMeta _ttsVoiceMeta = const VerificationMeta(
    'ttsVoice',
  );
  @override
  late final GeneratedColumn<String> ttsVoice = GeneratedColumn<String>(
    'tts_voice',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _enabledMeta = const VerificationMeta(
    'enabled',
  );
  @override
  late final GeneratedColumn<bool> enabled = GeneratedColumn<bool>(
    'enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    scriptProfileId,
    ttsVoice,
    enabled,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'languages';
  @override
  VerificationContext validateIntegrity(
    Insertable<Language> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('script_profile_id')) {
      context.handle(
        _scriptProfileIdMeta,
        scriptProfileId.isAcceptableOrUnknown(
          data['script_profile_id']!,
          _scriptProfileIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_scriptProfileIdMeta);
    }
    if (data.containsKey('tts_voice')) {
      context.handle(
        _ttsVoiceMeta,
        ttsVoice.isAcceptableOrUnknown(data['tts_voice']!, _ttsVoiceMeta),
      );
    } else if (isInserting) {
      context.missing(_ttsVoiceMeta);
    }
    if (data.containsKey('enabled')) {
      context.handle(
        _enabledMeta,
        enabled.isAcceptableOrUnknown(data['enabled']!, _enabledMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Language map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Language(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      scriptProfileId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}script_profile_id'],
      )!,
      ttsVoice: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tts_voice'],
      )!,
      enabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}enabled'],
      )!,
    );
  }

  @override
  $LanguagesTable createAlias(String alias) {
    return $LanguagesTable(attachedDatabase, alias);
  }
}

class Language extends DataClass implements Insertable<Language> {
  final String id;
  final String name;
  final String scriptProfileId;
  final String ttsVoice;
  final bool enabled;
  const Language({
    required this.id,
    required this.name,
    required this.scriptProfileId,
    required this.ttsVoice,
    required this.enabled,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['script_profile_id'] = Variable<String>(scriptProfileId);
    map['tts_voice'] = Variable<String>(ttsVoice);
    map['enabled'] = Variable<bool>(enabled);
    return map;
  }

  LanguagesCompanion toCompanion(bool nullToAbsent) {
    return LanguagesCompanion(
      id: Value(id),
      name: Value(name),
      scriptProfileId: Value(scriptProfileId),
      ttsVoice: Value(ttsVoice),
      enabled: Value(enabled),
    );
  }

  factory Language.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Language(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      scriptProfileId: serializer.fromJson<String>(json['scriptProfileId']),
      ttsVoice: serializer.fromJson<String>(json['ttsVoice']),
      enabled: serializer.fromJson<bool>(json['enabled']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'scriptProfileId': serializer.toJson<String>(scriptProfileId),
      'ttsVoice': serializer.toJson<String>(ttsVoice),
      'enabled': serializer.toJson<bool>(enabled),
    };
  }

  Language copyWith({
    String? id,
    String? name,
    String? scriptProfileId,
    String? ttsVoice,
    bool? enabled,
  }) => Language(
    id: id ?? this.id,
    name: name ?? this.name,
    scriptProfileId: scriptProfileId ?? this.scriptProfileId,
    ttsVoice: ttsVoice ?? this.ttsVoice,
    enabled: enabled ?? this.enabled,
  );
  Language copyWithCompanion(LanguagesCompanion data) {
    return Language(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      scriptProfileId: data.scriptProfileId.present
          ? data.scriptProfileId.value
          : this.scriptProfileId,
      ttsVoice: data.ttsVoice.present ? data.ttsVoice.value : this.ttsVoice,
      enabled: data.enabled.present ? data.enabled.value : this.enabled,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Language(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('scriptProfileId: $scriptProfileId, ')
          ..write('ttsVoice: $ttsVoice, ')
          ..write('enabled: $enabled')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, scriptProfileId, ttsVoice, enabled);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Language &&
          other.id == this.id &&
          other.name == this.name &&
          other.scriptProfileId == this.scriptProfileId &&
          other.ttsVoice == this.ttsVoice &&
          other.enabled == this.enabled);
}

class LanguagesCompanion extends UpdateCompanion<Language> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> scriptProfileId;
  final Value<String> ttsVoice;
  final Value<bool> enabled;
  final Value<int> rowid;
  const LanguagesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.scriptProfileId = const Value.absent(),
    this.ttsVoice = const Value.absent(),
    this.enabled = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LanguagesCompanion.insert({
    required String id,
    required String name,
    required String scriptProfileId,
    required String ttsVoice,
    this.enabled = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       scriptProfileId = Value(scriptProfileId),
       ttsVoice = Value(ttsVoice);
  static Insertable<Language> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? scriptProfileId,
    Expression<String>? ttsVoice,
    Expression<bool>? enabled,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (scriptProfileId != null) 'script_profile_id': scriptProfileId,
      if (ttsVoice != null) 'tts_voice': ttsVoice,
      if (enabled != null) 'enabled': enabled,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LanguagesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? scriptProfileId,
    Value<String>? ttsVoice,
    Value<bool>? enabled,
    Value<int>? rowid,
  }) {
    return LanguagesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      scriptProfileId: scriptProfileId ?? this.scriptProfileId,
      ttsVoice: ttsVoice ?? this.ttsVoice,
      enabled: enabled ?? this.enabled,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (scriptProfileId.present) {
      map['script_profile_id'] = Variable<String>(scriptProfileId.value);
    }
    if (ttsVoice.present) {
      map['tts_voice'] = Variable<String>(ttsVoice.value);
    }
    if (enabled.present) {
      map['enabled'] = Variable<bool>(enabled.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LanguagesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('scriptProfileId: $scriptProfileId, ')
          ..write('ttsVoice: $ttsVoice, ')
          ..write('enabled: $enabled, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LexemesTable extends Lexemes with TableInfo<$LexemesTable, Lexeme> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LexemesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _languageIdMeta = const VerificationMeta(
    'languageId',
  );
  @override
  late final GeneratedColumn<String> languageId = GeneratedColumn<String>(
    'language_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES languages (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _conceptIdMeta = const VerificationMeta(
    'conceptId',
  );
  @override
  late final GeneratedColumn<String> conceptId = GeneratedColumn<String>(
    'concept_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES concepts (id)',
    ),
  );
  static const VerificationMeta _writtenFormMeta = const VerificationMeta(
    'writtenForm',
  );
  @override
  late final GeneratedColumn<String> writtenForm = GeneratedColumn<String>(
    'written_form',
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
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _audioPathMeta = const VerificationMeta(
    'audioPath',
  );
  @override
  late final GeneratedColumn<String> audioPath = GeneratedColumn<String>(
    'audio_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cefrBandMeta = const VerificationMeta(
    'cefrBand',
  );
  @override
  late final GeneratedColumn<String> cefrBand = GeneratedColumn<String>(
    'cefr_band',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('A1'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    languageId,
    conceptId,
    writtenForm,
    reading,
    audioPath,
    cefrBand,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'lexemes';
  @override
  VerificationContext validateIntegrity(
    Insertable<Lexeme> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('language_id')) {
      context.handle(
        _languageIdMeta,
        languageId.isAcceptableOrUnknown(data['language_id']!, _languageIdMeta),
      );
    } else if (isInserting) {
      context.missing(_languageIdMeta);
    }
    if (data.containsKey('concept_id')) {
      context.handle(
        _conceptIdMeta,
        conceptId.isAcceptableOrUnknown(data['concept_id']!, _conceptIdMeta),
      );
    } else if (isInserting) {
      context.missing(_conceptIdMeta);
    }
    if (data.containsKey('written_form')) {
      context.handle(
        _writtenFormMeta,
        writtenForm.isAcceptableOrUnknown(
          data['written_form']!,
          _writtenFormMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_writtenFormMeta);
    }
    if (data.containsKey('reading')) {
      context.handle(
        _readingMeta,
        reading.isAcceptableOrUnknown(data['reading']!, _readingMeta),
      );
    } else if (isInserting) {
      context.missing(_readingMeta);
    }
    if (data.containsKey('audio_path')) {
      context.handle(
        _audioPathMeta,
        audioPath.isAcceptableOrUnknown(data['audio_path']!, _audioPathMeta),
      );
    }
    if (data.containsKey('cefr_band')) {
      context.handle(
        _cefrBandMeta,
        cefrBand.isAcceptableOrUnknown(data['cefr_band']!, _cefrBandMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Lexeme map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Lexeme(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      languageId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}language_id'],
      )!,
      conceptId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}concept_id'],
      )!,
      writtenForm: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}written_form'],
      )!,
      reading: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reading'],
      )!,
      audioPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}audio_path'],
      ),
      cefrBand: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cefr_band'],
      )!,
    );
  }

  @override
  $LexemesTable createAlias(String alias) {
    return $LexemesTable(attachedDatabase, alias);
  }
}

class Lexeme extends DataClass implements Insertable<Lexeme> {
  final String id;
  final String languageId;
  final String conceptId;
  final String writtenForm;
  final String reading;
  final String? audioPath;
  final String cefrBand;
  const Lexeme({
    required this.id,
    required this.languageId,
    required this.conceptId,
    required this.writtenForm,
    required this.reading,
    this.audioPath,
    required this.cefrBand,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['language_id'] = Variable<String>(languageId);
    map['concept_id'] = Variable<String>(conceptId);
    map['written_form'] = Variable<String>(writtenForm);
    map['reading'] = Variable<String>(reading);
    if (!nullToAbsent || audioPath != null) {
      map['audio_path'] = Variable<String>(audioPath);
    }
    map['cefr_band'] = Variable<String>(cefrBand);
    return map;
  }

  LexemesCompanion toCompanion(bool nullToAbsent) {
    return LexemesCompanion(
      id: Value(id),
      languageId: Value(languageId),
      conceptId: Value(conceptId),
      writtenForm: Value(writtenForm),
      reading: Value(reading),
      audioPath: audioPath == null && nullToAbsent
          ? const Value.absent()
          : Value(audioPath),
      cefrBand: Value(cefrBand),
    );
  }

  factory Lexeme.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Lexeme(
      id: serializer.fromJson<String>(json['id']),
      languageId: serializer.fromJson<String>(json['languageId']),
      conceptId: serializer.fromJson<String>(json['conceptId']),
      writtenForm: serializer.fromJson<String>(json['writtenForm']),
      reading: serializer.fromJson<String>(json['reading']),
      audioPath: serializer.fromJson<String?>(json['audioPath']),
      cefrBand: serializer.fromJson<String>(json['cefrBand']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'languageId': serializer.toJson<String>(languageId),
      'conceptId': serializer.toJson<String>(conceptId),
      'writtenForm': serializer.toJson<String>(writtenForm),
      'reading': serializer.toJson<String>(reading),
      'audioPath': serializer.toJson<String?>(audioPath),
      'cefrBand': serializer.toJson<String>(cefrBand),
    };
  }

  Lexeme copyWith({
    String? id,
    String? languageId,
    String? conceptId,
    String? writtenForm,
    String? reading,
    Value<String?> audioPath = const Value.absent(),
    String? cefrBand,
  }) => Lexeme(
    id: id ?? this.id,
    languageId: languageId ?? this.languageId,
    conceptId: conceptId ?? this.conceptId,
    writtenForm: writtenForm ?? this.writtenForm,
    reading: reading ?? this.reading,
    audioPath: audioPath.present ? audioPath.value : this.audioPath,
    cefrBand: cefrBand ?? this.cefrBand,
  );
  Lexeme copyWithCompanion(LexemesCompanion data) {
    return Lexeme(
      id: data.id.present ? data.id.value : this.id,
      languageId: data.languageId.present
          ? data.languageId.value
          : this.languageId,
      conceptId: data.conceptId.present ? data.conceptId.value : this.conceptId,
      writtenForm: data.writtenForm.present
          ? data.writtenForm.value
          : this.writtenForm,
      reading: data.reading.present ? data.reading.value : this.reading,
      audioPath: data.audioPath.present ? data.audioPath.value : this.audioPath,
      cefrBand: data.cefrBand.present ? data.cefrBand.value : this.cefrBand,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Lexeme(')
          ..write('id: $id, ')
          ..write('languageId: $languageId, ')
          ..write('conceptId: $conceptId, ')
          ..write('writtenForm: $writtenForm, ')
          ..write('reading: $reading, ')
          ..write('audioPath: $audioPath, ')
          ..write('cefrBand: $cefrBand')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    languageId,
    conceptId,
    writtenForm,
    reading,
    audioPath,
    cefrBand,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Lexeme &&
          other.id == this.id &&
          other.languageId == this.languageId &&
          other.conceptId == this.conceptId &&
          other.writtenForm == this.writtenForm &&
          other.reading == this.reading &&
          other.audioPath == this.audioPath &&
          other.cefrBand == this.cefrBand);
}

class LexemesCompanion extends UpdateCompanion<Lexeme> {
  final Value<String> id;
  final Value<String> languageId;
  final Value<String> conceptId;
  final Value<String> writtenForm;
  final Value<String> reading;
  final Value<String?> audioPath;
  final Value<String> cefrBand;
  final Value<int> rowid;
  const LexemesCompanion({
    this.id = const Value.absent(),
    this.languageId = const Value.absent(),
    this.conceptId = const Value.absent(),
    this.writtenForm = const Value.absent(),
    this.reading = const Value.absent(),
    this.audioPath = const Value.absent(),
    this.cefrBand = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LexemesCompanion.insert({
    required String id,
    required String languageId,
    required String conceptId,
    required String writtenForm,
    required String reading,
    this.audioPath = const Value.absent(),
    this.cefrBand = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       languageId = Value(languageId),
       conceptId = Value(conceptId),
       writtenForm = Value(writtenForm),
       reading = Value(reading);
  static Insertable<Lexeme> custom({
    Expression<String>? id,
    Expression<String>? languageId,
    Expression<String>? conceptId,
    Expression<String>? writtenForm,
    Expression<String>? reading,
    Expression<String>? audioPath,
    Expression<String>? cefrBand,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (languageId != null) 'language_id': languageId,
      if (conceptId != null) 'concept_id': conceptId,
      if (writtenForm != null) 'written_form': writtenForm,
      if (reading != null) 'reading': reading,
      if (audioPath != null) 'audio_path': audioPath,
      if (cefrBand != null) 'cefr_band': cefrBand,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LexemesCompanion copyWith({
    Value<String>? id,
    Value<String>? languageId,
    Value<String>? conceptId,
    Value<String>? writtenForm,
    Value<String>? reading,
    Value<String?>? audioPath,
    Value<String>? cefrBand,
    Value<int>? rowid,
  }) {
    return LexemesCompanion(
      id: id ?? this.id,
      languageId: languageId ?? this.languageId,
      conceptId: conceptId ?? this.conceptId,
      writtenForm: writtenForm ?? this.writtenForm,
      reading: reading ?? this.reading,
      audioPath: audioPath ?? this.audioPath,
      cefrBand: cefrBand ?? this.cefrBand,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (languageId.present) {
      map['language_id'] = Variable<String>(languageId.value);
    }
    if (conceptId.present) {
      map['concept_id'] = Variable<String>(conceptId.value);
    }
    if (writtenForm.present) {
      map['written_form'] = Variable<String>(writtenForm.value);
    }
    if (reading.present) {
      map['reading'] = Variable<String>(reading.value);
    }
    if (audioPath.present) {
      map['audio_path'] = Variable<String>(audioPath.value);
    }
    if (cefrBand.present) {
      map['cefr_band'] = Variable<String>(cefrBand.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LexemesCompanion(')
          ..write('id: $id, ')
          ..write('languageId: $languageId, ')
          ..write('conceptId: $conceptId, ')
          ..write('writtenForm: $writtenForm, ')
          ..write('reading: $reading, ')
          ..write('audioPath: $audioPath, ')
          ..write('cefrBand: $cefrBand, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CharactersTable extends Characters
    with TableInfo<$CharactersTable, Character> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CharactersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _languageIdMeta = const VerificationMeta(
    'languageId',
  );
  @override
  late final GeneratedColumn<String> languageId = GeneratedColumn<String>(
    'language_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES languages (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _glyphMeta = const VerificationMeta('glyph');
  @override
  late final GeneratedColumn<String> glyph = GeneratedColumn<String>(
    'glyph',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _readingsJsonMeta = const VerificationMeta(
    'readingsJson',
  );
  @override
  late final GeneratedColumn<String> readingsJson = GeneratedColumn<String>(
    'readings_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _meaningMeta = const VerificationMeta(
    'meaning',
  );
  @override
  late final GeneratedColumn<String> meaning = GeneratedColumn<String>(
    'meaning',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _strokeOrderAssetIdMeta =
      const VerificationMeta('strokeOrderAssetId');
  @override
  late final GeneratedColumn<String> strokeOrderAssetId =
      GeneratedColumn<String>(
        'stroke_order_asset_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _mnemonicIdMeta = const VerificationMeta(
    'mnemonicId',
  );
  @override
  late final GeneratedColumn<String> mnemonicId = GeneratedColumn<String>(
    'mnemonic_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    languageId,
    glyph,
    readingsJson,
    meaning,
    strokeOrderAssetId,
    mnemonicId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'characters';
  @override
  VerificationContext validateIntegrity(
    Insertable<Character> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('language_id')) {
      context.handle(
        _languageIdMeta,
        languageId.isAcceptableOrUnknown(data['language_id']!, _languageIdMeta),
      );
    } else if (isInserting) {
      context.missing(_languageIdMeta);
    }
    if (data.containsKey('glyph')) {
      context.handle(
        _glyphMeta,
        glyph.isAcceptableOrUnknown(data['glyph']!, _glyphMeta),
      );
    } else if (isInserting) {
      context.missing(_glyphMeta);
    }
    if (data.containsKey('readings_json')) {
      context.handle(
        _readingsJsonMeta,
        readingsJson.isAcceptableOrUnknown(
          data['readings_json']!,
          _readingsJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_readingsJsonMeta);
    }
    if (data.containsKey('meaning')) {
      context.handle(
        _meaningMeta,
        meaning.isAcceptableOrUnknown(data['meaning']!, _meaningMeta),
      );
    } else if (isInserting) {
      context.missing(_meaningMeta);
    }
    if (data.containsKey('stroke_order_asset_id')) {
      context.handle(
        _strokeOrderAssetIdMeta,
        strokeOrderAssetId.isAcceptableOrUnknown(
          data['stroke_order_asset_id']!,
          _strokeOrderAssetIdMeta,
        ),
      );
    }
    if (data.containsKey('mnemonic_id')) {
      context.handle(
        _mnemonicIdMeta,
        mnemonicId.isAcceptableOrUnknown(data['mnemonic_id']!, _mnemonicIdMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Character map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Character(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      languageId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}language_id'],
      )!,
      glyph: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}glyph'],
      )!,
      readingsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}readings_json'],
      )!,
      meaning: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}meaning'],
      )!,
      strokeOrderAssetId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}stroke_order_asset_id'],
      ),
      mnemonicId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mnemonic_id'],
      ),
    );
  }

  @override
  $CharactersTable createAlias(String alias) {
    return $CharactersTable(attachedDatabase, alias);
  }
}

class Character extends DataClass implements Insertable<Character> {
  final String id;
  final String languageId;
  final String glyph;
  final String readingsJson;
  final String meaning;
  final String? strokeOrderAssetId;
  final String? mnemonicId;
  const Character({
    required this.id,
    required this.languageId,
    required this.glyph,
    required this.readingsJson,
    required this.meaning,
    this.strokeOrderAssetId,
    this.mnemonicId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['language_id'] = Variable<String>(languageId);
    map['glyph'] = Variable<String>(glyph);
    map['readings_json'] = Variable<String>(readingsJson);
    map['meaning'] = Variable<String>(meaning);
    if (!nullToAbsent || strokeOrderAssetId != null) {
      map['stroke_order_asset_id'] = Variable<String>(strokeOrderAssetId);
    }
    if (!nullToAbsent || mnemonicId != null) {
      map['mnemonic_id'] = Variable<String>(mnemonicId);
    }
    return map;
  }

  CharactersCompanion toCompanion(bool nullToAbsent) {
    return CharactersCompanion(
      id: Value(id),
      languageId: Value(languageId),
      glyph: Value(glyph),
      readingsJson: Value(readingsJson),
      meaning: Value(meaning),
      strokeOrderAssetId: strokeOrderAssetId == null && nullToAbsent
          ? const Value.absent()
          : Value(strokeOrderAssetId),
      mnemonicId: mnemonicId == null && nullToAbsent
          ? const Value.absent()
          : Value(mnemonicId),
    );
  }

  factory Character.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Character(
      id: serializer.fromJson<String>(json['id']),
      languageId: serializer.fromJson<String>(json['languageId']),
      glyph: serializer.fromJson<String>(json['glyph']),
      readingsJson: serializer.fromJson<String>(json['readingsJson']),
      meaning: serializer.fromJson<String>(json['meaning']),
      strokeOrderAssetId: serializer.fromJson<String?>(
        json['strokeOrderAssetId'],
      ),
      mnemonicId: serializer.fromJson<String?>(json['mnemonicId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'languageId': serializer.toJson<String>(languageId),
      'glyph': serializer.toJson<String>(glyph),
      'readingsJson': serializer.toJson<String>(readingsJson),
      'meaning': serializer.toJson<String>(meaning),
      'strokeOrderAssetId': serializer.toJson<String?>(strokeOrderAssetId),
      'mnemonicId': serializer.toJson<String?>(mnemonicId),
    };
  }

  Character copyWith({
    String? id,
    String? languageId,
    String? glyph,
    String? readingsJson,
    String? meaning,
    Value<String?> strokeOrderAssetId = const Value.absent(),
    Value<String?> mnemonicId = const Value.absent(),
  }) => Character(
    id: id ?? this.id,
    languageId: languageId ?? this.languageId,
    glyph: glyph ?? this.glyph,
    readingsJson: readingsJson ?? this.readingsJson,
    meaning: meaning ?? this.meaning,
    strokeOrderAssetId: strokeOrderAssetId.present
        ? strokeOrderAssetId.value
        : this.strokeOrderAssetId,
    mnemonicId: mnemonicId.present ? mnemonicId.value : this.mnemonicId,
  );
  Character copyWithCompanion(CharactersCompanion data) {
    return Character(
      id: data.id.present ? data.id.value : this.id,
      languageId: data.languageId.present
          ? data.languageId.value
          : this.languageId,
      glyph: data.glyph.present ? data.glyph.value : this.glyph,
      readingsJson: data.readingsJson.present
          ? data.readingsJson.value
          : this.readingsJson,
      meaning: data.meaning.present ? data.meaning.value : this.meaning,
      strokeOrderAssetId: data.strokeOrderAssetId.present
          ? data.strokeOrderAssetId.value
          : this.strokeOrderAssetId,
      mnemonicId: data.mnemonicId.present
          ? data.mnemonicId.value
          : this.mnemonicId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Character(')
          ..write('id: $id, ')
          ..write('languageId: $languageId, ')
          ..write('glyph: $glyph, ')
          ..write('readingsJson: $readingsJson, ')
          ..write('meaning: $meaning, ')
          ..write('strokeOrderAssetId: $strokeOrderAssetId, ')
          ..write('mnemonicId: $mnemonicId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    languageId,
    glyph,
    readingsJson,
    meaning,
    strokeOrderAssetId,
    mnemonicId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Character &&
          other.id == this.id &&
          other.languageId == this.languageId &&
          other.glyph == this.glyph &&
          other.readingsJson == this.readingsJson &&
          other.meaning == this.meaning &&
          other.strokeOrderAssetId == this.strokeOrderAssetId &&
          other.mnemonicId == this.mnemonicId);
}

class CharactersCompanion extends UpdateCompanion<Character> {
  final Value<String> id;
  final Value<String> languageId;
  final Value<String> glyph;
  final Value<String> readingsJson;
  final Value<String> meaning;
  final Value<String?> strokeOrderAssetId;
  final Value<String?> mnemonicId;
  final Value<int> rowid;
  const CharactersCompanion({
    this.id = const Value.absent(),
    this.languageId = const Value.absent(),
    this.glyph = const Value.absent(),
    this.readingsJson = const Value.absent(),
    this.meaning = const Value.absent(),
    this.strokeOrderAssetId = const Value.absent(),
    this.mnemonicId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CharactersCompanion.insert({
    required String id,
    required String languageId,
    required String glyph,
    required String readingsJson,
    required String meaning,
    this.strokeOrderAssetId = const Value.absent(),
    this.mnemonicId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       languageId = Value(languageId),
       glyph = Value(glyph),
       readingsJson = Value(readingsJson),
       meaning = Value(meaning);
  static Insertable<Character> custom({
    Expression<String>? id,
    Expression<String>? languageId,
    Expression<String>? glyph,
    Expression<String>? readingsJson,
    Expression<String>? meaning,
    Expression<String>? strokeOrderAssetId,
    Expression<String>? mnemonicId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (languageId != null) 'language_id': languageId,
      if (glyph != null) 'glyph': glyph,
      if (readingsJson != null) 'readings_json': readingsJson,
      if (meaning != null) 'meaning': meaning,
      if (strokeOrderAssetId != null)
        'stroke_order_asset_id': strokeOrderAssetId,
      if (mnemonicId != null) 'mnemonic_id': mnemonicId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CharactersCompanion copyWith({
    Value<String>? id,
    Value<String>? languageId,
    Value<String>? glyph,
    Value<String>? readingsJson,
    Value<String>? meaning,
    Value<String?>? strokeOrderAssetId,
    Value<String?>? mnemonicId,
    Value<int>? rowid,
  }) {
    return CharactersCompanion(
      id: id ?? this.id,
      languageId: languageId ?? this.languageId,
      glyph: glyph ?? this.glyph,
      readingsJson: readingsJson ?? this.readingsJson,
      meaning: meaning ?? this.meaning,
      strokeOrderAssetId: strokeOrderAssetId ?? this.strokeOrderAssetId,
      mnemonicId: mnemonicId ?? this.mnemonicId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (languageId.present) {
      map['language_id'] = Variable<String>(languageId.value);
    }
    if (glyph.present) {
      map['glyph'] = Variable<String>(glyph.value);
    }
    if (readingsJson.present) {
      map['readings_json'] = Variable<String>(readingsJson.value);
    }
    if (meaning.present) {
      map['meaning'] = Variable<String>(meaning.value);
    }
    if (strokeOrderAssetId.present) {
      map['stroke_order_asset_id'] = Variable<String>(strokeOrderAssetId.value);
    }
    if (mnemonicId.present) {
      map['mnemonic_id'] = Variable<String>(mnemonicId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CharactersCompanion(')
          ..write('id: $id, ')
          ..write('languageId: $languageId, ')
          ..write('glyph: $glyph, ')
          ..write('readingsJson: $readingsJson, ')
          ..write('meaning: $meaning, ')
          ..write('strokeOrderAssetId: $strokeOrderAssetId, ')
          ..write('mnemonicId: $mnemonicId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CharComponentsTable extends CharComponents
    with TableInfo<$CharComponentsTable, CharComponent> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CharComponentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _characterIdMeta = const VerificationMeta(
    'characterId',
  );
  @override
  late final GeneratedColumn<String> characterId = GeneratedColumn<String>(
    'character_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES characters (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _componentGlyphMeta = const VerificationMeta(
    'componentGlyph',
  );
  @override
  late final GeneratedColumn<String> componentGlyph = GeneratedColumn<String>(
    'component_glyph',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<String> position = GeneratedColumn<String>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    characterId,
    componentGlyph,
    position,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'char_components';
  @override
  VerificationContext validateIntegrity(
    Insertable<CharComponent> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('character_id')) {
      context.handle(
        _characterIdMeta,
        characterId.isAcceptableOrUnknown(
          data['character_id']!,
          _characterIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_characterIdMeta);
    }
    if (data.containsKey('component_glyph')) {
      context.handle(
        _componentGlyphMeta,
        componentGlyph.isAcceptableOrUnknown(
          data['component_glyph']!,
          _componentGlyphMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_componentGlyphMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CharComponent map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CharComponent(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      characterId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}character_id'],
      )!,
      componentGlyph: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}component_glyph'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}position'],
      )!,
    );
  }

  @override
  $CharComponentsTable createAlias(String alias) {
    return $CharComponentsTable(attachedDatabase, alias);
  }
}

class CharComponent extends DataClass implements Insertable<CharComponent> {
  final String id;
  final String characterId;
  final String componentGlyph;
  final String position;
  const CharComponent({
    required this.id,
    required this.characterId,
    required this.componentGlyph,
    required this.position,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['character_id'] = Variable<String>(characterId);
    map['component_glyph'] = Variable<String>(componentGlyph);
    map['position'] = Variable<String>(position);
    return map;
  }

  CharComponentsCompanion toCompanion(bool nullToAbsent) {
    return CharComponentsCompanion(
      id: Value(id),
      characterId: Value(characterId),
      componentGlyph: Value(componentGlyph),
      position: Value(position),
    );
  }

  factory CharComponent.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CharComponent(
      id: serializer.fromJson<String>(json['id']),
      characterId: serializer.fromJson<String>(json['characterId']),
      componentGlyph: serializer.fromJson<String>(json['componentGlyph']),
      position: serializer.fromJson<String>(json['position']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'characterId': serializer.toJson<String>(characterId),
      'componentGlyph': serializer.toJson<String>(componentGlyph),
      'position': serializer.toJson<String>(position),
    };
  }

  CharComponent copyWith({
    String? id,
    String? characterId,
    String? componentGlyph,
    String? position,
  }) => CharComponent(
    id: id ?? this.id,
    characterId: characterId ?? this.characterId,
    componentGlyph: componentGlyph ?? this.componentGlyph,
    position: position ?? this.position,
  );
  CharComponent copyWithCompanion(CharComponentsCompanion data) {
    return CharComponent(
      id: data.id.present ? data.id.value : this.id,
      characterId: data.characterId.present
          ? data.characterId.value
          : this.characterId,
      componentGlyph: data.componentGlyph.present
          ? data.componentGlyph.value
          : this.componentGlyph,
      position: data.position.present ? data.position.value : this.position,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CharComponent(')
          ..write('id: $id, ')
          ..write('characterId: $characterId, ')
          ..write('componentGlyph: $componentGlyph, ')
          ..write('position: $position')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, characterId, componentGlyph, position);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CharComponent &&
          other.id == this.id &&
          other.characterId == this.characterId &&
          other.componentGlyph == this.componentGlyph &&
          other.position == this.position);
}

class CharComponentsCompanion extends UpdateCompanion<CharComponent> {
  final Value<String> id;
  final Value<String> characterId;
  final Value<String> componentGlyph;
  final Value<String> position;
  final Value<int> rowid;
  const CharComponentsCompanion({
    this.id = const Value.absent(),
    this.characterId = const Value.absent(),
    this.componentGlyph = const Value.absent(),
    this.position = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CharComponentsCompanion.insert({
    required String id,
    required String characterId,
    required String componentGlyph,
    required String position,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       characterId = Value(characterId),
       componentGlyph = Value(componentGlyph),
       position = Value(position);
  static Insertable<CharComponent> custom({
    Expression<String>? id,
    Expression<String>? characterId,
    Expression<String>? componentGlyph,
    Expression<String>? position,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (characterId != null) 'character_id': characterId,
      if (componentGlyph != null) 'component_glyph': componentGlyph,
      if (position != null) 'position': position,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CharComponentsCompanion copyWith({
    Value<String>? id,
    Value<String>? characterId,
    Value<String>? componentGlyph,
    Value<String>? position,
    Value<int>? rowid,
  }) {
    return CharComponentsCompanion(
      id: id ?? this.id,
      characterId: characterId ?? this.characterId,
      componentGlyph: componentGlyph ?? this.componentGlyph,
      position: position ?? this.position,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (characterId.present) {
      map['character_id'] = Variable<String>(characterId.value);
    }
    if (componentGlyph.present) {
      map['component_glyph'] = Variable<String>(componentGlyph.value);
    }
    if (position.present) {
      map['position'] = Variable<String>(position.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CharComponentsCompanion(')
          ..write('id: $id, ')
          ..write('characterId: $characterId, ')
          ..write('componentGlyph: $componentGlyph, ')
          ..write('position: $position, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CanDoGoalsTable extends CanDoGoals
    with TableInfo<$CanDoGoalsTable, CanDoGoal> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CanDoGoalsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _languageIdMeta = const VerificationMeta(
    'languageId',
  );
  @override
  late final GeneratedColumn<String> languageId = GeneratedColumn<String>(
    'language_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES languages (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _cefrBandMeta = const VerificationMeta(
    'cefrBand',
  );
  @override
  late final GeneratedColumn<String> cefrBand = GeneratedColumn<String>(
    'cefr_band',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, languageId, cefrBand, description];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'can_do_goals';
  @override
  VerificationContext validateIntegrity(
    Insertable<CanDoGoal> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('language_id')) {
      context.handle(
        _languageIdMeta,
        languageId.isAcceptableOrUnknown(data['language_id']!, _languageIdMeta),
      );
    } else if (isInserting) {
      context.missing(_languageIdMeta);
    }
    if (data.containsKey('cefr_band')) {
      context.handle(
        _cefrBandMeta,
        cefrBand.isAcceptableOrUnknown(data['cefr_band']!, _cefrBandMeta),
      );
    } else if (isInserting) {
      context.missing(_cefrBandMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_descriptionMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CanDoGoal map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CanDoGoal(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      languageId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}language_id'],
      )!,
      cefrBand: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cefr_band'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
    );
  }

  @override
  $CanDoGoalsTable createAlias(String alias) {
    return $CanDoGoalsTable(attachedDatabase, alias);
  }
}

class CanDoGoal extends DataClass implements Insertable<CanDoGoal> {
  final String id;
  final String languageId;
  final String cefrBand;
  final String description;
  const CanDoGoal({
    required this.id,
    required this.languageId,
    required this.cefrBand,
    required this.description,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['language_id'] = Variable<String>(languageId);
    map['cefr_band'] = Variable<String>(cefrBand);
    map['description'] = Variable<String>(description);
    return map;
  }

  CanDoGoalsCompanion toCompanion(bool nullToAbsent) {
    return CanDoGoalsCompanion(
      id: Value(id),
      languageId: Value(languageId),
      cefrBand: Value(cefrBand),
      description: Value(description),
    );
  }

  factory CanDoGoal.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CanDoGoal(
      id: serializer.fromJson<String>(json['id']),
      languageId: serializer.fromJson<String>(json['languageId']),
      cefrBand: serializer.fromJson<String>(json['cefrBand']),
      description: serializer.fromJson<String>(json['description']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'languageId': serializer.toJson<String>(languageId),
      'cefrBand': serializer.toJson<String>(cefrBand),
      'description': serializer.toJson<String>(description),
    };
  }

  CanDoGoal copyWith({
    String? id,
    String? languageId,
    String? cefrBand,
    String? description,
  }) => CanDoGoal(
    id: id ?? this.id,
    languageId: languageId ?? this.languageId,
    cefrBand: cefrBand ?? this.cefrBand,
    description: description ?? this.description,
  );
  CanDoGoal copyWithCompanion(CanDoGoalsCompanion data) {
    return CanDoGoal(
      id: data.id.present ? data.id.value : this.id,
      languageId: data.languageId.present
          ? data.languageId.value
          : this.languageId,
      cefrBand: data.cefrBand.present ? data.cefrBand.value : this.cefrBand,
      description: data.description.present
          ? data.description.value
          : this.description,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CanDoGoal(')
          ..write('id: $id, ')
          ..write('languageId: $languageId, ')
          ..write('cefrBand: $cefrBand, ')
          ..write('description: $description')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, languageId, cefrBand, description);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CanDoGoal &&
          other.id == this.id &&
          other.languageId == this.languageId &&
          other.cefrBand == this.cefrBand &&
          other.description == this.description);
}

class CanDoGoalsCompanion extends UpdateCompanion<CanDoGoal> {
  final Value<String> id;
  final Value<String> languageId;
  final Value<String> cefrBand;
  final Value<String> description;
  final Value<int> rowid;
  const CanDoGoalsCompanion({
    this.id = const Value.absent(),
    this.languageId = const Value.absent(),
    this.cefrBand = const Value.absent(),
    this.description = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CanDoGoalsCompanion.insert({
    required String id,
    required String languageId,
    required String cefrBand,
    required String description,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       languageId = Value(languageId),
       cefrBand = Value(cefrBand),
       description = Value(description);
  static Insertable<CanDoGoal> custom({
    Expression<String>? id,
    Expression<String>? languageId,
    Expression<String>? cefrBand,
    Expression<String>? description,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (languageId != null) 'language_id': languageId,
      if (cefrBand != null) 'cefr_band': cefrBand,
      if (description != null) 'description': description,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CanDoGoalsCompanion copyWith({
    Value<String>? id,
    Value<String>? languageId,
    Value<String>? cefrBand,
    Value<String>? description,
    Value<int>? rowid,
  }) {
    return CanDoGoalsCompanion(
      id: id ?? this.id,
      languageId: languageId ?? this.languageId,
      cefrBand: cefrBand ?? this.cefrBand,
      description: description ?? this.description,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (languageId.present) {
      map['language_id'] = Variable<String>(languageId.value);
    }
    if (cefrBand.present) {
      map['cefr_band'] = Variable<String>(cefrBand.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CanDoGoalsCompanion(')
          ..write('id: $id, ')
          ..write('languageId: $languageId, ')
          ..write('cefrBand: $cefrBand, ')
          ..write('description: $description, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $GrammarPointsTable extends GrammarPoints
    with TableInfo<$GrammarPointsTable, GrammarPoint> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GrammarPointsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _languageIdMeta = const VerificationMeta(
    'languageId',
  );
  @override
  late final GeneratedColumn<String> languageId = GeneratedColumn<String>(
    'language_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES languages (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _cefrBandMeta = const VerificationMeta(
    'cefrBand',
  );
  @override
  late final GeneratedColumn<String> cefrBand = GeneratedColumn<String>(
    'cefr_band',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sequenceIndexMeta = const VerificationMeta(
    'sequenceIndex',
  );
  @override
  late final GeneratedColumn<int> sequenceIndex = GeneratedColumn<int>(
    'sequence_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _canDoIdMeta = const VerificationMeta(
    'canDoId',
  );
  @override
  late final GeneratedColumn<String> canDoId = GeneratedColumn<String>(
    'can_do_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES can_do_goals (id)',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    languageId,
    cefrBand,
    sequenceIndex,
    canDoId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'grammar_points';
  @override
  VerificationContext validateIntegrity(
    Insertable<GrammarPoint> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('language_id')) {
      context.handle(
        _languageIdMeta,
        languageId.isAcceptableOrUnknown(data['language_id']!, _languageIdMeta),
      );
    } else if (isInserting) {
      context.missing(_languageIdMeta);
    }
    if (data.containsKey('cefr_band')) {
      context.handle(
        _cefrBandMeta,
        cefrBand.isAcceptableOrUnknown(data['cefr_band']!, _cefrBandMeta),
      );
    } else if (isInserting) {
      context.missing(_cefrBandMeta);
    }
    if (data.containsKey('sequence_index')) {
      context.handle(
        _sequenceIndexMeta,
        sequenceIndex.isAcceptableOrUnknown(
          data['sequence_index']!,
          _sequenceIndexMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sequenceIndexMeta);
    }
    if (data.containsKey('can_do_id')) {
      context.handle(
        _canDoIdMeta,
        canDoId.isAcceptableOrUnknown(data['can_do_id']!, _canDoIdMeta),
      );
    } else if (isInserting) {
      context.missing(_canDoIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  GrammarPoint map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GrammarPoint(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      languageId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}language_id'],
      )!,
      cefrBand: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cefr_band'],
      )!,
      sequenceIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sequence_index'],
      )!,
      canDoId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}can_do_id'],
      )!,
    );
  }

  @override
  $GrammarPointsTable createAlias(String alias) {
    return $GrammarPointsTable(attachedDatabase, alias);
  }
}

class GrammarPoint extends DataClass implements Insertable<GrammarPoint> {
  final String id;
  final String languageId;
  final String cefrBand;
  final int sequenceIndex;
  final String canDoId;
  const GrammarPoint({
    required this.id,
    required this.languageId,
    required this.cefrBand,
    required this.sequenceIndex,
    required this.canDoId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['language_id'] = Variable<String>(languageId);
    map['cefr_band'] = Variable<String>(cefrBand);
    map['sequence_index'] = Variable<int>(sequenceIndex);
    map['can_do_id'] = Variable<String>(canDoId);
    return map;
  }

  GrammarPointsCompanion toCompanion(bool nullToAbsent) {
    return GrammarPointsCompanion(
      id: Value(id),
      languageId: Value(languageId),
      cefrBand: Value(cefrBand),
      sequenceIndex: Value(sequenceIndex),
      canDoId: Value(canDoId),
    );
  }

  factory GrammarPoint.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GrammarPoint(
      id: serializer.fromJson<String>(json['id']),
      languageId: serializer.fromJson<String>(json['languageId']),
      cefrBand: serializer.fromJson<String>(json['cefrBand']),
      sequenceIndex: serializer.fromJson<int>(json['sequenceIndex']),
      canDoId: serializer.fromJson<String>(json['canDoId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'languageId': serializer.toJson<String>(languageId),
      'cefrBand': serializer.toJson<String>(cefrBand),
      'sequenceIndex': serializer.toJson<int>(sequenceIndex),
      'canDoId': serializer.toJson<String>(canDoId),
    };
  }

  GrammarPoint copyWith({
    String? id,
    String? languageId,
    String? cefrBand,
    int? sequenceIndex,
    String? canDoId,
  }) => GrammarPoint(
    id: id ?? this.id,
    languageId: languageId ?? this.languageId,
    cefrBand: cefrBand ?? this.cefrBand,
    sequenceIndex: sequenceIndex ?? this.sequenceIndex,
    canDoId: canDoId ?? this.canDoId,
  );
  GrammarPoint copyWithCompanion(GrammarPointsCompanion data) {
    return GrammarPoint(
      id: data.id.present ? data.id.value : this.id,
      languageId: data.languageId.present
          ? data.languageId.value
          : this.languageId,
      cefrBand: data.cefrBand.present ? data.cefrBand.value : this.cefrBand,
      sequenceIndex: data.sequenceIndex.present
          ? data.sequenceIndex.value
          : this.sequenceIndex,
      canDoId: data.canDoId.present ? data.canDoId.value : this.canDoId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GrammarPoint(')
          ..write('id: $id, ')
          ..write('languageId: $languageId, ')
          ..write('cefrBand: $cefrBand, ')
          ..write('sequenceIndex: $sequenceIndex, ')
          ..write('canDoId: $canDoId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, languageId, cefrBand, sequenceIndex, canDoId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GrammarPoint &&
          other.id == this.id &&
          other.languageId == this.languageId &&
          other.cefrBand == this.cefrBand &&
          other.sequenceIndex == this.sequenceIndex &&
          other.canDoId == this.canDoId);
}

class GrammarPointsCompanion extends UpdateCompanion<GrammarPoint> {
  final Value<String> id;
  final Value<String> languageId;
  final Value<String> cefrBand;
  final Value<int> sequenceIndex;
  final Value<String> canDoId;
  final Value<int> rowid;
  const GrammarPointsCompanion({
    this.id = const Value.absent(),
    this.languageId = const Value.absent(),
    this.cefrBand = const Value.absent(),
    this.sequenceIndex = const Value.absent(),
    this.canDoId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GrammarPointsCompanion.insert({
    required String id,
    required String languageId,
    required String cefrBand,
    required int sequenceIndex,
    required String canDoId,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       languageId = Value(languageId),
       cefrBand = Value(cefrBand),
       sequenceIndex = Value(sequenceIndex),
       canDoId = Value(canDoId);
  static Insertable<GrammarPoint> custom({
    Expression<String>? id,
    Expression<String>? languageId,
    Expression<String>? cefrBand,
    Expression<int>? sequenceIndex,
    Expression<String>? canDoId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (languageId != null) 'language_id': languageId,
      if (cefrBand != null) 'cefr_band': cefrBand,
      if (sequenceIndex != null) 'sequence_index': sequenceIndex,
      if (canDoId != null) 'can_do_id': canDoId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GrammarPointsCompanion copyWith({
    Value<String>? id,
    Value<String>? languageId,
    Value<String>? cefrBand,
    Value<int>? sequenceIndex,
    Value<String>? canDoId,
    Value<int>? rowid,
  }) {
    return GrammarPointsCompanion(
      id: id ?? this.id,
      languageId: languageId ?? this.languageId,
      cefrBand: cefrBand ?? this.cefrBand,
      sequenceIndex: sequenceIndex ?? this.sequenceIndex,
      canDoId: canDoId ?? this.canDoId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (languageId.present) {
      map['language_id'] = Variable<String>(languageId.value);
    }
    if (cefrBand.present) {
      map['cefr_band'] = Variable<String>(cefrBand.value);
    }
    if (sequenceIndex.present) {
      map['sequence_index'] = Variable<int>(sequenceIndex.value);
    }
    if (canDoId.present) {
      map['can_do_id'] = Variable<String>(canDoId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GrammarPointsCompanion(')
          ..write('id: $id, ')
          ..write('languageId: $languageId, ')
          ..write('cefrBand: $cefrBand, ')
          ..write('sequenceIndex: $sequenceIndex, ')
          ..write('canDoId: $canDoId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SentencesTable extends Sentences
    with TableInfo<$SentencesTable, Sentence> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SentencesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _languageIdMeta = const VerificationMeta(
    'languageId',
  );
  @override
  late final GeneratedColumn<String> languageId = GeneratedColumn<String>(
    'language_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES languages (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _cefrBandMeta = const VerificationMeta(
    'cefrBand',
  );
  @override
  late final GeneratedColumn<String> cefrBand = GeneratedColumn<String>(
    'cefr_band',
    aliasedName,
    false,
    type: DriftSqlType.string,
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
  static const VerificationMeta _knownCoverageMeta = const VerificationMeta(
    'knownCoverage',
  );
  @override
  late final GeneratedColumn<double> knownCoverage = GeneratedColumn<double>(
    'known_coverage',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(1.0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    languageId,
    cefrBand,
    content,
    knownCoverage,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sentences';
  @override
  VerificationContext validateIntegrity(
    Insertable<Sentence> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('language_id')) {
      context.handle(
        _languageIdMeta,
        languageId.isAcceptableOrUnknown(data['language_id']!, _languageIdMeta),
      );
    } else if (isInserting) {
      context.missing(_languageIdMeta);
    }
    if (data.containsKey('cefr_band')) {
      context.handle(
        _cefrBandMeta,
        cefrBand.isAcceptableOrUnknown(data['cefr_band']!, _cefrBandMeta),
      );
    } else if (isInserting) {
      context.missing(_cefrBandMeta);
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('known_coverage')) {
      context.handle(
        _knownCoverageMeta,
        knownCoverage.isAcceptableOrUnknown(
          data['known_coverage']!,
          _knownCoverageMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Sentence map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Sentence(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      languageId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}language_id'],
      )!,
      cefrBand: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cefr_band'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      knownCoverage: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}known_coverage'],
      )!,
    );
  }

  @override
  $SentencesTable createAlias(String alias) {
    return $SentencesTable(attachedDatabase, alias);
  }
}

class Sentence extends DataClass implements Insertable<Sentence> {
  final String id;
  final String languageId;
  final String cefrBand;
  final String content;
  final double knownCoverage;
  const Sentence({
    required this.id,
    required this.languageId,
    required this.cefrBand,
    required this.content,
    required this.knownCoverage,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['language_id'] = Variable<String>(languageId);
    map['cefr_band'] = Variable<String>(cefrBand);
    map['content'] = Variable<String>(content);
    map['known_coverage'] = Variable<double>(knownCoverage);
    return map;
  }

  SentencesCompanion toCompanion(bool nullToAbsent) {
    return SentencesCompanion(
      id: Value(id),
      languageId: Value(languageId),
      cefrBand: Value(cefrBand),
      content: Value(content),
      knownCoverage: Value(knownCoverage),
    );
  }

  factory Sentence.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Sentence(
      id: serializer.fromJson<String>(json['id']),
      languageId: serializer.fromJson<String>(json['languageId']),
      cefrBand: serializer.fromJson<String>(json['cefrBand']),
      content: serializer.fromJson<String>(json['content']),
      knownCoverage: serializer.fromJson<double>(json['knownCoverage']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'languageId': serializer.toJson<String>(languageId),
      'cefrBand': serializer.toJson<String>(cefrBand),
      'content': serializer.toJson<String>(content),
      'knownCoverage': serializer.toJson<double>(knownCoverage),
    };
  }

  Sentence copyWith({
    String? id,
    String? languageId,
    String? cefrBand,
    String? content,
    double? knownCoverage,
  }) => Sentence(
    id: id ?? this.id,
    languageId: languageId ?? this.languageId,
    cefrBand: cefrBand ?? this.cefrBand,
    content: content ?? this.content,
    knownCoverage: knownCoverage ?? this.knownCoverage,
  );
  Sentence copyWithCompanion(SentencesCompanion data) {
    return Sentence(
      id: data.id.present ? data.id.value : this.id,
      languageId: data.languageId.present
          ? data.languageId.value
          : this.languageId,
      cefrBand: data.cefrBand.present ? data.cefrBand.value : this.cefrBand,
      content: data.content.present ? data.content.value : this.content,
      knownCoverage: data.knownCoverage.present
          ? data.knownCoverage.value
          : this.knownCoverage,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Sentence(')
          ..write('id: $id, ')
          ..write('languageId: $languageId, ')
          ..write('cefrBand: $cefrBand, ')
          ..write('content: $content, ')
          ..write('knownCoverage: $knownCoverage')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, languageId, cefrBand, content, knownCoverage);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Sentence &&
          other.id == this.id &&
          other.languageId == this.languageId &&
          other.cefrBand == this.cefrBand &&
          other.content == this.content &&
          other.knownCoverage == this.knownCoverage);
}

class SentencesCompanion extends UpdateCompanion<Sentence> {
  final Value<String> id;
  final Value<String> languageId;
  final Value<String> cefrBand;
  final Value<String> content;
  final Value<double> knownCoverage;
  final Value<int> rowid;
  const SentencesCompanion({
    this.id = const Value.absent(),
    this.languageId = const Value.absent(),
    this.cefrBand = const Value.absent(),
    this.content = const Value.absent(),
    this.knownCoverage = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SentencesCompanion.insert({
    required String id,
    required String languageId,
    required String cefrBand,
    required String content,
    this.knownCoverage = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       languageId = Value(languageId),
       cefrBand = Value(cefrBand),
       content = Value(content);
  static Insertable<Sentence> custom({
    Expression<String>? id,
    Expression<String>? languageId,
    Expression<String>? cefrBand,
    Expression<String>? content,
    Expression<double>? knownCoverage,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (languageId != null) 'language_id': languageId,
      if (cefrBand != null) 'cefr_band': cefrBand,
      if (content != null) 'content': content,
      if (knownCoverage != null) 'known_coverage': knownCoverage,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SentencesCompanion copyWith({
    Value<String>? id,
    Value<String>? languageId,
    Value<String>? cefrBand,
    Value<String>? content,
    Value<double>? knownCoverage,
    Value<int>? rowid,
  }) {
    return SentencesCompanion(
      id: id ?? this.id,
      languageId: languageId ?? this.languageId,
      cefrBand: cefrBand ?? this.cefrBand,
      content: content ?? this.content,
      knownCoverage: knownCoverage ?? this.knownCoverage,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (languageId.present) {
      map['language_id'] = Variable<String>(languageId.value);
    }
    if (cefrBand.present) {
      map['cefr_band'] = Variable<String>(cefrBand.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (knownCoverage.present) {
      map['known_coverage'] = Variable<double>(knownCoverage.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SentencesCompanion(')
          ..write('id: $id, ')
          ..write('languageId: $languageId, ')
          ..write('cefrBand: $cefrBand, ')
          ..write('content: $content, ')
          ..write('knownCoverage: $knownCoverage, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LearnItemsTable extends LearnItems
    with TableInfo<$LearnItemsTable, LearnItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LearnItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _languageIdMeta = const VerificationMeta(
    'languageId',
  );
  @override
  late final GeneratedColumn<String> languageId = GeneratedColumn<String>(
    'language_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES languages (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _refTypeMeta = const VerificationMeta(
    'refType',
  );
  @override
  late final GeneratedColumn<String> refType = GeneratedColumn<String>(
    'ref_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _refIdMeta = const VerificationMeta('refId');
  @override
  late final GeneratedColumn<String> refId = GeneratedColumn<String>(
    'ref_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _masteryRungMeta = const VerificationMeta(
    'masteryRung',
  );
  @override
  late final GeneratedColumn<int> masteryRung = GeneratedColumn<int>(
    'mastery_rung',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _easeMeta = const VerificationMeta('ease');
  @override
  late final GeneratedColumn<double> ease = GeneratedColumn<double>(
    'ease',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(2.5),
  );
  static const VerificationMeta _intervalDaysMeta = const VerificationMeta(
    'intervalDays',
  );
  @override
  late final GeneratedColumn<int> intervalDays = GeneratedColumn<int>(
    'interval_days',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _dueAtMeta = const VerificationMeta('dueAt');
  @override
  late final GeneratedColumn<DateTime> dueAt = GeneratedColumn<DateTime>(
    'due_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
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
  static const VerificationMeta _consecutiveCorrectMeta =
      const VerificationMeta('consecutiveCorrect');
  @override
  late final GeneratedColumn<int> consecutiveCorrect = GeneratedColumn<int>(
    'consecutive_correct',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    languageId,
    refType,
    refId,
    masteryRung,
    ease,
    intervalDays,
    dueAt,
    reps,
    lapses,
    consecutiveCorrect,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'learn_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<LearnItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('language_id')) {
      context.handle(
        _languageIdMeta,
        languageId.isAcceptableOrUnknown(data['language_id']!, _languageIdMeta),
      );
    } else if (isInserting) {
      context.missing(_languageIdMeta);
    }
    if (data.containsKey('ref_type')) {
      context.handle(
        _refTypeMeta,
        refType.isAcceptableOrUnknown(data['ref_type']!, _refTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_refTypeMeta);
    }
    if (data.containsKey('ref_id')) {
      context.handle(
        _refIdMeta,
        refId.isAcceptableOrUnknown(data['ref_id']!, _refIdMeta),
      );
    } else if (isInserting) {
      context.missing(_refIdMeta);
    }
    if (data.containsKey('mastery_rung')) {
      context.handle(
        _masteryRungMeta,
        masteryRung.isAcceptableOrUnknown(
          data['mastery_rung']!,
          _masteryRungMeta,
        ),
      );
    }
    if (data.containsKey('ease')) {
      context.handle(
        _easeMeta,
        ease.isAcceptableOrUnknown(data['ease']!, _easeMeta),
      );
    }
    if (data.containsKey('interval_days')) {
      context.handle(
        _intervalDaysMeta,
        intervalDays.isAcceptableOrUnknown(
          data['interval_days']!,
          _intervalDaysMeta,
        ),
      );
    }
    if (data.containsKey('due_at')) {
      context.handle(
        _dueAtMeta,
        dueAt.isAcceptableOrUnknown(data['due_at']!, _dueAtMeta),
      );
    } else if (isInserting) {
      context.missing(_dueAtMeta);
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
    if (data.containsKey('consecutive_correct')) {
      context.handle(
        _consecutiveCorrectMeta,
        consecutiveCorrect.isAcceptableOrUnknown(
          data['consecutive_correct']!,
          _consecutiveCorrectMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {languageId, refType, refId},
  ];
  @override
  LearnItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LearnItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      languageId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}language_id'],
      )!,
      refType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ref_type'],
      )!,
      refId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ref_id'],
      )!,
      masteryRung: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}mastery_rung'],
      )!,
      ease: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}ease'],
      )!,
      intervalDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}interval_days'],
      )!,
      dueAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}due_at'],
      )!,
      reps: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reps'],
      )!,
      lapses: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}lapses'],
      )!,
      consecutiveCorrect: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}consecutive_correct'],
      )!,
    );
  }

  @override
  $LearnItemsTable createAlias(String alias) {
    return $LearnItemsTable(attachedDatabase, alias);
  }
}

class LearnItem extends DataClass implements Insertable<LearnItem> {
  final String id;
  final String languageId;
  final String refType;
  final String refId;
  final int masteryRung;
  final double ease;
  final int intervalDays;
  final DateTime dueAt;
  final int reps;
  final int lapses;
  final int consecutiveCorrect;
  const LearnItem({
    required this.id,
    required this.languageId,
    required this.refType,
    required this.refId,
    required this.masteryRung,
    required this.ease,
    required this.intervalDays,
    required this.dueAt,
    required this.reps,
    required this.lapses,
    required this.consecutiveCorrect,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['language_id'] = Variable<String>(languageId);
    map['ref_type'] = Variable<String>(refType);
    map['ref_id'] = Variable<String>(refId);
    map['mastery_rung'] = Variable<int>(masteryRung);
    map['ease'] = Variable<double>(ease);
    map['interval_days'] = Variable<int>(intervalDays);
    map['due_at'] = Variable<DateTime>(dueAt);
    map['reps'] = Variable<int>(reps);
    map['lapses'] = Variable<int>(lapses);
    map['consecutive_correct'] = Variable<int>(consecutiveCorrect);
    return map;
  }

  LearnItemsCompanion toCompanion(bool nullToAbsent) {
    return LearnItemsCompanion(
      id: Value(id),
      languageId: Value(languageId),
      refType: Value(refType),
      refId: Value(refId),
      masteryRung: Value(masteryRung),
      ease: Value(ease),
      intervalDays: Value(intervalDays),
      dueAt: Value(dueAt),
      reps: Value(reps),
      lapses: Value(lapses),
      consecutiveCorrect: Value(consecutiveCorrect),
    );
  }

  factory LearnItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LearnItem(
      id: serializer.fromJson<String>(json['id']),
      languageId: serializer.fromJson<String>(json['languageId']),
      refType: serializer.fromJson<String>(json['refType']),
      refId: serializer.fromJson<String>(json['refId']),
      masteryRung: serializer.fromJson<int>(json['masteryRung']),
      ease: serializer.fromJson<double>(json['ease']),
      intervalDays: serializer.fromJson<int>(json['intervalDays']),
      dueAt: serializer.fromJson<DateTime>(json['dueAt']),
      reps: serializer.fromJson<int>(json['reps']),
      lapses: serializer.fromJson<int>(json['lapses']),
      consecutiveCorrect: serializer.fromJson<int>(json['consecutiveCorrect']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'languageId': serializer.toJson<String>(languageId),
      'refType': serializer.toJson<String>(refType),
      'refId': serializer.toJson<String>(refId),
      'masteryRung': serializer.toJson<int>(masteryRung),
      'ease': serializer.toJson<double>(ease),
      'intervalDays': serializer.toJson<int>(intervalDays),
      'dueAt': serializer.toJson<DateTime>(dueAt),
      'reps': serializer.toJson<int>(reps),
      'lapses': serializer.toJson<int>(lapses),
      'consecutiveCorrect': serializer.toJson<int>(consecutiveCorrect),
    };
  }

  LearnItem copyWith({
    String? id,
    String? languageId,
    String? refType,
    String? refId,
    int? masteryRung,
    double? ease,
    int? intervalDays,
    DateTime? dueAt,
    int? reps,
    int? lapses,
    int? consecutiveCorrect,
  }) => LearnItem(
    id: id ?? this.id,
    languageId: languageId ?? this.languageId,
    refType: refType ?? this.refType,
    refId: refId ?? this.refId,
    masteryRung: masteryRung ?? this.masteryRung,
    ease: ease ?? this.ease,
    intervalDays: intervalDays ?? this.intervalDays,
    dueAt: dueAt ?? this.dueAt,
    reps: reps ?? this.reps,
    lapses: lapses ?? this.lapses,
    consecutiveCorrect: consecutiveCorrect ?? this.consecutiveCorrect,
  );
  LearnItem copyWithCompanion(LearnItemsCompanion data) {
    return LearnItem(
      id: data.id.present ? data.id.value : this.id,
      languageId: data.languageId.present
          ? data.languageId.value
          : this.languageId,
      refType: data.refType.present ? data.refType.value : this.refType,
      refId: data.refId.present ? data.refId.value : this.refId,
      masteryRung: data.masteryRung.present
          ? data.masteryRung.value
          : this.masteryRung,
      ease: data.ease.present ? data.ease.value : this.ease,
      intervalDays: data.intervalDays.present
          ? data.intervalDays.value
          : this.intervalDays,
      dueAt: data.dueAt.present ? data.dueAt.value : this.dueAt,
      reps: data.reps.present ? data.reps.value : this.reps,
      lapses: data.lapses.present ? data.lapses.value : this.lapses,
      consecutiveCorrect: data.consecutiveCorrect.present
          ? data.consecutiveCorrect.value
          : this.consecutiveCorrect,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LearnItem(')
          ..write('id: $id, ')
          ..write('languageId: $languageId, ')
          ..write('refType: $refType, ')
          ..write('refId: $refId, ')
          ..write('masteryRung: $masteryRung, ')
          ..write('ease: $ease, ')
          ..write('intervalDays: $intervalDays, ')
          ..write('dueAt: $dueAt, ')
          ..write('reps: $reps, ')
          ..write('lapses: $lapses, ')
          ..write('consecutiveCorrect: $consecutiveCorrect')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    languageId,
    refType,
    refId,
    masteryRung,
    ease,
    intervalDays,
    dueAt,
    reps,
    lapses,
    consecutiveCorrect,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LearnItem &&
          other.id == this.id &&
          other.languageId == this.languageId &&
          other.refType == this.refType &&
          other.refId == this.refId &&
          other.masteryRung == this.masteryRung &&
          other.ease == this.ease &&
          other.intervalDays == this.intervalDays &&
          other.dueAt == this.dueAt &&
          other.reps == this.reps &&
          other.lapses == this.lapses &&
          other.consecutiveCorrect == this.consecutiveCorrect);
}

class LearnItemsCompanion extends UpdateCompanion<LearnItem> {
  final Value<String> id;
  final Value<String> languageId;
  final Value<String> refType;
  final Value<String> refId;
  final Value<int> masteryRung;
  final Value<double> ease;
  final Value<int> intervalDays;
  final Value<DateTime> dueAt;
  final Value<int> reps;
  final Value<int> lapses;
  final Value<int> consecutiveCorrect;
  final Value<int> rowid;
  const LearnItemsCompanion({
    this.id = const Value.absent(),
    this.languageId = const Value.absent(),
    this.refType = const Value.absent(),
    this.refId = const Value.absent(),
    this.masteryRung = const Value.absent(),
    this.ease = const Value.absent(),
    this.intervalDays = const Value.absent(),
    this.dueAt = const Value.absent(),
    this.reps = const Value.absent(),
    this.lapses = const Value.absent(),
    this.consecutiveCorrect = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LearnItemsCompanion.insert({
    required String id,
    required String languageId,
    required String refType,
    required String refId,
    this.masteryRung = const Value.absent(),
    this.ease = const Value.absent(),
    this.intervalDays = const Value.absent(),
    required DateTime dueAt,
    this.reps = const Value.absent(),
    this.lapses = const Value.absent(),
    this.consecutiveCorrect = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       languageId = Value(languageId),
       refType = Value(refType),
       refId = Value(refId),
       dueAt = Value(dueAt);
  static Insertable<LearnItem> custom({
    Expression<String>? id,
    Expression<String>? languageId,
    Expression<String>? refType,
    Expression<String>? refId,
    Expression<int>? masteryRung,
    Expression<double>? ease,
    Expression<int>? intervalDays,
    Expression<DateTime>? dueAt,
    Expression<int>? reps,
    Expression<int>? lapses,
    Expression<int>? consecutiveCorrect,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (languageId != null) 'language_id': languageId,
      if (refType != null) 'ref_type': refType,
      if (refId != null) 'ref_id': refId,
      if (masteryRung != null) 'mastery_rung': masteryRung,
      if (ease != null) 'ease': ease,
      if (intervalDays != null) 'interval_days': intervalDays,
      if (dueAt != null) 'due_at': dueAt,
      if (reps != null) 'reps': reps,
      if (lapses != null) 'lapses': lapses,
      if (consecutiveCorrect != null) 'consecutive_correct': consecutiveCorrect,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LearnItemsCompanion copyWith({
    Value<String>? id,
    Value<String>? languageId,
    Value<String>? refType,
    Value<String>? refId,
    Value<int>? masteryRung,
    Value<double>? ease,
    Value<int>? intervalDays,
    Value<DateTime>? dueAt,
    Value<int>? reps,
    Value<int>? lapses,
    Value<int>? consecutiveCorrect,
    Value<int>? rowid,
  }) {
    return LearnItemsCompanion(
      id: id ?? this.id,
      languageId: languageId ?? this.languageId,
      refType: refType ?? this.refType,
      refId: refId ?? this.refId,
      masteryRung: masteryRung ?? this.masteryRung,
      ease: ease ?? this.ease,
      intervalDays: intervalDays ?? this.intervalDays,
      dueAt: dueAt ?? this.dueAt,
      reps: reps ?? this.reps,
      lapses: lapses ?? this.lapses,
      consecutiveCorrect: consecutiveCorrect ?? this.consecutiveCorrect,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (languageId.present) {
      map['language_id'] = Variable<String>(languageId.value);
    }
    if (refType.present) {
      map['ref_type'] = Variable<String>(refType.value);
    }
    if (refId.present) {
      map['ref_id'] = Variable<String>(refId.value);
    }
    if (masteryRung.present) {
      map['mastery_rung'] = Variable<int>(masteryRung.value);
    }
    if (ease.present) {
      map['ease'] = Variable<double>(ease.value);
    }
    if (intervalDays.present) {
      map['interval_days'] = Variable<int>(intervalDays.value);
    }
    if (dueAt.present) {
      map['due_at'] = Variable<DateTime>(dueAt.value);
    }
    if (reps.present) {
      map['reps'] = Variable<int>(reps.value);
    }
    if (lapses.present) {
      map['lapses'] = Variable<int>(lapses.value);
    }
    if (consecutiveCorrect.present) {
      map['consecutive_correct'] = Variable<int>(consecutiveCorrect.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LearnItemsCompanion(')
          ..write('id: $id, ')
          ..write('languageId: $languageId, ')
          ..write('refType: $refType, ')
          ..write('refId: $refId, ')
          ..write('masteryRung: $masteryRung, ')
          ..write('ease: $ease, ')
          ..write('intervalDays: $intervalDays, ')
          ..write('dueAt: $dueAt, ')
          ..write('reps: $reps, ')
          ..write('lapses: $lapses, ')
          ..write('consecutiveCorrect: $consecutiveCorrect, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ReviewLogTable extends ReviewLog
    with TableInfo<$ReviewLogTable, ReviewLogData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReviewLogTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _learnItemIdMeta = const VerificationMeta(
    'learnItemId',
  );
  @override
  late final GeneratedColumn<String> learnItemId = GeneratedColumn<String>(
    'learn_item_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES learn_items (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _rungMeta = const VerificationMeta('rung');
  @override
  late final GeneratedColumn<int> rung = GeneratedColumn<int>(
    'rung',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _resultMeta = const VerificationMeta('result');
  @override
  late final GeneratedColumn<String> result = GeneratedColumn<String>(
    'result',
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
  @override
  List<GeneratedColumn> get $columns => [id, learnItemId, rung, result, ts];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'review_log';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReviewLogData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('learn_item_id')) {
      context.handle(
        _learnItemIdMeta,
        learnItemId.isAcceptableOrUnknown(
          data['learn_item_id']!,
          _learnItemIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_learnItemIdMeta);
    }
    if (data.containsKey('rung')) {
      context.handle(
        _rungMeta,
        rung.isAcceptableOrUnknown(data['rung']!, _rungMeta),
      );
    } else if (isInserting) {
      context.missing(_rungMeta);
    }
    if (data.containsKey('result')) {
      context.handle(
        _resultMeta,
        result.isAcceptableOrUnknown(data['result']!, _resultMeta),
      );
    } else if (isInserting) {
      context.missing(_resultMeta);
    }
    if (data.containsKey('ts')) {
      context.handle(_tsMeta, ts.isAcceptableOrUnknown(data['ts']!, _tsMeta));
    } else if (isInserting) {
      context.missing(_tsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReviewLogData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReviewLogData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      learnItemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}learn_item_id'],
      )!,
      rung: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rung'],
      )!,
      result: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}result'],
      )!,
      ts: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}ts'],
      )!,
    );
  }

  @override
  $ReviewLogTable createAlias(String alias) {
    return $ReviewLogTable(attachedDatabase, alias);
  }
}

class ReviewLogData extends DataClass implements Insertable<ReviewLogData> {
  final String id;
  final String learnItemId;
  final int rung;
  final String result;
  final DateTime ts;
  const ReviewLogData({
    required this.id,
    required this.learnItemId,
    required this.rung,
    required this.result,
    required this.ts,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['learn_item_id'] = Variable<String>(learnItemId);
    map['rung'] = Variable<int>(rung);
    map['result'] = Variable<String>(result);
    map['ts'] = Variable<DateTime>(ts);
    return map;
  }

  ReviewLogCompanion toCompanion(bool nullToAbsent) {
    return ReviewLogCompanion(
      id: Value(id),
      learnItemId: Value(learnItemId),
      rung: Value(rung),
      result: Value(result),
      ts: Value(ts),
    );
  }

  factory ReviewLogData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReviewLogData(
      id: serializer.fromJson<String>(json['id']),
      learnItemId: serializer.fromJson<String>(json['learnItemId']),
      rung: serializer.fromJson<int>(json['rung']),
      result: serializer.fromJson<String>(json['result']),
      ts: serializer.fromJson<DateTime>(json['ts']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'learnItemId': serializer.toJson<String>(learnItemId),
      'rung': serializer.toJson<int>(rung),
      'result': serializer.toJson<String>(result),
      'ts': serializer.toJson<DateTime>(ts),
    };
  }

  ReviewLogData copyWith({
    String? id,
    String? learnItemId,
    int? rung,
    String? result,
    DateTime? ts,
  }) => ReviewLogData(
    id: id ?? this.id,
    learnItemId: learnItemId ?? this.learnItemId,
    rung: rung ?? this.rung,
    result: result ?? this.result,
    ts: ts ?? this.ts,
  );
  ReviewLogData copyWithCompanion(ReviewLogCompanion data) {
    return ReviewLogData(
      id: data.id.present ? data.id.value : this.id,
      learnItemId: data.learnItemId.present
          ? data.learnItemId.value
          : this.learnItemId,
      rung: data.rung.present ? data.rung.value : this.rung,
      result: data.result.present ? data.result.value : this.result,
      ts: data.ts.present ? data.ts.value : this.ts,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReviewLogData(')
          ..write('id: $id, ')
          ..write('learnItemId: $learnItemId, ')
          ..write('rung: $rung, ')
          ..write('result: $result, ')
          ..write('ts: $ts')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, learnItemId, rung, result, ts);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReviewLogData &&
          other.id == this.id &&
          other.learnItemId == this.learnItemId &&
          other.rung == this.rung &&
          other.result == this.result &&
          other.ts == this.ts);
}

class ReviewLogCompanion extends UpdateCompanion<ReviewLogData> {
  final Value<String> id;
  final Value<String> learnItemId;
  final Value<int> rung;
  final Value<String> result;
  final Value<DateTime> ts;
  final Value<int> rowid;
  const ReviewLogCompanion({
    this.id = const Value.absent(),
    this.learnItemId = const Value.absent(),
    this.rung = const Value.absent(),
    this.result = const Value.absent(),
    this.ts = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReviewLogCompanion.insert({
    required String id,
    required String learnItemId,
    required int rung,
    required String result,
    required DateTime ts,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       learnItemId = Value(learnItemId),
       rung = Value(rung),
       result = Value(result),
       ts = Value(ts);
  static Insertable<ReviewLogData> custom({
    Expression<String>? id,
    Expression<String>? learnItemId,
    Expression<int>? rung,
    Expression<String>? result,
    Expression<DateTime>? ts,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (learnItemId != null) 'learn_item_id': learnItemId,
      if (rung != null) 'rung': rung,
      if (result != null) 'result': result,
      if (ts != null) 'ts': ts,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReviewLogCompanion copyWith({
    Value<String>? id,
    Value<String>? learnItemId,
    Value<int>? rung,
    Value<String>? result,
    Value<DateTime>? ts,
    Value<int>? rowid,
  }) {
    return ReviewLogCompanion(
      id: id ?? this.id,
      learnItemId: learnItemId ?? this.learnItemId,
      rung: rung ?? this.rung,
      result: result ?? this.result,
      ts: ts ?? this.ts,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (learnItemId.present) {
      map['learn_item_id'] = Variable<String>(learnItemId.value);
    }
    if (rung.present) {
      map['rung'] = Variable<int>(rung.value);
    }
    if (result.present) {
      map['result'] = Variable<String>(result.value);
    }
    if (ts.present) {
      map['ts'] = Variable<DateTime>(ts.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReviewLogCompanion(')
          ..write('id: $id, ')
          ..write('learnItemId: $learnItemId, ')
          ..write('rung: $rung, ')
          ..write('result: $result, ')
          ..write('ts: $ts, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$LearningDb extends GeneratedDatabase {
  _$LearningDb(QueryExecutor e) : super(e);
  $LearningDbManager get managers => $LearningDbManager(this);
  late final $ConceptsTable concepts = $ConceptsTable(this);
  late final $AssetsTable assets = $AssetsTable(this);
  late final $ScriptProfilesTable scriptProfiles = $ScriptProfilesTable(this);
  late final $LanguagesTable languages = $LanguagesTable(this);
  late final $LexemesTable lexemes = $LexemesTable(this);
  late final $CharactersTable characters = $CharactersTable(this);
  late final $CharComponentsTable charComponents = $CharComponentsTable(this);
  late final $CanDoGoalsTable canDoGoals = $CanDoGoalsTable(this);
  late final $GrammarPointsTable grammarPoints = $GrammarPointsTable(this);
  late final $SentencesTable sentences = $SentencesTable(this);
  late final $LearnItemsTable learnItems = $LearnItemsTable(this);
  late final $ReviewLogTable reviewLog = $ReviewLogTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    concepts,
    assets,
    scriptProfiles,
    languages,
    lexemes,
    characters,
    charComponents,
    canDoGoals,
    grammarPoints,
    sentences,
    learnItems,
    reviewLog,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'concepts',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('assets', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'languages',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('lexemes', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'languages',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('characters', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'characters',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('char_components', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'languages',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('can_do_goals', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'languages',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('grammar_points', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'languages',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('sentences', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'languages',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('learn_items', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'learn_items',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('review_log', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$ConceptsTableCreateCompanionBuilder =
    ConceptsCompanion Function({
      required String id,
      required String glossKey,
      required String partOfSpeech,
      Value<String> defaultAssetType,
      Value<int> rowid,
    });
typedef $$ConceptsTableUpdateCompanionBuilder =
    ConceptsCompanion Function({
      Value<String> id,
      Value<String> glossKey,
      Value<String> partOfSpeech,
      Value<String> defaultAssetType,
      Value<int> rowid,
    });

final class $$ConceptsTableReferences
    extends BaseReferences<_$LearningDb, $ConceptsTable, Concept> {
  $$ConceptsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$AssetsTable, List<Asset>> _assetsRefsTable(
    _$LearningDb db,
  ) => MultiTypedResultKey.fromTable(
    db.assets,
    aliasName: $_aliasNameGenerator(db.concepts.id, db.assets.conceptId),
  );

  $$AssetsTableProcessedTableManager get assetsRefs {
    final manager = $$AssetsTableTableManager(
      $_db,
      $_db.assets,
    ).filter((f) => f.conceptId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_assetsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$LexemesTable, List<Lexeme>> _lexemesRefsTable(
    _$LearningDb db,
  ) => MultiTypedResultKey.fromTable(
    db.lexemes,
    aliasName: $_aliasNameGenerator(db.concepts.id, db.lexemes.conceptId),
  );

  $$LexemesTableProcessedTableManager get lexemesRefs {
    final manager = $$LexemesTableTableManager(
      $_db,
      $_db.lexemes,
    ).filter((f) => f.conceptId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_lexemesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ConceptsTableFilterComposer
    extends Composer<_$LearningDb, $ConceptsTable> {
  $$ConceptsTableFilterComposer({
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

  ColumnFilters<String> get glossKey => $composableBuilder(
    column: $table.glossKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get partOfSpeech => $composableBuilder(
    column: $table.partOfSpeech,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get defaultAssetType => $composableBuilder(
    column: $table.defaultAssetType,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> assetsRefs(
    Expression<bool> Function($$AssetsTableFilterComposer f) f,
  ) {
    final $$AssetsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.assets,
      getReferencedColumn: (t) => t.conceptId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AssetsTableFilterComposer(
            $db: $db,
            $table: $db.assets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> lexemesRefs(
    Expression<bool> Function($$LexemesTableFilterComposer f) f,
  ) {
    final $$LexemesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.lexemes,
      getReferencedColumn: (t) => t.conceptId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LexemesTableFilterComposer(
            $db: $db,
            $table: $db.lexemes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ConceptsTableOrderingComposer
    extends Composer<_$LearningDb, $ConceptsTable> {
  $$ConceptsTableOrderingComposer({
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

  ColumnOrderings<String> get glossKey => $composableBuilder(
    column: $table.glossKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get partOfSpeech => $composableBuilder(
    column: $table.partOfSpeech,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get defaultAssetType => $composableBuilder(
    column: $table.defaultAssetType,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ConceptsTableAnnotationComposer
    extends Composer<_$LearningDb, $ConceptsTable> {
  $$ConceptsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get glossKey =>
      $composableBuilder(column: $table.glossKey, builder: (column) => column);

  GeneratedColumn<String> get partOfSpeech => $composableBuilder(
    column: $table.partOfSpeech,
    builder: (column) => column,
  );

  GeneratedColumn<String> get defaultAssetType => $composableBuilder(
    column: $table.defaultAssetType,
    builder: (column) => column,
  );

  Expression<T> assetsRefs<T extends Object>(
    Expression<T> Function($$AssetsTableAnnotationComposer a) f,
  ) {
    final $$AssetsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.assets,
      getReferencedColumn: (t) => t.conceptId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AssetsTableAnnotationComposer(
            $db: $db,
            $table: $db.assets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> lexemesRefs<T extends Object>(
    Expression<T> Function($$LexemesTableAnnotationComposer a) f,
  ) {
    final $$LexemesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.lexemes,
      getReferencedColumn: (t) => t.conceptId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LexemesTableAnnotationComposer(
            $db: $db,
            $table: $db.lexemes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ConceptsTableTableManager
    extends
        RootTableManager<
          _$LearningDb,
          $ConceptsTable,
          Concept,
          $$ConceptsTableFilterComposer,
          $$ConceptsTableOrderingComposer,
          $$ConceptsTableAnnotationComposer,
          $$ConceptsTableCreateCompanionBuilder,
          $$ConceptsTableUpdateCompanionBuilder,
          (Concept, $$ConceptsTableReferences),
          Concept,
          PrefetchHooks Function({bool assetsRefs, bool lexemesRefs})
        > {
  $$ConceptsTableTableManager(_$LearningDb db, $ConceptsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ConceptsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ConceptsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ConceptsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> glossKey = const Value.absent(),
                Value<String> partOfSpeech = const Value.absent(),
                Value<String> defaultAssetType = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ConceptsCompanion(
                id: id,
                glossKey: glossKey,
                partOfSpeech: partOfSpeech,
                defaultAssetType: defaultAssetType,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String glossKey,
                required String partOfSpeech,
                Value<String> defaultAssetType = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ConceptsCompanion.insert(
                id: id,
                glossKey: glossKey,
                partOfSpeech: partOfSpeech,
                defaultAssetType: defaultAssetType,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ConceptsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({assetsRefs = false, lexemesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (assetsRefs) db.assets,
                if (lexemesRefs) db.lexemes,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (assetsRefs)
                    await $_getPrefetchedData<Concept, $ConceptsTable, Asset>(
                      currentTable: table,
                      referencedTable: $$ConceptsTableReferences
                          ._assetsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$ConceptsTableReferences(db, table, p0).assetsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.conceptId == item.id),
                      typedResults: items,
                    ),
                  if (lexemesRefs)
                    await $_getPrefetchedData<Concept, $ConceptsTable, Lexeme>(
                      currentTable: table,
                      referencedTable: $$ConceptsTableReferences
                          ._lexemesRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$ConceptsTableReferences(db, table, p0).lexemesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.conceptId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$ConceptsTableProcessedTableManager =
    ProcessedTableManager<
      _$LearningDb,
      $ConceptsTable,
      Concept,
      $$ConceptsTableFilterComposer,
      $$ConceptsTableOrderingComposer,
      $$ConceptsTableAnnotationComposer,
      $$ConceptsTableCreateCompanionBuilder,
      $$ConceptsTableUpdateCompanionBuilder,
      (Concept, $$ConceptsTableReferences),
      Concept,
      PrefetchHooks Function({bool assetsRefs, bool lexemesRefs})
    >;
typedef $$AssetsTableCreateCompanionBuilder =
    AssetsCompanion Function({
      required String id,
      required String conceptId,
      required String type,
      required String path,
      Value<int> rowid,
    });
typedef $$AssetsTableUpdateCompanionBuilder =
    AssetsCompanion Function({
      Value<String> id,
      Value<String> conceptId,
      Value<String> type,
      Value<String> path,
      Value<int> rowid,
    });

final class $$AssetsTableReferences
    extends BaseReferences<_$LearningDb, $AssetsTable, Asset> {
  $$AssetsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ConceptsTable _conceptIdTable(_$LearningDb db) => db.concepts
      .createAlias($_aliasNameGenerator(db.assets.conceptId, db.concepts.id));

  $$ConceptsTableProcessedTableManager get conceptId {
    final $_column = $_itemColumn<String>('concept_id')!;

    final manager = $$ConceptsTableTableManager(
      $_db,
      $_db.concepts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_conceptIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$AssetsTableFilterComposer extends Composer<_$LearningDb, $AssetsTable> {
  $$AssetsTableFilterComposer({
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

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnFilters(column),
  );

  $$ConceptsTableFilterComposer get conceptId {
    final $$ConceptsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.conceptId,
      referencedTable: $db.concepts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ConceptsTableFilterComposer(
            $db: $db,
            $table: $db.concepts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AssetsTableOrderingComposer
    extends Composer<_$LearningDb, $AssetsTable> {
  $$AssetsTableOrderingComposer({
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

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnOrderings(column),
  );

  $$ConceptsTableOrderingComposer get conceptId {
    final $$ConceptsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.conceptId,
      referencedTable: $db.concepts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ConceptsTableOrderingComposer(
            $db: $db,
            $table: $db.concepts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AssetsTableAnnotationComposer
    extends Composer<_$LearningDb, $AssetsTable> {
  $$AssetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get path =>
      $composableBuilder(column: $table.path, builder: (column) => column);

  $$ConceptsTableAnnotationComposer get conceptId {
    final $$ConceptsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.conceptId,
      referencedTable: $db.concepts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ConceptsTableAnnotationComposer(
            $db: $db,
            $table: $db.concepts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AssetsTableTableManager
    extends
        RootTableManager<
          _$LearningDb,
          $AssetsTable,
          Asset,
          $$AssetsTableFilterComposer,
          $$AssetsTableOrderingComposer,
          $$AssetsTableAnnotationComposer,
          $$AssetsTableCreateCompanionBuilder,
          $$AssetsTableUpdateCompanionBuilder,
          (Asset, $$AssetsTableReferences),
          Asset,
          PrefetchHooks Function({bool conceptId})
        > {
  $$AssetsTableTableManager(_$LearningDb db, $AssetsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AssetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AssetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AssetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> conceptId = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> path = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AssetsCompanion(
                id: id,
                conceptId: conceptId,
                type: type,
                path: path,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String conceptId,
                required String type,
                required String path,
                Value<int> rowid = const Value.absent(),
              }) => AssetsCompanion.insert(
                id: id,
                conceptId: conceptId,
                type: type,
                path: path,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$AssetsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({conceptId = false}) {
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
                    if (conceptId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.conceptId,
                                referencedTable: $$AssetsTableReferences
                                    ._conceptIdTable(db),
                                referencedColumn: $$AssetsTableReferences
                                    ._conceptIdTable(db)
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

typedef $$AssetsTableProcessedTableManager =
    ProcessedTableManager<
      _$LearningDb,
      $AssetsTable,
      Asset,
      $$AssetsTableFilterComposer,
      $$AssetsTableOrderingComposer,
      $$AssetsTableAnnotationComposer,
      $$AssetsTableCreateCompanionBuilder,
      $$AssetsTableUpdateCompanionBuilder,
      (Asset, $$AssetsTableReferences),
      Asset,
      PrefetchHooks Function({bool conceptId})
    >;
typedef $$ScriptProfilesTableCreateCompanionBuilder =
    ScriptProfilesCompanion Function({
      required String id,
      required String scriptType,
      Value<String> direction,
      required String decomposability,
      Value<bool> positionalForms,
      Value<String> toneSystem,
      Value<bool> needsScriptTrack,
      Value<String> transliteration,
      Value<String> inputMethodsJson,
      Value<int> rowid,
    });
typedef $$ScriptProfilesTableUpdateCompanionBuilder =
    ScriptProfilesCompanion Function({
      Value<String> id,
      Value<String> scriptType,
      Value<String> direction,
      Value<String> decomposability,
      Value<bool> positionalForms,
      Value<String> toneSystem,
      Value<bool> needsScriptTrack,
      Value<String> transliteration,
      Value<String> inputMethodsJson,
      Value<int> rowid,
    });

final class $$ScriptProfilesTableReferences
    extends
        BaseReferences<_$LearningDb, $ScriptProfilesTable, ScriptProfileRow> {
  $$ScriptProfilesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$LanguagesTable, List<Language>>
  _languagesRefsTable(_$LearningDb db) => MultiTypedResultKey.fromTable(
    db.languages,
    aliasName: $_aliasNameGenerator(
      db.scriptProfiles.id,
      db.languages.scriptProfileId,
    ),
  );

  $$LanguagesTableProcessedTableManager get languagesRefs {
    final manager = $$LanguagesTableTableManager($_db, $_db.languages).filter(
      (f) => f.scriptProfileId.id.sqlEquals($_itemColumn<String>('id')!),
    );

    final cache = $_typedResult.readTableOrNull(_languagesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ScriptProfilesTableFilterComposer
    extends Composer<_$LearningDb, $ScriptProfilesTable> {
  $$ScriptProfilesTableFilterComposer({
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

  ColumnFilters<String> get scriptType => $composableBuilder(
    column: $table.scriptType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get direction => $composableBuilder(
    column: $table.direction,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get decomposability => $composableBuilder(
    column: $table.decomposability,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get positionalForms => $composableBuilder(
    column: $table.positionalForms,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get toneSystem => $composableBuilder(
    column: $table.toneSystem,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get needsScriptTrack => $composableBuilder(
    column: $table.needsScriptTrack,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get transliteration => $composableBuilder(
    column: $table.transliteration,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get inputMethodsJson => $composableBuilder(
    column: $table.inputMethodsJson,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> languagesRefs(
    Expression<bool> Function($$LanguagesTableFilterComposer f) f,
  ) {
    final $$LanguagesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.languages,
      getReferencedColumn: (t) => t.scriptProfileId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LanguagesTableFilterComposer(
            $db: $db,
            $table: $db.languages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ScriptProfilesTableOrderingComposer
    extends Composer<_$LearningDb, $ScriptProfilesTable> {
  $$ScriptProfilesTableOrderingComposer({
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

  ColumnOrderings<String> get scriptType => $composableBuilder(
    column: $table.scriptType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get direction => $composableBuilder(
    column: $table.direction,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get decomposability => $composableBuilder(
    column: $table.decomposability,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get positionalForms => $composableBuilder(
    column: $table.positionalForms,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get toneSystem => $composableBuilder(
    column: $table.toneSystem,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get needsScriptTrack => $composableBuilder(
    column: $table.needsScriptTrack,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get transliteration => $composableBuilder(
    column: $table.transliteration,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get inputMethodsJson => $composableBuilder(
    column: $table.inputMethodsJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ScriptProfilesTableAnnotationComposer
    extends Composer<_$LearningDb, $ScriptProfilesTable> {
  $$ScriptProfilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get scriptType => $composableBuilder(
    column: $table.scriptType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get direction =>
      $composableBuilder(column: $table.direction, builder: (column) => column);

  GeneratedColumn<String> get decomposability => $composableBuilder(
    column: $table.decomposability,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get positionalForms => $composableBuilder(
    column: $table.positionalForms,
    builder: (column) => column,
  );

  GeneratedColumn<String> get toneSystem => $composableBuilder(
    column: $table.toneSystem,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get needsScriptTrack => $composableBuilder(
    column: $table.needsScriptTrack,
    builder: (column) => column,
  );

  GeneratedColumn<String> get transliteration => $composableBuilder(
    column: $table.transliteration,
    builder: (column) => column,
  );

  GeneratedColumn<String> get inputMethodsJson => $composableBuilder(
    column: $table.inputMethodsJson,
    builder: (column) => column,
  );

  Expression<T> languagesRefs<T extends Object>(
    Expression<T> Function($$LanguagesTableAnnotationComposer a) f,
  ) {
    final $$LanguagesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.languages,
      getReferencedColumn: (t) => t.scriptProfileId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LanguagesTableAnnotationComposer(
            $db: $db,
            $table: $db.languages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ScriptProfilesTableTableManager
    extends
        RootTableManager<
          _$LearningDb,
          $ScriptProfilesTable,
          ScriptProfileRow,
          $$ScriptProfilesTableFilterComposer,
          $$ScriptProfilesTableOrderingComposer,
          $$ScriptProfilesTableAnnotationComposer,
          $$ScriptProfilesTableCreateCompanionBuilder,
          $$ScriptProfilesTableUpdateCompanionBuilder,
          (ScriptProfileRow, $$ScriptProfilesTableReferences),
          ScriptProfileRow,
          PrefetchHooks Function({bool languagesRefs})
        > {
  $$ScriptProfilesTableTableManager(_$LearningDb db, $ScriptProfilesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ScriptProfilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ScriptProfilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ScriptProfilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> scriptType = const Value.absent(),
                Value<String> direction = const Value.absent(),
                Value<String> decomposability = const Value.absent(),
                Value<bool> positionalForms = const Value.absent(),
                Value<String> toneSystem = const Value.absent(),
                Value<bool> needsScriptTrack = const Value.absent(),
                Value<String> transliteration = const Value.absent(),
                Value<String> inputMethodsJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ScriptProfilesCompanion(
                id: id,
                scriptType: scriptType,
                direction: direction,
                decomposability: decomposability,
                positionalForms: positionalForms,
                toneSystem: toneSystem,
                needsScriptTrack: needsScriptTrack,
                transliteration: transliteration,
                inputMethodsJson: inputMethodsJson,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String scriptType,
                Value<String> direction = const Value.absent(),
                required String decomposability,
                Value<bool> positionalForms = const Value.absent(),
                Value<String> toneSystem = const Value.absent(),
                Value<bool> needsScriptTrack = const Value.absent(),
                Value<String> transliteration = const Value.absent(),
                Value<String> inputMethodsJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ScriptProfilesCompanion.insert(
                id: id,
                scriptType: scriptType,
                direction: direction,
                decomposability: decomposability,
                positionalForms: positionalForms,
                toneSystem: toneSystem,
                needsScriptTrack: needsScriptTrack,
                transliteration: transliteration,
                inputMethodsJson: inputMethodsJson,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ScriptProfilesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({languagesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (languagesRefs) db.languages],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (languagesRefs)
                    await $_getPrefetchedData<
                      ScriptProfileRow,
                      $ScriptProfilesTable,
                      Language
                    >(
                      currentTable: table,
                      referencedTable: $$ScriptProfilesTableReferences
                          ._languagesRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$ScriptProfilesTableReferences(
                            db,
                            table,
                            p0,
                          ).languagesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.scriptProfileId == item.id,
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

typedef $$ScriptProfilesTableProcessedTableManager =
    ProcessedTableManager<
      _$LearningDb,
      $ScriptProfilesTable,
      ScriptProfileRow,
      $$ScriptProfilesTableFilterComposer,
      $$ScriptProfilesTableOrderingComposer,
      $$ScriptProfilesTableAnnotationComposer,
      $$ScriptProfilesTableCreateCompanionBuilder,
      $$ScriptProfilesTableUpdateCompanionBuilder,
      (ScriptProfileRow, $$ScriptProfilesTableReferences),
      ScriptProfileRow,
      PrefetchHooks Function({bool languagesRefs})
    >;
typedef $$LanguagesTableCreateCompanionBuilder =
    LanguagesCompanion Function({
      required String id,
      required String name,
      required String scriptProfileId,
      required String ttsVoice,
      Value<bool> enabled,
      Value<int> rowid,
    });
typedef $$LanguagesTableUpdateCompanionBuilder =
    LanguagesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> scriptProfileId,
      Value<String> ttsVoice,
      Value<bool> enabled,
      Value<int> rowid,
    });

final class $$LanguagesTableReferences
    extends BaseReferences<_$LearningDb, $LanguagesTable, Language> {
  $$LanguagesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ScriptProfilesTable _scriptProfileIdTable(_$LearningDb db) =>
      db.scriptProfiles.createAlias(
        $_aliasNameGenerator(
          db.languages.scriptProfileId,
          db.scriptProfiles.id,
        ),
      );

  $$ScriptProfilesTableProcessedTableManager get scriptProfileId {
    final $_column = $_itemColumn<String>('script_profile_id')!;

    final manager = $$ScriptProfilesTableTableManager(
      $_db,
      $_db.scriptProfiles,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_scriptProfileIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$LexemesTable, List<Lexeme>> _lexemesRefsTable(
    _$LearningDb db,
  ) => MultiTypedResultKey.fromTable(
    db.lexemes,
    aliasName: $_aliasNameGenerator(db.languages.id, db.lexemes.languageId),
  );

  $$LexemesTableProcessedTableManager get lexemesRefs {
    final manager = $$LexemesTableTableManager(
      $_db,
      $_db.lexemes,
    ).filter((f) => f.languageId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_lexemesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$CharactersTable, List<Character>>
  _charactersRefsTable(_$LearningDb db) => MultiTypedResultKey.fromTable(
    db.characters,
    aliasName: $_aliasNameGenerator(db.languages.id, db.characters.languageId),
  );

  $$CharactersTableProcessedTableManager get charactersRefs {
    final manager = $$CharactersTableTableManager(
      $_db,
      $_db.characters,
    ).filter((f) => f.languageId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_charactersRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$CanDoGoalsTable, List<CanDoGoal>>
  _canDoGoalsRefsTable(_$LearningDb db) => MultiTypedResultKey.fromTable(
    db.canDoGoals,
    aliasName: $_aliasNameGenerator(db.languages.id, db.canDoGoals.languageId),
  );

  $$CanDoGoalsTableProcessedTableManager get canDoGoalsRefs {
    final manager = $$CanDoGoalsTableTableManager(
      $_db,
      $_db.canDoGoals,
    ).filter((f) => f.languageId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_canDoGoalsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$GrammarPointsTable, List<GrammarPoint>>
  _grammarPointsRefsTable(_$LearningDb db) => MultiTypedResultKey.fromTable(
    db.grammarPoints,
    aliasName: $_aliasNameGenerator(
      db.languages.id,
      db.grammarPoints.languageId,
    ),
  );

  $$GrammarPointsTableProcessedTableManager get grammarPointsRefs {
    final manager = $$GrammarPointsTableTableManager(
      $_db,
      $_db.grammarPoints,
    ).filter((f) => f.languageId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_grammarPointsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$SentencesTable, List<Sentence>>
  _sentencesRefsTable(_$LearningDb db) => MultiTypedResultKey.fromTable(
    db.sentences,
    aliasName: $_aliasNameGenerator(db.languages.id, db.sentences.languageId),
  );

  $$SentencesTableProcessedTableManager get sentencesRefs {
    final manager = $$SentencesTableTableManager(
      $_db,
      $_db.sentences,
    ).filter((f) => f.languageId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_sentencesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$LearnItemsTable, List<LearnItem>>
  _learnItemsRefsTable(_$LearningDb db) => MultiTypedResultKey.fromTable(
    db.learnItems,
    aliasName: $_aliasNameGenerator(db.languages.id, db.learnItems.languageId),
  );

  $$LearnItemsTableProcessedTableManager get learnItemsRefs {
    final manager = $$LearnItemsTableTableManager(
      $_db,
      $_db.learnItems,
    ).filter((f) => f.languageId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_learnItemsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$LanguagesTableFilterComposer
    extends Composer<_$LearningDb, $LanguagesTable> {
  $$LanguagesTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ttsVoice => $composableBuilder(
    column: $table.ttsVoice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnFilters(column),
  );

  $$ScriptProfilesTableFilterComposer get scriptProfileId {
    final $$ScriptProfilesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.scriptProfileId,
      referencedTable: $db.scriptProfiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScriptProfilesTableFilterComposer(
            $db: $db,
            $table: $db.scriptProfiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> lexemesRefs(
    Expression<bool> Function($$LexemesTableFilterComposer f) f,
  ) {
    final $$LexemesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.lexemes,
      getReferencedColumn: (t) => t.languageId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LexemesTableFilterComposer(
            $db: $db,
            $table: $db.lexemes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> charactersRefs(
    Expression<bool> Function($$CharactersTableFilterComposer f) f,
  ) {
    final $$CharactersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.characters,
      getReferencedColumn: (t) => t.languageId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CharactersTableFilterComposer(
            $db: $db,
            $table: $db.characters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> canDoGoalsRefs(
    Expression<bool> Function($$CanDoGoalsTableFilterComposer f) f,
  ) {
    final $$CanDoGoalsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.canDoGoals,
      getReferencedColumn: (t) => t.languageId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CanDoGoalsTableFilterComposer(
            $db: $db,
            $table: $db.canDoGoals,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> grammarPointsRefs(
    Expression<bool> Function($$GrammarPointsTableFilterComposer f) f,
  ) {
    final $$GrammarPointsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.grammarPoints,
      getReferencedColumn: (t) => t.languageId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GrammarPointsTableFilterComposer(
            $db: $db,
            $table: $db.grammarPoints,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> sentencesRefs(
    Expression<bool> Function($$SentencesTableFilterComposer f) f,
  ) {
    final $$SentencesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.sentences,
      getReferencedColumn: (t) => t.languageId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SentencesTableFilterComposer(
            $db: $db,
            $table: $db.sentences,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> learnItemsRefs(
    Expression<bool> Function($$LearnItemsTableFilterComposer f) f,
  ) {
    final $$LearnItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.learnItems,
      getReferencedColumn: (t) => t.languageId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LearnItemsTableFilterComposer(
            $db: $db,
            $table: $db.learnItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$LanguagesTableOrderingComposer
    extends Composer<_$LearningDb, $LanguagesTable> {
  $$LanguagesTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ttsVoice => $composableBuilder(
    column: $table.ttsVoice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnOrderings(column),
  );

  $$ScriptProfilesTableOrderingComposer get scriptProfileId {
    final $$ScriptProfilesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.scriptProfileId,
      referencedTable: $db.scriptProfiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScriptProfilesTableOrderingComposer(
            $db: $db,
            $table: $db.scriptProfiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LanguagesTableAnnotationComposer
    extends Composer<_$LearningDb, $LanguagesTable> {
  $$LanguagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get ttsVoice =>
      $composableBuilder(column: $table.ttsVoice, builder: (column) => column);

  GeneratedColumn<bool> get enabled =>
      $composableBuilder(column: $table.enabled, builder: (column) => column);

  $$ScriptProfilesTableAnnotationComposer get scriptProfileId {
    final $$ScriptProfilesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.scriptProfileId,
      referencedTable: $db.scriptProfiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScriptProfilesTableAnnotationComposer(
            $db: $db,
            $table: $db.scriptProfiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> lexemesRefs<T extends Object>(
    Expression<T> Function($$LexemesTableAnnotationComposer a) f,
  ) {
    final $$LexemesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.lexemes,
      getReferencedColumn: (t) => t.languageId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LexemesTableAnnotationComposer(
            $db: $db,
            $table: $db.lexemes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> charactersRefs<T extends Object>(
    Expression<T> Function($$CharactersTableAnnotationComposer a) f,
  ) {
    final $$CharactersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.characters,
      getReferencedColumn: (t) => t.languageId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CharactersTableAnnotationComposer(
            $db: $db,
            $table: $db.characters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> canDoGoalsRefs<T extends Object>(
    Expression<T> Function($$CanDoGoalsTableAnnotationComposer a) f,
  ) {
    final $$CanDoGoalsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.canDoGoals,
      getReferencedColumn: (t) => t.languageId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CanDoGoalsTableAnnotationComposer(
            $db: $db,
            $table: $db.canDoGoals,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> grammarPointsRefs<T extends Object>(
    Expression<T> Function($$GrammarPointsTableAnnotationComposer a) f,
  ) {
    final $$GrammarPointsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.grammarPoints,
      getReferencedColumn: (t) => t.languageId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GrammarPointsTableAnnotationComposer(
            $db: $db,
            $table: $db.grammarPoints,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> sentencesRefs<T extends Object>(
    Expression<T> Function($$SentencesTableAnnotationComposer a) f,
  ) {
    final $$SentencesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.sentences,
      getReferencedColumn: (t) => t.languageId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SentencesTableAnnotationComposer(
            $db: $db,
            $table: $db.sentences,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> learnItemsRefs<T extends Object>(
    Expression<T> Function($$LearnItemsTableAnnotationComposer a) f,
  ) {
    final $$LearnItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.learnItems,
      getReferencedColumn: (t) => t.languageId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LearnItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.learnItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$LanguagesTableTableManager
    extends
        RootTableManager<
          _$LearningDb,
          $LanguagesTable,
          Language,
          $$LanguagesTableFilterComposer,
          $$LanguagesTableOrderingComposer,
          $$LanguagesTableAnnotationComposer,
          $$LanguagesTableCreateCompanionBuilder,
          $$LanguagesTableUpdateCompanionBuilder,
          (Language, $$LanguagesTableReferences),
          Language,
          PrefetchHooks Function({
            bool scriptProfileId,
            bool lexemesRefs,
            bool charactersRefs,
            bool canDoGoalsRefs,
            bool grammarPointsRefs,
            bool sentencesRefs,
            bool learnItemsRefs,
          })
        > {
  $$LanguagesTableTableManager(_$LearningDb db, $LanguagesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LanguagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LanguagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LanguagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> scriptProfileId = const Value.absent(),
                Value<String> ttsVoice = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LanguagesCompanion(
                id: id,
                name: name,
                scriptProfileId: scriptProfileId,
                ttsVoice: ttsVoice,
                enabled: enabled,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String scriptProfileId,
                required String ttsVoice,
                Value<bool> enabled = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LanguagesCompanion.insert(
                id: id,
                name: name,
                scriptProfileId: scriptProfileId,
                ttsVoice: ttsVoice,
                enabled: enabled,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$LanguagesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                scriptProfileId = false,
                lexemesRefs = false,
                charactersRefs = false,
                canDoGoalsRefs = false,
                grammarPointsRefs = false,
                sentencesRefs = false,
                learnItemsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (lexemesRefs) db.lexemes,
                    if (charactersRefs) db.characters,
                    if (canDoGoalsRefs) db.canDoGoals,
                    if (grammarPointsRefs) db.grammarPoints,
                    if (sentencesRefs) db.sentences,
                    if (learnItemsRefs) db.learnItems,
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
                        if (scriptProfileId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.scriptProfileId,
                                    referencedTable: $$LanguagesTableReferences
                                        ._scriptProfileIdTable(db),
                                    referencedColumn: $$LanguagesTableReferences
                                        ._scriptProfileIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (lexemesRefs)
                        await $_getPrefetchedData<
                          Language,
                          $LanguagesTable,
                          Lexeme
                        >(
                          currentTable: table,
                          referencedTable: $$LanguagesTableReferences
                              ._lexemesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$LanguagesTableReferences(
                                db,
                                table,
                                p0,
                              ).lexemesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.languageId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (charactersRefs)
                        await $_getPrefetchedData<
                          Language,
                          $LanguagesTable,
                          Character
                        >(
                          currentTable: table,
                          referencedTable: $$LanguagesTableReferences
                              ._charactersRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$LanguagesTableReferences(
                                db,
                                table,
                                p0,
                              ).charactersRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.languageId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (canDoGoalsRefs)
                        await $_getPrefetchedData<
                          Language,
                          $LanguagesTable,
                          CanDoGoal
                        >(
                          currentTable: table,
                          referencedTable: $$LanguagesTableReferences
                              ._canDoGoalsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$LanguagesTableReferences(
                                db,
                                table,
                                p0,
                              ).canDoGoalsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.languageId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (grammarPointsRefs)
                        await $_getPrefetchedData<
                          Language,
                          $LanguagesTable,
                          GrammarPoint
                        >(
                          currentTable: table,
                          referencedTable: $$LanguagesTableReferences
                              ._grammarPointsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$LanguagesTableReferences(
                                db,
                                table,
                                p0,
                              ).grammarPointsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.languageId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (sentencesRefs)
                        await $_getPrefetchedData<
                          Language,
                          $LanguagesTable,
                          Sentence
                        >(
                          currentTable: table,
                          referencedTable: $$LanguagesTableReferences
                              ._sentencesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$LanguagesTableReferences(
                                db,
                                table,
                                p0,
                              ).sentencesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.languageId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (learnItemsRefs)
                        await $_getPrefetchedData<
                          Language,
                          $LanguagesTable,
                          LearnItem
                        >(
                          currentTable: table,
                          referencedTable: $$LanguagesTableReferences
                              ._learnItemsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$LanguagesTableReferences(
                                db,
                                table,
                                p0,
                              ).learnItemsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.languageId == item.id,
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

typedef $$LanguagesTableProcessedTableManager =
    ProcessedTableManager<
      _$LearningDb,
      $LanguagesTable,
      Language,
      $$LanguagesTableFilterComposer,
      $$LanguagesTableOrderingComposer,
      $$LanguagesTableAnnotationComposer,
      $$LanguagesTableCreateCompanionBuilder,
      $$LanguagesTableUpdateCompanionBuilder,
      (Language, $$LanguagesTableReferences),
      Language,
      PrefetchHooks Function({
        bool scriptProfileId,
        bool lexemesRefs,
        bool charactersRefs,
        bool canDoGoalsRefs,
        bool grammarPointsRefs,
        bool sentencesRefs,
        bool learnItemsRefs,
      })
    >;
typedef $$LexemesTableCreateCompanionBuilder =
    LexemesCompanion Function({
      required String id,
      required String languageId,
      required String conceptId,
      required String writtenForm,
      required String reading,
      Value<String?> audioPath,
      Value<String> cefrBand,
      Value<int> rowid,
    });
typedef $$LexemesTableUpdateCompanionBuilder =
    LexemesCompanion Function({
      Value<String> id,
      Value<String> languageId,
      Value<String> conceptId,
      Value<String> writtenForm,
      Value<String> reading,
      Value<String?> audioPath,
      Value<String> cefrBand,
      Value<int> rowid,
    });

final class $$LexemesTableReferences
    extends BaseReferences<_$LearningDb, $LexemesTable, Lexeme> {
  $$LexemesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $LanguagesTable _languageIdTable(_$LearningDb db) =>
      db.languages.createAlias(
        $_aliasNameGenerator(db.lexemes.languageId, db.languages.id),
      );

  $$LanguagesTableProcessedTableManager get languageId {
    final $_column = $_itemColumn<String>('language_id')!;

    final manager = $$LanguagesTableTableManager(
      $_db,
      $_db.languages,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_languageIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ConceptsTable _conceptIdTable(_$LearningDb db) => db.concepts
      .createAlias($_aliasNameGenerator(db.lexemes.conceptId, db.concepts.id));

  $$ConceptsTableProcessedTableManager get conceptId {
    final $_column = $_itemColumn<String>('concept_id')!;

    final manager = $$ConceptsTableTableManager(
      $_db,
      $_db.concepts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_conceptIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$LexemesTableFilterComposer
    extends Composer<_$LearningDb, $LexemesTable> {
  $$LexemesTableFilterComposer({
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

  ColumnFilters<String> get writtenForm => $composableBuilder(
    column: $table.writtenForm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reading => $composableBuilder(
    column: $table.reading,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get audioPath => $composableBuilder(
    column: $table.audioPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cefrBand => $composableBuilder(
    column: $table.cefrBand,
    builder: (column) => ColumnFilters(column),
  );

  $$LanguagesTableFilterComposer get languageId {
    final $$LanguagesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.languageId,
      referencedTable: $db.languages,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LanguagesTableFilterComposer(
            $db: $db,
            $table: $db.languages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ConceptsTableFilterComposer get conceptId {
    final $$ConceptsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.conceptId,
      referencedTable: $db.concepts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ConceptsTableFilterComposer(
            $db: $db,
            $table: $db.concepts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LexemesTableOrderingComposer
    extends Composer<_$LearningDb, $LexemesTable> {
  $$LexemesTableOrderingComposer({
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

  ColumnOrderings<String> get writtenForm => $composableBuilder(
    column: $table.writtenForm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reading => $composableBuilder(
    column: $table.reading,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get audioPath => $composableBuilder(
    column: $table.audioPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cefrBand => $composableBuilder(
    column: $table.cefrBand,
    builder: (column) => ColumnOrderings(column),
  );

  $$LanguagesTableOrderingComposer get languageId {
    final $$LanguagesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.languageId,
      referencedTable: $db.languages,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LanguagesTableOrderingComposer(
            $db: $db,
            $table: $db.languages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ConceptsTableOrderingComposer get conceptId {
    final $$ConceptsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.conceptId,
      referencedTable: $db.concepts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ConceptsTableOrderingComposer(
            $db: $db,
            $table: $db.concepts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LexemesTableAnnotationComposer
    extends Composer<_$LearningDb, $LexemesTable> {
  $$LexemesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get writtenForm => $composableBuilder(
    column: $table.writtenForm,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reading =>
      $composableBuilder(column: $table.reading, builder: (column) => column);

  GeneratedColumn<String> get audioPath =>
      $composableBuilder(column: $table.audioPath, builder: (column) => column);

  GeneratedColumn<String> get cefrBand =>
      $composableBuilder(column: $table.cefrBand, builder: (column) => column);

  $$LanguagesTableAnnotationComposer get languageId {
    final $$LanguagesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.languageId,
      referencedTable: $db.languages,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LanguagesTableAnnotationComposer(
            $db: $db,
            $table: $db.languages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ConceptsTableAnnotationComposer get conceptId {
    final $$ConceptsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.conceptId,
      referencedTable: $db.concepts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ConceptsTableAnnotationComposer(
            $db: $db,
            $table: $db.concepts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LexemesTableTableManager
    extends
        RootTableManager<
          _$LearningDb,
          $LexemesTable,
          Lexeme,
          $$LexemesTableFilterComposer,
          $$LexemesTableOrderingComposer,
          $$LexemesTableAnnotationComposer,
          $$LexemesTableCreateCompanionBuilder,
          $$LexemesTableUpdateCompanionBuilder,
          (Lexeme, $$LexemesTableReferences),
          Lexeme,
          PrefetchHooks Function({bool languageId, bool conceptId})
        > {
  $$LexemesTableTableManager(_$LearningDb db, $LexemesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LexemesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LexemesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LexemesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> languageId = const Value.absent(),
                Value<String> conceptId = const Value.absent(),
                Value<String> writtenForm = const Value.absent(),
                Value<String> reading = const Value.absent(),
                Value<String?> audioPath = const Value.absent(),
                Value<String> cefrBand = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LexemesCompanion(
                id: id,
                languageId: languageId,
                conceptId: conceptId,
                writtenForm: writtenForm,
                reading: reading,
                audioPath: audioPath,
                cefrBand: cefrBand,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String languageId,
                required String conceptId,
                required String writtenForm,
                required String reading,
                Value<String?> audioPath = const Value.absent(),
                Value<String> cefrBand = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LexemesCompanion.insert(
                id: id,
                languageId: languageId,
                conceptId: conceptId,
                writtenForm: writtenForm,
                reading: reading,
                audioPath: audioPath,
                cefrBand: cefrBand,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$LexemesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({languageId = false, conceptId = false}) {
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
                    if (languageId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.languageId,
                                referencedTable: $$LexemesTableReferences
                                    ._languageIdTable(db),
                                referencedColumn: $$LexemesTableReferences
                                    ._languageIdTable(db)
                                    .id,
                              )
                              as T;
                    }
                    if (conceptId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.conceptId,
                                referencedTable: $$LexemesTableReferences
                                    ._conceptIdTable(db),
                                referencedColumn: $$LexemesTableReferences
                                    ._conceptIdTable(db)
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

typedef $$LexemesTableProcessedTableManager =
    ProcessedTableManager<
      _$LearningDb,
      $LexemesTable,
      Lexeme,
      $$LexemesTableFilterComposer,
      $$LexemesTableOrderingComposer,
      $$LexemesTableAnnotationComposer,
      $$LexemesTableCreateCompanionBuilder,
      $$LexemesTableUpdateCompanionBuilder,
      (Lexeme, $$LexemesTableReferences),
      Lexeme,
      PrefetchHooks Function({bool languageId, bool conceptId})
    >;
typedef $$CharactersTableCreateCompanionBuilder =
    CharactersCompanion Function({
      required String id,
      required String languageId,
      required String glyph,
      required String readingsJson,
      required String meaning,
      Value<String?> strokeOrderAssetId,
      Value<String?> mnemonicId,
      Value<int> rowid,
    });
typedef $$CharactersTableUpdateCompanionBuilder =
    CharactersCompanion Function({
      Value<String> id,
      Value<String> languageId,
      Value<String> glyph,
      Value<String> readingsJson,
      Value<String> meaning,
      Value<String?> strokeOrderAssetId,
      Value<String?> mnemonicId,
      Value<int> rowid,
    });

final class $$CharactersTableReferences
    extends BaseReferences<_$LearningDb, $CharactersTable, Character> {
  $$CharactersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $LanguagesTable _languageIdTable(_$LearningDb db) =>
      db.languages.createAlias(
        $_aliasNameGenerator(db.characters.languageId, db.languages.id),
      );

  $$LanguagesTableProcessedTableManager get languageId {
    final $_column = $_itemColumn<String>('language_id')!;

    final manager = $$LanguagesTableTableManager(
      $_db,
      $_db.languages,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_languageIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$CharComponentsTable, List<CharComponent>>
  _charComponentsRefsTable(_$LearningDb db) => MultiTypedResultKey.fromTable(
    db.charComponents,
    aliasName: $_aliasNameGenerator(
      db.characters.id,
      db.charComponents.characterId,
    ),
  );

  $$CharComponentsTableProcessedTableManager get charComponentsRefs {
    final manager = $$CharComponentsTableTableManager(
      $_db,
      $_db.charComponents,
    ).filter((f) => f.characterId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_charComponentsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CharactersTableFilterComposer
    extends Composer<_$LearningDb, $CharactersTable> {
  $$CharactersTableFilterComposer({
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

  ColumnFilters<String> get glyph => $composableBuilder(
    column: $table.glyph,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get readingsJson => $composableBuilder(
    column: $table.readingsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get meaning => $composableBuilder(
    column: $table.meaning,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get strokeOrderAssetId => $composableBuilder(
    column: $table.strokeOrderAssetId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mnemonicId => $composableBuilder(
    column: $table.mnemonicId,
    builder: (column) => ColumnFilters(column),
  );

  $$LanguagesTableFilterComposer get languageId {
    final $$LanguagesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.languageId,
      referencedTable: $db.languages,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LanguagesTableFilterComposer(
            $db: $db,
            $table: $db.languages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> charComponentsRefs(
    Expression<bool> Function($$CharComponentsTableFilterComposer f) f,
  ) {
    final $$CharComponentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.charComponents,
      getReferencedColumn: (t) => t.characterId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CharComponentsTableFilterComposer(
            $db: $db,
            $table: $db.charComponents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CharactersTableOrderingComposer
    extends Composer<_$LearningDb, $CharactersTable> {
  $$CharactersTableOrderingComposer({
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

  ColumnOrderings<String> get glyph => $composableBuilder(
    column: $table.glyph,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get readingsJson => $composableBuilder(
    column: $table.readingsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get meaning => $composableBuilder(
    column: $table.meaning,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get strokeOrderAssetId => $composableBuilder(
    column: $table.strokeOrderAssetId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mnemonicId => $composableBuilder(
    column: $table.mnemonicId,
    builder: (column) => ColumnOrderings(column),
  );

  $$LanguagesTableOrderingComposer get languageId {
    final $$LanguagesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.languageId,
      referencedTable: $db.languages,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LanguagesTableOrderingComposer(
            $db: $db,
            $table: $db.languages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CharactersTableAnnotationComposer
    extends Composer<_$LearningDb, $CharactersTable> {
  $$CharactersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get glyph =>
      $composableBuilder(column: $table.glyph, builder: (column) => column);

  GeneratedColumn<String> get readingsJson => $composableBuilder(
    column: $table.readingsJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get meaning =>
      $composableBuilder(column: $table.meaning, builder: (column) => column);

  GeneratedColumn<String> get strokeOrderAssetId => $composableBuilder(
    column: $table.strokeOrderAssetId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get mnemonicId => $composableBuilder(
    column: $table.mnemonicId,
    builder: (column) => column,
  );

  $$LanguagesTableAnnotationComposer get languageId {
    final $$LanguagesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.languageId,
      referencedTable: $db.languages,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LanguagesTableAnnotationComposer(
            $db: $db,
            $table: $db.languages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> charComponentsRefs<T extends Object>(
    Expression<T> Function($$CharComponentsTableAnnotationComposer a) f,
  ) {
    final $$CharComponentsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.charComponents,
      getReferencedColumn: (t) => t.characterId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CharComponentsTableAnnotationComposer(
            $db: $db,
            $table: $db.charComponents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CharactersTableTableManager
    extends
        RootTableManager<
          _$LearningDb,
          $CharactersTable,
          Character,
          $$CharactersTableFilterComposer,
          $$CharactersTableOrderingComposer,
          $$CharactersTableAnnotationComposer,
          $$CharactersTableCreateCompanionBuilder,
          $$CharactersTableUpdateCompanionBuilder,
          (Character, $$CharactersTableReferences),
          Character,
          PrefetchHooks Function({bool languageId, bool charComponentsRefs})
        > {
  $$CharactersTableTableManager(_$LearningDb db, $CharactersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CharactersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CharactersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CharactersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> languageId = const Value.absent(),
                Value<String> glyph = const Value.absent(),
                Value<String> readingsJson = const Value.absent(),
                Value<String> meaning = const Value.absent(),
                Value<String?> strokeOrderAssetId = const Value.absent(),
                Value<String?> mnemonicId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CharactersCompanion(
                id: id,
                languageId: languageId,
                glyph: glyph,
                readingsJson: readingsJson,
                meaning: meaning,
                strokeOrderAssetId: strokeOrderAssetId,
                mnemonicId: mnemonicId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String languageId,
                required String glyph,
                required String readingsJson,
                required String meaning,
                Value<String?> strokeOrderAssetId = const Value.absent(),
                Value<String?> mnemonicId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CharactersCompanion.insert(
                id: id,
                languageId: languageId,
                glyph: glyph,
                readingsJson: readingsJson,
                meaning: meaning,
                strokeOrderAssetId: strokeOrderAssetId,
                mnemonicId: mnemonicId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CharactersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({languageId = false, charComponentsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (charComponentsRefs) db.charComponents,
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
                        if (languageId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.languageId,
                                    referencedTable: $$CharactersTableReferences
                                        ._languageIdTable(db),
                                    referencedColumn:
                                        $$CharactersTableReferences
                                            ._languageIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (charComponentsRefs)
                        await $_getPrefetchedData<
                          Character,
                          $CharactersTable,
                          CharComponent
                        >(
                          currentTable: table,
                          referencedTable: $$CharactersTableReferences
                              ._charComponentsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CharactersTableReferences(
                                db,
                                table,
                                p0,
                              ).charComponentsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.characterId == item.id,
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

typedef $$CharactersTableProcessedTableManager =
    ProcessedTableManager<
      _$LearningDb,
      $CharactersTable,
      Character,
      $$CharactersTableFilterComposer,
      $$CharactersTableOrderingComposer,
      $$CharactersTableAnnotationComposer,
      $$CharactersTableCreateCompanionBuilder,
      $$CharactersTableUpdateCompanionBuilder,
      (Character, $$CharactersTableReferences),
      Character,
      PrefetchHooks Function({bool languageId, bool charComponentsRefs})
    >;
typedef $$CharComponentsTableCreateCompanionBuilder =
    CharComponentsCompanion Function({
      required String id,
      required String characterId,
      required String componentGlyph,
      required String position,
      Value<int> rowid,
    });
typedef $$CharComponentsTableUpdateCompanionBuilder =
    CharComponentsCompanion Function({
      Value<String> id,
      Value<String> characterId,
      Value<String> componentGlyph,
      Value<String> position,
      Value<int> rowid,
    });

final class $$CharComponentsTableReferences
    extends BaseReferences<_$LearningDb, $CharComponentsTable, CharComponent> {
  $$CharComponentsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $CharactersTable _characterIdTable(_$LearningDb db) =>
      db.characters.createAlias(
        $_aliasNameGenerator(db.charComponents.characterId, db.characters.id),
      );

  $$CharactersTableProcessedTableManager get characterId {
    final $_column = $_itemColumn<String>('character_id')!;

    final manager = $$CharactersTableTableManager(
      $_db,
      $_db.characters,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_characterIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$CharComponentsTableFilterComposer
    extends Composer<_$LearningDb, $CharComponentsTable> {
  $$CharComponentsTableFilterComposer({
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

  ColumnFilters<String> get componentGlyph => $composableBuilder(
    column: $table.componentGlyph,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  $$CharactersTableFilterComposer get characterId {
    final $$CharactersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.characterId,
      referencedTable: $db.characters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CharactersTableFilterComposer(
            $db: $db,
            $table: $db.characters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CharComponentsTableOrderingComposer
    extends Composer<_$LearningDb, $CharComponentsTable> {
  $$CharComponentsTableOrderingComposer({
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

  ColumnOrderings<String> get componentGlyph => $composableBuilder(
    column: $table.componentGlyph,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  $$CharactersTableOrderingComposer get characterId {
    final $$CharactersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.characterId,
      referencedTable: $db.characters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CharactersTableOrderingComposer(
            $db: $db,
            $table: $db.characters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CharComponentsTableAnnotationComposer
    extends Composer<_$LearningDb, $CharComponentsTable> {
  $$CharComponentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get componentGlyph => $composableBuilder(
    column: $table.componentGlyph,
    builder: (column) => column,
  );

  GeneratedColumn<String> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  $$CharactersTableAnnotationComposer get characterId {
    final $$CharactersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.characterId,
      referencedTable: $db.characters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CharactersTableAnnotationComposer(
            $db: $db,
            $table: $db.characters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CharComponentsTableTableManager
    extends
        RootTableManager<
          _$LearningDb,
          $CharComponentsTable,
          CharComponent,
          $$CharComponentsTableFilterComposer,
          $$CharComponentsTableOrderingComposer,
          $$CharComponentsTableAnnotationComposer,
          $$CharComponentsTableCreateCompanionBuilder,
          $$CharComponentsTableUpdateCompanionBuilder,
          (CharComponent, $$CharComponentsTableReferences),
          CharComponent,
          PrefetchHooks Function({bool characterId})
        > {
  $$CharComponentsTableTableManager(_$LearningDb db, $CharComponentsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CharComponentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CharComponentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CharComponentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> characterId = const Value.absent(),
                Value<String> componentGlyph = const Value.absent(),
                Value<String> position = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CharComponentsCompanion(
                id: id,
                characterId: characterId,
                componentGlyph: componentGlyph,
                position: position,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String characterId,
                required String componentGlyph,
                required String position,
                Value<int> rowid = const Value.absent(),
              }) => CharComponentsCompanion.insert(
                id: id,
                characterId: characterId,
                componentGlyph: componentGlyph,
                position: position,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CharComponentsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({characterId = false}) {
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
                    if (characterId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.characterId,
                                referencedTable: $$CharComponentsTableReferences
                                    ._characterIdTable(db),
                                referencedColumn:
                                    $$CharComponentsTableReferences
                                        ._characterIdTable(db)
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

typedef $$CharComponentsTableProcessedTableManager =
    ProcessedTableManager<
      _$LearningDb,
      $CharComponentsTable,
      CharComponent,
      $$CharComponentsTableFilterComposer,
      $$CharComponentsTableOrderingComposer,
      $$CharComponentsTableAnnotationComposer,
      $$CharComponentsTableCreateCompanionBuilder,
      $$CharComponentsTableUpdateCompanionBuilder,
      (CharComponent, $$CharComponentsTableReferences),
      CharComponent,
      PrefetchHooks Function({bool characterId})
    >;
typedef $$CanDoGoalsTableCreateCompanionBuilder =
    CanDoGoalsCompanion Function({
      required String id,
      required String languageId,
      required String cefrBand,
      required String description,
      Value<int> rowid,
    });
typedef $$CanDoGoalsTableUpdateCompanionBuilder =
    CanDoGoalsCompanion Function({
      Value<String> id,
      Value<String> languageId,
      Value<String> cefrBand,
      Value<String> description,
      Value<int> rowid,
    });

final class $$CanDoGoalsTableReferences
    extends BaseReferences<_$LearningDb, $CanDoGoalsTable, CanDoGoal> {
  $$CanDoGoalsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $LanguagesTable _languageIdTable(_$LearningDb db) =>
      db.languages.createAlias(
        $_aliasNameGenerator(db.canDoGoals.languageId, db.languages.id),
      );

  $$LanguagesTableProcessedTableManager get languageId {
    final $_column = $_itemColumn<String>('language_id')!;

    final manager = $$LanguagesTableTableManager(
      $_db,
      $_db.languages,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_languageIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$GrammarPointsTable, List<GrammarPoint>>
  _grammarPointsRefsTable(_$LearningDb db) => MultiTypedResultKey.fromTable(
    db.grammarPoints,
    aliasName: $_aliasNameGenerator(db.canDoGoals.id, db.grammarPoints.canDoId),
  );

  $$GrammarPointsTableProcessedTableManager get grammarPointsRefs {
    final manager = $$GrammarPointsTableTableManager(
      $_db,
      $_db.grammarPoints,
    ).filter((f) => f.canDoId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_grammarPointsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CanDoGoalsTableFilterComposer
    extends Composer<_$LearningDb, $CanDoGoalsTable> {
  $$CanDoGoalsTableFilterComposer({
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

  ColumnFilters<String> get cefrBand => $composableBuilder(
    column: $table.cefrBand,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  $$LanguagesTableFilterComposer get languageId {
    final $$LanguagesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.languageId,
      referencedTable: $db.languages,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LanguagesTableFilterComposer(
            $db: $db,
            $table: $db.languages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> grammarPointsRefs(
    Expression<bool> Function($$GrammarPointsTableFilterComposer f) f,
  ) {
    final $$GrammarPointsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.grammarPoints,
      getReferencedColumn: (t) => t.canDoId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GrammarPointsTableFilterComposer(
            $db: $db,
            $table: $db.grammarPoints,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CanDoGoalsTableOrderingComposer
    extends Composer<_$LearningDb, $CanDoGoalsTable> {
  $$CanDoGoalsTableOrderingComposer({
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

  ColumnOrderings<String> get cefrBand => $composableBuilder(
    column: $table.cefrBand,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  $$LanguagesTableOrderingComposer get languageId {
    final $$LanguagesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.languageId,
      referencedTable: $db.languages,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LanguagesTableOrderingComposer(
            $db: $db,
            $table: $db.languages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CanDoGoalsTableAnnotationComposer
    extends Composer<_$LearningDb, $CanDoGoalsTable> {
  $$CanDoGoalsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get cefrBand =>
      $composableBuilder(column: $table.cefrBand, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  $$LanguagesTableAnnotationComposer get languageId {
    final $$LanguagesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.languageId,
      referencedTable: $db.languages,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LanguagesTableAnnotationComposer(
            $db: $db,
            $table: $db.languages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> grammarPointsRefs<T extends Object>(
    Expression<T> Function($$GrammarPointsTableAnnotationComposer a) f,
  ) {
    final $$GrammarPointsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.grammarPoints,
      getReferencedColumn: (t) => t.canDoId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GrammarPointsTableAnnotationComposer(
            $db: $db,
            $table: $db.grammarPoints,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CanDoGoalsTableTableManager
    extends
        RootTableManager<
          _$LearningDb,
          $CanDoGoalsTable,
          CanDoGoal,
          $$CanDoGoalsTableFilterComposer,
          $$CanDoGoalsTableOrderingComposer,
          $$CanDoGoalsTableAnnotationComposer,
          $$CanDoGoalsTableCreateCompanionBuilder,
          $$CanDoGoalsTableUpdateCompanionBuilder,
          (CanDoGoal, $$CanDoGoalsTableReferences),
          CanDoGoal,
          PrefetchHooks Function({bool languageId, bool grammarPointsRefs})
        > {
  $$CanDoGoalsTableTableManager(_$LearningDb db, $CanDoGoalsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CanDoGoalsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CanDoGoalsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CanDoGoalsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> languageId = const Value.absent(),
                Value<String> cefrBand = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CanDoGoalsCompanion(
                id: id,
                languageId: languageId,
                cefrBand: cefrBand,
                description: description,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String languageId,
                required String cefrBand,
                required String description,
                Value<int> rowid = const Value.absent(),
              }) => CanDoGoalsCompanion.insert(
                id: id,
                languageId: languageId,
                cefrBand: cefrBand,
                description: description,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CanDoGoalsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({languageId = false, grammarPointsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (grammarPointsRefs) db.grammarPoints,
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
                        if (languageId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.languageId,
                                    referencedTable: $$CanDoGoalsTableReferences
                                        ._languageIdTable(db),
                                    referencedColumn:
                                        $$CanDoGoalsTableReferences
                                            ._languageIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (grammarPointsRefs)
                        await $_getPrefetchedData<
                          CanDoGoal,
                          $CanDoGoalsTable,
                          GrammarPoint
                        >(
                          currentTable: table,
                          referencedTable: $$CanDoGoalsTableReferences
                              ._grammarPointsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CanDoGoalsTableReferences(
                                db,
                                table,
                                p0,
                              ).grammarPointsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.canDoId == item.id,
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

typedef $$CanDoGoalsTableProcessedTableManager =
    ProcessedTableManager<
      _$LearningDb,
      $CanDoGoalsTable,
      CanDoGoal,
      $$CanDoGoalsTableFilterComposer,
      $$CanDoGoalsTableOrderingComposer,
      $$CanDoGoalsTableAnnotationComposer,
      $$CanDoGoalsTableCreateCompanionBuilder,
      $$CanDoGoalsTableUpdateCompanionBuilder,
      (CanDoGoal, $$CanDoGoalsTableReferences),
      CanDoGoal,
      PrefetchHooks Function({bool languageId, bool grammarPointsRefs})
    >;
typedef $$GrammarPointsTableCreateCompanionBuilder =
    GrammarPointsCompanion Function({
      required String id,
      required String languageId,
      required String cefrBand,
      required int sequenceIndex,
      required String canDoId,
      Value<int> rowid,
    });
typedef $$GrammarPointsTableUpdateCompanionBuilder =
    GrammarPointsCompanion Function({
      Value<String> id,
      Value<String> languageId,
      Value<String> cefrBand,
      Value<int> sequenceIndex,
      Value<String> canDoId,
      Value<int> rowid,
    });

final class $$GrammarPointsTableReferences
    extends BaseReferences<_$LearningDb, $GrammarPointsTable, GrammarPoint> {
  $$GrammarPointsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $LanguagesTable _languageIdTable(_$LearningDb db) =>
      db.languages.createAlias(
        $_aliasNameGenerator(db.grammarPoints.languageId, db.languages.id),
      );

  $$LanguagesTableProcessedTableManager get languageId {
    final $_column = $_itemColumn<String>('language_id')!;

    final manager = $$LanguagesTableTableManager(
      $_db,
      $_db.languages,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_languageIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $CanDoGoalsTable _canDoIdTable(_$LearningDb db) =>
      db.canDoGoals.createAlias(
        $_aliasNameGenerator(db.grammarPoints.canDoId, db.canDoGoals.id),
      );

  $$CanDoGoalsTableProcessedTableManager get canDoId {
    final $_column = $_itemColumn<String>('can_do_id')!;

    final manager = $$CanDoGoalsTableTableManager(
      $_db,
      $_db.canDoGoals,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_canDoIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$GrammarPointsTableFilterComposer
    extends Composer<_$LearningDb, $GrammarPointsTable> {
  $$GrammarPointsTableFilterComposer({
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

  ColumnFilters<String> get cefrBand => $composableBuilder(
    column: $table.cefrBand,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sequenceIndex => $composableBuilder(
    column: $table.sequenceIndex,
    builder: (column) => ColumnFilters(column),
  );

  $$LanguagesTableFilterComposer get languageId {
    final $$LanguagesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.languageId,
      referencedTable: $db.languages,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LanguagesTableFilterComposer(
            $db: $db,
            $table: $db.languages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CanDoGoalsTableFilterComposer get canDoId {
    final $$CanDoGoalsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.canDoId,
      referencedTable: $db.canDoGoals,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CanDoGoalsTableFilterComposer(
            $db: $db,
            $table: $db.canDoGoals,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$GrammarPointsTableOrderingComposer
    extends Composer<_$LearningDb, $GrammarPointsTable> {
  $$GrammarPointsTableOrderingComposer({
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

  ColumnOrderings<String> get cefrBand => $composableBuilder(
    column: $table.cefrBand,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sequenceIndex => $composableBuilder(
    column: $table.sequenceIndex,
    builder: (column) => ColumnOrderings(column),
  );

  $$LanguagesTableOrderingComposer get languageId {
    final $$LanguagesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.languageId,
      referencedTable: $db.languages,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LanguagesTableOrderingComposer(
            $db: $db,
            $table: $db.languages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CanDoGoalsTableOrderingComposer get canDoId {
    final $$CanDoGoalsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.canDoId,
      referencedTable: $db.canDoGoals,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CanDoGoalsTableOrderingComposer(
            $db: $db,
            $table: $db.canDoGoals,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$GrammarPointsTableAnnotationComposer
    extends Composer<_$LearningDb, $GrammarPointsTable> {
  $$GrammarPointsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get cefrBand =>
      $composableBuilder(column: $table.cefrBand, builder: (column) => column);

  GeneratedColumn<int> get sequenceIndex => $composableBuilder(
    column: $table.sequenceIndex,
    builder: (column) => column,
  );

  $$LanguagesTableAnnotationComposer get languageId {
    final $$LanguagesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.languageId,
      referencedTable: $db.languages,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LanguagesTableAnnotationComposer(
            $db: $db,
            $table: $db.languages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CanDoGoalsTableAnnotationComposer get canDoId {
    final $$CanDoGoalsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.canDoId,
      referencedTable: $db.canDoGoals,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CanDoGoalsTableAnnotationComposer(
            $db: $db,
            $table: $db.canDoGoals,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$GrammarPointsTableTableManager
    extends
        RootTableManager<
          _$LearningDb,
          $GrammarPointsTable,
          GrammarPoint,
          $$GrammarPointsTableFilterComposer,
          $$GrammarPointsTableOrderingComposer,
          $$GrammarPointsTableAnnotationComposer,
          $$GrammarPointsTableCreateCompanionBuilder,
          $$GrammarPointsTableUpdateCompanionBuilder,
          (GrammarPoint, $$GrammarPointsTableReferences),
          GrammarPoint,
          PrefetchHooks Function({bool languageId, bool canDoId})
        > {
  $$GrammarPointsTableTableManager(_$LearningDb db, $GrammarPointsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GrammarPointsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GrammarPointsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GrammarPointsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> languageId = const Value.absent(),
                Value<String> cefrBand = const Value.absent(),
                Value<int> sequenceIndex = const Value.absent(),
                Value<String> canDoId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GrammarPointsCompanion(
                id: id,
                languageId: languageId,
                cefrBand: cefrBand,
                sequenceIndex: sequenceIndex,
                canDoId: canDoId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String languageId,
                required String cefrBand,
                required int sequenceIndex,
                required String canDoId,
                Value<int> rowid = const Value.absent(),
              }) => GrammarPointsCompanion.insert(
                id: id,
                languageId: languageId,
                cefrBand: cefrBand,
                sequenceIndex: sequenceIndex,
                canDoId: canDoId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$GrammarPointsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({languageId = false, canDoId = false}) {
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
                    if (languageId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.languageId,
                                referencedTable: $$GrammarPointsTableReferences
                                    ._languageIdTable(db),
                                referencedColumn: $$GrammarPointsTableReferences
                                    ._languageIdTable(db)
                                    .id,
                              )
                              as T;
                    }
                    if (canDoId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.canDoId,
                                referencedTable: $$GrammarPointsTableReferences
                                    ._canDoIdTable(db),
                                referencedColumn: $$GrammarPointsTableReferences
                                    ._canDoIdTable(db)
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

typedef $$GrammarPointsTableProcessedTableManager =
    ProcessedTableManager<
      _$LearningDb,
      $GrammarPointsTable,
      GrammarPoint,
      $$GrammarPointsTableFilterComposer,
      $$GrammarPointsTableOrderingComposer,
      $$GrammarPointsTableAnnotationComposer,
      $$GrammarPointsTableCreateCompanionBuilder,
      $$GrammarPointsTableUpdateCompanionBuilder,
      (GrammarPoint, $$GrammarPointsTableReferences),
      GrammarPoint,
      PrefetchHooks Function({bool languageId, bool canDoId})
    >;
typedef $$SentencesTableCreateCompanionBuilder =
    SentencesCompanion Function({
      required String id,
      required String languageId,
      required String cefrBand,
      required String content,
      Value<double> knownCoverage,
      Value<int> rowid,
    });
typedef $$SentencesTableUpdateCompanionBuilder =
    SentencesCompanion Function({
      Value<String> id,
      Value<String> languageId,
      Value<String> cefrBand,
      Value<String> content,
      Value<double> knownCoverage,
      Value<int> rowid,
    });

final class $$SentencesTableReferences
    extends BaseReferences<_$LearningDb, $SentencesTable, Sentence> {
  $$SentencesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $LanguagesTable _languageIdTable(_$LearningDb db) =>
      db.languages.createAlias(
        $_aliasNameGenerator(db.sentences.languageId, db.languages.id),
      );

  $$LanguagesTableProcessedTableManager get languageId {
    final $_column = $_itemColumn<String>('language_id')!;

    final manager = $$LanguagesTableTableManager(
      $_db,
      $_db.languages,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_languageIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$SentencesTableFilterComposer
    extends Composer<_$LearningDb, $SentencesTable> {
  $$SentencesTableFilterComposer({
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

  ColumnFilters<String> get cefrBand => $composableBuilder(
    column: $table.cefrBand,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get knownCoverage => $composableBuilder(
    column: $table.knownCoverage,
    builder: (column) => ColumnFilters(column),
  );

  $$LanguagesTableFilterComposer get languageId {
    final $$LanguagesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.languageId,
      referencedTable: $db.languages,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LanguagesTableFilterComposer(
            $db: $db,
            $table: $db.languages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SentencesTableOrderingComposer
    extends Composer<_$LearningDb, $SentencesTable> {
  $$SentencesTableOrderingComposer({
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

  ColumnOrderings<String> get cefrBand => $composableBuilder(
    column: $table.cefrBand,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get knownCoverage => $composableBuilder(
    column: $table.knownCoverage,
    builder: (column) => ColumnOrderings(column),
  );

  $$LanguagesTableOrderingComposer get languageId {
    final $$LanguagesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.languageId,
      referencedTable: $db.languages,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LanguagesTableOrderingComposer(
            $db: $db,
            $table: $db.languages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SentencesTableAnnotationComposer
    extends Composer<_$LearningDb, $SentencesTable> {
  $$SentencesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get cefrBand =>
      $composableBuilder(column: $table.cefrBand, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<double> get knownCoverage => $composableBuilder(
    column: $table.knownCoverage,
    builder: (column) => column,
  );

  $$LanguagesTableAnnotationComposer get languageId {
    final $$LanguagesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.languageId,
      referencedTable: $db.languages,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LanguagesTableAnnotationComposer(
            $db: $db,
            $table: $db.languages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SentencesTableTableManager
    extends
        RootTableManager<
          _$LearningDb,
          $SentencesTable,
          Sentence,
          $$SentencesTableFilterComposer,
          $$SentencesTableOrderingComposer,
          $$SentencesTableAnnotationComposer,
          $$SentencesTableCreateCompanionBuilder,
          $$SentencesTableUpdateCompanionBuilder,
          (Sentence, $$SentencesTableReferences),
          Sentence,
          PrefetchHooks Function({bool languageId})
        > {
  $$SentencesTableTableManager(_$LearningDb db, $SentencesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SentencesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SentencesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SentencesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> languageId = const Value.absent(),
                Value<String> cefrBand = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<double> knownCoverage = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SentencesCompanion(
                id: id,
                languageId: languageId,
                cefrBand: cefrBand,
                content: content,
                knownCoverage: knownCoverage,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String languageId,
                required String cefrBand,
                required String content,
                Value<double> knownCoverage = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SentencesCompanion.insert(
                id: id,
                languageId: languageId,
                cefrBand: cefrBand,
                content: content,
                knownCoverage: knownCoverage,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$SentencesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({languageId = false}) {
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
                    if (languageId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.languageId,
                                referencedTable: $$SentencesTableReferences
                                    ._languageIdTable(db),
                                referencedColumn: $$SentencesTableReferences
                                    ._languageIdTable(db)
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

typedef $$SentencesTableProcessedTableManager =
    ProcessedTableManager<
      _$LearningDb,
      $SentencesTable,
      Sentence,
      $$SentencesTableFilterComposer,
      $$SentencesTableOrderingComposer,
      $$SentencesTableAnnotationComposer,
      $$SentencesTableCreateCompanionBuilder,
      $$SentencesTableUpdateCompanionBuilder,
      (Sentence, $$SentencesTableReferences),
      Sentence,
      PrefetchHooks Function({bool languageId})
    >;
typedef $$LearnItemsTableCreateCompanionBuilder =
    LearnItemsCompanion Function({
      required String id,
      required String languageId,
      required String refType,
      required String refId,
      Value<int> masteryRung,
      Value<double> ease,
      Value<int> intervalDays,
      required DateTime dueAt,
      Value<int> reps,
      Value<int> lapses,
      Value<int> consecutiveCorrect,
      Value<int> rowid,
    });
typedef $$LearnItemsTableUpdateCompanionBuilder =
    LearnItemsCompanion Function({
      Value<String> id,
      Value<String> languageId,
      Value<String> refType,
      Value<String> refId,
      Value<int> masteryRung,
      Value<double> ease,
      Value<int> intervalDays,
      Value<DateTime> dueAt,
      Value<int> reps,
      Value<int> lapses,
      Value<int> consecutiveCorrect,
      Value<int> rowid,
    });

final class $$LearnItemsTableReferences
    extends BaseReferences<_$LearningDb, $LearnItemsTable, LearnItem> {
  $$LearnItemsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $LanguagesTable _languageIdTable(_$LearningDb db) =>
      db.languages.createAlias(
        $_aliasNameGenerator(db.learnItems.languageId, db.languages.id),
      );

  $$LanguagesTableProcessedTableManager get languageId {
    final $_column = $_itemColumn<String>('language_id')!;

    final manager = $$LanguagesTableTableManager(
      $_db,
      $_db.languages,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_languageIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$ReviewLogTable, List<ReviewLogData>>
  _reviewLogRefsTable(_$LearningDb db) => MultiTypedResultKey.fromTable(
    db.reviewLog,
    aliasName: $_aliasNameGenerator(db.learnItems.id, db.reviewLog.learnItemId),
  );

  $$ReviewLogTableProcessedTableManager get reviewLogRefs {
    final manager = $$ReviewLogTableTableManager(
      $_db,
      $_db.reviewLog,
    ).filter((f) => f.learnItemId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_reviewLogRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$LearnItemsTableFilterComposer
    extends Composer<_$LearningDb, $LearnItemsTable> {
  $$LearnItemsTableFilterComposer({
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

  ColumnFilters<String> get refType => $composableBuilder(
    column: $table.refType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get refId => $composableBuilder(
    column: $table.refId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get masteryRung => $composableBuilder(
    column: $table.masteryRung,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get ease => $composableBuilder(
    column: $table.ease,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get intervalDays => $composableBuilder(
    column: $table.intervalDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get dueAt => $composableBuilder(
    column: $table.dueAt,
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

  ColumnFilters<int> get consecutiveCorrect => $composableBuilder(
    column: $table.consecutiveCorrect,
    builder: (column) => ColumnFilters(column),
  );

  $$LanguagesTableFilterComposer get languageId {
    final $$LanguagesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.languageId,
      referencedTable: $db.languages,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LanguagesTableFilterComposer(
            $db: $db,
            $table: $db.languages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> reviewLogRefs(
    Expression<bool> Function($$ReviewLogTableFilterComposer f) f,
  ) {
    final $$ReviewLogTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.reviewLog,
      getReferencedColumn: (t) => t.learnItemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReviewLogTableFilterComposer(
            $db: $db,
            $table: $db.reviewLog,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$LearnItemsTableOrderingComposer
    extends Composer<_$LearningDb, $LearnItemsTable> {
  $$LearnItemsTableOrderingComposer({
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

  ColumnOrderings<String> get refType => $composableBuilder(
    column: $table.refType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get refId => $composableBuilder(
    column: $table.refId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get masteryRung => $composableBuilder(
    column: $table.masteryRung,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get ease => $composableBuilder(
    column: $table.ease,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get intervalDays => $composableBuilder(
    column: $table.intervalDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dueAt => $composableBuilder(
    column: $table.dueAt,
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

  ColumnOrderings<int> get consecutiveCorrect => $composableBuilder(
    column: $table.consecutiveCorrect,
    builder: (column) => ColumnOrderings(column),
  );

  $$LanguagesTableOrderingComposer get languageId {
    final $$LanguagesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.languageId,
      referencedTable: $db.languages,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LanguagesTableOrderingComposer(
            $db: $db,
            $table: $db.languages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LearnItemsTableAnnotationComposer
    extends Composer<_$LearningDb, $LearnItemsTable> {
  $$LearnItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get refType =>
      $composableBuilder(column: $table.refType, builder: (column) => column);

  GeneratedColumn<String> get refId =>
      $composableBuilder(column: $table.refId, builder: (column) => column);

  GeneratedColumn<int> get masteryRung => $composableBuilder(
    column: $table.masteryRung,
    builder: (column) => column,
  );

  GeneratedColumn<double> get ease =>
      $composableBuilder(column: $table.ease, builder: (column) => column);

  GeneratedColumn<int> get intervalDays => $composableBuilder(
    column: $table.intervalDays,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get dueAt =>
      $composableBuilder(column: $table.dueAt, builder: (column) => column);

  GeneratedColumn<int> get reps =>
      $composableBuilder(column: $table.reps, builder: (column) => column);

  GeneratedColumn<int> get lapses =>
      $composableBuilder(column: $table.lapses, builder: (column) => column);

  GeneratedColumn<int> get consecutiveCorrect => $composableBuilder(
    column: $table.consecutiveCorrect,
    builder: (column) => column,
  );

  $$LanguagesTableAnnotationComposer get languageId {
    final $$LanguagesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.languageId,
      referencedTable: $db.languages,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LanguagesTableAnnotationComposer(
            $db: $db,
            $table: $db.languages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> reviewLogRefs<T extends Object>(
    Expression<T> Function($$ReviewLogTableAnnotationComposer a) f,
  ) {
    final $$ReviewLogTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.reviewLog,
      getReferencedColumn: (t) => t.learnItemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReviewLogTableAnnotationComposer(
            $db: $db,
            $table: $db.reviewLog,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$LearnItemsTableTableManager
    extends
        RootTableManager<
          _$LearningDb,
          $LearnItemsTable,
          LearnItem,
          $$LearnItemsTableFilterComposer,
          $$LearnItemsTableOrderingComposer,
          $$LearnItemsTableAnnotationComposer,
          $$LearnItemsTableCreateCompanionBuilder,
          $$LearnItemsTableUpdateCompanionBuilder,
          (LearnItem, $$LearnItemsTableReferences),
          LearnItem,
          PrefetchHooks Function({bool languageId, bool reviewLogRefs})
        > {
  $$LearnItemsTableTableManager(_$LearningDb db, $LearnItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LearnItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LearnItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LearnItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> languageId = const Value.absent(),
                Value<String> refType = const Value.absent(),
                Value<String> refId = const Value.absent(),
                Value<int> masteryRung = const Value.absent(),
                Value<double> ease = const Value.absent(),
                Value<int> intervalDays = const Value.absent(),
                Value<DateTime> dueAt = const Value.absent(),
                Value<int> reps = const Value.absent(),
                Value<int> lapses = const Value.absent(),
                Value<int> consecutiveCorrect = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LearnItemsCompanion(
                id: id,
                languageId: languageId,
                refType: refType,
                refId: refId,
                masteryRung: masteryRung,
                ease: ease,
                intervalDays: intervalDays,
                dueAt: dueAt,
                reps: reps,
                lapses: lapses,
                consecutiveCorrect: consecutiveCorrect,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String languageId,
                required String refType,
                required String refId,
                Value<int> masteryRung = const Value.absent(),
                Value<double> ease = const Value.absent(),
                Value<int> intervalDays = const Value.absent(),
                required DateTime dueAt,
                Value<int> reps = const Value.absent(),
                Value<int> lapses = const Value.absent(),
                Value<int> consecutiveCorrect = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LearnItemsCompanion.insert(
                id: id,
                languageId: languageId,
                refType: refType,
                refId: refId,
                masteryRung: masteryRung,
                ease: ease,
                intervalDays: intervalDays,
                dueAt: dueAt,
                reps: reps,
                lapses: lapses,
                consecutiveCorrect: consecutiveCorrect,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$LearnItemsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({languageId = false, reviewLogRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (reviewLogRefs) db.reviewLog],
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
                    if (languageId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.languageId,
                                referencedTable: $$LearnItemsTableReferences
                                    ._languageIdTable(db),
                                referencedColumn: $$LearnItemsTableReferences
                                    ._languageIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (reviewLogRefs)
                    await $_getPrefetchedData<
                      LearnItem,
                      $LearnItemsTable,
                      ReviewLogData
                    >(
                      currentTable: table,
                      referencedTable: $$LearnItemsTableReferences
                          ._reviewLogRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$LearnItemsTableReferences(
                            db,
                            table,
                            p0,
                          ).reviewLogRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.learnItemId == item.id,
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

typedef $$LearnItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$LearningDb,
      $LearnItemsTable,
      LearnItem,
      $$LearnItemsTableFilterComposer,
      $$LearnItemsTableOrderingComposer,
      $$LearnItemsTableAnnotationComposer,
      $$LearnItemsTableCreateCompanionBuilder,
      $$LearnItemsTableUpdateCompanionBuilder,
      (LearnItem, $$LearnItemsTableReferences),
      LearnItem,
      PrefetchHooks Function({bool languageId, bool reviewLogRefs})
    >;
typedef $$ReviewLogTableCreateCompanionBuilder =
    ReviewLogCompanion Function({
      required String id,
      required String learnItemId,
      required int rung,
      required String result,
      required DateTime ts,
      Value<int> rowid,
    });
typedef $$ReviewLogTableUpdateCompanionBuilder =
    ReviewLogCompanion Function({
      Value<String> id,
      Value<String> learnItemId,
      Value<int> rung,
      Value<String> result,
      Value<DateTime> ts,
      Value<int> rowid,
    });

final class $$ReviewLogTableReferences
    extends BaseReferences<_$LearningDb, $ReviewLogTable, ReviewLogData> {
  $$ReviewLogTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $LearnItemsTable _learnItemIdTable(_$LearningDb db) =>
      db.learnItems.createAlias(
        $_aliasNameGenerator(db.reviewLog.learnItemId, db.learnItems.id),
      );

  $$LearnItemsTableProcessedTableManager get learnItemId {
    final $_column = $_itemColumn<String>('learn_item_id')!;

    final manager = $$LearnItemsTableTableManager(
      $_db,
      $_db.learnItems,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_learnItemIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ReviewLogTableFilterComposer
    extends Composer<_$LearningDb, $ReviewLogTable> {
  $$ReviewLogTableFilterComposer({
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

  ColumnFilters<int> get rung => $composableBuilder(
    column: $table.rung,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get result => $composableBuilder(
    column: $table.result,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get ts => $composableBuilder(
    column: $table.ts,
    builder: (column) => ColumnFilters(column),
  );

  $$LearnItemsTableFilterComposer get learnItemId {
    final $$LearnItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.learnItemId,
      referencedTable: $db.learnItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LearnItemsTableFilterComposer(
            $db: $db,
            $table: $db.learnItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReviewLogTableOrderingComposer
    extends Composer<_$LearningDb, $ReviewLogTable> {
  $$ReviewLogTableOrderingComposer({
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

  ColumnOrderings<int> get rung => $composableBuilder(
    column: $table.rung,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get result => $composableBuilder(
    column: $table.result,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get ts => $composableBuilder(
    column: $table.ts,
    builder: (column) => ColumnOrderings(column),
  );

  $$LearnItemsTableOrderingComposer get learnItemId {
    final $$LearnItemsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.learnItemId,
      referencedTable: $db.learnItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LearnItemsTableOrderingComposer(
            $db: $db,
            $table: $db.learnItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReviewLogTableAnnotationComposer
    extends Composer<_$LearningDb, $ReviewLogTable> {
  $$ReviewLogTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get rung =>
      $composableBuilder(column: $table.rung, builder: (column) => column);

  GeneratedColumn<String> get result =>
      $composableBuilder(column: $table.result, builder: (column) => column);

  GeneratedColumn<DateTime> get ts =>
      $composableBuilder(column: $table.ts, builder: (column) => column);

  $$LearnItemsTableAnnotationComposer get learnItemId {
    final $$LearnItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.learnItemId,
      referencedTable: $db.learnItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LearnItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.learnItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReviewLogTableTableManager
    extends
        RootTableManager<
          _$LearningDb,
          $ReviewLogTable,
          ReviewLogData,
          $$ReviewLogTableFilterComposer,
          $$ReviewLogTableOrderingComposer,
          $$ReviewLogTableAnnotationComposer,
          $$ReviewLogTableCreateCompanionBuilder,
          $$ReviewLogTableUpdateCompanionBuilder,
          (ReviewLogData, $$ReviewLogTableReferences),
          ReviewLogData,
          PrefetchHooks Function({bool learnItemId})
        > {
  $$ReviewLogTableTableManager(_$LearningDb db, $ReviewLogTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReviewLogTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReviewLogTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReviewLogTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> learnItemId = const Value.absent(),
                Value<int> rung = const Value.absent(),
                Value<String> result = const Value.absent(),
                Value<DateTime> ts = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReviewLogCompanion(
                id: id,
                learnItemId: learnItemId,
                rung: rung,
                result: result,
                ts: ts,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String learnItemId,
                required int rung,
                required String result,
                required DateTime ts,
                Value<int> rowid = const Value.absent(),
              }) => ReviewLogCompanion.insert(
                id: id,
                learnItemId: learnItemId,
                rung: rung,
                result: result,
                ts: ts,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ReviewLogTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({learnItemId = false}) {
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
                    if (learnItemId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.learnItemId,
                                referencedTable: $$ReviewLogTableReferences
                                    ._learnItemIdTable(db),
                                referencedColumn: $$ReviewLogTableReferences
                                    ._learnItemIdTable(db)
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

typedef $$ReviewLogTableProcessedTableManager =
    ProcessedTableManager<
      _$LearningDb,
      $ReviewLogTable,
      ReviewLogData,
      $$ReviewLogTableFilterComposer,
      $$ReviewLogTableOrderingComposer,
      $$ReviewLogTableAnnotationComposer,
      $$ReviewLogTableCreateCompanionBuilder,
      $$ReviewLogTableUpdateCompanionBuilder,
      (ReviewLogData, $$ReviewLogTableReferences),
      ReviewLogData,
      PrefetchHooks Function({bool learnItemId})
    >;

class $LearningDbManager {
  final _$LearningDb _db;
  $LearningDbManager(this._db);
  $$ConceptsTableTableManager get concepts =>
      $$ConceptsTableTableManager(_db, _db.concepts);
  $$AssetsTableTableManager get assets =>
      $$AssetsTableTableManager(_db, _db.assets);
  $$ScriptProfilesTableTableManager get scriptProfiles =>
      $$ScriptProfilesTableTableManager(_db, _db.scriptProfiles);
  $$LanguagesTableTableManager get languages =>
      $$LanguagesTableTableManager(_db, _db.languages);
  $$LexemesTableTableManager get lexemes =>
      $$LexemesTableTableManager(_db, _db.lexemes);
  $$CharactersTableTableManager get characters =>
      $$CharactersTableTableManager(_db, _db.characters);
  $$CharComponentsTableTableManager get charComponents =>
      $$CharComponentsTableTableManager(_db, _db.charComponents);
  $$CanDoGoalsTableTableManager get canDoGoals =>
      $$CanDoGoalsTableTableManager(_db, _db.canDoGoals);
  $$GrammarPointsTableTableManager get grammarPoints =>
      $$GrammarPointsTableTableManager(_db, _db.grammarPoints);
  $$SentencesTableTableManager get sentences =>
      $$SentencesTableTableManager(_db, _db.sentences);
  $$LearnItemsTableTableManager get learnItems =>
      $$LearnItemsTableTableManager(_db, _db.learnItems);
  $$ReviewLogTableTableManager get reviewLog =>
      $$ReviewLogTableTableManager(_db, _db.reviewLog);
}
