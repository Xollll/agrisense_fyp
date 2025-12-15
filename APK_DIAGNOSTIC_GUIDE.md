# APK Connectivity Diagnostic Guide

## Problem: "APK works on browser but not in app"

This is a classic symptom of network configuration issues in Android release builds.

---

## Why Browser Works But APK Doesn't

| Aspect | Browser | APK App |
|--------|---------|---------|
| **HTTP Handling** | Direct, no restrictions | Blocked unless configured |
| **Network Security** | Inherited from OS | Controlled by `network_security_config.xml` |
| **Configuration** | Real-time, dynamic | Built into APK, read at build time |
| **IP Address** | User can type any IP | Hard-coded from `.env` at build |
| **Timeout** | Browser waits longer | App has strict timeouts |

---

## Diagnostic Flowchart

```
APK can't access Flask server?
│
├─ Test 1: Is Flask running?
│  ├─ YES → Go to Test 2
│  └─ NO → Start Flask server
│
├─ Test 2: Can tablet access Flask in browser?
│  ├─ YES → Go to Test 3
│  └─ NO → Network problem
│     ├─ Check IP address
│     ├─ Check firewall
│     └─ Check Flask host (needs 0.0.0.0)
│
├─ Test 3: Is `.env` correct in APK?
│  ├─ YES → Go to Test 4
│  └─ NO → Rebuild APK with correct IP
│
├─ Test 4: Does APK have network permissions?
│  ├─ YES → Go to Test 5
│  └─ NO → Update AndroidManifest.xml
│
└─ Test 5: Can APK make HTTPS requests? (Supabase)
   ├─ YES → Test complete!
   └─ NO → Check Supabase credentials
```

---

## Detailed Diagnostic Steps

### Test 1: Flask Server Status

**Check if Flask is running:**
```bash
# Windows
netstat -ano | findstr :5000

# Should show: Listening on 0.0.0.0:5000 or 127.0.0.1:5000
```

**Verify Flask host is correct:**
```bash
# When running Flask, you should see:
# * Running on http://0.0.0.0:5000

# NOT:
# * Running on http://127.0.0.1:5000
```

If Flask is bound to `127.0.0.1`, it's **only accessible locally**, not from other devices.

**Fix:**
```bash
python app.py --host 0.0.0.0 --port 5000
```

---

### Test 2: Network Accessibility from Tablet

**From tablet browser, test these endpoints:**

```
http://192.168.8.10:5000/health
```

**Expected response:** `{"status": "ok"}` or similar

If this fails:
- ❌ Check IP address (run `ipconfig` on laptop again)
- ❌ Check firewall (Windows Defender blocking port 5000)
- ❌ Check network (tablet on same WiFi as laptop?)

**Command to temporarily disable Windows firewall (testing only):**
```bash
# Open Command Prompt as Administrator:
netsh advfirewall set allprofiles state off

# Re-enable after testing:
netsh advfirewall set allprofiles state on
```

---

### Test 3: Verify `.env` Contents in APK

**Add this to `lib/main.dart` right after dotenv.load():**

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  await dotenv.load(fileName: ".env");
  
  // DEBUG: Print what was loaded
  print('═' * 50);
  print('📋 ENVIRONMENT VARIABLES LOADED:');
  print('DETECTION_SERVER_URL: ${dotenv.env['DETECTION_SERVER_URL']}');
  print('SUPABASE_URL: ${dotenv.env['SUPABASE_URL']}');
  print('SUPABASE_ANON_KEY: ${dotenv.env['SUPABASE_ANON_KEY']?.substring(0, 20)}...');
  print('═' * 50);
  
  // ... rest of main
}
```

Run the app and check Flutter logs:
```bash
flutter logs
```

Look for the debug output showing the server URL.

**If URL is wrong/missing:**
1. Update `.env`
2. Run `flutter clean`
3. Rebuild APK

---

### Test 4: Verify Android Permissions

**Check that `AndroidManifest.xml` includes:**

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
```

**Check `application` tag has:**
```xml
android:networkSecurityConfig="@xml/network_security_config"
```

**Verify file exists:**
- `android/app/src/main/res/xml/network_security_config.xml`

If missing, the APK will block HTTP requests to local server.

---

### Test 5: Verify Network Security Config

**File location:** `android/app/src/main/res/xml/network_security_config.xml`

**Should contain:**
```xml
<domain-config cleartextTrafficPermitted="true">
    <domain includeSubdomains="true">192.168.8.0</domain>
    <!-- other local IP ranges -->
</domain-config>
```

If this file is missing or wrong, Android blocks HTTP requests.

---

## Common Error Messages and Fixes

### ❌ "Connection refused"
**Cause:** Flask not running on correct address
**Fix:** Run Flask with `--host 0.0.0.0`

### ❌ "Connection timeout"
**Cause:** Wrong IP address or firewall blocking
**Fix:** 
1. Verify IP with `ipconfig`
2. Update `.env`
3. Rebuild APK

### ❌ "FileNotFoundException: .env"
**Cause:** `.env` not in APK
**Fix:** Verify in `pubspec.yaml`:
```yaml
flutter:
  assets:
    - .env
```

### ❌ "java.net.UnknownHostException"
**Cause:** Network security config blocking local IPs
**Fix:** Create `network_security_config.xml`

### ❌ "PERMISSION_DENIED"
**Cause:** Missing `INTERNET` permission
**Fix:** Add to `AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.INTERNET" />
```

---

## Complete Rebuild Procedure

```bash
# Step 1: Clean
flutter clean

# Step 2: Get dependencies
flutter pub get

# Step 3: Verify files
# Check: .env exists and has correct IP
# Check: AndroidManifest.xml has permissions
# Check: network_security_config.xml exists

# Step 4: Build release APK
flutter build apk --release

# Step 5: Install
flutter install

# Step 6: Run and check logs
flutter logs | findstr "DETECTION_SERVER_URL\|Stream\|Error"
```

---

## Environment Variable Verification

**In `lib/main.dart`, after `dotenv.load()`:**

```dart
// Debug printouts
print('✅ Env Load Status:');
print('   DETECTION_SERVER_URL: ${dotenv.env['DETECTION_SERVER_URL'] ?? 'NOT SET'}');
print('   SUPABASE_URL: ${dotenv.env['SUPABASE_URL'] ?? 'NOT SET'}');

// Verify in detection_service.dart
print('✅ Using server: ${dotenv.env['DETECTION_SERVER_URL'] ?? 'http://192.168.8.6:5000'}');
```

When you run `flutter logs`, you'll see these messages showing the actual values.

---

## Network Configuration Checklist

- [ ] **Laptop IP address** - Current (use `ipconfig`)
- [ ] **Flask running** - With `--host 0.0.0.0`
- [ ] **`.env` file** - Contains correct IP
- [ ] **`pubspec.yaml`** - Has `- .env` in assets
- [ ] **`AndroidManifest.xml`** - Has `android:networkSecurityConfig`
- [ ] **`network_security_config.xml`** - Created with cleartext domains
- [ ] **Permissions** - INTERNET, ACCESS_NETWORK_STATE in manifest
- [ ] **Firewall** - Allows Python/Flask on port 5000
- [ ] **APK rebuilt** - After each change (`flutter clean` first)

---

## Still Not Working?

1. **Gather logs:**
   ```bash
   flutter logs > app_logs.txt
   ```

2. **Test from tablet terminal:**
   ```bash
   adb shell
   ping 192.168.8.10  # Your laptop IP
   curl http://192.168.8.10:5000/health
   ```

3. **Share logs** - The logs will show exact error messages

---

## Key Insight

**Why it works in browser but not APK:**
- Browser = Direct HTTP, bypasses security configs
- APK = Subject to Android Network Security Policy
- Solution = Configure policy to allow local HTTP

The fix ensures your APK can make HTTP requests to your local Flask server, just like the browser can.
