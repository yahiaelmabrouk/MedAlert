# Google SSO Setup Guide

This guide explains what credentials you need and where to put them.

---

## Step 1: Create a Google Cloud Project

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Click "Select a Project" → "NEW PROJECT"
3. Name it (e.g., "MedReminder")
4. Click "CREATE"
5. Wait for it to load, then select your new project

---

## Step 2: Enable Google Sign-In API

1. In the Google Cloud Console, search for "Google Identity Services"
2. Click it and select "Google Identity Services API"
3. Click "ENABLE"

---

## Step 3: Create OAuth 2.0 Credentials

1. Go to **Credentials** (left sidebar)
2. Click **"+ CREATE CREDENTIALS"** → **"OAuth client ID"**
3. If prompted: click "CONFIGURE CONSENT SCREEN" first
   - Choose **External** user type → "CREATE"
   - Fill required fields (app name, support email)
   - Leave scopes default → "SAVE AND CONTINUE"
   - Don't add test users (not needed for SSO)
   - Go back to Credentials

4. Now create OAuth 2.0 credentials:
   - Choose **"Web application"** (NOT "Android" or "iOS" yet)
   - Click "CREATE"
   - **Copy the "Client ID"** — you'll need this for web

---

## Step 4: Android Setup

### 4a. Get your SHA-1 Fingerprint

```bash
# Windows (PowerShell)
cd android
./gradlew signingReport

# Mac/Linux (bash)
cd android
./gradlew signingReport
```

Look for the **SHA1** value (looks like: `AB:CD:EF:12:34:...`)

### 4b. Add Android Credential in Google Cloud

1. Back in Google Cloud Console → **Credentials**
2. Click **"+ CREATE CREDENTIALS"** → **"OAuth client ID"**
3. Choose **"Android"**
4. Fill in:
   - **Package name**: `com.example.medreminder` (or your actual package name)
     - Find it in `android/app/build.gradle` → look for `applicationId`
   - **SHA-1 certificate fingerprint**: Paste the SHA1 from step 4a
5. Click "CREATE"
6. **Copy the resulting OAuth 2.0 Client ID** (you don't need this for Android, but good to have)

### 4c. Download & Place google-services.json

1. In Google Cloud Console → **Credentials**
2. Look for your Android app credential → click **the download icon** (or the three dots → Download)
3. This downloads `google-services.json`
4. **Place it in**: `android/app/google-services.json`

### 4d. Update Android Build Files

**File: `android/build.gradle`** (the project-level one, NOT app-level)

Add inside `buildscript { dependencies { } }`:
```gradle
dependencies {
    classpath 'com.google.gms:google-services:4.4.1'
    // ... other classpath entries
}
```

**File: `android/app/build.gradle`** (the app-level one)

Add at the **very bottom** (after all other plugins):
```gradle
apply plugin: 'com.google.gms.google-services'
```

---

## Step 5: iOS Setup

### 5a. Add iOS Credential in Google Cloud

1. Back in Google Cloud Console → **Credentials**
2. Click **"+ CREATE CREDENTIALS"** → **"OAuth client ID"**
3. Choose **"iOS"**
4. Fill in:
   - **Bundle ID**: Open `ios/Runner.xcworkspace` in Xcode
     - Or check `ios/Runner/Info.plist` for the value (look for `CFBundleIdentifier`)
     - Typically: `com.example.medreminder` (or similar)
   - **App Store ID**: Leave empty (optional)
   - **Team ID**: Leave empty (optional)
5. Click "CREATE"

### 5b. Download & Place GoogleService-Info.plist

1. In Google Cloud Console → **Credentials**
2. Look for your iOS app credential → click **the download icon**
3. This downloads `GoogleService-Info.plist`
4. **Open `ios/Runner.xcworkspace` in Xcode** (NOT `ios/Runner.xcodeproj`)
5. Drag & drop `GoogleService-Info.plist` into Xcode (into the Runner folder)
6. Ensure it's added to the Runner target

### 5c. Configure URL Scheme

1. In Xcode, go to **Runner** (project) → **Runner** (target)
2. Go to **"Info"** tab
3. Scroll down to **"URL Types"** (or expand if collapsed)
4. Click **"+"** to add a new URL type
5. In the **"URL Schemes"** field, paste the **REVERSED_CLIENT_ID** from `GoogleService-Info.plist`
   - Open the plist file: right-click → "Open As" → "Source Code"
   - Find `REVERSED_CLIENT_ID` value (looks like: `com.googleusercontent.apps.123456789-abcdef...`)
   - Copy just the value, paste it in Xcode's URL Schemes

---

## Step 6: Web Setup

### 6a. Get Web Client ID

1. Go to Google Cloud Console → **Credentials**
2. Look for the **Web application** credential you created in Step 3
3. **Copy the "Client ID"**

### 6b. Run Flutter with the Web Client ID

When you run the app on web, pass the client ID:

```bash
flutter run -d chrome --dart-define=GOOGLE_WEB_CLIENT_ID=YOUR_WEB_CLIENT_ID_HERE
```

Or for building web:
```bash
flutter build web --dart-define=GOOGLE_WEB_CLIENT_ID=YOUR_WEB_CLIENT_ID_HERE
```

---

## Summary of Credentials

| Platform | Credential | Where It Goes |
|----------|-----------|----------------|
| **Android** | `google-services.json` | `android/app/google-services.json` |
| **iOS** | `GoogleService-Info.plist` | `ios/Runner/GoogleService-Info.plist` |
| **iOS** | URL Scheme from REVERSED_CLIENT_ID | Xcode → Info tab → URL Types |
| **Web** | Web Client ID | Pass via `--dart-define=GOOGLE_WEB_CLIENT_ID=...` |

---

## Testing Google Sign-In

1. **Android**: `flutter run` (on Android device/emulator)
2. **iOS**: `flutter run` (on iOS device/simulator)
3. **Web**: `flutter run -d chrome --dart-define=GOOGLE_WEB_CLIENT_ID=...`

Tap the "Continue with Google" button → you should see the Google account picker.

---

## Troubleshooting

**"10: Developer error"** (Android)
- SHA-1 fingerprint doesn't match
- Run `./gradlew signingReport` again and verify you copied it correctly

**"URL Scheme not registered"** (iOS)
- Check that the REVERSED_CLIENT_ID URL scheme is added in Xcode Info.plist

**"Invalid Client ID"** (Web)
- Make sure you're passing the correct web client ID via `--dart-define`
- Verify the client ID matches what's in Google Cloud Console

---

## Notes

- **Android**: The `google-services.json` file contains all the info needed; no other setup required beyond build.gradle
- **iOS**: Both the `.plist` file AND the URL scheme in Info.plist are required
- **Web**: Only needs the client ID passed at runtime
- All credentials are public (OAuth 2.0 is designed this way) — don't worry about committing them to git if needed
