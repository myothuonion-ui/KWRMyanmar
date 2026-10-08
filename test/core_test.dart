import 'package:flutter_test/flutter_test.dart';
import 'package:cryptography/cryptography.dart';
import 'package:kwrmyanmar/core/rules.dart';
import 'package:kwrmyanmar/core/storage.dart';

void main() {
  test('calendar month is not a 90-day countdown',(){
    expect(dateLabel(addCalendarMonths(DateTime(2026,1,31),1)),'2026-02-28');
    expect(dateLabel(addCalendarMonths(DateTime(2026,7,31),3)),'2026-10-31');
    expect(dateLabel(addCalendarMonths(DateTime(2024,1,31),1)),'2024-02-29');
  });
  test('short service exception does not legalize dismissal',(){
    final answer=dismissalGuide(start:DateTime(2026,9,1),dismissal:DateTime(2026,9,20),workers:'5+',protectedLeave:false);
    expect(answer,contains('ခြွင်းချက်'));expect(answer,contains('အပြီးသတ်မဆုံးဖြတ်'));expect(answer,contains('Article 23 / 27'));
  });
  test('3 month boundary uses calendar date',(){
    final answer=dismissalGuide(start:DateTime(2026,1,31),dismissal:DateTime(2026,4,30),workers:'unknown',protectedLeave:false);
    expect(answer,contains('ပုံမှန်အားဖြင့် ရက် ၃၀ ကြိုအသိပေး'));expect(answer,contains('မသိသေး'));
  });
  test('night premium overlaps without paying base twice',(){
    const input=PayInput(rate:10000,regular:8,overtime:2,night:2,holidayFirst:0,holidayExtra:0,allowance:0,dorm:0,other:0,premiumsApply:true);
    expect(input.calculate()['gross'],120000);
  });
  test('invalid night hours cannot produce a verdict',(){
    const input=PayInput(rate:10000,regular:8,overtime:0,night:9,holidayFirst:0,holidayExtra:0,allowance:0,dorm:0,other:0,premiumsApply:true);
    expect(input.calculate,throwsArgumentError);
  });
  test('private ID is masked before provider context',(){
    expect(maskPrivateText('990101-1234567'),isNot(contains('990101')));
    expect(maskPrivateText('MA1234567'),isNot(contains('MA1234567')));
    expect(maskPrivateText('base wage 2200000'),contains('2200000'));
  });
  test('vault authenticates ciphertext and uses unique nonce',() async {
    final vault=VaultCipher(await AesGcm.with256bits().newSecretKey());
    final a=await vault.encrypt([1,2,3]);final b=await vault.encrypt([1,2,3]);
    expect(a,isNot(equals(b)));expect(await vault.decrypt(a),[1,2,3]);
    a[13]^=1;await expectLater(vault.decrypt(a),throwsA(isA<SecretBoxAuthenticationError>()));
  });
}
