import 'package:flutter/material.dart';

import '../../../core/theme.dart';
import '../kanji_data.dart';

class QuizCard extends StatefulWidget {
  final KanjiEntry kanji;
  final bool showAnswer;
  final bool? wasCorrect;

  const QuizCard({
    super.key,
    required this.kanji,
    required this.showAnswer,
    this.wasCorrect,
  });

  @override
  State<QuizCard> createState() => _QuizCardState();
}

class _QuizCardState extends State<QuizCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _flipCtrl;
  late Animation<double> _flipAnim;
  bool _showingBack = false;

  @override
  void initState() {
    super.initState();
    _flipCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _flipAnim = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _flipCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(QuizCard old) {
    super.didUpdateWidget(old);
    if (widget.showAnswer && !old.showAnswer && !_showingBack) {
      _showingBack = true;
      _flipCtrl.forward();
    } else if (!widget.showAnswer && old.showAnswer) {
      _showingBack = false;
      _flipCtrl.reverse();
    }
  }

  @override
  void dispose() {
    _flipCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _flipAnim,
      builder: (context, _) {
        final angle = _flipAnim.value * 3.14159;
        final isFront = angle < 1.5708;
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(angle),
          child: isFront ? _buildFront(context) : _buildBack(context),
        );
      },
    );
  }

  Widget _buildFront(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          widget.kanji.kanji,
          style: AppTheme.jpLarge.copyWith(fontSize: 96),
        ),
      ),
    );
  }

  Widget _buildBack(BuildContext context) {
    Color borderColor = AppColors.border;
    Color bgColor = AppColors.card;
    if (widget.wasCorrect == true) {
      borderColor = AppColors.green.withOpacity(0.5);
      bgColor = AppColors.green.withOpacity(0.06);
    } else if (widget.wasCorrect == false) {
      borderColor = AppColors.red.withOpacity(0.5);
      bgColor = AppColors.red.withOpacity(0.06);
    }

    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()..rotateY(3.14159),
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              widget.kanji.kanji,
              style: AppTheme.jpMedium.copyWith(fontSize: 48),
            ),
            const SizedBox(height: 12),
            Text(
              widget.kanji.meaningDe,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: widget.wasCorrect == true
                        ? AppColors.green
                        : widget.wasCorrect == false
                            ? AppColors.red
                            : AppColors.ink,
                    fontWeight: FontWeight.w700,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'On\'yomi: ${widget.kanji.onyomi}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              'Kun\'yomi: ${widget.kanji.kunyomi}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (widget.kanji.examples.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                widget.kanji.examples.first,
                style: AppTheme.jpBody,
              ),
              if (widget.kanji.exampleMeanings.isNotEmpty)
                Text(
                  widget.kanji.exampleMeanings.first,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.ink2),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
