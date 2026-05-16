import 'package:flutter/material.dart';

/// Small colored chip showing interaction severity (severe / moderate / mild).
///
/// Colours adapt to light & dark themes: the background is a soft tint of the
/// severity colour, and the text is brightened in dark mode for contrast.
class SeverityChip extends StatelessWidget {
  final String severity;
  const SeverityChip({super.key, required this.severity});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final (Color base, IconData icon) = switch (severity.toLowerCase()) {
      'severe' => (const Color(0xFFE53935), Icons.warning_amber_rounded),
      'moderate' => (const Color(0xFFEF8A00), Icons.error_outline_rounded),
      _ => (const Color(0xFF3B82F6), Icons.info_outline_rounded),
    };

    final bg = base.withValues(alpha: isDark ? 0.22 : 0.14);
    final fg = isDark ? Color.lerp(base, Colors.white, 0.45)! : base;
    final label = severity.isEmpty
        ? 'Unknown'
        : severity[0].toUpperCase() + severity.substring(1);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: base.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
