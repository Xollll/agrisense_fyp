# Files Modified - Exact Changes Made

## Summary of Changes

This document shows EXACTLY what was changed to fix APK connectivity issues.

---

## 1. ✅ MODIFIED: `android/app/src/main/AndroidManifest.xml`

### What Changed:
- Added 3 permission declarations
- Added `android:networkSecurityConfig` reference to `<application>` tag

### Before:
```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <application
        android:label="agrisense"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher">
```

### After:
```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- Internet and Network Permissions -->
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
    <uses-permission android:name="android.permission.CAMERA" />

    <application
        android:label="agrisense"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher"
        android:networkSecurityConfig="@xml/network_security_config">
```

### Why:
- `INTERNET` permission: Allows APK to make network requests to Flask
- `ACCESS_NETWORK_STATE`: Allows checking network connectivity status
- `CAMERA`: Allows camera access (if needed for device camera)
- `android:networkSecurityConfig`: References the security policy file that allows local HTTP

---

## 2. ✅ CREATED: `android/app/src/main/res/xml/network_security_config.xml` (NEW FILE)

### What It Does:
Tells Android to allow cleartext (HTTP) traffic to local IP addresses and localhost. Without this file, Android 9+ blocks HTTP requests by default.

### File Contents:
```xml
<?xml version="1.0" encoding="utf-8"?>
<network-security-config>
    <!-- Allow cleartext traffic for local network development -->
    <!-- This enables HTTP (non-HTTPS) requests to local server -->
    <domain-config cleartextTrafficPermitted="true">
        <!-- Local network ranges -->
        <domain includeSubdomains="true">192.168.0.0</domain>
        <domain includeSubdomains="true">192.168.1.0</domain>
        <domain includeSubdomains="true">192.168.8.0</domain>
        <domain includeSubdomains="true">10.0.0.0</domain>
        <domain includeSubdomains="true">172.16.0.0</domain>
        <domain includeSubdomains="true">127.0.0.1</domain>
        <domain includeSubdomains="true">localhost</domain>
    </domain-config>

    <!-- HTTPS (Supabase and other cloud services) - always permitted -->
    <!-- No additional config needed for HTTPS -->
</network-security-config>
```

### Explanation:
- `cleartextTrafficPermitted="true"` = Allow unencrypted HTTP traffic
- `<domain>` entries = Whitelist of IP ranges allowed for HTTP
- Covers all common local network ranges (192.168.x.x, 10.x.x.x, 127.0.0.1)

### Why This File:
Android 9+ (API 28+) restricts cleartext (HTTP) traffic for security. Your Flask server runs on HTTP port 5000. This config tells Android: "These local IPs can use HTTP (Flask), but everything else still requires HTTPS."

---

## 3. ⚠️ YOU MUST UPDATE: `.env`

### What Needs Changing:
Your laptop's IP address. This MUST be updated before every APK rebuild because:
- APK reads `.env` at build time (not runtime)
- IP addresses change when networks change
- Old IP in APK = "Connection refused" error

### Before:
```properties
DETECTION_SERVER_URL=http://192.168.8.6:5000
```

### After (Example - Use YOUR IP):
```properties
DETECTION_SERVER_URL=http://192.168.8.10:5000
```

### How to Find YOUR IP:
1. Open Command Prompt on your laptop
2. Run: `ipconfig`
3. Find: `IPv4 Address . . . . . . . . . . . : 192.168.x.x`
4. Update `.env` with that IP

### Why:
- App is hardcoded to this IP at build time
- Flask server must be accessible at this IP
- If IP is wrong, APK can't reach Flask

---

## 4. ✅ VERIFY: `pubspec.yaml` (No changes needed, just verify)

### What to Check:
Make sure `.env` is listed in assets:

```yaml
flutter:
  uses-material-design: true
  
  assets:
    - .env                    # ← This line MUST be present
    - assets/app logo.png
```

### Why:
Without this line, `.env` file is NOT included in the APK. Environment variables will be empty.

### Action:
- ✅ Verify this line exists
- ✅ Don't change anything if it exists
- ❌ If missing, add it

---

## Summary Table

| File | Change | Type | Impact |
|------|--------|------|--------|
| `AndroidManifest.xml` | Added permissions + security config ref | CRITICAL | Without this, APK blocked from network access |
| `network_security_config.xml` | NEW FILE | CRITICAL | Without this, HTTP requests to local IPs blocked |
| `.env` | Update IP address | CRITICAL | Wrong IP = "Connection refused" |
| `pubspec.yaml` | Verify `.env` in assets | IMPORTANT | Missing = environment variables empty |

---

## Files That DON'T Need Changes

The following files are already correctly configured:
- ✅ `lib/main.dart` - Already loads `.env` and initializes correctly
- ✅ `lib/detection_service.dart` - Already reads `DETECTION_SERVER_URL`
- ✅ `lib/widgets/mjpeg_stream.dart` - Already handles video stream
- ✅ `pubspec.yaml` - Already has `.env` in assets (verify this)

---

## Verification Checklist

After making changes, verify:

- [ ] **`AndroidManifest.xml`**
  - Contains: `<uses-permission android:name="android.permission.INTERNET" />`
  - Contains: `android:networkSecurityConfig="@xml/network_security_config"`
  
- [ ] **`network_security_config.xml`**
  - File exists at: `android/app/src/main/res/xml/network_security_config.xml`
  - Contains: `cleartextTrafficPermitted="true"`
  - Contains: Local IP domain entries
  
- [ ] **`.env`**
  - Updated with YOUR current IP address
  - Format: `DETECTION_SERVER_URL=http://192.168.x.x:5000`
  
- [ ] **`pubspec.yaml`**
  - Contains: `- .env` in flutter.assets section

---

## Before You Rebuild

```bash
# 1. Verify .env was updated
type .env
# Should show your correct IP

# 2. Clean
flutter clean

# 3. Get dependencies
flutter pub get

# 4. Build
flutter build apk --release

# 5. Install
flutter install
```

---

## Expected File Structure After Changes

```
agrisense/
├── android/
│   └── app/
│       └── src/
│           └── main/
│               ├── AndroidManifest.xml          ✅ MODIFIED
│               └── res/
│                   └── xml/
│                       └── network_security_config.xml    ✅ NEW FILE
├── .env                                         ⚠️ UPDATE IP
├── pubspec.yaml                                 ✅ VERIFY (no change)
└── lib/
    ├── main.dart                               ✅ NO CHANGE NEEDED
    ├── detection_service.dart                  ✅ NO CHANGE NEEDED
    └── ...
```

---

## Rollback Instructions (If Needed)

If something goes wrong, here's how to revert:

### Revert `AndroidManifest.xml`:
```xml
<!-- Remove these lines: -->
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
<uses-permission android:name="android.permission.CAMERA" />

<!-- Remove from <application>: -->
android:networkSecurityConfig="@xml/network_security_config"
```

### Delete `network_security_config.xml`:
```bash
rm android/app/src/main/res/xml/network_security_config.xml
```

### Revert `.env`:
```properties
DETECTION_SERVER_URL=http://192.168.8.6:5000
```

Then rebuild: `flutter build apk --release`

---

## Testing the Changes

### Step 1: Test Network Configuration
```bash
# On tablet, test Flask endpoint
http://192.168.8.10:5000/health
# Should work in browser
```

### Step 2: Test APK Network Access
```bash
# Install APK with new permissions
flutter install

# Start Flask
python app.py --host 0.0.0.0 --port 5000

# Open APK on tablet
# Video stream should display
```

### Step 3: Check Logs
```bash
flutter logs
# Should show no network errors
```

---

## Why These Changes Work

```
BEFORE:
  APK tries to access http://192.168.8.6:5000 (Flask)
    ↓
  Android checks: "Is this HTTPS? Is this whitelisted?"
    ↓
  Android says: "HTTP and not whitelisted = BLOCKED"
    ↓
  APK fails ❌

AFTER:
  APK tries to access http://192.168.8.10:5000 (Flask)
    ↓
  Android checks network_security_config.xml
    ↓
  Config says: "192.168.x.x is allowed for HTTP"
    ↓
  Android says: "Allowed!"
    ↓
  APK succeeds ✅
```

---

## Key Files Reference

| File | Purpose | Type |
|------|---------|------|
| `AndroidManifest.xml` | Declares app permissions and security config | Android System |
| `network_security_config.xml` | Configures Android's network security policy | Android System |
| `.env` | Stores server IP and credentials | Configuration |
| `pubspec.yaml` | Declares project dependencies and assets | Flutter Config |

---

## Next Steps

1. ✅ Make changes listed above
2. ✅ Update `.env` with YOUR laptop IP
3. ✅ Run `flutter clean && flutter pub get`
4. ✅ Run `flutter build apk --release`
5. ✅ Run `flutter install`
6. ✅ Test on tablet

Done! 🎉
