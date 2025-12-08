# ✅ PHASE 1 IMPLEMENTATION CHECKLIST

**Start Date**: ___________  
**Target Completion**: 2-3 weeks  
**Status**: 🔴 Not Started → 🟡 In Progress → 🟢 Complete

---

## 📋 DEPENDENCY UPDATES

- [ ] **Add to `pubspec.yaml`**:
  - [ ] `sqflite: ^2.3.0` (local database)
  - [ ] `path: ^1.8.0` (file paths)
  - [ ] `path_provider: ^2.1.0` (app documents folder)

- [ ] **Run**: `flutter pub get`
- [ ] **Verify**: No errors in console

---

## 📁 FILES TO CREATE

### Core Services

- [ ] `lib/services/validation_service.dart`
  - **Source**: `COMPLETE_IMPLEMENTATION_GUIDE.md` → Section "1️⃣ INPUT VALIDATION SERVICE"
  - **Status**: ⏳ Waiting
  - **Lines**: ~200
  - **Classes**: ValidationService (static methods only)

- [ ] `lib/services/http_service.dart`
  - **Source**: `COMPLETE_IMPLEMENTATION_GUIDE.md` → Section "HTTP RETRY LOGIC"
  - **Status**: ⏳ Waiting
  - **Lines**: ~150
  - **Classes**: HttpService (retry logic, exponential backoff)

- [ ] `lib/services/cache_service.dart`
  - **Source**: `COMPLETE_IMPLEMENTATION_GUIDE.md` → Section "LOCAL SQLITE CACHING"
  - **Status**: ⏳ Waiting
  - **Lines**: ~300
  - **Classes**: CacheService (SQLite database operations)

- [ ] `lib/services/preferences_service.dart`
  - **Source**: `COMPLETE_IMPLEMENTATION_GUIDE.md` → Section "SETTINGS INTEGRATION"
  - **Status**: ⏳ Waiting
  - **Lines**: ~150
  - **Classes**: PreferencesService (app settings)

### Configuration

- [ ] Create directory: `lib/config/`
  - [ ] `lib/config/timeout_config.dart`
    - **Source**: `COMPLETE_IMPLEMENTATION_GUIDE.md` → Section "REQUEST TIMEOUT CONFIGURATION"
    - **Status**: ⏳ Waiting
    - **Lines**: ~30
    - **Classes**: TimeoutConfig (constants)

### UI Pages

- [ ] `lib/pages/settings_page.dart`
  - **Source**: `COMPLETE_IMPLEMENTATION_GUIDE.md` → Section "SETTINGS INTEGRATION - Step 2"
  - **Status**: ⏳ Waiting
  - **Lines**: ~200
  - **Classes**: SettingsPage, _SettingsPageState

---

## 🔄 FILES TO MODIFY

- [ ] **`lib/detection_service.dart`**
  - Add imports for: validation, http, cache, timeout config
  - Replace raw `http.get()` with `HttpService.getWithRetry()`
  - Add `ValidationService.validate*()` calls before using API data
  - Add `CacheService.cacheDetection()` for all responses
  - **Reference**: `COMPLETE_IMPLEMENTATION_GUIDE.md` → Section "Step 2: Update Detection Service"
  - **Estimated changes**: 50-100 lines added

- [ ] **`lib/main.dart`**
  - Initialize `PreferencesService` in `main()` function
  - Add settings page to routes
  - **Reference**: `COMPLETE_IMPLEMENTATION_GUIDE.md` → Section "Step 2: Initialize Services in main.dart"
  - **Estimated changes**: 10-20 lines added

- [ ] **`pubspec.yaml`**
  - Already done in dependency updates
  - Just verify these exist:
    - `sqflite: ^2.3.0`
    - `path: ^1.8.0`
    - `path_provider: ^2.1.0`

---

## 🧪 TESTING PHASE 1

### Unit Tests

- [ ] **Validation Service**
  - [ ] Test valid confidence (0.0-1.0) ✅
  - [ ] Test invalid confidence (<0 or >1) ✅
  - [ ] Test valid diseases ✅
  - [ ] Test invalid diseases ✅
  - [ ] Test valid timestamps ✅
  - [ ] Test invalid timestamps ✅

- [ ] **Cache Service**
  - [ ] Create detection → Cache → Retrieve ✅
  - [ ] Mark as synced → Verify flag ✅
  - [ ] Get unsynced detections ✅
  - [ ] Get by disease ✅
  - [ ] Get in date range ✅
  - [ ] Delete old records ✅
  - [ ] Clear all cache ✅

- [ ] **Preferences Service**
  - [ ] Set & get live updates ✅
  - [ ] Set & get notifications ✅
  - [ ] Set & get offline mode ✅
  - [ ] Set & get auto sync ✅
  - [ ] Settings persist after restart ✅

### Integration Tests

- [ ] **HTTP with Retry**
  - [ ] Success on first try ✅
  - [ ] Success on second try (simulate 1 failure) ✅
  - [ ] Fail after 3 retries ✅
  - [ ] Exponential backoff (1s, 2s, 4s) ✅
  - [ ] Timeout handling ✅

- [ ] **Detection Flow**
  - [ ] Take detection → Validate → Cache → Show result ✅
  - [ ] Network failure → Use cache ✅
  - [ ] Invalid response → Handle gracefully ✅

- [ ] **Offline Mode**
  - [ ] Turn off WiFi → App still works ✅
  - [ ] Shows cached data ✅
  - [ ] Retries auto-enable when online ✅

- [ ] **Settings Integration**
  - [ ] Toggle live updates → Polling starts/stops ✅
  - [ ] Change polling interval → Resets timer ✅
  - [ ] Toggle notifications → Notifications on/off ✅
  - [ ] Toggle offline mode → Cache becomes primary source ✅

### Manual UI Tests

- [ ] Open app → No crashes ✅
- [ ] Settings page opens ✅
- [ ] Each setting toggle works ✅
- [ ] Take detection → Shows loading ✅
- [ ] Detection completes → Shows result ✅
- [ ] Turn off WiFi → App shows "offline mode" ✅
- [ ] Turn WiFi back on → Auto retries ✅
- [ ] Restart app → Settings persist ✅
- [ ] Check console → No errors ✅

---

## 🎯 COMPLETION MILESTONES

### Week 1: Foundation Services
- [ ] Day 1-2: Add dependencies, create validation service
- [ ] Day 3-4: Create HTTP service with retry
- [ ] Day 5: Create cache service
- [ ] Day 6-7: Create preferences service, timeout config

### Week 2: Integration
- [ ] Day 1-2: Update detection service
- [ ] Day 3-4: Create settings page
- [ ] Day 5: Update main.dart
- [ ] Day 6-7: Integration testing

### Week 3: Testing & Polish
- [ ] Day 1-3: Unit tests
- [ ] Day 4-5: Integration tests
- [ ] Day 6-7: Manual testing, bug fixes

---

## 📊 PROGRESS TRACKING

```
PHASE 1 Progress:

Files Created:     0/5 services + 1/1 config + 1/1 page = [■□□□□□□□□□] 0%
Files Modified:    0/2 = [■□□□□□□□□□] 0%
Dependencies:      0/3 = [■□□□□□□□□□] 0%
Unit Tests:        0/30 = [■□□□□□□□□□] 0%
Integration Tests: 0/10 = [■□□□□□□□□□] 0%
Manual Tests:      0/12 = [■□□□□□□□□□] 0%

Overall: 0/143 tasks = [■□□□□□□□□□] 0%
```

---

## 🔗 QUICK LINKS

| Task | File | Reference |
|------|------|-----------|
| Validation Service | `lib/services/validation_service.dart` | COMPLETE_IMPLEMENTATION_GUIDE.md#1️⃣ |
| HTTP Retry | `lib/services/http_service.dart` | COMPLETE_IMPLEMENTATION_GUIDE.md#HTTP-RETRY |
| Cache Service | `lib/services/cache_service.dart` | COMPLETE_IMPLEMENTATION_GUIDE.md#SQLITE-CACHING |
| Preferences | `lib/services/preferences_service.dart` | COMPLETE_IMPLEMENTATION_GUIDE.md#SETTINGS |
| Timeout Config | `lib/config/timeout_config.dart` | COMPLETE_IMPLEMENTATION_GUIDE.md#TIMEOUT |
| Settings Page | `lib/pages/settings_page.dart` | COMPLETE_IMPLEMENTATION_GUIDE.md#SETTINGS-UI |

---

## 💡 TIPS FOR SUCCESS

1. **Copy-paste accurately**: The code in the guides is tested and ready
2. **Test after each file**: Don't wait until everything is done
3. **Keep a compilation-free state**: Never skip `flutter pub get`
4. **Use offline mode early**: Test with WiFi off to catch bugs
5. **Check console logs**: They tell you what's working/failing
6. **Use print() debugging**: Add logs to trace execution
7. **Read error messages carefully**: They usually point to the fix

---

## 🚨 TROUBLESHOOTING

### "Cannot find package 'sqflite'"
1. Check `pubspec.yaml` has the line
2. Run: `flutter pub get`
3. Wait 1-2 minutes for download
4. Run: `flutter clean` if still failing
5. Run: `flutter pub get` again

### "CacheService not found"
1. Verify file is at: `lib/services/cache_service.dart`
2. Check file has no syntax errors
3. Run: `flutter pub get`
4. Restart IDE

### "Timeout in HTTP calls"
1. Check `timeout_config.dart` is imported
2. Verify you're using `HttpService.getWithRetry()`
3. Check network is actually slow (not connection issue)
4. Increase timeout value temporarily for testing

### "Settings don't persist"
1. Make sure `PreferencesService().initialize()` runs in `main()`
2. Check `shared_preferences` is in `pubspec.yaml` ✅ (already there)
3. Uninstall app and reinstall to reset preferences
4. Check logs for preference save errors

---

## ✨ YOU'RE READY!

You have:
- ✅ Complete documentation
- ✅ Copy-paste ready code
- ✅ Clear file paths
- ✅ Testing checklist
- ✅ Troubleshooting guide

**Start with**: 📄 `COMPLETE_IMPLEMENTATION_GUIDE.md`  
**First file**: 📁 `lib/services/validation_service.dart`

Good luck! 🚀
