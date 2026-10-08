import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';
import '../core/app_state.dart';
import '../core/document_service.dart';
import '../core/models.dart';
import '../core/rules.dart';
import 'widgets.dart';

class FilesScreen extends StatefulWidget {
  final AppState state;
  const FilesScreen(this.state,{super.key});
  @override State<FilesScreen> createState()=>_FilesScreenState();
}
class _FilesScreenState extends State<FilesScreen> {
  bool importing=false;String progress='';String kind='စာချုပ်';
  Future<void> importFile() async {
    if(importing)return;
    setState((){importing=true;progress='ဖိုင်ရွေးနေသည်…';});
    try {
      final file=await FilePicker.pickFile(type:FileType.custom,allowedExtensions:['pdf','jpg','jpeg','png']);
      if(file==null)return;
      final size=await file.length();
      if(size==null || size>20*1024*1024)throw const FormatException('ဖိုင်အရွယ်အစား စစ်မရ သို့မဟုတ် 20 MB ထက်ကြီးနေသည်။ ဖိုင်ကိုခွဲပါ။');
      final bytes=await file.readAsBytes();
      if(bytes.isEmpty || bytes.length>20*1024*1024)throw const FormatException('ဖိုင်မပြည့်စုံ သို့မဟုတ် 20 MB ထက်ကြီးနေသည်။');
      if(!mounted)return;
      setState(()=>progress='ဖုန်းပေါ်တွင် စာသားထုတ်နေသည်…');
      String text='',warning='';
      try {text=await DocumentService().extract(bytes,file.name.split('.').last.toLowerCase(),(value){if(mounted)setState(()=>progress=value);});}
      catch(e){warning='စာသားအလိုအလျောက်ထုတ်မရပါ။ မူရင်းနှင့်ယှဉ်ပြီး ကိုယ်တိုင်ဖြည့်နိုင်ပါသည်။ $e';}
      final id=DateTime.now().microsecondsSinceEpoch.toString();
      await widget.state.vault.writeDocument(id,bytes);
      final document=PersonalDocument(id:id,name:file.name,kind:kind,text:text,created:DateTime.now().toIso8601String());
      try{await widget.state.putDocument(document);}catch(_){await widget.state.vault.deleteDocument(id);rethrow;}
      if(mounted){
        if(warning.isNotEmpty)message(context,warning);
        await Navigator.push(context,MaterialPageRoute(builder:(_)=>DocumentEditor(widget.state,id)));
      }
    }catch(e){if(mounted)message(context,e.toString());}
    finally {try{await FilePicker.clearTemporaryFiles();}catch(_){}if(mounted)setState(()=>importing=false);}
  }
  Future<void> manual() async {
    final id=DateTime.now().microsecondsSinceEpoch.toString();
    await widget.state.vault.writeDocument(id,Uint8List.fromList(utf8.encode('ကိုယ်တိုင်ရေးထားသောမှတ်စု')));
    await widget.state.putDocument(PersonalDocument(id:id,name:'မှတ်စု-${dateLabel(DateTime.now())}.txt',kind:'မှတ်စု',text:'',created:DateTime.now().toIso8601String()));
    if(mounted)await Navigator.push(context,MaterialPageRoute(builder:(_)=>DocumentEditor(widget.state,id)));
  }
  Future<void> addEvent() async {
    final date=await showDatePicker(context:context,initialDate:DateTime.now(),firstDate:DateTime(2000),lastDate:DateTime(2100));
    if(date==null || !mounted)return;
    final title=TextEditingController();
    final text=await showDialog<String>(context:context,builder:(context)=>AlertDialog(title:Text(dateLabel(date)),content:field('ဖြစ်ရပ် / official deadline မှတ်စု',title,lines:3),actions:[TextButton(onPressed:()=>Navigator.pop(context),child:const Text('ပိတ်မယ်')),FilledButton(onPressed:()=>Navigator.pop(context,title.text.trim()),child:const Text('သိမ်းမယ်'))]));
    title.dispose();
    if(text!=null && text.isNotEmpty)await widget.state.addEvent({'date':dateLabel(date),'title':text});
  }
  @override Widget build(BuildContext context)=>ListView(padding:const EdgeInsets.all(20),children:[
    Text('ကိုယ့်အချက်အလက်',style:Theme.of(context).textTheme.headlineSmall),
    note(context,'တင်ထားသောဖိုင်ကို အလိုအလျောက် online ပို့မည်မဟုတ်ပါ။ OCR စာသားကို မူရင်းနဲ့စစ်ပြီး အတည်ပြုပါ။ AI context ထဲ ထည့်မထည့် ကိုယ်တိုင်ရွေးနိုင်သည်။'),
    OutlinedButton.icon(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>ProfileEditor(widget.state))),icon:const Icon(Icons.person_outline),label:const Text('Visa / လုပ်ငန်း / အလုပ်စရက် / လစာ profile')),
    sectionTitle(context,'စာရွက်နှင့်စာသား'),
    DropdownButtonFormField<String>(value:kind,decoration:const InputDecoration(labelText:'စာရွက်အမျိုးအစား'),items:['စာချုပ်','လစာစာရင်း','အဆောင်','Visa','အခြား'].map((v)=>DropdownMenuItem(value:v,child:Text(v))).toList(),onChanged:importing?null:(v)=>setState(()=>kind=v!)),
    const SizedBox(height:12),FilledButton.icon(onPressed:importing?null:importFile,icon:const Icon(Icons.upload_file),label:const Text('PDF / ပုံကို တင်မယ်')),
    TextButton.icon(onPressed:importing?null:manual,icon:const Icon(Icons.edit_note),label:const Text('ကိုယ်တိုင်စာသားရေးမယ်')),
    if(importing)...[const LinearProgressIndicator(),note(context,progress)],
    note(context,'20 MB / PDF အများဆုံး 40 စာမျက်နှာ · PDF text extraction + Korean / Latin OCR။ မြန်မာပုံစာသားအတွက် ကိုယ်တိုင်ဖြည့်ပါ။'),
    if(widget.state.documents.isEmpty)const Padding(padding:EdgeInsets.all(16),child:Text('စာချုပ်၊ payslip နဲ့ အဆောင်စည်းကမ်းကို ဒီမှာသိမ်းနိုင်သည်။')),
    ...widget.state.documents.reversed.map((d)=>Card(child:ListTile(leading:Icon(d.confirmed?Icons.verified_outlined:Icons.fact_check_outlined),title:Text(d.name),subtitle:Text('${d.kind} · ${d.confirmed?'စစ်ပြီး':'စာသားစစ်ရန်'}${d.selected?' · AI context ရွေးထား':''}'),trailing:const Icon(Icons.chevron_right),onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>DocumentEditor(widget.state,d.id)))))),
    sectionTitle(context,'ကိုယ့် timeline'),
    OutlinedButton.icon(onPressed:addEvent,icon:const Icon(Icons.event),label:const Text('ရက်စွဲ / ဖြစ်ရပ် ထည့်မယ်')),
    ...([...widget.state.events]..sort((a,b)=>b['date'].toString().compareTo(a['date'].toString()))).map((e)=>ListTile(contentPadding:EdgeInsets.zero,title:Text(e['title']),subtitle:Text(e['date']))),
    note(context,'ဤ timeline သည် မှတ်စုဖြစ်သည်။ Official deadline တွက်ချက်အတည်ပြုခြင်းနှင့် reminder notification service မဟုတ်ပါ။')
  ]);
}

class ProfileEditor extends StatefulWidget {
  final AppState state;const ProfileEditor(this.state,{super.key});
  @override State<ProfileEditor> createState()=>_ProfileEditorState();
}
class _ProfileEditorState extends State<ProfileEditor> {
  late Map<String,TextEditingController> values;String workers='unknown';DateTime? start,stay;
  bool confirmed=false;
  @override void initState(){super.initState();final p=widget.state.profile;
    values={for(final k in ['visa','nationality','sector','hourly','contractState','dorm'])k:TextEditingController(text:p[k]?.toString()??'')};
    workers=p['workers']??'unknown';start=DateTime.tryParse(p['start']??'');stay=DateTime.tryParse(p['stayExpiry']??'');confirmed=p['confirmed']==true;
  }
  @override void dispose(){for(final v in values.values){v.dispose();}super.dispose();}
  Future<void> pick(bool work) async {final date=await showDatePicker(context:context,initialDate:(work?start:stay)??DateTime.now(),firstDate:DateTime(2000),lastDate:DateTime(2100));if(date!=null && mounted)setState((){if(work)start=date;else stay=date;confirmed=false;});}
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Profile ပြင်ရန်')),body:ListView(padding:const EdgeInsets.all(20),children:[
    note(context,'မသိသောအချက်ကို အလွတ်ထားပါ။ ARC / passport နံပါတ် ထည့်ရန်မလိုပါ။ Profile ကို AI သို့သုံးရန် သီးခြားရွေးပြီး preview စစ်ရပါမည်။'),
    for(final pair in [('visa','လက်ရှိ 체류자격 / Visa subtype'),('nationality','နိုင်ငံသား'),('sector','လုပ်ငန်းအမျိုးအစား'),('hourly','Ordinary hourly wage (₩)'),('contractState','လက်ရှိစာချုပ် / အလုပ်အခြေအနေ'),('dorm','အဆောင်နှင့်ဖြတ်ငွေ မှတ်စု')])Padding(padding:const EdgeInsets.symmetric(vertical:8),child:TextField(controller:values[pair.$1],onChanged:(_)=>setState(()=>confirmed=false),maxLines:pair.$1=='dorm'||pair.$1=='contractState'?3:1,decoration:InputDecoration(labelText:pair.$2,border:const OutlineInputBorder()))),
    DropdownButtonFormField<String>(value:workers,decoration:const InputDecoration(labelText:'ပုံမှန်အလုပ်သမားဦးရေ'),items:const[DropdownMenuItem(value:'unknown',child:Text('မသိသေး')),DropdownMenuItem(value:'1-4',child:Text('၄ ဦးနှင့်အောက်')),DropdownMenuItem(value:'5+',child:Text('၅ ဦးနှင့်အထက်'))],onChanged:(v)=>setState((){workers=v!;confirmed=false;})),
    const SizedBox(height:12),OutlinedButton(onPressed:()=>pick(true),child:Text('အလုပ်စရက်: ${start==null?'မဖြည့်ရသေး':dateLabel(start!)}')),
    OutlinedButton(onPressed:()=>pick(false),child:Text('현재 체류기간 만료일: ${stay==null?'မဖြည့်ရသေး':dateLabel(stay!)}')),
    TextButton(onPressed:()=>setState((){start=null;stay=null;confirmed=false;}),child:const Text('ရက်စွဲနှစ်ခု ရှင်းရန်')),
    CheckboxListTile(contentPadding:EdgeInsets.zero,value:confirmed,onChanged:(v)=>setState(()=>confirmed=v??false),title:const Text('အချက်အလက်ကို ကိုယ်တိုင်စစ်ပြီးပြီ')),
    FilledButton(onPressed:() async {await widget.state.setProfile({for(final e in values.entries)e.key:e.value.text.trim(),'workers':workers,'start':start==null?'':dateLabel(start!),'stayExpiry':stay==null?'':dateLabel(stay!),'confirmed':confirmed});if(!confirmed)await widget.state.setSetting('profileContext',false);if(context.mounted)Navigator.pop(context);},child:const Text('ဖုန်းပေါ်တွင် သိမ်းမယ်'))
  ]));
}

class DocumentEditor extends StatefulWidget {
  final AppState state;final String id;
  const DocumentEditor(this.state,this.id,{super.key});
  @override State<DocumentEditor> createState()=>_DocumentEditorState();
}
class _DocumentEditorState extends State<DocumentEditor> {
  late PersonalDocument original;late TextEditingController text;
  late bool confirmed;bool selected=false,saving=false;
  @override void initState(){super.initState();original=widget.state.documents.firstWhere((d)=>d.id==widget.id);text=TextEditingController(text:original.text);confirmed=original.confirmed;selected=original.selected;}
  @override void dispose(){text.dispose();super.dispose();}
  Future<void> viewOriginal() async {
    try {final bytes=await widget.state.vault.readDocument(widget.id);if(!mounted)return;
      await Navigator.push(context,MaterialPageRoute(builder:(context)=>Scaffold(appBar:AppBar(title:Text(original.name)),body:original.name.toLowerCase().endsWith('.pdf')?PdfViewer.data(bytes,sourceName:widget.id):original.name.endsWith('.txt')?Padding(padding:const EdgeInsets.all(20),child:SelectableText(utf8.decode(bytes))):InteractiveViewer(minScale:.5,maxScale:5,child:Center(child:Image.memory(bytes))))));
    }catch(e){if(mounted)message(context,'မူရင်းဖိုင်ကိုဖွင့်မရပါ။ $e');}
  }
  Future<void> save() async {
    if(text.text.trim().length>180000){message(context,'စာသား 180,000 characters ထက်ကျော်နေသည်။ ခွဲ၍သိမ်းပါ။');return;}
    setState(()=>saving=true);
    try {await widget.state.putDocument(original.copyWith(text:text.text,confirmed:confirmed&&text.text.trim().isNotEmpty,selected:selected&&confirmed));if(context.mounted){message(context,'စာသားနှင့်ရွေးချယ်မှုသိမ်းပြီးပြီ။');Navigator.pop(context);}}
    catch(e){if(mounted)message(context,e.toString());}
    finally{if(mounted)setState(()=>saving=false);}
  }
  Future<void> remove() async {
    final ok=await showDialog<bool>(context:context,builder:(context)=>AlertDialog(title:const Text('စာရွက်ဖျက်မလား?'),content:const Text('မူရင်းနဲ့စာသားကို ဤဖုန်းမှ ဖျက်မည်။ အရင် chat history ထဲ သိမ်းထားသော excerpt များကိုဖျက်လိုလျှင် AI tab တွင် history ကိုပါရှင်းပါ။'),actions:[TextButton(onPressed:()=>Navigator.pop(context,false),child:const Text('မဖျက်တော့ဘူး')),FilledButton(onPressed:()=>Navigator.pop(context,true),child:const Text('ဖျက်မယ်'))]));
    if(ok==true){await widget.state.removeDocument(widget.id);if(mounted)Navigator.pop(context);}
  }
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:Text(original.kind),actions:[IconButton(tooltip:'ဖျက်ရန်',onPressed:saving?null:remove,icon:const Icon(Icons.delete_outline))]),body:ListView(padding:const EdgeInsets.all(20),children:[
    Text(original.name,style:Theme.of(context).textTheme.titleMedium),
    OutlinedButton.icon(onPressed:viewOriginal,icon:const Icon(Icons.visibility_outlined),label:const Text('မူရင်း PDF / ပုံကို ဖတ်မယ်')),
    note(context,'ရက်၊ ငွေ၊ အလုပ်ချိန်၊ အမည်နှင့် Korean စာသားကို မူရင်းနှင့်ယှဉ်စစ်ပါ။ OCR မှားနိုင်သည်။ ဤစာသားသည် contract evidence ဖြစ်ပြီး ဥပဒေရင်းမြစ် မဟုတ်ပါ။'),
    TextField(controller:text,minLines:10,maxLines:24,onChanged:(_)=>setState((){confirmed=false;selected=false;}),decoration:const InputDecoration(labelText:'ထုတ်ထားသောစာသား · ပြင်နိုင်သည်',alignLabelWithHint:true,border:OutlineInputBorder())),
    CheckboxListTile(contentPadding:EdgeInsets.zero,value:confirmed,onChanged:text.text.trim().isEmpty?null:(v)=>setState((){confirmed=v??false;if(!confirmed)selected=false;}),title:const Text('မူရင်းနှင့် စစ်ပြီးပြီ')),
    SwitchListTile(contentPadding:EdgeInsets.zero,value:selected,onChanged:confirmed?(v)=>setState(()=>selected=v):null,title:const Text('AI context အတွက် ရွေးထားမယ်'),subtitle:const Text('Online send တိုင်း ပို့မည့်စာသားကို ထပ်စစ်နိုင်သည်။')),
    FilledButton(onPressed:saving?null:save,child:const Text('သိမ်းမယ်'))
  ]));
}
