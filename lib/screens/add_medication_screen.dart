import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/interaction.dart';
import '../models/medication.dart';
import '../providers/providers.dart';
import '../services/drug_api_service.dart';
import '../widgets/severity_chip.dart';

class AddMedicationScreen extends ConsumerStatefulWidget {
  const AddMedicationScreen({super.key});

  @override
  ConsumerState<AddMedicationScreen> createState() =>
      _AddMedicationScreenState();
}

class _AddMedicationScreenState extends ConsumerState<AddMedicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _dosageCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  TimeOfDay _time = const TimeOfDay(hour: 8, minute: 0);

  Timer? _debounce;
  bool _searching = false;
  List<DrugSearchResult> _results = [];
  List<Interaction> _liveInteractions = [];

  @override
  void dispose() {
    _debounce?.cancel();
    _nameCtrl.dispose();
    _dosageCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _onNameChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      final existing =
          ref.read(medicationsProvider).valueOrNull ?? [];
      final inter = await ref
          .read(interactionServiceProvider)
          .checkAgainstExisting(value, existing);
      if (!mounted) return;
      setState(() => _liveInteractions = inter);

      if (value.trim().length < 3) {
        setState(() => _results = []);
        return;
      }
      setState(() => _searching = true);
      try {
        final found =
            await ref.read(drugApiServiceProvider).search(value);
        if (!mounted) return;
        setState(() {
          _results = found;
          _searching = false;
        });
      } catch (_) {
        if (!mounted) return;
        setState(() {
          _results = [];
          _searching = false;
        });
      }
    });
  }

  Future<void> _pickTime() async {
    final picked =
        await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final med = Medication(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameCtrl.text.trim(),
      dosage: _dosageCtrl.text.trim(),
      hour: _time.hour,
      minute: _time.minute,
      notes: _notesCtrl.text.trim(),
    );

    await ref.read(medicationsProvider.notifier).addMedication(med);

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Add Medication')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: 'Medication name',
                hintText: 'e.g. Ibuprofen',
                prefixIcon: const Icon(Icons.medication_rounded),
                suffixIcon: _searching
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child:
                              CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : null,
                border: const OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
              onChanged: _onNameChanged,
            ),
            if (_results.isNotEmpty) _buildSearchResults(theme),
            if (_liveInteractions.isNotEmpty) _buildLiveWarning(theme),
            const SizedBox(height: 16),
            TextFormField(
              controller: _dosageCtrl,
              decoration: const InputDecoration(
                labelText: 'Dosage',
                hintText: 'e.g. 200 mg, 1 tablet',
                prefixIcon: Icon(Icons.straighten_rounded),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _pickTime,
              borderRadius: BorderRadius.circular(8),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Daily reminder time',
                  prefixIcon: Icon(Icons.access_time_rounded),
                  border: OutlineInputBorder(),
                ),
                child: Text(_time.format(context)),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                hintText: 'Take with food, etc.',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save_rounded),
              label: const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('Save medication'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest
            .withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: _results.map((r) {
          final display = r.brandName.isNotEmpty
              ? r.brandName
              : (r.genericName.isNotEmpty ? r.genericName : 'Unknown');
          return ListTile(
            leading: const Icon(Icons.search_rounded),
            title: Text(display),
            subtitle:
                r.genericName.isNotEmpty && r.genericName != display
                    ? Text('Generic: ${r.genericName}')
                    : null,
            onTap: () {
              _nameCtrl.text =
                  r.genericName.isNotEmpty ? r.genericName : display;
              _onNameChanged(_nameCtrl.text);
              setState(() => _results = []);
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLiveWarning(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE5E5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.warning_amber_rounded,
                  color: Color(0xFFB3261E)),
              SizedBox(width: 8),
              Text(
                'Possible interaction',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFB3261E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ..._liveInteractions.map(
            (i) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SeverityChip(severity: i.severity),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'With ${i.drugA == _nameCtrl.text.toLowerCase() ? i.drugB : i.drugA}: ${i.description}',
                      style:
                          const TextStyle(color: Color(0xFFB3261E)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
