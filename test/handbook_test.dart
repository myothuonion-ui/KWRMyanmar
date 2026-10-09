import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
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
  test('pack has substantive guides and complete original page boundaries', () {
    expect(guides.length, 55);
    expect(guides.map((g) => g.id).toSet().length, guides.length);
    expect(guides.every((g) => g.sections.length >= 2), true);
    expect(
      guides.every(
        (g) => g.sourceIds.every((id) => sources.any((s) => s.id == id)),
      ),
      true,
    );
    expect(sources.length, 11);
    expect(sources.fold<int>(0, (n, s) => n + s.pages.length), 610);
    for (final s in sources.where((s) => s.asset.isNotEmpty)) {
      expect(File(s.asset).readAsBytesSync().take(5), [37, 80, 68, 70, 45]);
      expect(s.pages.every((p) => p.trim().isNotEmpty), true);
    }
  });
  test('search finds original-only text without a card and opens exact page', () {
    final text = '고용허가서';
    final hits = index.search(text, kind: 'sources');
    expect(hits, isNotEmpty);
    final hit = hits.first;
    expect(hit.guide, isNull);
    expect(hit.page, greaterThan(0));
    expect(
      foldSearch(hit.source!.pages[hit.page! - 1]),
      contains(foldSearch(text)),
    );
    // A synthetic source guarantees the query exists nowhere in guide metadata.
    final source = SourceDocument(
      id: 'test',
      title: 'မူရင်း',
      korean: '원문',
      category: 'အလုပ်',
      publisher: 'test',
      url: 'https://example.org',
      asset: '',
      edition: '2026',
      downloaded: '2026',
      pages: ['ပထမစာမျက်နှာ', '원문전용고유문구'],
    );
    final originalOnly = HandbookIndex(guides, [source]).search('원문전용고유문구');
    expect(originalOnly.single.page, 2);
    expect(originalOnly.single.source, source);
  });
  test('Burmese aliases and detailed sections retrieve beyond titles', () {
    expect(
      index.search('လစာမရဘူး', kind: 'guides').map((h) => h.guide!.id),
      contains('unpaid'),
    );
    expect(index.search('စက်ထိ', kind: 'sources'), isNotEmpty);
    expect(
      index.search('장기요양보험 가입제외', kind: 'guides').map((h) => h.guide!.id),
      contains('longterm'),
    );
    expect(
      index.search('အာမခံငွေ', kind: 'guides').map((h) => h.guide!.id),
      contains('deposit_return'),
    );
    expect(foldSearch('E-၉\u200b'), 'e9');
    expect(index.search('neverfoundzzzzzz'), isEmpty);
  });
  test('filters respect source vs guide and category', () {
    expect(
      index
          .search('အာမခံ', kind: 'guides', category: 'အာမခံ')
          .every((h) => h.guide?.category == 'အာမခံ'),
      true,
    );
    expect(
      index
          .search('임금', kind: 'sources')
          .every((h) => h.source != null && h.guide == null),
      true,
    );
  });
}
