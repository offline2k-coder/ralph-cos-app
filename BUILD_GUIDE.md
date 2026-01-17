# How to Build Ralph-CoS App Locally

## Prerequisites

### 1. Install Flutter
```bash
# macOS (using Homebrew)
brew install flutter

# Or download from: https://docs.flutter.dev/get-started/install
```

### 2. Install Android Studio
1. Download from: https://developer.android.com/studio
2. Install Android SDK (API level 21 or higher)
3. Install Android SDK Build-Tools

### 3. Set up Android SDK
```bash
# Set ANDROID_HOME environment variable
export ANDROID_HOME=$HOME/Library/Android/sdk
export PATH=$PATH:$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools
```

Add to your `~/.zshrc` or `~/.bashrc` to make permanent.

### 4. Verify Flutter Installation
```bash
flutter doctor

# Should show:
# ✓ Flutter
# ✓ Android toolchain
# ✓ Android Studio
```

---

## Building the App

### Navigate to Project Directory
```bash
cd /Users/joerg/development/ralph-cos-app
```

### Option 1: Debug Build (Fastest)
```bash
flutter build apk --debug
```

**Output:** `build/app/outputs/flutter-apk/app-debug.apk`

**Size:** ~50-60 MB
**Use for:** Testing, development
**Includes:** Debug symbols, logging

### Option 2: Release Build (Optimized)
```bash
flutter build apk --release
```

**Output:** `build/app/outputs/flutter-apk/app-release.apk`

**Size:** ~20-30 MB (smaller!)
**Use for:** Production, distribution
**Optimizations:** Code minification, obfuscation

### Option 3: Split APKs (Smaller Downloads)
```bash
flutter build apk --split-per-abi
```

**Outputs:**
- `app-armeabi-v7a-release.apk` (ARM 32-bit)
- `app-arm64-v8a-release.apk` (ARM 64-bit) ← **Most devices**
- `app-x86_64-release.apk` (Intel 64-bit)

**Use for:** Google Play Store uploads

---

## Installing on Device

### Via USB (Recommended)
```bash
# Connect your Android phone via USB
# Enable Developer Options and USB Debugging on phone

# Check device is connected
adb devices

# Install APK
adb install build/app/outputs/flutter-apk/app-debug.apk

# Or for release
adb install build/app/outputs/flutter-apk/app-release.apk
```

### Via File Transfer
1. Copy APK to phone (USB, email, cloud)
2. On phone: Open file manager
3. Tap APK file
4. Allow "Install from unknown sources" if prompted
5. Tap "Install"

---

## Running in Development Mode

### Start Emulator
```bash
# List available emulators
flutter emulators

# Start an emulator
flutter emulators --launch <emulator_id>
```

### Run App with Hot Reload
```bash
# Connect device or start emulator first
flutter run

# Now you can:
# - Press 'r' to hot reload
# - Press 'R' to hot restart
# - Press 'q' to quit
```

---

## Common Issues & Fixes

### Issue: "Flutter not found"
```bash
# Add Flutter to PATH
export PATH="$PATH:/path/to/flutter/bin"

# Or reinstall via Homebrew
brew install flutter
```

### Issue: "Android SDK not found"
```bash
# Set ANDROID_HOME
export ANDROID_HOME=$HOME/Library/Android/sdk

# Or open Android Studio → Preferences → Android SDK
```

### Issue: "Gradle build failed"
```bash
# Clean build
flutter clean

# Get dependencies
flutter pub get

# Rebuild
flutter build apk --debug
```

### Issue: "Version conflicts"
```bash
# Update Flutter
flutter upgrade

# Update dependencies
flutter pub upgrade
```

### Issue: "Device not found"
```bash
# Check ADB connection
adb devices

# If empty, reconnect USB or restart ADB
adb kill-server
adb start-server
```

---

## Project Structure

```
ralph-cos-app/
├── android/                    # Android platform code
│   ├── app/
│   │   ├── build.gradle.kts   # Build configuration
│   │   └── src/main/
│   │       ├── AndroidManifest.xml  # Permissions
│   │       └── kotlin/              # MainActivity
├── lib/                       # Flutter Dart code
│   ├── main.dart             # Entry point
│   ├── models/               # Data models
│   ├── screens/              # UI screens
│   └── services/             # Business logic
├── ralph_personality/        # Dan Koe article
├── pubspec.yaml              # Dependencies
└── build/                    # Build outputs (generated)
```

---

## Build Configuration

### Minimum SDK Version
Set in `android/app/build.gradle.kts`:
```kotlin
minSdk = 21  // Android 5.0 and above
```

### App Name & Package
**Package:** `com.ralphcos.app`
**App Name:** `ralph_cos_app`

Change in:
- `android/app/build.gradle.kts` → `applicationId`
- `android/app/src/main/AndroidManifest.xml` → `android:label`

### Signing (For Release)
Create `android/key.properties`:
```properties
storePassword=<your-password>
keyPassword=<your-password>
keyAlias=upload
storeFile=<path-to-keystore>
```

Then update `android/app/build.gradle.kts` to use it.

---

## Dependencies

All dependencies are in `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  local_auth: ^3.0.0              # Biometric auth
  sqflite: ^2.4.2                 # Local database
  flutter_secure_storage: ^10.0.0 # Encrypted storage
  flutter_local_notifications: ^19.5.0  # Notifications
  workmanager: ^0.9.0+3           # Background tasks
  http: ^1.6.0                    # HTTP requests
  google_generative_ai: ^0.4.6   # Gemini AI
  # ... and more
```

### Installing Dependencies
```bash
flutter pub get
```

---

## Testing

### Run Tests
```bash
flutter test
```

### Check for Issues
```bash
flutter analyze
```

### Check Performance
```bash
flutter run --profile
```

---

## Build Variants

### Debug (Development)
```bash
flutter build apk --debug
```
- Includes debugging tools
- Larger file size
- No code obfuscation

### Profile (Performance Testing)
```bash
flutter build apk --profile
```
- Performance profiling enabled
- Some optimizations
- Can measure app performance

### Release (Production)
```bash
flutter build apk --release
```
- Fully optimized
- Code obfuscated
- Smallest file size
- No debugging

---

## Deployment Checklist

Before distributing:
- [ ] Update version in `pubspec.yaml`
- [ ] Build release APK
- [ ] Test on multiple devices
- [ ] Verify all features work
- [ ] Check permissions are justified
- [ ] Update CHANGELOG.md
- [ ] Create GitHub release tag
- [ ] Sign APK for distribution

---

## Quick Reference

```bash
# Build debug APK
flutter build apk --debug

# Install on connected device
adb install build/app/outputs/flutter-apk/app-debug.apk

# Run with hot reload
flutter run

# Clean and rebuild
flutter clean && flutter pub get && flutter build apk --debug

# Check what's wrong
flutter doctor -v
```

---

## APK Location

After building, find APKs at:

**Debug:**
`build/app/outputs/flutter-apk/app-debug.apk`

**Release:**
`build/app/outputs/flutter-apk/app-release.apk`

**Split (Release):**
```
build/app/outputs/flutter-apk/
├── app-armeabi-v7a-release.apk
├── app-arm64-v8a-release.apk
└── app-x86_64-release.apk
```

---

## Build Time

| Build Type | Approx. Time | File Size |
|-----------|--------------|-----------|
| Debug (first) | 2-3 minutes | 50-60 MB |
| Debug (incremental) | 5-10 seconds | 50-60 MB |
| Release | 3-5 minutes | 20-30 MB |

---

## Next Steps

1. **Build the app:** `flutter build apk --debug`
2. **Install on phone:** `adb install build/app/outputs/flutter-apk/app-debug.apk`
3. **Set up GitHub token** in app Settings
4. **Start tracking** your discipline journey!

---

**Need help?** Check `flutter doctor` for diagnostics.
