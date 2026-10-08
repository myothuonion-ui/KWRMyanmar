import 'package:flutter/material.dart';
import '../core/ai_service.dart';
import '../core/app_state.dart';
import '../core/context.dart';
import '../core/models.dart';
import '../core/rules.dart';
import 'settings.dart';
import 'widgets.dart';

class ChatScreen extends StatefulWidget {
  final AppState state;
  const ChatScreen(this.state,{super.key});
  @override State<ChatScreen> createState()=>ChatScreenState();
}
class ChatScreenState extends State<ChatScreen> {
  final input=TextEditingController();
  bool busy=false;AiService? service;int generation=0;
  void setQuestion(String text){input.text=text;}
  @override void dispose(){generation++;service?.close();input.dispose();super.dispose();}
  void cancel(){generation++;service?.close();service=null;if(mounted)setState(()=>busy=false);}
  Future<Map<String,String>?> preview(String query,String personal,ProviderConfig provider,String model,List<LegalCard> sources) async {
    final question=TextEditingController(text:maskPrivateText(query));
    final contextInput=TextEditingController(text:personal);bool accepted=false;
    final value=await showDialog<Map<String,String>>(context:context,builder:(context)=>StatefulBuilder(builder:(context,setDialog)=>AlertDialog(
      title:const Text('Online ပို့မည့်အချက်အလက်'),
      content:SizedBox(width:560,child:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.start,children:[
        Text('${provider.label} · $model'),
        note(context,'အောက်ပါမေးခွန်းနှင့် context ကို provider ထံ ပို့မည်။ ID / account / email အချို့ဖျောက်ထားသော်လည်း အမည်၊ လိပ်စာနှင့် အခြားကိုယ်ရေးအချက်များကို ထပ်စစ်ဖယ်ပါ။ API provider ၏ data policy သက်ဆိုင်သည်။'),
        field('မေးခွန်း · ပြင်နိုင်သည်',question,lines:3),
        field('ရွေးထားသော context · မလိုတာဖယ်နိုင်သည်',contextInput,lines:8),
        note(context,'Public source cards: ${sources.map((s)=>s.title).join('၊ ')}\nမူရင်း PDF / ပုံ မပို့ပါ။ အရင် chat ထဲက context ကိုလည်း အလိုအလျောက်မပို့ပါ။'),
        CheckboxListTile(contentPadding:EdgeInsets.zero,value:accepted,onChanged:(v)=>setDialog(()=>accepted=v??false),title:const Text('ပို့မည့်စာသားကို စစ်ပြီး သဘောတူသည်'))
      ]))),actions:[TextButton(onPressed:()=>Navigator.pop(context),child:const Text('မပို့တော့ဘူး')),FilledButton(onPressed:!accepted?null:(){if(question.text.trim().isEmpty)return;if(contextInput.text.length>80000){message(context,'Context ရှည်လွန်းပါသည်။ လိုအပ်သည့် excerpt ကိုသာထားပါ။');return;}Navigator.pop(context,{'question':question.text.trim(),'personal':contextInput.text});},child:const Text('Provider ထံ ပို့မယ်'))])));
    // Controllers stay alive until the dialog exit animation has finished.
    Future<void>.delayed(const Duration(milliseconds:400),(){question.dispose();contextInput.dispose();});
    return value;
  }
  Future<void> send() async {
    if(busy || input.text.trim().isEmpty)return;
    final state=widget.state;final query=input.text.trim();
    final online=state.settings['online']==true;
    final sources=searchCards(state.cards,query).take(6).toList();
    final token=++generation;
    setState(()=>busy=true);
    try {
      if(!online){
        final answer=sources.isEmpty?'ထည့်ထားသော offline sources ထဲတွင် တိုက်ရိုက်သက်ဆိုင်သောအချက် မတွေ့သေးပါ။ ပိုတိုသောစကားလုံးဖြင့် ရှာပါ။ လိုအပ်သည့်ရင်းမြစ်ကို official website / 1350 / 1345 ဖြင့်စစ်ပါ။':'သက်ဆိုင်သော offline ကတ်အနှစ်ချုပ်များကို အောက်တွင်ပြထားသည်။ ကိုယ့်အမှုအတွက် အတည်ပြုဆုံးဖြတ်ချက်မဟုတ်ပါ။\n\n${sources.take(3).map((s)=>'${s.title}\n${s.summary}').join('\n\n')}';
        await state.addHistory({'date':DateTime.now().toIso8601String(),'question':query,'answer':answer,'online':false,'source_ids':sources.map((s)=>s.id).toList(),'questions':<String>[],'steps':<String>[]});
      }else {
        final id=state.settings['provider'] as String;
        final p=providers.firstWhere((p)=>p.id==id);
        final config=state.providerSettings(id);
        final model=(config['model']??'').toString();
        final key=await state.vault.keyFor(id);
        if(key.isEmpty || model.isEmpty)throw const AiFailure('Settings ထဲတွင် provider၊ API key နဲ့ model ကို အရင်သိမ်းပါ။');
        if(!mounted || token!=generation)return;
        final personal=selectedContext(profile:state.profile,useProfile:state.settings['profileContext']==true,documents:state.documents);
        final consent=await preview(query,personal,p,model,sources);
        if(consent==null || !mounted || token!=generation || state.settings['online']!=true)return;
        service=AiService();
        final raw=await service!.chat(provider:p,base:config['base']??p.baseUrl,key:key,model:model,
          system:legalSystemPrompt(sources,consent['personal']!),messages:[{'role':'user','content':consent['question']!}]);
        if(!mounted || token!=generation)return;
        final answer=AiAnswer.parse(raw,sources.map((s)=>s.id).toSet());
        if(!answer.validated)throw const AiFailure('AI အဖြေပုံစံ / source IDs ကို စစ်မရပါ။ အဖြေကို မသိမ်းရသေးပါ။ အခြား model ဖြင့် ပြန်စမ်းပါ။');
        await state.addHistory({'date':DateTime.now().toIso8601String(),'question':consent['question'],'answer':answer.answer,
          'questions':answer.questions,'steps':answer.steps,'source_ids':answer.sourceIds,'online':true,'provider':p.label,'model':model,
          'context_snapshot':consent['personal'],'source_snapshot':sources.map((s)=>s.evidence).toList()});
      }
      if(mounted && token==generation)input.clear();
    }catch(e){if(mounted && token==generation)message(context,e.toString());}
    finally {if(token==generation){service?.close();service=null;if(mounted)setState(()=>busy=false);}}
  }
  Future<void> clear() async {
    final ok=await showDialog<bool>(context:context,builder:(context)=>AlertDialog(title:const Text('Chat history ရှင်းမလား?'),content:const Text('ဖုန်းပေါ်တွင် သိမ်းထားသောအဖြေများနှင့် context snapshots ဖျက်မည်။ Provider ပေါ်ရှိ record များကို ဤနေရာမှ မဖျက်နိုင်ပါ။'),actions:[TextButton(onPressed:()=>Navigator.pop(context,false),child:const Text('မရှင်းတော့ဘူး')),FilledButton(onPressed:()=>Navigator.pop(context,true),child:const Text('ရှင်းမယ်'))]));
    if(ok==true)await widget.state.clearHistory();
  }
  Widget turn(Map<String,dynamic> row) {
    final ids=List<String>.from(row['source_ids']??[]);
    final sources=widget.state.cards.where((c)=>ids.contains(c.id));
    return Card(margin:const EdgeInsets.only(bottom:14),child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Text(row['question']??'',style:Theme.of(context).textTheme.titleMedium?.copyWith(height:1.8)),
      note(context,'${row['online']==true?'${row['provider']} · ${row['model']}':'Offline source search'} · ${row['date'].toString().split('T').first}'),
      SelectableText(row['answer']??'',style:const TextStyle(height:1.9)),
      for(final q in List<String>.from(row['questions']??[]))TextButton(onPressed:()=>setQuestion(q),child:Text(q)),
      if((row['steps'] as List? ?? []).isNotEmpty)sectionTitle(context,'ဆက်လုပ်ရန်'),
      ...List<String>.from(row['steps']??[]).map((s)=>Padding(padding:const EdgeInsets.symmetric(vertical:5),child:Text('• $s',style:const TextStyle(height:1.8)))),
      if(sources.isNotEmpty)sectionTitle(context,'အဖြေတွင်သုံးထားသော sources'),
      ...sources.map((c)=>TextButton.icon(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>CardDetail(widget.state,c,setQuestion))),icon:const Icon(Icons.link,size:18),label:Text(c.title))),
      if(row['online']==true && ids.isEmpty)note(context,'Source citation မပါသေးပါ။ ဥပဒေ / Visa ဆိုင်ရာဆုံးဖြတ်ချက်အဖြစ် မယူပါနှင့်။'),
      if(row['online']==true)note(context,'AI source ID စစ်ခြင်းသည် အဖြေအားလုံးမှန်ကြောင်း အာမမခံပါ။ Pending / latest rule အတွက် official source ကိုစစ်ပါ။'),
      if(row['context_snapshot']!=null)ExpansionTile(tilePadding:EdgeInsets.zero,title:const Text('အသုံးပြုခဲ့သော context ကိုဖတ်ရန်'),children:[SelectableText(row['context_snapshot'].toString().isEmpty?'ကိုယ်ရေး context မပါ':row['context_snapshot'],style:const TextStyle(height:1.7))])
    ])));
  }
  @override Widget build(BuildContext context) {
    final state=widget.state;final online=state.settings['online']==true;
    final provider=providers.firstWhere((p)=>p.id==state.settings['provider']);
    return Column(children:[
      Expanded(child:ListView(padding:const EdgeInsets.all(18),children:[
        Row(children:[Expanded(child:Text('ရင်းမြစ်နဲ့ မေးမယ်',style:Theme.of(context).textTheme.titleLarge)),IconButton(tooltip:'AI settings',onPressed:busy?null:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>SettingsScreen(state))),icon:const Icon(Icons.tune)),IconButton(tooltip:'History ရှင်းရန်',onPressed:busy?null:clear,icon:const Icon(Icons.delete_sweep_outlined))]),
        SwitchListTile(contentPadding:EdgeInsets.zero,title:Text(online?'Online AI · ${provider.label}':'Offline · ကတ်ရင်းမြစ်ရှာဖတ်'),subtitle:Text(online?'Model: ${state.providerSettings(provider.id)['model'].toString().isEmpty?'မရွေးရသေး':state.providerSettings(provider.id)['model']}':'Internet / API key မလိုပါ။ AI model အဖြေအသစ် မထုတ်ပါ။'),value:online,onChanged:(v) async {if(!v)cancel();await state.setSetting('online',v);}),
        ExpansionTile(tilePadding:EdgeInsets.zero,title:const Text('ကိုယ်ရေး context ရွေးရန်'),children:[
          CheckboxListTile(contentPadding:EdgeInsets.zero,value:state.settings['profileContext']==true && state.profile['confirmed']==true,onChanged:busy||state.profile['confirmed']!=true?null:(v)=>state.setSetting('profileContext',v??false),title:const Text('စစ်ပြီး profile ကိုသုံးမယ်'),subtitle:Text(state.profile['confirmed']==true?'ဖုန်းပေါ်သိမ်းထားသော လက်ရှိ profile':'ကိုယ့်ဖိုင် tab တွင် profile ကို အရင်အတည်ပြုပါ။')),
          ...state.documents.map((d)=>CheckboxListTile(contentPadding:EdgeInsets.zero,value:d.selected&&d.confirmed,onChanged:busy||!d.confirmed?null:(v)=>state.putDocument(d.copyWith(selected:v??false)),title:Text(d.name),subtitle:Text(d.confirmed?'စစ်ပြီးစာသား':'မူရင်းနှင့်စစ်ရန်လို'))),
          note(context,'ရွေးထားသည့်စာသားကိုသာ preview တွင်ပြမည်။ Send တစ်ကြိမ်စီတွင် ပြန်စစ်ပါ။ စာသားအတိုဆုံး relevant excerpt သာပို့ပါ။')
        ]),
        if(state.history.isEmpty)...[const SizedBox(height:14),note(context,'ဥပမာ: “အလုပ်စပြီး ရက်၂၀မှာ အလုပ်ထုတ်ခံရရင်?”၊ “E-9 ကနေ D-2 ပြောင်းချင်တယ်”၊ “လစာစာရွက်မှာ ညအပိုကြေးဘယ်လိုစစ်မလဲ?”')],
        ...state.history.reversed.take(30).map(turn),
        if(state.history.length>30)note(context,'လတ်တလော အဖြေ 30 ခု ပြထားသည်။ History အများဆုံး 100 ခုကို encrypted သိမ်းထားပြီး Settings မှ export လုပ်နိုင်သည်။')
      ])),
      if(busy)const LinearProgressIndicator(),
      SafeArea(top:false,child:Padding(padding:const EdgeInsets.fromLTRB(16,8,12,12),child:Row(crossAxisAlignment:CrossAxisAlignment.end,children:[
        Expanded(child:TextField(controller:input,minLines:1,maxLines:5,enabled:!busy,decoration:const InputDecoration(hintText:'ကိုယ့်အခြေအနေကို မေးပါ…',border:OutlineInputBorder()))),
        const SizedBox(width:6),IconButton.filled(tooltip:busy?'ရပ်မယ်':'မေးမယ်',onPressed:busy?cancel:send,icon:Icon(busy?Icons.stop:Icons.arrow_upward))
      ])))
    ]);
  }
}
