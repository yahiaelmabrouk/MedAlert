import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// SharedPreferences key under which the chosen theme mode is stored.
const String themeModePrefsKey = 'theme_mode';

/// Holds the [ThemeMode] read from disk before the app starts.
///
/// Overridden in `main()` — mirrors how `authStateProvider` is seeded, so the
/// app paints with the correct theme on the very first frame (no flicker).
final initialThemeModeProvider = Provider<ThemeMode>((_) => ThemeMode.system);

/// The active theme mode. Watch it to rebuild on change; mutate it via
/// `ref.read(themeModeProvider.notifier).setMode(...)`.
final themeModeProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ref.read(initialThemeModeProvider);

  /// Updates the mode and persists it so it survives app restarts.
  Future<void> setMode(ThemeMode mode) async {
    if (mode == state) return;
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(themeModePrefsKey, mode.name);
  }
}

/// Parses a stored mode name (e.g. "dark") back into a [ThemeMode],
/// falling back to [ThemeMode.system] for unknown / missing values.
ThemeMode themeModeFromName(String? name) => ThemeMode.values.firstWhere(
      (m) => m.name == name,
      orElse: () => ThemeMode.system,
    );
