import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_key_service.dart';

class AnthropicClient {
  static const _model = 'claude-haiku-4-5-20251001';
  static const _url = 'https://api.anthropic.com/v1/messages';

  static Future<String?> _getKey() => ApiKeyService.get();

  // Grammatik-Feedback auf freie Eingabe
  static Future<String> getFeedback({
    required String userInput,
    required String scenario,
    required String task,
  }) async {
    final apiKey = await _getKey();
    if (apiKey == null) return 'Kein API-Key hinterlegt. Bitte in den Einstellungen eintragen.';

    final response = await http.post(
      Uri.parse(_url),
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
      },
      body: jsonEncode({
        'model': _model,
        'max_tokens': 500,
        'system': '''Du bist ein geduldiger Japanisch-Tutor.
Gib kurzes Feedback auf Deutsch:
1. Was war richtig
2. Was kann verbessert werden (mit korrigiertem Japanisch)
3. Ein natürlicher Modellsatz

Sei warm, direkt, kurz. Maximal 5 Sätze gesamt.''',
        'messages': [
          {
            'role': 'user',
            'content':
                'Szenario: $scenario\nAufgabe: $task\nMeine Antwort: $userInput'
          }
        ],
      }),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return data['content'][0]['text'] as String;
    } else {
      return 'Fehler beim Abrufen des Feedbacks (${response.statusCode}).';
    }
  }

  // Konversations-Antwort (nicht-streaming)
  static Future<String> converse({
    required List<Map<String, String>> history,
    required String systemPrompt,
    required String userMessage,
  }) async {
    final apiKey = await _getKey();
    if (apiKey == null) return 'APIキーが設定されていません。';

    final messages = [
      ...history.map((m) => {'role': m['role']!, 'content': m['content']!}),
      {'role': 'user', 'content': userMessage},
    ];

    final response = await http.post(
      Uri.parse(_url),
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
        'anthropic-beta': 'prompt-caching-2024-07-31',
      },
      body: jsonEncode({
        'model': _model,
        'max_tokens': 200,
        'system': [
          {
            'type': 'text',
            'text': systemPrompt,
            'cache_control': {'type': 'ephemeral'}
          }
        ],
        'messages': messages,
      }),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return data['content'][0]['text'] as String;
    } else {
      return 'エラーが発生しました。';
    }
  }

  // Streaming-Konversation (SSE)
  static Stream<String> converseStream({
    required List<Map<String, String>> history,
    required String systemPrompt,
    required String userMessage,
  }) async* {
    final apiKey = await _getKey();
    if (apiKey == null) {
      yield 'APIキーが設定されていません。';
      return;
    }

    final messages = [
      ...history.map((m) => {'role': m['role']!, 'content': m['content']!}),
      {'role': 'user', 'content': userMessage},
    ];

    final request = http.Request('POST', Uri.parse(_url));
    request.headers.addAll({
      'Content-Type': 'application/json',
      'x-api-key': apiKey,
      'anthropic-version': '2023-06-01',
      'anthropic-beta': 'prompt-caching-2024-07-31',
    });
    request.body = jsonEncode({
      'model': _model,
      'max_tokens': 200,
      'stream': true,
      'system': [
        {
          'type': 'text',
          'text': systemPrompt,
          'cache_control': {'type': 'ephemeral'}
        }
      ],
      'messages': messages,
    });

    final client = http.Client();
    try {
      final streamed = await client.send(request).timeout(const Duration(seconds: 30));
      await for (final chunk in streamed.stream.transform(utf8.decoder)) {
        for (final line in chunk.split('\n')) {
          if (line.startsWith('data: ')) {
            final data = line.substring(6).trim();
            if (data == '[DONE]') return;
            try {
              final json = jsonDecode(data);
              if (json['type'] == 'content_block_delta') {
                final text = json['delta']?['text'] as String?;
                if (text != null) yield text;
              }
            } catch (_) {}
          }
        }
      }
    } finally {
      client.close();
    }
  }

  // Konversationsnachbesprechung
  static Future<String> reviewConversation({
    required List<Map<String, String>> history,
    required int userLevel,
    required String targetLanguage,
  }) async {
    final apiKey = await _getKey();
    if (apiKey == null) return 'Kein API-Key.';

    final conv = history
        .map((m) => '${m['role'] == 'user' ? 'Lernender' : 'KI'}: ${m['content']}')
        .join('\n');

    final response = await http.post(
      Uri.parse(_url),
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
      },
      body: jsonEncode({
        'model': _model,
        'max_tokens': 600,
        'messages': [
          {
            'role': 'user',
            'content': '''Analysiere dieses $targetLanguage-Gespräch eines Lerners (Level $userLevel/50).
Gib Feedback auf Deutsch:

1. Was lief gut? (2-3 Punkte)
2. Grammatikfehler die auffielen (max 3, mit Korrektur)
3. Ein natürlicherer Alternativsatz für den schwächsten Moment
4. Nützliche Wörter/Ausdrücke zum Nachlernen

Unter 150 Wörter. Warmer, direkter Ton.

Gespräch:
$conv'''
          }
        ],
      }),
    ).timeout(const Duration(seconds: 45));

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return data['content'][0]['text'] as String;
    } else {
      return 'Fehler beim Laden der Nachbesprechung.';
    }
  }

  // Travel-Pack generieren
  static Future<String> generateTravelPack({
    required String countryCode,
    required String countryName,
    required String targetLanguage,
  }) async {
    final apiKey = await _getKey();
    if (apiKey == null) return '[]';

    final response = await http.post(
      Uri.parse('https://api.anthropic.com/v1/messages'),
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
      },
      body: jsonEncode({
        'model': 'claude-sonnet-4-6',
        'max_tokens': 4000,
        'messages': [
          {
            'role': 'user',
            'content': '''Erstelle 50 Reise-Phrasen für $countryName ($targetLanguage) als JSON-Array.

Format:
[
  {
    "target": "$targetLanguage-Phrase",
    "romanization": "Romanisierung (falls nötig, sonst null)",
    "germanDE": "Deutsche Bedeutung",
    "context": "Kontext-Hinweis",
    "isEssential": true/false,
    "category": "top10|greeting|food|transport|accommodation|shopping|emergency|smalltalk|numbers"
  },
  ...
]

Kategorienverteilung: 10 top10, 5 greeting, 8 food, 7 transport, 5 accommodation, 6 shopping, 5 emergency, 4 smalltalk.
Nur JSON zurückgeben, kein Text davor oder danach.'''
          }
        ],
      }),
    ).timeout(const Duration(seconds: 60));

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return data['content'][0]['text'] as String;
    }
    return '[]';
  }
}
