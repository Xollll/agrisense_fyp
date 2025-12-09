# 🎬 Live Stream Auto-Refresh Visual Guide

## 🎯 Before vs After Comparison

### BEFORE (Problems)

```
Flask Server OFF              Flask Server ON
       ↓                              ↓
No stream available          Stream available
       ↓                              ↓
   🔴 RED?                      🟢 GREEN?
       ↓                              ↓
   (Stuck loading)           (But URL exists)
       ↓                              ↓
   ❌ Manual navigation needed to refresh!
```

### AFTER (Fixed!)

```
Flask Server OFF              Flask Server ON
       ↓                              ↓
No stream available          Stream available
       ↓                              ↓
Auto-detects                  Auto-detects
       ↓                              ↓
🔴 RED (shows              🟢 GREEN (streams
loading spinner)           live) ✨
       ↓                              ↓
Auto-reconnects           No navigation
every 3 seconds          needed! ✨
```

---

## 📊 Timeline Examples

### Example 1: Starting Flask During App Use

```
0:00 - App is open, stream is offline
       Indicator: 🔴 RED
       Screen: Loading spinner
       
         (You start Flask server)
         
0:01 - didUpdateWidget() detects streamUrl change
       Calls _startStream() automatically
       Indicator: 🟡 YELLOW (connecting)
       
0:02 - MJPEG successfully connects
       Indicator: 🟢 GREEN (flicker animation)
       Screen: Live video playing ✨
       
Result: NO page navigation needed! ✨
```

### Example 2: Stopping Flask During App Use

```
0:00 - App is open, stream is live
       Indicator: 🟢 GREEN (flickering)
       Screen: Live video playing
       
         (You stop Flask server)
         
0:01 - MJPEG stream gets error
       Indicator: 🔴 RED
       Screen: Loading spinner
       onStatusChanged(false, false)
       
0:02 - Auto-reconnect timer starts
       Waits 3 seconds...
       
0:05 - First reconnect attempt
       Flask still down... fails
       Timer restarts (3 seconds)
       
0:10 - User restarts Flask server
       
0:11 - Auto-reconnect attempt succeeds!
       Indicator: 🟢 GREEN (flicker)
       Screen: Live video playing ✨
       
Result: Automatic reconnection! ✨
```

### Example 3: Brief Network Issue

```
0:00 - Streaming live
       Indicator: 🟢 GREEN
       
0:15 - Network glitch
       Connection drops
       Indicator: 🔴 RED
       Loading spinner appears
       
0:18 - Auto-reconnect fires
       Network recovered
       Connection succeeds!
       
0:19 - Back to normal
       Indicator: 🟢 GREEN
       Live video playing
       
Result: Brief red indicator, auto-recovered! ✨
```

---

## 🔄 State Transition Diagram

```
                    ┌─────────────────────┐
                    │  App Load / Start   │
                    └──────────┬──────────┘
                               │
                               ▼
                    ┌─────────────────────┐
                    │  Check streamUrl    │
                    │  if empty → 🔴 RED  │
                    └──────────┬──────────┘
                               │
                               ▼
                    ┌─────────────────────┐
         ┌─────────→│  didUpdateWidget()  │◄─────────┐
         │          │  URL changed?       │          │
         │          └──────────┬──────────┘          │
         │                     │                     │
    YES │                  NO  │                 YES │
         │                     │                     │
         │          ┌──────────▼────────┐            │
         │          │ _startStream()    │            │
         │          │ Try to connect    │            │
         │          └──────────┬────────┘            │
         │                     │                     │
         │        ┌────────────┼────────────┐        │
         │        │            │            │        │
         │      SUCCESS       ERROR       DONE       │
         │        │            │            │        │
         │        ▼            ▼            ▼        │
         │    ┌────────┐   ┌────────┐   ┌────────┐  │
         │    │SUCCESS │   │RETRY   │   │RETRY   │  │
         │    │🟢GREEN │   │🟡YELLOW    │🟡YELLOW   │
         │    │ STREAM │   │ WAIT    │   │ WAIT    │  │
         │    └────────┘   │ 3 SECS  │   │ 3 SECS  │  │
         │        │        └────────┘   └────────┘   │
         │        │              │           │        │
         │        │              └─────┬─────┘        │
         │        │                    │              │
         └────────┴────────────────────┘              │
                        │                             │
           ┌────────────┴─────────────┐               │
           │                          │               │
        Still                   URL changes      (auto-retry)
        offline?                to empty?
           │                          │
           NO                        YES
           │                          │
           ▼                          ▼
      Retry                     🔴 RED
      (wait 3)                DISCONNECTED
                              ← Reset & return to start
```

---

## 💻 Code Flow Visualization

### When Flask Starts

```
Flask starts
    │
    ├─ streamUrl changes to "http://localhost:5000/stream"
    │
    └─→ LiveStreamWidget receives new streamUrl
         │
         └─→ MJPEGStream.didUpdateWidget() detects change
             │
             └─→ Calls _startStream() immediately!
                 │
                 ├─ Cancel old connection
                 │
                 └─→ HTTP connection attempt
                     │
                     ├─ Success!
                     │  ├─ setState(_isConnected = true)
                     │  └─ onStatusChanged(true, false) callback
                     │      │
                     │      └─→ LiveStreamWidget._updateStreamStatus()
                     │          ├─ _liveStatus = LiveStatus.connected
                     │          └─ setState()
                     │              │
                     │              └─→ AnimatedLiveIndicator updates
                     │                  │
                     │                  └─→ Shows 🟢 GREEN (flicker)
                     │
                     └─ Stream frames start flowing
                        │
                        └─→ Display live video! ✨
```

### When Flask Stops

```
Flask stops
    │
    ├─ MJPEG stream gets error or onDone
    │
    └─→ onError() / onDone() callback fires
        │
        ├─ setState(_isConnected = false)
        │
        ├─ onStatusChanged(false, false) callback
        │  │
        │  └─→ LiveStreamWidget._updateStreamStatus()
        │      ├─ _liveStatus = LiveStatus.disconnected
        │      └─ setState()
        │          │
        │          └─→ AnimatedLiveIndicator updates
        │              │
        │              └─→ Shows 🔴 RED (static)
        │
        └─ Start _reconnectTimer
           │
           └─→ Wait 3 seconds
               │
               └─→ Timer fires → Call _startStream() again
                   │
                   └─→ Try to reconnect automatically!
```

---

## 🔌 Connection Status Flow

```
┌─────────────────────────────────────────────────┐
│         MJPEG Stream Connection States          │
├─────────────────────────────────────────────────┤
│                                                 │
│  ① CONNECTING (Starting)                        │
│     _isConnecting = true                        │
│     _isConnected = false                        │
│     onStatusChanged(false, true)                │
│     Indicator: 🟡 YELLOW (pulsing)              │
│                                                 │
│  ② CONNECTED (Active)                          │
│     _isConnecting = false                       │
│     _isConnected = true                         │
│     onStatusChanged(true, false)                │
│     Indicator: 🟢 GREEN (flickering)            │
│     Display: Live video frames                  │
│                                                 │
│  ③ DISCONNECTED (Error/Done)                   │
│     _isConnecting = false                       │
│     _isConnected = false                        │
│     onStatusChanged(false, false)               │
│     Indicator: 🔴 RED (static)                  │
│     Display: Loading spinner                    │
│     Action: Start retry timer                   │
│                                                 │
│  ④ RETRY (Auto-reconnect)                      │
│     Wait 3 seconds                              │
│     Then return to ① CONNECTING                 │
│                                                 │
└─────────────────────────────────────────────────┘
```

---

## 📱 UI Updates

### Before Fix

```
┌─────────────────────────────┐
│ Flask OFF → 🟢 GREEN        │ ← Wrong! (Stuck)
│ Flask ON → Still Loading    │ ← Need to navigate
└─────────────────────────────┘
```

### After Fix

```
┌─────────────────────────────┐
│ Flask OFF → 🔴 RED + Spinner│ ← Correct!
│             Auto-reconnects │ ← No navigation
│                             │
│ Flask ON → 🟢 GREEN + Video │ ← Correct!
│            Auto-refreshes   │ ← No navigation
└─────────────────────────────┘
```

---

## ⏱️ Timing Diagram

### Scenario: Flask Server Cycles

```
Time:      0s    3s    6s    9s   12s   15s   18s   21s
           │     │     │     │    │     │     │     │
Flask:     ◀─────ON────→│◀────OFF──→│◀────ON────→
                        
MJPEG:     🟢 🟢 🟢 🔴  🟡  🔴 🟡  🔴 🟡  🔴  🟢  🟢
           LIVE│  RED  CONNECTING...  RED  CONNECTING... LIVE
                │     (retry timer)       (retry timer)
                └─ Detects change
                
Display:   Video│ Spinner Spinner Spinner Spinner Video
                │ (loading) (retry)  (retry)  (retry) (live)
```

---

## 🎯 Key Improvements

| Aspect | Before | After |
|--------|--------|-------|
| **Flask starts** | Manual navigation | Auto-refresh ✨ |
| **Flask stops** | Stuck on frame | Shows RED + spinner |
| **Reconnection** | Manual only | Auto every 3s ✨ |
| **Network glitch** | Stuck | Auto-recovers ✨ |
| **User action needed** | ❌ YES | ✅ NO |
| **Status accuracy** | ❌ Wrong | ✅ Correct |

---

## 🔍 How didUpdateWidget() Works

```
didUpdateWidget() called every time widget parameters change
                      │
                      ▼
         Check if streamUrl changed?
                   │
        ┌──────────┴──────────┐
        │                     │
       YES                   NO
        │                     │
        ▼                     ▼
    Cancel old         Do nothing
    subscription
        │
        ▼
    Clear frame buffer
        │
        ▼
    _startStream()
        │
        ▼
    New connection
        │
        └─→ Success/Failure logic
```

---

## ⚙️ Timer Mechanism

```
Connection fails
        │
        ▼
_reconnectTimer = Timer(3 seconds)
        │
        ├─ User keeps app open
        │  ├─ After 3 seconds
        │  └─ Timer callback fires
        │     │
        │     └─→ _startStream() called again
        │         │
        │         └─ If Flask is back: Connect! 🟢
        │         └─ If Flask is down: Set another timer
        │
        └─ User closes widget
           │
           └─→ dispose() cancels timer
               (No memory leak!) ✅
```

---

## 📊 Performance Impact

```
Before: Checking URL only
        └─ Cost: Minimal
        └─ Accuracy: Low (stuck frames)

After:  Monitoring actual connection
        ├─ HTTP connection attempts (every 3s when down)
        ├─ Frame parsing (only when connected)
        ├─ Status callbacks
        └─ Cost: Still minimal (only 3 seconds apart)
        └─ Accuracy: High (real-time state)
```

---

## ✅ Testing Visual

```
Test Case 1: Flask Running
┌─ Start app
├─ Flask is running
└─ Expected: 🟢 GREEN, video playing ✓

Test Case 2: Flask Stopped
┌─ Start app with Flask off
├─ Flask is not running
└─ Expected: 🔴 RED, spinner, auto-retry ✓

Test Case 3: Start Flask
┌─ App open, Flask off (🔴 RED)
├─ Start Flask server
└─ Expected: Auto-connects, 🟢 GREEN ✓

Test Case 4: Stop Flask
┌─ App open, Flask on (🟢 GREEN)
├─ Stop Flask server
└─ Expected: 🔴 RED, spinner, auto-retry ✓

Test Case 5: Network Glitch
┌─ Streaming live (🟢 GREEN)
├─ Brief network issue
├─ Network recovers
└─ Expected: Brief 🔴 RED, auto-recovers to 🟢 GREEN ✓
```

---

**Status**: ✅ Complete & Tested
**No More Manual Navigation**: 🎉
**Auto-Refresh**: ✨ Working
