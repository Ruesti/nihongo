// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'jmdict_db.dart';

// ignore_for_file: type=lint
class $JmdictEntriesTable extends JmdictEntries
    with TableInfo<$JmdictEntriesTable, JmdictEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $JmdictEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [id];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'jmdict_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<JmdictEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  JmdictEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return JmdictEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
    );
  }

  @override
  $JmdictEntriesTable createAlias(String alias) {
    return $JmdictEntriesTable(attachedDatabase, alias);
  }
}

class JmdictEntry extends DataClass implements Insertable<JmdictEntry> {
  final int id;
  const JmdictEntry({required this.id});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    return map;
  }

  JmdictEntriesCompanion toCompanion(bool nullToAbsent) {
    return JmdictEntriesCompanion(id: Value(id));
  }

  factory JmdictEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return JmdictEntry(id: serializer.fromJson<int>(json['id']));
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{'id': serializer.toJson<int>(id)};
  }

  JmdictEntry copyWith({int? id}) => JmdictEntry(id: id ?? this.id);
  JmdictEntry copyWithCompanion(JmdictEntriesCompanion data) {
    return JmdictEntry(id: data.id.present ? data.id.value : this.id);
  }

  @override
  String toString() {
    return (StringBuffer('JmdictEntry(')
          ..write('id: $id')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => id.hashCode;
  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is JmdictEntry && other.id == this.id);
}

class JmdictEntriesCompanion extends UpdateCompanion<JmdictEntry> {
  final Value<int> id;
  const JmdictEntriesCompanion({this.id = const Value.absent()});
  JmdictEntriesCompanion.insert({this.id = const Value.absent()});
  static Insertable<JmdictEntry> custom({Expression<int>? id}) {
    return RawValuesInsertable({if (id != null) 'id': id});
  }

  JmdictEntriesCompanion copyWith({Value<int>? id}) {
    return JmdictEntriesCompanion(id: id ?? this.id);
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('JmdictEntriesCompanion(')
          ..write('id: $id')
          ..write(')'))
        .toString();
  }
}

class $JmdictLemmasTable extends JmdictLemmas
    with TableInfo<$JmdictLemmasTable, JmdictLemma> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $JmdictLemmasTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entryIdMeta = const VerificationMeta(
    'entryId',
  );
  @override
  late final GeneratedColumn<int> entryId = GeneratedColumn<int>(
    'entry_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES jmdict_entries (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _formMeta = const VerificationMeta('form');
  @override
  late final GeneratedColumn<String> form = GeneratedColumn<String>(
    'form',
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
  @override
  List<GeneratedColumn> get $columns => [id, entryId, form, kind];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'jmdict_lemmas';
  @override
  VerificationContext validateIntegrity(
    Insertable<JmdictLemma> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('entry_id')) {
      context.handle(
        _entryIdMeta,
        entryId.isAcceptableOrUnknown(data['entry_id']!, _entryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entryIdMeta);
    }
    if (data.containsKey('form')) {
      context.handle(
        _formMeta,
        form.isAcceptableOrUnknown(data['form']!, _formMeta),
      );
    } else if (isInserting) {
      context.missing(_formMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  JmdictLemma map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return JmdictLemma(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      entryId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}entry_id'],
      )!,
      form: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}form'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
    );
  }

  @override
  $JmdictLemmasTable createAlias(String alias) {
    return $JmdictLemmasTable(attachedDatabase, alias);
  }
}

class JmdictLemma extends DataClass implements Insertable<JmdictLemma> {
  final String id;
  final int entryId;
  final String form;
  final String kind;
  const JmdictLemma({
    required this.id,
    required this.entryId,
    required this.form,
    required this.kind,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['entry_id'] = Variable<int>(entryId);
    map['form'] = Variable<String>(form);
    map['kind'] = Variable<String>(kind);
    return map;
  }

  JmdictLemmasCompanion toCompanion(bool nullToAbsent) {
    return JmdictLemmasCompanion(
      id: Value(id),
      entryId: Value(entryId),
      form: Value(form),
      kind: Value(kind),
    );
  }

  factory JmdictLemma.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return JmdictLemma(
      id: serializer.fromJson<String>(json['id']),
      entryId: serializer.fromJson<int>(json['entryId']),
      form: serializer.fromJson<String>(json['form']),
      kind: serializer.fromJson<String>(json['kind']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'entryId': serializer.toJson<int>(entryId),
      'form': serializer.toJson<String>(form),
      'kind': serializer.toJson<String>(kind),
    };
  }

  JmdictLemma copyWith({
    String? id,
    int? entryId,
    String? form,
    String? kind,
  }) => JmdictLemma(
    id: id ?? this.id,
    entryId: entryId ?? this.entryId,
    form: form ?? this.form,
    kind: kind ?? this.kind,
  );
  JmdictLemma copyWithCompanion(JmdictLemmasCompanion data) {
    return JmdictLemma(
      id: data.id.present ? data.id.value : this.id,
      entryId: data.entryId.present ? data.entryId.value : this.entryId,
      form: data.form.present ? data.form.value : this.form,
      kind: data.kind.present ? data.kind.value : this.kind,
    );
  }

  @override
  String toString() {
    return (StringBuffer('JmdictLemma(')
          ..write('id: $id, ')
          ..write('entryId: $entryId, ')
          ..write('form: $form, ')
          ..write('kind: $kind')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, entryId, form, kind);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is JmdictLemma &&
          other.id == this.id &&
          other.entryId == this.entryId &&
          other.form == this.form &&
          other.kind == this.kind);
}

class JmdictLemmasCompanion extends UpdateCompanion<JmdictLemma> {
  final Value<String> id;
  final Value<int> entryId;
  final Value<String> form;
  final Value<String> kind;
  final Value<int> rowid;
  const JmdictLemmasCompanion({
    this.id = const Value.absent(),
    this.entryId = const Value.absent(),
    this.form = const Value.absent(),
    this.kind = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  JmdictLemmasCompanion.insert({
    required String id,
    required int entryId,
    required String form,
    required String kind,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       entryId = Value(entryId),
       form = Value(form),
       kind = Value(kind);
  static Insertable<JmdictLemma> custom({
    Expression<String>? id,
    Expression<int>? entryId,
    Expression<String>? form,
    Expression<String>? kind,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (entryId != null) 'entry_id': entryId,
      if (form != null) 'form': form,
      if (kind != null) 'kind': kind,
      if (rowid != null) 'rowid': rowid,
    });
  }

  JmdictLemmasCompanion copyWith({
    Value<String>? id,
    Value<int>? entryId,
    Value<String>? form,
    Value<String>? kind,
    Value<int>? rowid,
  }) {
    return JmdictLemmasCompanion(
      id: id ?? this.id,
      entryId: entryId ?? this.entryId,
      form: form ?? this.form,
      kind: kind ?? this.kind,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (entryId.present) {
      map['entry_id'] = Variable<int>(entryId.value);
    }
    if (form.present) {
      map['form'] = Variable<String>(form.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('JmdictLemmasCompanion(')
          ..write('id: $id, ')
          ..write('entryId: $entryId, ')
          ..write('form: $form, ')
          ..write('kind: $kind, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $JmdictSensesTable extends JmdictSenses
    with TableInfo<$JmdictSensesTable, JmdictSense> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $JmdictSensesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entryIdMeta = const VerificationMeta(
    'entryId',
  );
  @override
  late final GeneratedColumn<int> entryId = GeneratedColumn<int>(
    'entry_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES jmdict_entries (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _senseOrderMeta = const VerificationMeta(
    'senseOrder',
  );
  @override
  late final GeneratedColumn<int> senseOrder = GeneratedColumn<int>(
    'sense_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
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
  static const VerificationMeta _glossesJsonMeta = const VerificationMeta(
    'glossesJson',
  );
  @override
  late final GeneratedColumn<String> glossesJson = GeneratedColumn<String>(
    'glosses_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    entryId,
    senseOrder,
    pos,
    glossesJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'jmdict_senses';
  @override
  VerificationContext validateIntegrity(
    Insertable<JmdictSense> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('entry_id')) {
      context.handle(
        _entryIdMeta,
        entryId.isAcceptableOrUnknown(data['entry_id']!, _entryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entryIdMeta);
    }
    if (data.containsKey('sense_order')) {
      context.handle(
        _senseOrderMeta,
        senseOrder.isAcceptableOrUnknown(data['sense_order']!, _senseOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_senseOrderMeta);
    }
    if (data.containsKey('pos')) {
      context.handle(
        _posMeta,
        pos.isAcceptableOrUnknown(data['pos']!, _posMeta),
      );
    } else if (isInserting) {
      context.missing(_posMeta);
    }
    if (data.containsKey('glosses_json')) {
      context.handle(
        _glossesJsonMeta,
        glossesJson.isAcceptableOrUnknown(
          data['glosses_json']!,
          _glossesJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_glossesJsonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  JmdictSense map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return JmdictSense(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      entryId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}entry_id'],
      )!,
      senseOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sense_order'],
      )!,
      pos: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pos'],
      )!,
      glossesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}glosses_json'],
      )!,
    );
  }

  @override
  $JmdictSensesTable createAlias(String alias) {
    return $JmdictSensesTable(attachedDatabase, alias);
  }
}

class JmdictSense extends DataClass implements Insertable<JmdictSense> {
  final String id;
  final int entryId;
  final int senseOrder;
  final String pos;
  final String glossesJson;
  const JmdictSense({
    required this.id,
    required this.entryId,
    required this.senseOrder,
    required this.pos,
    required this.glossesJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['entry_id'] = Variable<int>(entryId);
    map['sense_order'] = Variable<int>(senseOrder);
    map['pos'] = Variable<String>(pos);
    map['glosses_json'] = Variable<String>(glossesJson);
    return map;
  }

  JmdictSensesCompanion toCompanion(bool nullToAbsent) {
    return JmdictSensesCompanion(
      id: Value(id),
      entryId: Value(entryId),
      senseOrder: Value(senseOrder),
      pos: Value(pos),
      glossesJson: Value(glossesJson),
    );
  }

  factory JmdictSense.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return JmdictSense(
      id: serializer.fromJson<String>(json['id']),
      entryId: serializer.fromJson<int>(json['entryId']),
      senseOrder: serializer.fromJson<int>(json['senseOrder']),
      pos: serializer.fromJson<String>(json['pos']),
      glossesJson: serializer.fromJson<String>(json['glossesJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'entryId': serializer.toJson<int>(entryId),
      'senseOrder': serializer.toJson<int>(senseOrder),
      'pos': serializer.toJson<String>(pos),
      'glossesJson': serializer.toJson<String>(glossesJson),
    };
  }

  JmdictSense copyWith({
    String? id,
    int? entryId,
    int? senseOrder,
    String? pos,
    String? glossesJson,
  }) => JmdictSense(
    id: id ?? this.id,
    entryId: entryId ?? this.entryId,
    senseOrder: senseOrder ?? this.senseOrder,
    pos: pos ?? this.pos,
    glossesJson: glossesJson ?? this.glossesJson,
  );
  JmdictSense copyWithCompanion(JmdictSensesCompanion data) {
    return JmdictSense(
      id: data.id.present ? data.id.value : this.id,
      entryId: data.entryId.present ? data.entryId.value : this.entryId,
      senseOrder: data.senseOrder.present
          ? data.senseOrder.value
          : this.senseOrder,
      pos: data.pos.present ? data.pos.value : this.pos,
      glossesJson: data.glossesJson.present
          ? data.glossesJson.value
          : this.glossesJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('JmdictSense(')
          ..write('id: $id, ')
          ..write('entryId: $entryId, ')
          ..write('senseOrder: $senseOrder, ')
          ..write('pos: $pos, ')
          ..write('glossesJson: $glossesJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, entryId, senseOrder, pos, glossesJson);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is JmdictSense &&
          other.id == this.id &&
          other.entryId == this.entryId &&
          other.senseOrder == this.senseOrder &&
          other.pos == this.pos &&
          other.glossesJson == this.glossesJson);
}

class JmdictSensesCompanion extends UpdateCompanion<JmdictSense> {
  final Value<String> id;
  final Value<int> entryId;
  final Value<int> senseOrder;
  final Value<String> pos;
  final Value<String> glossesJson;
  final Value<int> rowid;
  const JmdictSensesCompanion({
    this.id = const Value.absent(),
    this.entryId = const Value.absent(),
    this.senseOrder = const Value.absent(),
    this.pos = const Value.absent(),
    this.glossesJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  JmdictSensesCompanion.insert({
    required String id,
    required int entryId,
    required int senseOrder,
    required String pos,
    required String glossesJson,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       entryId = Value(entryId),
       senseOrder = Value(senseOrder),
       pos = Value(pos),
       glossesJson = Value(glossesJson);
  static Insertable<JmdictSense> custom({
    Expression<String>? id,
    Expression<int>? entryId,
    Expression<int>? senseOrder,
    Expression<String>? pos,
    Expression<String>? glossesJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (entryId != null) 'entry_id': entryId,
      if (senseOrder != null) 'sense_order': senseOrder,
      if (pos != null) 'pos': pos,
      if (glossesJson != null) 'glosses_json': glossesJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  JmdictSensesCompanion copyWith({
    Value<String>? id,
    Value<int>? entryId,
    Value<int>? senseOrder,
    Value<String>? pos,
    Value<String>? glossesJson,
    Value<int>? rowid,
  }) {
    return JmdictSensesCompanion(
      id: id ?? this.id,
      entryId: entryId ?? this.entryId,
      senseOrder: senseOrder ?? this.senseOrder,
      pos: pos ?? this.pos,
      glossesJson: glossesJson ?? this.glossesJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (entryId.present) {
      map['entry_id'] = Variable<int>(entryId.value);
    }
    if (senseOrder.present) {
      map['sense_order'] = Variable<int>(senseOrder.value);
    }
    if (pos.present) {
      map['pos'] = Variable<String>(pos.value);
    }
    if (glossesJson.present) {
      map['glosses_json'] = Variable<String>(glossesJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('JmdictSensesCompanion(')
          ..write('id: $id, ')
          ..write('entryId: $entryId, ')
          ..write('senseOrder: $senseOrder, ')
          ..write('pos: $pos, ')
          ..write('glossesJson: $glossesJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$JmdictDb extends GeneratedDatabase {
  _$JmdictDb(QueryExecutor e) : super(e);
  $JmdictDbManager get managers => $JmdictDbManager(this);
  late final $JmdictEntriesTable jmdictEntries = $JmdictEntriesTable(this);
  late final $JmdictLemmasTable jmdictLemmas = $JmdictLemmasTable(this);
  late final $JmdictSensesTable jmdictSenses = $JmdictSensesTable(this);
  late final Index jmdictLemmasFormIdx = Index(
    'jmdict_lemmas_form_idx',
    'CREATE INDEX jmdict_lemmas_form_idx ON jmdict_lemmas (form)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    jmdictEntries,
    jmdictLemmas,
    jmdictSenses,
    jmdictLemmasFormIdx,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'jmdict_entries',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('jmdict_lemmas', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'jmdict_entries',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('jmdict_senses', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$JmdictEntriesTableCreateCompanionBuilder =
    JmdictEntriesCompanion Function({Value<int> id});
typedef $$JmdictEntriesTableUpdateCompanionBuilder =
    JmdictEntriesCompanion Function({Value<int> id});

final class $$JmdictEntriesTableReferences
    extends BaseReferences<_$JmdictDb, $JmdictEntriesTable, JmdictEntry> {
  $$JmdictEntriesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$JmdictLemmasTable, List<JmdictLemma>>
  _jmdictLemmasRefsTable(_$JmdictDb db) => MultiTypedResultKey.fromTable(
    db.jmdictLemmas,
    aliasName: $_aliasNameGenerator(
      db.jmdictEntries.id,
      db.jmdictLemmas.entryId,
    ),
  );

  $$JmdictLemmasTableProcessedTableManager get jmdictLemmasRefs {
    final manager = $$JmdictLemmasTableTableManager(
      $_db,
      $_db.jmdictLemmas,
    ).filter((f) => f.entryId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_jmdictLemmasRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$JmdictSensesTable, List<JmdictSense>>
  _jmdictSensesRefsTable(_$JmdictDb db) => MultiTypedResultKey.fromTable(
    db.jmdictSenses,
    aliasName: $_aliasNameGenerator(
      db.jmdictEntries.id,
      db.jmdictSenses.entryId,
    ),
  );

  $$JmdictSensesTableProcessedTableManager get jmdictSensesRefs {
    final manager = $$JmdictSensesTableTableManager(
      $_db,
      $_db.jmdictSenses,
    ).filter((f) => f.entryId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_jmdictSensesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$JmdictEntriesTableFilterComposer
    extends Composer<_$JmdictDb, $JmdictEntriesTable> {
  $$JmdictEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> jmdictLemmasRefs(
    Expression<bool> Function($$JmdictLemmasTableFilterComposer f) f,
  ) {
    final $$JmdictLemmasTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.jmdictLemmas,
      getReferencedColumn: (t) => t.entryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$JmdictLemmasTableFilterComposer(
            $db: $db,
            $table: $db.jmdictLemmas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> jmdictSensesRefs(
    Expression<bool> Function($$JmdictSensesTableFilterComposer f) f,
  ) {
    final $$JmdictSensesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.jmdictSenses,
      getReferencedColumn: (t) => t.entryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$JmdictSensesTableFilterComposer(
            $db: $db,
            $table: $db.jmdictSenses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$JmdictEntriesTableOrderingComposer
    extends Composer<_$JmdictDb, $JmdictEntriesTable> {
  $$JmdictEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$JmdictEntriesTableAnnotationComposer
    extends Composer<_$JmdictDb, $JmdictEntriesTable> {
  $$JmdictEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  Expression<T> jmdictLemmasRefs<T extends Object>(
    Expression<T> Function($$JmdictLemmasTableAnnotationComposer a) f,
  ) {
    final $$JmdictLemmasTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.jmdictLemmas,
      getReferencedColumn: (t) => t.entryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$JmdictLemmasTableAnnotationComposer(
            $db: $db,
            $table: $db.jmdictLemmas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> jmdictSensesRefs<T extends Object>(
    Expression<T> Function($$JmdictSensesTableAnnotationComposer a) f,
  ) {
    final $$JmdictSensesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.jmdictSenses,
      getReferencedColumn: (t) => t.entryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$JmdictSensesTableAnnotationComposer(
            $db: $db,
            $table: $db.jmdictSenses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$JmdictEntriesTableTableManager
    extends
        RootTableManager<
          _$JmdictDb,
          $JmdictEntriesTable,
          JmdictEntry,
          $$JmdictEntriesTableFilterComposer,
          $$JmdictEntriesTableOrderingComposer,
          $$JmdictEntriesTableAnnotationComposer,
          $$JmdictEntriesTableCreateCompanionBuilder,
          $$JmdictEntriesTableUpdateCompanionBuilder,
          (JmdictEntry, $$JmdictEntriesTableReferences),
          JmdictEntry,
          PrefetchHooks Function({bool jmdictLemmasRefs, bool jmdictSensesRefs})
        > {
  $$JmdictEntriesTableTableManager(_$JmdictDb db, $JmdictEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$JmdictEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$JmdictEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$JmdictEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({Value<int> id = const Value.absent()}) =>
              JmdictEntriesCompanion(id: id),
          createCompanionCallback: ({Value<int> id = const Value.absent()}) =>
              JmdictEntriesCompanion.insert(id: id),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$JmdictEntriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({jmdictLemmasRefs = false, jmdictSensesRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (jmdictLemmasRefs) db.jmdictLemmas,
                    if (jmdictSensesRefs) db.jmdictSenses,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (jmdictLemmasRefs)
                        await $_getPrefetchedData<
                          JmdictEntry,
                          $JmdictEntriesTable,
                          JmdictLemma
                        >(
                          currentTable: table,
                          referencedTable: $$JmdictEntriesTableReferences
                              ._jmdictLemmasRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$JmdictEntriesTableReferences(
                                db,
                                table,
                                p0,
                              ).jmdictLemmasRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.entryId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (jmdictSensesRefs)
                        await $_getPrefetchedData<
                          JmdictEntry,
                          $JmdictEntriesTable,
                          JmdictSense
                        >(
                          currentTable: table,
                          referencedTable: $$JmdictEntriesTableReferences
                              ._jmdictSensesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$JmdictEntriesTableReferences(
                                db,
                                table,
                                p0,
                              ).jmdictSensesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.entryId == item.id,
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

typedef $$JmdictEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$JmdictDb,
      $JmdictEntriesTable,
      JmdictEntry,
      $$JmdictEntriesTableFilterComposer,
      $$JmdictEntriesTableOrderingComposer,
      $$JmdictEntriesTableAnnotationComposer,
      $$JmdictEntriesTableCreateCompanionBuilder,
      $$JmdictEntriesTableUpdateCompanionBuilder,
      (JmdictEntry, $$JmdictEntriesTableReferences),
      JmdictEntry,
      PrefetchHooks Function({bool jmdictLemmasRefs, bool jmdictSensesRefs})
    >;
typedef $$JmdictLemmasTableCreateCompanionBuilder =
    JmdictLemmasCompanion Function({
      required String id,
      required int entryId,
      required String form,
      required String kind,
      Value<int> rowid,
    });
typedef $$JmdictLemmasTableUpdateCompanionBuilder =
    JmdictLemmasCompanion Function({
      Value<String> id,
      Value<int> entryId,
      Value<String> form,
      Value<String> kind,
      Value<int> rowid,
    });

final class $$JmdictLemmasTableReferences
    extends BaseReferences<_$JmdictDb, $JmdictLemmasTable, JmdictLemma> {
  $$JmdictLemmasTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $JmdictEntriesTable _entryIdTable(_$JmdictDb db) =>
      db.jmdictEntries.createAlias(
        $_aliasNameGenerator(db.jmdictLemmas.entryId, db.jmdictEntries.id),
      );

  $$JmdictEntriesTableProcessedTableManager get entryId {
    final $_column = $_itemColumn<int>('entry_id')!;

    final manager = $$JmdictEntriesTableTableManager(
      $_db,
      $_db.jmdictEntries,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_entryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$JmdictLemmasTableFilterComposer
    extends Composer<_$JmdictDb, $JmdictLemmasTable> {
  $$JmdictLemmasTableFilterComposer({
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

  ColumnFilters<String> get form => $composableBuilder(
    column: $table.form,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  $$JmdictEntriesTableFilterComposer get entryId {
    final $$JmdictEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.entryId,
      referencedTable: $db.jmdictEntries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$JmdictEntriesTableFilterComposer(
            $db: $db,
            $table: $db.jmdictEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$JmdictLemmasTableOrderingComposer
    extends Composer<_$JmdictDb, $JmdictLemmasTable> {
  $$JmdictLemmasTableOrderingComposer({
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

  ColumnOrderings<String> get form => $composableBuilder(
    column: $table.form,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  $$JmdictEntriesTableOrderingComposer get entryId {
    final $$JmdictEntriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.entryId,
      referencedTable: $db.jmdictEntries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$JmdictEntriesTableOrderingComposer(
            $db: $db,
            $table: $db.jmdictEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$JmdictLemmasTableAnnotationComposer
    extends Composer<_$JmdictDb, $JmdictLemmasTable> {
  $$JmdictLemmasTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get form =>
      $composableBuilder(column: $table.form, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  $$JmdictEntriesTableAnnotationComposer get entryId {
    final $$JmdictEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.entryId,
      referencedTable: $db.jmdictEntries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$JmdictEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.jmdictEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$JmdictLemmasTableTableManager
    extends
        RootTableManager<
          _$JmdictDb,
          $JmdictLemmasTable,
          JmdictLemma,
          $$JmdictLemmasTableFilterComposer,
          $$JmdictLemmasTableOrderingComposer,
          $$JmdictLemmasTableAnnotationComposer,
          $$JmdictLemmasTableCreateCompanionBuilder,
          $$JmdictLemmasTableUpdateCompanionBuilder,
          (JmdictLemma, $$JmdictLemmasTableReferences),
          JmdictLemma,
          PrefetchHooks Function({bool entryId})
        > {
  $$JmdictLemmasTableTableManager(_$JmdictDb db, $JmdictLemmasTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$JmdictLemmasTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$JmdictLemmasTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$JmdictLemmasTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> entryId = const Value.absent(),
                Value<String> form = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => JmdictLemmasCompanion(
                id: id,
                entryId: entryId,
                form: form,
                kind: kind,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int entryId,
                required String form,
                required String kind,
                Value<int> rowid = const Value.absent(),
              }) => JmdictLemmasCompanion.insert(
                id: id,
                entryId: entryId,
                form: form,
                kind: kind,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$JmdictLemmasTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({entryId = false}) {
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
                    if (entryId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.entryId,
                                referencedTable: $$JmdictLemmasTableReferences
                                    ._entryIdTable(db),
                                referencedColumn: $$JmdictLemmasTableReferences
                                    ._entryIdTable(db)
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

typedef $$JmdictLemmasTableProcessedTableManager =
    ProcessedTableManager<
      _$JmdictDb,
      $JmdictLemmasTable,
      JmdictLemma,
      $$JmdictLemmasTableFilterComposer,
      $$JmdictLemmasTableOrderingComposer,
      $$JmdictLemmasTableAnnotationComposer,
      $$JmdictLemmasTableCreateCompanionBuilder,
      $$JmdictLemmasTableUpdateCompanionBuilder,
      (JmdictLemma, $$JmdictLemmasTableReferences),
      JmdictLemma,
      PrefetchHooks Function({bool entryId})
    >;
typedef $$JmdictSensesTableCreateCompanionBuilder =
    JmdictSensesCompanion Function({
      required String id,
      required int entryId,
      required int senseOrder,
      required String pos,
      required String glossesJson,
      Value<int> rowid,
    });
typedef $$JmdictSensesTableUpdateCompanionBuilder =
    JmdictSensesCompanion Function({
      Value<String> id,
      Value<int> entryId,
      Value<int> senseOrder,
      Value<String> pos,
      Value<String> glossesJson,
      Value<int> rowid,
    });

final class $$JmdictSensesTableReferences
    extends BaseReferences<_$JmdictDb, $JmdictSensesTable, JmdictSense> {
  $$JmdictSensesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $JmdictEntriesTable _entryIdTable(_$JmdictDb db) =>
      db.jmdictEntries.createAlias(
        $_aliasNameGenerator(db.jmdictSenses.entryId, db.jmdictEntries.id),
      );

  $$JmdictEntriesTableProcessedTableManager get entryId {
    final $_column = $_itemColumn<int>('entry_id')!;

    final manager = $$JmdictEntriesTableTableManager(
      $_db,
      $_db.jmdictEntries,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_entryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$JmdictSensesTableFilterComposer
    extends Composer<_$JmdictDb, $JmdictSensesTable> {
  $$JmdictSensesTableFilterComposer({
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

  ColumnFilters<int> get senseOrder => $composableBuilder(
    column: $table.senseOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pos => $composableBuilder(
    column: $table.pos,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get glossesJson => $composableBuilder(
    column: $table.glossesJson,
    builder: (column) => ColumnFilters(column),
  );

  $$JmdictEntriesTableFilterComposer get entryId {
    final $$JmdictEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.entryId,
      referencedTable: $db.jmdictEntries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$JmdictEntriesTableFilterComposer(
            $db: $db,
            $table: $db.jmdictEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$JmdictSensesTableOrderingComposer
    extends Composer<_$JmdictDb, $JmdictSensesTable> {
  $$JmdictSensesTableOrderingComposer({
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

  ColumnOrderings<int> get senseOrder => $composableBuilder(
    column: $table.senseOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pos => $composableBuilder(
    column: $table.pos,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get glossesJson => $composableBuilder(
    column: $table.glossesJson,
    builder: (column) => ColumnOrderings(column),
  );

  $$JmdictEntriesTableOrderingComposer get entryId {
    final $$JmdictEntriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.entryId,
      referencedTable: $db.jmdictEntries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$JmdictEntriesTableOrderingComposer(
            $db: $db,
            $table: $db.jmdictEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$JmdictSensesTableAnnotationComposer
    extends Composer<_$JmdictDb, $JmdictSensesTable> {
  $$JmdictSensesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get senseOrder => $composableBuilder(
    column: $table.senseOrder,
    builder: (column) => column,
  );

  GeneratedColumn<String> get pos =>
      $composableBuilder(column: $table.pos, builder: (column) => column);

  GeneratedColumn<String> get glossesJson => $composableBuilder(
    column: $table.glossesJson,
    builder: (column) => column,
  );

  $$JmdictEntriesTableAnnotationComposer get entryId {
    final $$JmdictEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.entryId,
      referencedTable: $db.jmdictEntries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$JmdictEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.jmdictEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$JmdictSensesTableTableManager
    extends
        RootTableManager<
          _$JmdictDb,
          $JmdictSensesTable,
          JmdictSense,
          $$JmdictSensesTableFilterComposer,
          $$JmdictSensesTableOrderingComposer,
          $$JmdictSensesTableAnnotationComposer,
          $$JmdictSensesTableCreateCompanionBuilder,
          $$JmdictSensesTableUpdateCompanionBuilder,
          (JmdictSense, $$JmdictSensesTableReferences),
          JmdictSense,
          PrefetchHooks Function({bool entryId})
        > {
  $$JmdictSensesTableTableManager(_$JmdictDb db, $JmdictSensesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$JmdictSensesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$JmdictSensesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$JmdictSensesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> entryId = const Value.absent(),
                Value<int> senseOrder = const Value.absent(),
                Value<String> pos = const Value.absent(),
                Value<String> glossesJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => JmdictSensesCompanion(
                id: id,
                entryId: entryId,
                senseOrder: senseOrder,
                pos: pos,
                glossesJson: glossesJson,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int entryId,
                required int senseOrder,
                required String pos,
                required String glossesJson,
                Value<int> rowid = const Value.absent(),
              }) => JmdictSensesCompanion.insert(
                id: id,
                entryId: entryId,
                senseOrder: senseOrder,
                pos: pos,
                glossesJson: glossesJson,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$JmdictSensesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({entryId = false}) {
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
                    if (entryId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.entryId,
                                referencedTable: $$JmdictSensesTableReferences
                                    ._entryIdTable(db),
                                referencedColumn: $$JmdictSensesTableReferences
                                    ._entryIdTable(db)
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

typedef $$JmdictSensesTableProcessedTableManager =
    ProcessedTableManager<
      _$JmdictDb,
      $JmdictSensesTable,
      JmdictSense,
      $$JmdictSensesTableFilterComposer,
      $$JmdictSensesTableOrderingComposer,
      $$JmdictSensesTableAnnotationComposer,
      $$JmdictSensesTableCreateCompanionBuilder,
      $$JmdictSensesTableUpdateCompanionBuilder,
      (JmdictSense, $$JmdictSensesTableReferences),
      JmdictSense,
      PrefetchHooks Function({bool entryId})
    >;

class $JmdictDbManager {
  final _$JmdictDb _db;
  $JmdictDbManager(this._db);
  $$JmdictEntriesTableTableManager get jmdictEntries =>
      $$JmdictEntriesTableTableManager(_db, _db.jmdictEntries);
  $$JmdictLemmasTableTableManager get jmdictLemmas =>
      $$JmdictLemmasTableTableManager(_db, _db.jmdictLemmas);
  $$JmdictSensesTableTableManager get jmdictSenses =>
      $$JmdictSensesTableTableManager(_db, _db.jmdictSenses);
}
