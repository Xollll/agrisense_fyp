# Stream Recovery Fix - Testing Guide

## Quick Summary of Changes

### What Was Fixed
- **HTTP client resource leaks** preventing reconnection after network interruption
- **App lifecycle not handled** causing stream to stay stuck after emulator restart
- **Weak watchdog monitoring** missing frozen connections

### Key Improvements
1. Proper HTTP client disposal in all code paths
2. Automatic stream restart on app resume/foreground
3. Enhanced watchdog detects both "no frames" and "frozen connection"
4. Better diagnostic logging with emoji indicators

## Testing Steps

### Test 1: Normal Stream Operation
**Expected**: Smooth streaming with frames updating continuously
```
Steps:
1. Launch app on emulator
2. Dashboard page loads
3. Camera stream appears within 3-5 seconds
4. Stream shows live video frames

Look for in logs:
✅ MJPEG Stream connected, status: 200
📺 MJPEG Stream connection established, waiting for frames...
```

### Test 2: Emulator Restart Recovery
**Expected**: Stream reconnects automatically within 10 seconds of restart
```
Steps:
1. App running with live stream active
2. Restart emulator (adb emu kill / emulator restart)
3. App should detect offline state
4. Observe stream status change from Connected → Connecting
5. Stream should reconnect within 10 seconds

Look for in logs:
❌ Server health check failed: Server unreachable
❌ MJPEG connection error: ...
⏳ Scheduling reconnect in 1 second...
🔄 Attempting to reconnect to stream...
✅ MJPEG Stream connected, status: 200
```

### Test 3: App Backgrounding/Resuming
**Expected**: Stream reconnects immediately when app returns to foreground
```
Steps:
1. App running with live stream
2. Press Home button to background app
3. Wait 5 seconds
4. Return to app (recent apps or launcher)
5. Stream should reconnect immediately

Look for in logs:
📱 App resumed - forcing stream restart...
📺 Stream URL cleared - waiting for reconnection...
🔌 Initiating MJPEG stream connection...
✅ MJPEG Stream connected, status: 200
```

### Test 4: Network Disconnect/Reconnect
**Expected**: Stream detects offline and reconnects when network available
```
Steps:
1. App running with live stream
2. Toggle airplane mode ON
3. Observe stream status: Connected → Offline (animation changes)
4. Toggle airplane mode OFF
5. Stream should reconnect within 10 seconds

Look for in logs:
❌ Server health check failed: Server unreachable
❌ No frames received for 5 seconds - stream stalled, reconnecting...
📱 Server went offline - stopping stream
🔄 Attempting to reconnect...
✅ Server came online - restarting stream...
```

### Test 5: Server Stop/Start
**Expected**: Health check detects server status, stream adapts
```
Steps:
1. App running with live stream
2. Stop Flask server (Ctrl+C on RPi or stop container)
3. Observe stream status change: Connected → Offline
4. Restart Flask server
5. Observe stream reconnect: Offline → Connecting → Connected

Look for in logs:
❌ Server health check failed
❌ Server went offline - stopping stream
✅ Server came online - restarting stream...
🔄 Attempting to reconnect to stream...
```

### Test 6: Frozen Connection Detection
**Expected**: Watchdog detects when connection is stuck and forces reconnect
```
Steps:
1. Simulate frozen connection (e.g., local network latency or server stall)
2. Stream connects but no frames arrive for 10 seconds
3. Watchdog should trigger automatic reconnection

Look for in logs:
✅ MJPEG Stream connected, status: 200
📺 MJPEG Stream connection established, waiting for frames...
⚠️ Connected but no frames received for 10 seconds - stream frozen, reconnecting...
🔄 Attempting to reconnect to stream...
```

## Monitoring the Logs

### Enable Detailed Logging
1. Open logcat: `flutter run -v` (verbose mode)
2. Filter for app logs: `adb logcat | grep "agrisense\|Stream\|Server"`
3. Look for emoji indicators:
   - 🔌 = Connection attempt
   - ✅ = Success
   - ❌ = Error/Failure
   - ⚠️ = Warning/Stall
   - 📱 = App lifecycle
   - 📺 = Stream status
   - 🔄 = Reconnect attempt

### Key Log Patterns to Watch

**Healthy Stream**:
```
🔌 Initiating MJPEG stream connection...
✅ MJPEG Stream connected, status: 200
📺 MJPEG Stream connection established, waiting for frames...
[repeated frame updates]
```

**Stream Recovery**:
```
❌ MJPEG connection error: Connection refused
⏳ Scheduling reconnect in 1 second...
🔄 Attempting to reconnect to stream...
🔌 Initiating MJPEG stream connection...
✅ MJPEG Stream connected, status: 200
```

**Server Restart**:
```
❌ Server health check failed: Server unreachable
📱 Server went offline - stopping stream
[waiting...]
✅ Server came online - restarting stream...
🔄 Attempting to reconnect to stream...
✅ MJPEG Stream connected, status: 200
```

## Visual Indicators in UI

### Live Indicator States
- **Connected (Green)**: ✅ Live badge + pulsing green animation + video frames
- **Connecting (Orange)**: ⏳ Connecting badge + spinning animation + loading spinner
- **Disconnected (Red)**: ❌ Offline badge + static indicator + "Connecting to camera..." message

### Status Changes
1. **Normal operation**: Green (steady)
2. **Network interruption**: Green → Orange → (if recovers) Green
3. **Emulator restart**: Connected → Orange (10s) → Connected
4. **App resume**: Connected → Orange (instant) → Connected

## Performance Metrics

| Metric | Target | How to Measure |
|--------|--------|---|
| Initial connection | < 5s | Time from app launch to first frame |
| Reconnect after network fail | < 10s | Time from network restore to frame |
| App resume reconnect | < 2s | Time from app foreground to frame |
| Frozen stream detection | < 10s | Time from freeze to reconnect attempt |
| Memory leaks | Stable | Check DevTools memory over 20+ reconnects |

## Debugging Commands

```bash
# View full logs with timestamps
adb logcat -v time | grep "flutter\|Stream\|Server"

# View only errors
adb logcat *:E | grep -E "Stream|Server|error"

# Restart app
adb shell am force-stop com.example.agrisense
flutter run

# Monitor memory (in another terminal)
flutter run --profile

# Kill emulator and restart
adb emu kill
emulator @<device_name>

# Test network isolation
adb shell pm set-inactive <package_name> true
adb shell pm set-inactive <package_name> false
```

## Expected Outcomes After Fix

✅ **Stream never gets permanently stuck**
✅ **Automatic recovery on network restore within 10s**
✅ **Automatic recovery on app resume within 2s**
✅ **No HTTP connection resource leaks**
✅ **Clear diagnostic logs for debugging**
✅ **Smooth UI state transitions during reconnection**

## If Issues Persist

1. **Stream stays stuck in "Connecting"**
   - Check server URL in .env: `DETECTION_SERVER_URL=http://172.20.10.3:5000`
   - Check network connectivity: `adb shell ping 172.20.10.3`
   - Verify Flask server is running: `ps aux | grep python`

2. **Frequent disconnections**
   - Check network stability with: `adb shell ping -c 100 172.20.10.3`
   - Check server logs for errors: `tail -f server.log`
   - Reduce detection polling rate if CPU high

3. **Memory growing after reconnects**
   - Run in profile mode to monitor memory
   - Check for suspended timers in dispose()
   - Verify HTTP client is being closed

4. **Connection timeout errors**
   - Check server response: `curl http://172.20.10.3:5000/health`
   - Increase timeout in network_config.dart if needed
   - Check RPi/server resource usage (CPU, memory, disk)
