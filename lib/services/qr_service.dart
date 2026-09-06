import 'dart:convert';
import '../models/match.dart';
import '../models/models.dart';

/// Обект, който се предава чрез QR код.
class QrPayload {
  final int tableNumber; // 1 или 2
  final Match match;

  QrPayload({required this.tableNumber, required this.match});

  String toJsonString() {
    return jsonEncode({
      'tableNumber': tableNumber,
      'match': match.toJson(),
    });
  }

  static QrPayload? fromJsonString(String jsonString) {
    try {
      final map = jsonDecode(jsonString) as Map<String, dynamic>;
      final tableNumber = map['tableNumber'] as int;
      final matchJson = map['match'] as Map<String, dynamic>;
      return QrPayload(
        tableNumber: tableNumber,
        match: Match.fromJson(matchJson),
      );
    } catch (_) {
      return null;
    }
  }
}