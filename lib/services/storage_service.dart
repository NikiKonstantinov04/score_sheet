import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/match.dart';
import '../scoring/scoring.dart';

/// Метаданни за запазен мач.
class SavedMatchInfo {
  final String id;
  final String name;
  final MatchMode mode;
  final DateTime savedAt;

  SavedMatchInfo({
    required this.id,
    required this.name,
    required this.mode,
    required this.savedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'mode': mode.name,
    'savedAt': savedAt.toIso8601String(),
  };

  factory SavedMatchInfo.fromJson(Map<String, dynamic> json) => SavedMatchInfo(
    id: json['id'] as String,
    name: json['name'] as String,
    mode: MatchMode.values.byName(json['mode'] as String),
    savedAt: DateTime.parse(json['savedAt'] as String),
  );
}

/// Сервиз за запазване и зареждане на мачове.
class StorageService {
  static const String _matchPrefix = 'match_';

  /// Създава нов мач или обновява съществуващ по id.
  /// Връща id-то на записа.
  static Future<String> saveMatch({
    required String? id,
    required MatchMode mode,
    required Match? singleMatch,
    required Match? table1,
    required Match? table2,
    required String name,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final effectiveId = id ?? DateTime.now().millisecondsSinceEpoch.toString();
    final savedAt = DateTime.now();

    final matchData = <String, dynamic>{
      'mode': mode.name,
      if (singleMatch != null) 'singleMatch': singleMatch.toJson(),
      if (table1 != null) 'table1': table1.toJson(),
      if (table2 != null) 'table2': table2.toJson(),
    };

    final entry = {
      'id': effectiveId,
      'name': name,
      'mode': mode.name,
      'savedAt': savedAt.toIso8601String(),
      'matchData': matchData,
    };

    await prefs.setString('$_matchPrefix$effectiveId', jsonEncode(entry));
    return effectiveId;
  }

  /// Зарежда списък с всички запазени мачове.
  static Future<List<SavedMatchInfo>> getAllSavedMatches() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith(_matchPrefix));
    final list = <SavedMatchInfo>[];
    for (final key in keys) {
      final jsonString = prefs.getString(key);
      if (jsonString != null) {
        final map = jsonDecode(jsonString) as Map<String, dynamic>;
        list.add(SavedMatchInfo.fromJson(map));
      }
    }
    return list;
  }

  /// Зарежда данните на конкретен мач по id.
  static Future<Map<String, dynamic>?> loadMatchData(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_matchPrefix$id';
    final jsonString = prefs.getString(key);
    if (jsonString == null) return null;
    final map = jsonDecode(jsonString) as Map<String, dynamic>;
    return map['matchData'] as Map<String, dynamic>;
  }

  /// Изтрива мач по id.
  static Future<void> deleteMatch(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_matchPrefix$id');
  }
}