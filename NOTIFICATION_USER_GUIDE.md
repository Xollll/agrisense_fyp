# Notification System - End User Guide

## For App Users: How to Use Notifications

### 📱 Where to Find Notifications

**Location**: Top-right corner of the Dashboard screen

```
┌─────────────────────────────────────────────┐
│  AgriSense  [🔔 5]  ← Tap this             │ ← App Bar
│  PRECISION AGRICULTURE                      │
├─────────────────────────────────────────────┤
│                                             │
│     Live Stream View                        │
│     (showing camera feed)                   │
│                                             │
├─────────────────────────────────────────────┤
│  AI Recommendations                         │
│  & Statistics                               │
└─────────────────────────────────────────────┘
```

### 🔔 Understanding the Badge

The **red badge** with a number shows how many **new alerts** you haven't read yet:

- **[🔔 0]** = No new notifications
- **[🔔 3]** = 3 new disease detections  
- **[🔔 12]** = 12 new alerts

### 📋 Opening Your Notification List

1. **Tap the notification icon** (bell) in the top-right
2. The app will navigate to your **Notification History** page
3. You'll see all your detection alerts listed

### 👀 What You'll See on the Notification List

```
┌──────────────────────────────────────────┐
│ Notifications          [Clear All] (×)   │ ← Header
├──────────────────────────────────────────┤
│ 📊 Total: 5 | Critical: 2 | Info: 3    │ ← Stats
├──────────────────────────────────────────┤
│                                          │
│ 🚨 Leaf Spot                            │ ← Alert
│    Critical (92%)  •  2 hours ago  (×) │
│                                          │
│ ⚠️ Powdery Mildew                       │ ← Alert
│    Medium (68%)   •  4 hours ago   (×) │
│                                          │
│ ℹ️  Septoria Leaf Blotch                 │ ← Alert
│    Low (45%)     •  1 day ago     (×)   │
│                                          │
└──────────────────────────────────────────┘
```

### 🎨 Understanding the Colors

Each disease alert shows its **severity**:

| Color  | Meaning | What It Means |
|--------|---------|--------------|
| 🔴 Red | Critical | > 80% confidence - Act immediately |
| 🟠 Orange | Medium | 60-80% confidence - Important |
| 🟡 Yellow | Low | < 60% confidence - Monitor |

### 📖 Reading Alert Details

**To see full details about a disease:**

1. **Tap any alert card** in the list
2. A detailed view will pop up showing:
   - Disease name
   - Confidence percentage
   - Exact time it was detected
   - **AI Recommendation** - What to do about it

```
┌─────────────────────────────────┐
│ Disease Details                 │
├─────────────────────────────────┤
│ Disease:  Leaf Spot             │
│ Confidence: 92%                 │
│ Detected: 2024-12-25 10:30      │
│                                 │
│ Recommendation:                 │
│ Apply copper-based fungicide    │
│ spray every 7 days. Ensure      │
│ complete coverage of leaves.    │
│ Repeat after rain.              │
│                                 │
│             [Close]             │
└─────────────────────────────────┘
```

### 🗑️ Deleting Alerts

**To remove a single alert:**

1. Find the alert in the list
2. Tap the **(×)** button on the right side
3. The alert is deleted

**To delete all alerts at once:**

1. Tap the **[Clear All]** button (top-right)
2. Confirm when prompted
3. All notifications are deleted

⚠️ *Note: Deleted notifications cannot be recovered!*

### 📊 Understanding the Stats Bar

At the top of the notification list, you see:

```
Total: 5  |  Critical: 2  |  Info: 3
```

- **Total**: All notifications combined
- **Critical**: High-risk detections (>80%)
- **Info**: Low-risk detections (<60%)

This helps you quickly see how many urgent alerts need attention!

### ⏰ Understanding Time Stamps

Notifications show "time ago" format:

- **just now** = Less than 1 minute ago
- **5m ago** = 5 minutes ago
- **2h ago** = 2 hours ago
- **3d ago** = 3 days ago
- **15/12/2024** = More than 7 days (shows actual date)

### 📱 Reading & Unread Notifications

**Unread notifications:**
- Show in the badge count
- Display with a slightly different style
- Auto-mark as read when you view the notification list

**What "read" means:**
- You've seen the notification list
- All notifications are marked as "seen"
- The badge count goes back to 0
- They still appear in your history

### 🔄 Persistent Storage

Your notifications are **saved on your phone**:

- ✅ Survive app closures
- ✅ Survive phone restarts
- ✅ Stay even if you uninstall (then reinstall)
- ✅ Last 50 notifications kept

⚠️ *If you clear app data, notifications are deleted!*

### 💡 Tips & Best Practices

**1. Check Regularly**
- Check the notification badge regularly
- Critical alerts (red) need immediate attention

**2. Read Recommendations**
- Tap each alert to read the AI-generated solution
- Follow the recommendations for best crop health

**3. Document Issues**
- Note which diseases appear frequently
- Use History page to track patterns

**4. Act Quickly**
- Critical alerts (>80%) should be addressed same day
- Medium alerts within 24 hours
- Low alerts can be monitored

**5. Organize Your List**
- Periodically clear old notifications
- Don't let list get too large
- Keep recent critical alerts for reference

### 🚨 Critical vs. Medium vs. Low Alerts

**Critical Alerts (Red, >80%)**
- Disease is very likely present
- Immediate action recommended
- Could spread quickly
- **Action**: Apply treatment same day

**Medium Alerts (Orange, 60-80%)**
- Disease is probable
- Monitor closely
- Treatment recommended
- **Action**: Apply treatment within 24 hours

**Low Alerts (Yellow, <60%)**
- Disease possibility detected
- Unlikely but possible
- Monitor for confirmation
- **Action**: Monitor, confirm with follow-up detection

### 📸 Notification Workflow

Here's a typical workflow:

```
1. Disease detected while monitoring camera
   ↓
2. 🔔 Badge appears with number
   ↓
3. 📢 System notification pops up
   ↓
4. You tap notification icon or notification itself
   ↓
5. 📋 See notification list with all alerts
   ↓
6. 👀 Tap alert to read full details & recommendation
   ↓
7. ✅ Follow the recommendation and treat plants
   ↓
8. 🗑️ Delete alert once addressed
```

### ❓ Frequently Asked Questions

**Q: Why don't I see old notifications?**
A: Only last 50 notifications are kept. Older ones are automatically deleted.

**Q: Can I recover deleted notifications?**
A: No, once deleted they cannot be recovered. But old data may be in your history page.

**Q: Why is my badge count different?**
A: Badge shows only *unread* notifications. Once you view the list, all become read.

**Q: Are notifications saved if I restart my phone?**
A: Yes! Notifications are saved on your device and persist through restarts.

**Q: Can I turn off notifications?**
A: The notification list always shows history. System popups depend on Android/iOS settings.

**Q: What if I don't get a system notification popup?**
A: Check your phone's notification settings for the AgriSense app.

**Q: How accurate are the confidence percentages?**
A: They're based on AI analysis of the camera feed. Higher percentages are more reliable.

**Q: Why do I get multiple alerts for the same disease?**
A: Each detection is a separate event. Multiple detections = disease present in multiple plants/areas.

**Q: Should I treat based on low-confidence alerts?**
A: It's best to wait for higher confidence or multiple detections before treating.

---

## For Developers: How the Notification System Works

### System Architecture

```
Detection Found
    ↓
Notification Created
    ↓
Saved to Device Storage
    ↓
Badge Updated
    ↓
UI Refreshed
```

### Key Components

1. **NotificationProvider** - Manages notification state
2. **NotificationHistoryService** - Handles persistent storage
3. **NotificationListPage** - Beautiful UI for viewing
4. **DetectionManager** - Integration with disease detection
5. **AppBar** - Shows badge with count

### Data Flow

When disease detected:
1. DetectionManager finds disease
2. Creates NotificationAlert object
3. Adds to NotificationProvider
4. Saves to SharedPreferences
5. Updates UI via Consumer widget
6. Badge count increases

When user views list:
1. Navigate to NotificationListPage
2. Load notifications from provider
3. Call markAllAsRead()
4. Display list with all alerts
5. Badge count goes to 0

### Storage Details

- **Method**: SharedPreferences (JSON)
- **Location**: Device storage
- **Limit**: Last 50 notifications
- **Persistence**: Survives app/device restart
- **Format**: JSON serialized NotificationAlert objects

### API Usage

```dart
// Get the provider
final provider = Provider.of<NotificationProvider>(context);

// Check unread count
int unread = provider.unreadCount;

// Get all notifications
List<NotificationAlert> all = provider.notifications;

// Add notification (done automatically)
await provider.addNotification(
  disease: 'Leaf Spot',
  confidence: 0.92,
  solution: 'Apply fungicide',
);

// Mark as read
await provider.markAsRead(notificationId);

// Delete notification
await provider.deleteNotification(notificationId);
```

---

## Troubleshooting Guide

### Problem: Badge not showing

**Cause**: AppBar not listening to NotificationProvider

**Solution**:
1. Check Consumer<NotificationProvider> wraps AppBar
2. Verify NotificationProvider in MultiProvider
3. Restart app

### Problem: Notifications not saving

**Cause**: SharedPreferences not initialized

**Solution**:
1. Verify SharedPreferences in pubspec.yaml
2. Check notification_history_service.dart
3. Check storage permissions

### Problem: Count not updating

**Cause**: notifyListeners() not called

**Solution**:
1. Check detection_manager calls addNotification()
2. Verify NotificationProvider.addNotification() calls notifyListeners()
3. Check Consumer is not listening: false

### Problem: Notification list crashes

**Cause**: Missing route or context issue

**Solution**:
1. Verify '/notifications' route in MaterialApp
2. Check NotificationListPage imports
3. Check Navigation pushNamed has context

### Problem: Old notifications deleted

**Cause**: Storage limit (50 notifications) reached

**Solution**:
1. Clear old notifications regularly
2. Increase storage limit if needed (in notification_history_service.dart)
3. Export data if you need to keep history

---

## Summary

The notification system is designed to:

✅ **Alert you immediately** when diseases are detected  
✅ **Provide detailed information** about each detection  
✅ **Recommend treatments** via AI analysis  
✅ **Keep permanent history** of all detections  
✅ **Work seamlessly** in the background  

Simply tap the notification icon to see all your disease detection history!
