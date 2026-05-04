import 'package:flutter/material.dart';

import '../models/interaction.dart';
import '../widgets/severity_chip.dart';

/// Lists every detected interaction between the user's medications.
class InteractionsScreen extends StatelessWidget {
  final List<Interaction> interactions;
  const InteractionsScreen({super.key, required this.interactions});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Drug Interactions')),
      body: interactions.isEmpty
          ? _buildEmpty(theme)
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: interactions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final i = interactions[index];
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${_capitalize(i.drugA)}  ↔  ${_capitalize(i.drugB)}',
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          SeverityChip(severity: i.severity),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        i.description,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildEmpty(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.verified_rounded,
              size: 96,
              color: theme.colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No interactions detected',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Your current medications appear safe to take together based on our database.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : (s[0].toUpperCase() + s.substring(1));
}
