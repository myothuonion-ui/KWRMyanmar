import 'models.dart';

class SourceDocument {
  final String id,
      title,
      korean,
      category,
      publisher,
      url,
      asset,
      edition,
      downloaded;
  final List<String> pages;
  const SourceDocument({
    required this.id,
    required this.title,
    required this.korean,
    required this.category,
    required this.publisher,
    required this.url,
    required this.asset,
    required this.edition,
    required this.downloaded,
    required this.pages,
  });
  factory SourceDocument.fromJson(Map<String, dynamic> j) => SourceDocument(
    id: j['id'],
    title: j['title'],
    korean: j['korean'],
    category: j['category'],
    publisher: j['publisher'],
    url: j['url'],
    asset: j['asset'],
    edition: j['edition'],
    downloaded: j['downloaded'],
    pages: List<String>.from(j['pages']),
  );
}

class SearchHit {
  final LegalCard? guide;
  final SourceDocument? source;
  final int? page;
  final String excerpt;
  final double score;
  const SearchHit({
    this.guide,
    this.source,
    this.page,
    required this.excerpt,
    required this.score,
  });
  String get title => guide?.title ?? source!.title;
}

// These are retrieval aliases, never facts or eligibility rules.
const searchAliases = [
  [
    'လစာမပေး',
    'လစာမရ',
    'လစာကျန်',
    'လစာနောက်ကျ',
    'လုပ်ခမပေး',
    'လုပ်ခကျန်',
    '임금체불',
    '체불임금',
    'unpaid wages',
  ],
  ['အလုပ်ထုတ်', 'ထုတ်ခံရ', 'အလုပ်ဖြုတ်', '해고', 'dismissal', 'fired'],
  ['အလုပ်ထွက်', 'အလုပ်ကထွက်', '퇴직', '사직', 'resign'],
  ['အလုပ်ပြောင်း', '사업장 변경', '근무처 변경', 'workplace change'],
  ['အချိန်ပို', '연장근로', '초과근로', 'overtime'],
  ['ညဆိုင်း', 'ညအလုပ်', 'ညကြေး', '야간근로', 'night shift'],
  ['ပိတ်ရက်', '휴일', 'holiday'],
  ['ခွင့်ရက်', 'နှစ်ပတ်လည်ခွင့်', '연차', '유급휴가', 'annual leave'],
  ['နားချိန်', '휴게', 'break'],
  ['အနည်းဆုံးလစာ', '최저임금', 'minimum wage'],
  [
    'အလုပ်ဒဏ်ရာ',
    'အလုပ်မှာဒဏ်ရာ',
    'စက်ထိ',
    'လုပ်ငန်းခွင်ဒဏ်ရာ',
    '산재',
    '산업재해',
    'work injury',
  ],
  [
    'ကျန်းမာရေးအာမခံ',
    'ဆေးကုသ',
    'ဆေးခန်း',
    'ဆေးရုံ',
    '건강보험',
    '병원',
    'health insurance',
  ],
  ['ပင်စင်', '국민연금', 'pension'],
  ['အလုပ်လက်မဲ့', '실업급여', '고용보험', 'unemployment'],
  ['နေရပ်ပြန်စရိတ်', 'ပြန်ခရီးစရိတ်', '귀국비용보험', 'return cost'],
  ['ထွက်ခွာအာမခံ', '출국만기보험', 'departure guarantee'],
  ['မပေးသောလစာအာမခံ', '임금체불보증보험', 'wage guarantee'],
  ['ထိခိုက်မှုအာမခံ', '상해보험', 'accident insurance'],
  ['ရေရှည်စောင့်ရှောက်', '장기요양', 'long term care'],
  ['အာမခံ', '보험', 'insurance'],
  ['အလုပ်ထွက်ငွေ', 'လုပ်သက်ငွေ', '퇴직금', '퇴직급여', 'severance'],
  ['စာချုပ်', '근로계약', 'contract'],
  ['လစာစာရွက်', '임금명세서', '급여명세서', 'payslip'],
  ['အဆောင်', '기숙사', 'dormitory'],
  ['အိမ်ငှား', 'အိမ်လခ', '월세', '임대차', 'rent'],
  ['အာမခံငွေ', 'စပေါ်ငွေ', '보증금', 'deposit'],
  ['လိပ်စာပြောင်း', '체류지 변경', '주소', 'address change'],
  ['နေထိုင်ခွင့်ကတ်', '외국인등록', 'residence card', 'arc'],
  ['ဗီဇာ', 'visa', '체류자격', 'e9', 'e-9', 'e7', 'e-7'],
  ['အခွန်', '세금', '연말정산', 'tax'],
  ['နှိပ်စက်', 'အနိုင်ကျင့်', '괴롭힘', 'harassment'],
  ['လိင်ပိုင်း', '성희롱', 'sexual harassment'],
  ['သားဖွား', 'ကိုယ်ဝန်', '출산', '임신', 'maternity'],
  ['မိဘခွင့်', '육아휴직', 'parental leave'],
  ['ပြန်နိုင်ငံ', 'နေရပ်ပြန်', '귀국', '출국', 'departure'],
  ['ဘဏ်', '은행', 'bank'],
  ['ငွေလွှဲ', '송금', 'remittance'],
  ['အရေးပေါ်', '긴급', 'emergency'],
];

String foldSearch(String text) {
  var value = text
      .toLowerCase()
      .replaceAll(RegExp(r'[\u200b\u200c\u200d\ufeff]'), '')
      .replaceAll(RegExp(r'[\s\-–—.,!?၊။]'), '');
  const digits = '၀၁၂၃၄၅၆၇၈၉';
  for (var i = 0; i < digits.length; i++) {
    value = value.replaceAll(digits[i], '$i');
  }
  return value;
}

String searchExcerpt(String text, List<String> terms) {
  final lines = text.split(RegExp(r'\n+|။'));
  for (final line in lines) {
    if (line.trim().length > 16 &&
        terms.any((t) => foldSearch(line).contains(t))) {
      final clean = line.trim();
      return clean.length > 240 ? '${clean.substring(0, 240)}…' : clean;
    }
  }
  final clean = text.replaceAll(RegExp(r'\s+'), ' ').trim();
  return clean.length > 240 ? '${clean.substring(0, 240)}…' : clean;
}

class HandbookIndex {
  final List<LegalCard> guides;
  final List<SourceDocument> sources;
  late final List<
    ({
      LegalCard? guide,
      SourceDocument? source,
      int? page,
      String title,
      String body,
      String original,
    })
  >
  records;
  HandbookIndex(this.guides, this.sources) {
    records = [
      for (final g in guides)
        (
          guide: g,
          source: null,
          page: null,
          title: foldSearch('${g.title} ${g.tags.join(' ')}'),
          body: foldSearch(g.searchText),
          original:
              '${g.summary}\n${g.body}\n${g.sections.map((s) => s.text).join('\n')}',
        ),
      for (final s in sources)
        for (var i = 0; i < s.pages.length; i++)
          (
            guide: null,
            source: s,
            page: i + 1,
            title: i == 0 ? foldSearch('${s.title} ${s.korean}') : '',
            body: foldSearch(s.pages[i]),
            original: s.pages[i],
          ),
    ];
  }
  List<SearchHit> search(
    String query, {
    String kind = 'all',
    String? category,
    int limit = 60,
  }) {
    final q = foldSearch(query);
    if (q.isEmpty) return [];
    final direct = <String>{
      q,
      ...query.split(RegExp(r'\s+')).map(foldSearch).where((t) => t.length > 2),
    };
    final expanded = <String>{};
    for (final group in searchAliases) {
      if (group.any((t) => q.contains(foldSearch(t)))) {
        expanded.addAll(group.map(foldSearch));
      }
    }
    final terms = {...direct, ...expanded}.toList();
    final hits = <SearchHit>[];
    for (final r in records) {
      if (kind == 'guides' && r.guide == null ||
          kind == 'sources' && r.source == null)
        continue;
      if (category != null &&
          (r.guide?.category ?? r.source?.category) != category)
        continue;
      var score = 0.0;
      if (r.title.contains(q)) score += 150;
      if (r.body.contains(q)) score += 25;
      for (final t in terms) {
        if (r.title.contains(t)) score += direct.contains(t) ? 25 : 8;
        if (r.body.contains(t)) score += direct.contains(t) ? 4 : 1.5;
      }
      // For an unmatched spelling, overlap over Unicode code points tolerates
      // short typos without requiring Burmese words to contain spaces.
      if (score == 0 && q.runes.length >= 5 && r.guide != null) {
        final a = q.runes.toList();
        final b = r.title.runes.toList();
        final grams = <String>{
          for (var i = 0; i + 3 <= a.length; i++)
            String.fromCharCodes(a.sublist(i, i + 3)),
        };
        final titleGrams = <String>{
          for (var i = 0; i + 3 <= b.length; i++)
            String.fromCharCodes(b.sublist(i, i + 3)),
        };
        final overlap = grams.intersection(titleGrams).length / grams.length;
        if (overlap >= .65) score = overlap * 4;
      }
      if (score > 0)
        hits.add(
          SearchHit(
            guide: r.guide,
            source: r.source,
            page: r.page,
            excerpt: searchExcerpt(r.original, terms),
            score: score,
          ),
        );
    }
    hits.sort((a, b) => b.score.compareTo(a.score));
    return hits.take(limit).toList();
  }
}
