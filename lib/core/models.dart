import 'dart:convert';

class LegalCard {
  final String id, title, category, summary, body, source, url, checked;
  final List<String> tags, steps;
  final bool pending;
  const LegalCard({required this.id, required this.title, required this.category,
    required this.summary, required this.body, required this.source,
    required this.url, required this.checked, required this.tags,
    required this.steps, this.pending = false});
  factory LegalCard.fromJson(Map<String, dynamic> j) => LegalCard(
    id: j['id'], title: j['title'], category: j['category'], summary: j['summary'],
    body: j['body'], source: j['source'], url: j['url'], checked: j['checked'],
    tags: List<String>.from(j['tags']), steps: List<String>.from(j['steps']),
    pending: j['pending'] == true);
  String get evidence => '[$id] $title\n$summary\n$body\n'
      'Source: $source; $url; checked $checked; pending=$pending';
}

class PersonalDocument {
  final String id, name, kind, text, created;
  final bool confirmed, selected;
  const PersonalDocument({required this.id, required this.name, required this.kind,
    required this.text, required this.created, this.confirmed = false,
    this.selected = false});
  factory PersonalDocument.fromJson(Map<String, dynamic> j) => PersonalDocument(
    id: j['id'], name: j['name'], kind: j['kind'], text: j['text'],
    created: j['created'], confirmed: j['confirmed'] == true,
    selected: j['selected'] == true);
  Map<String, dynamic> toJson() => {'id':id,'name':name,'kind':kind,'text':text,
    'created':created,'confirmed':confirmed,'selected':selected};
  PersonalDocument copyWith({String? text, bool? confirmed, bool? selected}) =>
      PersonalDocument(id:id,name:name,kind:kind,text:text ?? this.text,
        created:created,confirmed:confirmed ?? this.confirmed,
        selected:selected ?? this.selected);
}

class ProviderConfig {
  final String id, label, baseUrl, protocol;
  const ProviderConfig(this.id, this.label, this.baseUrl, this.protocol);
}
const providers = [
  ProviderConfig('gemini','Gemini','https://generativelanguage.googleapis.com/v1beta','gemini'),
  ProviderConfig('openai','ChatGPT / OpenAI','https://api.openai.com/v1','responses'),
  ProviderConfig('claude','Claude','https://api.anthropic.com/v1','claude'),
  ProviderConfig('nvidia','NVIDIA NIM','https://integrate.api.nvidia.com/v1','chat'),
  ProviderConfig('deepseek','DeepSeek','https://api.deepseek.com','chat'),
  ProviderConfig('custom','Other · OpenAI compatible','','chat'),
];

class AiAnswer {
  final String answer;
  final List<String> questions, steps, sourceIds;
  final bool validated;
  const AiAnswer(this.answer, this.questions, this.steps, this.sourceIds, this.validated);
  factory AiAnswer.parse(String response, Set<String> allowedSources) {
    var clean=response.trim();
    clean=clean.replaceFirst(RegExp(r'^```(?:json)?\s*'), '').replaceFirst(RegExp(r'\s*```$'), '');
    try {
      final j=jsonDecode(clean) as Map<String,dynamic>;
      final ids=List<String>.from(j['source_ids'] ?? []);
      final valid=j['source_ids'] is List && ids.every(allowedSources.contains) &&
          j['answer'] is String && (j['answer'] as String).trim().isNotEmpty &&
          j['questions'] is List && j['steps'] is List;
      return AiAnswer(j['answer']?.toString() ?? '',
        List<String>.from(j['questions'] ?? []), List<String>.from(j['steps'] ?? []),
        ids.where(allowedSources.contains).toList(), valid);
    } catch (_) {
      return AiAnswer(response, const [], const [], const [], false);
    }
  }
}
