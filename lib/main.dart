import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:medreminder/core/providers/providers.dart';
import 'package:medreminder/core/theme/app_theme.dart';
import 'package:medreminder/core/theme/theme_controller.dart';
import 'package:medreminder/features/medications/screens/home_screen.dart';
import 'package:medreminder/features/auth/screens/login_screen.dart';
import 'package:medreminder/features/medications/services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().init();

  // Read persisted state from disk before the app starts so the first frame
  // is already correct — AuthGate has no loading state and the theme never
  // flickers from system → saved mode.
  final prefs = await SharedPreferences.getInstance();
  final isLoggedIn = prefs.getBool('auth_logged_in') ?? false;
  final themeMode = themeModeFromName(prefs.getString(themeModePrefsKey));

  runApp(
    ProviderScope(
      overrides: [
        authStateProvider.overrideWith((ref) => isLoggedIn),
        initialThemeModeProvider.overrideWithValue(themeMode),
      ],
      child: const MedReminderApp(),
    ),
  );
}

class MedReminderApp extends ConsumerWidget {
  const MedReminderApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'MedReminder',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      home: const AuthGate(),
    );
  }
}

// Watches a plain bool — no async, no loading state.
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoggedIn = ref.watch(authStateProvider);
    return isLoggedIn ? const HomeScreen() : const LoginScreen();
  }
}
