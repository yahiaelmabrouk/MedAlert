import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:medreminder/core/providers/providers.dart';
import 'package:medreminder/features/medications/screens/home_screen.dart';
import 'package:medreminder/features/auth/screens/login_screen.dart';
import 'package:medreminder/features/medications/services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().init();

  // Read login state from disk before the app starts so AuthGate
  // never needs a loading/async state — it always has the correct value.
  final prefs = await SharedPreferences.getInstance();
  final isLoggedIn = prefs.getBool('auth_logged_in') ?? false;

  runApp(
    ProviderScope(
      overrides: [
        authStateProvider.overrideWith((ref) => isLoggedIn),
      ],
      child: const MedReminderApp(),
    ),
  );
}

class MedReminderApp extends StatelessWidget {
  const MedReminderApp({super.key});

  static const _seed = Color(0xFF00897B);

  @override
  Widget build(BuildContext context) {
    final lightScheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: Brightness.light,
    );

    return MaterialApp(
      title: 'MedReminder',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: lightScheme,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF7F9FB),
        textTheme: GoogleFonts.interTextTheme(),
        appBarTheme: AppBarTheme(
          backgroundColor: lightScheme.surface,
          foregroundColor: lightScheme.onSurface,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: lightScheme.onSurface,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          shape: StadiumBorder(),
        ),
      ),
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
