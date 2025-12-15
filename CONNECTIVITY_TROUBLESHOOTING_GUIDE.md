# APK Connectivity Troubleshooting Guide

## Problem Summary
Your APK app cannot access:
1. **Camera stream** (video feed from Flask server)
2. **Database** (Supabase)

But the browser on the tablet **CAN** access the video stream.

---

## Root Causes & Solutions

### 🔴 Issue 1: Network Configuration in APK

**Problem:** The APK uses environment variables from `.env` file at build time, but `.env` may NOT be included in the APK release build.

**Current Configuration (in `lib/main.dart` and `lib/detection_service.dart`):**
```dart
String _streamUrl = "${dotenv.env['DETECTION_SERVER_URL'] ?? 'http://192.168.8.6:5000'}/video_feed";
final serverUrl = dotenv.env['DETECTION_SERVER_URL'] ?? 'http://192.168.8.6:5000';
```

**Why it fails in APK:**
- Release APK strips unnecessary files
- The `.env` file might not be properly bundled in the APK
- Falls back to hardcoded IP `192.168.8.6` which may be:
  - Incorrect for your current network setup
  - Not accessible from the tablet's network context
  - Based on your laptop's local IP at build time

**Solution Steps:**

#### Step 1: Verify `.env` is included in APK
Check `pubspec.yaml`:
```yaml
flutter:
  assets:
    - .env          # ✅ This MUST be present
    - assets/app logo.png
```

#### Step 2: Update `.env` with correct server address

Open `.env` and update with your **laptop's current IP address**:
```bash
# Find your laptop IP
# Windows: Open CMD and type: ipconfig
# Look for IPv4 Address under your active network adapter
```

Example:
```properties
DETECTION_SERVER_URL=http://192.168.x.x:5000
```

#### Step 3: Ensure Flask server is accessible on network

Run your Flask server with:
```bash
python app.py --host 0.0.0.0 --port 5000
```

Test from tablet browser:
```
http://192.168.x.x:5000/health
http://192.168.x.x:5000/video_feed
```

---

### 🔴 Issue 2: Android Network Security Configuration

**Problem:** Release APK may have stricter network security policies.

**Solution:**

Create/Update `android/app/src/main/AndroidManifest.xml`:
```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
    <uses-permission android:name="android.permission.CAMERA" />
    
    <!-- Other configuration -->
</manifest>
```

Create `android/app/src/main/res/xml/network_security_config.xml`:
```xml
<?xml version="1.0" encoding="utf-8"?>
<network-security-config>
    <!-- Allow cleartext traffic for local development -->
    <domain-config cleartextTrafficPermitted="true">
        <domain includeSubdomains="true">192.168.0.0</domain>
        <domain includeSubdomains="true">10.0.0.0</domain>
        <domain includeSubdomains="true">127.0.0.1</domain>
    </domain-config>
</network-security-config>
```

Update `AndroidManifest.xml` to reference it:
```xml
<application
    android:label="agrisense"
    android:name="${applicationName}"
    android:icon="@mipmap/ic_launcher"
    android:networkSecurityConfig="@xml/network_security_config">
```

---

### 🔴 Issue 3: Camera Permission Not Granted

**Problem:** APK lacks proper camera permissions for release build.

**Current Status:** Your `AndroidManifest.xml` is missing camera permissions.

**Solution:**

Update `android/app/src/main/AndroidManifest.xml`:
```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- ADD THESE PERMISSIONS -->
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
    <uses-permission android:name="android.permission.CAMERA" />
    
    <application>
        <!-- existing content -->
    </application>
</manifest>
```

However, **note:** Your app uses MJPEG stream from Flask (not device camera), so camera permission may not be critical unless you're capturing photos.

---

### 🔴 Issue 4: Database (Supabase) Connection

**Problem:** APK cannot connect to Supabase database.

**Causes:**
1. Network configuration same as above (cleartext traffic restriction)
2. Supabase credentials in `.env` not included in APK

**Solution:**

Verify in `.env`:
```properties
SUPABASE_URL=https://iwbftcnzcuhdapjxrlhe.supabase.co
SUPABASE_ANON_KEY=sb_publishable_kKNvrSZqF98IAPkKGW_fdg_GqttByHO
```

These should load properly since Supabase uses HTTPS (already secure).

**Test:** Add debug logging in `lib/main.dart`:
```dart
// After initializing Supabase
print('✅ Supabase URL: ${dotenv.env['SUPABASE_URL']}');
print('✅ Supabase Key: ${dotenv.env['SUPABASE_ANON_KEY']?.substring(0, 20)}...');
```

---

## Complete Fix Checklist

- [ ] 1. Update `.env` with correct laptop IP address
- [ ] 2. Verify `.env` is in `pubspec.yaml` assets
- [ ] 3. Add `network_security_config.xml` for cleartext traffic
- [ ] 4. Update `AndroidManifest.xml` with required permissions
- [ ] 5. Run: `flutter clean && flutter pub get`
- [ ] 6. Rebuild APK: `flutter build apk --release`
- [ ] 7. Test on tablet:
  - [ ] Test video stream: `http://192.168.x.x:5000/video_feed`
  - [ ] Test database queries in app
  - [ ] Check logs: `flutter logs` while app runs

---

## Step-by-Step Build & Install

```bash
# 1. Clean previous builds
flutter clean

# 2. Get dependencies
flutter pub get

# 3. Build release APK
flutter build apk --release

# 4. Install on tablet (ensure tablet connected via adb)
flutter install

# 5. View logs
flutter logs
```

---

## Testing Video Stream Directly

From tablet browser:
```
http://<LAPTOP_IP>:5000/health
http://<LAPTOP_IP>:5000/video_feed
```

If these work in browser but not in APK, the issue is Android network security config.

---

## Finding Your Laptop IP Address

**Windows CMD:**
```batch
ipconfig
```

Look for: `IPv4 Address . . . . . . . . . . . . : 192.168.x.x`

**Verify connectivity from tablet:**
```
ping 192.168.x.x
```

---

## Common Mistakes

❌ **Wrong IP in `.env`** - If you rebuilt your network, your laptop IP changed
❌ **Flask running with `localhost:5000`** - App can't access localhost from tablet
❌ **Network security config missing** - Blocks HTTP (non-HTTPS) requests
❌ **Permissions not declared** - APK fails silently
❌ **`.env` not in assets** - Environment variables empty in APK

---

## Key Insight: Why Browser Works But APK Doesn't

1. **Browser directly accesses HTTP** - No Android security restrictions apply
2. **APK has Network Security Policy** - Restricts cleartext traffic by default in release builds
3. **APK reads from `.env` at build time** - Not dynamically loaded like browser

The fix is to properly configure Android's network security and ensure `.env` is bundled.
