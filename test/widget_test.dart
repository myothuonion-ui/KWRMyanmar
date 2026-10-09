import 'dart:convert';
import 'dart:io';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kwrmyanmar/core/app_state.dart';
import 'package:kwrmyanmar/core/handbook.dart';
import 'package:kwrmyanmar/core/models.dart';
import 'package:kwrmyanmar/core/storage.dart';
import 'package:kwrmyanmar/main.dart';
import 'package:kwrmyanmar/screens/chat.dart';
import 'package:kwrmyanmar/screens/source_reader.dart';
import 'package:kwrmyanmar/screens/widgets.dart';

class MemoryVault extends Vault {
  MemoryVault(super.secure, super.directory, super.cipher);
  @override
  Future<void> save(Map<String, dynamic> state) async {}
  @override
  Future<String> keyFor(String provider) async => '';
}

Future<AppState> makeState() async {
  final vault = MemoryVault(
    const FlutterSecureStorage(),
    Directory.systemTemp,
    VaultCipher(await AesGcm.with256bits().newSecretKey()),
  );
  final cards =
      (jsonDecode(File('assets/cards.json').readAsStringSync()) as List)
          .map((j) => LegalCard.fromJson(Map<String, dynamic>.from(j)))
          .toList();
  final sources =
      (jsonDecode(File('assets/sources.json').readAsStringSync()) as List)
          .map((j) => SourceDocument.fromJson(Map<String, dynamic>.from(j)))
          .toList();
  return AppState(vault, cards, {
    'profile': {'visa': 'E-9', 'workers': 'unknown'},
    'settings': {
      'provider': 'gemini',
      'online': false,
      'profileContext': false,
      'providers': <String, dynamic>{},
    },
    'documents': [],
    'history': [],
    'events': [],
    'bookmarks': [],
  }, sources: sources);
}

void main() {
  testWidgets('five handbook tabs, source search and bookmarks work offline', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final state = await makeState();
    await tester.pumpWidget(KwrApp(state));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    for (final label in [
      'လက်စွဲ',
      'ရှာဖွေ',
      'သိမ်းထား',
      'ကိုယ့်ဖိုင်',
      'ပင်မ',
    ]) {
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text(label),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('ရှာဖွေ'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '원문전용고유문구');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(find.text('သက်ဆိုင်ရာစာသား မတွေ့သေးပါ'), findsOneWidget);
    await tester.pumpWidget(
      MaterialApp(
        theme: handbookTheme(Brightness.light),
        home: SourceReader(state, state.sources.first, initialPage: 17),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('စာမျက်နှာ 17 / 42'), findsOneWidget);
    await tester.tap(find.byTooltip('စာမျက်နှာသိမ်းရန်'));
    await tester.pumpAndSettle();
    expect(state.bookmarks, contains('src:workers:17'));
    await tester.tap(find.byTooltip('နောက်စာမျက်နှာ'));
    await tester.pumpAndSettle();
    expect(find.text('စာမျက်နှာ 18 / 42'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    state.dispose();
  });
  testWidgets(
    'compact phone and large text do not overflow; offline chat needs no key',
    (tester) async {
      tester.view.physicalSize = const Size(960, 1800);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final state = await makeState();
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
          child: KwrApp(state),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.byTooltip('AI'));
      await tester.pumpAndSettle();
      final chat = find.byType(ChatScreen);
      await tester.enterText(
        find.descendant(of: chat, matching: find.byType(TextField)),
        'အလုပ်ထုတ်',
      );
      await tester.tap(find.byTooltip('မေးမယ်'));
      await tester.pumpAndSettle();
      expect(state.history.length, 1);
      expect(state.history.first['online'], false);
      expect(state.history.first['source_ids'], isNotEmpty);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      state.dispose();
    },
  );
  testWidgets('guide contents jump and reader settings preserve bookmarks', (
    tester,
  ) async {
    final state = await makeState();
    final guide = state.cards.firstWhere((g) => g.id == 'healthinsurance');
    await state.toggleBookmark('dismissal20');
    await tester.pumpWidget(
      MaterialApp(
        theme: handbookTheme(Brightness.light),
        home: CardDetail(state, guide, (_) {}),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('စာလုံးကြီးရန်'));
    await tester.pumpAndSettle();
    expect(state.settings['readerScale'], closeTo(1.1, .001));
    await tester.tap(find.byTooltip('သိမ်းရန်'));
    await tester.pumpAndSettle();
    expect(state.bookmarks, containsAll(['dismissal20', 'healthinsurance']));
    await tester.tap(find.byTooltip('မာတိကာ'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(guide.sections.last.title).last);
    await tester.pumpAndSettle();
    final heading = find.text(guide.sections.last.title);
    expect(tester.getRect(heading).top, lessThan(200));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    state.dispose();
  });
}
