# 🧪 AUTO-REFRESH TESTING GUIDE

## Quick Test Cases

### Test 1: Server Starts After App Load ✅
**Setup:**
- App is running with Flask server **offline**
- Dashboard shows 🔴 DISCONNECTED, loading spinner

**Action:**
- Start Flask server from terminal

**Expected Result:**
- ✅ Within 2 seconds: Indicator shows 🟡 CONNECTING
- ✅ Within 3 seconds: Indicator shows 🟢 CONNECTED
- ✅ Live video appears immediately
- ❌ **NO** manual navigation needed
- ❌ **NO** screen reload needed

**What's Happening:**
```
0.0s  - Server starts
2.0s  - Health check detects it
2.5s  - Stream restart triggered
3.0s  - Video connecting
3.2s  - Video streaming live
```

---

### Test 2: Server Stops While Streaming ✅
**Setup:**
- App is running with Flask server **online**
- Dashboard shows 🟢 CONNECTED, live video streaming

**Action:**
- Stop Flask server (Ctrl+C in terminal)

**Expected Result:**
- ✅ Within 3 seconds: Indicator shows 🔴 DISCONNECTED
- ✅ Loading spinner appears immediately (not stale frame!)
- ✅ Last frame is cleared from screen
- ✅ Auto-reconnect retries every 3 seconds (shows "Connecting to camera...")
- ❌ **NO** manual navigation needed
- ❌ **NO** stale frame lingering

**What's Happening:**
```
0.0s  - Server stops
1.0s  - Stream buffer empties
3.0s  - MJPEGStream onDone triggered
3.1s  - Frame cleared, indicator = DISCONNECTED
3.1s  - Auto-reconnect timer starts
6.0s  - Auto-reconnect attempt #1 (fails)
9.0s  - Auto-reconnect attempt #2 (fails)
```

---

### Test 3: Server Restarts While App Waiting ✅
**Setup:**
- App is running with Flask server **offline**
- Dashboard shows 🔴 DISCONNECTED
- App is waiting (auto-retrying every 3 seconds)

**Action:**
- Start Flask server from terminal

**Expected Result:**
- ✅ Within 3 seconds: Next auto-reconnect succeeds
- ✅ Indicator shows 🟢 CONNECTED
- ✅ Live video appears automatically
- ✅ No manual navigation needed
- ✅ Happens without user doing anything

**What's Happening:**
```
-6.0s  - Last reconnect attempt failed
-3.0s  - Another reconnect attempt failed
0.0s   - Server starts
3.0s   - Next auto-reconnect attempt
3.1s   - SUCCESS! Connected
3.2s   - Video streaming
```

---

### Test 4: Power Cycle Server ✅
**Setup:**
- App running with Flask server online
- Video streaming

**Action:**
- Kill server (Ctrl+C)
- Wait 5 seconds
- Restart server

**Expected Result:**
- ✅ Indicator goes 🔴 DISCONNECTED immediately
- ✅ Frame clears (loading spinner shows)
- ✅ Auto-reconnects after server restarts
- ✅ Video resumes automatically
- ✅ No user interaction needed

**Timeline:**
```
0.0s  - User stops server
3.0s  - Indicator red, loading spinner
3.0s  - Auto-reconnect starts (fails)
6.0s  - Auto-reconnect attempt #2 (fails)
6.0s  - User restarts server
9.0s  - Next auto-reconnect succeeds
9.1s  - Video back online
```

---

## Detailed Observations

### Indicator Animations

| State | Icon | Color | Animation | Meaning |
|-------|------|-------|-----------|---------|
| 🟢 CONNECTED | ⭕ | Green | Flicker | Video is streaming |
| 🟡 CONNECTING | ⭕ | Yellow | Pulse | Attempting to connect |
| 🔴 DISCONNECTED | ⭕ | Red | Static | No connection |

### UI Elements

**When Connected:**
```
┌─────────────────────────┐
│ 🟢 [Flicker animation]  │ ← Animated indicator
│                         │
│   [LIVE VIDEO FRAME]    │ ← Real-time image
│                         │
│    CURRENT DETECTIONS   │ ← Disease info
└─────────────────────────┘
```

**When Offline:**
```
┌─────────────────────────┐
│ 🔴 [Static red]         │ ← Static indicator
│                         │
│  🔄 Loading spinner     │ ← Connecting message
│  "Connecting to        │
│   camera..."           │
│                         │
│    CURRENT DETECTIONS   │ ← (Empty usually)
└─────────────────────────┘
```

---

## Things That Should NOT Happen Anymore ❌

1. ❌ Stale frame persisting after server stops
2. ❌ Indicator green when server is offline
3. ❌ Stuck loading screen that doesn't retry
4. ❌ Needing to navigate to another page to fix it
5. ❌ Manual reload to see server come back online
6. ❌ No feedback about connection status

---

## Debug Logging

All changes have console logs prefixed with emojis:

| Symbol | Meaning |
|--------|---------|
| ✅ | Success (server online, stream connected) |
| 🔄 | Action (reconnect, URL change, restart) |
| ❌ | Error (connection failed, timeout) |
| ⏹️ | Status (stream closed, timer cancelled) |

**Watch logs while testing:**
```
✅ MJPEG Stream connected
🔄 Attempting to reconnect to stream...
❌ Server health check failed: Connection refused
🔄 Stream URL changed, restarting...
✅ Server is online - triggering stream restart
```

---

## Network Conditions to Test

### Good Network (recommended first)
- Close to WiFi router
- App and server on same network
- No packet loss
- Expected: Instant connection

### Poor Network
- WiFi at far end of building
- Low signal strength
- Expected: 5-10 second connection time
- App should still work (auto-retry every 3 seconds)

### No Network
- WiFi disabled on phone
- Server unreachable
- Expected: Loading spinner, auto-retry, no error crash

---

## Performance Checklist

- [ ] Health check doesn't drain battery (lightweight HTTP HEAD)
- [ ] Auto-reconnect doesn't spam requests (3-second intervals)
- [ ] No UI freezing when connecting/disconnecting
- [ ] Memory not leaking (check timers are cancelled in dispose)
- [ ] No crashes on rapid server restarts
- [ ] Animations are smooth (30+ fps)

---

## Common Issues & Solutions

### Issue: Still Seeing Stale Frame
**Cause:** MJPEGStream not clearing frame on disconnect
**Solution:** Check that `_currentFrame = null;` is called in error handler
**Fix:** Verify `lib/widgets/mjpeg_stream.dart` line ~110-115

### Issue: Indicator Not Updating
**Cause:** Callback not firing
**Solution:** Check that `onStatusChanged?.call()` is invoked in MJPEGStream
**Fix:** Verify `_updateStreamStatus()` is being called from LiveStreamWidget

### Issue: Auto-Reconnect Not Working
**Cause:** Timer not being set
**Solution:** Check that `_reconnectTimer` is created and started
**Fix:** Verify timer creation in `onError` and `onDone` handlers

### Issue: Server Detector Not Working
**Cause:** Health endpoint doesn't exist or wrong URL
**Solution:** Verify Flask has `/health` endpoint
**Fix:** Add to Flask app:
```python
@app.route('/health', methods=['GET', 'HEAD'])
def health():
    return '', 200
```

---

## Success Criteria ✅

Your implementation is working if:
1. ✅ Server starts → Auto-reconnect within 2-3 seconds
2. ✅ Server stops → Frame clears, indicator red within 3 seconds
3. ✅ No manual navigation needed for any scenario
4. ✅ Loading spinner shows when offline (not stale frame)
5. ✅ Indicator animations are smooth
6. ✅ No crashes or console errors
7. ✅ App doesn't drain battery from polling

---

## Next: Deploy & Monitor

Once tests pass:
1. Test on real devices (not just emulator)
2. Test on different network conditions
3. Monitor logs for any patterns
4. Gather user feedback
5. Fine-tune timing intervals if needed
