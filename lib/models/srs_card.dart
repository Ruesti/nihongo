class SrsCard {
  final int? id;
  final String cardId;
  final String front;
  final String back;
  final String? reading;
  final double ease;
  final int interval;
  final int reps;
  final int dueAt;
  final String cardType; // 'kana' | 'vocab' | 'grammar' | 'kanji'
  final String languageCode; // 'ja', 'ko', 'es', ...

  const SrsCard({
    this.id,
    required this.cardId,
    required this.front,
    required this.back,
    this.reading,
    this.ease = 2.5,
    this.interval = 0,
    this.reps = 0,
    this.dueAt = 0,
    required this.cardType,
    this.languageCode = 'ja',
  });

  SrsCard copyWith({
    int? id,
    String? cardId,
    String? front,
    String? back,
    String? reading,
    double? ease,
    int? interval,
    int? reps,
    int? dueAt,
    String? cardType,
    String? languageCode,
  }) {
    return SrsCard(
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

  Map<String, dynamic> toMap() => {
        'id': id,
        'card_id': cardId,
        'front': front,
        'back': back,
        'reading': reading,
        'ease': ease,
        'interval': interval,
        'reps': reps,
        'due_at': dueAt,
        'card_type': cardType,
        'language_code': languageCode,
      };

  factory SrsCard.fromMap(Map<String, dynamic> map) => SrsCard(
        id: map['id'] as int?,
        cardId: map['card_id'] as String,
        front: map['front'] as String,
        back: map['back'] as String,
        reading: map['reading'] as String?,
        ease: (map['ease'] as num).toDouble(),
        interval: map['interval'] as int,
        reps: map['reps'] as int,
        dueAt: map['due_at'] as int,
        cardType: map['card_type'] as String,
        languageCode: map['language_code'] as String? ?? 'ja',
      );
}
