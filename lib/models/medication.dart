import 'dart:convert';

/// A single medication that the user is taking.
///
/// We store everything as simple Dart types so it can be saved to
/// SharedPreferences as JSON.
class Medication {
  final String id;
  final String name;        // Generic / display name (e.g. "Ibuprofen")
  final String dosage;      // Free-text dosage (e.g. "200 mg")
  final int hour;           // Reminder hour (0-23)
  final int minute;         // Reminder minute (0-59)
  final String notes;       // Optional notes from the user

  Medication({
    required this.id,
    required this.name,
    required this.dosage,
    required this.hour,
    required this.minute,
    this.notes = '',
  });

  /// Convert this object into a Map so it can be stored as JSON.
  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'dosage': dosage,
        'hour': hour,
        'minute': minute,
        'notes': notes,
      };

  /// Recreate a Medication from its Map form.
  factory Medication.fromMap(Map<String, dynamic> map) => Medication(
        id: map['id'] as String,
        name: map['name'] as String,
        dosage: map['dosage'] as String? ?? '',
        hour: map['hour'] as int,
        minute: map['minute'] as int,
        notes: map['notes'] as String? ?? '',
      );

  String toJson() => jsonEncode(toMap());

  factory Medication.fromJson(String source) =>
      Medication.fromMap(jsonDecode(source) as Map<String, dynamic>);

  /// Returns "08:30" style time string.
  String get timeLabel {
    final h = hour.toString().padLeft(2, '0');
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
