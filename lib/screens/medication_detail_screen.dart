import 'package:flutter/material.dart';

import '../models/medication.dart';
import '../services/drug_api_service.dart';

/// Shows everything we know about one medication, including info pulled
/// live from the OpenFDA API.
class MedicationDetailScreen extends StatefulWidget {
  final Medication med;
  const MedicationDetailScreen({super.key, required this.med});

  @override
  State<MedicationDetailScreen> createState() => _MedicationDetailScreenState();
}

class _MedicationDetailScreenState extends State<MedicationDetailScreen> {
  final _api = DrugApiService();
  bool _loading = true;
  DrugSearchResult? _info;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadInfo();
  }

  Future<void> _loadInfo() async {
    try {
      final results = await _api.search(widget.med.name, limit: 1);
      if (!mounted) return;
      setState(() {
        _info = results.isNotEmpty ? results.first : null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not reach OpenFDA';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final med = widget.med;

    return Scaffold(
      appBar: AppBar(title: Text(med.name)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Hero card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.primary.withOpacity(0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.medication_rounded,
                        color: Colors.white, size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        med.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _heroRow(Icons.straighten_rounded, 'Dosage',
                    med.dosage.isEmpty ? '—' : med.dosage),
                const SizedBox(height: 8),
                _heroRow(Icons.access_time_rounded, 'Reminder', med.timeLabel),
              ],
            ),
          ),

          if (med.notes.isNotEmpty) ...[
            const SizedBox(height: 24),
            _sectionTitle(theme, 'Notes'),
            const SizedBox(height: 8),
            Text(med.notes, style: theme.textTheme.bodyLarge),
          ],

          const SizedBox(height: 24),
          _sectionTitle(theme, 'Drug information (OpenFDA)'),
          const SizedBox(height: 8),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            _infoBox(theme, _error!, isError: true)
          else if (_info == null)
            _infoBox(theme, 'No detailed information found for "${med.name}".')
          else ...[
            if (_info!.purpose.isNotEmpty) ...[
              _label(theme, 'Purpose'),
              Text(_info!.purpose, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 12),
            ],
            if (_info!.warnings.isNotEmpty) ...[
              _label(theme, 'Warnings'),
              Text(_info!.warnings, style: theme.textTheme.bodyMedium),
            ],
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _heroRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 18),
        const SizedBox(width: 8),
        Text('$label: ',
            style: const TextStyle(color: Colors.white70, fontSize: 14)),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _sectionTitle(ThemeData theme, String title) => Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: theme.colorScheme.primary,
        ),
      );

  Widget _label(ThemeData theme, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 4, top: 4),
        child: Text(
          text,
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );

  Widget _infoBox(ThemeData theme, String text, {bool isError = false}) =>
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isError
              ? theme.colorScheme.errorContainer
              : theme.colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(text),
      );
}
