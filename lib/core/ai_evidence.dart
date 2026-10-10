import 'handbook.dart';
import 'models.dart';

/// A citation points to either a guide or one exact bundled original page.
class PublicEvidence {
  final String id, title, text, excerpt;
  final LegalCard? guide;
  final SourceDocument? source;
  final int? page;
  const PublicEvidence({
    required this.id,
    required this.title,
    required this.text,
    required this.excerpt,
    this.guide,
    this.source,
    this.page,
  });

  factory PublicEvidence.fromHit(SearchHit hit) {
    final guide = hit.guide;
    if (guide != null) {
      return PublicEvidence(
        id: guide.id,
        title: guide.title,
        guide: guide,
        excerpt: hit.excerpt,
        text:
            'Myanmar guide; source: ${guide.source}; ${guide.url}; '
            'checked: ${guide.checked}; pending=${guide.pending}\n'
            '${_passage(guide.searchText, hit.excerpt)}',
      );
    }
    final source = hit.source!;
    final page = hit.page!;
    return PublicEvidence(
      id: 'src:${source.id}:$page',
      title: '${source.title} · စာမျက်နှာ $page',
      source: source,
      page: page,
      excerpt: hit.excerpt,
      text:
          'Original source: ${source.korean}; publisher: ${source.publisher}; '
          'edition: ${source.edition}; page: $page; ${source.url}\n'
          '${_passage(source.pages[page - 1], hit.excerpt)}',
    );
  }

  String get evidence => '[$id] $title\n$text';

  static String _passage(String original, String excerpt) {
    const maxLength = 6000;
    if (original.length <= maxLength) return original;
    final anchor = excerpt.endsWith('…')
        ? excerpt.substring(0, excerpt.length - 1)
        : excerpt;
    final offset = original.indexOf(anchor);
    final start = (offset - 1500).clamp(0, original.length - maxLength);
    return '(Excerpt; surrounding text omitted)\n'
        '${original.substring(start, start + maxLength)}';
  }
}

List<PublicEvidence> retrieveEvidence(HandbookIndex index, String query) => [
  ...index.search(query, kind: 'guides', limit: 4),
  ...index.search(query, kind: 'sources', limit: 3),
].map(PublicEvidence.fromHit).toList();

PublicEvidence? resolveEvidence(
  String id,
  List<LegalCard> guides,
  List<SourceDocument> sources,
) {
  for (final guide in guides) {
    if (guide.id == id) {
      return PublicEvidence.fromHit(
        SearchHit(guide: guide, excerpt: guide.summary, score: 0),
      );
    }
  }
  final match = RegExp(r'^src:([^:]+):(\d+)$').firstMatch(id);
  if (match == null) return null;
  final page = int.tryParse(match.group(2)!);
  for (final source in sources) {
    if (source.id == match.group(1) &&
        page != null &&
        page >= 1 &&
        page <= source.pages.length) {
      return PublicEvidence.fromHit(
        SearchHit(source: source, page: page, excerpt: '', score: 0),
      );
    }
  }
  return null;
}
