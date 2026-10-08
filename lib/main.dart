import 'package:flutter/material.dart';
import 'core/app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {runApp(KwrApp(await AppState.load()));}
  catch(error) {runApp(MaterialApp(home:Scaffold(body:SafeArea(child:Padding(
    padding:const EdgeInsets.all(24),child:SelectableText('App ဖွင့်မရပါ။ ကိုယ်ရေးဒေတာမဖျက်ဘဲ ပြန်ဖွင့်ပါ။\n$error'))))));}
}
class KwrApp extends StatelessWidget {
  final AppState state;
  const KwrApp(this.state,{super.key});
  @override Widget build(BuildContext context)=>MaterialApp(
    title:'KWR Myanmar',debugShowCheckedModeBanner:false,
    theme:ThemeData(colorScheme:ColorScheme.fromSeed(seedColor:const Color(0xff086e76)),useMaterial3:true),
    home:Scaffold(appBar:AppBar(title:const Text('KWR Myanmar')),body:ListView(
      padding:const EdgeInsets.all(20),children:state.cards.map((c)=>Card(child:Padding(
        padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,
        children:[Text(c.title),const SizedBox(height:12),Text(c.summary)])))).toList())));
}
