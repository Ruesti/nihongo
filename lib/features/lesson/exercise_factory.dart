import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/language_module.dart';
import '../../data/kana_data.dart';
import '../../data/vocab_800.dart';
import '../../models/lesson.dart';
import 'exercises/exercise_base.dart';
import 'exercises/free_write.dart';
import 'exercises/gender_exercise.dart';
import 'exercises/kana_read.dart';
import 'exercises/tone_exercise.dart';
import 'exercises/kana_write.dart';
import 'exercises/sentence_build.dart';
import 'exercises/verb_conjugate.dart';
import 'exercises/vocab_listen.dart';
import 'exercises/vocab_meaning.dart';
import 'exercises/vocab_speak.dart';

final _rng = Random();

class ExerciseFactory {
  final Lesson lesson;
  final List<VocabEntry> vocabPool;
  final int userLevel;
  final LanguageModule? languageModule;

  ExerciseFactory({
    required this.lesson,
    required this.vocabPool,
    required this.userLevel,
    this.languageModule,
  });

  // Returns a list of exercise widgets for the lesson
  List<Widget Function(OnExerciseDone)> buildSession() {
    final exercises = <Widget Function(OnExerciseDone)>[];

    switch (lesson.category) {
      case LessonCategory.kana:
        exercises.addAll(_kanaExercises());
      case LessonCategory.vocab:
        exercises.addAll(_vocabExercises());
      case LessonCategory.grammar:
        exercises.addAll(_grammarExercises());
      case LessonCategory.listening:
        exercises.addAll(_listeningExercises());
      case LessonCategory.speaking:
        exercises.addAll(_speakingExercises());
      case LessonCategory.story:
        // Story exercises are handled by lesson_screen differently
        break;
    }

    // Ensure at least 5 exercises, max 15
    return exercises.take(15).toList();
  }

  List<Widget Function(OnExerciseDone)> _kanaExercises() {
    final result = <Widget Function(OnExerciseDone)>[];
    final kanaCards = _getKanaForLesson();
    if (kanaCards.isEmpty) return result;

    for (final k in kanaCards) {
      // Alternate read and write
      result.add((onDone) => KanaReadExercise(kana: k, onDone: onDone));
      final distractors = _getDistractors(k, kanaCards, count: 3);
      result.add((onDone) => KanaWriteExercise(
            kana: k,
            distractors: distractors,
            onDone: onDone,
          ));
    }
    result.shuffle();
    return result;
  }

  List<Widget Function(OnExerciseDone)> _vocabExercises() {
    final result = <Widget Function(OnExerciseDone)>[];
    final vocab = _getVocabForLesson();
    if (vocab.isEmpty) return result;

    final hasGender = languageModule?.hasGender ?? false;
    final hasConjugation = languageModule?.hasConjugation ?? false;
    final hasTones = languageModule?.hasToneSystem ?? false;
    final genderOptions = _genderOptionsForModule();

    for (final v in vocab) {
      result.add((onDone) => VocabMeaningExercise(vocab: v, onDone: onDone));
      // Add listen exercise for 50% of vocab
      if (_rng.nextBool()) {
        result.add((onDone) => VocabListenExercise(vocab: v, onDone: onDone));
      }
      // Gender exercise for nouns with known gender
      if (hasGender && v.gender != null && genderOptions.isNotEmpty) {
        result.add((onDone) => GenderExercise(
              noun: v,
              options: genderOptions,
              onDone: onDone,
            ));
      }
      // Conjugation exercise for verbs with a conjugation group
      if (hasConjugation && v.conjugationGroup != null) {
        final person = ConjugationPerson
            .values[_rng.nextInt(ConjugationPerson.values.length)];
        result.add((onDone) => VerbConjugateExercise(
              verb: v,
              person: person,
              onDone: onDone,
            ));
      }
      // Ton-Übung für Mandarin (wenn tonePattern bekannt)
      if (hasTones && v.tonePattern != null && v.tonePattern!.isNotEmpty) {
        result.add((onDone) => ToneExercise(word: v, onDone: onDone));
      }
      // Add example sentence exercise if available
      if (v.example.isNotEmpty && userLevel >= 15) {
        result.add((onDone) => SentenceBuildExercise(
              sentence: v.example,
              translation: v.exampleDe,
              onDone: onDone,
            ));
      }
    }
    result.shuffle();
    return result;
  }

  List<String> _genderOptionsForModule() {
    switch (languageModule?.code) {
      case 'es':
        return ['el', 'la'];
      case 'fr':
        return ['le', 'la'];
      case 'de':
        return ['der', 'die', 'das'];
      default:
        return [];
    }
  }

  List<Widget Function(OnExerciseDone)> _grammarExercises() {
    final result = <Widget Function(OnExerciseDone)>[];
    final vocab = _getVocabForLesson();

    for (final v in vocab) {
      result.add((onDone) => VocabMeaningExercise(vocab: v, onDone: onDone));
      if (v.example.isNotEmpty) {
        result.add((onDone) => SentenceBuildExercise(
              sentence: v.example,
              translation: v.exampleDe,
              onDone: onDone,
            ));
      }
    }

    // Add free-write for grammar context
    if (userLevel >= 20) {
      result.add((onDone) => FreeWriteExercise(
            scenario: 'Grammatik: ${lesson.titleDe}',
            task: 'Schreibe einen Satz mit der Grammatik aus dieser Lektion.',
            taskJp: 'この文法を使って文を書いてください。',
            onDone: onDone,
          ));
    }
    return result;
  }

  List<Widget Function(OnExerciseDone)> _listeningExercises() {
    final result = <Widget Function(OnExerciseDone)>[];
    final kanaCards = _getKanaForLesson();
    final vocab = _getVocabForLesson();

    for (final k in kanaCards) {
      result.add((onDone) => KanaWriteExercise(
            kana: k,
            distractors: _getDistractors(k, kanaCards, count: 3),
            onDone: onDone,
          ));
    }
    for (final v in vocab) {
      result.add((onDone) => VocabListenExercise(vocab: v, onDone: onDone));
    }
    return result;
  }

  List<Widget Function(OnExerciseDone)> _speakingExercises() {
    final result = <Widget Function(OnExerciseDone)>[];
    final vocab = _getVocabForLesson();

    for (final v in vocab) {
      result.add((onDone) => VocabSpeakExercise(vocab: v, onDone: onDone));
      // Also show meaning so user understands what to say
      result.add((onDone) => VocabMeaningExercise(vocab: v, onDone: onDone));
    }
    result.shuffle();
    return result;
  }

  List<KanaEntry> _getKanaForLesson() {
    final all = [...hiragana, ...katakana];
    return all.where((k) => lesson.cardIds.contains(k.cardId)).toList();
  }

  List<VocabEntry> _getVocabForLesson() {
    return vocabPool
        .where((v) => lesson.cardIds.contains(v.cardId))
        .toList();
  }

  List<KanaEntry> _getDistractors(
      KanaEntry target, List<KanaEntry> pool, {required int count}) {
    final candidates = pool.where((k) => k.cardId != target.cardId).toList();
    candidates.shuffle();
    return candidates.take(count).toList();
  }
}
