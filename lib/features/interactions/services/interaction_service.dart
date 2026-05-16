import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:medreminder/models/interaction.dart';
import 'package:medreminder/models/medication.dart';
import 'drug_api_service.dart';

/// Result of a pairwise interaction check between two named drugs.
class PairCheckResult {
  /// True when an interaction was found in either source.
  final bool hasInteraction;

  /// "severe", "moderate", "mild", or "unknown" (when only the API found it).
  final String severity;

  /// Human-readable explanation of the interaction.
  final String description;

  /// Where the data came from: "local" or "openfda".
  final String source;

  const PairCheckResult({
    required this.hasInteraction,
    required this.severity,
    required this.description,
    required this.source,
  });

  const PairCheckResult.safe()
      : hasInteraction = false,
        severity = 'none',
        description = '',
        source = 'local';
}

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

  /// Check a single pair of drug names for an interaction.
  ///
  /// First consults the local curated database. If no match is found,
  /// falls back to OpenFDA drug labels via [DrugApiService].
  Future<PairCheckResult> checkPair(
    String drugA,
    String drugB, {
    DrugApiService? api,
  }) async {
    await _ensureLoaded();
    final a = drugA.toLowerCase().trim();
    final b = drugB.toLowerCase().trim();
    if (a.isEmpty || b.isEmpty || a == b) {
      return const PairCheckResult.safe();
    }

    // 1. Local database lookup.
    for (final inter in _interactions) {
      final match = (inter.drugA == a && inter.drugB == b) ||
          (inter.drugA == b && inter.drugB == a);
      if (match) {
        return PairCheckResult(
          hasInteraction: true,
          severity: inter.severity,
          description: inter.description,
          source: 'local',
        );
      }
    }

    // 2. Fallback: query OpenFDA labels for cross-references.
    final svc = api ?? DrugApiService();
    try {
      final snippet = await svc.checkInteractionViaLabels(drugA, drugB);
      if (snippet.isNotEmpty) {
        return PairCheckResult(
          hasInteraction: true,
          severity: 'unknown',
          description: snippet,
          source: 'openfda',
        );
      }
    } catch (_) {
      // Network failure → treat as "no online data" but still report safe-by-local.
    }

    return const PairCheckResult.safe();
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
