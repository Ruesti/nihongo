import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/api_key_service.dart';
import '../../core/theme.dart';
import '../../models/conversation.dart';

class ConversationReview extends ConsumerStatefulWidget {
  final ConversationScenario scenario;
  final List<ConversationMessage> messages;
  final int userLevel;

  const ConversationReview({
    super.key,
    required this.scenario,
    required this.messages,
    required this.userLevel,
  });

  @override
  ConsumerState<ConversationReview> createState() =>
      _ConversationReviewState();
}

class _ConversationReviewState extends ConsumerState<ConversationReview> {
  String? _feedback;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFeedback();
  }

  Future<void> _loadFeedback() async {
    try {
      final apiKey = await ApiKeyService.get();
      if (apiKey == null || apiKey.isEmpty) {
        setState(() {
          _loading = false;
          _error = 'Kein API-Key';
        });
        return;
      }
      final feedback = await AnthropicClient.reviewConversation(
        history: widget.messages
            .map((m) => {'role': m.role, 'content': m.content})
            .toList(),
        userLevel: widget.userLevel,
        targetLanguage: 'Japanisch',
      );
      setState(() {
        _feedback = feedback;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Feedback')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ConversationSummary(
            messageCount: widget.messages.length,
            userMessages:
                widget.messages.where((m) => m.role == 'user').length,
            scenario: widget.scenario,
          ),
          const SizedBox(height: 16),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_error != null)
            Text(
              'Feedback nicht verfügbar: $_error',
              style: TextStyle(color: AppColors.ink2),
            )
          else if (_feedback != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                _feedback!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () =>
                  Navigator.of(context).popUntil((r) => r.isFirst),
              child: const Text('Zurück zur Übersicht'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConversationSummary extends StatelessWidget {
  final int messageCount;
  final int userMessages;
  final ConversationScenario scenario;

  const _ConversationSummary({
    required this.messageCount,
    required this.userMessages,
    required this.scenario,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            scenario.titleJp,
            style: AppTheme.jpBody.copyWith(fontWeight: FontWeight.w700),
          ),
          Text(
            scenario.titleDe,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.ink2,
                ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _Chip(label: '$userMessages Nachrichten'),
              const SizedBox(width: 8),
              _Chip(label: 'Gesamt: $messageCount'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;

  const _Chip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.paper2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        label,
        style: Theme.of(context)
            .textTheme
            .bodySmall
            ?.copyWith(color: AppColors.ink2),
      ),
    );
  }
}
