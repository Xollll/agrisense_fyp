# MJPEG Stream Recovery Fix - Emulator Restart Issue

## Problem Summary
After emulator restart, the live camera stream would get stuck showing "Connecting to camera..." and never recover. This was due to:
1. HTTP client connections not being properly disposed
2. Half-open connections staying in memory
3. No lifecycle handling when app resumes after device sleep/restart
4. Watchdog timer only checking for "no frames" but not detecting complete connection stall

## Root Causes Identified

### 1. **HTTP Client Resource Leak**
- **Before**: `http.Client()` was created but never disposed when stream failed or was replaced
- **Impact**: Stale connections accumulate, preventing new connections
- **Fix**: 
  - Store `http.Client` as instance variable `_httpClient`
  - Explicitly call `_httpClient?.close()` in all error paths
  - Clean up client before creating a new one in `_startStream()`

### 2. **App Lifecycle Not Handled**
- **Before**: No response when app was resumed after emulator restart
- **Impact**: Stream would remain in failed state indefinitely
- **Fix**:
  - Add `WidgetsBindingObserver` mixin to `_MainWrapperState` 
  - Add `didChangeAppLifecycleState()` callback
  - Force stream restart when app returns to foreground (`AppLifecycleState.resumed`)

### 3. **Dashboard Wasn't Listening to App Lifecycle**
- **Before**: Only the MainWrapper had potential lifecycle handling, not the Dashboard
- **Impact**: Dashboard page didn't trigger fresh connection on app resume
- **Fix**:
  - Add `WidgetsBindingObserver` mixin to `_DashboardPageState`
  - Implement `didChangeAppLifecycleState()` to force stream restart
  - Log app resume events for debugging

### 4. **Weak Watchdog Monitoring**
- **Before**: Watchdog only checked "no frames for 5 seconds" 
- **Impact**: Could miss cases where connection is established but frozen (no frame flow)
- **Fix**:
  - Added second watchdog check: "Connected for 10+ seconds with no frames" 
  - Reduced watchdog timer interval from 5s to 2s for faster detection
  - Better differentiation between "connecting" and "frozen connection"

## Changes Made

### File: `lib/widgets/mjpeg_stream.dart`

#### 1. **Enhanced State Tracking**
```dart
http.Client? _httpClient;                    // Reusable client with proper cleanup
DateTime? _connectionAttemptTime;            // Track when we started connecting
```

#### 2. **Improved `_startStream()` Method**
- Clean up existing client before creating new one
- Track connection attempt time for watchdog monitoring
- Better error messages with diagnostic info
- Added status code logging on successful connection

#### 3. **Enhanced Watchdog Timer**
- Now runs every 2 seconds (vs 5 seconds before)
- **Check 1**: No frames for 5+ seconds → reconnect
- **Check 2**: Connected 10+ seconds with no frames → force reconnect (detects frozen streams)

#### 4. **Proper Resource Cleanup**
All error/done paths now:
```dart
_subscription?.cancel();
_httpClient?.close();      // NEW: Properly close HTTP client
_watchdogTimer?.cancel();
```

#### 5. **Enhanced Logging**
Added emoji indicators for easier log scanning:
- 🔌 Connection attempts
- ✅ Successful connection
- ❌ Connection errors
- ⚠️ Stream stalls/freezes
- 📺 General stream status
- 🔄 Reconnect attempts

### File: `lib/main.dart`

#### 1. **MainWrapper Lifecycle Handling**
```dart
class _MainWrapperState extends State<MainWrapper> with WidgetsBindingObserver {
  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      appLog('📱 App resumed - forcing stream restart...');
      setState(() {}); // Rebuild current page
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
```

#### 2. **Dashboard Lifecycle Handling**
Added same lifecycle handling to `_DashboardPageState` to trigger `_restartStream()` when app resumes:
```dart
@override
void didChangeAppLifecycleState(AppLifecycleState state) {
  if (state == AppLifecycleState.resumed) {
    appLog('📱 Dashboard: App resumed - restarting stream...');
    _restartStream();
  }
}
```

## How It Works Now

### Emulator Restart Scenario (Before Fix)
1. Emulator restarts → Network becomes unreachable
2. Stream tries to connect, timeout occurs
3. Reconnect timer starts
4. But old HTTP client still holds resources
5. New client can't connect
6. Stream stuck forever ❌

### Emulator Restart Scenario (After Fix)
1. Emulator restarts → Network becomes unreachable
2. Stream tries to connect, timeout occurs → HTTP client properly closed
3. Reconnect timer starts
4. Fresh HTTP client created, successfully connects
5. Stream resumes ✅

### App Resume Scenario (After Fix)
1. App was backgrounded during emulator restart
2. User brings app to foreground
3. `didChangeAppLifecycleState(AppLifecycleState.resumed)` fires
4. Dashboard calls `_restartStream()` 
5. Stream URL temporarily set to empty (triggers reset in widget)
6. Stream URL restored, MJPEGStream rebuilds with fresh connection
7. Stream reconnects immediately ✅

## Monitoring & Diagnostics

### Stream Status Indicators
The app now logs stream status with clear indicators:
```
🔌 Initiating MJPEG stream connection to: http://172.20.10.3:5000/video_feed
✅ MJPEG Stream connected, status: 200
📺 MJPEG Stream connection established, waiting for frames...
✅ First frame received
⚠️ No frames received for 5 seconds - stream stalled, reconnecting...
⏳ Scheduling reconnect in 1 second...
🔄 Attempting to reconnect to stream...
```

### Watchdog Triggers
- **5s no frames**: Stream has frames but then stops (server or network issue)
- **10s connected, no frames**: Connection accepted but no data flow (frozen server)

## Testing Checklist

After these changes, verify:

- [ ] **Normal Operation**: Stream connects smoothly and displays frames continuously
- [ ] **Emulator Restart**: After emulator restart, app reconnects within 5-10 seconds
- [ ] **App Background/Foreground**: Closing and reopening app restarts stream immediately
- [ ] **Network Disconnect**: Pulling network cable shows reconnecting, reconnects when available
- [ ] **Server Stop/Start**: Health check detects server offline, reconnects when online
- [ ] **UI States**: Offline → Connecting → Connected states show correctly with animations
- [ ] **No Resource Leaks**: Repeated reconnections don't consume memory (check in DevTools)

## Performance Improvements

| Aspect | Before | After | Benefit |
|--------|--------|-------|---------|
| Connection timeout | 5s | 3s | Faster failure detection |
| Watchdog interval | 5s | 2s | Faster stall detection |
| Frozen connection detection | N/A | 10s | Detects half-open connections |
| HTTP client cleanup | None | Explicit | Prevents resource leaks |
| App resume recovery | Manual restart | Automatic | UX improvement |

## Edge Cases Handled

1. **URL changes**: `didUpdateWidget()` properly resets stream state
2. **URL becomes empty**: Shows "Connecting..." and waits for new URL
3. **Rapid reconnections**: Reconnect timer prevents hammering the server
4. **App lifecycle changes**: Automatically resumes stream on app foreground
5. **Half-open connections**: Explicit client.close() prevents them accumulating

## Files Modified
- `lib/widgets/mjpeg_stream.dart` - Enhanced MJPEG stream widget with lifecycle and cleanup
- `lib/main.dart` - Added app lifecycle observing to MainWrapper and DashboardPage

## Backward Compatibility
✅ All changes are backward compatible
✅ No API changes
✅ No new dependencies
✅ Works with existing .env configuration
