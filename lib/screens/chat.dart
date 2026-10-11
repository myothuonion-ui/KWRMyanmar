import 'package:flutter/material.dart';

import '../core/ai_service.dart';
import '../core/ai_evidence.dart';
import '../core/app_state.dart';
import '../core/context.dart';
import '../core/conversation.dart';
import '../core/models.dart';
import '../core/rules.dart' show maskPrivateText;
import 'settings.dart';
import 'widgets.dart';
import 'source_reader.dart';

class ChatScreen extends StatefulWidget {
  final AppState state;
  final AiService Function()? serviceFactory;
  const ChatScreen(this.state, {super.key, this.serviceFactory});
  @override
  State<ChatScreen> createState() => ChatScreenState();
}

class ChatScreenState extends State<ChatScreen> {
  final input = TextEditingController();
  bool busy = false;
  AiService? service;
  int generation = 0;
  void setQuestion(String text) {
    input.text = text;
  }

  @override
  void dispose() {
    generation++;
    service?.close();
    input.dispose();
    super.dispose();
  }

  void cancel() {
    generation++;
    service?.close();
    service = null;
    if (mounted) setState(() => busy = false);
  }

  Future<Map<String, String>?> preview(
    String query,
    String personal,
    ProviderConfig provider,
    String model,
    List<Map<String, dynamic>> turns,
  ) async {
    final question = TextEditingController(text: maskPrivateText(query));
    final contextInput = TextEditingController(text: personal);
    bool accepted = false;
    bool useHistory = turns.isNotEmpty;
    final previousMessages = conversationMessages(turns);
    final value = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialog) => AlertDialog(
          title: const Text('Online ပို့မည့်အချက်အလက်'),
          content: SizedBox(
            width: 560,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${provider.label} · $model'),
                  note(
                    context,
                    'အောက်ပါမေးခွန်းနှင့် context ကို provider ထံ ပို့မည်။ ID / account / email အချို့ဖျောက်ထားသော်လည်း အမည်၊ လိပ်စာနှင့် အခြားကိုယ်ရေးအချက်များကို ထပ်စစ်ဖယ်ပါ။ API provider ၏ data policy သက်ဆိုင်သည်။',
                  ),
                  TextField(
                    controller: question,
                    minLines: 2,
                    maxLines: 4,
                    onChanged: (_) => setDialog(() {}),
                    decoration: const InputDecoration(
                      labelText: 'မေးခွန်း · ပြင်နိုင်သည်',
                    ),
                  ),
                  field(
                    'ရွေးထားသော context · မလိုတာဖယ်နိုင်သည်',
                    contextInput,
                    lines: 8,
                  ),
                  if (turns.isNotEmpty) ...[
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: useHistory,
                      onChanged: (v) => setDialog(() {
                        useHistory = v ?? false;
                        accepted = false;
                      }),
                      title: const Text(
                        'ဒီစကားဝိုင်း၏ မေး/ဖြေများကို ဆက်သုံးမယ်',
                      ),
                      subtitle: const Text(
                        'နောက်ဆုံး 4 တွဲအထိ · အောက်တွင် စစ်နိုင်သည်',
                      ),
                    ),
                    if (useHistory)
                      ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        title: const Text('ပို့မည့် အရင်မေး/ဖြေစာသား'),
                        children: [
                          for (final m in previousMessages)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: SelectableText(
                                '${m['role']}\n${m['content']}',
                              ),
                            ),
                        ],
                      ),
                  ],
                  ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    title: const Text('ပို့မည့် လက်စွဲနှင့် မူရင်းစာသား'),
                    children: [
                      for (final source in retrieveEvidence(
                        widget.state.index,
                        conversationSearchQuery(
                          question.text,
                          useHistory ? turns : [],
                        ),
                      ))
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: SelectableText(source.evidence),
                        ),
                    ],
                  ),
                  note(
                    context,
                    'သက်ဆိုင်ရာ လက်စွဲနှင့် မူရင်းစာမျက်နှာမှ စာသားကို ပို့မည်။ အရင်ရွေးခဲ့သော profile / ဖိုင်စာသားကို ပြန်မထည့်ပါ။ ယခုရွေးထားသော context နှင့် ဒီစကားဝိုင်း၏ မေး/ဖြေစာသားကို စစ်ပါ။',
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: accepted,
                    onChanged: (v) => setDialog(() => accepted = v ?? false),
                    title: const Text('ပို့မည့်စာသားကို စစ်ပြီး သဘောတူသည်'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('မပို့တော့ဘူး'),
            ),
            FilledButton(
              onPressed: !accepted
                  ? null
                  : () {
                      if (question.text.trim().isEmpty) return;
                      if (contextInput.text.length > 80000) {
                        message(
                          context,
                          'Context ရှည်လွန်းပါသည်။ လိုအပ်သည့် excerpt ကိုသာထားပါ။',
                        );
                        return;
                      }
                      Navigator.pop(context, {
                        'question': question.text.trim(),
                        'personal': contextInput.text,
                        'use_history': useHistory.toString(),
                      });
                    },
              child: const Text('Provider ထံ ပို့မယ်'),
            ),
          ],
        ),
      ),
    );
    // Controllers stay alive until the dialog exit animation has finished.
    Future<void>.delayed(const Duration(milliseconds: 400), () {
      question.dispose();
      contextInput.dispose();
    });
    return value;
  }

  Future<void> send() async {
    if (busy || input.text.trim().isEmpty) return;
    final state = widget.state;
    final query = input.text.trim();
    final sessionId = state.activeChatId;
    final turns = state.currentConversation;
    var searchQuery = conversationSearchQuery(query, turns);
    final online = state.settings['online'] == true;
    var sources = retrieveEvidence(state.index, searchQuery);
    final token = ++generation;
    setState(() => busy = true);
    try {
      if (!online) {
        final answer = sources.isEmpty
            ? 'ထည့်ထားသော offline sources ထဲတွင် တိုက်ရိုက်သက်ဆိုင်သောအချက် မတွေ့သေးပါ။ ပိုတိုသောစကားလုံးဖြင့် ရှာပါ။ လိုအပ်သည့်ရင်းမြစ်ကို official website / 1350 / 1345 ဖြင့်စစ်ပါ။'
            : 'သက်ဆိုင်သော offline လက်စွဲနှင့် မူရင်းစာသားများကို အောက်တွင်ပြထားသည်။ မူရင်းကိုရီးယားစာသားကို Online AI ဖြင့် မြန်မာလို မေးနိုင်သည်။\n\n${sources.map((s) => '${s.title}\n${s.guide?.summary ?? s.excerpt}').join('\n\n')}';
        await state.addHistory({
          'date': DateTime.now().toIso8601String(),
          'question': query,
          'session_id': sessionId,
          'retrieval_query': searchQuery,
          'answer': answer,
          'online': false,
          'source_ids': sources.map((s) => s.id).toList(),
          'questions': <String>[],
          'steps': <String>[],
        });
      } else {
        final id = state.settings['provider'] as String;
        final p = providers.firstWhere((p) => p.id == id);
        final config = state.providerSettings(id);
        final model = (config['model'] ?? '').toString();
        final key = await state.vault.keyFor(id);
        if (key.isEmpty || model.isEmpty)
          throw const AiFailure(
            'Settings ထဲတွင် provider၊ API key နဲ့ model ကို အရင်သိမ်းပါ။',
          );
        if (!mounted || token != generation) return;
        final personal = selectedContext(
          profile: state.profile,
          useProfile: state.settings['profileContext'] == true,
          documents: state.documents,
        );
        final consent = await preview(query, personal, p, model, turns);
        if (consent == null ||
            !mounted ||
            token != generation ||
            state.settings['online'] != true)
          return;
        final replay = consent['use_history'] == 'true'
            ? turns
            : <Map<String, dynamic>>[];
        searchQuery = conversationSearchQuery(consent['question']!, replay);
        sources = retrieveEvidence(state.index, searchQuery);
        service = widget.serviceFactory?.call() ?? AiService();
        final raw = await service!.chat(
          provider: p,
          base: config['base'] ?? p.baseUrl,
          key: key,
          model: model,
          system: legalSystemPrompt(sources, consent['personal']!),
          messages: [
            ...conversationMessages(replay),
            {'role': 'user', 'content': consent['question']!},
          ],
        );
        if (!mounted || token != generation) return;
        final answer = AiAnswer.parse(
          raw,
          sources.map((s) => s.id).toSet(),
          requireGrounding: true,
        );
        if (!answer.validated)
          throw const AiFailure(
            'AI အဖြေပုံစံ / အချက်နှင့်ရင်းမြစ် ချိတ်ဆက်မှုကို စစ်မရပါ။ အဖြေကို မသိမ်းရသေးပါ။ ပြန်မေးပါ သို့မဟုတ် model ပြောင်းစမ်းပါ။',
          );
        await state.addHistory({
          'date': DateTime.now().toIso8601String(),
          'question': consent['question'],
          'session_id': sessionId,
          'retrieval_query': searchQuery,
          'answer': answer.answer,
          'status': answer.status,
          'claims': answer.claims,
          'questions': answer.questions,
          'steps': answer.steps,
          'source_ids': answer.sourceIds,
          'online': true,
          'provider': p.label,
          'model': model,
          'context_snapshot': consent['personal'],
          'source_snapshot': sources.map((s) => s.evidence).toList(),
          'history_turns_sent': replay.length.clamp(0, 4),
        });
      }
      if (mounted && token == generation) input.clear();
    } catch (e) {
      if (mounted && token == generation) message(context, e.toString());
    } finally {
      if (token == generation) {
        service?.close();
        service = null;
        if (mounted) setState(() => busy = false);
      }
    }
  }

  Future<void> conversations() async {
    final groups = <String, List<Map<String, dynamic>>>{};
    for (final row in widget.state.history) {
      final id = (row['session_id'] ?? 'legacy').toString();
      groups.putIfAbsent(id, () => []).add(row);
    }
    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const ListTile(title: Text('သိမ်းထားသော စကားဝိုင်းများ')),
            if (groups.isEmpty)
              const ListTile(title: Text('စကားဝိုင်း မရှိသေးပါ')),
            for (final group in groups.entries.toList().reversed)
              ListTile(
                title: Text(
                  group.value.first['question'].toString(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  '${group.value.length} မေး/ဖြေ · ${group.value.last['date'].toString().split('T').first}',
                ),
                trailing: group.key == widget.state.activeChatId
                    ? const Icon(Icons.check)
                    : null,
                onTap: () => Navigator.pop(context, group.key),
              ),
          ],
        ),
      ),
    );
    if (selected != null && mounted) {
      input.clear();
      await widget.state.resumeConversation(selected);
    }
  }

  Future<void> clear() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chat history ရှင်းမလား?'),
        content: const Text(
          'ဖုန်းပေါ်တွင် သိမ်းထားသောအဖြေများနှင့် context snapshots ဖျက်မည်။ Provider ပေါ်ရှိ record များကို ဤနေရာမှ မဖျက်နိုင်ပါ။',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('မရှင်းတော့ဘူး'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ရှင်းမယ်'),
          ),
        ],
      ),
    );
    if (ok == true) await widget.state.clearHistory();
  }

  Widget turn(Map<String, dynamic> row) {
    final ids = List<String>.from(row['source_ids'] ?? []);
    final sources = ids
        .map(
          (id) => resolveEvidence(id, widget.state.cards, widget.state.sources),
        )
        .whereType<PublicEvidence>()
        .toList();
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              row['question'] ?? '',
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(height: 1.8),
            ),
            note(
              context,
              '${row['online'] == true ? '${row['provider']} · ${row['model']}' : 'Offline source search'} · ${row['date'].toString().split('T').first}',
            ),
            SelectableText(
              row['answer'] ?? '',
              style: const TextStyle(height: 1.9),
            ),
            for (final q in List<String>.from(row['questions'] ?? []))
              TextButton(
                onPressed: () => setQuestion('$q\nအဖြေ: '),
                child: Text(q),
              ),
            if (row['status'] == 'needs_information')
              note(
                context,
                'အခြေအနေ ထပ်မေးရန်လိုသည်။ အပေါ်က မေးခွန်းကို နှိပ်ပြီး ဖြေပါ။',
              ),
            if (row['status'] == 'insufficient_evidence')
              note(
                context,
                'ထည့်ထားသောရင်းမြစ် မလုံလောက်ပါ။ Official ရင်းမြစ်ဖြင့် ထပ်စစ်ပါ။',
              ),
            if ((row['claims'] as List? ?? []).isNotEmpty)
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: const Text('အချက်တစ်ခုချင်း၏ ရင်းမြစ်များ'),
                children: [
                  for (final claim in row['claims'] as List)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(claim['text'].toString()),
                      subtitle: Text((claim['source_ids'] as List).join(' · ')),
                    ),
                ],
              ),
            if ((row['steps'] as List? ?? []).isNotEmpty)
              sectionTitle(context, 'ဆက်လုပ်ရန်'),
            ...List<String>.from(row['steps'] ?? []).map(
              (s) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Text('• $s', style: const TextStyle(height: 1.8)),
              ),
            ),
            if (sources.isNotEmpty)
              sectionTitle(context, 'အဖြေတွင်သုံးထားသော sources'),
            ...sources.map(
              (c) => TextButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => c.guide != null
                        ? CardDetail(widget.state, c.guide!, setQuestion)
                        : SourceReader(
                            widget.state,
                            c.source!,
                            initialPage: c.page!,
                          ),
                  ),
                ),
                icon: const Icon(Icons.link, size: 18),
                label: Text(c.title),
              ),
            ),
            if (row['online'] == true && ids.isEmpty)
              note(
                context,
                'Source citation မပါသေးပါ။ ဥပဒေ / Visa ဆိုင်ရာဆုံးဖြတ်ချက်အဖြစ် မယူပါနှင့်။',
              ),
            if (row['online'] == true)
              note(
                context,
                'AI source ID စစ်ခြင်းသည် အဖြေအားလုံးမှန်ကြောင်း အာမမခံပါ။ Pending / latest rule အတွက် official source ကိုစစ်ပါ။',
              ),
            if (row['context_snapshot'] != null)
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: const Text('အသုံးပြုခဲ့သော context ကိုဖတ်ရန်'),
                children: [
                  SelectableText(
                    row['context_snapshot'].toString().isEmpty
                        ? 'ကိုယ်ရေး context မပါ'
                        : row['context_snapshot'],
                    style: const TextStyle(height: 1.7),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.state,
    builder: (context, _) => buildContent(context),
  );

  Widget buildContent(BuildContext context) {
    final state = widget.state;
    final currentTurns = state.currentConversation;
    final online = state.settings['online'] == true;
    final provider = providers.firstWhere(
      (p) => p.id == state.settings['provider'],
    );
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(18),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'ရင်းမြစ်နဲ့ မေးမယ်',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    tooltip: 'AI settings',
                    onPressed: busy
                        ? null
                        : () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SettingsScreen(state),
                            ),
                          ),
                    icon: const Icon(Icons.tune),
                  ),
                  IconButton(
                    tooltip: 'History ရှင်းရန်',
                    onPressed: busy ? null : clear,
                    icon: const Icon(Icons.delete_sweep_outlined),
                  ),
                ],
              ),
              Wrap(
                spacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: busy
                        ? null
                        : () async {
                            input.clear();
                            await state.startConversation();
                          },
                    icon: const Icon(Icons.add_comment_outlined),
                    label: const Text('အကြောင်းအရာသစ်'),
                  ),
                  TextButton.icon(
                    onPressed: busy ? null : conversations,
                    icon: const Icon(Icons.history),
                    label: const Text('အရင်စကားဝိုင်းများ'),
                  ),
                ],
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  online
                      ? 'Online AI · ${provider.label}'
                      : 'Offline · လက်စွဲရင်းမြစ်ရှာဖတ်',
                ),
                subtitle: Text(
                  online
                      ? 'Model: ${state.providerSettings(provider.id)['model'].toString().isEmpty ? 'မရွေးရသေး' : state.providerSettings(provider.id)['model']}'
                      : 'Internet / API key မလိုပါ။ AI model အဖြေအသစ် မထုတ်ပါ။',
                ),
                value: online,
                onChanged: (v) async {
                  if (!v) cancel();
                  await state.setSetting('online', v);
                },
              ),
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: const Text('ကိုယ်ရေး context ရွေးရန်'),
                children: [
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value:
                        state.settings['profileContext'] == true &&
                        state.profile['confirmed'] == true,
                    onChanged: busy || state.profile['confirmed'] != true
                        ? null
                        : (v) => state.setSetting('profileContext', v ?? false),
                    title: const Text('စစ်ပြီး profile ကိုသုံးမယ်'),
                    subtitle: Text(
                      state.profile['confirmed'] == true
                          ? 'ဖုန်းပေါ်သိမ်းထားသော လက်ရှိ profile'
                          : 'ကိုယ့်ဖိုင် tab တွင် profile ကို အရင်အတည်ပြုပါ။',
                    ),
                  ),
                  ...state.documents.map(
                    (d) => CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: d.selected && d.confirmed,
                      onChanged: busy || !d.confirmed
                          ? null
                          : (v) => state.putDocument(
                              d.copyWith(selected: v ?? false),
                            ),
                      title: Text(d.name),
                      subtitle: Text(
                        d.confirmed ? 'စစ်ပြီးစာသား' : 'မူရင်းနှင့်စစ်ရန်လို',
                      ),
                    ),
                  ),
                  note(
                    context,
                    'ရွေးထားသည့်စာသားကိုသာ preview တွင်ပြမည်။ Send တစ်ကြိမ်စီတွင် ပြန်စစ်ပါ။ စာသားအတိုဆုံး relevant excerpt သာပို့ပါ။',
                  ),
                ],
              ),
              if (currentTurns.isEmpty) ...[
                const SizedBox(height: 14),
                note(
                  context,
                  'ဒီစကားဝိုင်းသစ်တွင် အရင်အမှုကို မသုံးပါ။ ဥပမာ: “သူဌေးက ပိုက်ဆံမရှင်းပေးဘူး”၊ “E9 နဲ့ လစာမရလို့ အလုပ်ပြောင်းချင်တယ်”။ ဆက်မေးလျှင် ဒီစကားဝိုင်းထဲမှ အကြောင်းအရာကို ဆက်သုံးမည်။',
                ),
              ],
              ...currentTurns.reversed.take(30).map(turn),
              if (currentTurns.length > 30)
                note(
                  context,
                  'လတ်တလော အဖြေ 30 ခု ပြထားသည်။ History အများဆုံး 100 ခုကို encrypted သိမ်းထားပြီး Settings မှ export လုပ်နိုင်သည်။',
                ),
            ],
          ),
        ),
        if (busy) const LinearProgressIndicator(),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 12, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: input,
                    minLines: 1,
                    maxLines: 5,
                    enabled: !busy,
                    decoration: const InputDecoration(
                      hintText: 'ကိုယ့်အခြေအနေကို မေးပါ…',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                IconButton.filled(
                  tooltip: busy ? 'ရပ်မယ်' : 'မေးမယ်',
                  onPressed: busy ? cancel : send,
                  icon: Icon(busy ? Icons.stop : Icons.arrow_upward),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
