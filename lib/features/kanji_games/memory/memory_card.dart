import 'package:flutter/material.dart';

import '../../../core/theme.dart';

enum MemoryCardType { kanji, meaning, reading }

class MemoryCardData {
  final String pairId;
  final MemoryCardType type;
  final String content;
  bool isFlipped;
  bool isMatched;

  MemoryCardData({
    required this.pairId,
    required this.type,
    required this.content,
    this.isFlipped = false,
    this.isMatched = false,
  });
}

class MemoryCardWidget extends StatefulWidget {
  final MemoryCardData card;
  final VoidCallback onTap;
  final bool showPulse;

  const MemoryCardWidget({
    super.key,
    required this.card,
    required this.onTap,
    this.showPulse = false,
  });

  @override
  State<MemoryCardWidget> createState() => _MemoryCardWidgetState();
}

class _MemoryCardWidgetState extends State<MemoryCardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _flipAnim;
  bool _wasFlipped = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _flipAnim = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    _wasFlipped = widget.card.isFlipped || widget.card.isMatched;
    if (_wasFlipped) _ctrl.value = 1.0;
  }

  @override
  void didUpdateWidget(MemoryCardWidget old) {
    super.didUpdateWidget(old);
    final nowFlipped = widget.card.isFlipped || widget.card.isMatched;
    if (nowFlipped && !_wasFlipped) {
      _ctrl.forward();
    } else if (!nowFlipped && _wasFlipped) {
      _ctrl.reverse();
    }
    _wasFlipped = nowFlipped;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.card.isMatched ? null : widget.onTap,
      child: AnimatedBuilder(
        animation: _flipAnim,
        builder: (context, _) {
          final angle = _flipAnim.value * 3.14159;
          final isFront = angle < 1.5708;
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.002)
              ..rotateY(angle),
            child: isFront
                ? _buildBack(context)
                : Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..rotateY(3.14159),
                    child: _buildFront(context),
                  ),
          );
        },
      ),
    );
  }

  Widget _buildBack(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.red.withOpacity(0.08),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.red.withOpacity(0.3)),
      ),
      child: Center(
        child: Text(
          '日',
          style: AppTheme.jpMedium.copyWith(
            color: AppColors.red.withOpacity(0.2),
            fontSize: 28,
          ),
        ),
      ),
    );
  }

  Widget _buildFront(BuildContext context) {
    Color borderColor = AppColors.border;
    Color bgColor = AppColors.card;
    if (widget.card.isMatched) {
      borderColor = AppColors.green.withOpacity(0.4);
      bgColor = AppColors.green.withOpacity(0.08);
    } else if (widget.showPulse) {
      borderColor = AppColors.red.withOpacity(0.5);
    }

    final isKanji = widget.card.type == MemoryCardType.kanji;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Center(
        child: Text(
          widget.card.content,
          style: isKanji
              ? AppTheme.jpMedium.copyWith(fontSize: 28)
              : Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
