import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kwrmyanmar/core/ai_evidence.dart';
import 'package:kwrmyanmar/core/conversation.dart';
import 'package:kwrmyanmar/core/handbook.dart';
import 'package:kwrmyanmar/core/models.dart';

void main() {
  final guides =
      (jsonDecode(File('assets/cards.json').readAsStringSync()) as List)
          .map((j) => LegalCard.fromJson(Map<String, dynamic>.from(j)))
          .toList();
  final sources =
      (jsonDecode(File('assets/sources.json').readAsStringSync()) as List)
          .map((j) => SourceDocument.fromJson(Map<String, dynamic>.from(j)))
          .toList();
  final index = HandbookIndex(guides, sources);

  test('new cases isolate old questions, including pre-upgrade history', () {
    final rows = <Map<String, dynamic>>[
      {'question': 'legacy private case'},
      {'session_id': 'a', 'question': 'လစာမရ'},
      {'session_id': 'b', 'question': 'ဆေးရုံသွားမယ်'},
    ];
    expect(sessionTurns(rows, 'current'), isEmpty);
    expect(sessionTurns(rows, 'a').single['question'], 'လစာမရ');
    expect(
      sessionTurns(rows, 'legacy').single['question'],
      'legacy private case',
    );
    expect(conversationSearchQuery('ဘယ်မှာတင်ရမလဲ', []), 'ဘယ်မှာတင်ရမလဲ');
  });

  test(
    'follow-up search keeps the problem and an explicit new topic replaces it',
    () {
      final turns = <Map<String, dynamic>>[
        {'question': 'သူဌေးက ပိုက်ဆံမရှင်းပေးဘူး'},
      ];
      final query = conversationSearchQuery('အဲ့ဒါကို ဘယ်မှာတင်ရမလဲ', turns);
      expect(query, contains('ပိုက်ဆံမရှင်း'));
      expect(index.search(query, kind: 'guides').first.guide!.id, 'unpaid');
      expect(
        conversationSearchQuery('ကျန်းမာရေးအာမခံကို စစ်ချင်တယ်', turns),
        'ကျန်းမာရေးအာမခံကို စစ်ချင်တယ်',
      );
    },
  );

  test(
    'replay is bounded, masks identifiers and excludes old private snapshots',
    () {
      final turns = List<Map<String, dynamic>>.generate(
        8,
        (i) => {
          'question': 'question $i MA1234567',
          'answer': List.filled(3000, 'a').join(),
          'questions': ['email x@example.com'],
          'steps': ['passport MA1234567'],
          'context_snapshot': 'OLD_PRIVATE_PROFILE',
          'source_snapshot': ['OLD_DOCUMENT_TEXT'],
          'claims': [
            {
              'text': 'OLD_CLAIM',
              'source_ids': ['not-current'],
            },
          ],
        },
      );
      final messages = conversationMessages(turns);
      expect(messages.length, 8);
      final text = jsonEncode(messages);
      expect(text, contains('question 4'));
      for (final secret in [
        'question 3',
        'MA1234567',
        'x@example.com',
        'OLD_PRIVATE_PROFILE',
        'OLD_DOCUMENT_TEXT',
        'not-current',
      ]) {
        expect(text, isNot(contains(secret)));
      }
      expect(jsonDecode(messages[1]['content']!)['answer'].length, 2601);
      expect(messages.map((m) => m['role']).toList(), [
        'user',
        'assistant',
        'user',
        'assistant',
        'user',
        'assistant',
        'user',
        'assistant',
      ]);
    },
  );

  test(
    'colloquial unpaid intent outranks broad E9 and includes workplace change',
    () {
      for (final q in [
        'သူဌေးက ပိုက်ဆံမရှင်းပေးဘူး',
        'လုပ်အားခမရသေးဘူး',
        'လစာမပေးဘူး ဘယ်လိုလုပ်ရမလဲ',
      ]) {
        expect(
          index.search(q, kind: 'guides').first.guide!.id,
          'unpaid',
          reason: q,
        );
      }
      final ids = index
          .search(
            'E9 နဲ့ လစာမပေးလို့ အလုပ်ပြောင်းချင်တယ်',
            kind: 'guides',
            limit: 4,
          )
          .map((h) => h.guide!.id)
          .toList();
      expect(ids.take(2), containsAll(['unpaid', 'change1month']));
      expect(ids.first, isNot('e7route'));
    },
  );

  test(
    '30 workflows link only exact available pages and retain unresolved flags',
    () {
      final practical = guides
          .where((g) => g.procedure.questions.isNotEmpty)
          .toList();
      expect(practical.length, 30);
      for (final guide in practical) {
        expect(guide.procedure.documents, isNotEmpty);
        expect(guide.procedure.offices, isNotEmpty);
        expect(guide.procedure.phrases.single['ko'], isNotEmpty);
        expect(guide.steps.length, greaterThanOrEqualTo(4));
        for (final ref in guide.sourceRefs) {
          expect(
            resolveEvidence('src:${ref.sourceId}:${ref.page}', guides, sources),
            isNotNull,
          );
        }
      }
      for (final id in ['pension', 'severance', 'extension']) {
        expect(guides.firstWhere((g) => g.id == id).pending, true);
      }
      expect(guides.firstWhere((g) => g.id == 'tax').sourceIds, isEmpty);
    },
  );

  test(
    'retrieval follows reviewed pages, de-duplicates and caps transmitted text',
    () {
      final evidence = retrieveEvidence(index, 'သူဌေးက ပိုက်ဆံမရှင်းပေးဘူး');
      expect(evidence.first.guide!.id, 'unpaid');
      expect(evidence.map((e) => e.id), contains('src:wages:45'));
      expect(evidence.map((e) => e.id).toSet().length, evidence.length);
      expect(
        evidence.fold<int>(0, (n, e) => n + e.text.length),
        lessThanOrEqualTo(36000),
      );
    },
  );

  test(
    'strict answers reject missing claim citations and fabricated page IDs',
    () {
      Map<String, dynamic> reply() => {
        'status': 'supported',
        'answer': 'အဖြေ',
        'questions': [],
        'steps': [],
        'source_ids': ['src:wages:45'],
        'claims': [
          {
            'text': 'စစ်ရန်အချက်',
            'source_ids': ['src:wages:45'],
          },
        ],
      };
      bool valid(Map<String, dynamic> r) => AiAnswer.parse(jsonEncode(r), {
        'src:wages:45',
      }, requireGrounding: true).validated;
      expect(valid(reply()), true);
      expect(valid(reply()..['claims'] = []), false);
      expect(valid(reply()..['source_ids'] = []), false);
      expect(
        valid(
          reply()
            ..['claims'] = [
              {'text': 'unsupported', 'source_ids': []},
            ],
        ),
        false,
      );
      expect(
        valid(
          reply()
            ..['claims'] = [
              {
                'text': 'invented',
                'source_ids': ['src:wages:999'],
              },
            ],
        ),
        false,
      );
      expect(valid(reply()..['status'] = 'definitely_eligible'), false);
      expect(
        valid({
          'status': 'needs_information',
          'answer': 'ထပ်မေးပါမယ်',
          'questions': ['အလုပ်စရက်က?'],
          'steps': [],
          'source_ids': [],
          'claims': [],
        }),
        true,
      );
      expect(
        valid({
          'status': 'insufficient_evidence',
          'answer': 'ရင်းမြစ်မတွေ့ပါ',
          'questions': [],
          'steps': [],
          'source_ids': [],
          'claims': [],
        }),
        true,
      );
    },
  );
}
