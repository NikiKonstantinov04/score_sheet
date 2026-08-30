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
    if (!mounted) return;
    // Сортиране по дата (най-новите първи)
    matches.sort((a, b) => b.savedAt.compareTo(a.savedAt));
    setState(() {
      _matches = matches;
    });
  }

  Future<void> _openMatch(SavedMatchInfo info) async {
    final data = await StorageService.loadMatchData(info.id);
    if (data == null) {
      if (!mounted) return;
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
          savedMatchId: info.id,
          savedMatchName: info.name,
        ),
      ),
    );
  }

  Future<void> _deleteMatch(SavedMatchInfo info) async {
    // Потвърждение
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Изтриване на мач'),
        content: Text('Сигурни ли сте, че искате да изтриете "${info.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отказ'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Изтрий'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await StorageService.deleteMatch(info.id);
    await _loadMatches();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Мачът "${info.name}" е изтрит')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Заредени мачове')),
      body: SafeArea(
        child: _matches == null
            ? const Center(child: CircularProgressIndicator())
            : _matches!.isEmpty
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.folder_open,
                size: 64,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(
                'Няма запазени мачове',
                style: theme.textTheme.titleMedium,
              ),
            ],
          ),
        )
            : RefreshIndicator(
          onRefresh: _loadMatches,
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
            itemCount: _matches!.length,
            itemBuilder: (context, index) {
              final info = _matches![index];
              final isSingleTable = info.mode == MatchMode.singleTable;

              return Dismissible(
                key: Key(info.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  color: theme.colorScheme.errorContainer,
                  child: Icon(
                    Icons.delete_outline,
                    color: theme.colorScheme.onErrorContainer,
                  ),
                ),
                onDismissed: (_) => _deleteMatch(info),
                child: Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: Icon(
                      isSingleTable
                          ? Icons.table_restaurant
                          : Icons.groups,
                      color: theme.colorScheme.primary,
                    ),
                    title: Text(
                      info.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${isSingleTable ? 'Каре' : 'Отборно'} • '
                          '${info.savedAt.day}.${info.savedAt.month}.${info.savedAt.year} '
                          '${info.savedAt.hour}:${info.savedAt.minute}',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _deleteMatch(info),
                    ),
                    onTap: () => _openMatch(info),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}