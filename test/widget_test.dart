import 'dart:convert';
import 'dart:io';
import 'package:cryptography/cryptography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kwrmyanmar/core/app_state.dart';
import 'package:kwrmyanmar/core/models.dart';
import 'package:kwrmyanmar/core/storage.dart';
import 'package:kwrmyanmar/main.dart';
import 'package:kwrmyanmar/screens/chat.dart';

class MemoryVault extends Vault {
  MemoryVault(super.secure,super.directory,super.cipher);
  @override Future<void> save(Map<String,dynamic> state) async {}
  @override Future<String> keyFor(String provider) async=>'';
}
void main(){
  testWidgets('five tabs and offline answer work without a key',(tester) async {
    tester.view.physicalSize=const Size(1080,1920);tester.view.devicePixelRatio=3;
    addTearDown(tester.view.resetPhysicalSize);addTearDown(tester.view.resetDevicePixelRatio);
    final vault=MemoryVault(const FlutterSecureStorage(),Directory.systemTemp,VaultCipher(await AesGcm.with256bits().newSecretKey()));
    final cards=(jsonDecode(File('assets/cards.json').readAsStringSync()) as List).map((j)=>LegalCard.fromJson(Map<String,dynamic>.from(j))).toList();
    final state=AppState(vault,cards,{'profile':{'visa':'E-9','workers':'unknown'},'settings':{'provider':'gemini','online':false,'profileContext':false,'providers':<String,dynamic>{}},'documents':[],'history':[],'events':[],'bookmarks':[]});
    await tester.pumpWidget(KwrApp(state));await tester.pumpAndSettle();expect(tester.takeException(),isNull);
    for(final label in ['AI','Visa','လစာ','ကိုယ့်ဖိုင်','ကတ်များ']){
      await tester.tap(find.descendant(of:find.byType(NavigationBar),matching:find.text(label)));await tester.pumpAndSettle();expect(tester.takeException(),isNull);
    }
    await tester.tap(find.descendant(of:find.byType(NavigationBar),matching:find.text('AI')));await tester.pumpAndSettle();
    final chat=find.byType(ChatScreen);await tester.enterText(find.descendant(of:chat,matching:find.byType(TextField)),'အလုပ်ထုတ်');
    await tester.tap(find.byTooltip('မေးမယ်'));await tester.pumpAndSettle();
    expect(state.history.length,1);expect(state.history.first['online'],false);expect(state.history.first['source_ids'],isNotEmpty);expect(tester.takeException(),isNull);
    await tester.pumpWidget(const SizedBox());state.dispose();
  });
}
