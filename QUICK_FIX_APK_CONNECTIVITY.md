# Quick Fix: APK Camera & Database Connectivity

## 🎯 What You Need to Do RIGHT NOW

### Step 1: Find Your Laptop's IP Address
Open **Command Prompt** on your laptop and run:
```batch
ipconfig
```

Look for the line that says `IPv4 Address . . . . . . . . . . . : 192.168.x.x`

**Note it down!** For example: `192.168.8.10`

---

### Step 2: Update `.env` File
Edit the `.env` file in your project and change:

**FROM:**
```properties
DETECTION_SERVER_URL=http://192.168.8.6:5000
```

**TO:**
```properties
DETECTION_SERVER_URL=http://192.168.8.10:5000
```
(Replace `192.168.8.10` with YOUR actual laptop IP)

---

### Step 3: Update Flask Server
When you run your Flask server, use:
```bash
python app.py --host 0.0.0.0 --port 5000
```

**Important:** `--host 0.0.0.0` makes it accessible from other devices on the network!

---

### Step 4: Test Connection from Tablet Browser
Open your tablet's browser and test:
- `http://192.168.8.10:5000/health` (should show response)
- `http://192.168.8.10:5000/video_feed` (should show video)

If these work, proceed to Step 5.

---

### Step 5: Rebuild and Install APK

```bash
# 1. Clean everything
flutter clean

# 2. Get dependencies
flutter pub get

# 3. Build release APK
flutter build apk --release

# 4. Install on tablet (connect via USB and enable USB debugging)
flutter install

# 5. Run the app on tablet and check logs
flutter logs
```

---

### Step 6: Verify in App

1. Launch the app on your tablet
2. Open **Developer Console** (if available) to see logs
3. Check if:
   - ✅ Video stream shows
   - ✅ Database data loads

---

## 🔍 What Was Fixed?

✅ **Android Network Security** - Created `network_security_config.xml` to allow HTTP requests to local server

✅ **Permissions** - Added `INTERNET`, `CAMERA`, `ACCESS_NETWORK_STATE` to `AndroidManifest.xml`

✅ **IP Configuration** - Updated `.env` with correct server address

---

## If Still Not Working

### Test 1: Network Connectivity
From your **tablet**, open browser and try:
```
http://192.168.8.10:5000/health
```
- ✅ Works → Issue is in APK app, not network
- ❌ Doesn't work → Network problem (check IP, firewall)

### Test 2: Check Flask Server Logs
Run Flask with verbose output:
```bash
python app.py --host 0.0.0.0 --port 5000 --debug
```
When tablet tries to connect, you should see requests in the logs.

### Test 3: Check APK Logs
```bash
flutter logs
```
Look for error messages like:
- `Connection refused`
- `Timeout`
- `Network error`

### Test 4: Firewall
On Windows, temporarily disable firewall for testing:
- Settings → Windows Defender Firewall → Allow app through firewall
- Find Python and enable it

---

## 📋 Checklist Before Building

- [ ] IP address in `.env` is correct and current
- [ ] Flask server runs with `--host 0.0.0.0`
- [ ] Tablet can access Flask in browser (`http://IP:5000/health`)
- [ ] `flutter clean` was run
- [ ] `AndroidManifest.xml` has permissions
- [ ] `network_security_config.xml` exists

---

## Key Points

1. **IP Address matters** - Your laptop IP might have changed since last build
2. **Build time settings** - `.env` is read at build time, not runtime
3. **Network security** - Android 9+ blocks cleartext HTTP by default
4. **Flask needs `0.0.0.0`** - Making it listen on all network interfaces

Good luck! 🚀
