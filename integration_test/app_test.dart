import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kwrmyanmar/core/app_state.dart';
import 'package:kwrmyanmar/core/document_service.dart';
import 'package:kwrmyanmar/core/storage.dart';
import 'package:kwrmyanmar/main.dart';
import 'package:kwrmyanmar/screens/chat.dart';
import 'package:kwrmyanmar/screens/source_reader.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('native vault, OCR, PDF and offline navigation', (tester) async {
    final reportError = FlutterError.onError;
    FlutterError.onError = (details) {
      print(
        'NATIVE_FLUTTER_ERROR: ${details.exceptionAsString()}\n${details.stack}',
      );
      reportError?.call(details);
    };
    try {
      print('NATIVE_STAGE: vault');
      final state = await AppState.load();
      await state.reset();
      await state.setProfile({
        'visa': 'E-9',
        'workers': '5+',
        'confirmed': true,
        'sector': 'PRIVATE_TEST_FACT',
      });
      final encrypted = await File(
        '${state.vault.directory.path}/state.enc',
      ).readAsBytes();
      expect(
        utf8.decode(encrypted, allowMalformed: true),
        isNot(contains('PRIVATE_TEST_FACT')),
      );
      final reopened = await Vault.open();
      expect((await reopened.load())['profile']['sector'], 'PRIVATE_TEST_FACT');
      await reopened.setKey('gemini', 'TEST_NOT_REAL');
      expect(await reopened.keyFor('gemini'), 'TEST_NOT_REAL');
      await reopened.setKey('gemini', '');
      await reopened.writeDocument(
        'native-test',
        Uint8List.fromList([5, 6, 7]),
      );
      expect(await reopened.readDocument('native-test'), [5, 6, 7]);
      await reopened.deleteDocument('native-test');
      print('NATIVE_STAGE: OCR');
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      canvas.drawRect(
        const Rect.fromLTWH(0, 0, 1400, 220),
        Paint()..color = Colors.white,
      );
      final painter = TextPainter(
        text: const TextSpan(
          text: 'CONTRACT 2026',
          style: TextStyle(color: Colors.black, fontSize: 110),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      painter.paint(canvas, const Offset(30, 45));
      final picture = recorder.endRecording();
      final image = await picture.toImage(1400, 220);
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      final extracted = await DocumentService().extract(
        png!.buffer.asUint8List(),
        'png',
        (_) {},
      );
      expect(extracted.toUpperCase(), contains('CONTRACT'));
      image.dispose();
      picture.dispose();
      print('NATIVE_STAGE: PDF');
      final pdf = base64Decode(testPdfBase64);
      final pdfText = await DocumentService().extract(pdf, 'pdf', (_) {});
      expect(pdfText, contains('CONTRACT TEST'));
      expect(pdfText, contains('Page 1'));
      print('NATIVE_STAGE: offline source PDF');
      final bundled = await rootBundle.load('assets/sources/workers.pdf');
      final source = await PdfDocument.openData(bundled.buffer.asUint8List());
      expect(source.pages.length, 42);
      final page17 = await source.pages[16].loadText();
      expect(page17?.fullText, contains('휴게'));
      final rendered = await source.pages[16].render(width: 320, height: 450);
      expect(rendered, isNotNull);
      rendered?.dispose();
      await source.dispose();
      final hits = state.index.search('고용허가서', kind: 'sources');
      expect(hits, isNotEmpty);
      await state.toggleBookmark('src:workers:17');
      expect(
        (await state.vault.load())['bookmarks'],
        contains('src:workers:17'),
      );
      print('NATIVE_STAGE: navigation');
      await tester.pumpWidget(KwrApp(state));
      await tester.pumpAndSettle();
      expect(find.text('KWR Myanmar'), findsOneWidget);
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
      print('NATIVE_STAGE: source reader');
      final navigator = Navigator.of(
        tester.element(find.byType(NavigationBar)),
      );
      navigator.push(
        MaterialPageRoute(
          builder: (_) =>
              SourceReader(state, state.sources.first, initialPage: 17),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('စာမျက်နှာ 17 / 42'), findsOneWidget);
      await tester.tap(find.text('မူရင်း PDF'));
      await tester.pumpAndSettle();
      expect(find.byType(PdfViewer), findsOneWidget);
      await tester.tap(find.byTooltip('နောက်စာမျက်နှာ'));
      await tester.pumpAndSettle();
      expect(find.text('စာမျက်နှာ 18 / 42'), findsOneWidget);
      navigator.pop();
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('AI'));
      await tester.pumpAndSettle();
      // Release mode rejects the debug-only -1 text-input client. Register the
      // test IME so setClient supplies the real connection ID before injection.
      tester.testTextInput.register();
      addTearDown(tester.testTextInput.unregister);
      final inputFinder = find.descendant(
        of: find.byType(ChatScreen),
        matching: find.byType(TextField),
      );
      await tester.enterText(inputFinder, 'အလုပ်ထုတ်');
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(inputFinder).controller!.text,
        'အလုပ်ထုတ်',
        reason: 'release text-input connection',
      );
      await tester.tap(find.byTooltip('မေးမယ်'));
      await tester.pumpAndSettle();
      expect(state.history, isNotEmpty, reason: 'offline reply saved');
      expect(state.history.first['online'], false);
      expect(
        state.history.first['source_ids'],
        isNotEmpty,
        reason: 'retrieved source cards',
      );
      await state.reset();
      await tester.pumpAndSettle();
      expect(state.history, isEmpty);
      expect(tester.takeException(), isNull);
      print('NATIVE_STAGE: complete');
    } catch (error, stack) {
      print('NATIVE_FAILURE: $error\n$stack');
      rethrow;
    }
  });
}

// Synthetic one-page PDF fixture. Contains no user information.
const testPdfBase64 =
    'JVBERi0xLjMKJZOMi54gUmVwb3J0TGFiIEdlbmVyYXRlZCBQREYgZG9jdW1lbnQgKG9wZW5zb3VyY2UpCjEgMCBvYmoKPDwKL0YxIDIgMCBSCj4+CmVuZG9iagoyIDAgb2JqCjw8Ci9CYXNlRm9udCAvSGVsdmV0aWNhIC9FbmNvZGluZyAvV2luQW5zaUVuY29kaW5nIC9OYW1lIC9GMSAvU3VidHlwZSAvVHlwZTEgL1R5cGUgL0ZvbnQKPj4KZW5kb2JqCjMgMCBvYmoKPDwKL0NvbnRlbnRzIDcgMCBSIC9NZWRpYUJveCBbIDAgMCA1OTUuMjc1NiA4NDEuODg5OCBdIC9QYXJlbnQgNiAwIFIgL1Jlc291cmNlcyA8PAovRm9udCAxIDAgUiAvUHJvY1NldCBbIC9QREYgL1RleHQgL0ltYWdlQiAvSW1hZ2VDIC9JbWFnZUkgXQo+PiAvUm90YXRlIDAgL1RyYW5zIDw8Cgo+PiAKICAvVHlwZSAvUGFnZQo+PgplbmRvYmoKNCAwIG9iago8PAovUGFnZU1vZGUgL1VzZU5vbmUgL1BhZ2VzIDYgMCBSIC9UeXBlIC9DYXRhbG9nCj4+CmVuZG9iago1IDAgb2JqCjw8Ci9BdXRob3IgKGFub255bW91cykgL0NyZWF0aW9uRGF0ZSAoRDoyMDI2MTAwODIyMzQ1NiswOScwMCcpIC9DcmVhdG9yIChhbm9ueW1vdXMpIC9LZXl3b3JkcyAoKSAvTW9kRGF0ZSAoRDoyMDI2MTAwODIyMzQ1NiswOScwMCcpIC9Qcm9kdWNlciAoUmVwb3J0TGFiIFBERiBMaWJyYXJ5IC0gXChvcGVuc291cmNlXCkpIAogIC9TdWJqZWN0ICh1bnNwZWNpZmllZCkgL1RpdGxlICh1bnRpdGxlZCkgL1RyYXBwZWQgL0ZhbHNlCj4+CmVuZG9iago2IDAgb2JqCjw8Ci9Db3VudCAxIC9LaWRzIFsgMyAwIFIgXSAvVHlwZSAvUGFnZXMKPj4KZW5kb2JqCjcgMCBvYmoKPDwKL0ZpbHRlciBbIC9BU0NJSTg1RGVjb2RlIC9GbGF0ZURlY29kZSBdIC9MZW5ndGggMTA5Cj4+CnN0cmVhbQpHYXBARDBhYEZiJ0xSKD9uT0BaSnJfZGk9V0tTYEREQkxuRV4mTWdeJCRlbV8waktgZTQ7M1tKU0lQMlNfRW5wXzY8JyhrcWMuXXQ1JCpTXWcvZFVZLFNVZEpTYVMlTVVcYXBjNEhOQVFcR34+ZW5kc3RyZWFtCmVuZG9iagp4cmVmCjAgOAowMDAwMDAwMDAwIDY1NTM1IGYgCjAwMDAwMDAwNjEgMDAwMDAgbiAKMDAwMDAwMDA5MiAwMDAwMCBuIAowMDAwMDAwMTk5IDAwMDAwIG4gCjAwMDAwMDA0MDIgMDAwMDAgbiAKMDAwMDAwMDQ3MCAwMDAwMCBuIAowMDAwMDAwNzMxIDAwMDAwIG4gCjAwMDAwMDA3OTAgMDAwMDAgbiAKdHJhaWxlcgo8PAovSUQgCls8NDQyMzQ0ZGQ0MDdlMjU2MDk0OGJjNDY0MDY3NTc2NWM+PDQ0MjM0NGRkNDA3ZTI1NjA5NDhiYzQ2NDA2NzU3NjVjPl0KJSBSZXBvcnRMYWIgZ2VuZXJhdGVkIFBERiBkb2N1bWVudCAtLSBkaWdlc3QgKG9wZW5zb3VyY2UpCgovSW5mbyA1IDAgUgovUm9vdCA0IDAgUgovU2l6ZSA4Cj4+CnN0YXJ0eHJlZgo5ODkKJSVFT0YK';
