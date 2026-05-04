import 'dart:async';
import 'package:flutter/material.dart';

import '../models/medication.dart';
import '../models/interaction.dart';
import '../services/drug_api_service.dart';
import '../services/medication_service.dart';
import '../services/interaction_service.dart';
import '../services/notification_service.dart';
import '../widgets/severity_chip.dart';

/// Form screen to add a new medication.
///
/// Lets the user search OpenFDA to autofill the name, set a dosage and
/// reminder time, and warns about interactions before saving.
class AddMedicationScreen extends StatefulWidget {
  final List<Medication> existing;
  const AddMedicationScreen({super.key, required this.existing});

  @override
  State<AddMedicationScreen> createState() => _AddMedicationScreenState();
}

class _AddMedicationScreenState extends State<AddMedicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _dosageCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  TimeOfDay _time = const TimeOfDay(hour: 8, minute: 0);

  // OpenFDA search state
  final _api = DrugApiService();
  Timer? _debounce;
  bool _searching = false;
  List<DrugSearchResult> _results = [];

  // Interaction warning shown live as user types the name
  final _interactionService = InteractionService();
  List<Interaction> _liveInteractions = [];

  @override
  void dispose() {
    _debounce?.cancel();
    _nameCtrl.dispose();
    _dosageCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  /// Called every time the name field changes. We debounce by 400ms so we
  /// don't hammer the API while the user is still typing.
  void _onNameChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      // Live interaction check
      final inter = await _interactionService.checkAgainstExisting(
        value,
        widget.existing,
      );
      if (!mounted) return;
      setState(() => _liveInteractions = inter);

      // OpenFDA search
      if (value.trim().length < 3) {
        setState(() => _results = []);
        return;
      }
      setState(() => _searching = true);
      try {
        final found = await _api.search(value);
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
    final picked = await showTimePicker(
      context: context,
      initialTime: _time,
    );
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

    await MedicationService().add(med);
    await NotificationService().scheduleDaily(med);

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Medication'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // -------- NAME (with OpenFDA suggestions) --------
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
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : null,
                border: const OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
              onChanged: _onNameChanged,
            ),

            // OpenFDA search results
            if (_results.isNotEmpty) _buildSearchResults(theme),

            // Live interaction warning
            if (_liveInteractions.isNotEmpty) _buildLiveWarning(theme),

            const SizedBox(height: 16),

            // -------- DOSAGE --------
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

            // -------- TIME --------
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

            // -------- NOTES --------
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
        color: theme.colorScheme.surfaceVariant.withOpacity(0.4),
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
            subtitle: r.genericName.isNotEmpty && r.genericName != display
                ? Text('Generic: ${r.genericName}')
                : null,
            onTap: () {
              _nameCtrl.text = r.genericName.isNotEmpty
                  ? r.genericName
                  : display;
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
              Icon(Icons.warning_amber_rounded, color: Color(0xFFB3261E)),
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
                      style: const TextStyle(color: Color(0xFFB3261E)),
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
