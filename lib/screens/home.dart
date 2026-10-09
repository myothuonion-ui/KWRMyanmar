import 'package:flutter/material.dart';

import '../core/app_state.dart';
import 'widgets.dart';
import 'handbook_screens.dart';
import 'calculators.dart';

class HomeScreen extends StatelessWidget {
  final AppState state;
  final void Function(String) onAsk, onSearch, onCategory;
  const HomeScreen(
    this.state,
    this.onAsk, {
    required this.onSearch,
    required this.onCategory,
    super.key,
  });
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
    children: [
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xff102e36), Color(0xff176156)],
          ),
          borderRadius: BorderRadius.circular(26),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'KOREA · MYANMAR',
                        style: TextStyle(
                          color: Color(0xffcae6dc),
                          fontSize: 10,
                          letterSpacing: 1.4,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Icon(
                  Icons.menu_book_rounded,
                  color: Color(0xffacd6bf),
                  size: 26,
                ),
              ],
            ),
            const SizedBox(height: 22),
            const Text(
              'ကိုရီးယားဘဝ၊\nရှင်းရှင်းလင်းလင်း',
              style: TextStyle(
                fontSize: 25,
                height: 1.65,
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'အခွင့်အရေးကို နားလည်ဖို့၊\nနေ့စဉ်ဘဝမှာ အားကိုးဖို့။',
              style: TextStyle(color: Color(0xffd3e5df), height: 1.9),
            ),
            const SizedBox(height: 20),
            Text(
              '${state.cards.length} လက်စွဲ  ·  ${state.sources.length} မူရင်း  ·  OFFLINE',
              style: const TextStyle(
                color: Color(0xffb6dbc8),
                fontSize: 11,
                height: 1.7,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      Material(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => onSearch(''),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.search,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'လစာ၊ အာမခံ၊ ဗီဇာ… ရှာမယ်',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const Icon(Icons.arrow_forward, size: 18),
              ],
            ),
          ),
        ),
      ),
      const SizedBox(height: 26),
      Text(
        'ဘယ်အကြောင်း သိချင်လဲ',
        style: Theme.of(context).textTheme.titleLarge,
      ),
      const SizedBox(height: 16),
      LayoutBuilder(
        builder: (context, box) => Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final c in handbookCategories.entries)
              SizedBox(
                width: (box.maxWidth - 12) / 2,
                child: Material(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(18),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => onCategory(c.key),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            c.value,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            c.key,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            '${state.cards.where((g) => g.category == c.key).length} လက်စွဲ',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      const SizedBox(height: 28),
      Text('အခုအကူအညီလိုနေလား', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 12),
      for (final row in [
        ('unpaid', 'လစာမရသေးဘူး', Icons.payments_outlined),
        ('insurance_map', 'အာမခံဘာတွေရှိလဲ', Icons.shield_outlined),
        ('change1month', 'အလုပ်ပြောင်းချင်တယ်', Icons.swap_horiz),
      ])
        Card(
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 6,
            ),
            leading: Icon(row.$3, color: Theme.of(context).colorScheme.primary),
            title: Text(row.$2),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              final g = state.cards.where((c) => c.id == row.$1);
              if (g.isNotEmpty)
                readGuide(context, state, g.first, onAsk);
              else
                onSearch(row.$2);
            },
          ),
        ),
      const SizedBox(height: 26),
      Text(
        'ကိုယ့်အတွက် အသုံးဝင်တာ',
        style: Theme.of(context).textTheme.titleLarge,
      ),
      const SizedBox(height: 12),
      Card(
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.calculate_outlined),
              title: const Text('လစာနှင့် အပိုကြေး တွက်မယ်'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => Scaffold(
                    appBar: AppBar(title: const Text('လစာတွက်ချက်မှု')),
                    body: PayScreen(state),
                  ),
                ),
              ),
            ),
            const Divider(height: 1, indent: 56),
            ListTile(
              leading: const Icon(Icons.badge_outlined),
              title: const Text('ဗီဇာနှင့် အချိန်ကာလ စစ်မယ်'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => Scaffold(
                    appBar: AppBar(title: const Text('ဗီဇာအချိန်ကာလ')),
                    body: VisaScreen(state, onAsk),
                  ),
                ),
              ),
            ),
            const Divider(height: 1, indent: 56),
            ListTile(
              leading: const Icon(Icons.fact_check_outlined),
              title: const Text('အလုပ်ထုတ်ခံရမှု စစ်မယ်'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => DismissalScreen(state)),
              ),
            ),
            const Divider(height: 1, indent: 56),
            ListTile(
              leading: const Icon(Icons.auto_awesome_outlined),
              title: const Text('AI နှင့် ရင်းမြစ်ရှာဖွေမှု'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => onAsk(''),
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      note(
        context,
        'KWR Myanmar · လက်စွဲမူ ၂၀၂၆-၁၀-၀၉\nလက်စွဲနှင့် မူရင်းဖတ်ခြင်းသည် အင်တာနက်မလိုပါ။ AI အဖြေအသစ်အတွက် အင်တာနက်၊ ကိုယ့် API key နှင့် model လိုအပ်သည်။',
      ),
    ],
  );
}
