import 'dart:convert';

import 'handbook.dart';
import 'rules.dart';

/// Old turns and private document snapshots never enter a new case implicitly.
List<Map<String, dynamic>> sessionTurns(
  List<Map<String, dynamic>> history,
  String sessionId,
) => history.where((t) => (t['session_id'] ?? 'legacy') == sessionId).toList();

String conversationSearchQuery(
  String question,
  List<Map<String, dynamic>> turns,
) {
  if (turns.isEmpty || hasSpecificSearchIntent(question)) return question;
  final previous =
      (turns.last['retrieval_query'] ?? turns.last['question'] ?? '')
          .toString();
  final bounded = previous.length > 1800
      ? previous.substring(previous.length - 1800)
      : previous;
  return '$bounded\n$question'.trim();
}

/// Only visible question/answer/clarifications are replayed, never old selected
/// profile, imported text, or context snapshots. Every replay is previewed.
List<Map<String, String>> conversationMessages(
  List<Map<String, dynamic>> turns, {
  int maxTurns = 4,
}) {
  final recent = turns.skip(
    turns.length > maxTurns ? turns.length - maxTurns : 0,
  );
  String bounded(Object? value, int max) {
    final text = maskPrivateText((value ?? '').toString());
    return text.length > max ? '${text.substring(0, max)}…' : text;
  }

  return [
    for (final turn in recent) ...[
      {'role': 'user', 'content': bounded(turn['question'], 1600)},
      {
        'role': 'assistant',
        'content': jsonEncode({
          'answer': bounded(turn['answer'], 2600),
          'questions': (turn['questions'] as List? ?? [])
              .take(5)
              .map((q) => bounded(q, 400))
              .toList(),
          'steps': (turn['steps'] as List? ?? [])
              .take(5)
              .map((s) => bounded(s, 600))
              .toList(),
          // Previous citations are historical, not current evidence IDs.
          'historical_answer': true,
        }),
      },
    ],
  ];
}
