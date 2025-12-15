# ✅ APK Connectivity Fix - Action Checklist

## DO THIS NOW (5 minutes)

### ☐ 1. Find Your Laptop's Current IP Address

**Open Command Prompt on your laptop:**
```batch
ipconfig
```

**Look for this line:**
```
IPv4 Address . . . . . . . . . . . : 192.168.8.10
```

**Write it down:** `___________`

---

### ☐ 2. Update .env File

**Open:** `c:\Users\nain2\Desktop\flutter_app\agrisense\.env`

**CHANGE THIS:**
```properties
DETECTION_SERVER_URL=http://192.168.8.6:5000
```

**TO THIS:** (replace with YOUR IP from Step 1)
```properties
DETECTION_SERVER_URL=http://192.168.8.10:5000
```

**SAVE THE FILE**

---

### ☐ 3. Verify Android Configuration Files

**File 1: Check permissions are added**
- Open: `android/app/src/main/AndroidManifest.xml`
- Verify it contains:
```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
```
✅ Done if you see these three lines

**File 2: Check network security config exists**
- File should exist: `android/app/src/main/res/xml/network_security_config.xml`
- Should contain:
```xml
<domain-config cleartextTrafficPermitted="true">
    <domain includeSubdomains="true">192.168.8.0</domain>
```
✅ Done if file exists and has this content

---

### ☐ 4. Rebuild APK (10 minutes)

**Open Terminal in your project directory and run:**

```bash
# Clean everything
flutter clean

# Get dependencies
flutter pub get

# Build release APK
flutter build apk --release

# Result: APK saved at build/app/outputs/flutter-app-release.apk
```

**Wait for it to complete.** You should see:
```
✅ Build complete: build/app/outputs/flutter-app-release.apk
```

---

### ☐ 5. Install on Tablet (1 minute)

**Option A: Using flutter install (USB)**
```bash
flutter install
```

**Option B: Manual install**
1. Transfer APK to tablet via USB or email
2. Tap to install
3. Allow installation from unknown sources

---

### ☐ 6. Test Flask Server (2 minutes)

**On your laptop, start Flask:**
```bash
python app.py --host 0.0.0.0 --port 5000
```

**Expected output:**
```
* Running on http://0.0.0.0:5000
```

**Do NOT close this terminal** - keep Flask running while testing.

---

### ☐ 7. Test from Tablet Browser (1 minute)

**On your tablet, open browser and test:**

Test 1: Health check
```
http://192.168.8.10:5000/health
```
Expected: Response page or `{"status": "ok"}`

Test 2: Video feed  
```
http://192.168.8.10:5000/video_feed
```
Expected: Live video stream

✅ If both work → Your network is good, proceed to Step 8

❌ If both fail → Network problem (see troubleshooting at bottom)

---

### ☐ 8. Test APK on Tablet (2 minutes)

**Open the APK app on your tablet:**

1. Launch the app
2. Wait 5 seconds for startup
3. Look for:
   - ✅ Live video stream (should show live camera)
   - ✅ Detection data (should show results)
   - ✅ Database data (should load from Supabase)

**Check for errors in logs:**
```bash
flutter logs
```

---

## SUCCESS INDICATORS ✅

If you see ALL of these, you're done:

- ✅ Video stream displays in app
- ✅ Detection results appear
- ✅ Database data loads
- ✅ No "Connection refused" errors
- ✅ No "Timeout" errors
- ✅ No "Network error" messages

---

## TROUBLESHOOTING 🔧

### ❌ Video feed shows in browser but NOT in APK

**Cause:** Network security config not working

**Fix:**
1. Verify `network_security_config.xml` exists
2. Verify `AndroidManifest.xml` has:
   ```xml
   android:networkSecurityConfig="@xml/network_security_config"
   ```
3. Rebuild: `flutter clean && flutter build apk --release`

---

### ❌ "Connection refused" error in APK

**Cause:** Flask not listening on all interfaces

**Fix:**
```bash
# WRONG:
python app.py --port 5000

# CORRECT:
python app.py --host 0.0.0.0 --port 5000
```

---

### ❌ "Connection timeout" error

**Cause:** Wrong IP address

**Fix:**
1. Run `ipconfig` again (IP might have changed)
2. Update `.env` with correct IP
3. Rebuild APK: `flutter clean && flutter build apk --release`

---

### ❌ "PERMISSION_DENIED" error

**Cause:** Missing INTERNET permission

**Fix:**
1. Verify `AndroidManifest.xml` has:
   ```xml
   <uses-permission android:name="android.permission.INTERNET" />
   ```
2. Rebuild APK

---

### ❌ Video stream works but Database is empty

**Cause:** Supabase credentials not loaded

**Fix:**
1. Verify `.env` has correct Supabase credentials:
   ```
   SUPABASE_URL=https://iwbftcnzcuhdapjxrlhe.supabase.co
   SUPABASE_ANON_KEY=sb_publishable_...
   ```
2. Verify `pubspec.yaml` has `.env` in assets:
   ```yaml
   assets:
     - .env
   ```
3. Rebuild APK

---

### ❌ Browser can access server but APK cannot

**Cause:** Android network security policy

**Fix:**
1. Create `network_security_config.xml` if missing
2. Add to `AndroidManifest.xml`:
   ```xml
   android:networkSecurityConfig="@xml/network_security_config"
   ```
3. Rebuild APK

---

### ❌ "FileNotFoundException: .env" error

**Cause:** `.env` not bundled in APK

**Fix:**
1. Verify `pubspec.yaml` contains:
   ```yaml
   flutter:
     assets:
       - .env
   ```
2. Run: `flutter clean`
3. Rebuild APK

---

## COMMAND REFERENCE

| Task | Command |
|------|---------|
| Get laptop IP | `ipconfig` |
| Clean build | `flutter clean` |
| Get dependencies | `flutter pub get` |
| Build APK | `flutter build apk --release` |
| Install APK | `flutter install` |
| View logs | `flutter logs` |
| Check network | `ping 192.168.8.10` |
| Start Flask | `python app.py --host 0.0.0.0 --port 5000` |

---

## FILE LOCATIONS

| File | Purpose | Status |
|------|---------|--------|
| `.env` | Configuration (IP, credentials) | ✅ Update with correct IP |
| `AndroidManifest.xml` | Permissions & security config | ✅ Already updated |
| `network_security_config.xml` | Allow HTTP to local IPs | ✅ Already created |
| `pubspec.yaml` | Assets (should include .env) | ✅ Check it has `.env` |

---

## QUICK TEST FLOW

```
1. Update .env IP
   ↓
2. Run Flutter clean
   ↓
3. Build APK: flutter build apk --release
   ↓
4. Install: flutter install
   ↓
5. Start Flask: python app.py --host 0.0.0.0 --port 5000
   ↓
6. Test browser: http://IP:5000/video_feed
   ↓
7. Test APK: Open app on tablet
   ↓
8. Success? ✅ All working!
   Fail? → Check troubleshooting section
```

---

## BEFORE YOU BUILD

**Quick checklist (2 minutes):**

- [ ] `.env` updated with correct IP? 
  - Run: `ipconfig`
  - Update: `.env` DETECTION_SERVER_URL
  
- [ ] Network config file exists?
  - File: `android/app/src/main/res/xml/network_security_config.xml`
  
- [ ] Permissions added?
  - File: `android/app/src/main/AndroidManifest.xml`
  - Check: 3 `<uses-permission>` lines exist
  - Check: `android:networkSecurityConfig` in `<application>`

- [ ] Ready to build?
  - Run: `flutter clean && flutter pub get`
  - Run: `flutter build apk --release`

---

## EXPECTED RESULTS

### Before Fix ❌
```
Browser:     http://IP:5000/video_feed → ✅ Works
APK:         Video stream               → ❌ Fails
APK:         Database sync              → ❌ Fails
Error:       "Connection refused" or "Network error"
```

### After Fix ✅
```
Browser:     http://IP:5000/video_feed → ✅ Works
APK:         Video stream               → ✅ Works
APK:         Database sync              → ✅ Works
Error:       None
```

---

## IF STILL STUCK

**Gather this information:**

1. Run: `flutter logs > logs.txt`
2. Search for "ERROR" or "Connection"
3. Share the error message

**Common messages and fixes:**

| Message | Fix |
|---------|-----|
| `Connection refused` | Run Flask with `--host 0.0.0.0` |
| `Connection timeout` | Update IP in `.env`, rebuild APK |
| `UnknownHostException` | Network config missing or wrong |
| `PERMISSION_DENIED` | Add INTERNET permission |
| `FileNotFound: .env` | Add to pubspec.yaml assets |

---

## FINAL VERIFICATION

**Run this test sequence:**

```bash
# 1. Make sure you're in project directory
cd c:\Users\nain2\Desktop\flutter_app\agrisense

# 2. Check if .env is correct
type .env

# 3. Clean and build
flutter clean
flutter pub get
flutter build apk --release

# 4. Install
flutter install

# 5. Start Flask (in separate terminal)
python app.py --host 0.0.0.0 --port 5000

# 6. View logs (in third terminal)
flutter logs

# 7. Open app on tablet and test
```

---

## YOU'RE DONE WHEN:

✅ Video stream shows in app  
✅ Detections display correctly  
✅ Database data loads  
✅ No connection errors  

**All set!** 🎉
