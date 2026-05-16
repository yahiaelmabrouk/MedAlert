import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:medreminder/models/medication.dart';
import 'package:medreminder/core/providers/providers.dart';
import 'package:medreminder/widgets/medication_card.dart';
import 'package:medreminder/widgets/theme_mode_button.dart';
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
          const ThemeModeButton(),
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
                  SliverToBoxAdapter(
                    child: _Header(count: meds.length, userName: userName),
                  ),
                  SliverToBoxAdapter(
                    child: _buildCheckInteractionTile(context, theme),
                  ),
                  if (interactions.isNotEmpty)
                    SliverToBoxAdapter(
                      child: _buildInteractionBanner(
                          context, theme, interactions.length),
                    ),
                  if (meds.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding:
                            const EdgeInsets.fromLTRB(20, 16, 20, 4),
                        child: Text(
                          'Your medications',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
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

  Widget _buildCheckInteractionTile(BuildContext context, ThemeData theme) {
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CheckInteractionScreen()),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.shield_outlined, color: scheme.onPrimary),
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
                          color: scheme.onPrimaryContainer,
                        ),
                      ),
                      Text(
                        'Compare any two medications instantly',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onPrimaryContainer
                              .withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    color: scheme.onPrimaryContainer),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInteractionBanner(
      BuildContext context, ThemeData theme, int count) {
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Material(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const InteractionsScreen()),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: scheme.error,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.warning_amber_rounded,
                      color: scheme.onError),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$count interaction${count == 1 ? '' : 's'} detected',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: scheme.onErrorContainer,
                        ),
                      ),
                      Text(
                        'Tap to review the details',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onErrorContainer
                              .withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    color: scheme.onErrorContainer),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: scheme.primaryContainer.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.medication_outlined,
              size: 64,
              color: scheme.primary,
            ),
          ),
          const SizedBox(height: 20),
          Text('No medications yet', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Tap "Add Medication" to start tracking your treatments and detect interactions automatically.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
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

/// Gradient hero header greeting the user and showing their medication count.
class _Header extends StatelessWidget {
  final int count;
  final String? userName;

  const _Header({required this.count, this.userName});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final greeting = userName != null ? 'Hello, $userName' : 'Welcome back';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              scheme.primary,
              Color.lerp(scheme.primary, scheme.tertiary, 0.55)!,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    greeting,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: scheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    count == 0
                        ? 'No medications tracked yet'
                        : 'You are tracking $count '
                            'medication${count == 1 ? '' : 's'}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onPrimary.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: scheme.onPrimary.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.medical_services_rounded,
                color: scheme.onPrimary,
                size: 28,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
