import 'package:flutter/material.dart';
import '../scoring/scoring.dart';
import '../services/storage_service.dart';
import 'match_screen.dart';
import 'load_match_screen.dart';

/// Начален екран – избор на режим и зареждане на запазен мач.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  MatchMode _selectedMode = MatchMode.singleTable;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
              Theme.of(context).colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.style,
                  size: 80,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Bridge Scorer',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Изберете режим на игра',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey.shade600,
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
                  label: const Text('Зареди запазен мач'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Карта за избор на режим.
  Widget _buildModeCard(
      BuildContext context, {
        required MatchMode mode,
        required String title,
        required String subtitle,
        required IconData icon,
      }) {
    final isSelected = _selectedMode == mode;
    final primary = Theme.of(context).colorScheme.primary;

    return Card(
      elevation: isSelected ? 6 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? primary : Colors.transparent,
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
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? primary.withValues(alpha: 0.01)
                      : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  size: 36,
                  color: isSelected ? primary : Colors.grey.shade600,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade600,
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
    );
  }

  /// Стартира нов мач с избрания режим.
  void _startMatch() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MatchScreen(mode: _selectedMode),
      ),
    );
  }

  /// Зарежда запазените мачове ако има такива
  Future<void> _loadSavedMatch() async {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const LoadMatchScreen()),
    );
  }
}