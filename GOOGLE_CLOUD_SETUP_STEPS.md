# Google Cloud Console Setup Steps

Detailed walkthrough for setting up your Google Cloud project for SSO.

---

## Section 1: Initial Google Cloud Setup

### Step 1.1: Create a Google Cloud Project

1. Go to https://console.cloud.google.com/
2. Sign in with your Google account (or create one)
3. At the top, click the project selector dropdown (shows "Select a Project" or a project name)
4. Click **"NEW PROJECT"**
5. Fill in:
   - **Project name**: `MedReminder` (or your app name)
   - **Organization**: Leave as is (or select if you have one)
6. Click **"CREATE"**
7. Wait 1-2 minutes for the project to load
8. Select the new project from the dropdown

---

### Step 1.2: Enable Required APIs

1. In the left sidebar, click **"APIs & Services"** → **"Library"**
2. Search for **"Google Identity Services"**
3. Click on **"Google Identity Services API"**
4. Click the **"ENABLE"** button (it's blue, top center)
5. Wait for it to enable (you'll see "API enabled" at top)

---

## Section 2: OAuth 2.0 Consent Screen (One-time Setup)

This happens only once per project.

1. In the left sidebar, go to **"APIs & Services"** → **"OAuth consent screen"**
2. Choose **"External"** (for external users) → **"CREATE"**
3. Fill in the form:
   - **App name**: `MedReminder`
   - **User support email**: Your email (e.g., `yourname@gmail.com`)
   - **Developer contact**: Your email again
4. Click **"SAVE AND CONTINUE"**
5. On **"Scopes"** page: Click **"SAVE AND CONTINUE"** (leave scopes as default)
6. On **"Test users"** page: Click **"SAVE AND CONTINUE"** (no need to add test users)
7. On summary page: Click **"BACK TO DASHBOARD"**

---

## Section 3: Create OAuth 2.0 Credentials

### Step 3.1: Web Application Credential (for Web & testing)

1. In the left sidebar, click **"APIs & Services"** → **"Credentials"**
2. Click **"+ CREATE CREDENTIALS"** → **"OAuth client ID"**
3. Choose **"Web application"**
4. Fill in:
   - **Name**: `Web Client`
   - **Authorized JavaScript origins**: (for now, skip this)
   - **Authorized redirect URIs**: (for now, skip this)
5. Click **"CREATE"**
6. A popup shows your credentials:
   - **Client ID**: `123456789-abcdefghijklmnop.apps.googleusercontent.com` ← **Copy this for web later**
   - **Client Secret**: (ignore for mobile apps)
7. Click **"OK"** to close

---

### Step 3.2: Android Credential

#### Step 3.2a: Get Your SHA-1 Fingerprint

First, you need your app's **SHA-1 certificate fingerprint**.

1. Open a terminal/PowerShell
2. Navigate to your project's `android` folder:
   ```bash
   cd android
   ```
3. Run:
   ```bash
   ./gradlew signingReport
   ```
4. Look for the output like:
   ```
   SHA-1: AB:CD:EF:12:34:56:78:90:AB:CD:EF:12:34:56:78:90:AB:CD:EF:12
   ```
5. **Copy the SHA-1 value** (including the colons)

#### Step 3.2b: Find Your Package Name

In your project:
1. Open `android/app/build.gradle`
2. Look for this line:
   ```gradle
   applicationId "com.example.medreminder"
   ```
3. Copy the package name: `com.example.medreminder`

#### Step 3.2c: Create Android Credential in Google Cloud

1. In Google Cloud Console → **Credentials**
2. Click **"+ CREATE CREDENTIALS"** → **"OAuth client ID"**
3. Choose **"Android"**
4. Fill in:
   - **Package name**: `com.example.medreminder` (from step 3.2b)
   - **SHA-1 certificate fingerprint**: Paste your SHA-1 (from step 3.2a)
5. Click **"CREATE"**
6. Note the OAuth 2.0 Client ID shown (you won't need it, but good to have)
7. Click **"OK"**

#### Step 3.2d: Download google-services.json

1. In Google Cloud Console → **Credentials**
2. Look for your **Android** credential (shows "Android" as the type)
3. Click the **three dots** (⋮) on the right → **"Download"**
   - (OR click the download icon if visible)
4. This downloads `google-services.json`
5. **Place this file in**: `android/app/google-services.json`

---

### Step 3.3: iOS Credential

#### Step 3.3a: Find Your Bundle ID

In Xcode or your project:
1. Open `ios/Runner.xcworkspace` (NOT `.xcodeproj`) in Xcode
2. In the left panel, click **"Runner"** (the blue project icon)
3. Select **"Runner"** (the target, in the main panel)
4. Go to the **"General"** tab
5. Find **"Bundle Identifier"** at the top (e.g., `com.example.medreminder`)
6. Copy it

OR, without Xcode:
1. Open `ios/Runner/Info.plist` in a text editor
2. Find the line: `<key>CFBundleIdentifier</key>`
3. Copy the value from the next line

#### Step 3.3b: Create iOS Credential in Google Cloud

1. In Google Cloud Console → **Credentials**
2. Click **"+ CREATE CREDENTIALS"** → **"OAuth client ID"**
3. Choose **"iOS"**
4. Fill in:
   - **Bundle ID**: `com.example.medreminder` (from step 3.3a)
   - **App Store ID**: Leave empty
   - **Team ID**: Leave empty
5. Click **"CREATE"**
6. Note the credentials shown
7. Click **"OK"**

#### Step 3.3c: Download GoogleService-Info.plist

1. In Google Cloud Console → **Credentials**
2. Look for your **iOS** credential
3. Click the **three dots** (⋮) → **"Download"**
4. This downloads `GoogleService-Info.plist`
5. **Place this file in Xcode**:
   - Open `ios/Runner.xcworkspace` in Xcode
   - In the left panel, right-click on **"Runner"** folder
   - Select **"Add Files to Runner..."**
   - Select the `GoogleService-Info.plist` file
   - Make sure **"Copy items if needed"** is checked
   - Click **"Add"**

#### Step 3.3d: Add URL Scheme

1. In Xcode, click **"Runner"** (blue project) in left panel
2. Select **"Runner"** (target) in the main panel
3. Go to **"Info"** tab
4. Scroll down to **"URL Types"** section
5. Click **"+"** to add a new URL type
6. In the new row, under **"URL Schemes"**, you need the **REVERSED_CLIENT_ID**:
   - Open the `GoogleService-Info.plist` file (double-click it in Xcode)
   - Find the key **"REVERSED_CLIENT_ID"**
   - Copy its value (e.g., `com.googleusercontent.apps.123456789-abcdefghijklmnop`)
7. Paste this value in the **"URL Schemes"** field in the Info tab
8. Save (Cmd+S)

---

## Section 4: Verify All Credentials Are Set Up

### Android
- [ ] `android/app/google-services.json` exists
- [ ] `android/build.gradle` has `classpath 'com.google.gms:google-services:4.4.1'`
- [ ] `android/app/build.gradle` has `apply plugin: 'com.google.gms.google-services'` at the bottom

### iOS
- [ ] `ios/Runner/GoogleService-Info.plist` exists in Xcode (you can see it in left panel)
- [ ] URL Scheme added in Xcode (Info tab → URL Types)

### Web
- [ ] You have copied your **Web Client ID** from Google Cloud Console

---

## Section 5: Test Each Platform

### Android
```bash
flutter run
```
- The app should start on your Android device/emulator
- Tap "Continue with Google"
- You should see the Google account picker
- Select your Google account
- You should be logged in

### iOS
```bash
flutter run
```
- The app should start on your iOS device/simulator
- Same as Android, tap "Continue with Google"

### Web
```bash
flutter run -d chrome --dart-define=GOOGLE_WEB_CLIENT_ID=123456789-abcdefghijklmnop.apps.googleusercontent.com
```
(Replace with your actual Web Client ID)

---

## Common Mistakes to Avoid

1. **SHA-1 fingerprint doesn't match**
   - Make sure you ran `./gradlew signingReport` from the `android/` folder
   - Don't copy extra spaces

2. **"API not enabled" error**
   - Go back to APIs & Services → Library
   - Make sure you enabled "Google Identity Services API"

3. **Consent screen not configured**
   - Go to OAuth consent screen in Google Cloud Console
   - Fill it out once (even if you skip all optional fields)

4. **Android app crashes on Google button**
   - Check that `google-services.json` is in the correct location: `android/app/`
   - Check that the build.gradle files were updated correctly

5. **iOS keeps asking for permission**
   - Make sure the URL Scheme (REVERSED_CLIENT_ID) is added in Xcode Info.plist

6. **Web says "Invalid Client"**
   - Make sure you're using the Web Client ID (not Android or iOS)
   - Make sure you passed it correctly: `--dart-define=GOOGLE_WEB_CLIENT_ID=...`

---

## Need Help?

- Check GOOGLE_CREDENTIALS_REFERENCE.md to see what credentials look like
- Check GOOGLE_SSO_SETUP.md for the big picture
- If stuck, check the error message in the console — it usually tells you what's wrong
