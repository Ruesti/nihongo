// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $SrsCardsTable extends SrsCards
    with TableInfo<$SrsCardsTable, SrsCardRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SrsCardsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _cardIdMeta = const VerificationMeta('cardId');
  @override
  late final GeneratedColumn<String> cardId = GeneratedColumn<String>(
    'card_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _frontMeta = const VerificationMeta('front');
  @override
  late final GeneratedColumn<String> front = GeneratedColumn<String>(
    'front',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _backMeta = const VerificationMeta('back');
  @override
  late final GeneratedColumn<String> back = GeneratedColumn<String>(
    'back',
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
  static const VerificationMeta _intervalMeta = const VerificationMeta(
    'interval',
  );
  @override
  late final GeneratedColumn<int> interval = GeneratedColumn<int>(
    'interval',
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
  static const VerificationMeta _dueAtMeta = const VerificationMeta('dueAt');
  @override
  late final GeneratedColumn<int> dueAt = GeneratedColumn<int>(
    'due_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _cardTypeMeta = const VerificationMeta(
    'cardType',
  );
  @override
  late final GeneratedColumn<String> cardType = GeneratedColumn<String>(
    'card_type',
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
    requiredDuringInsert: false,
    defaultValue: const Constant('ja'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    cardId,
    front,
    back,
    reading,
    ease,
    interval,
    reps,
    dueAt,
    cardType,
    languageCode,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'srs_cards';
  @override
  VerificationContext validateIntegrity(
    Insertable<SrsCardRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('card_id')) {
      context.handle(
        _cardIdMeta,
        cardId.isAcceptableOrUnknown(data['card_id']!, _cardIdMeta),
      );
    } else if (isInserting) {
      context.missing(_cardIdMeta);
    }
    if (data.containsKey('front')) {
      context.handle(
        _frontMeta,
        front.isAcceptableOrUnknown(data['front']!, _frontMeta),
      );
    } else if (isInserting) {
      context.missing(_frontMeta);
    }
    if (data.containsKey('back')) {
      context.handle(
        _backMeta,
        back.isAcceptableOrUnknown(data['back']!, _backMeta),
      );
    } else if (isInserting) {
      context.missing(_backMeta);
    }
    if (data.containsKey('reading')) {
      context.handle(
        _readingMeta,
        reading.isAcceptableOrUnknown(data['reading']!, _readingMeta),
      );
    }
    if (data.containsKey('ease')) {
      context.handle(
        _easeMeta,
        ease.isAcceptableOrUnknown(data['ease']!, _easeMeta),
      );
    }
    if (data.containsKey('interval')) {
      context.handle(
        _intervalMeta,
        interval.isAcceptableOrUnknown(data['interval']!, _intervalMeta),
      );
    }
    if (data.containsKey('reps')) {
      context.handle(
        _repsMeta,
        reps.isAcceptableOrUnknown(data['reps']!, _repsMeta),
      );
    }
    if (data.containsKey('due_at')) {
      context.handle(
        _dueAtMeta,
        dueAt.isAcceptableOrUnknown(data['due_at']!, _dueAtMeta),
      );
    }
    if (data.containsKey('card_type')) {
      context.handle(
        _cardTypeMeta,
        cardType.isAcceptableOrUnknown(data['card_type']!, _cardTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_cardTypeMeta);
    }
    if (data.containsKey('language_code')) {
      context.handle(
        _languageCodeMeta,
        languageCode.isAcceptableOrUnknown(
          data['language_code']!,
          _languageCodeMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {cardId, languageCode},
  ];
  @override
  SrsCardRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SrsCardRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      cardId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}card_id'],
      )!,
      front: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}front'],
      )!,
      back: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}back'],
      )!,
      reading: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reading'],
      ),
      ease: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}ease'],
      )!,
      interval: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}interval'],
      )!,
      reps: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reps'],
      )!,
      dueAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}due_at'],
      )!,
      cardType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}card_type'],
      )!,
      languageCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}language_code'],
      )!,
    );
  }

  @override
  $SrsCardsTable createAlias(String alias) {
    return $SrsCardsTable(attachedDatabase, alias);
  }
}

class SrsCardRow extends DataClass implements Insertable<SrsCardRow> {
  final int id;
  final String cardId;
  final String front;
  final String back;
  final String? reading;
  final double ease;
  final int interval;
  final int reps;
  final int dueAt;
  final String cardType;
  final String languageCode;
  const SrsCardRow({
    required this.id,
    required this.cardId,
    required this.front,
    required this.back,
    this.reading,
    required this.ease,
    required this.interval,
    required this.reps,
    required this.dueAt,
    required this.cardType,
    required this.languageCode,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['card_id'] = Variable<String>(cardId);
    map['front'] = Variable<String>(front);
    map['back'] = Variable<String>(back);
    if (!nullToAbsent || reading != null) {
      map['reading'] = Variable<String>(reading);
    }
    map['ease'] = Variable<double>(ease);
    map['interval'] = Variable<int>(interval);
    map['reps'] = Variable<int>(reps);
    map['due_at'] = Variable<int>(dueAt);
    map['card_type'] = Variable<String>(cardType);
    map['language_code'] = Variable<String>(languageCode);
    return map;
  }

  SrsCardsCompanion toCompanion(bool nullToAbsent) {
    return SrsCardsCompanion(
      id: Value(id),
      cardId: Value(cardId),
      front: Value(front),
      back: Value(back),
      reading: reading == null && nullToAbsent
          ? const Value.absent()
          : Value(reading),
      ease: Value(ease),
      interval: Value(interval),
      reps: Value(reps),
      dueAt: Value(dueAt),
      cardType: Value(cardType),
      languageCode: Value(languageCode),
    );
  }

  factory SrsCardRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SrsCardRow(
      id: serializer.fromJson<int>(json['id']),
      cardId: serializer.fromJson<String>(json['cardId']),
      front: serializer.fromJson<String>(json['front']),
      back: serializer.fromJson<String>(json['back']),
      reading: serializer.fromJson<String?>(json['reading']),
      ease: serializer.fromJson<double>(json['ease']),
      interval: serializer.fromJson<int>(json['interval']),
      reps: serializer.fromJson<int>(json['reps']),
      dueAt: serializer.fromJson<int>(json['dueAt']),
      cardType: serializer.fromJson<String>(json['cardType']),
      languageCode: serializer.fromJson<String>(json['languageCode']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'cardId': serializer.toJson<String>(cardId),
      'front': serializer.toJson<String>(front),
      'back': serializer.toJson<String>(back),
      'reading': serializer.toJson<String?>(reading),
      'ease': serializer.toJson<double>(ease),
      'interval': serializer.toJson<int>(interval),
      'reps': serializer.toJson<int>(reps),
      'dueAt': serializer.toJson<int>(dueAt),
      'cardType': serializer.toJson<String>(cardType),
      'languageCode': serializer.toJson<String>(languageCode),
    };
  }

  SrsCardRow copyWith({
    int? id,
    String? cardId,
    String? front,
    String? back,
    Value<String?> reading = const Value.absent(),
    double? ease,
    int? interval,
    int? reps,
    int? dueAt,
    String? cardType,
    String? languageCode,
  }) => SrsCardRow(
    id: id ?? this.id,
    cardId: cardId ?? this.cardId,
    front: front ?? this.front,
    back: back ?? this.back,
    reading: reading.present ? reading.value : this.reading,
    ease: ease ?? this.ease,
    interval: interval ?? this.interval,
    reps: reps ?? this.reps,
    dueAt: dueAt ?? this.dueAt,
    cardType: cardType ?? this.cardType,
    languageCode: languageCode ?? this.languageCode,
  );
  SrsCardRow copyWithCompanion(SrsCardsCompanion data) {
    return SrsCardRow(
      id: data.id.present ? data.id.value : this.id,
      cardId: data.cardId.present ? data.cardId.value : this.cardId,
      front: data.front.present ? data.front.value : this.front,
      back: data.back.present ? data.back.value : this.back,
      reading: data.reading.present ? data.reading.value : this.reading,
      ease: data.ease.present ? data.ease.value : this.ease,
      interval: data.interval.present ? data.interval.value : this.interval,
      reps: data.reps.present ? data.reps.value : this.reps,
      dueAt: data.dueAt.present ? data.dueAt.value : this.dueAt,
      cardType: data.cardType.present ? data.cardType.value : this.cardType,
      languageCode: data.languageCode.present
          ? data.languageCode.value
          : this.languageCode,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SrsCardRow(')
          ..write('id: $id, ')
          ..write('cardId: $cardId, ')
          ..write('front: $front, ')
          ..write('back: $back, ')
          ..write('reading: $reading, ')
          ..write('ease: $ease, ')
          ..write('interval: $interval, ')
          ..write('reps: $reps, ')
          ..write('dueAt: $dueAt, ')
          ..write('cardType: $cardType, ')
          ..write('languageCode: $languageCode')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    cardId,
    front,
    back,
    reading,
    ease,
    interval,
    reps,
    dueAt,
    cardType,
    languageCode,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SrsCardRow &&
          other.id == this.id &&
          other.cardId == this.cardId &&
          other.front == this.front &&
          other.back == this.back &&
          other.reading == this.reading &&
          other.ease == this.ease &&
          other.interval == this.interval &&
          other.reps == this.reps &&
          other.dueAt == this.dueAt &&
          other.cardType == this.cardType &&
          other.languageCode == this.languageCode);
}

class SrsCardsCompanion extends UpdateCompanion<SrsCardRow> {
  final Value<int> id;
  final Value<String> cardId;
  final Value<String> front;
  final Value<String> back;
  final Value<String?> reading;
  final Value<double> ease;
  final Value<int> interval;
  final Value<int> reps;
  final Value<int> dueAt;
  final Value<String> cardType;
  final Value<String> languageCode;
  const SrsCardsCompanion({
    this.id = const Value.absent(),
    this.cardId = const Value.absent(),
    this.front = const Value.absent(),
    this.back = const Value.absent(),
    this.reading = const Value.absent(),
    this.ease = const Value.absent(),
    this.interval = const Value.absent(),
    this.reps = const Value.absent(),
    this.dueAt = const Value.absent(),
    this.cardType = const Value.absent(),
    this.languageCode = const Value.absent(),
  });
  SrsCardsCompanion.insert({
    this.id = const Value.absent(),
    required String cardId,
    required String front,
    required String back,
    this.reading = const Value.absent(),
    this.ease = const Value.absent(),
    this.interval = const Value.absent(),
    this.reps = const Value.absent(),
    this.dueAt = const Value.absent(),
    required String cardType,
    this.languageCode = const Value.absent(),
  }) : cardId = Value(cardId),
       front = Value(front),
       back = Value(back),
       cardType = Value(cardType);
  static Insertable<SrsCardRow> custom({
    Expression<int>? id,
    Expression<String>? cardId,
    Expression<String>? front,
    Expression<String>? back,
    Expression<String>? reading,
    Expression<double>? ease,
    Expression<int>? interval,
    Expression<int>? reps,
    Expression<int>? dueAt,
    Expression<String>? cardType,
    Expression<String>? languageCode,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (cardId != null) 'card_id': cardId,
      if (front != null) 'front': front,
      if (back != null) 'back': back,
      if (reading != null) 'reading': reading,
      if (ease != null) 'ease': ease,
      if (interval != null) 'interval': interval,
      if (reps != null) 'reps': reps,
      if (dueAt != null) 'due_at': dueAt,
      if (cardType != null) 'card_type': cardType,
      if (languageCode != null) 'language_code': languageCode,
    });
  }

  SrsCardsCompanion copyWith({
    Value<int>? id,
    Value<String>? cardId,
    Value<String>? front,
    Value<String>? back,
    Value<String?>? reading,
    Value<double>? ease,
    Value<int>? interval,
    Value<int>? reps,
    Value<int>? dueAt,
    Value<String>? cardType,
    Value<String>? languageCode,
  }) {
    return SrsCardsCompanion(
      id: id ?? this.id,
      cardId: cardId ?? this.cardId,
      front: front ?? this.front,
      back: back ?? this.back,
      reading: reading ?? this.reading,
      ease: ease ?? this.ease,
      interval: interval ?? this.interval,
      reps: reps ?? this.reps,
      dueAt: dueAt ?? this.dueAt,
      cardType: cardType ?? this.cardType,
      languageCode: languageCode ?? this.languageCode,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (cardId.present) {
      map['card_id'] = Variable<String>(cardId.value);
    }
    if (front.present) {
      map['front'] = Variable<String>(front.value);
    }
    if (back.present) {
      map['back'] = Variable<String>(back.value);
    }
    if (reading.present) {
      map['reading'] = Variable<String>(reading.value);
    }
    if (ease.present) {
      map['ease'] = Variable<double>(ease.value);
    }
    if (interval.present) {
      map['interval'] = Variable<int>(interval.value);
    }
    if (reps.present) {
      map['reps'] = Variable<int>(reps.value);
    }
    if (dueAt.present) {
      map['due_at'] = Variable<int>(dueAt.value);
    }
    if (cardType.present) {
      map['card_type'] = Variable<String>(cardType.value);
    }
    if (languageCode.present) {
      map['language_code'] = Variable<String>(languageCode.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SrsCardsCompanion(')
          ..write('id: $id, ')
          ..write('cardId: $cardId, ')
          ..write('front: $front, ')
          ..write('back: $back, ')
          ..write('reading: $reading, ')
          ..write('ease: $ease, ')
          ..write('interval: $interval, ')
          ..write('reps: $reps, ')
          ..write('dueAt: $dueAt, ')
          ..write('cardType: $cardType, ')
          ..write('languageCode: $languageCode')
          ..write(')'))
        .toString();
  }
}

class $LessonProgressTable extends LessonProgress
    with TableInfo<$LessonProgressTable, LessonProgressData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LessonProgressTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _lessonIdMeta = const VerificationMeta(
    'lessonId',
  );
  @override
  late final GeneratedColumn<int> lessonId = GeneratedColumn<int>(
    'lesson_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
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
    requiredDuringInsert: false,
    defaultValue: const Constant('ja'),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<int> status = GeneratedColumn<int>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _accuracyMeta = const VerificationMeta(
    'accuracy',
  );
  @override
  late final GeneratedColumn<int> accuracy = GeneratedColumn<int>(
    'accuracy',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _xpEarnedMeta = const VerificationMeta(
    'xpEarned',
  );
  @override
  late final GeneratedColumn<int> xpEarned = GeneratedColumn<int>(
    'xp_earned',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<int> completedAt = GeneratedColumn<int>(
    'completed_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    lessonId,
    languageCode,
    status,
    accuracy,
    xpEarned,
    completedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'lesson_progress';
  @override
  VerificationContext validateIntegrity(
    Insertable<LessonProgressData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('lesson_id')) {
      context.handle(
        _lessonIdMeta,
        lessonId.isAcceptableOrUnknown(data['lesson_id']!, _lessonIdMeta),
      );
    } else if (isInserting) {
      context.missing(_lessonIdMeta);
    }
    if (data.containsKey('language_code')) {
      context.handle(
        _languageCodeMeta,
        languageCode.isAcceptableOrUnknown(
          data['language_code']!,
          _languageCodeMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('accuracy')) {
      context.handle(
        _accuracyMeta,
        accuracy.isAcceptableOrUnknown(data['accuracy']!, _accuracyMeta),
      );
    }
    if (data.containsKey('xp_earned')) {
      context.handle(
        _xpEarnedMeta,
        xpEarned.isAcceptableOrUnknown(data['xp_earned']!, _xpEarnedMeta),
      );
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {lessonId, languageCode},
  ];
  @override
  LessonProgressData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LessonProgressData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      lessonId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}lesson_id'],
      )!,
      languageCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}language_code'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}status'],
      )!,
      accuracy: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}accuracy'],
      )!,
      xpEarned: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}xp_earned'],
      )!,
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}completed_at'],
      )!,
    );
  }

  @override
  $LessonProgressTable createAlias(String alias) {
    return $LessonProgressTable(attachedDatabase, alias);
  }
}

class LessonProgressData extends DataClass
    implements Insertable<LessonProgressData> {
  final int id;
  final int lessonId;
  final String languageCode;
  final int status;
  final int accuracy;
  final int xpEarned;
  final int completedAt;
  const LessonProgressData({
    required this.id,
    required this.lessonId,
    required this.languageCode,
    required this.status,
    required this.accuracy,
    required this.xpEarned,
    required this.completedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['lesson_id'] = Variable<int>(lessonId);
    map['language_code'] = Variable<String>(languageCode);
    map['status'] = Variable<int>(status);
    map['accuracy'] = Variable<int>(accuracy);
    map['xp_earned'] = Variable<int>(xpEarned);
    map['completed_at'] = Variable<int>(completedAt);
    return map;
  }

  LessonProgressCompanion toCompanion(bool nullToAbsent) {
    return LessonProgressCompanion(
      id: Value(id),
      lessonId: Value(lessonId),
      languageCode: Value(languageCode),
      status: Value(status),
      accuracy: Value(accuracy),
      xpEarned: Value(xpEarned),
      completedAt: Value(completedAt),
    );
  }

  factory LessonProgressData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LessonProgressData(
      id: serializer.fromJson<int>(json['id']),
      lessonId: serializer.fromJson<int>(json['lessonId']),
      languageCode: serializer.fromJson<String>(json['languageCode']),
      status: serializer.fromJson<int>(json['status']),
      accuracy: serializer.fromJson<int>(json['accuracy']),
      xpEarned: serializer.fromJson<int>(json['xpEarned']),
      completedAt: serializer.fromJson<int>(json['completedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'lessonId': serializer.toJson<int>(lessonId),
      'languageCode': serializer.toJson<String>(languageCode),
      'status': serializer.toJson<int>(status),
      'accuracy': serializer.toJson<int>(accuracy),
      'xpEarned': serializer.toJson<int>(xpEarned),
      'completedAt': serializer.toJson<int>(completedAt),
    };
  }

  LessonProgressData copyWith({
    int? id,
    int? lessonId,
    String? languageCode,
    int? status,
    int? accuracy,
    int? xpEarned,
    int? completedAt,
  }) => LessonProgressData(
    id: id ?? this.id,
    lessonId: lessonId ?? this.lessonId,
    languageCode: languageCode ?? this.languageCode,
    status: status ?? this.status,
    accuracy: accuracy ?? this.accuracy,
    xpEarned: xpEarned ?? this.xpEarned,
    completedAt: completedAt ?? this.completedAt,
  );
  LessonProgressData copyWithCompanion(LessonProgressCompanion data) {
    return LessonProgressData(
      id: data.id.present ? data.id.value : this.id,
      lessonId: data.lessonId.present ? data.lessonId.value : this.lessonId,
      languageCode: data.languageCode.present
          ? data.languageCode.value
          : this.languageCode,
      status: data.status.present ? data.status.value : this.status,
      accuracy: data.accuracy.present ? data.accuracy.value : this.accuracy,
      xpEarned: data.xpEarned.present ? data.xpEarned.value : this.xpEarned,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LessonProgressData(')
          ..write('id: $id, ')
          ..write('lessonId: $lessonId, ')
          ..write('languageCode: $languageCode, ')
          ..write('status: $status, ')
          ..write('accuracy: $accuracy, ')
          ..write('xpEarned: $xpEarned, ')
          ..write('completedAt: $completedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    lessonId,
    languageCode,
    status,
    accuracy,
    xpEarned,
    completedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LessonProgressData &&
          other.id == this.id &&
          other.lessonId == this.lessonId &&
          other.languageCode == this.languageCode &&
          other.status == this.status &&
          other.accuracy == this.accuracy &&
          other.xpEarned == this.xpEarned &&
          other.completedAt == this.completedAt);
}

class LessonProgressCompanion extends UpdateCompanion<LessonProgressData> {
  final Value<int> id;
  final Value<int> lessonId;
  final Value<String> languageCode;
  final Value<int> status;
  final Value<int> accuracy;
  final Value<int> xpEarned;
  final Value<int> completedAt;
  const LessonProgressCompanion({
    this.id = const Value.absent(),
    this.lessonId = const Value.absent(),
    this.languageCode = const Value.absent(),
    this.status = const Value.absent(),
    this.accuracy = const Value.absent(),
    this.xpEarned = const Value.absent(),
    this.completedAt = const Value.absent(),
  });
  LessonProgressCompanion.insert({
    this.id = const Value.absent(),
    required int lessonId,
    this.languageCode = const Value.absent(),
    this.status = const Value.absent(),
    this.accuracy = const Value.absent(),
    this.xpEarned = const Value.absent(),
    this.completedAt = const Value.absent(),
  }) : lessonId = Value(lessonId);
  static Insertable<LessonProgressData> custom({
    Expression<int>? id,
    Expression<int>? lessonId,
    Expression<String>? languageCode,
    Expression<int>? status,
    Expression<int>? accuracy,
    Expression<int>? xpEarned,
    Expression<int>? completedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (lessonId != null) 'lesson_id': lessonId,
      if (languageCode != null) 'language_code': languageCode,
      if (status != null) 'status': status,
      if (accuracy != null) 'accuracy': accuracy,
      if (xpEarned != null) 'xp_earned': xpEarned,
      if (completedAt != null) 'completed_at': completedAt,
    });
  }

  LessonProgressCompanion copyWith({
    Value<int>? id,
    Value<int>? lessonId,
    Value<String>? languageCode,
    Value<int>? status,
    Value<int>? accuracy,
    Value<int>? xpEarned,
    Value<int>? completedAt,
  }) {
    return LessonProgressCompanion(
      id: id ?? this.id,
      lessonId: lessonId ?? this.lessonId,
      languageCode: languageCode ?? this.languageCode,
      status: status ?? this.status,
      accuracy: accuracy ?? this.accuracy,
      xpEarned: xpEarned ?? this.xpEarned,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (lessonId.present) {
      map['lesson_id'] = Variable<int>(lessonId.value);
    }
    if (languageCode.present) {
      map['language_code'] = Variable<String>(languageCode.value);
    }
    if (status.present) {
      map['status'] = Variable<int>(status.value);
    }
    if (accuracy.present) {
      map['accuracy'] = Variable<int>(accuracy.value);
    }
    if (xpEarned.present) {
      map['xp_earned'] = Variable<int>(xpEarned.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<int>(completedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LessonProgressCompanion(')
          ..write('id: $id, ')
          ..write('lessonId: $lessonId, ')
          ..write('languageCode: $languageCode, ')
          ..write('status: $status, ')
          ..write('accuracy: $accuracy, ')
          ..write('xpEarned: $xpEarned, ')
          ..write('completedAt: $completedAt')
          ..write(')'))
        .toString();
  }
}

class $UserStatsTable extends UserStats
    with TableInfo<$UserStatsTable, UserStat> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserStatsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
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
    requiredDuringInsert: false,
    defaultValue: const Constant('ja'),
  );
  static const VerificationMeta _totalXpMeta = const VerificationMeta(
    'totalXp',
  );
  @override
  late final GeneratedColumn<int> totalXp = GeneratedColumn<int>(
    'total_xp',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _totalCardsLearnedMeta = const VerificationMeta(
    'totalCardsLearned',
  );
  @override
  late final GeneratedColumn<int> totalCardsLearned = GeneratedColumn<int>(
    'total_cards_learned',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _totalSessionsMeta = const VerificationMeta(
    'totalSessions',
  );
  @override
  late final GeneratedColumn<int> totalSessions = GeneratedColumn<int>(
    'total_sessions',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _conversationSessionsMeta =
      const VerificationMeta('conversationSessions');
  @override
  late final GeneratedColumn<int> conversationSessions = GeneratedColumn<int>(
    'conversation_sessions',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastStudiedAtMeta = const VerificationMeta(
    'lastStudiedAt',
  );
  @override
  late final GeneratedColumn<int> lastStudiedAt = GeneratedColumn<int>(
    'last_studied_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    languageCode,
    totalXp,
    totalCardsLearned,
    totalSessions,
    conversationSessions,
    lastStudiedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_stats';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserStat> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('language_code')) {
      context.handle(
        _languageCodeMeta,
        languageCode.isAcceptableOrUnknown(
          data['language_code']!,
          _languageCodeMeta,
        ),
      );
    }
    if (data.containsKey('total_xp')) {
      context.handle(
        _totalXpMeta,
        totalXp.isAcceptableOrUnknown(data['total_xp']!, _totalXpMeta),
      );
    }
    if (data.containsKey('total_cards_learned')) {
      context.handle(
        _totalCardsLearnedMeta,
        totalCardsLearned.isAcceptableOrUnknown(
          data['total_cards_learned']!,
          _totalCardsLearnedMeta,
        ),
      );
    }
    if (data.containsKey('total_sessions')) {
      context.handle(
        _totalSessionsMeta,
        totalSessions.isAcceptableOrUnknown(
          data['total_sessions']!,
          _totalSessionsMeta,
        ),
      );
    }
    if (data.containsKey('conversation_sessions')) {
      context.handle(
        _conversationSessionsMeta,
        conversationSessions.isAcceptableOrUnknown(
          data['conversation_sessions']!,
          _conversationSessionsMeta,
        ),
      );
    }
    if (data.containsKey('last_studied_at')) {
      context.handle(
        _lastStudiedAtMeta,
        lastStudiedAt.isAcceptableOrUnknown(
          data['last_studied_at']!,
          _lastStudiedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {languageCode},
  ];
  @override
  UserStat map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserStat(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      languageCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}language_code'],
      )!,
      totalXp: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_xp'],
      )!,
      totalCardsLearned: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_cards_learned'],
      )!,
      totalSessions: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_sessions'],
      )!,
      conversationSessions: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}conversation_sessions'],
      )!,
      lastStudiedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_studied_at'],
      )!,
    );
  }

  @override
  $UserStatsTable createAlias(String alias) {
    return $UserStatsTable(attachedDatabase, alias);
  }
}

class UserStat extends DataClass implements Insertable<UserStat> {
  final int id;
  final String languageCode;
  final int totalXp;
  final int totalCardsLearned;
  final int totalSessions;
  final int conversationSessions;
  final int lastStudiedAt;
  const UserStat({
    required this.id,
    required this.languageCode,
    required this.totalXp,
    required this.totalCardsLearned,
    required this.totalSessions,
    required this.conversationSessions,
    required this.lastStudiedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['language_code'] = Variable<String>(languageCode);
    map['total_xp'] = Variable<int>(totalXp);
    map['total_cards_learned'] = Variable<int>(totalCardsLearned);
    map['total_sessions'] = Variable<int>(totalSessions);
    map['conversation_sessions'] = Variable<int>(conversationSessions);
    map['last_studied_at'] = Variable<int>(lastStudiedAt);
    return map;
  }

  UserStatsCompanion toCompanion(bool nullToAbsent) {
    return UserStatsCompanion(
      id: Value(id),
      languageCode: Value(languageCode),
      totalXp: Value(totalXp),
      totalCardsLearned: Value(totalCardsLearned),
      totalSessions: Value(totalSessions),
      conversationSessions: Value(conversationSessions),
      lastStudiedAt: Value(lastStudiedAt),
    );
  }

  factory UserStat.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserStat(
      id: serializer.fromJson<int>(json['id']),
      languageCode: serializer.fromJson<String>(json['languageCode']),
      totalXp: serializer.fromJson<int>(json['totalXp']),
      totalCardsLearned: serializer.fromJson<int>(json['totalCardsLearned']),
      totalSessions: serializer.fromJson<int>(json['totalSessions']),
      conversationSessions: serializer.fromJson<int>(
        json['conversationSessions'],
      ),
      lastStudiedAt: serializer.fromJson<int>(json['lastStudiedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'languageCode': serializer.toJson<String>(languageCode),
      'totalXp': serializer.toJson<int>(totalXp),
      'totalCardsLearned': serializer.toJson<int>(totalCardsLearned),
      'totalSessions': serializer.toJson<int>(totalSessions),
      'conversationSessions': serializer.toJson<int>(conversationSessions),
      'lastStudiedAt': serializer.toJson<int>(lastStudiedAt),
    };
  }

  UserStat copyWith({
    int? id,
    String? languageCode,
    int? totalXp,
    int? totalCardsLearned,
    int? totalSessions,
    int? conversationSessions,
    int? lastStudiedAt,
  }) => UserStat(
    id: id ?? this.id,
    languageCode: languageCode ?? this.languageCode,
    totalXp: totalXp ?? this.totalXp,
    totalCardsLearned: totalCardsLearned ?? this.totalCardsLearned,
    totalSessions: totalSessions ?? this.totalSessions,
    conversationSessions: conversationSessions ?? this.conversationSessions,
    lastStudiedAt: lastStudiedAt ?? this.lastStudiedAt,
  );
  UserStat copyWithCompanion(UserStatsCompanion data) {
    return UserStat(
      id: data.id.present ? data.id.value : this.id,
      languageCode: data.languageCode.present
          ? data.languageCode.value
          : this.languageCode,
      totalXp: data.totalXp.present ? data.totalXp.value : this.totalXp,
      totalCardsLearned: data.totalCardsLearned.present
          ? data.totalCardsLearned.value
          : this.totalCardsLearned,
      totalSessions: data.totalSessions.present
          ? data.totalSessions.value
          : this.totalSessions,
      conversationSessions: data.conversationSessions.present
          ? data.conversationSessions.value
          : this.conversationSessions,
      lastStudiedAt: data.lastStudiedAt.present
          ? data.lastStudiedAt.value
          : this.lastStudiedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserStat(')
          ..write('id: $id, ')
          ..write('languageCode: $languageCode, ')
          ..write('totalXp: $totalXp, ')
          ..write('totalCardsLearned: $totalCardsLearned, ')
          ..write('totalSessions: $totalSessions, ')
          ..write('conversationSessions: $conversationSessions, ')
          ..write('lastStudiedAt: $lastStudiedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    languageCode,
    totalXp,
    totalCardsLearned,
    totalSessions,
    conversationSessions,
    lastStudiedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserStat &&
          other.id == this.id &&
          other.languageCode == this.languageCode &&
          other.totalXp == this.totalXp &&
          other.totalCardsLearned == this.totalCardsLearned &&
          other.totalSessions == this.totalSessions &&
          other.conversationSessions == this.conversationSessions &&
          other.lastStudiedAt == this.lastStudiedAt);
}

class UserStatsCompanion extends UpdateCompanion<UserStat> {
  final Value<int> id;
  final Value<String> languageCode;
  final Value<int> totalXp;
  final Value<int> totalCardsLearned;
  final Value<int> totalSessions;
  final Value<int> conversationSessions;
  final Value<int> lastStudiedAt;
  const UserStatsCompanion({
    this.id = const Value.absent(),
    this.languageCode = const Value.absent(),
    this.totalXp = const Value.absent(),
    this.totalCardsLearned = const Value.absent(),
    this.totalSessions = const Value.absent(),
    this.conversationSessions = const Value.absent(),
    this.lastStudiedAt = const Value.absent(),
  });
  UserStatsCompanion.insert({
    this.id = const Value.absent(),
    this.languageCode = const Value.absent(),
    this.totalXp = const Value.absent(),
    this.totalCardsLearned = const Value.absent(),
    this.totalSessions = const Value.absent(),
    this.conversationSessions = const Value.absent(),
    this.lastStudiedAt = const Value.absent(),
  });
  static Insertable<UserStat> custom({
    Expression<int>? id,
    Expression<String>? languageCode,
    Expression<int>? totalXp,
    Expression<int>? totalCardsLearned,
    Expression<int>? totalSessions,
    Expression<int>? conversationSessions,
    Expression<int>? lastStudiedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (languageCode != null) 'language_code': languageCode,
      if (totalXp != null) 'total_xp': totalXp,
      if (totalCardsLearned != null) 'total_cards_learned': totalCardsLearned,
      if (totalSessions != null) 'total_sessions': totalSessions,
      if (conversationSessions != null)
        'conversation_sessions': conversationSessions,
      if (lastStudiedAt != null) 'last_studied_at': lastStudiedAt,
    });
  }

  UserStatsCompanion copyWith({
    Value<int>? id,
    Value<String>? languageCode,
    Value<int>? totalXp,
    Value<int>? totalCardsLearned,
    Value<int>? totalSessions,
    Value<int>? conversationSessions,
    Value<int>? lastStudiedAt,
  }) {
    return UserStatsCompanion(
      id: id ?? this.id,
      languageCode: languageCode ?? this.languageCode,
      totalXp: totalXp ?? this.totalXp,
      totalCardsLearned: totalCardsLearned ?? this.totalCardsLearned,
      totalSessions: totalSessions ?? this.totalSessions,
      conversationSessions: conversationSessions ?? this.conversationSessions,
      lastStudiedAt: lastStudiedAt ?? this.lastStudiedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (languageCode.present) {
      map['language_code'] = Variable<String>(languageCode.value);
    }
    if (totalXp.present) {
      map['total_xp'] = Variable<int>(totalXp.value);
    }
    if (totalCardsLearned.present) {
      map['total_cards_learned'] = Variable<int>(totalCardsLearned.value);
    }
    if (totalSessions.present) {
      map['total_sessions'] = Variable<int>(totalSessions.value);
    }
    if (conversationSessions.present) {
      map['conversation_sessions'] = Variable<int>(conversationSessions.value);
    }
    if (lastStudiedAt.present) {
      map['last_studied_at'] = Variable<int>(lastStudiedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserStatsCompanion(')
          ..write('id: $id, ')
          ..write('languageCode: $languageCode, ')
          ..write('totalXp: $totalXp, ')
          ..write('totalCardsLearned: $totalCardsLearned, ')
          ..write('totalSessions: $totalSessions, ')
          ..write('conversationSessions: $conversationSessions, ')
          ..write('lastStudiedAt: $lastStudiedAt')
          ..write(')'))
        .toString();
  }
}

class $StudyHistoryTable extends StudyHistory
    with TableInfo<$StudyHistoryTable, StudyHistoryData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StudyHistoryTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
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
    requiredDuringInsert: false,
    defaultValue: const Constant('ja'),
  );
  static const VerificationMeta _dayEpochMeta = const VerificationMeta(
    'dayEpoch',
  );
  @override
  late final GeneratedColumn<int> dayEpoch = GeneratedColumn<int>(
    'day_epoch',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cardsStudiedMeta = const VerificationMeta(
    'cardsStudied',
  );
  @override
  late final GeneratedColumn<int> cardsStudied = GeneratedColumn<int>(
    'cards_studied',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _correctAnswersMeta = const VerificationMeta(
    'correctAnswers',
  );
  @override
  late final GeneratedColumn<int> correctAnswers = GeneratedColumn<int>(
    'correct_answers',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _minutesStudiedMeta = const VerificationMeta(
    'minutesStudied',
  );
  @override
  late final GeneratedColumn<int> minutesStudied = GeneratedColumn<int>(
    'minutes_studied',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    languageCode,
    dayEpoch,
    cardsStudied,
    correctAnswers,
    minutesStudied,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'study_history';
  @override
  VerificationContext validateIntegrity(
    Insertable<StudyHistoryData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('language_code')) {
      context.handle(
        _languageCodeMeta,
        languageCode.isAcceptableOrUnknown(
          data['language_code']!,
          _languageCodeMeta,
        ),
      );
    }
    if (data.containsKey('day_epoch')) {
      context.handle(
        _dayEpochMeta,
        dayEpoch.isAcceptableOrUnknown(data['day_epoch']!, _dayEpochMeta),
      );
    } else if (isInserting) {
      context.missing(_dayEpochMeta);
    }
    if (data.containsKey('cards_studied')) {
      context.handle(
        _cardsStudiedMeta,
        cardsStudied.isAcceptableOrUnknown(
          data['cards_studied']!,
          _cardsStudiedMeta,
        ),
      );
    }
    if (data.containsKey('correct_answers')) {
      context.handle(
        _correctAnswersMeta,
        correctAnswers.isAcceptableOrUnknown(
          data['correct_answers']!,
          _correctAnswersMeta,
        ),
      );
    }
    if (data.containsKey('minutes_studied')) {
      context.handle(
        _minutesStudiedMeta,
        minutesStudied.isAcceptableOrUnknown(
          data['minutes_studied']!,
          _minutesStudiedMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {languageCode, dayEpoch},
  ];
  @override
  StudyHistoryData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StudyHistoryData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      languageCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}language_code'],
      )!,
      dayEpoch: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}day_epoch'],
      )!,
      cardsStudied: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cards_studied'],
      )!,
      correctAnswers: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}correct_answers'],
      )!,
      minutesStudied: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}minutes_studied'],
      )!,
    );
  }

  @override
  $StudyHistoryTable createAlias(String alias) {
    return $StudyHistoryTable(attachedDatabase, alias);
  }
}

class StudyHistoryData extends DataClass
    implements Insertable<StudyHistoryData> {
  final int id;
  final String languageCode;
  final int dayEpoch;
  final int cardsStudied;
  final int correctAnswers;
  final int minutesStudied;
  const StudyHistoryData({
    required this.id,
    required this.languageCode,
    required this.dayEpoch,
    required this.cardsStudied,
    required this.correctAnswers,
    required this.minutesStudied,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['language_code'] = Variable<String>(languageCode);
    map['day_epoch'] = Variable<int>(dayEpoch);
    map['cards_studied'] = Variable<int>(cardsStudied);
    map['correct_answers'] = Variable<int>(correctAnswers);
    map['minutes_studied'] = Variable<int>(minutesStudied);
    return map;
  }

  StudyHistoryCompanion toCompanion(bool nullToAbsent) {
    return StudyHistoryCompanion(
      id: Value(id),
      languageCode: Value(languageCode),
      dayEpoch: Value(dayEpoch),
      cardsStudied: Value(cardsStudied),
      correctAnswers: Value(correctAnswers),
      minutesStudied: Value(minutesStudied),
    );
  }

  factory StudyHistoryData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StudyHistoryData(
      id: serializer.fromJson<int>(json['id']),
      languageCode: serializer.fromJson<String>(json['languageCode']),
      dayEpoch: serializer.fromJson<int>(json['dayEpoch']),
      cardsStudied: serializer.fromJson<int>(json['cardsStudied']),
      correctAnswers: serializer.fromJson<int>(json['correctAnswers']),
      minutesStudied: serializer.fromJson<int>(json['minutesStudied']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'languageCode': serializer.toJson<String>(languageCode),
      'dayEpoch': serializer.toJson<int>(dayEpoch),
      'cardsStudied': serializer.toJson<int>(cardsStudied),
      'correctAnswers': serializer.toJson<int>(correctAnswers),
      'minutesStudied': serializer.toJson<int>(minutesStudied),
    };
  }

  StudyHistoryData copyWith({
    int? id,
    String? languageCode,
    int? dayEpoch,
    int? cardsStudied,
    int? correctAnswers,
    int? minutesStudied,
  }) => StudyHistoryData(
    id: id ?? this.id,
    languageCode: languageCode ?? this.languageCode,
    dayEpoch: dayEpoch ?? this.dayEpoch,
    cardsStudied: cardsStudied ?? this.cardsStudied,
    correctAnswers: correctAnswers ?? this.correctAnswers,
    minutesStudied: minutesStudied ?? this.minutesStudied,
  );
  StudyHistoryData copyWithCompanion(StudyHistoryCompanion data) {
    return StudyHistoryData(
      id: data.id.present ? data.id.value : this.id,
      languageCode: data.languageCode.present
          ? data.languageCode.value
          : this.languageCode,
      dayEpoch: data.dayEpoch.present ? data.dayEpoch.value : this.dayEpoch,
      cardsStudied: data.cardsStudied.present
          ? data.cardsStudied.value
          : this.cardsStudied,
      correctAnswers: data.correctAnswers.present
          ? data.correctAnswers.value
          : this.correctAnswers,
      minutesStudied: data.minutesStudied.present
          ? data.minutesStudied.value
          : this.minutesStudied,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StudyHistoryData(')
          ..write('id: $id, ')
          ..write('languageCode: $languageCode, ')
          ..write('dayEpoch: $dayEpoch, ')
          ..write('cardsStudied: $cardsStudied, ')
          ..write('correctAnswers: $correctAnswers, ')
          ..write('minutesStudied: $minutesStudied')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    languageCode,
    dayEpoch,
    cardsStudied,
    correctAnswers,
    minutesStudied,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StudyHistoryData &&
          other.id == this.id &&
          other.languageCode == this.languageCode &&
          other.dayEpoch == this.dayEpoch &&
          other.cardsStudied == this.cardsStudied &&
          other.correctAnswers == this.correctAnswers &&
          other.minutesStudied == this.minutesStudied);
}

class StudyHistoryCompanion extends UpdateCompanion<StudyHistoryData> {
  final Value<int> id;
  final Value<String> languageCode;
  final Value<int> dayEpoch;
  final Value<int> cardsStudied;
  final Value<int> correctAnswers;
  final Value<int> minutesStudied;
  const StudyHistoryCompanion({
    this.id = const Value.absent(),
    this.languageCode = const Value.absent(),
    this.dayEpoch = const Value.absent(),
    this.cardsStudied = const Value.absent(),
    this.correctAnswers = const Value.absent(),
    this.minutesStudied = const Value.absent(),
  });
  StudyHistoryCompanion.insert({
    this.id = const Value.absent(),
    this.languageCode = const Value.absent(),
    required int dayEpoch,
    this.cardsStudied = const Value.absent(),
    this.correctAnswers = const Value.absent(),
    this.minutesStudied = const Value.absent(),
  }) : dayEpoch = Value(dayEpoch);
  static Insertable<StudyHistoryData> custom({
    Expression<int>? id,
    Expression<String>? languageCode,
    Expression<int>? dayEpoch,
    Expression<int>? cardsStudied,
    Expression<int>? correctAnswers,
    Expression<int>? minutesStudied,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (languageCode != null) 'language_code': languageCode,
      if (dayEpoch != null) 'day_epoch': dayEpoch,
      if (cardsStudied != null) 'cards_studied': cardsStudied,
      if (correctAnswers != null) 'correct_answers': correctAnswers,
      if (minutesStudied != null) 'minutes_studied': minutesStudied,
    });
  }

  StudyHistoryCompanion copyWith({
    Value<int>? id,
    Value<String>? languageCode,
    Value<int>? dayEpoch,
    Value<int>? cardsStudied,
    Value<int>? correctAnswers,
    Value<int>? minutesStudied,
  }) {
    return StudyHistoryCompanion(
      id: id ?? this.id,
      languageCode: languageCode ?? this.languageCode,
      dayEpoch: dayEpoch ?? this.dayEpoch,
      cardsStudied: cardsStudied ?? this.cardsStudied,
      correctAnswers: correctAnswers ?? this.correctAnswers,
      minutesStudied: minutesStudied ?? this.minutesStudied,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (languageCode.present) {
      map['language_code'] = Variable<String>(languageCode.value);
    }
    if (dayEpoch.present) {
      map['day_epoch'] = Variable<int>(dayEpoch.value);
    }
    if (cardsStudied.present) {
      map['cards_studied'] = Variable<int>(cardsStudied.value);
    }
    if (correctAnswers.present) {
      map['correct_answers'] = Variable<int>(correctAnswers.value);
    }
    if (minutesStudied.present) {
      map['minutes_studied'] = Variable<int>(minutesStudied.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StudyHistoryCompanion(')
          ..write('id: $id, ')
          ..write('languageCode: $languageCode, ')
          ..write('dayEpoch: $dayEpoch, ')
          ..write('cardsStudied: $cardsStudied, ')
          ..write('correctAnswers: $correctAnswers, ')
          ..write('minutesStudied: $minutesStudied')
          ..write(')'))
        .toString();
  }
}

class $BlitzHighscoresTable extends BlitzHighscores
    with TableInfo<$BlitzHighscoresTable, BlitzHighscore> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BlitzHighscoresTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _scoreMeta = const VerificationMeta('score');
  @override
  late final GeneratedColumn<int> score = GeneratedColumn<int>(
    'score',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _correctCountMeta = const VerificationMeta(
    'correctCount',
  );
  @override
  late final GeneratedColumn<int> correctCount = GeneratedColumn<int>(
    'correct_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bestStreakMeta = const VerificationMeta(
    'bestStreak',
  );
  @override
  late final GeneratedColumn<int> bestStreak = GeneratedColumn<int>(
    'best_streak',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _playedAtMeta = const VerificationMeta(
    'playedAt',
  );
  @override
  late final GeneratedColumn<int> playedAt = GeneratedColumn<int>(
    'played_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kanjiSetMeta = const VerificationMeta(
    'kanjiSet',
  );
  @override
  late final GeneratedColumn<String> kanjiSet = GeneratedColumn<String>(
    'kanji_set',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('N5'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    score,
    correctCount,
    bestStreak,
    playedAt,
    kanjiSet,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'blitz_highscores';
  @override
  VerificationContext validateIntegrity(
    Insertable<BlitzHighscore> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('score')) {
      context.handle(
        _scoreMeta,
        score.isAcceptableOrUnknown(data['score']!, _scoreMeta),
      );
    } else if (isInserting) {
      context.missing(_scoreMeta);
    }
    if (data.containsKey('correct_count')) {
      context.handle(
        _correctCountMeta,
        correctCount.isAcceptableOrUnknown(
          data['correct_count']!,
          _correctCountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_correctCountMeta);
    }
    if (data.containsKey('best_streak')) {
      context.handle(
        _bestStreakMeta,
        bestStreak.isAcceptableOrUnknown(data['best_streak']!, _bestStreakMeta),
      );
    } else if (isInserting) {
      context.missing(_bestStreakMeta);
    }
    if (data.containsKey('played_at')) {
      context.handle(
        _playedAtMeta,
        playedAt.isAcceptableOrUnknown(data['played_at']!, _playedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_playedAtMeta);
    }
    if (data.containsKey('kanji_set')) {
      context.handle(
        _kanjiSetMeta,
        kanjiSet.isAcceptableOrUnknown(data['kanji_set']!, _kanjiSetMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BlitzHighscore map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BlitzHighscore(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      score: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}score'],
      )!,
      correctCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}correct_count'],
      )!,
      bestStreak: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}best_streak'],
      )!,
      playedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}played_at'],
      )!,
      kanjiSet: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kanji_set'],
      )!,
    );
  }

  @override
  $BlitzHighscoresTable createAlias(String alias) {
    return $BlitzHighscoresTable(attachedDatabase, alias);
  }
}

class BlitzHighscore extends DataClass implements Insertable<BlitzHighscore> {
  final int id;
  final int score;
  final int correctCount;
  final int bestStreak;
  final int playedAt;
  final String kanjiSet;
  const BlitzHighscore({
    required this.id,
    required this.score,
    required this.correctCount,
    required this.bestStreak,
    required this.playedAt,
    required this.kanjiSet,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['score'] = Variable<int>(score);
    map['correct_count'] = Variable<int>(correctCount);
    map['best_streak'] = Variable<int>(bestStreak);
    map['played_at'] = Variable<int>(playedAt);
    map['kanji_set'] = Variable<String>(kanjiSet);
    return map;
  }

  BlitzHighscoresCompanion toCompanion(bool nullToAbsent) {
    return BlitzHighscoresCompanion(
      id: Value(id),
      score: Value(score),
      correctCount: Value(correctCount),
      bestStreak: Value(bestStreak),
      playedAt: Value(playedAt),
      kanjiSet: Value(kanjiSet),
    );
  }

  factory BlitzHighscore.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BlitzHighscore(
      id: serializer.fromJson<int>(json['id']),
      score: serializer.fromJson<int>(json['score']),
      correctCount: serializer.fromJson<int>(json['correctCount']),
      bestStreak: serializer.fromJson<int>(json['bestStreak']),
      playedAt: serializer.fromJson<int>(json['playedAt']),
      kanjiSet: serializer.fromJson<String>(json['kanjiSet']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'score': serializer.toJson<int>(score),
      'correctCount': serializer.toJson<int>(correctCount),
      'bestStreak': serializer.toJson<int>(bestStreak),
      'playedAt': serializer.toJson<int>(playedAt),
      'kanjiSet': serializer.toJson<String>(kanjiSet),
    };
  }

  BlitzHighscore copyWith({
    int? id,
    int? score,
    int? correctCount,
    int? bestStreak,
    int? playedAt,
    String? kanjiSet,
  }) => BlitzHighscore(
    id: id ?? this.id,
    score: score ?? this.score,
    correctCount: correctCount ?? this.correctCount,
    bestStreak: bestStreak ?? this.bestStreak,
    playedAt: playedAt ?? this.playedAt,
    kanjiSet: kanjiSet ?? this.kanjiSet,
  );
  BlitzHighscore copyWithCompanion(BlitzHighscoresCompanion data) {
    return BlitzHighscore(
      id: data.id.present ? data.id.value : this.id,
      score: data.score.present ? data.score.value : this.score,
      correctCount: data.correctCount.present
          ? data.correctCount.value
          : this.correctCount,
      bestStreak: data.bestStreak.present
          ? data.bestStreak.value
          : this.bestStreak,
      playedAt: data.playedAt.present ? data.playedAt.value : this.playedAt,
      kanjiSet: data.kanjiSet.present ? data.kanjiSet.value : this.kanjiSet,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BlitzHighscore(')
          ..write('id: $id, ')
          ..write('score: $score, ')
          ..write('correctCount: $correctCount, ')
          ..write('bestStreak: $bestStreak, ')
          ..write('playedAt: $playedAt, ')
          ..write('kanjiSet: $kanjiSet')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, score, correctCount, bestStreak, playedAt, kanjiSet);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BlitzHighscore &&
          other.id == this.id &&
          other.score == this.score &&
          other.correctCount == this.correctCount &&
          other.bestStreak == this.bestStreak &&
          other.playedAt == this.playedAt &&
          other.kanjiSet == this.kanjiSet);
}

class BlitzHighscoresCompanion extends UpdateCompanion<BlitzHighscore> {
  final Value<int> id;
  final Value<int> score;
  final Value<int> correctCount;
  final Value<int> bestStreak;
  final Value<int> playedAt;
  final Value<String> kanjiSet;
  const BlitzHighscoresCompanion({
    this.id = const Value.absent(),
    this.score = const Value.absent(),
    this.correctCount = const Value.absent(),
    this.bestStreak = const Value.absent(),
    this.playedAt = const Value.absent(),
    this.kanjiSet = const Value.absent(),
  });
  BlitzHighscoresCompanion.insert({
    this.id = const Value.absent(),
    required int score,
    required int correctCount,
    required int bestStreak,
    required int playedAt,
    this.kanjiSet = const Value.absent(),
  }) : score = Value(score),
       correctCount = Value(correctCount),
       bestStreak = Value(bestStreak),
       playedAt = Value(playedAt);
  static Insertable<BlitzHighscore> custom({
    Expression<int>? id,
    Expression<int>? score,
    Expression<int>? correctCount,
    Expression<int>? bestStreak,
    Expression<int>? playedAt,
    Expression<String>? kanjiSet,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (score != null) 'score': score,
      if (correctCount != null) 'correct_count': correctCount,
      if (bestStreak != null) 'best_streak': bestStreak,
      if (playedAt != null) 'played_at': playedAt,
      if (kanjiSet != null) 'kanji_set': kanjiSet,
    });
  }

  BlitzHighscoresCompanion copyWith({
    Value<int>? id,
    Value<int>? score,
    Value<int>? correctCount,
    Value<int>? bestStreak,
    Value<int>? playedAt,
    Value<String>? kanjiSet,
  }) {
    return BlitzHighscoresCompanion(
      id: id ?? this.id,
      score: score ?? this.score,
      correctCount: correctCount ?? this.correctCount,
      bestStreak: bestStreak ?? this.bestStreak,
      playedAt: playedAt ?? this.playedAt,
      kanjiSet: kanjiSet ?? this.kanjiSet,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (score.present) {
      map['score'] = Variable<int>(score.value);
    }
    if (correctCount.present) {
      map['correct_count'] = Variable<int>(correctCount.value);
    }
    if (bestStreak.present) {
      map['best_streak'] = Variable<int>(bestStreak.value);
    }
    if (playedAt.present) {
      map['played_at'] = Variable<int>(playedAt.value);
    }
    if (kanjiSet.present) {
      map['kanji_set'] = Variable<String>(kanjiSet.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BlitzHighscoresCompanion(')
          ..write('id: $id, ')
          ..write('score: $score, ')
          ..write('correctCount: $correctCount, ')
          ..write('bestStreak: $bestStreak, ')
          ..write('playedAt: $playedAt, ')
          ..write('kanjiSet: $kanjiSet')
          ..write(')'))
        .toString();
  }
}

class $MemoryBesttimesTable extends MemoryBesttimes
    with TableInfo<$MemoryBesttimesTable, MemoryBesttime> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MemoryBesttimesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _gridSizeMeta = const VerificationMeta(
    'gridSize',
  );
  @override
  late final GeneratedColumn<String> gridSize = GeneratedColumn<String>(
    'grid_size',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pairTypeMeta = const VerificationMeta(
    'pairType',
  );
  @override
  late final GeneratedColumn<String> pairType = GeneratedColumn<String>(
    'pair_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _movesMeta = const VerificationMeta('moves');
  @override
  late final GeneratedColumn<int> moves = GeneratedColumn<int>(
    'moves',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _timeSecondsMeta = const VerificationMeta(
    'timeSeconds',
  );
  @override
  late final GeneratedColumn<int> timeSeconds = GeneratedColumn<int>(
    'time_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _playedAtMeta = const VerificationMeta(
    'playedAt',
  );
  @override
  late final GeneratedColumn<int> playedAt = GeneratedColumn<int>(
    'played_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    gridSize,
    pairType,
    moves,
    timeSeconds,
    playedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'memory_besttimes';
  @override
  VerificationContext validateIntegrity(
    Insertable<MemoryBesttime> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('grid_size')) {
      context.handle(
        _gridSizeMeta,
        gridSize.isAcceptableOrUnknown(data['grid_size']!, _gridSizeMeta),
      );
    } else if (isInserting) {
      context.missing(_gridSizeMeta);
    }
    if (data.containsKey('pair_type')) {
      context.handle(
        _pairTypeMeta,
        pairType.isAcceptableOrUnknown(data['pair_type']!, _pairTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_pairTypeMeta);
    }
    if (data.containsKey('moves')) {
      context.handle(
        _movesMeta,
        moves.isAcceptableOrUnknown(data['moves']!, _movesMeta),
      );
    } else if (isInserting) {
      context.missing(_movesMeta);
    }
    if (data.containsKey('time_seconds')) {
      context.handle(
        _timeSecondsMeta,
        timeSeconds.isAcceptableOrUnknown(
          data['time_seconds']!,
          _timeSecondsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_timeSecondsMeta);
    }
    if (data.containsKey('played_at')) {
      context.handle(
        _playedAtMeta,
        playedAt.isAcceptableOrUnknown(data['played_at']!, _playedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_playedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MemoryBesttime map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MemoryBesttime(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      gridSize: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}grid_size'],
      )!,
      pairType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pair_type'],
      )!,
      moves: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}moves'],
      )!,
      timeSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}time_seconds'],
      )!,
      playedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}played_at'],
      )!,
    );
  }

  @override
  $MemoryBesttimesTable createAlias(String alias) {
    return $MemoryBesttimesTable(attachedDatabase, alias);
  }
}

class MemoryBesttime extends DataClass implements Insertable<MemoryBesttime> {
  final int id;
  final String gridSize;
  final String pairType;
  final int moves;
  final int timeSeconds;
  final int playedAt;
  const MemoryBesttime({
    required this.id,
    required this.gridSize,
    required this.pairType,
    required this.moves,
    required this.timeSeconds,
    required this.playedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['grid_size'] = Variable<String>(gridSize);
    map['pair_type'] = Variable<String>(pairType);
    map['moves'] = Variable<int>(moves);
    map['time_seconds'] = Variable<int>(timeSeconds);
    map['played_at'] = Variable<int>(playedAt);
    return map;
  }

  MemoryBesttimesCompanion toCompanion(bool nullToAbsent) {
    return MemoryBesttimesCompanion(
      id: Value(id),
      gridSize: Value(gridSize),
      pairType: Value(pairType),
      moves: Value(moves),
      timeSeconds: Value(timeSeconds),
      playedAt: Value(playedAt),
    );
  }

  factory MemoryBesttime.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MemoryBesttime(
      id: serializer.fromJson<int>(json['id']),
      gridSize: serializer.fromJson<String>(json['gridSize']),
      pairType: serializer.fromJson<String>(json['pairType']),
      moves: serializer.fromJson<int>(json['moves']),
      timeSeconds: serializer.fromJson<int>(json['timeSeconds']),
      playedAt: serializer.fromJson<int>(json['playedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'gridSize': serializer.toJson<String>(gridSize),
      'pairType': serializer.toJson<String>(pairType),
      'moves': serializer.toJson<int>(moves),
      'timeSeconds': serializer.toJson<int>(timeSeconds),
      'playedAt': serializer.toJson<int>(playedAt),
    };
  }

  MemoryBesttime copyWith({
    int? id,
    String? gridSize,
    String? pairType,
    int? moves,
    int? timeSeconds,
    int? playedAt,
  }) => MemoryBesttime(
    id: id ?? this.id,
    gridSize: gridSize ?? this.gridSize,
    pairType: pairType ?? this.pairType,
    moves: moves ?? this.moves,
    timeSeconds: timeSeconds ?? this.timeSeconds,
    playedAt: playedAt ?? this.playedAt,
  );
  MemoryBesttime copyWithCompanion(MemoryBesttimesCompanion data) {
    return MemoryBesttime(
      id: data.id.present ? data.id.value : this.id,
      gridSize: data.gridSize.present ? data.gridSize.value : this.gridSize,
      pairType: data.pairType.present ? data.pairType.value : this.pairType,
      moves: data.moves.present ? data.moves.value : this.moves,
      timeSeconds: data.timeSeconds.present
          ? data.timeSeconds.value
          : this.timeSeconds,
      playedAt: data.playedAt.present ? data.playedAt.value : this.playedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MemoryBesttime(')
          ..write('id: $id, ')
          ..write('gridSize: $gridSize, ')
          ..write('pairType: $pairType, ')
          ..write('moves: $moves, ')
          ..write('timeSeconds: $timeSeconds, ')
          ..write('playedAt: $playedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, gridSize, pairType, moves, timeSeconds, playedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MemoryBesttime &&
          other.id == this.id &&
          other.gridSize == this.gridSize &&
          other.pairType == this.pairType &&
          other.moves == this.moves &&
          other.timeSeconds == this.timeSeconds &&
          other.playedAt == this.playedAt);
}

class MemoryBesttimesCompanion extends UpdateCompanion<MemoryBesttime> {
  final Value<int> id;
  final Value<String> gridSize;
  final Value<String> pairType;
  final Value<int> moves;
  final Value<int> timeSeconds;
  final Value<int> playedAt;
  const MemoryBesttimesCompanion({
    this.id = const Value.absent(),
    this.gridSize = const Value.absent(),
    this.pairType = const Value.absent(),
    this.moves = const Value.absent(),
    this.timeSeconds = const Value.absent(),
    this.playedAt = const Value.absent(),
  });
  MemoryBesttimesCompanion.insert({
    this.id = const Value.absent(),
    required String gridSize,
    required String pairType,
    required int moves,
    required int timeSeconds,
    required int playedAt,
  }) : gridSize = Value(gridSize),
       pairType = Value(pairType),
       moves = Value(moves),
       timeSeconds = Value(timeSeconds),
       playedAt = Value(playedAt);
  static Insertable<MemoryBesttime> custom({
    Expression<int>? id,
    Expression<String>? gridSize,
    Expression<String>? pairType,
    Expression<int>? moves,
    Expression<int>? timeSeconds,
    Expression<int>? playedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (gridSize != null) 'grid_size': gridSize,
      if (pairType != null) 'pair_type': pairType,
      if (moves != null) 'moves': moves,
      if (timeSeconds != null) 'time_seconds': timeSeconds,
      if (playedAt != null) 'played_at': playedAt,
    });
  }

  MemoryBesttimesCompanion copyWith({
    Value<int>? id,
    Value<String>? gridSize,
    Value<String>? pairType,
    Value<int>? moves,
    Value<int>? timeSeconds,
    Value<int>? playedAt,
  }) {
    return MemoryBesttimesCompanion(
      id: id ?? this.id,
      gridSize: gridSize ?? this.gridSize,
      pairType: pairType ?? this.pairType,
      moves: moves ?? this.moves,
      timeSeconds: timeSeconds ?? this.timeSeconds,
      playedAt: playedAt ?? this.playedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (gridSize.present) {
      map['grid_size'] = Variable<String>(gridSize.value);
    }
    if (pairType.present) {
      map['pair_type'] = Variable<String>(pairType.value);
    }
    if (moves.present) {
      map['moves'] = Variable<int>(moves.value);
    }
    if (timeSeconds.present) {
      map['time_seconds'] = Variable<int>(timeSeconds.value);
    }
    if (playedAt.present) {
      map['played_at'] = Variable<int>(playedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MemoryBesttimesCompanion(')
          ..write('id: $id, ')
          ..write('gridSize: $gridSize, ')
          ..write('pairType: $pairType, ')
          ..write('moves: $moves, ')
          ..write('timeSeconds: $timeSeconds, ')
          ..write('playedAt: $playedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $SrsCardsTable srsCards = $SrsCardsTable(this);
  late final $LessonProgressTable lessonProgress = $LessonProgressTable(this);
  late final $UserStatsTable userStats = $UserStatsTable(this);
  late final $StudyHistoryTable studyHistory = $StudyHistoryTable(this);
  late final $BlitzHighscoresTable blitzHighscores = $BlitzHighscoresTable(
    this,
  );
  late final $MemoryBesttimesTable memoryBesttimes = $MemoryBesttimesTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    srsCards,
    lessonProgress,
    userStats,
    studyHistory,
    blitzHighscores,
    memoryBesttimes,
  ];
}

typedef $$SrsCardsTableCreateCompanionBuilder =
    SrsCardsCompanion Function({
      Value<int> id,
      required String cardId,
      required String front,
      required String back,
      Value<String?> reading,
      Value<double> ease,
      Value<int> interval,
      Value<int> reps,
      Value<int> dueAt,
      required String cardType,
      Value<String> languageCode,
    });
typedef $$SrsCardsTableUpdateCompanionBuilder =
    SrsCardsCompanion Function({
      Value<int> id,
      Value<String> cardId,
      Value<String> front,
      Value<String> back,
      Value<String?> reading,
      Value<double> ease,
      Value<int> interval,
      Value<int> reps,
      Value<int> dueAt,
      Value<String> cardType,
      Value<String> languageCode,
    });

class $$SrsCardsTableFilterComposer
    extends Composer<_$AppDatabase, $SrsCardsTable> {
  $$SrsCardsTableFilterComposer({
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

  ColumnFilters<String> get cardId => $composableBuilder(
    column: $table.cardId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get front => $composableBuilder(
    column: $table.front,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get back => $composableBuilder(
    column: $table.back,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reading => $composableBuilder(
    column: $table.reading,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get ease => $composableBuilder(
    column: $table.ease,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get interval => $composableBuilder(
    column: $table.interval,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reps => $composableBuilder(
    column: $table.reps,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dueAt => $composableBuilder(
    column: $table.dueAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cardType => $composableBuilder(
    column: $table.cardType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get languageCode => $composableBuilder(
    column: $table.languageCode,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SrsCardsTableOrderingComposer
    extends Composer<_$AppDatabase, $SrsCardsTable> {
  $$SrsCardsTableOrderingComposer({
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

  ColumnOrderings<String> get cardId => $composableBuilder(
    column: $table.cardId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get front => $composableBuilder(
    column: $table.front,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get back => $composableBuilder(
    column: $table.back,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reading => $composableBuilder(
    column: $table.reading,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get ease => $composableBuilder(
    column: $table.ease,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get interval => $composableBuilder(
    column: $table.interval,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reps => $composableBuilder(
    column: $table.reps,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dueAt => $composableBuilder(
    column: $table.dueAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cardType => $composableBuilder(
    column: $table.cardType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get languageCode => $composableBuilder(
    column: $table.languageCode,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SrsCardsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SrsCardsTable> {
  $$SrsCardsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get cardId =>
      $composableBuilder(column: $table.cardId, builder: (column) => column);

  GeneratedColumn<String> get front =>
      $composableBuilder(column: $table.front, builder: (column) => column);

  GeneratedColumn<String> get back =>
      $composableBuilder(column: $table.back, builder: (column) => column);

  GeneratedColumn<String> get reading =>
      $composableBuilder(column: $table.reading, builder: (column) => column);

  GeneratedColumn<double> get ease =>
      $composableBuilder(column: $table.ease, builder: (column) => column);

  GeneratedColumn<int> get interval =>
      $composableBuilder(column: $table.interval, builder: (column) => column);

  GeneratedColumn<int> get reps =>
      $composableBuilder(column: $table.reps, builder: (column) => column);

  GeneratedColumn<int> get dueAt =>
      $composableBuilder(column: $table.dueAt, builder: (column) => column);

  GeneratedColumn<String> get cardType =>
      $composableBuilder(column: $table.cardType, builder: (column) => column);

  GeneratedColumn<String> get languageCode => $composableBuilder(
    column: $table.languageCode,
    builder: (column) => column,
  );
}

class $$SrsCardsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SrsCardsTable,
          SrsCardRow,
          $$SrsCardsTableFilterComposer,
          $$SrsCardsTableOrderingComposer,
          $$SrsCardsTableAnnotationComposer,
          $$SrsCardsTableCreateCompanionBuilder,
          $$SrsCardsTableUpdateCompanionBuilder,
          (
            SrsCardRow,
            BaseReferences<_$AppDatabase, $SrsCardsTable, SrsCardRow>,
          ),
          SrsCardRow,
          PrefetchHooks Function()
        > {
  $$SrsCardsTableTableManager(_$AppDatabase db, $SrsCardsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SrsCardsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SrsCardsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SrsCardsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> cardId = const Value.absent(),
                Value<String> front = const Value.absent(),
                Value<String> back = const Value.absent(),
                Value<String?> reading = const Value.absent(),
                Value<double> ease = const Value.absent(),
                Value<int> interval = const Value.absent(),
                Value<int> reps = const Value.absent(),
                Value<int> dueAt = const Value.absent(),
                Value<String> cardType = const Value.absent(),
                Value<String> languageCode = const Value.absent(),
              }) => SrsCardsCompanion(
                id: id,
                cardId: cardId,
                front: front,
                back: back,
                reading: reading,
                ease: ease,
                interval: interval,
                reps: reps,
                dueAt: dueAt,
                cardType: cardType,
                languageCode: languageCode,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String cardId,
                required String front,
                required String back,
                Value<String?> reading = const Value.absent(),
                Value<double> ease = const Value.absent(),
                Value<int> interval = const Value.absent(),
                Value<int> reps = const Value.absent(),
                Value<int> dueAt = const Value.absent(),
                required String cardType,
                Value<String> languageCode = const Value.absent(),
              }) => SrsCardsCompanion.insert(
                id: id,
                cardId: cardId,
                front: front,
                back: back,
                reading: reading,
                ease: ease,
                interval: interval,
                reps: reps,
                dueAt: dueAt,
                cardType: cardType,
                languageCode: languageCode,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SrsCardsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SrsCardsTable,
      SrsCardRow,
      $$SrsCardsTableFilterComposer,
      $$SrsCardsTableOrderingComposer,
      $$SrsCardsTableAnnotationComposer,
      $$SrsCardsTableCreateCompanionBuilder,
      $$SrsCardsTableUpdateCompanionBuilder,
      (SrsCardRow, BaseReferences<_$AppDatabase, $SrsCardsTable, SrsCardRow>),
      SrsCardRow,
      PrefetchHooks Function()
    >;
typedef $$LessonProgressTableCreateCompanionBuilder =
    LessonProgressCompanion Function({
      Value<int> id,
      required int lessonId,
      Value<String> languageCode,
      Value<int> status,
      Value<int> accuracy,
      Value<int> xpEarned,
      Value<int> completedAt,
    });
typedef $$LessonProgressTableUpdateCompanionBuilder =
    LessonProgressCompanion Function({
      Value<int> id,
      Value<int> lessonId,
      Value<String> languageCode,
      Value<int> status,
      Value<int> accuracy,
      Value<int> xpEarned,
      Value<int> completedAt,
    });

class $$LessonProgressTableFilterComposer
    extends Composer<_$AppDatabase, $LessonProgressTable> {
  $$LessonProgressTableFilterComposer({
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

  ColumnFilters<int> get lessonId => $composableBuilder(
    column: $table.lessonId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get languageCode => $composableBuilder(
    column: $table.languageCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get accuracy => $composableBuilder(
    column: $table.accuracy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get xpEarned => $composableBuilder(
    column: $table.xpEarned,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LessonProgressTableOrderingComposer
    extends Composer<_$AppDatabase, $LessonProgressTable> {
  $$LessonProgressTableOrderingComposer({
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

  ColumnOrderings<int> get lessonId => $composableBuilder(
    column: $table.lessonId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get languageCode => $composableBuilder(
    column: $table.languageCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get accuracy => $composableBuilder(
    column: $table.accuracy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get xpEarned => $composableBuilder(
    column: $table.xpEarned,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LessonProgressTableAnnotationComposer
    extends Composer<_$AppDatabase, $LessonProgressTable> {
  $$LessonProgressTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get lessonId =>
      $composableBuilder(column: $table.lessonId, builder: (column) => column);

  GeneratedColumn<String> get languageCode => $composableBuilder(
    column: $table.languageCode,
    builder: (column) => column,
  );

  GeneratedColumn<int> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get accuracy =>
      $composableBuilder(column: $table.accuracy, builder: (column) => column);

  GeneratedColumn<int> get xpEarned =>
      $composableBuilder(column: $table.xpEarned, builder: (column) => column);

  GeneratedColumn<int> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );
}

class $$LessonProgressTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LessonProgressTable,
          LessonProgressData,
          $$LessonProgressTableFilterComposer,
          $$LessonProgressTableOrderingComposer,
          $$LessonProgressTableAnnotationComposer,
          $$LessonProgressTableCreateCompanionBuilder,
          $$LessonProgressTableUpdateCompanionBuilder,
          (
            LessonProgressData,
            BaseReferences<
              _$AppDatabase,
              $LessonProgressTable,
              LessonProgressData
            >,
          ),
          LessonProgressData,
          PrefetchHooks Function()
        > {
  $$LessonProgressTableTableManager(
    _$AppDatabase db,
    $LessonProgressTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LessonProgressTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LessonProgressTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LessonProgressTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> lessonId = const Value.absent(),
                Value<String> languageCode = const Value.absent(),
                Value<int> status = const Value.absent(),
                Value<int> accuracy = const Value.absent(),
                Value<int> xpEarned = const Value.absent(),
                Value<int> completedAt = const Value.absent(),
              }) => LessonProgressCompanion(
                id: id,
                lessonId: lessonId,
                languageCode: languageCode,
                status: status,
                accuracy: accuracy,
                xpEarned: xpEarned,
                completedAt: completedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int lessonId,
                Value<String> languageCode = const Value.absent(),
                Value<int> status = const Value.absent(),
                Value<int> accuracy = const Value.absent(),
                Value<int> xpEarned = const Value.absent(),
                Value<int> completedAt = const Value.absent(),
              }) => LessonProgressCompanion.insert(
                id: id,
                lessonId: lessonId,
                languageCode: languageCode,
                status: status,
                accuracy: accuracy,
                xpEarned: xpEarned,
                completedAt: completedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LessonProgressTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LessonProgressTable,
      LessonProgressData,
      $$LessonProgressTableFilterComposer,
      $$LessonProgressTableOrderingComposer,
      $$LessonProgressTableAnnotationComposer,
      $$LessonProgressTableCreateCompanionBuilder,
      $$LessonProgressTableUpdateCompanionBuilder,
      (
        LessonProgressData,
        BaseReferences<_$AppDatabase, $LessonProgressTable, LessonProgressData>,
      ),
      LessonProgressData,
      PrefetchHooks Function()
    >;
typedef $$UserStatsTableCreateCompanionBuilder =
    UserStatsCompanion Function({
      Value<int> id,
      Value<String> languageCode,
      Value<int> totalXp,
      Value<int> totalCardsLearned,
      Value<int> totalSessions,
      Value<int> conversationSessions,
      Value<int> lastStudiedAt,
    });
typedef $$UserStatsTableUpdateCompanionBuilder =
    UserStatsCompanion Function({
      Value<int> id,
      Value<String> languageCode,
      Value<int> totalXp,
      Value<int> totalCardsLearned,
      Value<int> totalSessions,
      Value<int> conversationSessions,
      Value<int> lastStudiedAt,
    });

class $$UserStatsTableFilterComposer
    extends Composer<_$AppDatabase, $UserStatsTable> {
  $$UserStatsTableFilterComposer({
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

  ColumnFilters<String> get languageCode => $composableBuilder(
    column: $table.languageCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalXp => $composableBuilder(
    column: $table.totalXp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalCardsLearned => $composableBuilder(
    column: $table.totalCardsLearned,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalSessions => $composableBuilder(
    column: $table.totalSessions,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get conversationSessions => $composableBuilder(
    column: $table.conversationSessions,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastStudiedAt => $composableBuilder(
    column: $table.lastStudiedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UserStatsTableOrderingComposer
    extends Composer<_$AppDatabase, $UserStatsTable> {
  $$UserStatsTableOrderingComposer({
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

  ColumnOrderings<String> get languageCode => $composableBuilder(
    column: $table.languageCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalXp => $composableBuilder(
    column: $table.totalXp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalCardsLearned => $composableBuilder(
    column: $table.totalCardsLearned,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalSessions => $composableBuilder(
    column: $table.totalSessions,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get conversationSessions => $composableBuilder(
    column: $table.conversationSessions,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastStudiedAt => $composableBuilder(
    column: $table.lastStudiedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UserStatsTableAnnotationComposer
    extends Composer<_$AppDatabase, $UserStatsTable> {
  $$UserStatsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get languageCode => $composableBuilder(
    column: $table.languageCode,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalXp =>
      $composableBuilder(column: $table.totalXp, builder: (column) => column);

  GeneratedColumn<int> get totalCardsLearned => $composableBuilder(
    column: $table.totalCardsLearned,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalSessions => $composableBuilder(
    column: $table.totalSessions,
    builder: (column) => column,
  );

  GeneratedColumn<int> get conversationSessions => $composableBuilder(
    column: $table.conversationSessions,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastStudiedAt => $composableBuilder(
    column: $table.lastStudiedAt,
    builder: (column) => column,
  );
}

class $$UserStatsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UserStatsTable,
          UserStat,
          $$UserStatsTableFilterComposer,
          $$UserStatsTableOrderingComposer,
          $$UserStatsTableAnnotationComposer,
          $$UserStatsTableCreateCompanionBuilder,
          $$UserStatsTableUpdateCompanionBuilder,
          (UserStat, BaseReferences<_$AppDatabase, $UserStatsTable, UserStat>),
          UserStat,
          PrefetchHooks Function()
        > {
  $$UserStatsTableTableManager(_$AppDatabase db, $UserStatsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserStatsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserStatsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UserStatsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> languageCode = const Value.absent(),
                Value<int> totalXp = const Value.absent(),
                Value<int> totalCardsLearned = const Value.absent(),
                Value<int> totalSessions = const Value.absent(),
                Value<int> conversationSessions = const Value.absent(),
                Value<int> lastStudiedAt = const Value.absent(),
              }) => UserStatsCompanion(
                id: id,
                languageCode: languageCode,
                totalXp: totalXp,
                totalCardsLearned: totalCardsLearned,
                totalSessions: totalSessions,
                conversationSessions: conversationSessions,
                lastStudiedAt: lastStudiedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> languageCode = const Value.absent(),
                Value<int> totalXp = const Value.absent(),
                Value<int> totalCardsLearned = const Value.absent(),
                Value<int> totalSessions = const Value.absent(),
                Value<int> conversationSessions = const Value.absent(),
                Value<int> lastStudiedAt = const Value.absent(),
              }) => UserStatsCompanion.insert(
                id: id,
                languageCode: languageCode,
                totalXp: totalXp,
                totalCardsLearned: totalCardsLearned,
                totalSessions: totalSessions,
                conversationSessions: conversationSessions,
                lastStudiedAt: lastStudiedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UserStatsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UserStatsTable,
      UserStat,
      $$UserStatsTableFilterComposer,
      $$UserStatsTableOrderingComposer,
      $$UserStatsTableAnnotationComposer,
      $$UserStatsTableCreateCompanionBuilder,
      $$UserStatsTableUpdateCompanionBuilder,
      (UserStat, BaseReferences<_$AppDatabase, $UserStatsTable, UserStat>),
      UserStat,
      PrefetchHooks Function()
    >;
typedef $$StudyHistoryTableCreateCompanionBuilder =
    StudyHistoryCompanion Function({
      Value<int> id,
      Value<String> languageCode,
      required int dayEpoch,
      Value<int> cardsStudied,
      Value<int> correctAnswers,
      Value<int> minutesStudied,
    });
typedef $$StudyHistoryTableUpdateCompanionBuilder =
    StudyHistoryCompanion Function({
      Value<int> id,
      Value<String> languageCode,
      Value<int> dayEpoch,
      Value<int> cardsStudied,
      Value<int> correctAnswers,
      Value<int> minutesStudied,
    });

class $$StudyHistoryTableFilterComposer
    extends Composer<_$AppDatabase, $StudyHistoryTable> {
  $$StudyHistoryTableFilterComposer({
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

  ColumnFilters<String> get languageCode => $composableBuilder(
    column: $table.languageCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dayEpoch => $composableBuilder(
    column: $table.dayEpoch,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cardsStudied => $composableBuilder(
    column: $table.cardsStudied,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get correctAnswers => $composableBuilder(
    column: $table.correctAnswers,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get minutesStudied => $composableBuilder(
    column: $table.minutesStudied,
    builder: (column) => ColumnFilters(column),
  );
}

class $$StudyHistoryTableOrderingComposer
    extends Composer<_$AppDatabase, $StudyHistoryTable> {
  $$StudyHistoryTableOrderingComposer({
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

  ColumnOrderings<String> get languageCode => $composableBuilder(
    column: $table.languageCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dayEpoch => $composableBuilder(
    column: $table.dayEpoch,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cardsStudied => $composableBuilder(
    column: $table.cardsStudied,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get correctAnswers => $composableBuilder(
    column: $table.correctAnswers,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get minutesStudied => $composableBuilder(
    column: $table.minutesStudied,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$StudyHistoryTableAnnotationComposer
    extends Composer<_$AppDatabase, $StudyHistoryTable> {
  $$StudyHistoryTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get languageCode => $composableBuilder(
    column: $table.languageCode,
    builder: (column) => column,
  );

  GeneratedColumn<int> get dayEpoch =>
      $composableBuilder(column: $table.dayEpoch, builder: (column) => column);

  GeneratedColumn<int> get cardsStudied => $composableBuilder(
    column: $table.cardsStudied,
    builder: (column) => column,
  );

  GeneratedColumn<int> get correctAnswers => $composableBuilder(
    column: $table.correctAnswers,
    builder: (column) => column,
  );

  GeneratedColumn<int> get minutesStudied => $composableBuilder(
    column: $table.minutesStudied,
    builder: (column) => column,
  );
}

class $$StudyHistoryTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StudyHistoryTable,
          StudyHistoryData,
          $$StudyHistoryTableFilterComposer,
          $$StudyHistoryTableOrderingComposer,
          $$StudyHistoryTableAnnotationComposer,
          $$StudyHistoryTableCreateCompanionBuilder,
          $$StudyHistoryTableUpdateCompanionBuilder,
          (
            StudyHistoryData,
            BaseReferences<_$AppDatabase, $StudyHistoryTable, StudyHistoryData>,
          ),
          StudyHistoryData,
          PrefetchHooks Function()
        > {
  $$StudyHistoryTableTableManager(_$AppDatabase db, $StudyHistoryTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StudyHistoryTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StudyHistoryTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StudyHistoryTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> languageCode = const Value.absent(),
                Value<int> dayEpoch = const Value.absent(),
                Value<int> cardsStudied = const Value.absent(),
                Value<int> correctAnswers = const Value.absent(),
                Value<int> minutesStudied = const Value.absent(),
              }) => StudyHistoryCompanion(
                id: id,
                languageCode: languageCode,
                dayEpoch: dayEpoch,
                cardsStudied: cardsStudied,
                correctAnswers: correctAnswers,
                minutesStudied: minutesStudied,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> languageCode = const Value.absent(),
                required int dayEpoch,
                Value<int> cardsStudied = const Value.absent(),
                Value<int> correctAnswers = const Value.absent(),
                Value<int> minutesStudied = const Value.absent(),
              }) => StudyHistoryCompanion.insert(
                id: id,
                languageCode: languageCode,
                dayEpoch: dayEpoch,
                cardsStudied: cardsStudied,
                correctAnswers: correctAnswers,
                minutesStudied: minutesStudied,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$StudyHistoryTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StudyHistoryTable,
      StudyHistoryData,
      $$StudyHistoryTableFilterComposer,
      $$StudyHistoryTableOrderingComposer,
      $$StudyHistoryTableAnnotationComposer,
      $$StudyHistoryTableCreateCompanionBuilder,
      $$StudyHistoryTableUpdateCompanionBuilder,
      (
        StudyHistoryData,
        BaseReferences<_$AppDatabase, $StudyHistoryTable, StudyHistoryData>,
      ),
      StudyHistoryData,
      PrefetchHooks Function()
    >;
typedef $$BlitzHighscoresTableCreateCompanionBuilder =
    BlitzHighscoresCompanion Function({
      Value<int> id,
      required int score,
      required int correctCount,
      required int bestStreak,
      required int playedAt,
      Value<String> kanjiSet,
    });
typedef $$BlitzHighscoresTableUpdateCompanionBuilder =
    BlitzHighscoresCompanion Function({
      Value<int> id,
      Value<int> score,
      Value<int> correctCount,
      Value<int> bestStreak,
      Value<int> playedAt,
      Value<String> kanjiSet,
    });

class $$BlitzHighscoresTableFilterComposer
    extends Composer<_$AppDatabase, $BlitzHighscoresTable> {
  $$BlitzHighscoresTableFilterComposer({
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

  ColumnFilters<int> get score => $composableBuilder(
    column: $table.score,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get correctCount => $composableBuilder(
    column: $table.correctCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get bestStreak => $composableBuilder(
    column: $table.bestStreak,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get playedAt => $composableBuilder(
    column: $table.playedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kanjiSet => $composableBuilder(
    column: $table.kanjiSet,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BlitzHighscoresTableOrderingComposer
    extends Composer<_$AppDatabase, $BlitzHighscoresTable> {
  $$BlitzHighscoresTableOrderingComposer({
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

  ColumnOrderings<int> get score => $composableBuilder(
    column: $table.score,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get correctCount => $composableBuilder(
    column: $table.correctCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get bestStreak => $composableBuilder(
    column: $table.bestStreak,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get playedAt => $composableBuilder(
    column: $table.playedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kanjiSet => $composableBuilder(
    column: $table.kanjiSet,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BlitzHighscoresTableAnnotationComposer
    extends Composer<_$AppDatabase, $BlitzHighscoresTable> {
  $$BlitzHighscoresTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get score =>
      $composableBuilder(column: $table.score, builder: (column) => column);

  GeneratedColumn<int> get correctCount => $composableBuilder(
    column: $table.correctCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get bestStreak => $composableBuilder(
    column: $table.bestStreak,
    builder: (column) => column,
  );

  GeneratedColumn<int> get playedAt =>
      $composableBuilder(column: $table.playedAt, builder: (column) => column);

  GeneratedColumn<String> get kanjiSet =>
      $composableBuilder(column: $table.kanjiSet, builder: (column) => column);
}

class $$BlitzHighscoresTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BlitzHighscoresTable,
          BlitzHighscore,
          $$BlitzHighscoresTableFilterComposer,
          $$BlitzHighscoresTableOrderingComposer,
          $$BlitzHighscoresTableAnnotationComposer,
          $$BlitzHighscoresTableCreateCompanionBuilder,
          $$BlitzHighscoresTableUpdateCompanionBuilder,
          (
            BlitzHighscore,
            BaseReferences<
              _$AppDatabase,
              $BlitzHighscoresTable,
              BlitzHighscore
            >,
          ),
          BlitzHighscore,
          PrefetchHooks Function()
        > {
  $$BlitzHighscoresTableTableManager(
    _$AppDatabase db,
    $BlitzHighscoresTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BlitzHighscoresTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BlitzHighscoresTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BlitzHighscoresTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> score = const Value.absent(),
                Value<int> correctCount = const Value.absent(),
                Value<int> bestStreak = const Value.absent(),
                Value<int> playedAt = const Value.absent(),
                Value<String> kanjiSet = const Value.absent(),
              }) => BlitzHighscoresCompanion(
                id: id,
                score: score,
                correctCount: correctCount,
                bestStreak: bestStreak,
                playedAt: playedAt,
                kanjiSet: kanjiSet,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int score,
                required int correctCount,
                required int bestStreak,
                required int playedAt,
                Value<String> kanjiSet = const Value.absent(),
              }) => BlitzHighscoresCompanion.insert(
                id: id,
                score: score,
                correctCount: correctCount,
                bestStreak: bestStreak,
                playedAt: playedAt,
                kanjiSet: kanjiSet,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BlitzHighscoresTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BlitzHighscoresTable,
      BlitzHighscore,
      $$BlitzHighscoresTableFilterComposer,
      $$BlitzHighscoresTableOrderingComposer,
      $$BlitzHighscoresTableAnnotationComposer,
      $$BlitzHighscoresTableCreateCompanionBuilder,
      $$BlitzHighscoresTableUpdateCompanionBuilder,
      (
        BlitzHighscore,
        BaseReferences<_$AppDatabase, $BlitzHighscoresTable, BlitzHighscore>,
      ),
      BlitzHighscore,
      PrefetchHooks Function()
    >;
typedef $$MemoryBesttimesTableCreateCompanionBuilder =
    MemoryBesttimesCompanion Function({
      Value<int> id,
      required String gridSize,
      required String pairType,
      required int moves,
      required int timeSeconds,
      required int playedAt,
    });
typedef $$MemoryBesttimesTableUpdateCompanionBuilder =
    MemoryBesttimesCompanion Function({
      Value<int> id,
      Value<String> gridSize,
      Value<String> pairType,
      Value<int> moves,
      Value<int> timeSeconds,
      Value<int> playedAt,
    });

class $$MemoryBesttimesTableFilterComposer
    extends Composer<_$AppDatabase, $MemoryBesttimesTable> {
  $$MemoryBesttimesTableFilterComposer({
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

  ColumnFilters<String> get gridSize => $composableBuilder(
    column: $table.gridSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pairType => $composableBuilder(
    column: $table.pairType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get moves => $composableBuilder(
    column: $table.moves,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get timeSeconds => $composableBuilder(
    column: $table.timeSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get playedAt => $composableBuilder(
    column: $table.playedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MemoryBesttimesTableOrderingComposer
    extends Composer<_$AppDatabase, $MemoryBesttimesTable> {
  $$MemoryBesttimesTableOrderingComposer({
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

  ColumnOrderings<String> get gridSize => $composableBuilder(
    column: $table.gridSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pairType => $composableBuilder(
    column: $table.pairType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get moves => $composableBuilder(
    column: $table.moves,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get timeSeconds => $composableBuilder(
    column: $table.timeSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get playedAt => $composableBuilder(
    column: $table.playedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MemoryBesttimesTableAnnotationComposer
    extends Composer<_$AppDatabase, $MemoryBesttimesTable> {
  $$MemoryBesttimesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get gridSize =>
      $composableBuilder(column: $table.gridSize, builder: (column) => column);

  GeneratedColumn<String> get pairType =>
      $composableBuilder(column: $table.pairType, builder: (column) => column);

  GeneratedColumn<int> get moves =>
      $composableBuilder(column: $table.moves, builder: (column) => column);

  GeneratedColumn<int> get timeSeconds => $composableBuilder(
    column: $table.timeSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<int> get playedAt =>
      $composableBuilder(column: $table.playedAt, builder: (column) => column);
}

class $$MemoryBesttimesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MemoryBesttimesTable,
          MemoryBesttime,
          $$MemoryBesttimesTableFilterComposer,
          $$MemoryBesttimesTableOrderingComposer,
          $$MemoryBesttimesTableAnnotationComposer,
          $$MemoryBesttimesTableCreateCompanionBuilder,
          $$MemoryBesttimesTableUpdateCompanionBuilder,
          (
            MemoryBesttime,
            BaseReferences<
              _$AppDatabase,
              $MemoryBesttimesTable,
              MemoryBesttime
            >,
          ),
          MemoryBesttime,
          PrefetchHooks Function()
        > {
  $$MemoryBesttimesTableTableManager(
    _$AppDatabase db,
    $MemoryBesttimesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MemoryBesttimesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MemoryBesttimesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MemoryBesttimesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> gridSize = const Value.absent(),
                Value<String> pairType = const Value.absent(),
                Value<int> moves = const Value.absent(),
                Value<int> timeSeconds = const Value.absent(),
                Value<int> playedAt = const Value.absent(),
              }) => MemoryBesttimesCompanion(
                id: id,
                gridSize: gridSize,
                pairType: pairType,
                moves: moves,
                timeSeconds: timeSeconds,
                playedAt: playedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String gridSize,
                required String pairType,
                required int moves,
                required int timeSeconds,
                required int playedAt,
              }) => MemoryBesttimesCompanion.insert(
                id: id,
                gridSize: gridSize,
                pairType: pairType,
                moves: moves,
                timeSeconds: timeSeconds,
                playedAt: playedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MemoryBesttimesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MemoryBesttimesTable,
      MemoryBesttime,
      $$MemoryBesttimesTableFilterComposer,
      $$MemoryBesttimesTableOrderingComposer,
      $$MemoryBesttimesTableAnnotationComposer,
      $$MemoryBesttimesTableCreateCompanionBuilder,
      $$MemoryBesttimesTableUpdateCompanionBuilder,
      (
        MemoryBesttime,
        BaseReferences<_$AppDatabase, $MemoryBesttimesTable, MemoryBesttime>,
      ),
      MemoryBesttime,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$SrsCardsTableTableManager get srsCards =>
      $$SrsCardsTableTableManager(_db, _db.srsCards);
  $$LessonProgressTableTableManager get lessonProgress =>
      $$LessonProgressTableTableManager(_db, _db.lessonProgress);
  $$UserStatsTableTableManager get userStats =>
      $$UserStatsTableTableManager(_db, _db.userStats);
  $$StudyHistoryTableTableManager get studyHistory =>
      $$StudyHistoryTableTableManager(_db, _db.studyHistory);
  $$BlitzHighscoresTableTableManager get blitzHighscores =>
      $$BlitzHighscoresTableTableManager(_db, _db.blitzHighscores);
  $$MemoryBesttimesTableTableManager get memoryBesttimes =>
      $$MemoryBesttimesTableTableManager(_db, _db.memoryBesttimes);
}
