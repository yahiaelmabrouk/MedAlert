import 'package:flutter/material.dart';

/// Small colored chip used to show interaction severity (severe / moderate / mild).
class SeverityChip extends StatelessWidget {
  final String severity;
  const SeverityChip({super.key, required this.severity});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    IconData icon;

    switch (severity.toLowerCase()) {
      case 'severe':
        bg = const Color(0xFFFFE5E5);
        fg = const Color(0xFFB3261E);
        icon = Icons.warning_amber_rounded;
        break;
      case 'moderate':
        bg = const Color(0xFFFFF4E5);
        fg = const Color(0xFFB55A00);
        icon = Icons.error_outline_rounded;
        break;
      default: // mild
        bg = const Color(0xFFE8F0FE);
        fg = const Color(0xFF1A4D8F);
        icon = Icons.info_outline_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 4),
          Text(
            severity[0].toUpperCase() + severity.substring(1),
            style: TextStyle(
              color: fg,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
