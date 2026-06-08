import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../core/tts_service.dart';

class AudioButton extends StatefulWidget {
  final String text;
  final bool slow;
  final double size;

  const AudioButton({
    super.key,
    required this.text,
    this.slow = false,
    this.size = 40,
  });

  @override
  State<AudioButton> createState() => _AudioButtonState();
}

class _AudioButtonState extends State<AudioButton> {
  bool _playing = false;

  Future<void> _play() async {
    if (_playing) return;
    setState(() => _playing = true);
    if (widget.slow) {
      await TtsService.instance.speakSlow(widget.text);
    } else {
      await TtsService.instance.speak(widget.text);
    }
    if (mounted) setState(() => _playing = false);
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _play,
      borderRadius: BorderRadius.circular(widget.size / 2),
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: _playing
              ? AppColors.red.withOpacity(0.1)
              : AppColors.card,
          shape: BoxShape.circle,
          border: Border.all(
            color: _playing ? AppColors.red : AppColors.border,
            width: 1,
          ),
        ),
        child: Icon(
          _playing ? Icons.volume_up : Icons.volume_up_outlined,
          size: widget.size * 0.5,
          color: _playing ? AppColors.red : AppColors.ink2,
        ),
      ),
    );
  }
}

class LargeAudioButton extends StatefulWidget {
  final String text;

  const LargeAudioButton({super.key, required this.text});

  @override
  State<LargeAudioButton> createState() => _LargeAudioButtonState();
}

class _LargeAudioButtonState extends State<LargeAudioButton> {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _AudioBtn(
          icon: Icons.play_arrow_outlined,
          label: 'Normal',
          onTap: () => TtsService.instance.speak(widget.text),
        ),
        const SizedBox(width: 12),
        _AudioBtn(
          icon: Icons.slow_motion_video_outlined,
          label: 'Langsam',
          onTap: () => TtsService.instance.speakSlow(widget.text),
        ),
      ],
    );
  }
}

class _AudioBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _AudioBtn({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: AppColors.ink2),
            const SizedBox(width: 6),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
