# Flutter Apps Setup Guide

## Overview

Two Flutter apps for Localboy:
1. **Tourist App** (`localboy-frontend`) - For tourists to book guides/drivers
2. **Driver App** (`localboy-driver`) - For drivers and guides

Both apps now use **OpenStreetMap** (flutter_map) instead of Google Maps.

---

## ✅ Prerequisites

### Required
- **Flutter SDK**: 3.0+
  ```bash
  flutter --version
  ```
- **Android SDK** (for Android build)
  ```bash
  flutter doctor
  ```
- **Xcode** (for iOS, Mac only)

### Verify Setup
```bash
flutter doctor
```
Should show all checkmarks ✓

---

## 📱 Tourist App (localboy-frontend)

### Step 1: Setup Project

```bash
cd localboy-frontend

# Get dependencies (including new flutter_map)
flutter pub get

# Check analysis
flutter analyze
```

### Step 2: Configure Environment

Create `.env` file:
```
API_BASE_URL=http://localhost:3000/api
FIREBASE_PROJECT_ID=your_firebase_project

# For release builds
API_BASE_URL_PROD=https://api.localboy.com/api
```

Load it in `lib/config/config.dart`:
```dart
class Config {
  static const String apiBaseUrl = 'http://localhost:3000/api';
  // ... other configs
}
```

### Step 3: Android Configuration

**File:** `android/app/build.gradle`
- Ensure `minSdkVersion 21` or higher
- Ensure `compileSdkVersion 34`

**File:** `android/app/src/main/AndroidManifest.xml`
- Already configured (Google Maps metadata removed)

**Required Permissions:**
```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
```

### Step 4: iOS Configuration

**File:** `ios/Podfile`
```ruby
post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    target.build_configurations.each do |config|
      config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= [
        '$(inherited)',
        'PERMISSION_CAMERA=1',
        'PERMISSION_LOCATION=1',
      ]
    end
  end
end
```

**Required Permissions** - `ios/Runner/Info.plist`:
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>We need your location to show nearby attractions</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>We need your location for real-time tracking</string>
<key>NSCameraUsageDescription</key>
<string>We need camera access for profile photos</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>We need access to your photos</string>
```

### Step 5: Firebase Setup (Authentication)

1. Create Firebase project: https://console.firebase.google.com
2. Add Android & iOS apps
3. Download and place config files:
   - Android: `android/app/google-services.json`
   - iOS: `ios/Runner/GoogleService-Info.plist`

4. Initialize in `main.dart`:
```dart
import 'firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}
```

### Step 6: Maps Migration (OpenStreetMap)

Update screens that use maps. Old GoogleMap code needs to be replaced with flutter_map.

**Example - Trip Map Screen:**
```dart
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong2.dart';

class TripMapScreen extends StatelessWidget {
  final List<LatLng> route = [
    const LatLng(15.3, 73.8),
    const LatLng(15.4, 73.85),
  ];

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      options: MapOptions(
        initialCenter: const LatLng(15.35, 73.825),
        initialZoom: 13.0,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.localboy.tourist',
        ),
        PolylineLayer(
          polylines: [
            Polyline(
              points: route,
              color: Colors.blue,
              strokeWidth: 4.0,
            ),
          ],
        ),
        MarkerLayer(
          markers: [
            Marker(
              point: route.first,
              width: 80,
              height: 80,
              child: Icon(Icons.location_on, color: Colors.green),
            ),
            Marker(
              point: route.last,
              width: 80,
              height: 80,
              child: Icon(Icons.location_on, color: Colors.red),
            ),
          ],
        ),
      ],
    );
  }
}
```

### Step 7: Run on Android

```bash
# List available devices
flutter devices

# Run on device/emulator
flutter run -d <device_id>

# Or specific device
flutter run -d emulator-5554

# Release build (generates APK)
flutter build apk --release
```

APK will be at: `build/app/outputs/flutter-apk/app-release.apk`

### Step 8: Run on iOS

```bash
# Open iOS app and install pods
cd ios
pod install
cd ..

# Run on device
flutter run -d <device_id>

# Build for release (generates IPA)
flutter build ipa --release
```

---

## 👨‍💼 Driver App (localboy-driver)

### Same steps as Tourist App:

```bash
cd ../localboy-driver

flutter pub get
flutter analyze
```

### Key differences from Tourist App:
- No Firebase Auth (uses same backend auth as tourist)
- Focus on location tracking
- Real-time trip status updates
- Driver/guide availability management

### Run:
```bash
flutter run -d <device_id>
flutter build apk --release
```

---

## 🔒 Security Checklist

- [ ] Don't commit `.env` or config files with secrets
- [ ] Use environment-specific configs
- [ ] Validate all API responses
- [ ] Store auth tokens securely (use `secure_storage` package)
- [ ] Implement certificate pinning for production
- [ ] Code obfuscation for release builds

### Implement Secure Storage:
```bash
flutter pub add flutter_secure_storage
```

```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const secureStorage = FlutterSecureStorage();

// Save token securely
await secureStorage.write(key: 'authToken', value: token);

// Retrieve token
final token = await secureStorage.read(key: 'authToken');
```

---

## 📊 Building for Production

### Android Release

```bash
# Generate keystore
keytool -genkey -v -keystore ~/localboy.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias localboy -storepass password123 -keypass password123

# Sign and build
flutter build apk --release \
  -t lib/main_prod.dart
```

### iOS Release

```bash
flutter build ipa --release
# Upload to App Store Connect
```

---

## 🧪 Testing

### Unit Tests
```bash
flutter test
```

### Integration Tests
```bash
flutter drive --target=test_driver/main_test.dart
```

### Manual Testing Checklist
- [ ] User registration & login
- [ ] Phone OTP verification
- [ ] Browse attractions (POIs)
- [ ] Book a trip
- [ ] Real-time location tracking
- [ ] Chat/messages
- [ ] Payment flow
- [ ] Ratings & reviews

---

## 📦 App Store Distribution

### Android (Google Play)

1. Create Google Play account ($25)
2. Generate signed APK/AAB:
   ```bash
   flutter build appbundle --release
   # Generates app-release.aab
   ```
3. Upload to Google Play Console
4. Fill in store listing, screenshots, etc.

### iOS (Apple App Store)

1. Get Apple Developer account ($99/year)
2. Generate IPA:
   ```bash
   flutter build ipa --release
   ```
3. Upload via App Store Connect
4. Submit for review (takes 24-48 hours)

---

## Common Issues & Solutions

### Issue: "Doctor" shows ❌
```
flutter doctor --android-licenses
flutter doctor
```

### Issue: Build fails with "Pod install" error
```bash
cd ios
rm -rf Pods
rm Podfile.lock
pod install
cd ..
flutter clean
flutter pub get
flutter build ios
```

### Issue: "Failed to build for device" on iOS
```bash
flutter clean
cd ios
rm -rf Pods Podfile.lock
pod install
cd ..
flutter build ios
```

### Issue: Maps not loading on device
- Ensure internet permission is granted
- Check API key (OpenStreetMap - no key needed)
- Test with `flutter logs`

### Issue: Location always fails
```bash
# Grant location permission at runtime
# Check in app settings
```

---

## 💡 Performance Tips

1. **Lazy load images**: Use `cached_network_image`
2. **Minimize rebuild**: Use `const` constructor
3. **Optimize list rendering**: Use `ListView.builder`
4. **Profile app**: `flutter run --profile`
5. **Enable release mode for testing**: `flutter run --release`

---

## 📚 Resources

- [Flutter Official Docs](https://flutter.dev/docs)
- [flutter_map Documentation](https://github.com/fleaflet/flutter_map)
- [OpenStreetMap Tiles](https://wiki.openstreetmap.org/wiki/Tiles)
- [Firebase for Flutter](https://firebase.flutter.dev/)
- [Dart Language Tour](https://dart.dev/guides/language/language-tour)

---

## Quick Reference

| Task | Command |
|------|---------|
| Get dependencies | `flutter pub get` |
| Analyze code | `flutter analyze` |
| Format code | `dart format -r lib/` |
| Run dev mode | `flutter run -d <device>` |
| Build Android APK | `flutter build apk --release` |
| Build iOS IPA | `flutter build ipa --release` |
| Clean project | `flutter clean` |
| Update packages | `flutter pub upgrade` |
| Run tests | `flutter test` |
| Check setup | `flutter doctor` |

---

**Status:** Ready for Development
**Last Updated:** May 3, 2026
**Apps Updated:** ✅ Dependencies replaced (Google Maps → OpenStreetMap)
