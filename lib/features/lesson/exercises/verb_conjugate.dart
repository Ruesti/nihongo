import 'package:flutter/material.dart';

import '../../../core/theme.dart';
import '../../../data/vocab_800.dart';
import 'exercise_base.dart';

enum ConjugationPerson { ich, du, er, wir, ihr, sie }
enum ConjugationTense { present }

extension ConjugationPersonLabel on ConjugationPerson {
  String labelFor(String lang) {
    switch (lang) {
      case 'fr':
        const fr = ['je (ich)', 'tu (du)', 'il/elle (er/sie)', 'nous (wir)', 'vous (ihr)', 'ils/elles (sie)'];
        return fr[index];
      case 'it':
        const it = ['io (ich)', 'tu (du)', 'lui/lei (er/sie)', 'noi (wir)', 'voi (ihr)', 'loro (sie)'];
        return it[index];
      case 'es':
      default:
        const es = ['yo (ich)', 'tú (du)', 'él/ella (er/sie)', 'nosotros (wir)', 'vosotros (ihr)', 'ellos (sie)'];
        return es[index];
    }
  }

  String get label => labelFor('es');
}

String _conjugate(String infinitive, String group, ConjugationPerson person, String lang) {
  final stem = infinitive.substring(0, infinitive.length - 2);
  switch (lang) {
    case 'fr':
      if (group == 'ER') {
        const endings = ['e', 'es', 'e', 'ons', 'ez', 'ent'];
        return stem + endings[person.index];
      }
      if (group == 'RE') {
        const endings = ['ds', 'ds', 'd', 'ons', 'ez', 'ent'];
        final s = infinitive.substring(0, infinitive.length - 2);
        return s + endings[person.index];
      }
      return infinitive;
    case 'it':
      if (group == 'ARE') {
        const endings = ['o', 'i', 'a', 'iamo', 'ate', 'ano'];
        return stem + endings[person.index];
      }
      if (group == 'ERE') {
        const endings = ['o', 'i', 'e', 'iamo', 'ete', 'ono'];
        return stem + endings[person.index];
      }
      if (group == 'IRE') {
        const endings = ['o', 'i', 'e', 'iamo', 'ite', 'ono'];
        return stem + endings[person.index];
      }
      return infinitive;
    case 'es':
    default:
      if (group == 'AR') {
        const endings = ['o', 'as', 'a', 'amos', 'áis', 'an'];
        return stem + endings[person.index];
      }
      if (group == 'ER') {
        const endings = ['o', 'es', 'e', 'emos', 'éis', 'en'];
        return stem + endings[person.index];
      }
      if (group == 'IR') {
        const endings = ['o', 'es', 'e', 'imos', 'ís', 'en'];
        return stem + endings[person.index];
      }
      return infinitive;
  }
}

class VerbConjugateExercise extends StatefulWidget {
  final VocabEntry verb;
  final ConjugationPerson person;
  final OnExerciseDone onDone;

  const VerbConjugateExercise({
    super.key,
    required this.verb,
    required this.person,
    required this.onDone,
  });

  @override
  State<VerbConjugateExercise> createState() => _VerbConjugateExerciseState();
}

class _VerbConjugateExerciseState extends State<VerbConjugateExercise> {
  final _ctrl = TextEditingController();
  bool _submitted = false;
  bool _correct = false;

  String get _lang => widget.verb.languageCode;

  String get _expectedForm {
    final group = widget.verb.conjugationGroup ?? 'AR';
    return _conjugate(widget.verb.word, group, widget.person, _lang);
  }

  void _submit() {
    if (_submitted) {
      widget.onDone(_correct);
      return;
    }
    final input = _ctrl.text.trim().toLowerCase();
    final expected = _expectedForm.toLowerCase();
    setState(() {
      _submitted = true;
      _correct = input == expected;
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final personLabel = widget.person.labelFor(_lang);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Konjugiere:',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.ink2),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Text(
                  widget.verb.word,
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.red,
                      ),
                ),
                const SizedBox(height: 4),
                Text(widget.verb.meaningDe,
                    style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 16),
                Text(
                  personLabel,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (!_submitted) ...[
            TextField(
              controller: _ctrl,
              autofocus: true,
              decoration: const InputDecoration(hintText: 'Konjugierte Form…'),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submit,
                child: const Text('Prüfen'),
              ),
            ),
          ] else
            AnswerFeedback(
              correct: _correct,
              correctAnswer: _expectedForm,
              explanation: '$personLabel: ${widget.verb.word} → $_expectedForm',
              onContinue: () => widget.onDone(_correct),
            ),
        ],
      ),
    );
  }
}
