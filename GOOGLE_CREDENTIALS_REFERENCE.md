# Google Credentials Format Reference

This shows what each credential file/value looks like so you know what you're copying.

---

## Android: google-services.json

**Location**: `android/app/google-services.json`

**Format**: JSON file (downloaded from Google Cloud Console)

```json
{
  "type": "service_account",
  "project_id": "medreminder-12345",
  "private_key_id": "abcdef1234567890...",
  "private_key": "-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n",
  "client_email": "firebase-adminsdk-xyz@medreminder-12345.iam.gserviceaccount.com",
  "client_id": "123456789",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  // ... more fields ...
}
```

**What to do**: Just download it from Google Cloud Console and place it in `android/app/`. Don't modify it.

---

## iOS: GoogleService-Info.plist

**Location**: `ios/Runner/GoogleService-Info.plist`

**Format**: Property List (XML-like) file (downloaded from Google Cloud Console)

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" ...>
<plist version="1.0">
<dict>
    <key>CLIENT_ID</key>
    <string>123456789-abcdefghijklmnop.apps.googleusercontent.com</string>
    
    <key>REVERSED_CLIENT_ID</key>
    <string>com.googleusercontent.apps.123456789-abcdefghijklmnop</string>
    
    <key>BUNDLE_ID</key>
    <string>com.example.medreminder</string>
    
    <key>PROJECT_ID</key>
    <string>medreminder-12345</string>
    
    <key>API_KEY</key>
    <string>AIzaSyDxyz...</string>
    
    <!-- ... more keys ... -->
</dict>
</plist>
```

**What you need from this**:
- **REVERSED_CLIENT_ID** (for Xcode URL Scheme) → copy the value: `com.googleusercontent.apps.123456789-abcdefghijklmnop`

**What to do**: 
1. Download from Google Cloud Console
2. Drag into Xcode (Runner folder)
3. Extract the `REVERSED_CLIENT_ID` value
4. Add it as a URL Scheme in Xcode Info.plist

---

## Web: Client ID

**Where to find**: Google Cloud Console → Credentials → Web application credential

**Format**: Text string (looks like this):

```
123456789-abcdefghijklmnopqrstuvwxyz.apps.googleusercontent.com
```

**What to do**: Pass it at runtime:

```bash
flutter run -d chrome --dart-define=GOOGLE_WEB_CLIENT_ID=123456789-abcdefghijklmnopqrstuvwxyz.apps.googleusercontent.com
```

---

## Android: SHA-1 Fingerprint

**Where to get it**: Run in the `android/` folder:

```bash
./gradlew signingReport
```

**Format**: Colon-separated hex string:

```
AB:CD:EF:12:34:56:78:90:AB:CD:EF:12:34:56:78:90:AB:CD:EF:12
```

**What to do**: Copy this entire string (including the colons) and paste it in Google Cloud Console when creating the Android credential.

---

## Quick Checklist

- [ ] Created Google Cloud Project
- [ ] Enabled Google Identity Services API
- [ ] Created OAuth 2.0 credentials (Web application)
- [ ] Got SHA-1 fingerprint (`./gradlew signingReport`)
- [ ] Created Android credential in Google Cloud → downloaded `google-services.json`
- [ ] Placed `android/app/google-services.json` in the correct folder
- [ ] Updated `android/build.gradle` and `android/app/build.gradle`
- [ ] Created iOS credential in Google Cloud → downloaded `GoogleService-Info.plist`
- [ ] Added `ios/Runner/GoogleService-Info.plist` via Xcode
- [ ] Added URL Scheme in Xcode (REVERSED_CLIENT_ID value)
- [ ] Copied web Client ID for `--dart-define=GOOGLE_WEB_CLIENT_ID=...`

---

## File Locations in Your Project

```
medreminder/
├── android/
│   ├── app/
│   │   ├── build.gradle                    ← Add google-services plugin
│   │   └── google-services.json            ← Place downloaded file here
│   └── build.gradle                        ← Add google-services classpath
├── ios/
│   ├── Runner/
│   │   ├── Info.plist                      ← Add URL Scheme here
│   │   └── GoogleService-Info.plist        ← Place downloaded file here
│   └── Runner.xcworkspace                  ← Open in Xcode
└── lib/
    └── services/
        └── google_auth_service.dart        ← Dart code (already done)
```

---

## Next Steps

1. Follow the GOOGLE_SSO_SETUP.md guide step-by-step
2. Download credentials from Google Cloud Console
3. Place files in the correct locations
4. Test by running: `flutter run` (or `flutter run -d chrome --dart-define=...` for web)
5. Tap "Continue with Google" button
6. Select your Google account
7. You should be logged in!
