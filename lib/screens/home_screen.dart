import 'package:flutter/material.dart';
import '../scoring/scoring.dart';
import '../services/storage_service.dart';
import 'match_screen.dart';
import 'load_match_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  MatchMode _selectedMode = MatchMode.singleTable;
  int _savedMatchesCount = 0;

  @override
  void initState() {
    super.initState();
    _loadSavedMatchesCount();
  }

  Future<void> _loadSavedMatchesCount() async {
    final matches = await StorageService.getAllSavedMatches();
    if (!mounted) return;
    setState(() {
      _savedMatchesCount = matches.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.primary.withValues(alpha: 0.08),
              theme.colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 48,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Icon(
                        Icons.style,
                        size: 80,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Bridge Scorer',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Изберете режим на игра',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 40),
                      _buildModeCard(
                        context,
                        mode: MatchMode.singleTable,
                        title: 'Каре',
                        subtitle: 'Една маса • HCP задължения',
                        icon: Icons.table_restaurant,
                      ),
                      const SizedBox(height: 16),
                      _buildModeCard(
                        context,
                        mode: MatchMode.teamMatch,
                        title: 'Отборно',
                        subtitle: 'Две маси • Сравнение на резултати',
                        icon: Icons.groups,
                      ),
                      const SizedBox(height: 40),
                      FilledButton.icon(
                        onPressed: _startMatch,
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: const Text('Започни нов мач'),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _loadSavedMatch,
                        icon: const Icon(Icons.folder_open),
                        label: Text(
                          _savedMatchesCount > 0
                              ? 'Зареди запазен мач ($_savedMatchesCount)'
                              : 'Зареди запазен мач',
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildModeCard(
      BuildContext context, {
        required MatchMode mode,
        required String title,
        required String subtitle,
        required IconData icon,
      }) {
    final theme = Theme.of(context);
    final isSelected = _selectedMode == mode;
    final primary = theme.colorScheme.primary;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? primary.withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: isSelected ? 12 : 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Card(
        elevation: 0,
        color: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected ? primary : theme.colorScheme.outlineVariant,
            width: 2,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => setState(() => _selectedMode = mode),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? primary.withValues(alpha: 0.1)
                        : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    icon,
                    size: 36,
                    color: isSelected ? primary : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check_circle, color: primary),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _startMatch() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MatchScreen(mode: _selectedMode),
      ),
    );
  }

  void _loadSavedMatch() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const LoadMatchScreen()),
    );
  }
}