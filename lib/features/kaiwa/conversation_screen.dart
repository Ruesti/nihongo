import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/api_key_service.dart';
import '../../core/database.dart';
import '../../core/theme.dart';
import '../../core/tts_service.dart';
import '../../models/conversation.dart';
import '../home/home_screen.dart';
import 'conversation_review.dart';

class ConversationScreen extends ConsumerStatefulWidget {
  final ConversationScenario scenario;

  const ConversationScreen({super.key, required this.scenario});

  @override
  ConsumerState<ConversationScreen> createState() =>
      _ConversationScreenState();
}

class _ConversationScreenState extends ConsumerState<ConversationScreen> {
  final List<ConversationMessage> _messages = [];
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _loading = false;
  bool _hasApiKey = false;
  int _userLevel = 25;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final hasKey = await ApiKeyService.hasKey();
    final progressAsync = ref.read(userProgressProvider('ja'));
    final progress = progressAsync.asData?.value;
    setState(() {
      _hasApiKey = hasKey;
      _userLevel = progress?.completedLessons ?? 25;
    });
    if (hasKey) _addOpening();
  }

  void _addOpening() {
    final opening = ConversationMessage(
      role: 'assistant',
      content: widget.scenario.openingLine,
    );
    setState(() {
      _messages.add(opening);
    });
    TtsService.instance.speak(widget.scenario.openingLine);
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty || _loading) return;

    _inputCtrl.clear();
    setState(() {
      _messages.add(ConversationMessage(role: 'user', content: text));
      _loading = true;
    });
    _scroll();

    try {
      final systemPrompt = _buildSystemPrompt();
      final response = await AnthropicClient.converse(
        history: _messages
            .where((m) => m.role == 'user' || m.role == 'assistant')
            .map((m) => {'role': m.role, 'content': m.content})
            .toList(),
        systemPrompt: systemPrompt,
        userMessage: text,
      );

      if (mounted) {
        setState(() {
          _messages.add(ConversationMessage(
            role: 'assistant',
            content: response,
          ));
          _loading = false;
        });
        TtsService.instance.speak(response);
        _scroll();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        _showError('Fehler: $e');
      }
    }
  }

  String _buildSystemPrompt() {
    return '${widget.scenario.systemPrompt}\n\nUser level: $_userLevel/50';
  }

  void _scroll() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _endConversation() async {
    if (_messages.length < 2) {
      Navigator.of(context).pop();
      return;
    }
    // Record conversation session
    final db = ref.read(dbProvider);
    await db.incrementConversationSessions();

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ConversationReview(
          scenario: widget.scenario,
          messages: List.from(_messages),
          userLevel: _userLevel,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasApiKey) {
      return _NoApiKeyScreen(
          scenarioTitle: widget.scenario.titleDe);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.scenario.titleJp),
        actions: [
          TextButton(
            onPressed: _endConversation,
            child: Text(
              'Beenden',
              style: TextStyle(color: AppColors.red),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_loading ? 1 : 0),
              itemBuilder: (context, i) {
                if (i == _messages.length) {
                  return _TypingIndicator();
                }
                final msg = _messages[i];
                return _MessageBubble(message: msg);
              },
            ),
          ),
          if (widget.scenario.suggestedPhrases.isNotEmpty && _messages.length < 3)
            _SuggestionBar(
              phrases: widget.scenario.suggestedPhrases,
              onTap: (p) {
                _inputCtrl.text = p;
                _send();
              },
            ),
          _InputBar(
            controller: _inputCtrl,
            onSend: _send,
            loading: _loading,
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ConversationMessage message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isUser ? AppColors.red.withOpacity(0.1) : AppColors.card,
          borderRadius: BorderRadius.circular(12).copyWith(
            bottomRight: isUser ? const Radius.circular(2) : null,
            bottomLeft: isUser ? null : const Radius.circular(2),
          ),
          border: Border.all(
            color: isUser
                ? AppColors.red.withOpacity(0.3)
                : AppColors.border,
          ),
        ),
        child: Text(
          message.content,
          style: isUser
              ? Theme.of(context).textTheme.bodyMedium
              : AppTheme.jpBody.copyWith(fontSize: 15),
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: const SizedBox(
          width: 40,
          height: 16,
          child: _DotsAnimation(),
        ),
      ),
    );
  }
}

class _DotsAnimation extends StatefulWidget {
  const _DotsAnimation();

  @override
  State<_DotsAnimation> createState() => _DotsAnimationState();
}

class _DotsAnimationState extends State<_DotsAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (i) {
            final delay = i / 3;
            final opacity =
                ((_ctrl.value + delay) % 1.0 > 0.5) ? 1.0 : 0.3;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: AppColors.ink2.withOpacity(opacity),
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }
}

class _SuggestionBar extends StatelessWidget {
  final List<String> phrases;
  final void Function(String) onTap;

  const _SuggestionBar({required this.phrases, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.paper2,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        children: phrases.map((p) {
          return GestureDetector(
            onTap: () => onTap(p),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(p, style: AppTheme.jpBody.copyWith(fontSize: 12)),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final bool loading;

  const _InputBar({
    required this.controller,
    required this.onSend,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                decoration: const InputDecoration(
                  hintText: '日本語で答えてください…',
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
                onSubmitted: (_) => onSend(),
                textInputAction: TextInputAction.send,
              ),
            ),
            const SizedBox(width: 8),
            loading
                ? const SizedBox(
                    width: 44,
                    height: 44,
                    child: Center(
                      child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2)),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.send),
                    color: AppColors.red,
                    onPressed: onSend,
                  ),
          ],
        ),
      ),
    );
  }
}

class _NoApiKeyScreen extends StatelessWidget {
  final String scenarioTitle;

  const _NoApiKeyScreen({required this.scenarioTitle});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(scenarioTitle)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🔑', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 24),
              Text(
                'API-Key erforderlich',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                'Für KI-Konversation benötigst du einen Anthropic API-Key. '
                'Richte ihn in den Einstellungen ein.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Zurück'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
