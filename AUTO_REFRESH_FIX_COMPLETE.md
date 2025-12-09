# ✅ AUTO-REFRESH FIX - COMPLETE SOLUTION

## Problem Summary
The dashboard had two issues that required manual navigation to refresh:
1. **When Flask server starts**: Indicator remained disconnected until you navigated to another page and back
2. **When Flask server stops**: Indicator turned offline, but last frame stuck on screen until you navigated away and back

## Root Causes

### Issue 1: Stream URL is Static
- The stream URL was hardcoded and never changed, so `didUpdateWidget()` in `MJPEGStream` never detected a change
- The MJPEGStream component had no way to know the server became available again
- No auto-reconnect mechanism existed for offline → online transitions

### Issue 2: Last Frame Persists After Disconnect
- When stream closed or error occurred, the UI still showed the cached frame
- No mechanism to clear the frame when disconnected
- UI state didn't properly reflect the actual connection state

## Solution Overview

### 1. **Server Health Monitoring (DashboardPage)**
Added periodic server health checks that:
- Ping the Flask server every 2 seconds
- Detect when server transitions from offline → online or vice versa
- Trigger stream restart when server comes back online
- Force stream restart by toggling stream URL (empty → full)

### 2. **Enhanced MJPEGStream Widget**
Improved connection handling:
- Added `_shouldShowFrame` flag to control frame display
- Clear `_currentFrame` on errors/disconnect (not just on new URL)
- Added connection timeout (5 seconds) to detect dead servers faster
- Retry connection automatically after 3 seconds on any error
- Clear frame before reconnecting

### 3. **Cleaner Stream State Management**
- Reset frame when URL changes (via `didUpdateWidget`)
- Reset frame on connection errors
- Reset frame on stream close
- Show loading spinner during connection attempts
- Only display frame when actively receiving data

## Code Changes

### File: `lib/main.dart` (DashboardPage)

**Added:**
```dart
// Server health check variables
Timer? _serverCheckTimer;
bool _isServerOnline = false;
String _streamUrl = "http://192.168.8.6:5000/video_feed"; // Now dynamic!

// Initialize in initState()
_serverCheckTimer = Timer.periodic(
  const Duration(seconds: 2),
  (_) => _checkServerHealth(),
);

// New method: Check server every 2 seconds
Future<void> _checkServerHealth() async {
  final baseUrl = dotenv.env['DETECTION_SERVER_URL'] ?? 'http://192.168.8.6:5000';
  try {
    final response = await http.head(
      Uri.parse('$baseUrl/health'),
    ).timeout(const Duration(seconds: 2));
    
    final isOnline = response.statusCode == 200;
    
    // If server status changed, trigger stream restart
    if (isOnline != _isServerOnline && mounted) {
      setState(() {
        _isServerOnline = isOnline;
      });
      
      if (isOnline) {
        print('✅ Server is online - triggering stream restart');
        _restartStream();
      }
    }
  } catch (e) {
    if (_isServerOnline && mounted) {
      setState(() {
        _isServerOnline = false;
      });
    }
  }
}

// New method: Force stream restart by toggling URL
void _restartStream() {
  if (mounted) {
    setState(() {
      _streamUrl = ''; // Temporarily empty
    });
    
    // Restore after 500ms
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _streamUrl = "${dotenv.env['DETECTION_SERVER_URL'] ?? 'http://192.168.8.6:5000'}/video_feed";
        });
      }
    });
  }
}

// Update dispose()
void dispose() {
  _detectionTimer?.cancel();
  _serverCheckTimer?.cancel(); // NEW!
  super.dispose();
}
```

### File: `lib/widgets/mjpeg_stream.dart`

**Added:**
```dart
bool _shouldShowFrame = false; // Only show if actively connected

// In _startStream():
if (widget.url.isEmpty) {
  setState(() {
    _isConnecting = false;
    _isConnected = false;
    _shouldShowFrame = false;
  });
  return;
}

// Add connection timeout
final response = await client.send(request).timeout(
  const Duration(seconds: 5),
  onTimeout: () {
    throw TimeoutException('Stream connection timeout');
  },
);

// On success
setState(() {
  _shouldShowFrame = true; // Show frames only when connected
});

// On error/disconnect - CLEAR THE FRAME!
setState(() {
  _isConnecting = false;
  _isConnected = false;
  _shouldShowFrame = false;
  _currentFrame = null; // Clear cached frame!
});

// Only update UI if actively connected
if (mounted && _shouldShowFrame) setState(() {});
```

## How It Works - Step by Step

### Scenario 1: Flask Server Starts ✅
```
1. Flask server starts at http://192.168.8.6:5000
2. DashboardPage runs _checkServerHealth() every 2 seconds
3. Health check succeeds (statusCode 200)
4. _isServerOnline changes from false → true
5. _restartStream() is triggered:
   - _streamUrl = '' (empty)
   - MJPEGStream detects URL change in didUpdateWidget()
   - MJPEGStream clears _currentFrame and _subscription
   - After 500ms, _streamUrl is restored to "http://192.168.8.6:5000/video_feed"
   - MJPEGStream detects URL change again
   - _startStream() connects to the server
   - _shouldShowFrame = true
   - Frames start displaying immediately
6. Indicator shows "CONNECTED" (green, flicker animation)
```

### Scenario 2: Flask Server Stops ✅
```
1. Flask server stops
2. DashboardPage runs _checkServerHealth() every 2 seconds
3. Health check fails (timeout or connection error)
4. _isServerOnline changes from true → false
5. Nothing happens (no stream restart needed for offline)
6. MJPEGStream detects stream error (response.stream closes)
7. onDone or onError callback triggers:
   - _isConnected = false
   - _shouldShowFrame = false
   - _currentFrame = null (FRAME IS CLEARED!)
   - setState() shows loading spinner
   - Auto-reconnect timer starts (3 seconds)
8. Indicator shows "OFFLINE" (red, static)
9. On retry, stream still can't connect
10. Loading spinner persists (user knows it's trying)
11. User doesn't see stale frame anymore!
```

### Scenario 3: Auto-Reconnect Loop ✅
```
1. Server offline, stream disconnected
2. MJPEGStream triggers auto-reconnect every 3 seconds
3. On each retry attempt:
   - Loading spinner shows
   - Frame is cleared
   - Connection attempt is made
4. When server comes back online:
   - Next retry succeeds
   - Frame starts updating immediately
   - No manual navigation needed!
```

## Benefits

| Before | After |
|--------|-------|
| ❌ Manual navigation required | ✅ Automatic refresh |
| ❌ Stale frame persists | ✅ Frame clears on disconnect |
| ❌ Offline server shows last image | ✅ Shows loading spinner |
| ❌ No server detection | ✅ 2-second health checks |
| ❌ User confused about state | ✅ Clear visual feedback |

## Testing Checklist

- [ ] Start Flask server → Stream shows immediately (no reload needed)
- [ ] Stop Flask server → Indicator turns red, loading spinner appears (no stale frame)
- [ ] Restart Flask server → Stream reconnects automatically
- [ ] Close and reopen app → Stream reconnects on its own
- [ ] Poor network → Auto-reconnects every 3 seconds
- [ ] Server offline for 10+ seconds → Shows loading, not stale frame
- [ ] Check animations are smooth (no UI jank)

## Configuration

**Server Health Check Interval:** 2 seconds (in `_checkServerHealth()`)
```dart
Timer.periodic(const Duration(seconds: 2), ...)
```

**Auto-Reconnect Interval:** 3 seconds (in `mjpeg_stream.dart`)
```dart
Timer(const Duration(seconds: 3), ...)
```

**Connection Timeout:** 5 seconds (in `mjpeg_stream.dart`)
```dart
.timeout(const Duration(seconds: 5))
```

These can be tuned based on network conditions.

## Known Behaviors

1. **Server unreachable for 2+ seconds** → Detected and stream restart triggered
2. **Empty URL** → MJPEGStream shows loading spinner
3. **Frame cleared on disconnect** → User always sees current state
4. **Auto-reconnect continues indefinitely** → Until server comes back
5. **Health check is lightweight** → Uses HTTP HEAD request (minimal bandwidth)

## Files Modified

1. `lib/main.dart` - Added server health monitoring to DashboardPage
2. `lib/widgets/mjpeg_stream.dart` - Added frame clearing and better error handling
3. `lib/widgets/live_stream_widget.dart` - No changes (already uses callbacks correctly)

## Next Steps (Optional)

- Add user settings to configure health check interval
- Show network status badge with more details
- Add connection quality indicator (frame rate, bandwidth)
- Implement connection retry backoff (exponential)
- Add system notifications for connection state changes
