import 'package:flutter/material.dart';

import '../models/medication.dart';
import '../models/interaction.dart';
import '../services/medication_service.dart';
import '../services/interaction_service.dart';
import '../services/notification_service.dart';
import '../widgets/medication_card.dart';
import 'add_medication_screen.dart';
import 'medication_detail_screen.dart';
import 'interactions_screen.dart';
import 'check_interaction_screen.dart';

/// First screen the user sees: the list of their medications.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _medService = MedicationService();
  final _interactionService = InteractionService();

  List<Medication> _meds = [];
  List<Interaction> _interactions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadEverything();
  }

  Future<void> _loadEverything() async {
    setState(() => _loading = true);
    final meds = await _medService.loadAll();
    final interactions = await _interactionService.findInteractions(meds);
    setState(() {
      _meds = meds;
      _interactions = interactions;
      _loading = false;
    });
  }

  Future<void> _deleteMed(Medication med) async {
    await _medService.remove(med.id);
    await NotificationService().cancel(med);
    await _loadEverything();
  }

  Future<void> _openAddScreen() async {
    final added = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddMedicationScreen(existing: _meds),
      ),
    );
    if (added == true) await _loadEverything();
  }

  void _openDetail(Medication med) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MedicationDetailScreen(med: med),
      ),
    );
  }

  void _openInteractions() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InteractionsScreen(interactions: _interactions),
      ),
    );
  }

  void _openCheckInteraction() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CheckInteractionScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadEverything,
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(child: _buildHeader(theme)),
                    SliverToBoxAdapter(
                        child: _buildCheckInteractionTile(theme)),
                    if (_interactions.isNotEmpty)
                      SliverToBoxAdapter(child: _buildInteractionBanner(theme)),
                    if (_meds.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _buildEmptyState(theme),
                      )
                    else
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final med = _meds[index];
                            return MedicationCard(
                              med: med,
                              onTap: () => _openDetail(med),
                              onDelete: () => _confirmDelete(med),
                            );
                          },
                          childCount: _meds.length,
                        ),
                      ),
                    const SliverToBoxAdapter(child: SizedBox(height: 100)),
                  ],
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddScreen,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Medication'),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'MedReminder',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'You have ${_meds.length} medication${_meds.length == 1 ? '' : 's'}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckInteractionTile(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Material(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _openCheckInteraction,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.shield_outlined,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Check Interaction',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                      Text(
                        'Compare any two medications instantly',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer
                              .withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInteractionBanner(ThemeData theme) {
    final count = _interactions.length;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Material(
        color: const Color(0xFFFFE5E5),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _openInteractions,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded,
                    color: Color(0xFFB3261E)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$count interaction${count == 1 ? '' : 's'} detected',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFB3261E),
                        ),
                      ),
                      const Text(
                        'Tap to review',
                        style: TextStyle(color: Color(0xFFB3261E)),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: Color(0xFFB3261E)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.medication_outlined,
            size: 96,
            color: theme.colorScheme.primary.withOpacity(0.4),
          ),
          const SizedBox(height: 16),
          Text(
            'No medications yet',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Tap "Add Medication" to start tracking your treatments and detect interactions automatically.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(Medication med) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete medication?'),
        content: Text('Remove "${med.name}" and its reminder?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) await _deleteMed(med);
  }
}
