import 'package:flutter/material.dart';
import '../core/app_state.dart';
import '../core/rules.dart';
import 'widgets.dart';

class PayScreen extends StatefulWidget {
  final AppState state;
  const PayScreen(this.state,{super.key});
  @override State<PayScreen> createState()=>_PayScreenState();
}
class _PayScreenState extends State<PayScreen> {
  final values=<String,TextEditingController>{for(final key in ['rate','regular','ot','night','holidayFirst','holidayExtra','allowance','dorm','other','actual']) key:TextEditingController()};
  bool premiums=false;Map<String,double>? result;String? error;double? actualPay;
  @override void initState(){super.initState();values['rate']!.text=widget.state.profile['hourly']?.toString() ?? '';}
  @override void dispose(){for(final v in values.values){v.dispose();}super.dispose();}
  void calculate() {
    try {
      double get(String key) {
        final parsed=double.tryParse(normalize(values[key]!.text).replaceAll(',',''));
        if(parsed==null) throw ArgumentError('$key ကို နံပါတ်ဖြည့်ပါ။ မရှိလျှင် 0 ထည့်ပါ။');
        return parsed;
      }
      final pay=PayInput(rate:get('rate'),regular:get('regular'),overtime:get('ot'),night:get('night'),
        holidayFirst:get('holidayFirst'),holidayExtra:get('holidayExtra'),allowance:get('allowance'),dorm:get('dorm'),other:get('other'),premiumsApply:premiums);
      final entered=normalize(values['actual']!.text).replaceAll(',','');
      final actual=entered.isEmpty?null:double.tryParse(entered);
      if(entered.isNotEmpty && (actual==null || !actual.isFinite || actual<0))throw ArgumentError('Payslip net pay ကို မှန်ကန်သော နံပါတ်ဖြည့်ပါ။');
      setState((){result=pay.calculate();actualPay=actual;error=null;});
    }catch(e){setState((){result=null;error=e.toString().replaceFirst('Invalid argument(s): ','');});}
  }
  String money(double v)=>'₩${v.round().toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'),(m)=>'${m[1]},')}';
  Widget amount(String label,String key)=>field(label,values[key]!,number:true,onChanged:(_)=>setState((){result=null;error=null;}));
  @override Widget build(BuildContext context)=>ListView(padding:const EdgeInsets.all(20),children:[
    Text('လစာ ခန့်မှန်းတွက်မယ်',style:Theme.of(context).textTheme.headlineSmall),
    note(context,'သက်ဆိုင်သော pay period တစ်ခုအတွက် ကိုယ်တိုင်အတည်ပြုထားသည့် ordinary hourly wage နဲ့ နာရီတွေကို ထည့်ပါ။ အခွန်/အာမခံကို အလိုအလျောက်မတွက်ပါ။'),
    amount('통상임금 · နာရီကြေး (₩)','rate'),
    amount('ပုံမှန် paid hours (OT / holiday မပါ)','regular'),
    amount('အချိန်ပိုနာရီ (regular / holiday မထပ်)','ot'),
    amount('Holiday · နေ့တစ်နေ့ချင်း ပထမ ၈နာရီအထိ စုပေါင်း','holidayFirst'),
    amount('Holiday · နေ့တစ်နေ့ချင်း ၈နာရီကျော် စုပေါင်း','holidayExtra'),
    amount('ည 22:00–06:00 နာရီ (အထက်နာရီများနှင့် ထပ်နိုင်)','night'),
    CheckboxListTile(contentPadding:EdgeInsets.zero,value:premiums,onChanged:(v)=>setState((){premiums=v??false;result=null;}),title:const Text('Article 56 အပိုကြေး သက်ဆိုင်မှု စစ်ပြီးပြီ'),subtitle:const Text('ပုံမှန်လုပ်သားဦးရေ၊ လုပ်ငန်းအမျိုးအစား/ခြွင်းချက်နှင့် contract ကို အရင်စစ်ပါ။')),
    amount('အခြားထပ်ဆောင်းငွေ (₩)','allowance'),
    amount('အဆောင် / စားစရိတ် ဖြတ်ငွေ (₩)','dorm'),
    amount('အခွန် / အာမခံ / အခြားဖြတ်ငွေ (₩)','other'),
    amount('Payslip ပေါ် net pay (ရွေးချယ်နိုင်)','actual'),
    FilledButton(onPressed:calculate,child:const Text('တွက်မယ်')),
    if(error!=null) Padding(padding:const EdgeInsets.all(12),child:Text(error!,style:TextStyle(color:Theme.of(context).colorScheme.error))),
    if(result!=null) Card(child:Padding(padding:const EdgeInsets.all(18),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      for(final pair in [('base','အလုပ်နာရီအတွက် base'),('premium','OT / night / holiday premium'),('gross','စုစုပေါင်း gross'),('deductions','ဖြတ်ငွေ'),('net','ခန့်မှန်း net')]) Padding(padding:const EdgeInsets.symmetric(vertical:7),child:Text('${pair.$2}: ${money(result![pair.$1]!)}',style:pair.$1=='net'?Theme.of(context).textTheme.titleLarge:null)),
      if(actualPay!=null) Text('ခန့်မှန်း net − စာရွက်ပေါ် net: ${money(result!['net']!-actualPay!)}'),
      note(context,'ဤကွာဟချက်တစ်ခုတည်းမှ လစာဥပဒေချိုးဖောက်မှုဟု မဆုံးဖြတ်ပါ။ Hour classification၊ wage components နဲ့ deductions ကို ပြန်စစ်ပါ။')
    ]))),
    ExpansionTile(title:const Text('တွက်ချက်ပုံ'),children:[Padding(padding:const EdgeInsets.all(14),child:Text('Base = နာရီကြေး × မထပ်သော regular + OT + holiday နာရီ\nPremium သက်ဆိုင်လျှင်: နာရီကြေး × (OT × 0.5 + night × 0.5 + holiday ပထမ 8h × 0.5 + holiday ကျော်နာရီ × 1.0)\nNet = base + premium + ထပ်ဆောင်းငွေ − ဖြတ်ငွေ\nHoliday base ကို regular hours ထဲပြန်မထည့်ပါနှင့်။ Paid-rest components ရှိလျှင် regular paid hours ထဲ ကိုယ်တိုင်အတည်ပြုထည့်ပါ။'))]),
    TextButton(onPressed:()=>openSource(context,'https://www.law.go.kr/lsLinkProc.do?joNo=005600&lsClsCd=L&lsNm=근로기준법&mode=11'),child:const Text('근로기준법 제56조 · မူရင်း'))
  ]);
}

class DismissalScreen extends StatefulWidget {
  final AppState state;const DismissalScreen(this.state,{super.key});
  @override State<DismissalScreen> createState()=>_DismissalScreenState();
}
class _DismissalScreenState extends State<DismissalScreen> {
  DateTime? start,dismissal;String workers='unknown';bool protectedLeave=false;String? answer;
  @override void initState(){super.initState();start=DateTime.tryParse(widget.state.profile['start']?.toString() ?? '');workers=widget.state.profile['workers']?.toString() ?? 'unknown';}
  Future<void> pick(bool first) async {
    final date=await showDatePicker(context:context,initialDate:(first?start:dismissal)??DateTime.now(),firstDate:DateTime(2000),lastDate:DateTime(2100));
    if(date!=null && mounted) setState((){if(first){start=date;}else{dismissal=date;}answer=null;});
  }
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('အလုပ်ထုတ်ခံရမှု စစ်ရန်')),
    body:ListView(padding:const EdgeInsets.all(20),children:[
      note(context,'ကိုယ်တိုင်ထွက်ခြင်း / စာချုပ်ကုန်ခြင်းအတွက် ဤစစ်ဆေးမှုကို မသုံးပါနှင့်။ အလုပ်ထုတ်ခံရမှုအချက်အလက်ကို အတည်ပြုဖြည့်ပါ။'),
      OutlinedButton(onPressed:()=>pick(true),child:Text('အလုပ်စရက်: ${start==null?'ရွေးရန်':dateLabel(start!)}')),
      OutlinedButton(onPressed:()=>pick(false),child:Text('အလုပ်ထုတ်ရက်: ${dismissal==null?'ရွေးရန်':dateLabel(dismissal!)}')),
      DropdownButtonFormField<String>(value:workers,decoration:const InputDecoration(labelText:'ပုံမှန်အလုပ်သမားဦးရေ'),items:const [DropdownMenuItem(value:'unknown',child:Text('မသိသေး')),DropdownMenuItem(value:'1-4',child:Text('၄ ဦးနှင့်အောက်')),DropdownMenuItem(value:'5+',child:Text('၅ ဦးနှင့်အထက်'))],onChanged:(v)=>setState((){workers=v!;answer=null;})),
      CheckboxListTile(contentPadding:EdgeInsets.zero,title:const Text('အလုပ်ဒဏ်ရာ / သားဖွားခွင့်အကာအကွယ် စစ်ရန်လို'),value:protectedLeave,onChanged:(v)=>setState((){protectedLeave=v??false;answer=null;})),
      FilledButton(onPressed:(){if(start==null || dismissal==null){message(context,'ရက်စွဲနှစ်ခုကိုရွေးပါ။');return;}try{setState(()=>answer=dismissalGuide(start:start!,dismissal:dismissal!,workers:workers,protectedLeave:protectedLeave));}catch(e){message(context,e.toString());}},child:const Text('Offline စစ်မယ်')),
      if(answer!=null) ...[const SizedBox(height:18),SelectableText(answer!,style:const TextStyle(height:2)),
        const SizedBox(height:12),OutlinedButton.icon(onPressed:() async {await widget.state.addHistory({'question':'အလုပ်ထုတ်ခံရမှု ${dateLabel(dismissal!)}','answer':answer,'online':false,'date':DateTime.now().toIso8601String(),'source_ids':['dismissal20','noticepay','unfairdismissal'],'facts':{'start':dateLabel(start!),'dismissal':dateLabel(dismissal!),'workers':workers,'protectedLeave':protectedLeave}});if(context.mounted)message(context,'အဖြေနဲ့အသုံးပြုခဲ့သောအချက်တွေကို သိမ်းပြီးပြီ။');},icon:const Icon(Icons.save_outlined),label:const Text('အဖြေကို သိမ်းမယ်'))],
      note(context,'근로기준법 제23 / 26 / 27 / 28 · ရင်းမြစ်စစ် 2026-10-08 · အပြီးသတ်အမှုဆုံးဖြတ်ချက်မဟုတ်။')
    ]));
}

class VisaScreen extends StatefulWidget {
  final AppState state;final void Function(String) onAsk;
  const VisaScreen(this.state,this.onAsk,{super.key});
  @override State<VisaScreen> createState()=>_VisaScreenState();
}
class _VisaScreenState extends State<VisaScreen> {
  DateTime? termination,application,officialDeadline;String target='D-2';
  Future<void> pick(int which) async {
    final chosen=await showDatePicker(context:context,initialDate:DateTime.now(),firstDate:DateTime(2000),lastDate:DateTime(2100));
    if(chosen!=null && mounted) setState((){if(which==0)termination=chosen;else if(which==1)application=chosen;else officialDeadline=chosen;});
  }
  @override Widget build(BuildContext context)=>ListView(padding:const EdgeInsets.all(20),children:[
    Text('Visa နဲ့ အလုပ်ပြောင်း',style:Theme.of(context).textTheme.headlineSmall),
    note(context,'မတူသောရက်စွဲတွေကို ခွဲထားပါ။ ရုံးကပေးထားသော official deadline နဲ့ ခြွင်းချက်ကို စစ်ပါ။'),
    OutlinedButton(onPressed:()=>pick(0),child:Text('စာချုပ်ပြီးဆုံးရက်: ${termination==null?'ရွေးရန်':dateLabel(termination!)}')),
    OutlinedButton(onPressed:()=>pick(1),child:Text('အလုပ်ပြောင်း 신청 ရက်: ${application==null?'ရွေးရန်':dateLabel(application!)}')),
    OutlinedButton(onPressed:()=>pick(2),child:Text('ရုံးကပေးထားသော deadline: ${officialDeadline==null?'ရွေးချယ်နိုင်':dateLabel(officialDeadline!)}')),
    if(termination!=null || application!=null) Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      if(termination!=null) Text('၁ လ milestone ခန့်မှန်း: ${dateLabel(addCalendarMonths(termination!,1))}'),
      if(application!=null) Text('၃ လ milestone ခန့်မှန်း: ${dateLabel(addCalendarMonths(application!,3))}'),
      if(officialDeadline!=null) Text('Official deadline: ${dateLabel(officialDeadline!)}'),
      note(context,'Calendar-month milestone ကိုသာပြထားသည်။ ရက်တွက်စည်းကမ်း၊ သတ်မှတ်ခြွင်းချက်၊ stay expiry နဲ့ ရုံးကပေးသောအတည်ပြုရက်ကို စစ်ပါ။')]))),
    sectionTitle(context,'ပြောင်းချင်တဲ့ Visa'),
    DropdownButtonFormField<String>(value:target,items:['D-2','D-4','E-7-1','E-7-2','E-7-3','E-7-4'].map((v)=>DropdownMenuItem(value:v,child:Text(v))).toList(),onChanged:(v)=>setState(()=>target=v!)),
    const SizedBox(height:12),FilledButton(onPressed:()=>widget.onAsk('လက်ရှိ ${widget.state.profile['visa']} ကနေ $target ပြောင်းဖို့ ဘာလိုလဲ?'),child:const Text('ကိုယ့်အခြေအနေဖြင့် မေးမယ်')),
    sectionTitle(context,'လမ်းကြောင်းအကြောင်း'),
    ...widget.state.cards.where((c)=>c.category=='Visa').map((c)=>TopicCard(c,onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>CardDetail(widget.state,c,widget.onAsk)))))
  ]);
}
