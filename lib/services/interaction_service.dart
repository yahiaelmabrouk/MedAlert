import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/interaction.dart';
import '../models/medication.dart';

/// Loads the local interactions JSON and checks medications against it.
class InteractionService {
  List<Interaction> _interactions = [];
  bool _loaded = false;

  /// Read assets/interactions.json into memory. Safe to call many times.
  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    final raw = await rootBundle.loadString('assets/interactions.json');
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final list = (decoded['interactions'] as List)
        .map((e) => Interaction.fromMap(e as Map<String, dynamic>))
        .toList();
    _interactions = list;
    _loaded = true;
  }

  /// Compare every pair of medications and return the matching interactions.
  Future<List<Interaction>> findInteractions(List<Medication> meds) async {
    await _ensureLoaded();
    final found = <Interaction>[];

    // We compare each medication against the others (i, j) where j > i so we
    // never compare the same pair twice.
    for (var i = 0; i < meds.length; i++) {
      for (var j = i + 1; j < meds.length; j++) {
        final a = meds[i].name.toLowerCase().trim();
        final b = meds[j].name.toLowerCase().trim();
        for (final inter in _interactions) {
          final match = (inter.drugA == a && inter.drugB == b) ||
              (inter.drugA == b && inter.drugB == a);
          if (match) found.add(inter);
        }
      }
    }
    return found;
  }

  /// Check if adding [newDrug] would clash with any existing medication.
  Future<List<Interaction>> checkAgainstExisting(
    String newDrug,
    List<Medication> existing,
  ) async {
    await _ensureLoaded();
    final newName = newDrug.toLowerCase().trim();
    final found = <Interaction>[];
    for (final med in existing) {
      final other = med.name.toLowerCase().trim();
      for (final inter in _interactions) {
        final match = (inter.drugA == newName && inter.drugB == other) ||
            (inter.drugA == other && inter.drugB == newName);
        if (match) found.add(inter);
      }
    }
    return found;
  }
}
