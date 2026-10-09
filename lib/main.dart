import 'package:flutter/material.dart';

import 'core/app_state.dart';
import 'screens/home.dart';
import 'screens/chat.dart';
import 'screens/files.dart';
import 'screens/settings.dart';
import 'screens/handbook_screens.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    runApp(KwrApp(await AppState.load()));
  } catch (error) {
    runApp(
      MaterialApp(
        home: Scaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: SelectableText(
                'App ဖွင့်မရပါ။ ကိုယ်ရေးဒေတာမဖျက်ဘဲ ပြန်ဖွင့်ပါ။\n$error',
              ),
            ),
          ),
        ),
      ),
    );
  }
}

ThemeData handbookTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final scheme =
      ColorScheme.fromSeed(
        seedColor: const Color(0xff167765),
        brightness: brightness,
      ).copyWith(
        primary: dark ? const Color(0xff89d7ba) : const Color(0xff176b58),
        surface: dark ? const Color(0xff18242a) : Colors.white,
        onSurface: dark ? const Color(0xffe6ebe9) : const Color(0xff172e36),
      );
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: 'NotoSansMyanmar',
    scaffoldBackgroundColor: dark
        ? const Color(0xff101c22)
        : const Color(0xfff3f5f2),
  );
  return base.copyWith(
    textTheme: base.textTheme.apply().copyWith(
      headlineSmall: base.textTheme.headlineSmall?.copyWith(
        fontSize: 24,
        height: 1.65,
        fontWeight: FontWeight.w700,
      ),
      titleLarge: base.textTheme.titleLarge?.copyWith(
        fontSize: 19,
        height: 1.8,
        fontWeight: FontWeight.w700,
      ),
      titleMedium: base.textTheme.titleMedium?.copyWith(
        fontSize: 16,
        height: 1.8,
        fontWeight: FontWeight.w600,
      ),
      bodyMedium: base.textTheme.bodyMedium?.copyWith(
        fontSize: 14,
        height: 1.85,
      ),
      bodySmall: base.textTheme.bodySmall?.copyWith(fontSize: 11, height: 1.8),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: base.scaffoldBackgroundColor,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamily: 'NotoSansMyanmar',
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: scheme.onSurface,
      ),
    ),
    cardTheme: CardThemeData(
      color: scheme.surface,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: .35)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surface,
      contentPadding: const EdgeInsets.all(16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: scheme.outlineVariant.withValues(alpha: .6),
        ),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      height: 82,
      indicatorColor: scheme.primary.withValues(alpha: .12),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (s) => TextStyle(
          fontFamily: 'NotoSansMyanmar',
          fontSize: 10,
          fontWeight: s.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w500,
          color: s.contains(WidgetState.selected)
              ? scheme.primary
              : scheme.onSurfaceVariant,
        ),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
  );
}

class KwrApp extends StatelessWidget {
  final AppState state;
  const KwrApp(this.state, {super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'KWR Myanmar',
    debugShowCheckedModeBanner: false,
    theme: handbookTheme(Brightness.light),
    darkTheme: handbookTheme(Brightness.dark),
    home: AppShell(state),
  );
}

class AppShell extends StatefulWidget {
  final AppState state;
  const AppShell(this.state, {super.key});
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int index = 0, resetVersion = 0;
  var libraryKey = GlobalKey<LibraryScreenState>();
  var searchKey = GlobalKey<SearchScreenState>();
  void ask(String question) {
    final key = GlobalKey<ChatScreenState>();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('AI နှင့် ရင်းမြစ်')),
          body: ChatScreen(widget.state, key: key),
        ),
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      key.currentState?.setQuestion(question);
    });
  }

  void search(String query) {
    setState(() => index = 2);
    searchKey.currentState?.setQuery(query);
  }

  void category(String value) {
    setState(() => index = 1);
    libraryKey.currentState?.selectCategory(value);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.state,
    builder: (context, _) {
      if (resetVersion != widget.state.resetVersion) {
        resetVersion = widget.state.resetVersion;
        libraryKey = GlobalKey<LibraryScreenState>();
        searchKey = GlobalKey<SearchScreenState>();
        index = 0;
      }
      return Scaffold(
        appBar: AppBar(
          title: const Text('KWR Myanmar'),
          actions: [
            IconButton(
              tooltip: 'AI',
              onPressed: () => ask(''),
              icon: const Icon(Icons.auto_awesome_outlined),
            ),
            IconButton(
              tooltip: 'Settings',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => SettingsScreen(widget.state)),
              ),
              icon: const Icon(Icons.tune),
            ),
          ],
        ),
        body: IndexedStack(
          key: ValueKey(resetVersion),
          index: index,
          children: [
            HomeScreen(
              widget.state,
              ask,
              onSearch: search,
              onCategory: category,
            ),
            LibraryScreen(widget.state, ask, key: libraryKey),
            SearchScreen(widget.state, ask, key: searchKey),
            SavedScreen(widget.state, ask),
            FilesScreen(widget.state),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: index,
          onDestinationSelected: (v) => setState(() => index = v),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'ပင်မ',
            ),
            NavigationDestination(
              icon: Icon(Icons.menu_book_outlined),
              selectedIcon: Icon(Icons.menu_book_rounded),
              label: 'လက်စွဲ',
            ),
            NavigationDestination(
              icon: Icon(Icons.search),
              selectedIcon: Icon(Icons.manage_search),
              label: 'ရှာဖွေ',
            ),
            NavigationDestination(
              icon: Icon(Icons.bookmark_border),
              selectedIcon: Icon(Icons.bookmark),
              label: 'သိမ်းထား',
            ),
            NavigationDestination(
              icon: Icon(Icons.folder_outlined),
              selectedIcon: Icon(Icons.folder),
              label: 'ကိုယ့်ဖိုင်',
            ),
          ],
        ),
      );
    },
  );
}
