import 'package:flutter/material.dart';
import '../models/models.dart';
import '../scoring/scoring.dart';
import '../services/storage_service.dart';
import 'match_screen.dart';

class LoadMatchScreen extends StatefulWidget {
  const LoadMatchScreen({super.key});

  @override
  State<LoadMatchScreen> createState() => _LoadMatchScreenState();
}

class _LoadMatchScreenState extends State<LoadMatchScreen> {
  List<SavedMatchInfo>? _matches;

  @override
  void initState() {
    super.initState();
    _loadMatches();
  }

  Future<void> _loadMatches() async {
    final matches = await StorageService.getAllSavedMatches();
    setState(() {
      _matches = matches;
    });
  }

  Future<void> _openMatch(SavedMatchInfo info) async {
    final data = await StorageService.loadMatchData(info.id);
    if (data == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Мачът не е намерен')),
      );
      return;
    }

    final mode = MatchMode.values.byName(data['mode'] as String);
    Match? singleMatch;
    Match? table1;
    Match? table2;

    if (mode == MatchMode.singleTable) {
      singleMatch = Match.fromJson(data['singleMatch'] as Map<String, dynamic>);
    } else {
      table1 = Match.fromJson(data['table1'] as Map<String, dynamic>);
      table2 = Match.fromJson(data['table2'] as Map<String, dynamic>);
    }

    if (!mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MatchScreen(
          mode: mode,
          existingSingleMatch: singleMatch,
          existingTable1: table1,
          existingTable2: table2,
        ),
      ),
    );
  }

  Future<void> _deleteMatch(SavedMatchInfo info) async {
    await StorageService.deleteMatch(info.id);
    await _loadMatches();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Мачът "${info.name}" е изтрит')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Заредени мачове')),
      body: _matches == null
          ? const Center(child: CircularProgressIndicator())
          : _matches!.isEmpty
          ? const Center(child: Text('Няма запазени мачове'))
          : ListView.builder(
        itemCount: _matches!.length,
        itemBuilder: (context, index) {
          final info = _matches![index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: ListTile(
              leading: Icon(
                info.mode == MatchMode.singleTable
                    ? Icons.table_restaurant
                    : Icons.groups,
              ),
              title: Text(info.name),
              subtitle: Text(
                '${info.mode == MatchMode.singleTable ? 'Каре' : 'Отборно'} • '
                    '${info.savedAt.day}.${info.savedAt.month}.${info.savedAt.year} '
                    '${info.savedAt.hour}:${info.savedAt.minute}',
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _deleteMatch(info),
              ),
              onTap: () => _openMatch(info),
            ),
          );
        },
      ),
    );
  }
}