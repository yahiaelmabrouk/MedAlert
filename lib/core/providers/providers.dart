import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:medreminder/models/interaction.dart';
import 'package:medreminder/models/medication.dart';
import 'package:medreminder/features/auth/services/auth_service.dart';
import 'package:medreminder/features/auth/services/google_auth_service.dart';
import 'package:medreminder/features/interactions/services/drug_api_service.dart';
import 'package:medreminder/features/interactions/services/interaction_service.dart';
import 'package:medreminder/features/medications/services/medication_service.dart';
import 'package:medreminder/features/medications/services/notification_service.dart';

// ── Auth ───────────────────────────────────────────────────────────────────

final authServiceProvider = Provider<AuthService>((_) => AuthService());

final googleAuthServiceProvider =
    Provider<GoogleAuthService>((_) => GoogleAuthService());

// Simple bool — overridden in main() with the value read from SharedPreferences
// before the app starts, so AuthGate never has a loading state.
final authStateProvider = StateProvider<bool>((ref) => false);

// ── Current user name ──────────────────────────────────────────────────────

final currentUserNameProvider = FutureProvider<String?>((ref) {
  return ref.read(authServiceProvider).getCurrentUserName();
});

// ── Service providers (singletons injected via Riverpod) ───────────────────

final medicationServiceProvider =
    Provider<MedicationService>((_) => MedicationService());

final drugApiServiceProvider =
    Provider<DrugApiService>((_) => DrugApiService());

final interactionServiceProvider =
    Provider<InteractionService>((_) => InteractionService());

final notificationServiceProvider =
    Provider<NotificationService>((_) => NotificationService());

// ── Medications list – AsyncNotifier (single source of truth) ─────────────

class MedicationsNotifier extends AsyncNotifier<List<Medication>> {
  @override
  Future<List<Medication>> build() =>
      ref.read(medicationServiceProvider).loadAll();

  Future<void> addMedication(Medication med) async {
    await ref.read(medicationServiceProvider).add(med);
    await ref.read(notificationServiceProvider).scheduleDaily(med);
    ref.invalidateSelf();
  }

  Future<void> removeMedication(Medication med) async {
    await ref.read(medicationServiceProvider).remove(med.id);
    await ref.read(notificationServiceProvider).cancel(med);
    ref.invalidateSelf();
  }
}

final medicationsProvider =
    AsyncNotifierProvider<MedicationsNotifier, List<Medication>>(
  MedicationsNotifier.new,
);

// ── Interactions – derived automatically from medications ──────────────────

final interactionsProvider = FutureProvider<List<Interaction>>((ref) async {
  final meds = await ref.watch(medicationsProvider.future);
  return ref.read(interactionServiceProvider).findInteractions(meds);
});

// ── Drug detail (OpenFDA) – cached per medication name ────────────────────

final drugDetailProvider =
    FutureProvider.family<DrugSearchResult?, String>((ref, name) async {
  if (name.trim().isEmpty) return null;
  final results =
      await ref.read(drugApiServiceProvider).search(name, limit: 1);
  return results.isNotEmpty ? results.first : null;
});
