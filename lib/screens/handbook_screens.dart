import 'dart:async';

import 'package:flutter/material.dart';

import '../core/app_state.dart';
import '../core/handbook.dart';
import '../core/models.dart';
import 'widgets.dart';
import 'source_reader.dart';

const handbookCategories = <String, IconData>{
  'အလုပ်': Icons.work_outline,
  'လစာ': Icons.payments_outlined,
  'အာမခံ': Icons.health_and_safety_outlined,
  'ဗီဇာ': Icons.badge_outlined,
  'နေထိုင်မှု': Icons.home_outlined,
  'ကျန်းမာရေး': Icons.medical_services_outlined,
  'နေ့စဉ်ဘဝ': Icons.explore_outlined,
  'အရေးပေါ်': Icons.support_agent_outlined,
};
void readGuide(
  BuildContext context,
  AppState state,
  LegalCard guide,
  void Function(String) ask,
) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => CardDetail(state, guide, ask)),
  );
}

void readSource(
  BuildContext context,
  AppState state,
  SourceDocument source, {
  int page = 1,
}) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => SourceReader(state, source, initialPage: page),
    ),
  );
}

class SourceTile extends StatelessWidget {
  final SourceDocument source;
  final VoidCallback onTap;
  const SourceTile(this.source, {required this.onTap, super.key});
  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      contentPadding: const EdgeInsets.all(16),
      leading: const Icon(Icons.picture_as_pdf_outlined),
      title: Text(source.title),
      subtitle: Text(
        '${source.korean}\n${source.pages.length} စာမျက်နှာ · ${source.edition}',
        style: const TextStyle(height: 1.8),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    ),
  );
}

class LibraryScreen extends StatefulWidget {
  final AppState state;
  final void Function(String) onAsk;
  const LibraryScreen(this.state, this.onAsk, {super.key});
  @override
  State<LibraryScreen> createState() => LibraryScreenState();
}

class LibraryScreenState extends State<LibraryScreen> {
  String category = 'အားလုံး';
  bool originals = false;
  void selectCategory(String value) {
    setState(() {
      category = value;
      originals = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final cards = state.cards.where(
      (g) => category == 'အားလုံး' || g.category == category,
    );
    final sources = state.sources.where(
      (s) => category == 'အားလုံး' || s.category == category,
    );
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        Text(
          'ကိုယ့်ဘဝအတွက် လက်စွဲ',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        note(
          context,
          'နားလည်လွယ်တဲ့ မြန်မာရှင်းလင်းချက်၊ လုပ်ဆောင်ရန်အဆင့်နဲ့ မူရင်းကိုရီးယားစာတမ်းတွေကို အင်တာနက်မလိုဘဲ ဖတ်ပါ။',
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              label: Text('မြန်မာလက်စွဲ ${state.cards.length}'),
              selected: !originals,
              onSelected: (_) => setState(() => originals = false),
            ),
            ChoiceChip(
              label: Text('မူရင်းရင်းမြစ် ${state.sources.length}'),
              selected: originals,
              onSelected: (_) => setState(() => originals = true),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final c in ['အားလုံး', ...handbookCategories.keys])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(c),
                    selected: c == category,
                    onSelected: (_) => setState(() => category = c),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (originals) ...[
          note(
            context,
            '၂၀၂၆-၁၀-၀၉ တွင် သိမ်းယူထားသော မူရင်းများ။ မူထုတ်ရက်ကို စာတမ်းတစ်စောင်စီမှာ ဖော်ပြထားသည်။ ဥပဒေပြောင်းလဲမှုနှင့် ကိုယ့်အခြေအနေကို သီးခြားစစ်ဆေးပါ။',
          ),
          ...sources.map(
            (s) => SourceTile(s, onTap: () => readSource(context, state, s)),
          ),
          if (sources.isEmpty)
            const EmptyPanel(
              Icons.menu_book_outlined,
              'ဤအမျိုးအစားမှာ PDF မပါသေးပါ',
              'မြန်မာလက်စွဲတွင် တရားဝင်ဝက်ဘ်ဆိုက်နှင့် လက်တွေ့လုပ်ဆောင်ရန်အချက်များကို ဖတ်နိုင်သည်။',
            ),
        ] else
          ...cards.map(
            (c) => TopicCard(
              c,
              onTap: () => readGuide(context, state, c, widget.onAsk),
            ),
          ),
        const SizedBox(height: 12),
        note(
          context,
          'လက်စွဲသည် ရွေးချယ်ထားသော အလုပ်နှင့် နေထိုင်မှုအကြောင်းအရာများကို လွှမ်းခြုံသည်။ ဥပဒေအားလုံးနှင့် လူတစ်ဦးချင်းအမှု ဆုံးဖြတ်ချက်များ မပါဝင်ပါ။',
        ),
      ],
    );
  }
}

class SearchScreen extends StatefulWidget {
  final AppState state;
  final void Function(String) onAsk;
  const SearchScreen(this.state, this.onAsk, {super.key});
  @override
  State<SearchScreen> createState() => SearchScreenState();
}

class SearchScreenState extends State<SearchScreen> {
  final input = TextEditingController();
  Timer? debounce;
  String query = '', kind = 'all';
  void setQuery(String value) {
    input.text = value;
    setState(() => query = value);
  }

  @override
  void dispose() {
    debounce?.cancel();
    input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hits = widget.state.index.search(query, kind: kind, limit: 120);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'လိုတာကို ရှာဖတ်ပါ',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 14),
              TextField(
                controller: input,
                onChanged: (v) {
                  debounce?.cancel();
                  debounce = Timer(const Duration(milliseconds: 220), () {
                    if (mounted) setState(() => query = v);
                  });
                },
                decoration: InputDecoration(
                  hintText: 'လစာမရ၊ အာမခံ၊ 임금체불…',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: input.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'ရှင်းရန်',
                          onPressed: () => setQuery(''),
                          icon: const Icon(Icons.close),
                        ),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  for (final pair in [
                    ('all', 'အားလုံး'),
                    ('guides', 'မြန်မာလက်စွဲ'),
                    ('sources', 'မူရင်းစာမျက်နှာ'),
                  ])
                    ChoiceChip(
                      label: Text(pair.$2),
                      selected: kind == pair.$1,
                      onSelected: (_) => setState(() => kind = pair.$1),
                    ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            children: [
              if (query.trim().isEmpty) ...[
                note(
                  context,
                  'ခေါင်းစဉ်၊ လက်စွဲစာသားနဲ့ မူရင်းစာတမ်းရဲ့ စာမျက်နှာတိုင်းကို ရှာသည်။ မြန်မာ၊ ကိုရီးယား၊ English စကားလုံးများသုံးနိုင်သည်။',
                ),
                const SizedBox(height: 16),
                Text(
                  'အများဆုံးလိုအပ်တတ်တာ',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 10,
                  children: [
                    for (final q in [
                      'လစာမရ',
                      'ကျန်းမာရေးအာမခံ',
                      'အလုပ်ပြောင်း',
                      'အလုပ်ဒဏ်ရာ',
                      'စပေါ်ငွေ',
                      '연차',
                      '육아휴직',
                    ])
                      ActionChip(label: Text(q), onPressed: () => setQuery(q)),
                  ],
                ),
              ] else ...[
                note(
                  context,
                  '${hits.length}${hits.length == 120 ? '+' : ''} ရလဒ် · Offline ရှာဖွေမှု',
                ),
                if (hits.isEmpty)
                  EmptyPanel(
                    Icons.search_off,
                    'သက်ဆိုင်ရာစာသား မတွေ့သေးပါ',
                    'စကားလုံးတိုတစ်လုံး၊ ကိုရီးယားအမည် သို့မဟုတ် စာလုံးပေါင်းပြောင်းရှာပါ။ ဤရလဒ်သည် အခွင့်အရေးမရှိဟု အဓိပ္ပာယ်မရပါ။',
                  ),
                for (final hit in hits)
                  Card(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => hit.guide != null
                          ? readGuide(
                              context,
                              widget.state,
                              hit.guide!,
                              widget.onAsk,
                            )
                          : readSource(
                              context,
                              widget.state,
                              hit.source!,
                              page: hit.page!,
                            ),
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              hit.guide != null
                                  ? 'မြန်မာလက်စွဲ · ${hit.guide!.category}'
                                  : 'မူရင်း · စာမျက်နှာ ${hit.page}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              hit.title,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              hit.excerpt,
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                            ),
                            if (hit.source != null)
                              note(context, hit.source!.publisher),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class SavedScreen extends StatelessWidget {
  final AppState state;
  final void Function(String) onAsk;
  const SavedScreen(this.state, this.onAsk, {super.key});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: state,
    builder: (context, _) {
      final guides = state.cards.where((g) => state.bookmarks.contains(g.id));
      final pages = state.bookmarks.where((b) => b.startsWith('src:'));
      return ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Text(
            'ပြန်ဖတ်မယ့်အရာတွေ',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          note(
            context,
            'လက်စွဲနဲ့ မူရင်းစာမျက်နှာကို bookmark လုပ်ပြီး ဒီနေရာမှာ အလွယ်တကူပြန်ဖတ်ပါ။',
          ),
          if (guides.isEmpty && pages.isEmpty)
            const EmptyPanel(
              Icons.bookmark_border,
              'သိမ်းထားတာ မရှိသေးပါ',
              'လက်စွဲ သို့မဟုတ် မူရင်းရင်းမြစ်ဖွင့်ပြီး အပေါ်က bookmark ကိုနှိပ်ပါ။',
            ),
          ...guides.map(
            (g) =>
                TopicCard(g, onTap: () => readGuide(context, state, g, onAsk)),
          ),
          for (final id in pages) ..._pageTile(context, id),
        ],
      );
    },
  );
  List<Widget> _pageTile(BuildContext context, String id) {
    final parts = id.split(':');
    if (parts.length != 3) return [];
    final matches = state.sources.where((s) => s.id == parts[1]);
    if (matches.isEmpty) return [];
    final page = int.tryParse(parts[2]);
    if (page == null || page < 1 || page > matches.first.pages.length)
      return [];
    final s = matches.first;
    return [
      Card(
        child: ListTile(
          leading: const Icon(Icons.bookmark),
          title: Text(s.title),
          subtitle: Text('မူရင်း · စာမျက်နှာ $page'),
          onTap: () => readSource(context, state, s, page: page),
          trailing: IconButton(
            tooltip: 'သိမ်းထားတာဖယ်ရန်',
            onPressed: () => state.toggleBookmark(id),
            icon: const Icon(Icons.close),
          ),
        ),
      ),
    ];
  }
}
