# Summary: Why APK Can't Access Camera & Database

## The Problem Explained Simply

You built and installed an APK on your tablet. The app can't:
1. ❌ Display video feed from Flask camera
2. ❌ Access the Supabase database

But the **browser on the tablet CAN** access the video feed.

---

## Root Cause Analysis

### 1️⃣ **Network Security in Android Release Builds**

Android 9+ has strict security policies:
- ❌ **Blocks HTTP** (unencrypted) requests by default
- ✅ **Allows HTTPS** (encrypted) requests
- ❌ **Blocks local IP ranges** unless explicitly configured

**Why it matters:**
- Your Flask server is `http://192.168.8.x:5000` (HTTP, not HTTPS)
- Android release builds block this by default
- Browser has different security rules (more permissive)

**Solution we implemented:**
- Created `network_security_config.xml` to allow HTTP to local IPs
- Updated `AndroidManifest.xml` to use this configuration

---

### 2️⃣ **Hard-coded IP Address from Build Time**

Your app reads configuration from `.env` at **build time**, not runtime.

**The problem:**
```dart
// This is evaluated when APK is BUILT, not when it runs
String serverUrl = dotenv.env['DETECTION_SERVER_URL'] ?? 'http://192.168.8.6:5000';
```

**Why it matters:**
- If you rebuild your network, your laptop IP changes
- Old `.env` = Old IP in APK
- APK can't reach the new IP

**What we did:**
- Made sure `.env` is correctly included in `pubspec.yaml` assets
- Instructions to update `.env` with current IP before rebuild

---

### 3️⃣ **Missing Permissions**

Your `AndroidManifest.xml` was missing critical permissions.

**The problem:**
```xml
<!-- MISSING THESE -->
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
<uses-permission android:name="android.permission.CAMERA" />
```

**Why it matters:**
- Without `INTERNET` permission, APK can't make network requests
- Without `ACCESS_NETWORK_STATE`, app can't check connection status

**What we did:**
- Added these permissions to `AndroidManifest.xml`

---

### 4️⃣ **Supabase Database Connection**

Supabase uses HTTPS, so it's not blocked by Android security.

**The real issue:**
- If `.env` isn't loaded correctly, credentials are empty
- Empty credentials = Failed authentication
- Failed auth = No database access

**What we did:**
- Added debug logging to show if credentials are loaded
- Ensured `.env` is properly bundled in APK

---

## What We Fixed

### ✅ File 1: `AndroidManifest.xml`
**Added:**
- `INTERNET` permission
- `CAMERA` permission  
- `ACCESS_NETWORK_STATE` permission
- Reference to network security config

```xml
<!-- NEW: Permissions at top level -->
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />

<!-- UPDATED: Application tag -->
<application
    ...
    android:networkSecurityConfig="@xml/network_security_config">
```

### ✅ File 2: `network_security_config.xml` (NEW)
**Created:** `android/app/src/main/res/xml/network_security_config.xml`

**Content:**
```xml
<network-security-config>
    <domain-config cleartextTrafficPermitted="true">
        <domain includeSubdomains="true">192.168.0.0</domain>
        <domain includeSubdomains="true">192.168.1.0</domain>
        <domain includeSubdomains="true">192.168.8.0</domain>
        <domain includeSubdomains="true">10.0.0.0</domain>
        <domain includeSubdomains="true">172.16.0.0</domain>
        <domain includeSubdomains="true">127.0.0.1</domain>
        <domain includeSubdomains="true">localhost</domain>
    </domain-config>
</network-security-config>
```

**What it does:**
- Tells Android: "Allow HTTP (cleartext) traffic to these local IP ranges"
- Enables your APK to communicate with local Flask server

### ✅ File 3: `.env` (YOU NEED TO UPDATE)
**Before rebuilding APK:**
1. Run `ipconfig` on your laptop
2. Find your IPv4 address (e.g., `192.168.8.10`)
3. Update `.env`:
```properties
DETECTION_SERVER_URL=http://192.168.8.10:5000
```

---

## Next Steps (IN ORDER)

### 🔴 STEP 1: Update Your IP Address
```bash
# On Windows, open Command Prompt:
ipconfig
```
Find line: `IPv4 Address . . . . . . . . . : 192.168.x.x`

Edit `.env`:
```properties
DETECTION_SERVER_URL=http://192.168.x.x:5000
```

### 🟠 STEP 2: Test Flask Server Accessibility
Start Flask with:
```bash
python app.py --host 0.0.0.0 --port 5000
```

From **tablet browser**, test:
```
http://192.168.x.x:5000/health
http://192.168.x.x:5000/video_feed
```

Both should work.

### 🟡 STEP 3: Clean & Rebuild APK
```bash
flutter clean
flutter pub get
flutter build apk --release
flutter install
```

### 🟢 STEP 4: Test on Tablet
Launch the app and verify:
- ✅ Video stream displays
- ✅ Database data loads

### 🔵 STEP 5: Check Logs (if issues remain)
```bash
flutter logs
```

Look for:
- `DETECTION_SERVER_URL: http://192.168.x.x:5000`
- Connection errors
- Timeout messages

---

## Why These Changes Matter

| Change | Reason | Impact |
|--------|--------|--------|
| **Add permissions** | APK needs permission to access network | Without it, no network requests work |
| **Network security config** | Android blocks HTTP by default | Without it, Flask connection fails |
| **Correct IP in `.env`** | APK reads config at build time | Wrong IP = Can't reach server |
| **Flask `0.0.0.0`** | Makes Flask listen on all interfaces | Without it, only localhost can access |

---

## Browser vs APK: Key Difference

```
BROWSER (works):
  1. User types: http://192.168.8.10:5000/video_feed
  2. Browser makes direct HTTP request
  3. No Android security policies apply
  4. Works! ✅

APK (didn't work before fix):
  1. APK has hardcoded server URL from .env
  2. APK tries to make HTTP request
  3. Android blocks it (no network security config)
  4. Fails! ❌

APK (works after fix):
  1. APK has hardcoded server URL from .env
  2. APK tries to make HTTP request
  3. Android checks network_security_config.xml
  4. Config says "allow HTTP to local IPs"
  5. Works! ✅
```

---

## Files Modified/Created

- ✅ `android/app/src/main/AndroidManifest.xml` - Added permissions & config reference
- ✅ `android/app/src/main/res/xml/network_security_config.xml` - NEW file for Android security
- ⚠️ `.env` - YOU NEED TO UPDATE with correct IP

---

## Quick Reference

**If APK still can't access Flask after these changes:**
1. Check IP with `ipconfig` - Did it change?
2. Test from tablet browser - Does `http://IP:5000/health` work?
3. Check Flask is running with `--host 0.0.0.0`
4. Run `flutter logs` - What's the actual error?
5. Check firewall - Is port 5000 blocked?

**If APK still can't access Supabase:**
1. Verify `.env` has correct `SUPABASE_URL` and `SUPABASE_ANON_KEY`
2. Check internet connection on tablet
3. Verify Supabase credentials are valid
4. Check app can reach HTTPS sites (should work)

---

## Success Indicators

After rebuilding APK:
- ✅ Video stream shows live video feed
- ✅ Detection data appears on dashboard
- ✅ Database queries return results
- ✅ Statistics page loads data
- ✅ No "Connection refused" or "Timeout" errors

---

**This should fix both issues!** Let me know if you hit any problems. 🚀
