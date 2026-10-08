import 'package:flutter/material.dart';
import '../core/app_state.dart';
import '../core/rules.dart';
import 'widgets.dart';
import 'calculators.dart';

class HomeScreen extends StatefulWidget {
  final AppState state;final void Function(String) onAsk;
  const HomeScreen(this.state,this.onAsk,{super.key});
  @override State<HomeScreen> createState()=>_HomeScreenState();
}
class _HomeScreenState extends State<HomeScreen> {
  final search=TextEditingController();String category='အားလုံး';bool savedOnly=false;
  @override void dispose(){search.dispose();super.dispose();}
  @override Widget build(BuildContext context) {
    final state=widget.state;
    final cards=searchCards(state.cards,search.text).where((c)=>(category=='အားလုံး'||c.category==category)&&(!savedOnly||state.bookmarks.contains(c.id))).toList();
    final categories=['အားလုံး',...state.cards.map((c)=>c.category).toSet()];
    return ListView(padding:const EdgeInsets.fromLTRB(18,8,18,24),children:[
      Container(padding:const EdgeInsets.all(22),decoration:BoxDecoration(color:Theme.of(context).colorScheme.primaryContainer,borderRadius:BorderRadius.circular(22)),
        child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('ကိုယ့်အခွင့်အရေးကို\nနားလည်ဖို့',style:Theme.of(context).textTheme.headlineSmall?.copyWith(height:1.65)),
          const SizedBox(height:10),Text('ကတ်တိုတွေဖတ်ပါ။ ကိုယ့်အခြေအနေနဲ့ စစ်ပါ။',style:TextStyle(color:Theme.of(context).colorScheme.onPrimaryContainer,height:1.8)),
          const SizedBox(height:12),Wrap(spacing:8,runSpacing:8,children:[
            FilledButton(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>DismissalScreen(state))),child:const Text('အလုပ်ထုတ်ခံရမှု စစ်ရန်')),
            OutlinedButton(onPressed:()=>widget.onAsk('ကိုယ့်စာချုပ်နဲ့ လစာစာရွက်ကို ဘယ်လိုစစ်ရမလဲ?'),child:const Text('AI ကိုမေးရန်'))])])),
      const SizedBox(height:18),TextField(controller:search,onChanged:(_)=>setState((){}),decoration:InputDecoration(prefixIcon:const Icon(Icons.search),hintText:'အလုပ်ထုတ်၊ ညဆိုင်း၊ E-9…',border:OutlineInputBorder(borderRadius:BorderRadius.circular(14)),suffixIcon:search.text.isEmpty?null:IconButton(onPressed:(){search.clear();setState((){});},icon:const Icon(Icons.close)))),
      const SizedBox(height:12),SingleChildScrollView(scrollDirection:Axis.horizontal,child:Row(children:categories.map((c)=>Padding(padding:const EdgeInsets.only(right:8),child:ChoiceChip(label:Text(c),selected:category==c,onSelected:(_)=>setState(()=>category=c)))).toList())),
      SwitchListTile(contentPadding:EdgeInsets.zero,title:const Text('သိမ်းထားတဲ့ကတ်များ'),value:savedOnly,onChanged:(v)=>setState(()=>savedOnly=v)),
      if(cards.isEmpty) Padding(padding:const EdgeInsets.all(20),child:Text('သက်ဆိုင်တဲ့ကတ် မတွေ့သေးပါ။ စကားလုံးပြောင်းရှာပါ သို့မဟုတ် AI ကိုမေးပါ။')),
      ...cards.map((c)=>TopicCard(c,onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>CardDetail(state,c,widget.onAsk))))),
      note(context,'Content pack 2026-10-08 · ${state.cards.length} ကတ် · Offline ရင်းမြစ်အနှစ်ချုပ်များ။ Latest rule ပြောင်းလဲမှုကို official source မှစစ်ပါ။')
    ]);
  }
}
