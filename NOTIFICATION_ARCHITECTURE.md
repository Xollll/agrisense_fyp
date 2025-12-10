# Notification System - Architecture Diagram

## System Flow Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                     DISEASE DETECTION FLOW                          │
└─────────────────────────────────────────────────────────────────────┘

    ┌──────────────────┐
    │ Detection Server │
    │  (RTSP Stream)   │
    └────────┬─────────┘
             │
             ▼
    ┌──────────────────┐
    │ DetectionManager │
    │  .startPolling() │
    └────────┬─────────┘
             │
             ▼
    ┌──────────────────────────────────────────────────┐
    │ Disease Detected                                 │
    │ ├─ Label: "Leaf Spot"                          │
    │ ├─ Confidence: 0.92                             │
    │ └─ Solution: "Apply fungicide..."               │
    └────────┬─────────────────────────────────────────┘
             │
    ┌────────┴──────────────────────────────────────────┐
    │                                                   │
    ▼                                                   ▼
┌──────────────────────────┐           ┌──────────────────────────┐
│  NotificationService     │           │  NotificationProvider    │
│  .showNotification()     │           │  .addNotification()      │
│  (Android/iOS popup)     │           │  (In-app alert)          │
└────────┬─────────────────┘           └────────┬─────────────────┘
         │                                       │
         │                              ┌────────▼─────────────┐
         │                              │ NotificationAlert    │
         │                              │ ├─ id: "timestamp"   │
         │                              │ ├─ disease: name     │
         │                              │ ├─ confidence: 0.92  │
         │                              │ ├─ timestamp: "now"  │
         │                              │ ├─ solution: text    │
         │                              │ └─ isRead: false     │
         │                              └────────┬─────────────┘
         │                                       │
         │                              ┌────────▼──────────────┐
         │                              │ NotificationHistory   │
         │                              │ Service               │
         │                              │ .saveNotification()   │
         │                              └────────┬──────────────┘
         │                                       │
         │                              ┌────────▼──────────────┐
         │                              │ SharedPreferences     │
         │                              │ (Persistent Storage)  │
         │                              └───────────────────────┘
         │
         └──────────┬──────────────────────┐
                    │                      │
                    ▼                      ▼
          ┌──────────────────┐   ┌──────────────────┐
          │ System Alert Box │   │  Update Badge    │
          │ (Toast/Popup)    │   │  Count on AppBar │
          └──────────────────┘   └────────┬─────────┘
                                          │
                                 ┌────────▼─────────┐
                                 │ notifyListeners()│
                                 │ (Provider Event) │
                                 └────────┬─────────┘
                                          │
                                 ┌────────▼──────────────────┐
                                 │ Consumer Widget Updates    │
                                 │ AppBar Shows Badge        │
                                 │ Badge Color: Red          │
                                 │ Badge Count: Unread       │
                                 └───────────────────────────┘
```

---

## User Interaction Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                  USER INTERACTION FLOW                          │
└─────────────────────────────────────────────────────────────────┘

    USER SEES:                          WHAT HAPPENS:
┌─────────────────────┐
│ Dashboard Page      │                 NotificationProvider
│                     │                 watches notifications
│ [🔔 3] ← Tap here   │◄────────────────────┐
│                     │                      │
└─────────────────────┘                      ▼
                                    ┌──────────────────┐
                                    │ Navigator.push   │
                                    │ ('/notifications')│
                                    └────────┬─────────┘
                                             │
                                    ┌────────▼──────────┐
                                    │ NotificationList  │
                                    │ Page Opens        │
                                    └────────┬──────────┘
                                             │
                                    ┌────────▼──────────┐
                                    │ Load notifications│
                                    │ from Provider     │
                                    └────────┬──────────┘
                                             │
                                    ┌────────▼──────────┐
                                    │ markAllAsRead()   │
                                    └────────┬──────────┘
                                             │
                                    ┌────────▼──────────┐
                                    │ notifyListeners() │
                                    │ Badge count → 0   │
                                    └───────────────────┘

┌─────────────────────────────────────┐
│ NOTIFICATION LIST PAGE              │
│                                     │
│ Notifications ──── [✕] Clear All    │
│                                     │
│ 📊 Stats: 5|2|3                    │
│                                     │
│ 🚨 Leaf Spot        [92%]  [×]     │◄─── User Sees:
│ ⚠️  Powdery Mildew  [68%]  [×]     │     • Disease name
│ ℹ️  Test Alert      [45%]  [×]     │     • Confidence %
│                                     │     • Time ago
│ ┌──────────────────────────────────┐│     • Delete button
│ │ Tap card for details             ││
│ └──────────────────────────────────┘│
└─────────────────────────────────────┘
     │
     │ User taps card
     ▼
┌──────────────────────────────────┐
│ DETAIL MODAL                     │
├──────────────────────────────────┤
│ Disease Details                  │
│                                  │
│ Disease: Leaf Spot               │
│ Confidence: 92%                  │
│ Detected: 2h ago                 │
│                                  │
│ Recommendation:                  │
│ Apply copper-based fungicide...  │
│                                  │
│            [Close]               │
└──────────────────────────────────┘
```

---

## Component Dependency Graph

```
┌──────────────────────────────────────────────────────────────┐
│                    MAIN APP                                  │
└──────────────────────────────────────────────────────────────┘
              │
              ├─────────────────────────────────────────────┐
              │                                             │
              ▼                                             ▼
    ┌──────────────────────┐                  ┌─────────────────────┐
    │  MultiProvider       │                  │ MaterialApp         │
    │  ├─ ThemeProvider    │                  │ ├─ routes           │
    │  ├─ AppSettings      │                  │ │ ├─ '/dash'       │
    │  ├─ Statistics       │                  │ │ └─ '/notif'      │
    │  └─ Notifications    │◄─────────────────┼─┤                   │
    └──────────┬───────────┘                  └─────────────────────┘
               │
        ┌──────┴────────┬─────────────────────────────┐
        │               │                             │
        ▼               ▼                             ▼
    ┌─────────┐  ┌────────────┐        ┌──────────────────┐
    │Dashboard│  │ Floating   │        │ Notification     │
    │ Page    │  │ Menu       │        │ List Page        │
    │         │  │ Button     │        │                  │
    │ ┌─────┐ │  └────────────┘        │ ┌──────────────┐ │
    │ │AppBar│◄─────────────┐          │ │Stats Bar     │ │
    │ │(with │              │          │ ├──────────────┤ │
    │ │notif)│  NotificationProvider   │ │Alert Cards   │ │
    │ └─────┘ │  (watches)             │ │ • Disease    │ │
    │         │                         │ │ • Confidence │ │
    │ ┌─────┐ │  ┌─────────────────┐   │ │ • Delete     │ │
    │ │ Live │  │ Detection       │   │ └──────────────┘ │
    │ │Stream│  │ Manager         │   │ ┌──────────────┐ │
    │ └─────┘ │  │ ├─ Polls every  │   │ │Detail Modal  │ │
    │         │  │ │   10 seconds   │   │ ├──────────────┤ │
    │         │  │ ├─ Gets notif    │   │ │• Full details│ │
    │         │  │ │   provider      │   │ │• Recommend.. │ │
    │         │  │ └─ Calls add()   │   │ └──────────────┘ │
    │         │  └────────┬─────────┘   │                  │
    └─────────┘           │             └──────────────────┘
                          │
                          ▼
                  ┌────────────────┐
                  │ Notification   │
                  │ Provider       │
                  │ (ChangeNotifier│
                  │ extends)       │
                  │ ├─ Manages     │
                  │ │  alerts list │
                  │ ├─ Tracks read │
                  │ ├─ Calculates  │
                  │ │  unread      │
                  │ └─ Persists    │
                  │    via service │
                  └────────┬───────┘
                           │
                           ▼
                  ┌────────────────────┐
                  │ Notification       │
                  │ History Service    │
                  │ ├─ Save            │
                  │ ├─ Load            │
                  │ ├─ Delete          │
                  │ └─ Manage 50 items │
                  └────────┬───────────┘
                           │
                           ▼
                  ┌────────────────────┐
                  │ SharedPreferences  │
                  │ (Local Storage)    │
                  │ JSON File on device│
                  └────────────────────┘
```

---

## State Management Flow

```
┌──────────────────────────────────────────────────────────┐
│           PROVIDER STATE MANAGEMENT                      │
└──────────────────────────────────────────────────────────┘

NotificationProvider:
┌─────────────────────────────────────────────────────────────┐
│ Private Members:                                            │
│  • List<NotificationAlert> _notifications = []             │
│  • int _unreadCount = 0                                    │
│  • NotificationHistoryService _historyService             │
│                                                             │
│ Public Getters:                                            │
│  • List<NotificationAlert> notifications                  │
│  • int unreadCount                                        │
│  • int totalCount                                         │
│                                                             │
│ Public Methods:                                            │
│  • addNotification()                                       │
│  • markAsRead()                                            │
│  • markAllAsRead()                                         │
│  • deleteNotification()                                    │
│  • clearAllNotifications()                                 │
│  • getUnreadNotifications()                                │
│  • getNotificationsByDisease()                             │
│  • notifyListeners() [inherited from ChangeNotifier]       │
└─────────────────────────────────────────────────────────────┘

       │
       │ When any state changes:
       ▼
┌─────────────────────────────────────┐
│ notifyListeners() called             │
└────────────────┬────────────────────┘
                 │
    ┌────────────┴────────────┐
    │                         │
    ▼                         ▼
┌──────────────┐      ┌──────────────────┐
│ Consumer<>   │      │ context.watch<>  │
│ widgets      │      │ rebuilt          │
│ rebuild      │      │                  │
└──────────────┘      └──────────────────┘
```

---

## Data Persistence Flow

```
┌──────────────────────────────────────────────┐
│     PERSISTENCE FLOW (JSON Serialization)    │
└──────────────────────────────────────────────┘

NotificationAlert Object:
┌────────────────────────────────────┐
│ {                                  │
│   "id": "1703537400000",           │
│   "disease": "Leaf Spot",          │
│   "confidence": 0.92,              │
│   "timestamp": "2024-12-25...",    │
│   "solution": "Apply fungicide",   │
│   "isRead": false                  │
│ }                                  │
└────────────────────┬───────────────┘
                     │
                     ▼ toJson()
┌────────────────────────────────────┐
│ JSON String in SharedPreferences   │
│                                    │
│ key: 'agrisense_notifications_...' │
│ value: '[{...}, {...}, {...}]'    │
└────────────────────┬───────────────┘
                     │
                     ▼ Save
┌────────────────────────────────────┐
│ Device Local Storage               │
│ (/data/data/com.../shared_prefs)  │
└────────────────────┬───────────────┘
                     │
                     ▼ App Restart
┌────────────────────────────────────┐
│ Initialize NotificationProvider    │
│ Load notifications()               │
│ Deserialize JSON                   │
│ Rebuild UI with saved data         │
└────────────────────────────────────┘
```

---

## Color Coding System

```
┌─────────────────────────────────────────────────────────┐
│        CONFIDENCE LEVEL → VISUAL INDICATOR              │
└─────────────────────────────────────────────────────────┘

Confidence     Label      Color   Icon   UI Element
─────────────────────────────────────────────────────
> 80%        CRITICAL    🔴 Red   ⚠️    Urgent
60-80%       MEDIUM      🟠 Orange ⚠️    Important
< 60%        LOW         🟡 Yellow ℹ️   Info

Badge:
┌──────────────┐
│    🔔 5      │ ← Badge count shows unread
│   (Red)      │
└──────────────┘

Card Styling:
┌────────────────────────────┐
│ 🔴 Leaf Spot               │ ← Critical
│    Border: Red, Bold       │
│    92% - CRITICAL          │
└────────────────────────────┘

┌────────────────────────────┐
│ 🟠 Powdery Mildew         │ ← Medium
│    Border: Orange         │
│    68% - MEDIUM            │
└────────────────────────────┘

┌────────────────────────────┐
│ 🟡 Test Alert              │ ← Low
│    Border: Yellow          │
│    45% - LOW                │
└────────────────────────────┘
```

---

## Timeline: From Disease Detection to User Sees Notification

```
Time    Action                              Component
────────────────────────────────────────────────────────────
T=0     Disease detected in frame          Detection Server
        
T+100ms Fetch detection data               DetectionManager
        
T+200ms Validate detection (>1% conf)      DetectionService
        
T+300ms Generate AI recommendation         GeminiService
        
T+400ms Create NotificationAlert           NotificationProvider
        
T+450ms Save to SharedPreferences          NotificationHistory
        
T+500ms Call notifyListeners()             Provider
        
T+550ms AppBar Consumer rebuilds           Consumer<Provider>
        
T+600ms Badge count updates                AppBar Widget
        
T+650ms Show system notification           NotificationService
        
T+700ms System alert popup appears         Android/iOS
        
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
TOTAL TIME: ~700ms (< 1 second)

User Experience:
  🔴 Badge appears with count
  🔔 System notification pops up
  💾 Data saved persistently
```

---

## Error Handling Flow

```
┌──────────────────────────────────────────────┐
│          ERROR HANDLING STRATEGY              │
└──────────────────────────────────────────────┘

Detection Phase:
  ├─ Low confidence (< 1%)? → Skip, don't notify
  └─ Error fetching? → Log, return empty

Notification Phase:
  ├─ Notification Service error? → Log, continue
  ├─ Provider error? → Catch, log, UI unaffected
  └─ Storage error? → In-memory list still works

UI Phase:
  ├─ Navigation fails? → Try-catch, show snackbar
  ├─ Deserialization fails? → Start fresh
  └─ Build error? → Error widget displayed

All errors logged to console with:
  ✅ ✅ Prefix → Success
  ⚠️ Prefix → Warning
  ❌ Prefix → Error
```

---

That's the complete architecture! Every part of the notification system visualized! 📊
