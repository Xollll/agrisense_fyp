# AgriSense Notification System Implementation Guide

## Overview
The notification system in AgriSense is a comprehensive solution that manages disease detection alerts and displays them both as system notifications and within the app. When a disease is detected, users receive:

1. **System Notifications** - Push notifications with disease details
2. **In-App Badge** - Notification icon on the dashboard with unread count
3. **Notification History** - Persistent list of all detection alerts

## Architecture

### Components

#### 1. **NotificationProvider** (`lib/providers/notification_provider.dart`)
- **Purpose**: State management for notifications using the Provider pattern
- **Key Features**:
  - Manages list of `NotificationAlert` objects
  - Tracks read/unread status
  - Calculates unread count for badge
  - Persists notifications using `NotificationHistoryService`

**Key Methods**:
```dart
addNotification()          // Add new notification when disease detected
markAsRead()              // Mark single notification as read
markAllAsRead()           // Mark all notifications as read
deleteNotification()      // Delete specific notification
clearAllNotifications()   // Clear all notifications
getUnreadNotifications()  // Get only unread alerts
```

#### 2. **NotificationHistoryService** (`lib/services/notification_history_service.dart`)
- **Purpose**: Persists notifications to SharedPreferences
- **Storage Limit**: Keeps last 50 notifications
- **Features**:
  - Load notifications from storage
  - Save new notifications
  - Update notification status
  - Delete notifications
  - Clear all notifications

#### 3. **NotificationListPage** (`lib/screens/notification_list_page.dart`)
- **Purpose**: Beautiful UI for viewing all notifications
- **Features**:
  - List of all disease detection alerts
  - Stats bar showing total, critical, and info notifications
  - Individual card details with disease, confidence, and timestamp
  - Bottom sheet modal for detailed notification info
  - Delete and clear functionality
  - Auto-marks notifications as read when page opens

#### 4. **DetectionManager** (`lib/services/detection_manager.dart`)
- **Updated**: Now integrates with `NotificationProvider`
- **Flow**: When disease detected → Show system notification → Add to app notification list

#### 5. **Enhanced App Bar** (`lib/widgets/enhanced_app_bar.dart`)
- **Updated**: Notification icon with badge
- **Badge Shows**: Unread notification count
- **On Tap**: Navigates to `NotificationListPage`

---

## Data Flow

```
Disease Detected (Detection Manager)
        ↓
Show System Notification (NotificationService)
        ↓
Add to NotificationProvider
        ↓
Save to SharedPreferences (NotificationHistoryService)
        ↓
Update Badge Count on Dashboard
        ↓
User taps notification icon
        ↓
Open NotificationListPage
        ↓
Mark all as read
        ↓
Display notification history with details
```

---

## NotificationAlert Model

```dart
class NotificationAlert {
  final String id;              // Unique identifier (timestamp)
  final String disease;         // Disease name
  final double confidence;      // Detection confidence (0.0 - 1.0)
  final String timestamp;       // Detection time
  final String solution;        // AI recommendation
  bool isRead;                 // Read status
}
```

---

## Integration Steps

### Step 1: Initialize in main()
✅ Already done. The notification system is initialized in `main.dart`:

```dart
final notificationProvider = NotificationProvider();
detectionManager.setNotificationProvider(notificationProvider);
```

### Step 2: Add to MultiProvider
✅ Already done. NotificationProvider is available to all widgets:

```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider.value(value: notificationProvider),
    // ... other providers
  ],
)
```

### Step 3: Add Route
✅ Already done. Route is registered in MaterialApp:

```dart
routes: {
  '/notifications': (context) => const NotificationListPage(),
}
```

### Step 4: Update Dashboard AppBar
✅ Already done. AppBar shows unread count:

```dart
Consumer<NotificationProvider>(
  builder: (context, notificationProvider, child) {
    return AppBarBuilder.dashboard(
      notificationCount: notificationProvider.unreadCount,
    );
  },
)
```

---

## Features

### ✅ Automatic Detection
When the detection service finds a disease:
1. System notification is shown (via NotificationService)
2. Alert is added to NotificationProvider
3. Badge count updates automatically
4. Notification is saved to persistent storage

### ✅ Badge with Unread Count
- Shows on dashboard app bar
- Updates in real-time as new notifications arrive
- Hides when count is 0

### ✅ Notification List Page
Features when user taps the notification icon:
- **Empty State**: Shows message when no notifications
- **Stats Bar**: Total, critical (>80%), and info alerts
- **Alert Cards**:
  - Disease name
  - Confidence level with color coding
  - Time ago
  - Delete button
- **Detail Modal**: Shows full recommendation on tap
- **Clear All**: Button to clear all notifications
- **Auto-Read**: Marks all as read when page opens

### ✅ Persistent Storage
- Notifications saved to SharedPreferences
- Survives app restart
- Limited to 50 most recent notifications
- Uses JSON serialization

### ✅ Color Coding by Confidence
```
> 80%  → Red (Critical)
60-80% → Orange (Medium)  
< 60%  → Yellow (Low)
```

---

## Usage

### For Developers

#### To add a notification programmatically:
```dart
final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
await notificationProvider.addNotification(
  disease: 'Leaf Spot',
  confidence: 0.92,
  solution: 'Apply fungicide...',
);
```

#### To mark notification as read:
```dart
await notificationProvider.markAsRead(notificationId);
```

#### To delete a notification:
```dart
await notificationProvider.deleteNotification(notificationId);
```

#### To get unread count:
```dart
int unreadCount = Provider.of<NotificationProvider>(context).unreadCount;
```

### For Users

1. **View Notifications**: Tap the bell icon on the dashboard
2. **See Details**: Tap any notification card
3. **Delete**: Tap the X button on a card
4. **Clear All**: Tap "Clear All" button
5. **Auto-Mark Read**: Opening the list marks all as read

---

## File Structure
```
lib/
├── providers/
│   └── notification_provider.dart       ← State management
├── services/
│   ├── detection_manager.dart           ← Updated for notifications
│   ├── notification_history_service.dart ← Persistence
│   └── notification_service.dart        ← System notifications
├── screens/
│   └── notification_list_page.dart      ← UI for notification list
├── widgets/
│   └── enhanced_app_bar.dart            ← Updated with notification icon
└── main.dart                             ← App setup & routes
```

---

## Testing

### Manual Testing Steps:
1. Start the app
2. Open dashboard - notification icon visible in app bar
3. Trigger a disease detection (via RTSP stream or manual test)
4. Verify:
   - System notification appears
   - Badge count increases
   - Check notification list page
   - Click notification to see details
   - Delete/clear notifications

### Unit Test Example (if needed):
```dart
test('addNotification increases unread count', () async {
  final provider = NotificationProvider();
  
  await provider.addNotification(
    disease: 'Test Disease',
    confidence: 0.8,
    solution: 'Test solution',
  );
  
  expect(provider.unreadCount, 1);
  expect(provider.totalCount, 1);
});
```

---

## Future Enhancements

Possible improvements:
- [ ] Filter notifications by disease type
- [ ] Search functionality
- [ ] Export notification history as PDF/CSV
- [ ] Cloud sync for notification history
- [ ] Email notifications for critical alerts
- [ ] Notification reminders
- [ ] Grouping notifications by day/week
- [ ] Notification categories (Critical, Warning, Info)
- [ ] Scheduling notification cleanup

---

## Troubleshooting

### Notifications not appearing?
1. Check `NotificationService.initialize()` is called in main()
2. Verify `NotificationProvider` is in MultiProvider
3. Check permissions on iOS/Android

### Badge count not updating?
1. Verify `Consumer<NotificationProvider>` wraps the app bar
2. Check `notificationProvider.unreadCount` is being used
3. Ensure `addNotification()` is being called

### Notifications not persisting?
1. Verify `NotificationHistoryService` is saving
2. Check SharedPreferences is initialized
3. Look for errors in console logs

---

## Dependencies Used

- `provider`: State management
- `shared_preferences`: Local persistent storage
- `flutter_local_notifications`: System notifications
- `flutter_dotenv`: Environment variables

All are already in your pubspec.yaml!

---

## Summary

The notification system is **fully implemented and ready to use**. It seamlessly integrates with your existing disease detection pipeline and provides users with:

✅ Real-time system notifications  
✅ In-app notification badge  
✅ Beautiful notification history UI  
✅ Persistent storage  
✅ Easy management (read/delete)  

Just run the app and test with disease detections!
