# APK Connectivity Fix - Visual Summary

## The Issues & Solutions

```
┌─────────────────────────────────────────────────────────────────┐
│ PROBLEM: APK can't access camera & database                     │
│ BUT: Browser on same tablet CAN access camera                  │
└─────────────────────────────────────────────────────────────────┘

                            ↓↓↓

┌─────────────────────────────────────────────────────────────────┐
│ ROOT CAUSE 1: Android Network Security Policy                   │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│ Release APK blocks:                                             │
│  • HTTP (port 5000, Flask)  ← ❌ BLOCKED                       │
│  • HTTPS (Supabase)         ← ✅ OK (encrypted)               │
│  • Local IP ranges          ← ❌ BLOCKED                       │
│                                                                 │
│ Browser allows:                                                 │
│  • All of the above         ← ✅ WORKS                        │
│                                                                 │
│ FIX: Create network_security_config.xml                        │
│      Tell Android: "Allow HTTP to local IPs"                   │
└─────────────────────────────────────────────────────────────────┘

                            ↓↓↓

┌─────────────────────────────────────────────────────────────────┐
│ ROOT CAUSE 2: Hard-coded IP from Build Time                     │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│ Your code:                                                      │
│   String url = dotenv.env['DETECTION_SERVER_URL']              │
│                  ?? 'http://192.168.8.6:5000';                │
│                                                                 │
│ Timeline:                                                       │
│   1. You built APK on Day 1 (your IP was 192.168.8.6)        │
│   2. IP got embedded in APK (can't change without rebuild)   │
│   3. Your IP changed on Day 2 (now 192.168.8.10)             │
│   4. APK tries to reach old IP (192.168.8.6) → FAILS        │
│                                                                 │
│ FIX: Update .env with CURRENT IP before rebuild               │
│      Run: ipconfig                                             │
│      Update .env                                               │
│      Rebuild APK: flutter build apk --release                 │
└─────────────────────────────────────────────────────────────────┘

                            ↓↓↓

┌─────────────────────────────────────────────────────────────────┐
│ ROOT CAUSE 3: Missing Permissions                               │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│ AndroidManifest.xml was missing:                               │
│  ❌ <uses-permission android:name="...INTERNET" />            │
│  ❌ <uses-permission android:name="...CAMERA" />              │
│  ❌ android:networkSecurityConfig="@xml/..."                  │
│                                                                 │
│ Result: APK can't make network requests                        │
│                                                                 │
│ FIX: Add permissions and security config reference             │
└─────────────────────────────────────────────────────────────────┘
```

---

## Architecture Comparison

### BEFORE (Broken)
```
┌─────────────┐         ┌──────────────────────────────────┐
│  TABLET     │         │  YOUR LAPTOP                     │
│             │         │                                  │
│ ┌─────────┐ │         │  ┌──────────────────────────────┐│
│ │ Browser │─┼────┐    │  │  Python Flask Server         ││
│ │ (Works) │ │    │    │  │  :5000 - Video Stream ✅     ││
│ └─────────┘ │    │    │  └──────────────────────────────┘│
│             │    │    │                                  │
│ ┌─────────┐ │    │    │  ┌──────────────────────────────┐│
│ │   APK   │ │    │    │  │  Supabase (Cloud)            ││
│ │ ❌ FAIL │─┼──┼─┼────┼──│  Database ❌ No credentials  ││
│ └─────────┘ │  │ │    │  └──────────────────────────────┘│
│             │  │ │    │                                  │
└─────────────┘  │ │    └──────────────────────────────────┘
                 │ │
     Browser:    │ │     APK:
     HTTP ✅      │ │     • No INTERNET permission ❌
     Direct ✅    │ │     • Blocked by security policy ❌
                 │ │     • Wrong IP hardcoded ❌
                 │ │
                 ↓ ↓
              FAILS
```

### AFTER (Fixed)
```
┌─────────────┐         ┌──────────────────────────────────┐
│  TABLET     │         │  YOUR LAPTOP                     │
│             │         │                                  │
│ ┌─────────┐ │         │  ┌──────────────────────────────┐│
│ │ Browser │─┼────┐    │  │  Python Flask Server         ││
│ │ (Works) │ │    │    │  │  :5000 - Video Stream ✅     ││
│ └─────────┘ │    │    │  └──────────────────────────────┘│
│             │    │    │                                  │
│ ┌─────────┐ │    │    │  ┌──────────────────────────────┐│
│ │   APK   │ │    │    │  │  Supabase (Cloud)            ││
│ │ ✅ WORKS│─┼────┤    │  │  Database ✅ Credentials OK  ││
│ └─────────┘ │    │    │  └──────────────────────────────┘│
│             │    │    │                                  │
│ ✅ INTERNET  │    │    │  ✅ network_security_config ✅  │
│ ✅ CAMERA    │    │    │  ✅ Correct IP in .env ✅      │
│ ✅ NETWORK   │    │    │                                  │
│             │    │    │                                  │
└─────────────┘    │    └──────────────────────────────────┘
                   │
                   ↓
                SUCCESS ✅
```

---

## What We Changed

### 1. AndroidManifest.xml
```xml
✅ ADDED:
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />

✅ UPDATED:
<application ... android:networkSecurityConfig="@xml/network_security_config">
```

### 2. network_security_config.xml (NEW FILE)
```xml
Created: android/app/src/main/res/xml/network_security_config.xml

Content:
<network-security-config>
    <domain-config cleartextTrafficPermitted="true">
        <domain>192.168.x.x</domain>  ← All local IP ranges
        ...
    </domain-config>
</network-security-config>
```

### 3. .env (YOU UPDATE)
```properties
❌ BEFORE:
DETECTION_SERVER_URL=http://192.168.8.6:5000

✅ AFTER:
DETECTION_SERVER_URL=http://192.168.8.10:5000  ← YOUR current IP
```

---

## Rebuild Process

```
Step 1: Update .env
┌─────────────────────────┐
│ Run: ipconfig           │
│ Get: IPv4 Address       │
│ Edit: .env file         │
└─────────────────────────┘
          ↓
Step 2: Clean Build
┌─────────────────────────┐
│ flutter clean           │
│ flutter pub get         │
└─────────────────────────┘
          ↓
Step 3: Build Release APK
┌─────────────────────────┐
│ flutter build apk       │
│ --release               │
└─────────────────────────┘
          ↓
Step 4: Install
┌─────────────────────────┐
│ flutter install         │
└─────────────────────────┘
          ↓
Step 5: Test
┌─────────────────────────┐
│ Open app on tablet      │
│ Check video stream ✅   │
│ Check database ✅       │
└─────────────────────────┘
```

---

## Common Issues & Solutions

```
Issue: "Connection refused"
  → Flask not running with --host 0.0.0.0
  → Run: python app.py --host 0.0.0.0 --port 5000

Issue: "Connection timeout"
  → Wrong IP in .env
  → Run: ipconfig and update .env
  → Rebuild: flutter build apk --release

Issue: "404 Not Found"
  → Flask endpoint doesn't exist
  → Check Flask server has /video_feed and /latest_detection

Issue: "Network security error"
  → network_security_config.xml missing
  → Check file exists at: android/app/src/main/res/xml/

Issue: "PERMISSION_DENIED"
  → AndroidManifest.xml missing permissions
  → Add: <uses-permission android:name="...INTERNET" />

Issue: "Database won't sync"
  → .env not loading in APK
  → Verify pubspec.yaml has: assets: [.env]
  → Check .env has valid Supabase credentials
```

---

## Testing Checklist

```
Before rebuild:
  ☐ Run ipconfig on laptop
  ☐ Update .env with current IP
  ☐ Verify Flask will run with --host 0.0.0.0
  ☐ Verify network_security_config.xml exists
  ☐ Verify AndroidManifest.xml has permissions

After rebuild:
  ☐ Flask server running
  ☐ Can access http://IP:5000/health from tablet browser
  ☐ Can access http://IP:5000/video_feed from tablet browser
  ☐ APK installed on tablet
  ☐ Video stream displays in app
  ☐ Database data loads
  ☐ No "Connection refused" errors in logs

Verification:
  ☐ Run: flutter logs
  ☐ Look for: DETECTION_SERVER_URL: http://192.168.x.x:5000
  ☐ Look for: Connection successful messages
```

---

## Success = ALL of these work:

✅ Browser on tablet → Flask video feed  
✅ APK on tablet → Flask video feed  
✅ APK on tablet → Supabase database  
✅ Detection results show in app  
✅ Database records sync  

**If you see all ✅, you're done!** 🎉

---

## Key Takeaways

1. **Android enforces security** - HTTP blocked unless configured
2. **APK configuration is static** - Set at build time, not runtime
3. **IP addresses change** - Always update before rebuild
4. **Network config tells Android rules** - Explicitly allow local HTTP
5. **Permissions are mandatory** - Can't make requests without INTERNET

---

**Questions? Check:**
- `COMPLETE_APK_FIX_SUMMARY.md` - Detailed explanation
- `QUICK_FIX_APK_CONNECTIVITY.md` - Step-by-step walkthrough
- `APK_DIAGNOSTIC_GUIDE.md` - Troubleshooting steps
