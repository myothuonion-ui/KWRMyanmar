import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'models.dart';
import 'storage.dart';
import 'handbook.dart';
import 'conversation.dart';

class AppState extends ChangeNotifier {
  final Vault vault;
  final List<LegalCard> cards;
  final List<SourceDocument> sources;
  late final HandbookIndex index = HandbookIndex(cards, sources);
  Map<String, dynamic> data;
  int resetVersion = 0;
  AppState(this.vault, this.cards, this.data, {this.sources = const []});
  static Future<AppState> load() async {
    final vault = await Vault.open();
    final cards =
        (jsonDecode(await rootBundle.loadString('assets/cards.json')) as List)
            .map((j) => LegalCard.fromJson(Map<String, dynamic>.from(j)))
            .toList();
    final data = await vault.load();
    data.putIfAbsent(
      'profile',
      () => {
        'visa': 'E-9',
        'nationality': 'Myanmar',
        'workers': 'unknown',
        'sector': 'မသိသေး',
      },
    );
    data.putIfAbsent(
      'settings',
      () => {
        'provider': 'gemini',
        'online': false,
        'profileContext': false,
        'providers': <String, dynamic>{},
      },
    );
    data.putIfAbsent('documents', () => []);
    data.putIfAbsent('history', () => []);
    data.putIfAbsent('bookmarks', () => []);
    data.putIfAbsent('events', () => []);
    data.putIfAbsent('guide_notes', () => <String, dynamic>{});
    data.putIfAbsent('guide_progress', () => <String, dynamic>{});
    final sources =
        (jsonDecode(await rootBundle.loadString('assets/sources.json')) as List)
            .map((j) => SourceDocument.fromJson(Map<String, dynamic>.from(j)))
            .toList();
    return AppState(vault, cards, data, sources: sources);
  }

  Map<String, dynamic> get profile =>
      Map<String, dynamic>.from(data['profile']);
  Map<String, dynamic> get settings =>
      Map<String, dynamic>.from(data['settings']);
  List<PersonalDocument> get documents => (data['documents'] as List)
      .map((j) => PersonalDocument.fromJson(Map<String, dynamic>.from(j)))
      .toList();
  List<Map<String, dynamic>> get history => (data['history'] as List)
      .map((j) => Map<String, dynamic>.from(j))
      .toList();
  String get activeChatId => (data['active_chat_id'] ?? 'current').toString();
  List<Map<String, dynamic>> get currentConversation =>
      sessionTurns(history, activeChatId);
  String guideNote(String id) =>
      ((data['guide_notes'] as Map? ?? {})[id] ?? '').toString();
  List<String> completedGuideSteps(String id) =>
      List<String>.from((data['guide_progress'] as Map? ?? {})[id] ?? []);
  Future<void> saveGuideNote(String id, String note) async {
    final notes =
        data.putIfAbsent('guide_notes', () => <String, dynamic>{}) as Map;
    note.trim().isEmpty ? notes.remove(id) : notes[id] = note.trim();
    await save();
  }

  Future<void> toggleGuideStep(String id, String step) async {
    final completed = completedGuideSteps(id);
    completed.contains(step) ? completed.remove(step) : completed.add(step);
    (data.putIfAbsent('guide_progress', () => <String, dynamic>{}) as Map)[id] =
        completed;
    await save();
  }

  Future<void> startConversation() async {
    data['active_chat_id'] = 'case_${DateTime.now().microsecondsSinceEpoch}';
    await save();
  }

  Future<void> resumeConversation(String id) async {
    data['active_chat_id'] = id;
    await save();
  }

  List<String> get bookmarks => List<String>.from(data['bookmarks']);
  List<Map<String, dynamic>> get events => (data['events'] as List)
      .map((j) => Map<String, dynamic>.from(j))
      .toList();
  Map<String, dynamic> providerSettings(String id) => Map<String, dynamic>.from(
    (settings['providers'] as Map)[id] ?? {'model': '', 'models': <String>[]},
  );
  Future<void> save() async {
    await vault.save(data);
    notifyListeners();
  }

  Future<void> setSetting(String key, dynamic value) async {
    (data['settings'] as Map)[key] = value;
    await save();
  }

  Future<void> setProvider(String id, Map<String, dynamic> value) async {
    ((data['settings'] as Map)['providers'] as Map)[id] = value;
    await save();
  }

  Future<void> setProfile(Map<String, dynamic> profile) async {
    data['profile'] = profile;
    await save();
  }

  Future<void> toggleBookmark(String id) async {
    final saved = bookmarks;
    saved.contains(id) ? saved.remove(id) : saved.add(id);
    data['bookmarks'] = saved;
    await save();
  }

  Future<void> putDocument(PersonalDocument document) async {
    final docs = documents;
    final index = docs.indexWhere((d) => d.id == document.id);
    if (index < 0) {
      docs.add(document);
    } else {
      docs[index] = document;
    }
    data['documents'] = docs.map((d) => d.toJson()).toList();
    await save();
  }

  Future<void> removeDocument(String id) async {
    data['documents'] = documents
        .where((d) => d.id != id)
        .map((d) => d.toJson())
        .toList();
    await save();
    await vault.deleteDocument(id);
  }

  Future<void> addHistory(Map<String, dynamic> turn) async {
    turn = {...turn, 'session_id': turn['session_id'] ?? activeChatId};
    final rows = history..add(turn);
    data['history'] = rows
        .skip(rows.length > 100 ? rows.length - 100 : 0)
        .toList();
    await save();
  }

  Future<void> clearHistory() async {
    data['history'] = [];
    data.remove('active_chat_id');
    await save();
  }

  Future<void> addEvent(Map<String, dynamic> event) async {
    data['events'] = [...events, event];
    await save();
  }

  Future<void> reset() async {
    resetVersion++;
    await vault.clear();
    data = {
      'profile': {
        'visa': 'E-9',
        'nationality': 'Myanmar',
        'workers': 'unknown',
        'sector': 'မသိသေး',
      },
      'settings': {
        'provider': 'gemini',
        'online': false,
        'profileContext': false,
        'providers': <String, dynamic>{},
      },
      'documents': [],
      'history': [],
      'bookmarks': [],
      'events': [],
      'guide_notes': <String, dynamic>{},
      'guide_progress': <String, dynamic>{},
    };
    await save();
  }
}
