# MedReminder Intelligent

A Flutter mobile app that reminds you to take your medications **and**
automatically detects dangerous drug-drug interactions.

## Features

- Add medications with dosage, daily reminder time, and notes
- **Drug name autocomplete** powered by the [OpenFDA Drug Label API](https://open.fda.gov/apis/drug/label/) (free, no API key)
- **Live interaction warnings** while you type a new medication
- Dedicated screen listing all detected interactions with severity (severe / moderate / mild)
- Daily local notifications (no internet required to trigger)
- Clean Material 3 UI with Google Fonts (Inter)
- All data stored locally on the device (SharedPreferences)

## API used

| API                              | Used for                  | Cost        |
| -------------------------------- | ------------------------- | ----------- |
| **OpenFDA Drug Label** (api.fda.gov) | Drug name autocomplete + warnings/purpose info | Free, no key |
| **Local interactions DB** (`assets/interactions.json`) | Drug-drug interaction detection | Bundled |

Why a bundled interaction database? Real DDI APIs (DrugBank, Medi-Span,
First DataBank) all require paid licenses, and NIH's free RxNav DDI
endpoint was retired in January 2024. Real-world med-reminder apps
solve this exactly the same way: a curated local DB. You can add more
interactions by editing [assets/interactions.json](assets/interactions.json).

## Project structure

```
lib/
├── main.dart                       # App entry + Material 3 theme
├── models/
│   ├── medication.dart             # Medication data class
│   └── interaction.dart            # Interaction data class
├── services/
│   ├── medication_service.dart     # Save/load medications
│   ├── drug_api_service.dart       # OpenFDA API calls
│   ├── interaction_service.dart    # Check meds against DB
│   └── notification_service.dart   # Daily reminders
├── screens/
│   ├── home_screen.dart            # Medication list
│   ├── add_medication_screen.dart  # Add form with live API search
│   ├── medication_detail_screen.dart
│   └── interactions_screen.dart
└── widgets/
    ├── medication_card.dart
    └── severity_chip.dart
```

## How to run

### 1. Install Flutter

Download from <https://docs.flutter.dev/get-started/install>.
Verify it's working:
```bash
flutter --version
flutter doctor
```

### 2. Generate the platform folders

This project ships with `lib/`, `assets/` and `pubspec.yaml` only. Run
this once **inside the project folder** to create `android/`, `ios/`,
`web/`, etc.:
```bash
cd c:/Users/Yahia/Desktop/flutterproj
flutter create .
```

### 3. Install dependencies

```bash
flutter pub get
```

### 4. (Android only) Add the notification permissions

Open `android/app/src/main/AndroidManifest.xml` and add these lines
**inside the `<manifest>` tag**, right above `<application>`:

```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.USE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
```

Then **inside the `<application>` tag**, add the receivers required by
`flutter_local_notifications`:

```xml
<receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />
<receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
    <intent-filter>
        <action android:name="android.intent.action.BOOT_COMPLETED"/>
        <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
        <action android:name="android.intent.action.QUICKBOOT_POWERON"/>
        <action android:name="com.htc.intent.action.QUICKBOOT_POWERON"/>
    </intent-filter>
</receiver>
```

In `android/app/build.gradle`, make sure `minSdkVersion` is at least
`21` and `compileSdkVersion`/`targetSdkVersion` are `34` or higher.

### 5. Run the app

Connect a phone (with USB debugging) or start an emulator, then:
```bash
flutter run
```

To build a release APK:
```bash
flutter build apk --release
```

The APK appears at `build/app/outputs/flutter-apk/app-release.apk`.

## Try it out

Once the app is running, add these three medications to see the
interaction detection in action:

1. **Warfarin** – 5 mg – 08:00
2. **Aspirin** – 100 mg – 12:00
3. **Ibuprofen** – 200 mg – 20:00

You should immediately see a red banner saying **"3 interactions
detected"**. Tap it to read the severity and explanation for each pair.

## Notes for development

- All code is plain `setState` (no Provider / Bloc / Riverpod) so it's
  easy to read for a junior developer.
- Each service is independent and can be tested in isolation.
- To add more drug interactions, just append to
  [assets/interactions.json](assets/interactions.json) — names must be
  lowercase generic names.
- The OpenFDA API is rate limited to ~240 requests/minute without a
  key, which is plenty for personal use. If you want a higher limit,
  request a free API key at <https://open.fda.gov/apis/authentication/>
  and add `&api_key=YOUR_KEY` in `lib/services/drug_api_service.dart`.

## Disclaimer

This app is an **educational project**. It must not be used as a
substitute for medical advice. Always consult a qualified healthcare
professional before changing any medication.
