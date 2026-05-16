import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:medreminder/models/medication.dart';
import 'package:medreminder/core/providers/providers.dart';
import 'package:medreminder/widgets/medication_card.dart';
import 'package:medreminder/features/auth/screens/login_screen.dart';
import 'package:medreminder/features/interactions/screens/check_interaction_screen.dart';
import 'package:medreminder/features/interactions/screens/interactions_screen.dart';
import 'add_medication_screen.dart';
import 'medication_detail_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final medsAsync = ref.watch(medicationsProvider);
    final interactionsAsync = ref.watch(interactionsProvider);
    final theme = Theme.of(context);

    final userName = ref.watch(currentUserNameProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text('MedReminder'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sign out',
            onPressed: () async {
              await ref.read(authServiceProvider).logout();
              ref.read(authStateProvider.notifier).state = false;
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: medsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error loading medications: $e')),
          data: (meds) {
            final interactions = interactionsAsync.valueOrNull ?? [];
            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(medicationsProvider);
                await ref.read(medicationsProvider.future);
              },
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _buildHeader(theme, meds.length, userName)),
                  SliverToBoxAdapter(
                      child: _buildCheckInteractionTile(context, theme)),
                  if (interactions.isNotEmpty)
                    SliverToBoxAdapter(
                      child: _buildInteractionBanner(
                          context, ref, theme, interactions.length),
                    ),
                  if (meds.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _buildEmptyState(theme),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final med = meds[index];
                          return MedicationCard(
                            med: med,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    MedicationDetailScreen(med: med),
                              ),
                            ),
                            onDelete: () =>
                                _confirmDelete(context, ref, med),
                          );
                        },
                        childCount: meds.length,
                      ),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddMedicationScreen()),
        ),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Medication'),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, int count, String? userName) {
    final greeting = userName != null ? 'Hello, $userName' : 'MedReminder';
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            greeting,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'You have $count medication${count == 1 ? '' : 's'}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckInteractionTile(BuildContext context, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Material(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const CheckInteractionScreen()),
          ),
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
                              .withValues(alpha: 0.8),
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

  Widget _buildInteractionBanner(
      BuildContext context, WidgetRef ref, ThemeData theme, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Material(
        color: const Color(0xFFFFE5E5),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const InteractionsScreen()),
          ),
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
            color: theme.colorScheme.primary.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text('No medications yet', style: theme.textTheme.titleLarge),
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

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, Medication med) async {
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
    if (ok == true) {
      await ref.read(medicationsProvider.notifier).removeMedication(med);
    }
  }
}
