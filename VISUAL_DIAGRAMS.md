# Visual Diagrams - APK Connectivity Issues

## Issue 1: Android Network Security Policy

### Before Fix ❌
```
┌─────────────────────────────────────┐
│   APK Tries HTTP Request            │
│   Target: http://192.168.8.6:5000   │
└────────────────┬────────────────────┘
                 │
                 ↓
┌─────────────────────────────────────┐
│   Android Checks Security Policy    │
│   Question: Is this HTTPS?          │
│   Answer: NO (it's HTTP)            │
└────────────────┬────────────────────┘
                 │
                 ↓ Answer: Not trusted
┌─────────────────────────────────────┐
│   ❌ REQUEST BLOCKED                │
│   Connection refused                │
└─────────────────────────────────────┘
```

### After Fix ✅
```
┌─────────────────────────────────────┐
│   APK Tries HTTP Request            │
│   Target: http://192.168.8.10:5000  │
└────────────────┬────────────────────┘
                 │
                 ↓
┌─────────────────────────────────────┐
│   Android Checks Network Config     │
│   File: network_security_config.xml │
└────────────────┬────────────────────┘
                 │
                 ↓
┌─────────────────────────────────────┐
│   Config Says:                      │
│   "192.168.x.x is allowed for HTTP" │
└────────────────┬────────────────────┘
                 │
                 ↓ Match found!
┌─────────────────────────────────────┐
│   ✅ REQUEST ALLOWED                │
│   Connected to Flask server         │
└─────────────────────────────────────┘
```

---

## Issue 2: Hard-coded IP from Build Time

### Timeline of Failure ❌
```
DAY 1 - FIRST BUILD
┌──────────────────────────┐
│ Your laptop IP: 192.168.8.6      │
│ You run: flutter build apk       │
│ Result: IP embedded in APK ←──┐  │
└──────────────────────────┘   │  │
                               │  │
                               ↓  │
┌──────────────────────────┐  │  │
│ APK contains:            │  │  │
│ DETECTION_SERVER_URL=    │  │  │
│   http://192.168.8.6:5000   │──┘
│ (Cannot change without rebuild) │
└──────────────────────────┘


DAY 2 - NETWORK CHANGED
┌──────────────────────────┐
│ Your laptop connects     │
│ to different WiFi        │
│ New IP: 192.168.8.10     │
└──────────────────────────┘
           │
           ↓
┌──────────────────────────┐
│ APK still has:           │
│ http://192.168.8.6:5000  │
└──────────────────────────┘
           │
           ↓
┌──────────────────────────┐
│ ❌ Connection Failed     │
│ APK reaches wrong IP!    │
└──────────────────────────┘
```

### Timeline of Success ✅
```
DAY 1 - FIRST BUILD
┌──────────────────────────┐
│ Find IP: ipconfig        │
│ Result: 192.168.8.6      │
└──────────────────────────┘
           │
           ↓
┌──────────────────────────┐
│ Update .env:             │
│ DETECTION_SERVER_URL=    │
│   http://192.168.8.6:5000   │
└──────────────────────────┘
           │
           ↓
┌──────────────────────────┐
│ Build APK                │
│ IP embedded: 192.168.8.6 │
└──────────────────────────┘
           │
           ↓
✅ Works


DAY 2 - NETWORK CHANGED
┌──────────────────────────┐
│ New IP: 192.168.8.10     │
└──────────────────────────┘
           │
           ↓
┌──────────────────────────┐
│ Update .env:             │
│ DETECTION_SERVER_URL=    │
│   http://192.168.8.10:5000  │
└──────────────────────────┘
           │
           ↓
┌──────────────────────────┐
│ Rebuild APK              │
│ IP embedded: 192.168.8.10   │
└──────────────────────────┘
           │
           ↓
✅ Works Again
```

---

## Issue 3: Missing Permissions

### Permission Requirements ✅
```
┌─────────────────────────────────────┐
│      APK Wants to Do Something      │
└────────────────┬────────────────────┘
                 │
    ┌────────────┼────────────┬─────────────┐
    │            │            │             │
    ↓            ↓            ↓             ↓
Make HTTP    Access        Check         Access
Request      Camera        Network       Device Info

    │            │            │             │
    ↓            ↓            ↓             ↓
┌──────────┐ ┌────────┐ ┌──────────┐ ┌──────────┐
│INTERNET  │ │ CAMERA │ │ACCESS_   │ │READ_     │
│          │ │        │ │NETWORK_  │ │PHONE_    │
│          │ │        │ │STATE     │ │STATE     │
└──────────┘ └────────┘ └──────────┘ └──────────┘
  REQUIRED    NEEDED      REQUIRED      OPTIONAL
```

### Before Fix ❌
```
┌──────────────────────────────────────────┐
│  APK Checks Permissions:                 │
│  INTERNET?     ✅ No (missing)           │
│  CAMERA?       ✅ No (missing)           │
│  ACCESS_NET?   ✅ No (missing)           │
└──────────────────────────────────────────┘
           │
           ↓
┌──────────────────────────────────────────┐
│  APK Asks: Can I make network request?   │
│  Android: NO - you didn't ask permission │
└──────────────────────────────────────────┘
           │
           ↓
┌──────────────────────────────────────────┐
│  ❌ REQUEST DENIED - PERMISSION ERROR    │
└──────────────────────────────────────────┘
```

### After Fix ✅
```
┌──────────────────────────────────────────┐
│  AndroidManifest.xml:                    │
│  <uses-permission INTERNET />            │
│  <uses-permission CAMERA />              │
│  <uses-permission ACCESS_NET_STATE />    │
└──────────────────────────────────────────┘
           │
           ↓
┌──────────────────────────────────────────┐
│  APK Checks Permissions:                 │
│  INTERNET?     ✅ Yes                    │
│  CAMERA?       ✅ Yes                    │
│  ACCESS_NET?   ✅ Yes                    │
└──────────────────────────────────────────┘
           │
           ↓
┌──────────────────────────────────────────┐
│  APK Asks: Can I make network request?   │
│  Android: YES - you declared permission  │
└──────────────────────────────────────────┘
           │
           ↓
┌──────────────────────────────────────────┐
│  ✅ REQUEST ALLOWED                      │
│  HTTP request proceeds...                │
└──────────────────────────────────────────┘
```

---

## Complete Request Flow

### Browser (Always Works) ✅
```
USER ACTION
    │
    ↓
Browser: "Let me access http://192.168.8.6:5000"
    │
    ↓
Browser Native: "Okay, sending request"
    │
    ↓
Android OS: "Browser did this? Okay, allow it"
    │
    ↓
WiFi Network: Connected ✅
    │
    ↓
Flask Server: Received request ✅
    │
    ↓
Response: Video stream ✅
```

### APK Before Fix (Fails) ❌
```
USER ACTION: Open app
    │
    ↓
APK Code: "Let me request http://192.168.8.6:5000"
    │
    ↓
APK Runtime: Checking...
    │
    ├─ Question 1: Do I have INTERNET permission?
    │  No ✗
    │
    ├─ Android blocks: PERMISSION DENIED
    │
    └─ ❌ REQUEST BLOCKED
```

### APK After Fix (Works) ✅
```
USER ACTION: Open app
    │
    ↓
APK Code: "Let me request http://192.168.8.10:5000"
    │
    ↓
APK Runtime: Checking...
    │
    ├─ Question 1: Do I have INTERNET permission?
    │  Yes ✓ (declared in manifest)
    │
    ├─ Question 2: Is this HTTP or HTTPS?
    │  HTTP (not secure)
    │
    ├─ Question 3: Check network_security_config.xml
    │  "Is 192.168.8.10 allowed for HTTP?"
    │  Yes ✓ (in domain config)
    │
    ├─ All checks passed!
    │
    ↓
WiFi Network: Connected ✅
    │
    ↓
Flask Server: Received request ✅
    │
    ↓
Response: Video stream ✅
```

---

## Fix Application Flow

```
┌─────────────────────────────────────────┐
│  YOU START HERE: Problem Analysis       │
│  "APK can't access Flask/Database"      │
└────────────────┬────────────────────────┘
                 │
         ┌───────┴───────┐
         │               │
         ↓               ↓
    ┌─────────────┐ ┌──────────────────┐
    │ Problem 1:  │ │ Problem 2:       │
    │ Android     │ │ Hard-coded IP    │
    │ blocks HTTP │ │ from build time  │
    └──────┬──────┘ └────────┬─────────┘
           │                 │
           ↓                 ↓
    ┌──────────────┐ ┌──────────────────┐
    │ Solution 1:  │ │ Solution 2:      │
    │ Create       │ │ Update .env      │
    │ network_     │ │ with current IP  │
    │ security_    │ │                  │
    │ config.xml   │ │ ipconfig →      │
    │              │ │ find IP →        │
    │ ✅ DONE      │ │ edit .env        │
    └──────┬───────┘ └────────┬─────────┘
           │                 │
           └────────┬────────┘
                    │
                    ↓
    ┌─────────────────────────────────┐
    │ Problem 3: Missing Permissions  │
    └────────────────┬────────────────┘
                     │
                     ↓
    ┌─────────────────────────────────┐
    │ Solution 3:                     │
    │ Update AndroidManifest.xml      │
    │ Add INTERNET, CAMERA, etc       │
    │                                 │
    │ ✅ DONE                         │
    └────────────────┬────────────────┘
                     │
                     ↓
    ┌─────────────────────────────────┐
    │ ACTION: Rebuild APK             │
    │ flutter clean                   │
    │ flutter build apk --release     │
    │ flutter install                 │
    └────────────────┬────────────────┘
                     │
                     ↓
    ┌─────────────────────────────────┐
    │ ACTION: Test                    │
    │ Start Flask: --host 0.0.0.0     │
    │ Open app on tablet              │
    │ Video stream should show ✅     │
    └─────────────────────────────────┘
```

---

## Network Architecture

### BEFORE FIX
```
TABLET                          LAPTOP

┌──────────────────┐           ┌──────────────────┐
│                  │   WiFi    │                  │
│  ┌────────────┐  │◄────────►│  Flask Server    │
│  │  Browser   │  │          │  :5000           │
│  │   ✅ Works │  │          │                  │
│  └────────────┘  │          └──────────────────┘
│                  │
│  ┌────────────┐  │          ┌──────────────────┐
│  │    APK     │  │          │  Supabase        │
│  │ ❌ Fails   │  │          │  (Cloud)         │
│  └────────────┘  │          └──────────────────┘
│                  │
│ ❌ No            │
│    permissions   │
│ ❌ HTTP blocked  │
│ ❌ Wrong IP      │
│                  │
└──────────────────┘
```

### AFTER FIX
```
TABLET                          LAPTOP

┌──────────────────┐           ┌──────────────────┐
│                  │   WiFi    │                  │
│  ┌────────────┐  │◄────────►│  Flask Server    │
│  │  Browser   │  │          │  :5000           │
│  │   ✅ Works │  │          │                  │
│  └────────────┘  │          └──────────────────┘
│                  │
│  ┌────────────┐  │          ┌──────────────────┐
│  │    APK     │  │          │  Supabase        │
│  │ ✅ Works   │  │◄────────►│  (Cloud)         │
│  │            │  │  HTTPS   │                  │
│  └────────────┘  │          └──────────────────┘
│                  │
│ ✅ Permissions  │
│ ✅ HTTP allowed │
│ ✅ Correct IP   │
│                  │
└──────────────────┘
```

---

## Rebuild Process Flowchart

```
START
  │
  ↓
Find IP: ipconfig
  │
  ↓
Update: .env with correct IP
  │
  ↓
Run: flutter clean
  │
  ↓
Run: flutter pub get
  │
  ↓
Run: flutter build apk --release
  │
  ├─ Compiles Dart code
  │ └─ Reads .env (IP locked in)
  │
  ├─ Includes Android config
  │ └─ AndroidManifest.xml (permissions)
  │ └─ network_security_config.xml (HTTP config)
  │
  ├─ Packages everything
  │ └─ APK file created
  │
  ↓
Run: flutter install
  │
  ├─ Uninstalls old APK
  ├─ Installs new APK
  │
  ↓
APK ready to test ✅
  │
  ↓
Start Flask: --host 0.0.0.0 --port 5000
  │
  ↓
Open APK on tablet
  │
  ↓
Test video stream
  │
  ├─ ✅ Works → SUCCESS
  │
  └─ ❌ Fails → Check logs: flutter logs
```

---

These diagrams show the complete picture of what was wrong and how it's fixed!
