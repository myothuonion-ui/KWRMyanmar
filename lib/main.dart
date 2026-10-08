import 'package:flutter/material.dart';
import 'core/app_state.dart';
import 'screens/home.dart';
import 'screens/chat.dart';
import 'screens/calculators.dart';
import 'screens/files.dart';
import 'screens/settings.dart';

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
    theme:ThemeData(colorScheme:ColorScheme.fromSeed(seedColor:const Color(0xff086e76)),scaffoldBackgroundColor:const Color(0xfff6f8f7),useMaterial3:true),
    darkTheme:ThemeData(colorScheme:ColorScheme.fromSeed(seedColor:const Color(0xff58b5b9),brightness:Brightness.dark),useMaterial3:true),
    home:AppShell(state));
}

class AppShell extends StatefulWidget {
  final AppState state;const AppShell(this.state,{super.key});
  @override State<AppShell> createState()=>_AppShellState();
}
class _AppShellState extends State<AppShell> {
  int index=0,resetVersion=0;var chatKey=GlobalKey<ChatScreenState>();
  void ask(String question){setState(()=>index=1);chatKey.currentState?.setQuestion(question);}
  @override Widget build(BuildContext context)=>ListenableBuilder(listenable:widget.state,builder:(context,_){
    if(resetVersion!=widget.state.resetVersion){resetVersion=widget.state.resetVersion;chatKey=GlobalKey<ChatScreenState>();index=0;}
    return Scaffold(
    appBar:AppBar(title:const Text('KWR Myanmar'),actions:[IconButton(tooltip:'Settings',onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>SettingsScreen(widget.state))),icon:const Icon(Icons.settings_outlined))]),
    body:IndexedStack(key:ValueKey(resetVersion),index:index,children:[HomeScreen(widget.state,ask),ChatScreen(widget.state,key:chatKey),VisaScreen(widget.state,ask),PayScreen(widget.state),FilesScreen(widget.state)]),
    bottomNavigationBar:NavigationBar(selectedIndex:index,onDestinationSelected:(v)=>setState(()=>index=v),destinations:const[
      NavigationDestination(icon:Icon(Icons.space_dashboard_outlined),selectedIcon:Icon(Icons.space_dashboard),label:'ကတ်များ'),
      NavigationDestination(icon:Icon(Icons.chat_bubble_outline),selectedIcon:Icon(Icons.chat_bubble),label:'AI'),
      NavigationDestination(icon:Icon(Icons.badge_outlined),selectedIcon:Icon(Icons.badge),label:'Visa'),
      NavigationDestination(icon:Icon(Icons.calculate_outlined),selectedIcon:Icon(Icons.calculate),label:'လစာ'),
      NavigationDestination(icon:Icon(Icons.folder_outlined),selectedIcon:Icon(Icons.folder),label:'ကိုယ့်ဖိုင်')
    ]));});
}
