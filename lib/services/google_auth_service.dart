// ─── Platform setup required before Google Sign-In works ──────────────────
//
// ANDROID
//   1. Place google-services.json in android/app/
//   2. android/build.gradle  → add inside dependencies:
//        classpath 'com.google.gms:google-services:4.4.1'
//   3. android/app/build.gradle → add at the very bottom:
//        apply plugin: 'com.google.gms.google-services'
//
// iOS
//   1. Place GoogleService-Info.plist in ios/Runner/ (via Xcode)
//   2. In ios/Runner/Info.plist add a CFBundleURLTypes entry whose
//      CFBundleURLSchemes value is the REVERSED_CLIENT_ID from the plist.
//
// WEB
//   Pass your web OAuth client ID via dart-define when running/building:
//     flutter run --dart-define=GOOGLE_WEB_CLIENT_ID=<your-web-client-id>
// ──────────────────────────────────────────────────────────────────────────

import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthService {
  // Injected at compile time with --dart-define=GOOGLE_WEB_CLIENT_ID=...
  // Leave empty for Android / iOS (credentials come from the config files).
  static const _webClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue: '',
  );

  final _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    clientId: _webClientId.isEmpty ? null : _webClientId,
  );

  // Returns the signed-in account, or null if the user cancelled / error.
  Future<GoogleSignInAccount?> signIn() async {
    try {
      // signIn() shows the account picker. Returns null when cancelled.
      return await _googleSignIn.signIn();
    } catch (_) {
      return null;
    }
  }

  // Signs out of Google so the account picker shows again next time.
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
  }
}
