import 'package:flutter_test/flutter_test.dart';
import 'package:kwrmyanmar/core/ai_evidence.dart';
import 'package:kwrmyanmar/core/ai_service.dart';
import 'package:kwrmyanmar/core/handbook.dart';
import 'package:kwrmyanmar/core/models.dart';

SourceDocument original(List<String> pages) => SourceDocument(
  id: 'test',
  title: 'မူရင်းစာအုပ်',
  korean: '공식 원문',
  category: 'အလုပ်',
  publisher: 'Test publisher',
  url: 'https://example.org',
  asset: '',
  edition: '2025-02-01',
  downloaded: '2026-10-09',
  pages: pages,
);

void main() {
  test('AI retrieves original-only text and validates exact-page citations', () {
    final source = original(['첫 페이지', '원문전용고유문구 신청 절차']);
    final evidence = retrieveEvidence(HandbookIndex([], [source]), '원문전용고유문구');
    expect(evidence.single.id, 'src:test:2');
    final prompt = legalSystemPrompt(evidence, 'SELECTED CONTEXT');
    expect(prompt, contains('원문전용고유문구 신청 절차'));
    expect(prompt, contains('edition: 2025-02-01; page: 2'));
    expect(prompt, contains('[src:test:2]'));
    final ids = evidence.map((e) => e.id).toSet();
    expect(
      AiAnswer.parse(
        '{"answer":"x","questions":[],"steps":[],"source_ids":["src:test:2"]}',
        ids,
      ).validated,
      true,
    );
    expect(
      AiAnswer.parse(
        '{"answer":"x","questions":[],"steps":[],"source_ids":["src:test:1"]}',
        ids,
      ).validated,
      false,
    );
    expect(resolveEvidence('src:test:2', [], [source])!.page, 2);
    for (final id in [
      'src:test:0',
      'src:test:3',
      'src:missing:1',
      'src:test:no',
    ]) {
      expect(resolveEvidence(id, [], [source]), isNull);
    }
  });

  test(
    'bounded source passage retains a match beyond the first 6000 characters',
    () {
      final source = original([
        '${List.filled(1500, '첫줄 내용\n').join()}원문전용고유문구 신청 절차',
      ]);
      final evidence = retrieveEvidence(
        HandbookIndex([], [source]),
        '원문전용고유문구',
      );
      expect(evidence.single.text, contains('원문전용고유문구 신청 절차'));
      expect(evidence.single.text, contains('surrounding text omitted'));
      expect(evidence.single.text.length, lessThan(6500));
    },
  );
}
