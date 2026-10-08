import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';

class VaultCipher {
  final cipher=AesGcm.with256bits();
  final SecretKey key;
  VaultCipher(this.key);
  Future<Uint8List> encrypt(List<int> bytes) async => Uint8List.fromList(
    (await cipher.encrypt(bytes,secretKey:key)).concatenation());
  Future<Uint8List> decrypt(List<int> bytes) async => Uint8List.fromList(
    await cipher.decrypt(SecretBox.fromConcatenation(bytes,nonceLength:12,macLength:16),secretKey:key));
}

class Vault {
  final FlutterSecureStorage secure;
  final Directory directory;
  final VaultCipher cipher;
  Future<void> _pending=Future.value();
  Vault(this.secure,this.directory,this.cipher);
  static Future<Vault> open() async {
    const secure=FlutterSecureStorage();
    var encoded=await secure.read(key:'vault_key_v1');
    if(encoded==null) {
      final key=await AesGcm.with256bits().newSecretKey();
      encoded=base64Encode(await key.extractBytes());
      await secure.write(key:'vault_key_v1',value:encoded);
    }
    final directory=Directory('${(await getApplicationSupportDirectory()).path}/kwr_vault');
    await directory.create(recursive:true);
    return Vault(secure,directory,VaultCipher(SecretKey(base64Decode(encoded))));
  }
  Future<Map<String,dynamic>> load() async {
    final primary=File('${directory.path}/state.enc');
    final backup=File('${directory.path}/state.bak');
    for(final file in [primary,backup]) {
      if(!await file.exists()) continue;
      try {return jsonDecode(utf8.decode(await cipher.decrypt(await file.readAsBytes()))) as Map<String,dynamic>;}catch(_){}
    }
    if(await primary.exists() || await backup.exists()) {
      throw StateError('ကိုယ်ရေးဒေတာကို ဖတ်မရပါ။ App data ကိုမဖျက်ဘဲ ပြန်စမ်းပါ။');
    }
    return {};
  }
  Future<void> save(Map<String,dynamic> state) {
    final snapshot=jsonEncode(state);
    final operation=_pending.then((_) async {
      final temp=File('${directory.path}/state.tmp');
      await temp.writeAsBytes(await cipher.encrypt(utf8.encode(snapshot)),flush:true);
      final target=File('${directory.path}/state.enc');
      if(await target.exists()) await target.copy('${directory.path}/state.bak');
      await temp.rename(target.path);
    });
    _pending=operation.catchError((Object error) {});
    return operation;
  }
  Future<String> keyFor(String provider) async => await secure.read(key:'api_$provider') ?? '';
  Future<void> setKey(String provider,String value) async {
    if(value.isEmpty) {await secure.delete(key:'api_$provider');}
    else {await secure.write(key:'api_$provider',value:value);}
  }
  Future<void> writeDocument(String id,Uint8List bytes) async {
    await File('${directory.path}/$id.enc').writeAsBytes(await cipher.encrypt(bytes),flush:true);
  }
  Future<Uint8List> readDocument(String id) async => cipher.decrypt(
    await File('${directory.path}/$id.enc').readAsBytes());
  Future<void> deleteDocument(String id) async {
    final file=File('${directory.path}/$id.enc');
    if(await file.exists()) await file.delete();
  }
  Future<void> clear() async {
    await _pending;
    if(await directory.exists()) await directory.delete(recursive:true);
    for(final p in ['gemini','openai','claude','nvidia','deepseek','custom']) {await secure.delete(key:'api_$p');}
    await directory.create(recursive:true);
  }
}
