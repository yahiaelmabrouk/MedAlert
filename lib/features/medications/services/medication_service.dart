import 'package:shared_preferences/shared_preferences.dart';
import 'package:medreminder/models/medication.dart';

/// Saves and loads the user's medications using SharedPreferences.
///
/// We keep things very simple: the whole list is stored as a list of
/// JSON strings under one key.
class MedicationService {
  static const String _key = 'medications';

  /// Load all medications from local storage.
  Future<List<Medication>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? [];
    return list.map((s) => Medication.fromJson(s)).toList();
  }

  /// Save the entire list of medications back to storage.
  Future<void> saveAll(List<Medication> meds) async {
    final prefs = await SharedPreferences.getInstance();
    final list = meds.map((m) => m.toJson()).toList();
    await prefs.setStringList(_key, list);
  }

  /// Add one medication and persist the new list.
  Future<List<Medication>> add(Medication med) async {
    final meds = await loadAll();
    meds.add(med);
    await saveAll(meds);
    return meds;
  }

  /// Remove a medication by its id.
  Future<List<Medication>> remove(String id) async {
    final meds = await loadAll();
    meds.removeWhere((m) => m.id == id);
    await saveAll(meds);
    return meds;
  }
}
