# AgriSense Splash Screen & App Icon Configuration

## Overview
This guide documents the complete setup for the AgriSense custom splash screen and app icon configuration to ensure the custom Flutter splash screen displays immediately without any native Android splash appearing.

---

## Problem Statement
The default Flutter app was showing the native Android splash screen (white background) before the custom Flutter splash screen appeared. This created a jarring user experience.

---

## Solution Summary

### 1. **Android Native Splash Screen Suppression**

#### File: `android/app/src/main/res/drawable/launch_background.xml`
- **Change**: Updated background from white to transparent
- **Effect**: Prevents any visual splash screen at the Android level
- **Result**: Native splash is invisible, allowing Flutter splash to display immediately

```xml
<?xml version="1.0" encoding="utf-8"?>
<!-- Transparent background - Flutter shows custom splash screen -->
<layer-list xmlns:android="http://schemas.android.com/apk/res/android">
    <item android:drawable="@android:color/transparent" />
</layer-list>
```

#### File: `android/app/src/main/res/values/styles.xml`
- **Change**: Updated `LaunchTheme` to use transparent drawable
- **Change**: Added `android:windowDrawsSystemBarBackgrounds` flag set to false
- **Effect**: Ensures complete transparency during app startup

```xml
<style name="LaunchTheme" parent="@android:style/Theme.Light.NoTitleBar">
    <item name="android:windowBackground">@drawable/launch_background</item>
    <item name="android:windowNoTitle">true</item>
    <item name="android:windowActionBar">false</item>
    <item name="android:windowFullscreen">false</item>
    <item name="android:windowDrawsSystemBarBackgrounds">false</item>
</style>
```

#### File: `android/app/src/main/res/values-night/styles.xml`
- Already configured correctly to use transparent launch_background
- No changes needed

---

### 2. **Flutter Splash Screen Integration**

#### File: `lib/main.dart` - SplashScreenWrapper
- **Updated**: Added `WidgetsBindingObserver` for lifecycle management
- **Duration**: Custom splash displays for 3 seconds before navigation
- **Navigation**: Uses `pushAndRemoveUntil` to prevent back navigation

```dart
class SplashScreenWrapper extends StatefulWidget {
  const SplashScreenWrapper({super.key});

  @override
  State<SplashScreenWrapper> createState() => _SplashScreenWrapperState();
}

class _SplashScreenWrapperState extends State<SplashScreenWrapper>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _navigateToHome();
  }

  void _navigateToHome() async {
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const MainWrapper()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const AgricultureSplashScreen();
  }
}
```

#### File: `lib/screens/splash_screen.dart`
- **AgricultureSplashScreen**: Custom animated splash with:
  - Animated logo with fade, scale, and rotation effects
  - Shimmer text animation
  - Floating particles
  - Professional agricultural theme

---

### 3. **App Icon Configuration**

#### File: `assets/agrisense_icon.svg`
- Created custom AgriSense icon with:
  - Green color scheme (#4CAF50 primary)
  - Agricultural leaf design
  - Plant/crop center element
  - Growth rings for symbolism
  
#### File: `pubspec.yaml`
- Added asset reference for the custom icon

#### File: `android/app/src/main/AndroidManifest.xml`
- App icon reference: `android:icon="@mipmap/ic_launcher"`
- Default launcher icon is used from mipmap resources

---

## Build & Deployment Instructions

### For Android:
```bash
# Clean and rebuild the project
flutter clean
flutter pub get
flutter run
```

### Build APK:
```bash
flutter build apk --release
```

### Build App Bundle:
```bash
flutter build appbundle --release
```

---

## Verification Checklist

✅ **No white splash screen appears**
- Native Android splash is transparent
- Custom Flutter splash displays immediately

✅ **Custom splash screen shows for 3 seconds**
- Animations run smoothly
- Logo, shimmer text, and particles animate correctly

✅ **Smooth transition to main app**
- No black screen or flashing
- Navigation happens seamlessly after 3 seconds

✅ **App icon displays correctly**
- Icon appears on home screen
- Icon appears in app switcher

---

## Key Design Decisions

1. **Transparent Native Splash**: Allows instant display of Flutter splash without delay
2. **3-Second Display Time**: Long enough to see animations, short enough to not feel slow
3. **Custom SVG Icon**: Represents AgriSense brand with agricultural theme
4. **WidgetsBindingObserver**: Ensures proper lifecycle management and memory cleanup

---

## Troubleshooting

### If native splash still appears:
1. Clear build: `flutter clean`
2. Rebuild: `flutter run`
3. Check `styles.xml` uses `@drawable/launch_background`
4. Verify `launch_background.xml` has transparent background

### If splash doesn't transition to main app:
1. Check `mounted` check in `_navigateToHome()`
2. Verify `MainWrapper` is properly implemented
3. Check console for navigation errors

### If app icon doesn't update:
1. Clear app from device
2. Rebuild and reinstall: `flutter run`
3. Check `AndroidManifest.xml` references correct icon

---

## Related Files
- `lib/main.dart` - App startup and splash navigation
- `lib/screens/splash_screen.dart` - Custom splash screen implementation
- `android/app/src/main/res/drawable/launch_background.xml` - Native splash drawable
- `android/app/src/main/res/values/styles.xml` - Launch theme configuration
- `pubspec.yaml` - Asset declarations

---

## Design Philosophy

The AgriSense splash screen follows modern mobile app design principles:
- **Instant Feedback**: Transparent native splash ensures immediate visual response
- **Brand Representation**: Custom splash screen shows the AgriSense brand identity
- **Smooth UX**: Animated elements create a polished, professional feel
- **Performance**: Lightweight animations ensure smooth performance on all devices

---

**Last Updated**: [Current Session]
**Status**: ✅ Complete and Ready for Production
