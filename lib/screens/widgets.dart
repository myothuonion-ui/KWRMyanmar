import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/app_state.dart';
import '../core/models.dart';

void message(BuildContext context,String text) => ScaffoldMessenger.of(context)
  .showSnackBar(SnackBar(content:Text(text)));
Widget sectionTitle(BuildContext context,String text)=>Padding(
  padding:const EdgeInsets.only(top:18,bottom:10),child:Text(text,style:Theme.of(context).textTheme.titleMedium));
Widget note(BuildContext context,String text)=>Padding(padding:const EdgeInsets.symmetric(vertical:8),
  child:Text(text,style:Theme.of(context).textTheme.bodySmall?.copyWith(height:1.8,color:Theme.of(context).colorScheme.onSurfaceVariant)));
Widget field(String label,TextEditingController controller,{int lines=1,bool number=false, bool obscure=false})=>Padding(
  padding:const EdgeInsets.symmetric(vertical:8),child:TextField(controller:controller,maxLines:lines,
    obscureText:obscure,keyboardType:number?const TextInputType.numberWithOptions(decimal:true):null,
    decoration:InputDecoration(labelText:label,border:const OutlineInputBorder())));
Future<void> openSource(BuildContext context,String url) async {
  try {final ok=await launchUrl(Uri.parse(url),mode:LaunchMode.externalApplication);
    if(!ok && context.mounted) message(context,'ရင်းမြစ်ဖွင့်မရပါ။ အင်တာနက်နှင့် browser ကိုစစ်ပါ။');
  }catch(_){if(context.mounted) message(context,'ရင်းမြစ်ဖွင့်မရပါ။');}
}

class TopicCard extends StatelessWidget {
  final LegalCard card;final VoidCallback onTap;
  const TopicCard(this.card,{required this.onTap,super.key});
  @override Widget build(BuildContext context)=>Card(margin:const EdgeInsets.only(bottom:12),
    child:InkWell(onTap:onTap,borderRadius:BorderRadius.circular(16),child:Padding(
      padding:const EdgeInsets.all(18),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Text(card.category,style:TextStyle(color:Theme.of(context).colorScheme.primary,fontSize:12)),
        const SizedBox(height:9),Text(card.title,style:Theme.of(context).textTheme.titleMedium?.copyWith(height:1.8)),
        const SizedBox(height:9),Text(card.summary,style:const TextStyle(height:1.9)),
        const SizedBox(height:10),Row(children:[Expanded(child:Text(card.pending?'မူအသစ်စစ်ရန်လို':'ရင်းမြစ်စစ် ${card.checked}',style:Theme.of(context).textTheme.bodySmall)),const Icon(Icons.arrow_forward,size:18)])
      ]))));
}

class CardDetail extends StatelessWidget {
  final AppState state;final LegalCard card;final void Function(String) onAsk;
  const CardDetail(this.state,this.card,this.onAsk,{super.key});
  @override Widget build(BuildContext context)=>ListenableBuilder(listenable:state,builder:(context,_)=>Scaffold(
    appBar:AppBar(title:Text(card.category),actions:[IconButton(tooltip:'သိမ်းရန်',onPressed:()=>state.toggleBookmark(card.id),
      icon:Icon(state.bookmarks.contains(card.id)?Icons.bookmark:Icons.bookmark_border))]),
    body:ListView(padding:const EdgeInsets.all(20),children:[
      Text(card.title,style:Theme.of(context).textTheme.headlineSmall?.copyWith(height:1.7)),
      const SizedBox(height:20),SelectableText(card.summary,style:Theme.of(context).textTheme.titleMedium?.copyWith(height:1.9)),
      const SizedBox(height:20),SelectableText(card.body,style:const TextStyle(height:2)),
      sectionTitle(context,'ဆက်လုပ်ရန်'),...card.steps.map((s)=>Padding(padding:const EdgeInsets.symmetric(vertical:7),child:Text('• $s',style:const TextStyle(height:1.9)))),
      const Divider(height:28),Text(card.source),note(context,'ရင်းမြစ်စစ်ရက် ${card.checked} · ဥပဒေပညာရှင်စစ်ပြီးသော အပြီးသတ်အမှုဆုံးဖြတ်ချက် မဟုတ်ပါ။'),
      if(card.pending) note(context,'ဤ topic အတွက် latest detailed rule မပြည့်သေးပါ။ အတည်ပြုရန်လိုသည်။'),
      OutlinedButton.icon(onPressed:()=>openSource(context,card.url),icon:const Icon(Icons.open_in_new),label:const Text('တရားဝင်ရင်းမြစ်ကို ဖွင့်မယ်')),
      const SizedBox(height:12),FilledButton.icon(onPressed:(){Navigator.pop(context);onAsk(card.title);},icon:const Icon(Icons.chat_bubble_outline),label:const Text('ကိုယ့်အခြေအနေနဲ့ မေးမယ်'))
    ])));
}
