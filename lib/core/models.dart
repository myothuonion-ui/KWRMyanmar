import 'dart:convert';

class GuideSection {
  final String title, text;
  const GuideSection(this.title, this.text);
  factory GuideSection.fromJson(Map<String, dynamic> j) =>
      GuideSection(j['title'], j['text']);
}

class GuideReference {
  final String sourceId, label;
  final int page;
  const GuideReference(this.sourceId, this.page, this.label);
  factory GuideReference.fromJson(Map<String, dynamic> j) =>
      GuideReference(j['source_id'], j['page'], j['label']);
}

class GuideProcedure {
  final List<String> questions, documents;
  final List<Map<String, String>> phrases, offices;
  const GuideProcedure({
    this.questions = const [],
    this.documents = const [],
    this.phrases = const [],
    this.offices = const [],
  });
  factory GuideProcedure.fromJson(Map<String, dynamic> j) => GuideProcedure(
    questions: List<String>.from(j['questions'] ?? []),
    documents: List<String>.from(j['documents'] ?? []),
    phrases: (j['phrases'] as List? ?? [])
        .map((p) => Map<String, String>.from(p))
        .toList(),
    offices: (j['offices'] as List? ?? [])
        .map((p) => Map<String, String>.from(p))
        .toList(),
  );
  String get text => [
    ...questions,
    ...documents,
    ...phrases.map((p) => '${p['ko']} — ${p['mm']}'),
    ...offices.map((o) => '${o['name']} — ${o['action']}'),
  ].join('\n');
}

class LegalCard {
  final String id, title, category, summary, body, source, url, checked;
  final List<String> tags, steps;
  final bool pending;
  final List<GuideSection> sections;
  final List<String> sourceIds;
  final List<String> questionAliases;
  final List<GuideReference> sourceRefs;
  final GuideProcedure procedure;
  const LegalCard({
    required this.id,
    required this.title,
    required this.category,
    required this.summary,
    required this.body,
    required this.source,
    required this.url,
    required this.checked,
    required this.tags,
    required this.steps,
    this.pending = false,
    this.sections = const [],
    this.sourceIds = const [],
    this.questionAliases = const [],
    this.sourceRefs = const [],
    this.procedure = const GuideProcedure(),
  });
  factory LegalCard.fromJson(Map<String, dynamic> j) => LegalCard(
    id: j['id'],
    title: j['title'],
    category: j['category'],
    summary: j['summary'],
    body: j['body'],
    source: j['source'],
    url: j['url'],
    checked: j['checked'],
    tags: List<String>.from(j['tags']),
    steps: List<String>.from(j['steps']),
    pending: j['pending'] == true,
    sections: (j['sections'] as List? ?? [])
        .map((s) => GuideSection.fromJson(Map<String, dynamic>.from(s)))
        .toList(),
    sourceIds: List<String>.from(j['source_ids'] ?? []),
    questionAliases: List<String>.from(j['question_aliases'] ?? []),
    sourceRefs: (j['source_refs'] as List? ?? [])
        .map((r) => GuideReference.fromJson(Map<String, dynamic>.from(r)))
        .toList(),
    procedure: GuideProcedure.fromJson(
      Map<String, dynamic>.from(j['procedure'] ?? {}),
    ),
  );
  String get searchText =>
      '$title\n$summary\n$body\n${tags.join(' ')}\n${questionAliases.join(' ')}\n${steps.join('\n')}\n${sections.map((s) => '${s.title}\n${s.text}').join('\n')}\n${procedure.text}';
  String get evidence =>
      '[$id] $title\n$summary\n$body\n'
      '${sections.map((s) => '${s.title}\n${s.text}').join('\n')}\nSource: $source; $url; checked $checked; pending=$pending';
}

class PersonalDocument {
  final String id, name, kind, text, created;
  final bool confirmed, selected;
  const PersonalDocument({
    required this.id,
    required this.name,
    required this.kind,
    required this.text,
    required this.created,
    this.confirmed = false,
    this.selected = false,
  });
  factory PersonalDocument.fromJson(Map<String, dynamic> j) => PersonalDocument(
    id: j['id'],
    name: j['name'],
    kind: j['kind'],
    text: j['text'],
    created: j['created'],
    confirmed: j['confirmed'] == true,
    selected: j['selected'] == true,
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'kind': kind,
    'text': text,
    'created': created,
    'confirmed': confirmed,
    'selected': selected,
  };
  PersonalDocument copyWith({String? text, bool? confirmed, bool? selected}) =>
      PersonalDocument(
        id: id,
        name: name,
        kind: kind,
        text: text ?? this.text,
        created: created,
        confirmed: confirmed ?? this.confirmed,
        selected: selected ?? this.selected,
      );
}

class ProviderConfig {
  final String id, label, baseUrl, protocol;
  const ProviderConfig(this.id, this.label, this.baseUrl, this.protocol);
}

const providers = [
  ProviderConfig(
    'gemini',
    'Gemini',
    'https://generativelanguage.googleapis.com/v1beta',
    'gemini',
  ),
  ProviderConfig(
    'openai',
    'ChatGPT / OpenAI',
    'https://api.openai.com/v1',
    'responses',
  ),
  ProviderConfig('claude', 'Claude', 'https://api.anthropic.com/v1', 'claude'),
  ProviderConfig(
    'nvidia',
    'NVIDIA NIM',
    'https://integrate.api.nvidia.com/v1',
    'chat',
  ),
  ProviderConfig('deepseek', 'DeepSeek', 'https://api.deepseek.com', 'chat'),
  ProviderConfig('custom', 'Other · OpenAI compatible', '', 'chat'),
];

class AiAnswer {
  final String answer;
  final List<String> questions, steps, sourceIds;
  final bool validated;
  final String status;
  final List<Map<String, dynamic>> claims;
  const AiAnswer(
    this.answer,
    this.questions,
    this.steps,
    this.sourceIds,
    this.validated, {
    this.status = 'supported',
    this.claims = const [],
  });
  factory AiAnswer.parse(
    String response,
    Set<String> allowedSources, {
    bool requireGrounding = false,
  }) {
    var clean = response.trim();
    clean = clean
        .replaceFirst(RegExp(r'^```(?:json)?\s*'), '')
        .replaceFirst(RegExp(r'\s*```$'), '');
    try {
      final j = jsonDecode(clean) as Map<String, dynamic>;
      final ids = List<String>.from(j['source_ids'] ?? []);
      final status =
          (j['status'] ?? (ids.isEmpty ? 'insufficient_evidence' : 'supported'))
              .toString();
      final claims = (j['claims'] as List? ?? [])
          .map((c) => Map<String, dynamic>.from(c))
          .toList();
      final grounded =
          [
            'supported',
            'needs_information',
            'insufficient_evidence',
          ].contains(status) &&
          j['status'] is String &&
          j['claims'] is List &&
          claims.length <= 12 &&
          claims.every(
            (c) =>
                c['text'] is String &&
                (c['text'] as String).trim().isNotEmpty &&
                c['source_ids'] is List &&
                (c['source_ids'] as List).isNotEmpty &&
                (c['source_ids'] as List).every(
                  (id) =>
                      id is String &&
                      ids.contains(id) &&
                      allowedSources.contains(id),
                ),
          ) &&
          (status != 'supported' || (ids.isNotEmpty && claims.isNotEmpty)) &&
          (status != 'needs_information' ||
              (j['questions'] as List? ?? []).isNotEmpty);
      final valid =
          j['source_ids'] is List &&
          ids.every(allowedSources.contains) &&
          j['answer'] is String &&
          (j['answer'] as String).trim().isNotEmpty &&
          j['questions'] is List &&
          j['steps'] is List &&
          (!requireGrounding || grounded);
      return AiAnswer(
        j['answer']?.toString() ?? '',
        List<String>.from(j['questions'] ?? []),
        List<String>.from(j['steps'] ?? []),
        ids.where(allowedSources.contains).toList(),
        valid,
        status: status,
        claims: claims,
      );
    } catch (_) {
      return AiAnswer(response, const [], const [], const [], false);
    }
  }
}
