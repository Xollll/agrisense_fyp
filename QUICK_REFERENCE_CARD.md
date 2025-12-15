# ⚡ Quick Reference Card - APK Fix

## TL;DR (Too Long; Didn't Read)

**Problem:** APK can't access camera or database  
**Reason:** Android blocks HTTP, APK has wrong IP, missing permissions  
**Solution:** Update IP, rebuild APK, test

---

## In 3 Steps:

### Step 1: Update IP (2 min)
```bash
ipconfig                          # Find your laptop IP
# Edit .env:
DETECTION_SERVER_URL=http://192.168.8.10:5000  # YOUR IP here
```

### Step 2: Rebuild (10 min)
```bash
flutter clean && flutter pub get && flutter build apk --release && flutter install
```

### Step 3: Test (2 min)
```bash
python app.py --host 0.0.0.0 --port 5000    # Start Flask
# Open app on tablet → Should show video stream ✅
```

---

## What Changed (Automatically Done)

| File | Change |
|------|--------|
| `AndroidManifest.xml` | ✅ Added permissions + network config |
| `network_security_config.xml` | ✅ Created (allows HTTP) |
| `.env` | ⚠️ **YOU UPDATE** with correct IP |

---

## Common Problems & Fixes

| Issue | Fix |
|-------|-----|
| "Connection refused" | Run Flask with `--host 0.0.0.0` |
| "Connection timeout" | Update IP in `.env`, rebuild |
| No video stream | Check Flask running, correct IP in `.env` |
| Database empty | Check `.env` has Supabase credentials |
| "Permission denied" | Already fixed in AndroidManifest |
| "Network security error" | Already fixed with network_security_config |

---

## Checklist Before Build

- [ ] IP from `ipconfig` written down
- [ ] `.env` updated with YOUR IP
- [ ] Files not accidentally modified:
  - [ ] `lib/main.dart` - NO changes
  - [ ] `lib/detection_service.dart` - NO changes
  - [ ] `pubspec.yaml` - Verify only (no changes)

---

## Key Commands

```bash
ipconfig                                    # Get your IP
flutter clean                               # Clean build
flutter pub get                             # Get deps
flutter build apk --release                 # Build APK
flutter install                             # Install on tablet
flutter logs                                # View logs
```

---

## Testing Flow

```
1. Find IP: ipconfig
2. Update: .env
3. Build: flutter build apk --release
4. Install: flutter install
5. Start Flask: python app.py --host 0.0.0.0 --port 5000
6. Test browser: http://IP:5000/video_feed
7. Test app: Launch on tablet
8. Success: Video shows ✅
```

---

## Files Created/Modified

✅ **Done (No action needed):**
- `android/app/src/main/AndroidManifest.xml` - Fixed
- `android/app/src/main/res/xml/network_security_config.xml` - Created

⚠️ **Must Update (Action needed):**
- `.env` - Change IP address before rebuild

---

## Why Simple Fix for Complex Problem?

```
APK blocked from HTTP ─→ Network security config
APK missing permissions ─→ AndroidManifest.xml
APK wrong IP ─→ Update .env before rebuild
```

All three issues → All three fixed ✅

---

## Expected Results

After this fix:

| Feature | Before | After |
|---------|--------|-------|
| Video Stream | ❌ | ✅ |
| Database | ❌ | ✅ |
| Detections | ❌ | ✅ |
| Browser Works | ✅ | ✅ |

---

## Version Info

- Flutter SDK: Any (tested on 3.9.2)
- Android: 9+ (API 28+)
- Dart: 3.0+

---

## Pro Tips

1. **Always check IP** - It changes when you reconnect to WiFi
2. **Always rebuild** - Changes to `.env` require APK rebuild
3. **Keep Flask running** - Start server before opening app
4. **Check logs** - `flutter logs` shows actual errors
5. **Test browser first** - If browser works, APK should work after fix

---

## One-Liner Help

```
Problem: "APK blocked from Flask server"
Cause: Android security policy + wrong IP + missing permissions
Fix: Update IP → Rebuild APK → Enable HTTP in security config
Time: 15 minutes total
Result: APK can access camera & database ✅
```

---

## Still Stuck?

1. Check: `flutter logs`
2. Look for: Error messages
3. Compare with: `APK_DIAGNOSTIC_GUIDE.md`
4. Or: Share the error message

---

## Fastest Path

```
1. ipconfig (get IP)
2. Edit .env (set IP)
3. flutter clean && flutter build apk --release
4. flutter install
5. Done ✅
```

**Time: 15 minutes**

---

## Remember

- **IP changes** when you reconnect WiFi → Update before rebuild
- **APK locked at build time** → Configuration is hard-coded
- **Android is strict** → Needs explicit permission config
- **Browser is flexible** → Bypasses many restrictions

**Fix them all → Connectivity works** ✅

---

### 📚 Full Guides

- `README_APK_FIX.md` - Full overview
- `IMMEDIATE_ACTION_CHECKLIST.md` - Step-by-step
- `APK_DIAGNOSTIC_GUIDE.md` - Troubleshooting
- `FILES_MODIFIED_EXACT_CHANGES.md` - What changed

Pick the one that matches your learning style!
