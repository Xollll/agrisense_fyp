# 🎬 AUTO-REFRESH MECHANISM - VISUAL FLOW DIAGRAM

## System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        DashboardPage                             │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  initState():                                                     │
│  ├─ Start detection polling (700ms interval)                     │
│  ├─ Start server health check (2 second interval) ⭐ NEW          │
│  └─ Call _checkServerHealth() once immediately                   │
│                                                                   │
│  Every 2 seconds:                                                │
│  ├─ _checkServerHealth()                                         │
│  │  ├─ HTTP HEAD to 'http://server:5000/health'                 │
│  │  ├─ Check response status == 200                              │
│  │  └─ If status changed: trigger _restartStream()             │
│  │                                                               │
│  └─ _restartStream() ⭐ NEW                                      │
│     ├─ Clear _streamUrl (set to empty '')                       │
│     ├─ Wait 500ms                                               │
│     └─ Restore _streamUrl to full URL                           │
│        └─ Triggers didUpdateWidget() in MJPEGStream            │
│                                                                   │
│  dispose():                                                      │
│  ├─ Cancel detection timer                                       │
│  └─ Cancel server check timer ⭐ NEW                             │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
           │
           │ passes _streamUrl
           │
           ▼
┌─────────────────────────────────────────────────────────────────┐
│                    LiveStreamWidget                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  _updateStreamStatus(isConnected, isConnecting):                │
│  ├─ Update _liveStatus based on connection state                │
│  └─ Trigger AnimatedLiveIndicator animation                     │
│                                                                   │
│  didUpdateWidget():                                              │
│  ├─ If streamUrl changed → reset _liveStatus                    │
│                                                                   │
│  MJPEGStream:                                                    │
│  ├─ Receives streamUrl                                          │
│  └─ Passes _updateStreamStatus callback                         │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
           │
           │ passes onStatusChanged callback
           │
           ▼
┌─────────────────────────────────────────────────────────────────┐
│                    MJPEGStream Widget                            │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  initState():                                                    │
│  └─ Call _startStream()                                          │
│                                                                   │
│  didUpdateWidget(): ⭐ ENHANCED                                  │
│  ├─ If url changed:                                              │
│  │  ├─ Cancel previous subscription                             │
│  │  ├─ Cancel reconnect timer                                   │
│  │  ├─ Clear _currentFrame                                      │
│  │  ├─ Set _shouldShowFrame = false                             │
│  │  └─ Call _startStream()                                      │
│  │                                                               │
│  _startStream(): ⭐ ENHANCED                                     │
│  │                                                               │
│  ├─ If url is empty:                                            │
│  │  ├─ Set state: disconnected, not showing                     │
│  │  └─ Return (don't try to connect)                            │
│  │                                                               │
│  ├─ Try HTTP connection with 5-second timeout:                  │
│  │  │                                                            │
│  │  ├─ ✅ Success:                                              │
│  │  │  ├─ Set _isConnected = true                              │
│  │  │  ├─ Set _shouldShowFrame = true                          │
│  │  │  ├─ Call onStatusChanged(true, false)                    │
│  │  │  └─ Parse MJPEG stream frames                            │
│  │  │     └─ Only update UI if _shouldShowFrame                │
│  │  │                                                            │
│  │  ├─ ❌ onError or onDone:                                    │
│  │  │  ├─ Set _isConnected = false                             │
│  │  │  ├─ Set _shouldShowFrame = false                         │
│  │  │  ├─ Clear _currentFrame ⭐ NEW! (no stale frame)         │
│  │  │  ├─ Call onStatusChanged(false, false)                   │
│  │  │  └─ Schedule reconnect after 3 seconds                   │
│  │  │                                                            │
│  │  └─ ⏱️ Exception (timeout, etc):                             │
│  │     ├─ Set _isConnected = false                              │
│  │     ├─ Clear _currentFrame ⭐ NEW!                           │
│  │     ├─ Call onStatusChanged(false, false)                    │
│  │     └─ Schedule reconnect after 3 seconds                    │
│  │                                                               │
│  dispose():                                                      │
│  ├─ Cancel stream subscription                                   │
│  └─ Cancel reconnect timer ⭐ NEW                                │
│                                                                   │
│  build():                                                        │
│  └─ If _currentFrame == null:                                   │
│     └─ Show loading spinner                                      │
│     └─ Else: Show image frame                                   │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
           │
           │ calls onStatusChanged()
           │
           ▼
┌─────────────────────────────────────────────────────────────────┐
│              AnimatedLiveIndicator Widget                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  Status Display:                                                 │
│  ├─ CONNECTED: 🟢 Green + Flicker animation                    │
│  ├─ CONNECTING: 🟡 Yellow + Pulse animation                    │
│  └─ DISCONNECTED: 🔴 Red + Static                              │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
```

## Timeline: Flask Server Starts

```
Time(s)  │ Event                              │ UI State
─────────┼────────────────────────────────────┼──────────────────
  0.0    │ Flask server starts                │ 🔴 DISCONNECTED
         │                                    │ (Showing loading)
─────────┼────────────────────────────────────┼──────────────────
  2.0    │ Health check detects server online │ 🟡 CONNECTING
         │ _restartStream() triggers          │ (Loading spinner)
         │ _streamUrl = '' (temporarily)      │
─────────┼────────────────────────────────────┼──────────────────
  2.5    │ MJPEGStream detects URL change     │ 🟡 CONNECTING
         │ _startStream() called              │ (Loading spinner)
         │ _streamUrl restored to full URL    │
─────────┼────────────────────────────────────┼──────────────────
  3.0    │ MJPEGStream connects successfully  │ 🟢 CONNECTED
         │ First MJPEG frame received         │ (Live video)
         │ _shouldShowFrame = true            │
─────────┼────────────────────────────────────┼──────────────────
  3.2    │ Animation activates (flicker)      │ 🟢 CONNECTED
         │ Frames continuously flowing        │ (Smooth video)
─────────┴────────────────────────────────────┴──────────────────
```

## Timeline: Flask Server Stops

```
Time(s)  │ Event                              │ UI State
─────────┼────────────────────────────────────┼──────────────────
  0.0    │ Flask server running               │ 🟢 CONNECTED
         │                                    │ (Live video)
─────────┼────────────────────────────────────┼──────────────────
  1.0    │ Flask server stopped               │ 🟢 CONNECTED
         │ (still streaming old data)         │ (Last frame)
─────────┼────────────────────────────────────┼──────────────────
  2.0    │ Health check detects server down   │ 🟡 CONNECTING
         │ _isServerOnline = false            │ (Shows last frame)
─────────┼────────────────────────────────────┼──────────────────
  3.0    │ MJPEGStream detects disconnect     │ 🔴 DISCONNECTED
         │ onDone/onError triggered           │ (Clear frame!)
         │ _currentFrame = null ⭐            │ (Loading spinner)
         │ _shouldShowFrame = false           │
         │ onStatusChanged(false, false)      │
─────────┼────────────────────────────────────┼──────────────────
  6.0    │ Auto-reconnect attempt #1          │ 🟡 CONNECTING
         │ (Still offline)                    │ (Loading spinner)
─────────┼────────────────────────────────────┼──────────────────
  9.0    │ Auto-reconnect attempt #2          │ 🟡 CONNECTING
         │ (Still offline)                    │ (Loading spinner)
─────────┼────────────────────────────────────┼──────────────────
 12.0    │ Flask server restarts              │ 🟡 CONNECTING
         │                                    │ (Loading spinner)
─────────┼────────────────────────────────────┼──────────────────
 12.5    │ Auto-reconnect succeeds            │ 🟢 CONNECTED
         │ Frames flowing again               │ (Live video)
─────────┴────────────────────────────────────┴──────────────────
```

## Key Differences: Before vs After

### Before ❌
```
Offline Server:
  1. Server stops
  2. Stream gets error
  3. Last frame persists on screen indefinitely ❌
  4. Indicator shows OFFLINE
  5. User sees stale data (confusing!)
  6. Must navigate away → back to fix

Online Server:
  1. Server starts
  2. Stream already connected (before server started)
  3. On connection error, no auto-reconnect ❌
  4. User must navigate away → back to reload
```

### After ✅
```
Offline Server:
  1. Server stops
  2. Stream gets error
  3. Frame immediately cleared ✅
  4. Indicator shows DISCONNECTED
  5. Loading spinner shows (user knows it's trying)
  6. Auto-reconnect every 3 seconds ✅
  7. When server restarts, auto-connects within 3 seconds

Online Server:
  1. Server starts
  2. Health check detects it (every 2 seconds)
  3. Stream restart triggered automatically ✅
  4. Reconnects within 2-3 seconds ✅
  5. User sees live video without any action
```

## Why This Works

| Component | Why It Matters |
|-----------|---------------|
| **Health Check** | Detects server status changes independently of stream state |
| **Stream Restart** | Forces MJPEGStream to reconnect by toggling URL |
| **Frame Clearing** | Prevents stale data from confusing users |
| **Auto-Reconnect** | Keeps trying until server is available again |
| **Timeout** | Detects dead servers faster (5-second timeout) |
| **Callback** | Keeps UI in sync with actual connection state |

## No Manual Navigation Required ✅

The system automatically:
- Detects server availability
- Clears stale frames
- Shows loading state
- Retries connection
- Updates indicator in real-time

**User just opens the app and watches it work!** 📱✨
