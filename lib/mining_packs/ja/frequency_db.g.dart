// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'frequency_db.dart';

// ignore_for_file: type=lint
class $FrequencyEntriesTable extends FrequencyEntries
    with TableInfo<$FrequencyEntriesTable, FrequencyEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FrequencyEntriesTable(this.attachedDatabase, [this._alias]);
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
  static const String $name = 'frequency_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<FrequencyEntry> instance, {
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
  FrequencyEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FrequencyEntry(
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
  $FrequencyEntriesTable createAlias(String alias) {
    return $FrequencyEntriesTable(attachedDatabase, alias);
  }
}

class FrequencyEntry extends DataClass implements Insertable<FrequencyEntry> {
  final String lemma;
  final int count;
  final int rank;
  const FrequencyEntry({
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

  FrequencyEntriesCompanion toCompanion(bool nullToAbsent) {
    return FrequencyEntriesCompanion(
      lemma: Value(lemma),
      count: Value(count),
      rank: Value(rank),
    );
  }

  factory FrequencyEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FrequencyEntry(
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

  FrequencyEntry copyWith({String? lemma, int? count, int? rank}) =>
      FrequencyEntry(
        lemma: lemma ?? this.lemma,
        count: count ?? this.count,
        rank: rank ?? this.rank,
      );
  FrequencyEntry copyWithCompanion(FrequencyEntriesCompanion data) {
    return FrequencyEntry(
      lemma: data.lemma.present ? data.lemma.value : this.lemma,
      count: data.count.present ? data.count.value : this.count,
      rank: data.rank.present ? data.rank.value : this.rank,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FrequencyEntry(')
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
      (other is FrequencyEntry &&
          other.lemma == this.lemma &&
          other.count == this.count &&
          other.rank == this.rank);
}

class FrequencyEntriesCompanion extends UpdateCompanion<FrequencyEntry> {
  final Value<String> lemma;
  final Value<int> count;
  final Value<int> rank;
  final Value<int> rowid;
  const FrequencyEntriesCompanion({
    this.lemma = const Value.absent(),
    this.count = const Value.absent(),
    this.rank = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FrequencyEntriesCompanion.insert({
    required String lemma,
    required int count,
    required int rank,
    this.rowid = const Value.absent(),
  }) : lemma = Value(lemma),
       count = Value(count),
       rank = Value(rank);
  static Insertable<FrequencyEntry> custom({
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

  FrequencyEntriesCompanion copyWith({
    Value<String>? lemma,
    Value<int>? count,
    Value<int>? rank,
    Value<int>? rowid,
  }) {
    return FrequencyEntriesCompanion(
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
    return (StringBuffer('FrequencyEntriesCompanion(')
          ..write('lemma: $lemma, ')
          ..write('count: $count, ')
          ..write('rank: $rank, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$FrequencyDb extends GeneratedDatabase {
  _$FrequencyDb(QueryExecutor e) : super(e);
  $FrequencyDbManager get managers => $FrequencyDbManager(this);
  late final $FrequencyEntriesTable frequencyEntries = $FrequencyEntriesTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [frequencyEntries];
}

typedef $$FrequencyEntriesTableCreateCompanionBuilder =
    FrequencyEntriesCompanion Function({
      required String lemma,
      required int count,
      required int rank,
      Value<int> rowid,
    });
typedef $$FrequencyEntriesTableUpdateCompanionBuilder =
    FrequencyEntriesCompanion Function({
      Value<String> lemma,
      Value<int> count,
      Value<int> rank,
      Value<int> rowid,
    });

class $$FrequencyEntriesTableFilterComposer
    extends Composer<_$FrequencyDb, $FrequencyEntriesTable> {
  $$FrequencyEntriesTableFilterComposer({
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

class $$FrequencyEntriesTableOrderingComposer
    extends Composer<_$FrequencyDb, $FrequencyEntriesTable> {
  $$FrequencyEntriesTableOrderingComposer({
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

class $$FrequencyEntriesTableAnnotationComposer
    extends Composer<_$FrequencyDb, $FrequencyEntriesTable> {
  $$FrequencyEntriesTableAnnotationComposer({
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

class $$FrequencyEntriesTableTableManager
    extends
        RootTableManager<
          _$FrequencyDb,
          $FrequencyEntriesTable,
          FrequencyEntry,
          $$FrequencyEntriesTableFilterComposer,
          $$FrequencyEntriesTableOrderingComposer,
          $$FrequencyEntriesTableAnnotationComposer,
          $$FrequencyEntriesTableCreateCompanionBuilder,
          $$FrequencyEntriesTableUpdateCompanionBuilder,
          (
            FrequencyEntry,
            BaseReferences<
              _$FrequencyDb,
              $FrequencyEntriesTable,
              FrequencyEntry
            >,
          ),
          FrequencyEntry,
          PrefetchHooks Function()
        > {
  $$FrequencyEntriesTableTableManager(
    _$FrequencyDb db,
    $FrequencyEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FrequencyEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FrequencyEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FrequencyEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> lemma = const Value.absent(),
                Value<int> count = const Value.absent(),
                Value<int> rank = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FrequencyEntriesCompanion(
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
              }) => FrequencyEntriesCompanion.insert(
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

typedef $$FrequencyEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$FrequencyDb,
      $FrequencyEntriesTable,
      FrequencyEntry,
      $$FrequencyEntriesTableFilterComposer,
      $$FrequencyEntriesTableOrderingComposer,
      $$FrequencyEntriesTableAnnotationComposer,
      $$FrequencyEntriesTableCreateCompanionBuilder,
      $$FrequencyEntriesTableUpdateCompanionBuilder,
      (
        FrequencyEntry,
        BaseReferences<_$FrequencyDb, $FrequencyEntriesTable, FrequencyEntry>,
      ),
      FrequencyEntry,
      PrefetchHooks Function()
    >;

class $FrequencyDbManager {
  final _$FrequencyDb _db;
  $FrequencyDbManager(this._db);
  $$FrequencyEntriesTableTableManager get frequencyEntries =>
      $$FrequencyEntriesTableTableManager(_db, _db.frequencyEntries);
}
