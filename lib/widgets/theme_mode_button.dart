import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:medreminder/core/theme/theme_controller.dart';

/// An AppBar action that opens an "Appearance" picker so the user can
/// switch between System / Light / Dark themes.
class ThemeModeButton extends ConsumerWidget {
  const ThemeModeButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    return IconButton(
      tooltip: 'Appearance',
      icon: Icon(_iconFor(mode)),
      onPressed: () => _showSheet(context, ref),
    );
  }

  static IconData _iconFor(ThemeMode mode) => switch (mode) {
        ThemeMode.light => Icons.light_mode_rounded,
        ThemeMode.dark => Icons.dark_mode_rounded,
        ThemeMode.system => Icons.brightness_auto_rounded,
      };

  void _showSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        final current = ref.watch(themeModeProvider);
        final theme = Theme.of(sheetContext);
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 4, 24, 12),
                child: Text(
                  'Appearance',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              _ModeTile(
                mode: ThemeMode.system,
                current: current,
                icon: Icons.brightness_auto_rounded,
                title: 'System default',
                subtitle: 'Follow your device setting',
                onTap: () => _select(sheetContext, ref, ThemeMode.system),
              ),
              _ModeTile(
                mode: ThemeMode.light,
                current: current,
                icon: Icons.light_mode_rounded,
                title: 'Light',
                subtitle: 'Always use the light theme',
                onTap: () => _select(sheetContext, ref, ThemeMode.light),
              ),
              _ModeTile(
                mode: ThemeMode.dark,
                current: current,
                icon: Icons.dark_mode_rounded,
                title: 'Dark',
                subtitle: 'Always use the dark theme',
                onTap: () => _select(sheetContext, ref, ThemeMode.dark),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  void _select(BuildContext context, WidgetRef ref, ThemeMode mode) {
    ref.read(themeModeProvider.notifier).setMode(mode);
    Navigator.pop(context);
  }
}

class _ModeTile extends StatelessWidget {
  final ThemeMode mode;
  final ThemeMode current;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ModeTile({
    required this.mode,
    required this.current,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final selected = mode == current;
    return ListTile(
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: selected
              ? scheme.primaryContainer
              : scheme.surfaceContainerHighest,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color:
              selected ? scheme.onPrimaryContainer : scheme.onSurfaceVariant,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
      subtitle: Text(subtitle),
      trailing: selected
          ? Icon(Icons.check_circle_rounded, color: scheme.primary)
          : null,
      onTap: onTap,
    );
  }
}
