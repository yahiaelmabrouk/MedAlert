import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart';
import '../services/interaction_service.dart';
import '../widgets/severity_chip.dart';

class CheckInteractionScreen extends ConsumerStatefulWidget {
  const CheckInteractionScreen({super.key});

  @override
  ConsumerState<CheckInteractionScreen> createState() =>
      _CheckInteractionScreenState();
}

class _CheckInteractionScreenState
    extends ConsumerState<CheckInteractionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _drugACtrl = TextEditingController();
  final _drugBCtrl = TextEditingController();

  bool _checking = false;

  @override
  void dispose() {
    _drugACtrl.dispose();
    _drugBCtrl.dispose();
    super.dispose();
  }

  Future<void> _check() async {
    if (!_formKey.currentState!.validate()) return;
    final a = _drugACtrl.text.trim();
    final b = _drugBCtrl.text.trim();
    if (a.toLowerCase() == b.toLowerCase()) {
      _showSimpleDialog(
        title: 'Same medication',
        body: 'Please enter two different medications.',
        icon: Icons.info_outline_rounded,
        color: Theme.of(context).colorScheme.primary,
      );
      return;
    }

    setState(() => _checking = true);
    try {
      final result =
          await ref.read(interactionServiceProvider).checkPair(a, b);
      if (!mounted) return;
      _showResultDialog(a, b, result);
    } catch (e) {
      if (!mounted) return;
      _showSimpleDialog(
        title: 'Check failed',
        body: 'Could not complete the check.\n\n$e',
        icon: Icons.error_outline_rounded,
        color: Colors.red,
      );
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  void _showResultDialog(String a, String b, PairCheckResult result) {
    final theme = Theme.of(context);

    if (!result.hasInteraction) {
      showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          icon: const Icon(Icons.verified_rounded,
              color: Color(0xFF2E7D32), size: 48),
          title: const Text('Looks safe'),
          content: Text(
            'No known interaction was found between '
            '"${_cap(a)}" and "${_cap(b)}".\n\n'
            'This check uses our curated database and the OpenFDA drug labels. '
            'Always confirm with your doctor or pharmacist.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    final color = switch (result.severity) {
      'severe' => const Color(0xFFB3261E),
      'moderate' => const Color(0xFFE08600),
      'mild' => const Color(0xFFB59B00),
      _ => theme.colorScheme.primary,
    };

    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        icon: Icon(Icons.warning_amber_rounded, color: color, size: 48),
        title: Text(
          result.severity == 'unknown'
              ? 'Possible interaction'
              : 'Interaction detected',
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_cap(a)}  ↔  ${_cap(b)}',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              if (result.severity != 'unknown' && result.severity != 'none')
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SeverityChip(severity: result.severity),
                ),
              Text(result.description),
              const SizedBox(height: 16),
              Text(
                result.source == 'openfda'
                    ? 'Source: OpenFDA drug label'
                    : 'Source: MedReminder database',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _showSimpleDialog({
    required String title,
    required String body,
    required IconData icon,
    required Color color,
  }) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        icon: Icon(icon, color: color, size: 48),
        title: Text(title),
        content: Text(body),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Check Interaction')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Compare two medications',
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter the names of two drugs to see if they interact. '
                  'We check our internal database first, then OpenFDA.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _drugACtrl,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'First medication',
                    hintText: 'e.g. Warfarin',
                    prefixIcon: Icon(Icons.medication_outlined),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _drugBCtrl,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    labelText: 'Second medication',
                    hintText: 'e.g. Aspirin',
                    prefixIcon: Icon(Icons.medication_outlined),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                  onFieldSubmitted: (_) => _check(),
                ),
                const SizedBox(height: 28),
                FilledButton.icon(
                  onPressed: _checking ? null : _check,
                  icon: _checking
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.shield_outlined),
                  label:
                      Text(_checking ? 'Checking…' : 'Check Interaction'),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer
                        .withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded,
                          color: theme.colorScheme.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'For best results, use generic drug names '
                          '(e.g. "ibuprofen" instead of "Advil").',
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _cap(String s) =>
      s.isEmpty ? s : (s[0].toUpperCase() + s.substring(1).toLowerCase());
}
