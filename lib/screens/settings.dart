import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../core/ai_service.dart';
import '../core/app_state.dart';
import '../core/models.dart';
import 'widgets.dart';

class SettingsScreen extends StatefulWidget {
  final AppState state;
  const SettingsScreen(this.state, {super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final keyInput = TextEditingController(),
      model = TextEditingController(),
      base = TextEditingController();
  late String providerId;
  List<String> models = [];
  bool busy = false, hidden = true;
  AiService? service;
  ProviderConfig get provider =>
      providers.firstWhere((p) => p.id == providerId);
  @override
  void initState() {
    super.initState();
    providerId = widget.state.settings['provider'];
    load(providerId);
  }

  Future<void> load(String id) async {
    setState(() => busy = true);
    try {
      final stored = widget.state.providerSettings(id);
      final key = await widget.state.vault.keyFor(id);
      if (!mounted) return;
      setState(() {
        providerId = id;
        keyInput.text = key;
        model.text = stored['model'] ?? '';
        models = List<String>.from(stored['models'] ?? []);
        base.text =
            stored['base'] ?? providers.firstWhere((p) => p.id == id).baseUrl;
      });
    } catch (e) {
      if (mounted) message(context, e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> save() async {
    if (providerId == 'custom') {
      final validator = AiService();
      try {
        validator.endpoint(base.text.trim(), 'models');
      } finally {
        validator.close();
      }
    }
    await widget.state.vault.setKey(providerId, keyInput.text.trim());
    await widget.state.setProvider(providerId, {
      'model': model.text.trim(),
      'models': models,
      'base': base.text.trim(),
    });
    await widget.state.setSetting('provider', providerId);
  }

  Future<void> refresh() async {
    setState(() => busy = true);
    service = AiService();
    try {
      final found = await service!.listModels(
        provider,
        base.text.trim(),
        keyInput.text.trim(),
      );
      if (!mounted) return;
      setState(() => models = found);
      await save();
      if (mounted)
        message(
          context,
          '${found.length} models ရပါပြီ။ Chat အတွက် model ကို ရွေးပါ။',
        );
    } catch (e) {
      if (mounted) message(context, e.toString());
    } finally {
      service?.close();
      service = null;
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> chooseModel() async {
    final search = TextEditingController();
    final chosen = await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialog) => AlertDialog(
          title: const Text('API ကရရှိသော models'),
          content: SizedBox(
            width: 500,
            height: 360,
            child: Column(
              children: [
                TextField(
                  controller: search,
                  onChanged: (_) => setDialog(() {}),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Model ID ရှာရန်',
                  ),
                ),
                Expanded(
                  child: ListView(
                    children: models
                        .where(
                          (m) => m.toLowerCase().contains(
                            search.text.toLowerCase(),
                          ),
                        )
                        .map(
                          (m) => ListTile(
                            title: Text(m),
                            onTap: () => Navigator.pop(context, m),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ပိတ်မယ်'),
            ),
          ],
        ),
      ),
    );
    Future<void>.delayed(const Duration(milliseconds: 400), search.dispose);
    if (chosen != null && mounted) setState(() => model.text = chosen);
  }

  Future<void> export() async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ဒေတာ export'),
        content: const Text(
          'Profile၊ စစ်ပြီးစာသား၊ chat history နဲ့ event များကို ဖတ်လို့ရသော JSON ဖိုင်အဖြစ် သိမ်းမည်။ မူရင်း PDF/ပုံနှင့် API key မပါပါ။ ဖိုင်ကို ကိုယ်တိုင်လုံခြုံစွာထားပါ။',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('မလုပ်တော့ဘူး'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Export မယ်'),
          ),
        ],
      ),
    );
    if (accepted != true) return;
    try {
      final data = {
        'version': 1,
        'exported': DateTime.now().toIso8601String(),
        'profile': widget.state.profile,
        'documents': widget.state.documents.map((d) => d.toJson()).toList(),
        'history': widget.state.history,
        'events': widget.state.events,
        'bookmarks': widget.state.bookmarks,
      };
      final uri = await FilePicker.saveFile(
        fileName: 'KWRMyanmar-data.json',
        bytes: Uint8List.fromList(
          utf8.encode(const JsonEncoder.withIndent('  ').convert(data)),
        ),
      );
      if (uri != null && mounted) message(context, 'Export ဖိုင်သိမ်းပြီးပြီ။');
    } catch (e) {
      if (mounted) message(context, e.toString());
    }
  }

  Future<void> erase() async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ဒေတာအားလုံး ဖျက်မလား?'),
        content: const Text(
          'ဤဖုန်းပေါ်ရှိ profile၊ တင်ထားသောစာရွက်၊ chat history၊ bookmarks နဲ့ API keys အားလုံးဖျက်မည်။ ပြန်ယူ၍မရပါ။',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('မဖျက်တော့ဘူး'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('အားလုံးဖျက်မယ်'),
          ),
        ],
      ),
    );
    if (accepted != true) return;
    await widget.state.reset();
    if (mounted) {
      await load('gemini');
      if (mounted) message(context, 'ကိုယ်ရေးဒေတာဖျက်ပြီးပြီ။');
    }
  }

  @override
  void dispose() {
    service?.close();
    keyInput.dispose();
    model.dispose();
    base.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('AI နှင့် Settings')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        note(
          context,
          'API key ကို provider ဆီ request ပို့ရန်သာ သုံးသည်။ ဖုန်း၏ secure storage တွင် သိမ်းသည်။ Provider ၏ usage charges / quota သက်ဆိုင်သည်။',
        ),
        DropdownButtonFormField<String>(
          value: providerId,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'AI provider',
            border: OutlineInputBorder(),
          ),
          items: providers
              .map((p) => DropdownMenuItem(value: p.id, child: Text(p.label)))
              .toList(),
          onChanged: busy ? null : (id) => load(id!),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: keyInput,
          obscureText: hidden,
          decoration: InputDecoration(
            labelText: 'API key',
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              onPressed: () => setState(() => hidden = !hidden),
              icon: Icon(
                hidden
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
            ),
          ),
        ),
        if (providerId == 'custom')
          field('HTTPS base URL · ဥပမာ https://host/v1', base),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: busy ? null : refresh,
          icon: busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.refresh),
          label: const Text('Online · API မှ model စာရင်းယူမယ်'),
        ),
        if (models.isNotEmpty)
          TextButton(
            onPressed: busy ? null : chooseModel,
            child: Text('Model စာရင်း ${models.length} ခုထဲမှ ရွေးမယ်'),
          ),
        field('Model ID · ရွေးနိုင် / ကိုယ်တိုင်ထည့်နိုင်', model),
        note(
          context,
          'Model စာရင်းတွင် chat မပံ့ပိုးသော model များလည်း ရှိနိုင်သည်။ ကိုယ့် API account တွင် အသုံးပြုခွင့်ရှိသော chat model ကိုရွေးပါ။',
        ),
        FilledButton.icon(
          onPressed: busy
              ? null
              : () async {
                  setState(() => busy = true);
                  try {
                    await save();
                    if (context.mounted)
                      message(context, 'Provider / key / model သိမ်းပြီးပြီ။');
                  } catch (e) {
                    if (context.mounted) message(context, e.toString());
                  } finally {
                    if (mounted) setState(() => busy = false);
                  }
                },
          icon: const Icon(Icons.save_outlined),
          label: const Text('ရွေးချယ်မှုကို သိမ်းမယ်'),
        ),
        const Divider(height: 32),
        sectionTitle(context, 'ကိုယ်ရေးဒေတာ'),
        note(
          context,
          'Profile၊ စာရွက်နဲ့ chat history ကို ဖုန်းပေါ်တွင် AES-GCM ဖြင့် encrypt လုပ်ထားသည်။ Online chat အတွက် ကိုယ်တိုင်ရွေးထားသော context ကို send preview မှ စစ်နိုင်သည်။ App data ဖျက်ခြင်း / uninstall လုပ်ခြင်းကြောင့် local records ပျောက်နိုင်သည်။',
        ),
        OutlinedButton.icon(
          onPressed: busy ? null : export,
          icon: const Icon(Icons.download_outlined),
          label: const Text('Profile / စာသား / history export'),
        ),
        TextButton.icon(
          onPressed: busy ? null : erase,
          icon: const Icon(Icons.delete_outline),
          label: const Text('ဒေတာနှင့် API keys အားလုံးဖျက်ရန်'),
        ),
        const Divider(height: 28),
        note(
          context,
          'KWR Myanmar 0.2.0 Preview · Android 6+\nလက်စွဲ၊ မူရင်း PDF၊ စာရွက်ဖတ်ခြင်း၊ လစာနှင့် milestone တွက်ခြင်းတို့ offline သုံးနိုင်သည်။ AI model အဖြေအသစ်အတွက် internet နှင့် API key လိုသည်။\nContent pack: 2026-10-09 · ဥပဒေပညာရှင်စစ်ပြီးသော service မဟုတ်ပါ။ D-2 / D-4 အတိအကျပြောင်းနိုင်မှုကို 1345 ဖြင့် စစ်ပါ။',
        ),
        TextButton(
          onPressed: () => openSource(
            context,
            'https://github.com/myothuonion-ui/KWRMyanmar',
          ),
          child: const Text('Source code / releases'),
        ),
      ],
    ),
  );
}
