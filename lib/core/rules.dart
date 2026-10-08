import 'models.dart';

String normalize(String value) {
  var result=value.toLowerCase().replaceAll('\u200b','').replaceAll('-','');
  const digits='၀၁၂၃၄၅၆၇၈၉';
  for(var i=0;i<digits.length;i++) {result=result.replaceAll(digits[i], '$i');}
  return result.replaceAll(RegExp(r'\s+'), ' ').trim();
}

List<LegalCard> searchCards(List<LegalCard> cards, String query) {
  final q=normalize(query);
  if(q.isEmpty) return cards;
  int score(LegalCard c) {
    var value=0;
    if(normalize(c.title).contains(q)) value+=100;
    for(final tag in c.tags) {
      final t=normalize(tag);
      if(t.isNotEmpty && (q.contains(t) || t.contains(q))) value+=20;
    }
    for(final token in q.split(' ').where((t)=>t.length>1)) {
      if(normalize(c.title).contains(token)) value+=6;
      if(normalize(c.body).contains(token)) value+=1;
    }
    return value;
  }
  final ranked=cards.map((c)=>(card:c,score:score(c))).where((v)=>v.score>0).toList()
    ..sort((a,b)=>b.score.compareTo(a.score));
  return ranked.map((v)=>v.card).toList();
}

DateTime addCalendarMonths(DateTime date,int months) {
  final last=DateTime(date.year,date.month+months+1,0).day;
  return DateTime(date.year,date.month+months,date.day>last ? last : date.day);
}
String dateLabel(DateTime date) => '${date.year}-${date.month.toString().padLeft(2,'0')}-${date.day.toString().padLeft(2,'0')}';

class PayInput {
  final double rate,regular,overtime,night,holidayFirst,holidayExtra,allowance,dorm,other;
  final bool premiumsApply;
  const PayInput({required this.rate,required this.regular,required this.overtime,
    required this.night,required this.holidayFirst,required this.holidayExtra,
    required this.allowance,required this.dorm,required this.other,
    required this.premiumsApply});
  double get totalHours => regular+overtime+holidayFirst+holidayExtra;
  void validate() {
    final values=[rate,regular,overtime,night,holidayFirst,holidayExtra,allowance,dorm,other];
    if(values.any((v)=>!v.isFinite || v<0) || rate==0) {
      throw ArgumentError('အနှုတ်ငွေ / ကွက်လပ်မထည့်ပါနှင့်။ နာရီကြေးသည် 0 ထက်များရမည်။');
    }
    if(night>totalHours) {throw ArgumentError('ညအပိုကြေးနာရီသည် စုစုပေါင်းအလုပ်နာရီထက် မကျော်ရပါ။');}
  }
  Map<String,double> calculate() {
    validate();
    final base=rate*totalHours;
    final premium=premiumsApply ? rate*(.5*overtime+.5*night+.5*holidayFirst+holidayExtra) : 0.0;
    return {'base':base,'premium':premium,'gross':base+premium+allowance,
      'deductions':dorm+other,'net':base+premium+allowance-dorm-other};
  }
}

String dismissalGuide({required DateTime start,required DateTime dismissal,
  required String workers,required bool protectedLeave}) {
  if(dismissal.isBefore(start)) {throw ArgumentError('အလုပ်ထုတ်ရက်က အလုပ်စရက်ထက် စောနေပါသည်။');}
  final under3=dismissal.isBefore(addCalendarMonths(start,3));
  final parts=<String>[
    under3 ? 'ဆက်တိုက်လုပ်သက် ၃ လမပြည့်သေးလို့ Article 26 ရဲ့ ရက် ၃၀ notice / notice pay ခြွင်းချက်ဖြစ်နိုင်ပါတယ်။'
      : 'Article 26 အရ ပုံမှန်အားဖြင့် ရက် ၃၀ ကြိုအသိပေးရမယ်။ မပြည့်လျှင် ရက် ၃၀စာနှင့်အထက် 통상임금 ပေးရမယ်။ အခြားဥပဒေခြွင်းချက်ကို စစ်ပါ။',
    'ဒီအချက်က အလုပ်ထုတ်တာတရားဝင်ကြောင်း အပြီးသတ်မဆုံးဖြတ်ပါ။',
    if(workers=='5+') 'ပုံမှန်လုပ်သား ၅ ဦးနှင့်အထက်အတွက် ခိုင်လုံသောအကြောင်းရင်းနဲ့ စာဖြင့် reason / dismissal date ပေးထားမှုကို Article 23 / 27 အရစစ်ပါ။ သက်ဆိုင်သော မတရားအလုပ်ထုတ် remedy ကို ပုံမှန် ၃ လအတွင်း လျှောက်ရပါတယ်။',
    if(workers=='1-4') 'ပုံမှန်လုပ်သား ၄ ဦးနှင့်အောက်မှာ အလုပ်ထုတ်မှုအကာအကွယ်တချို့နဲ့ ဖြေရှင်းလမ်းကြောင်း ကွာပါတယ်။ လစာ၊ စာချုပ်နဲ့ အခြားသက်ဆိုင်ရာအကာအကွယ်တွေကို ဆက်စစ်ပါ။',
    if(workers=='unknown') 'ပုံမှန်လုပ်သားဦးရေ မသိသေးလို့ ordinary unfair-dismissal အကာအကွယ်အကျုံးဝင်မှုကို အတည်မပြောနိုင်သေးပါ။',
    if(protectedLeave) 'အလုပ်ဒဏ်ရာ/ရောဂါဆေးကုသခွင့်၊ သားဖွားခွင့်ကာလနှင့် နောက်ရက် ၃၀ အကာအကွယ်ကို Article 23(2) အရ သီးခြားစစ်ပါ။',
    'အလုပ်ထုတ်စာ၊ မက်ဆေ့ချ်၊ စာချုပ်နဲ့ လစာစာရွက် သိမ်းထားပါ။ E-9 ဆို အလုပ်ပြောင်းလုပ်ထုံးလုပ်နည်းကိုပါ 고용센터 မှာ စစ်ပါ။'
  ];
  return parts.join('\n\n');
}

String maskPrivateText(String text) => text
  .replaceAll(RegExp(r'\b\d{6}[- ]?[1-8]\d{6}\b'),'[ARC/ID masked]')
  .replaceAll(RegExp(r'\b(?:MA|MB|MC|MD|ME|MF|MG|MH)[0-9]{6,9}\b',caseSensitive:false),'[passport masked]')
  .replaceAll(RegExp(r'\b\d{10,16}\b'),'[long number masked]')
  .replaceAll(RegExp(r'[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}',caseSensitive:false),'[email masked]');
