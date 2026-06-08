import 'package:flutter/material.dart';

import '../../../data/vocab_800.dart';

typedef OnExerciseDone = void Function(bool correct);

abstract class ExerciseWidget extends StatefulWidget {
  const ExerciseWidget({super.key});
}

class ExerciseResult {
  final bool correct;
  final String userAnswer;
  final String correctAnswer;

  const ExerciseResult({
    required this.correct,
    required this.userAnswer,
    required this.correctAnswer,
  });
}

// Shared feedback overlay shown after answering
class AnswerFeedback extends StatelessWidget {
  final bool correct;
  final String correctAnswer;
  final String? explanation;
  final VoidCallback onContinue;

  const AnswerFeedback({
    super.key,
    required this.correct,
    required this.correctAnswer,
    this.explanation,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final color = correct ? const Color(0xFF2D6A4F) : const Color(0xFFB5191C);
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        border: Border(top: BorderSide(color: color.withOpacity(0.3))),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                correct ? Icons.check_circle_outline : Icons.cancel_outlined,
                color: color,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                correct ? 'Richtig!' : 'Richtige Antwort:',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: color,
                  fontSize: 14,
                ),
              ),
              if (!correct) ...[
                const SizedBox(width: 8),
                Text(
                  correctAnswer,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: color,
                    fontSize: 14,
                    fontFamily: 'NotoSerifJP',
                  ),
                ),
              ],
            ],
          ),
          if (explanation != null) ...[
            const SizedBox(height: 6),
            Text(
              explanation!,
              style: TextStyle(
                fontSize: 13,
                color: color.withOpacity(0.85),
              ),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onContinue,
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
              ),
              child: const Text('Weiter'),
            ),
          ),
        ],
      ),
    );
  }
}

// Checks whether user input matches expected answer
bool isAnswerCorrect(String userInput, String expected,
    {bool partial = false}) {
  final u = userInput.trim().toLowerCase();
  final e = expected.trim().toLowerCase();
  if (u == e) return true;
  // Accept common romanization variants
  if (e == 'shi' && u == 'si') return true;
  if (e == 'chi' && u == 'ti') return true;
  if (e == 'tsu' && u == 'tu') return true;
  if (e == 'fu' && u == 'hu') return true;
  // Partial match for meanings with /
  if (partial && (e.contains('/') || e.contains(','))) {
    final parts = e.split(RegExp(r'[/,]')).map((s) => s.trim());
    return parts.any((p) => p == u || p.startsWith(u) || u.contains(p));
  }
  return false;
}

// Extract vocab card info helper
String vocabCardId(VocabEntry v) => v.cardId;
