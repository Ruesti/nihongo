// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'es_pack_db.dart';

// ignore_for_file: type=lint
class $EsLexemesTable extends EsLexemes
    with TableInfo<$EsLexemesTable, EsLexeme> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EsLexemesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  List<GeneratedColumn> get $columns => [id, form, glossesJson];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'es_lexemes';
  @override
  VerificationContext validateIntegrity(
    Insertable<EsLexeme> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('form')) {
      context.handle(
        _formMeta,
        form.isAcceptableOrUnknown(data['form']!, _formMeta),
      );
    } else if (isInserting) {
      context.missing(_formMeta);
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
  EsLexeme map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EsLexeme(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      form: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}form'],
      )!,
      glossesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}glosses_json'],
      )!,
    );
  }

  @override
  $EsLexemesTable createAlias(String alias) {
    return $EsLexemesTable(attachedDatabase, alias);
  }
}

class EsLexeme extends DataClass implements Insertable<EsLexeme> {
  final String id;
  final String form;
  final String glossesJson;
  const EsLexeme({
    required this.id,
    required this.form,
    required this.glossesJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['form'] = Variable<String>(form);
    map['glosses_json'] = Variable<String>(glossesJson);
    return map;
  }

  EsLexemesCompanion toCompanion(bool nullToAbsent) {
    return EsLexemesCompanion(
      id: Value(id),
      form: Value(form),
      glossesJson: Value(glossesJson),
    );
  }

  factory EsLexeme.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EsLexeme(
      id: serializer.fromJson<String>(json['id']),
      form: serializer.fromJson<String>(json['form']),
      glossesJson: serializer.fromJson<String>(json['glossesJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'form': serializer.toJson<String>(form),
      'glossesJson': serializer.toJson<String>(glossesJson),
    };
  }

  EsLexeme copyWith({String? id, String? form, String? glossesJson}) =>
      EsLexeme(
        id: id ?? this.id,
        form: form ?? this.form,
        glossesJson: glossesJson ?? this.glossesJson,
      );
  EsLexeme copyWithCompanion(EsLexemesCompanion data) {
    return EsLexeme(
      id: data.id.present ? data.id.value : this.id,
      form: data.form.present ? data.form.value : this.form,
      glossesJson: data.glossesJson.present
          ? data.glossesJson.value
          : this.glossesJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EsLexeme(')
          ..write('id: $id, ')
          ..write('form: $form, ')
          ..write('glossesJson: $glossesJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, form, glossesJson);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EsLexeme &&
          other.id == this.id &&
          other.form == this.form &&
          other.glossesJson == this.glossesJson);
}

class EsLexemesCompanion extends UpdateCompanion<EsLexeme> {
  final Value<String> id;
  final Value<String> form;
  final Value<String> glossesJson;
  final Value<int> rowid;
  const EsLexemesCompanion({
    this.id = const Value.absent(),
    this.form = const Value.absent(),
    this.glossesJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EsLexemesCompanion.insert({
    required String id,
    required String form,
    required String glossesJson,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       form = Value(form),
       glossesJson = Value(glossesJson);
  static Insertable<EsLexeme> custom({
    Expression<String>? id,
    Expression<String>? form,
    Expression<String>? glossesJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (form != null) 'form': form,
      if (glossesJson != null) 'glosses_json': glossesJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EsLexemesCompanion copyWith({
    Value<String>? id,
    Value<String>? form,
    Value<String>? glossesJson,
    Value<int>? rowid,
  }) {
    return EsLexemesCompanion(
      id: id ?? this.id,
      form: form ?? this.form,
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
    if (form.present) {
      map['form'] = Variable<String>(form.value);
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
    return (StringBuffer('EsLexemesCompanion(')
          ..write('id: $id, ')
          ..write('form: $form, ')
          ..write('glossesJson: $glossesJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EsFrequencyEntriesTable extends EsFrequencyEntries
    with TableInfo<$EsFrequencyEntriesTable, EsFrequencyEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EsFrequencyEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _lemmaMeta = const VerificationMeta('lemma');
  @override
  late final GeneratedColumn<String> lemma = GeneratedColumn<String>(
    'lemma',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _countMeta = const VerificationMeta('count');
  @override
  late final GeneratedColumn<int> count = GeneratedColumn<int>(
    'count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rankMeta = const VerificationMeta('rank');
  @override
  late final GeneratedColumn<int> rank = GeneratedColumn<int>(
    'rank',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [lemma, count, rank];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'es_frequency_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<EsFrequencyEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('lemma')) {
      context.handle(
        _lemmaMeta,
        lemma.isAcceptableOrUnknown(data['lemma']!, _lemmaMeta),
      );
    } else if (isInserting) {
      context.missing(_lemmaMeta);
    }
    if (data.containsKey('count')) {
      context.handle(
        _countMeta,
        count.isAcceptableOrUnknown(data['count']!, _countMeta),
      );
    } else if (isInserting) {
      context.missing(_countMeta);
    }
    if (data.containsKey('rank')) {
      context.handle(
        _rankMeta,
        rank.isAcceptableOrUnknown(data['rank']!, _rankMeta),
      );
    } else if (isInserting) {
      context.missing(_rankMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {lemma};
  @override
  EsFrequencyEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EsFrequencyEntry(
      lemma: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lemma'],
      )!,
      count: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}count'],
      )!,
      rank: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rank'],
      )!,
    );
  }

  @override
  $EsFrequencyEntriesTable createAlias(String alias) {
    return $EsFrequencyEntriesTable(attachedDatabase, alias);
  }
}

class EsFrequencyEntry extends DataClass
    implements Insertable<EsFrequencyEntry> {
  final String lemma;
  final int count;
  final int rank;
  const EsFrequencyEntry({
    required this.lemma,
    required this.count,
    required this.rank,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['lemma'] = Variable<String>(lemma);
    map['count'] = Variable<int>(count);
    map['rank'] = Variable<int>(rank);
    return map;
  }

  EsFrequencyEntriesCompanion toCompanion(bool nullToAbsent) {
    return EsFrequencyEntriesCompanion(
      lemma: Value(lemma),
      count: Value(count),
      rank: Value(rank),
    );
  }

  factory EsFrequencyEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EsFrequencyEntry(
      lemma: serializer.fromJson<String>(json['lemma']),
      count: serializer.fromJson<int>(json['count']),
      rank: serializer.fromJson<int>(json['rank']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'lemma': serializer.toJson<String>(lemma),
      'count': serializer.toJson<int>(count),
      'rank': serializer.toJson<int>(rank),
    };
  }

  EsFrequencyEntry copyWith({String? lemma, int? count, int? rank}) =>
      EsFrequencyEntry(
        lemma: lemma ?? this.lemma,
        count: count ?? this.count,
        rank: rank ?? this.rank,
      );
  EsFrequencyEntry copyWithCompanion(EsFrequencyEntriesCompanion data) {
    return EsFrequencyEntry(
      lemma: data.lemma.present ? data.lemma.value : this.lemma,
      count: data.count.present ? data.count.value : this.count,
      rank: data.rank.present ? data.rank.value : this.rank,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EsFrequencyEntry(')
          ..write('lemma: $lemma, ')
          ..write('count: $count, ')
          ..write('rank: $rank')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(lemma, count, rank);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EsFrequencyEntry &&
          other.lemma == this.lemma &&
          other.count == this.count &&
          other.rank == this.rank);
}

class EsFrequencyEntriesCompanion extends UpdateCompanion<EsFrequencyEntry> {
  final Value<String> lemma;
  final Value<int> count;
  final Value<int> rank;
  final Value<int> rowid;
  const EsFrequencyEntriesCompanion({
    this.lemma = const Value.absent(),
    this.count = const Value.absent(),
    this.rank = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EsFrequencyEntriesCompanion.insert({
    required String lemma,
    required int count,
    required int rank,
    this.rowid = const Value.absent(),
  }) : lemma = Value(lemma),
       count = Value(count),
       rank = Value(rank);
  static Insertable<EsFrequencyEntry> custom({
    Expression<String>? lemma,
    Expression<int>? count,
    Expression<int>? rank,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (lemma != null) 'lemma': lemma,
      if (count != null) 'count': count,
      if (rank != null) 'rank': rank,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EsFrequencyEntriesCompanion copyWith({
    Value<String>? lemma,
    Value<int>? count,
    Value<int>? rank,
    Value<int>? rowid,
  }) {
    return EsFrequencyEntriesCompanion(
      lemma: lemma ?? this.lemma,
      count: count ?? this.count,
      rank: rank ?? this.rank,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (lemma.present) {
      map['lemma'] = Variable<String>(lemma.value);
    }
    if (count.present) {
      map['count'] = Variable<int>(count.value);
    }
    if (rank.present) {
      map['rank'] = Variable<int>(rank.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EsFrequencyEntriesCompanion(')
          ..write('lemma: $lemma, ')
          ..write('count: $count, ')
          ..write('rank: $rank, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$EsPackDb extends GeneratedDatabase {
  _$EsPackDb(QueryExecutor e) : super(e);
  $EsPackDbManager get managers => $EsPackDbManager(this);
  late final $EsLexemesTable esLexemes = $EsLexemesTable(this);
  late final $EsFrequencyEntriesTable esFrequencyEntries =
      $EsFrequencyEntriesTable(this);
  late final Index esLexemesFormIdx = Index(
    'es_lexemes_form_idx',
    'CREATE INDEX es_lexemes_form_idx ON es_lexemes (form)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    esLexemes,
    esFrequencyEntries,
    esLexemesFormIdx,
  ];
}

typedef $$EsLexemesTableCreateCompanionBuilder =
    EsLexemesCompanion Function({
      required String id,
      required String form,
      required String glossesJson,
      Value<int> rowid,
    });
typedef $$EsLexemesTableUpdateCompanionBuilder =
    EsLexemesCompanion Function({
      Value<String> id,
      Value<String> form,
      Value<String> glossesJson,
      Value<int> rowid,
    });

class $$EsLexemesTableFilterComposer
    extends Composer<_$EsPackDb, $EsLexemesTable> {
  $$EsLexemesTableFilterComposer({
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

  ColumnFilters<String> get glossesJson => $composableBuilder(
    column: $table.glossesJson,
    builder: (column) => ColumnFilters(column),
  );
}

class $$EsLexemesTableOrderingComposer
    extends Composer<_$EsPackDb, $EsLexemesTable> {
  $$EsLexemesTableOrderingComposer({
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

  ColumnOrderings<String> get glossesJson => $composableBuilder(
    column: $table.glossesJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$EsLexemesTableAnnotationComposer
    extends Composer<_$EsPackDb, $EsLexemesTable> {
  $$EsLexemesTableAnnotationComposer({
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

  GeneratedColumn<String> get glossesJson => $composableBuilder(
    column: $table.glossesJson,
    builder: (column) => column,
  );
}

class $$EsLexemesTableTableManager
    extends
        RootTableManager<
          _$EsPackDb,
          $EsLexemesTable,
          EsLexeme,
          $$EsLexemesTableFilterComposer,
          $$EsLexemesTableOrderingComposer,
          $$EsLexemesTableAnnotationComposer,
          $$EsLexemesTableCreateCompanionBuilder,
          $$EsLexemesTableUpdateCompanionBuilder,
          (EsLexeme, BaseReferences<_$EsPackDb, $EsLexemesTable, EsLexeme>),
          EsLexeme,
          PrefetchHooks Function()
        > {
  $$EsLexemesTableTableManager(_$EsPackDb db, $EsLexemesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EsLexemesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EsLexemesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EsLexemesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> form = const Value.absent(),
                Value<String> glossesJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EsLexemesCompanion(
                id: id,
                form: form,
                glossesJson: glossesJson,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String form,
                required String glossesJson,
                Value<int> rowid = const Value.absent(),
              }) => EsLexemesCompanion.insert(
                id: id,
                form: form,
                glossesJson: glossesJson,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$EsLexemesTableProcessedTableManager =
    ProcessedTableManager<
      _$EsPackDb,
      $EsLexemesTable,
      EsLexeme,
      $$EsLexemesTableFilterComposer,
      $$EsLexemesTableOrderingComposer,
      $$EsLexemesTableAnnotationComposer,
      $$EsLexemesTableCreateCompanionBuilder,
      $$EsLexemesTableUpdateCompanionBuilder,
      (EsLexeme, BaseReferences<_$EsPackDb, $EsLexemesTable, EsLexeme>),
      EsLexeme,
      PrefetchHooks Function()
    >;
typedef $$EsFrequencyEntriesTableCreateCompanionBuilder =
    EsFrequencyEntriesCompanion Function({
      required String lemma,
      required int count,
      required int rank,
      Value<int> rowid,
    });
typedef $$EsFrequencyEntriesTableUpdateCompanionBuilder =
    EsFrequencyEntriesCompanion Function({
      Value<String> lemma,
      Value<int> count,
      Value<int> rank,
      Value<int> rowid,
    });

class $$EsFrequencyEntriesTableFilterComposer
    extends Composer<_$EsPackDb, $EsFrequencyEntriesTable> {
  $$EsFrequencyEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get lemma => $composableBuilder(
    column: $table.lemma,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get count => $composableBuilder(
    column: $table.count,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rank => $composableBuilder(
    column: $table.rank,
    builder: (column) => ColumnFilters(column),
  );
}

class $$EsFrequencyEntriesTableOrderingComposer
    extends Composer<_$EsPackDb, $EsFrequencyEntriesTable> {
  $$EsFrequencyEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get lemma => $composableBuilder(
    column: $table.lemma,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get count => $composableBuilder(
    column: $table.count,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rank => $composableBuilder(
    column: $table.rank,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$EsFrequencyEntriesTableAnnotationComposer
    extends Composer<_$EsPackDb, $EsFrequencyEntriesTable> {
  $$EsFrequencyEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get lemma =>
      $composableBuilder(column: $table.lemma, builder: (column) => column);

  GeneratedColumn<int> get count =>
      $composableBuilder(column: $table.count, builder: (column) => column);

  GeneratedColumn<int> get rank =>
      $composableBuilder(column: $table.rank, builder: (column) => column);
}

class $$EsFrequencyEntriesTableTableManager
    extends
        RootTableManager<
          _$EsPackDb,
          $EsFrequencyEntriesTable,
          EsFrequencyEntry,
          $$EsFrequencyEntriesTableFilterComposer,
          $$EsFrequencyEntriesTableOrderingComposer,
          $$EsFrequencyEntriesTableAnnotationComposer,
          $$EsFrequencyEntriesTableCreateCompanionBuilder,
          $$EsFrequencyEntriesTableUpdateCompanionBuilder,
          (
            EsFrequencyEntry,
            BaseReferences<
              _$EsPackDb,
              $EsFrequencyEntriesTable,
              EsFrequencyEntry
            >,
          ),
          EsFrequencyEntry,
          PrefetchHooks Function()
        > {
  $$EsFrequencyEntriesTableTableManager(
    _$EsPackDb db,
    $EsFrequencyEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EsFrequencyEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EsFrequencyEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EsFrequencyEntriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> lemma = const Value.absent(),
                Value<int> count = const Value.absent(),
                Value<int> rank = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EsFrequencyEntriesCompanion(
                lemma: lemma,
                count: count,
                rank: rank,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String lemma,
                required int count,
                required int rank,
                Value<int> rowid = const Value.absent(),
              }) => EsFrequencyEntriesCompanion.insert(
                lemma: lemma,
                count: count,
                rank: rank,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$EsFrequencyEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$EsPackDb,
      $EsFrequencyEntriesTable,
      EsFrequencyEntry,
      $$EsFrequencyEntriesTableFilterComposer,
      $$EsFrequencyEntriesTableOrderingComposer,
      $$EsFrequencyEntriesTableAnnotationComposer,
      $$EsFrequencyEntriesTableCreateCompanionBuilder,
      $$EsFrequencyEntriesTableUpdateCompanionBuilder,
      (
        EsFrequencyEntry,
        BaseReferences<_$EsPackDb, $EsFrequencyEntriesTable, EsFrequencyEntry>,
      ),
      EsFrequencyEntry,
      PrefetchHooks Function()
    >;

class $EsPackDbManager {
  final _$EsPackDb _db;
  $EsPackDbManager(this._db);
  $$EsLexemesTableTableManager get esLexemes =>
      $$EsLexemesTableTableManager(_db, _db.esLexemes);
  $$EsFrequencyEntriesTableTableManager get esFrequencyEntries =>
      $$EsFrequencyEntriesTableTableManager(_db, _db.esFrequencyEntries);
}
