import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/app_state.dart';
import '../core/models.dart';
import 'source_reader.dart';

void message(BuildContext context, String text) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
Widget sectionTitle(BuildContext context, String text) => Padding(
  padding: const EdgeInsets.only(top: 18, bottom: 10),
  child: Text(text, style: Theme.of(context).textTheme.titleMedium),
);
Widget note(BuildContext context, String text) => Padding(
  padding: const EdgeInsets.symmetric(vertical: 8),
  child: Text(
    text,
    style: Theme.of(context).textTheme.bodySmall?.copyWith(
      height: 1.8,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    ),
  ),
);
Widget field(
  String label,
  TextEditingController controller, {
  int lines = 1,
  bool number = false,
  bool obscure = false,
  ValueChanged<String>? onChanged,
}) => Padding(
  padding: const EdgeInsets.symmetric(vertical: 8),
  child: TextField(
    controller: controller,
    maxLines: lines,
    obscureText: obscure,
    onChanged: onChanged,
    keyboardType: number
        ? const TextInputType.numberWithOptions(decimal: true)
        : null,
    decoration: InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
    ),
  ),
);
Future<void> openSource(BuildContext context, String url) async {
  try {
    final ok = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!ok && context.mounted)
      message(context, 'ရင်းမြစ်ဖွင့်မရပါ။ အင်တာနက်နှင့် browser ကိုစစ်ပါ။');
  } catch (_) {
    if (context.mounted) message(context, 'ရင်းမြစ်ဖွင့်မရပါ။');
  }
}

class StatusPill extends StatelessWidget {
  final String text;
  final IconData icon;
  const StatusPill(this.text, this.icon, {super.key});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.primary.withValues(alpha: .08),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    ),
  );
}

class EmptyPanel extends StatelessWidget {
  final IconData icon;
  final String title, description;
  const EmptyPanel(this.icon, this.title, this.description, {super.key});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 12),
    child: Column(
      children: [
        Icon(icon, size: 44, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 18),
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 10),
        Text(
          description,
          textAlign: TextAlign.center,
          style: TextStyle(
            height: 1.9,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    ),
  );
}

class TopicCard extends StatelessWidget {
  final LegalCard card;
  final VoidCallback onTap;
  const TopicCard(this.card, {required this.onTap, super.key});
  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    card.category,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 12,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_outward,
                  size: 18,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(card.title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              card.summary,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                height: 1.85,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            if (card.pending)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  'မူအသစ်နှင့် အခြေအနေစစ်ရန်လို',
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

class CardDetail extends StatefulWidget {
  final AppState state;
  final LegalCard card;
  final void Function(String) onAsk;
  const CardDetail(this.state, this.card, this.onAsk, {super.key});
  @override
  State<CardDetail> createState() => _CardDetailState();
}

class _CardDetailState extends State<CardDetail> {
  late final keys = List.generate(
    widget.card.sections.length,
    (_) => GlobalKey(),
  );
  Future<void> contents() async {
    final index = await showModalBottomSheet<int>(
      context: context,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const Padding(padding: EdgeInsets.all(20), child: Text('မာတိကာ')),
            for (var i = 0; i < widget.card.sections.length; i++)
              ListTile(
                title: Text(widget.card.sections[i].title),
                leading: Text('${i + 1}'),
                onTap: () => Navigator.pop(context, i),
              ),
          ],
        ),
      ),
    );
    if (index != null && mounted && keys[index].currentContext != null) {
      await Scrollable.ensureVisible(
        keys[index].currentContext!,
        duration: const Duration(milliseconds: 300),
        alignment: .05,
      );
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.state,
    builder: (context, _) {
      final state = widget.state;
      final card = widget.card;
      final scale = (state.settings['readerScale'] as num? ?? 1).toDouble();
      final linked = state.sources
          .where((s) => card.sourceIds.contains(s.id))
          .toList();
      return Scaffold(
        appBar: AppBar(
          title: Text(card.category),
          actions: [
            if (card.sections.isNotEmpty)
              IconButton(
                tooltip: 'မာတိကာ',
                onPressed: contents,
                icon: const Icon(Icons.format_list_bulleted),
              ),
            IconButton(
              tooltip: 'သိမ်းရန်',
              onPressed: () => state.toggleBookmark(card.id),
              icon: Icon(
                state.bookmarks.contains(card.id)
                    ? Icons.bookmark
                    : Icons.bookmark_border,
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 8, 22, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const StatusPill('OFFLINE လက်စွဲ', Icons.menu_book_outlined),
              const SizedBox(height: 18),
              Text(
                card.title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary
                      .withValues(alpha: .07),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: SelectableText(
                  card.summary,
                  style: TextStyle(
                    fontSize: 16 * scale,
                    height: 1.95,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'ဖတ်ရန် စာလုံးအရွယ်',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  IconButton(
                    tooltip: 'စာလုံးသေးရန်',
                    onPressed: scale > .85
                        ? () => state.setSetting(
                            'readerScale',
                            (scale - .1).clamp(.85, 1.5),
                          )
                        : null,
                    icon: const Icon(Icons.text_decrease),
                  ),
                  IconButton(
                    tooltip: 'စာလုံးကြီးရန်',
                    onPressed: scale < 1.5
                        ? () => state.setSetting(
                            'readerScale',
                            (scale + .1).clamp(.85, 1.5),
                          )
                        : null,
                    icon: const Icon(Icons.text_increase),
                  ),
                ],
              ),
              if (card.pending)
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    'ဤအကြောင်းအရာ၏ မူအသစ် သို့မဟုတ် လူတစ်ဦးချင်းအကျုံးဝင်မှုကို ထပ်စစ်ရန်လိုသည်။ အောက်ပါအချက်များအပေါ်သာ မူတည်ပြီး ဆုံးဖြတ်ခြင်းမပြုပါနှင့်။',
                    style: TextStyle(height: 1.9),
                  ),
                ),
              SelectableText(
                card.body,
                style: TextStyle(fontSize: 16 * scale, height: 2),
              ),
              for (var i = 0; i < card.sections.length; i++)
                Padding(
                  key: keys[i],
                  padding: const EdgeInsets.only(top: 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        card.sections[i].title,
                        style: Theme.of(context).textTheme.titleLarge
                            ?.copyWith(fontSize: 19 * scale),
                      ),
                      const SizedBox(height: 12),
                      SelectableText(
                        card.sections[i].text,
                        style: TextStyle(fontSize: 16 * scale, height: 2),
                      ),
                    ],
                  ),
                ),
              if (card.steps.isNotEmpty) ...[
                const SizedBox(height: 28),
                Text(
                  'လက်တွေ့ ဆက်လုပ်ရန်',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                for (var i = 0; i < card.steps.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 26,
                          height: 26,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary
                                .withValues(alpha: .1),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${i + 1}',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SelectableText(
                            card.steps[i],
                            style: TextStyle(fontSize: 15 * scale, height: 1.9),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
              const Divider(height: 44),
              Text(
                'ရင်းမြစ်နှင့် မူရင်းအပြည့်အစုံ',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              note(
                context,
                'မြန်မာရှင်းလင်းချက် စစ်ဆေးရက် ${card.checked}\n${card.source}',
              ),
              for (final s in linked)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.offline_pin_outlined),
                    title: Text(s.title),
                    subtitle: Text(
                      'Offline · ${s.pages.length} စာမျက်နှာ · ${s.edition}',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => SourceReader(state, s)),
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => openSource(context, card.url),
                icon: const Icon(Icons.open_in_new),
                label: const Text('Online · တရားဝင်ရင်းမြစ်'),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () => widget.onAsk(card.title),
                icon: const Icon(Icons.auto_awesome_outlined),
                label: const Text('ကိုယ့်အခြေအနေနဲ့ မေးမယ်'),
              ),
              note(
                context,
                'မြန်မာစာသည် ရှင်းလင်းချက်ဖြစ်သည်။ မူရင်းနှင့် ကွဲလွဲပါက တရားဝင်မူကို စစ်ဆေးပါ။ မူရင်းစာတမ်းပါ အနာဂတ်စတင်သက်ရောက်မည့် ပြင်ဆင်ချက်ကို ယနေ့အတွက် စည်းမျဉ်းဟု မယူပါနှင့်။',
              ),
            ],
          ),
        ),
      );
    },
  );
}
