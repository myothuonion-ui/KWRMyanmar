import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

import '../core/app_state.dart';
import '../core/handbook.dart';
import 'widgets.dart';

class SourceReader extends StatefulWidget {
  final AppState state;
  final SourceDocument source;
  final int initialPage;
  const SourceReader(
    this.state,
    this.source, {
    this.initialPage = 1,
    super.key,
  });
  @override
  State<SourceReader> createState() => _SourceReaderState();
}

class _SourceReaderState extends State<SourceReader> {
  late int page;
  bool pdf = false;
  final pdfController = PdfViewerController();
  @override
  void initState() {
    super.initState();
    page = widget.initialPage.clamp(1, widget.source.pages.length);
  }

  void change(int value) {
    final target = value.clamp(1, widget.source.pages.length);
    setState(() => page = target);
    if (pdf && pdfController.isReady)
      pdfController.goToPage(pageNumber: target);
  }

  Future<void> jump() async {
    final value = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .65,
          child: ListView.builder(
            itemCount: widget.source.pages.length,
            itemBuilder: (context, i) => ListTile(
              title: Text('စာမျက်နှာ ${i + 1}'),
              subtitle: Text(
                widget.source.pages[i].replaceAll(RegExp(r'\s+'), ' '),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              selected: page == i + 1,
              onTap: () => Navigator.pop(context, i + 1),
            ),
          ),
        ),
      ),
    );
    if (value != null && mounted) change(value);
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.source;
    final bookmark = 'src:${s.id}:$page';
    final scale = (widget.state.settings['readerScale'] as num? ?? 1)
        .toDouble();
    return ListenableBuilder(
      listenable: widget.state,
      builder: (context, _) => Scaffold(
        appBar: AppBar(
          title: const Text('မူရင်းရင်းမြစ်'),
          actions: [
            IconButton(
              tooltip: 'စာမျက်နှာသိမ်းရန်',
              onPressed: () => widget.state.toggleBookmark(bookmark),
              icon: Icon(
                widget.state.bookmarks.contains(bookmark)
                    ? Icons.bookmark
                    : Icons.bookmark_border,
              ),
            ),
            IconButton(
              tooltip: 'တရားဝင်ဝက်ဘ်ဆိုက်',
              onPressed: () => openSource(context, s.url),
              icon: const Icon(Icons.open_in_new),
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.title, style: Theme.of(context).textTheme.titleMedium),
                  Text(
                    '${s.korean}\n${s.publisher}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      const StatusPill('OFFLINE', Icons.offline_pin_outlined),
                      StatusPill(
                        'မူရင်း ${s.edition}',
                        Icons.calendar_today_outlined,
                      ),
                      if (s.asset.isNotEmpty)
                        ChoiceChip(
                          label: const Text('မူရင်း PDF'),
                          selected: pdf,
                          onSelected: (v) => setState(() => pdf = v),
                        ),
                      ChoiceChip(
                        label: const Text('ဖတ်ရန် စာသား'),
                        selected: !pdf,
                        onSelected: (_) => setState(() => pdf = false),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: pdf
                  ? PdfViewer.asset(
                      s.asset,
                      initialPageNumber: page,
                      controller: pdfController,
                      params: PdfViewerParams(
                        maxImageBytesCachedOnMemory: 32 * 1024 * 1024,
                        onPageChanged: (value) {
                          if (value != null && value != page)
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted) setState(() => page = value);
                            });
                        },
                      ),
                    )
                  : SingleChildScrollView(
                      key: ValueKey('${s.id}:text:$page'),
                      padding: const EdgeInsets.all(22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          note(
                            context,
                            'ကိုရီးယားမူရင်း · စာမျက်နှာ $page / ${s.pages.length}\nစာသားထုတ်ယူမှုကြောင့် ဇယားနေရာလွဲနိုင်သည်။ ဇယားနှင့် အပြည့်အစုံပုံစံကို PDF တွင်စစ်ပါ။',
                          ),
                          SelectableText(
                            s.pages[page - 1],
                            style: TextStyle(fontSize: 16 * scale, height: 1.9),
                          ),
                        ],
                      ),
                    ),
            ),
            const Divider(height: 1),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'အရင်စာမျက်နှာ',
                      onPressed: page > 1 ? () => change(page - 1) : null,
                      icon: const Icon(Icons.chevron_left),
                    ),
                    Expanded(
                      child: TextButton(
                        onPressed: jump,
                        child: Text('စာမျက်နှာ $page / ${s.pages.length}'),
                      ),
                    ),
                    IconButton(
                      tooltip: 'နောက်စာမျက်နှာ',
                      onPressed: page < s.pages.length
                          ? () => change(page + 1)
                          : null,
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
