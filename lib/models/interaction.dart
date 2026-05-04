/// A drug-drug interaction loaded from assets/interactions.json.
class Interaction {
  final String drugA;
  final String drugB;
  final String severity;     // "severe", "moderate" or "mild"
  final String description;

  Interaction({
    required this.drugA,
    required this.drugB,
    required this.severity,
    required this.description,
  });

  factory Interaction.fromMap(Map<String, dynamic> map) => Interaction(
        drugA: (map['drug_a'] as String).toLowerCase(),
        drugB: (map['drug_b'] as String).toLowerCase(),
        severity: map['severity'] as String,
        description: map['description'] as String,
      );
}
