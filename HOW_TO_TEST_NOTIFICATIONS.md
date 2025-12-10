# How to Test & Verify Your Notification System

## Quick Testing Methods

### Method 1: Manual Test Button (Easiest)

Add this test button to your Dashboard to manually trigger notifications:

```dart
// Add this to DashboardPage build method (in main.dart)
FloatingActionButton(
  onPressed: () async {
    final notificationProvider = 
        Provider.of<NotificationProvider>(context, listen: false);
    
    await notificationProvider.addNotification(
      disease: 'Test Leaf Spot',
      confidence: 0.92,
      solution: 'Apply copper-based fungicide spray every 7 days',
    );
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ Test notification added!')),
    );
  },
  child: const Icon(Icons.bug_report),
  tooltip: 'Add Test Notification',
)
```

**Steps to Test:**
1. Run the app: `flutter run`
2. Navigate to Dashboard
3. Tap the floating action button (bug icon)
4. **Expected**: 
   - ✅ Badge count increases in top-right
   - ✅ Snackbar shows "Test notification added!"
   - ✅ Console shows: "✅ Notification added: Test Leaf Spot"

---

### Method 2: Check Console Logs

**What to look for in the console when app starts:**

```
✅ Environment variables loaded
✅ Supabase initialized
✅ Notification service initialized
✅ Local cache initialized
✅ Sync service initialized
✅ App settings initialized
✅ Notification provider initialized
✅ Detection polling started
```

**When a notification is added, you should see:**
```
✅ Notification added: Leaf Spot
```

**When user marks as read:**
```
(Console shows notification marked as read)
```

---

### Method 3: Tap Notification Icon & Check Page

**Steps:**
1. Add a test notification (Method 1)
2. Look at top-right - should see **[🔔 1]** badge
3. Tap the notification icon
4. **Expected**: 
   - ✅ Navigation to NotificationListPage
   - ✅ See your test notification in the list
   - ✅ Badge count becomes **[🔔 0]** (auto-marked as read)
   - ✅ Stats bar shows "Total: 1"

```
Notification List Page Should Show:
┌──────────────────────────────┐
│ Notifications    Clear All   │
├──────────────────────────────┤
│ 📊 Total: 1 | Critical: 1    │
├──────────────────────────────┤
│ 🔴 Test Leaf Spot            │
│    Critical (92%) • just now │
└──────────────────────────────┘
```

---

### Method 4: Test All Features

Create a test widget to check all functionality:

```dart
// Add this to a test file or temporarily to main.dart
class NotificationSystemTest extends StatelessWidget {
  const NotificationSystemTest({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notification System Test')),
      body: Consumer<NotificationProvider>(
        builder: (context, provider, child) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Test 1: Add Notification
              _buildTestButton(
                context,
                'Test 1: Add Notification',
                () async {
                  await provider.addNotification(
                    disease: 'Test Disease',
                    confidence: 0.85,
                    solution: 'Test solution',
                  );
                },
              ),
              const SizedBox(height: 12),

              // Test 2: Check Badge Count
              _buildTestButton(
                context,
                'Test 2: Check Count (Should increase)',
                () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Unread: ${provider.unreadCount} | Total: ${provider.totalCount}'),
                      duration: const Duration(seconds: 3),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),

              // Test 3: Mark as Read
              _buildTestButton(
                context,
                'Test 3: Mark as Read (Count should decrease)',
                () async {
                  if (provider.notifications.isNotEmpty) {
                    await provider.markAsRead(provider.notifications.first.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Marked read. Unread now: ${provider.unreadCount}'),
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 12),

              // Test 4: Delete Notification
              _buildTestButton(
                context,
                'Test 4: Delete First Notification',
                () async {
                  if (provider.notifications.isNotEmpty) {
                    await provider.deleteNotification(provider.notifications.first.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Deleted. Total now: ${provider.totalCount}'),
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 12),

              // Test 5: Clear All
              _buildTestButton(
                context,
                'Test 5: Clear All',
                () async {
                  await provider.clearAllNotifications();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('All cleared!')),
                  );
                },
              ),
              const SizedBox(height: 24),

              // Status Display
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Current Status:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text('Total Notifications: ${provider.totalCount}'),
                      Text('Unread Notifications: ${provider.unreadCount}'),
                      const SizedBox(height: 12),
                      if (provider.notifications.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Latest Notification:'),
                            Text('  Disease: ${provider.notifications.first.disease}'),
                            Text('  Confidence: ${(provider.notifications.first.confidence * 100).toStringAsFixed(0)}%'),
                            Text('  Read: ${provider.notifications.first.isRead}'),
                          ],
                        )
                      else
                        const Text(
                          'No notifications yet',
                          style: TextStyle(fontStyle: FontStyle.italic),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTestButton(
    BuildContext context,
    String label,
    VoidCallback onPressed,
  ) {
    return ElevatedButton(
      onPressed: onPressed,
      child: Text(label),
    );
  }
}
```

---

## Comprehensive Testing Checklist

### ✅ Phase 1: Basic Functionality

- [ ] App starts without crash
- [ ] No console errors on startup
- [ ] Notification icon visible in top-right of dashboard
- [ ] Badge shows 0 initially

### ✅ Phase 2: Adding Notifications

- [ ] Add test notification (using method 1)
- [ ] Badge count increases to 1
- [ ] Console shows: "✅ Notification added: ..."
- [ ] No crashes during addition

### ✅ Phase 3: Badge Display

- [ ] Badge shows correct number (1, 2, 3, etc.)
- [ ] Badge color is red
- [ ] Badge has pulsing animation
- [ ] Badge hides when count is 0

### ✅ Phase 4: Navigation

- [ ] Tap notification icon
- [ ] App navigates to NotificationListPage
- [ ] No crashes on navigation
- [ ] List page loads without errors

### ✅ Phase 5: List Display

- [ ] See notification in list
- [ ] Disease name displayed correctly
- [ ] Confidence percentage shown
- [ ] Time stamp shown ("just now")
- [ ] Stats bar shows correct counts
- [ ] Color coding correct (red for high confidence)

### ✅ Phase 6: Read/Unread

- [ ] Open notification list
- [ ] Badge becomes 0 (auto-marked read)
- [ ] Go back to dashboard
- [ ] Badge still shows 0
- [ ] Add new notification
- [ ] Badge shows 1 again

### ✅ Phase 7: Detail Modal

- [ ] Tap notification card
- [ ] Modal pops up
- [ ] Shows disease details
- [ ] Shows confidence percentage
- [ ] Shows timestamp
- [ ] Shows recommendation text
- [ ] Close button works

### ✅ Phase 8: Delete Function

- [ ] Add 3 notifications
- [ ] Tap × on one card
- [ ] Notification removed from list
- [ ] Count updates correctly
- [ ] Remaining notifications intact

### ✅ Phase 9: Clear All

- [ ] Add multiple notifications
- [ ] Tap "Clear All" button
- [ ] Confirmation dialog appears
- [ ] Confirm deletion
- [ ] All notifications deleted
- [ ] Empty state shown
- [ ] Badge becomes 0

### ✅ Phase 10: Persistence

- [ ] Add notification
- [ ] Close app completely
- [ ] Reopen app
- [ ] Notification still there
- [ ] Badge count restored
- [ ] Data loaded correctly

---

## What Each Feature Should Do

### Badge Icon
```
Initial: [🔔 0]
After adding 1: [🔔 1]
After adding 3 total: [🔔 3]
After viewing list: [🔔 0] (auto-marked read)
After adding 1 more: [🔔 1]
```

### Notification List
```
Shows:
- Total count
- Critical count (>80%)
- Info count (<60%)
- Each notification card with:
  * Disease name
  * Confidence %
  * Time ago
  * Delete button
```

### Detail Modal (On Tap)
```
Shows:
- "Disease Details" header
- Disease name
- Confidence percentage
- Detected time
- "Recommendation" header
- Full solution text
- Close button
```

### Empty State
```
Shows:
- Large notification icon
- "No Notifications" text
- "Disease detections will appear here"
- Friendly message
```

---

## Common Test Scenarios

### Scenario 1: Fresh App Start
```
1. Clear app data: Settings > Apps > AgriSense > Clear Cache/Storage
2. Run app
3. Should see: Badge [🔔 0], no notifications
4. Add test notification
5. Should see: Badge [🔔 1], notification appears
✅ PASS if everything shows correctly
```

### Scenario 2: Multiple Detections
```
1. Add 5 test notifications
2. Check badge shows [🔔 5]
3. Open notification list
4. Check stats show: Total: 5
5. Badge becomes [🔔 0]
6. Close app and reopen
7. Check all 5 still there
✅ PASS if all persist correctly
```

### Scenario 3: Real Disease Detection
```
1. Start app with camera feed
2. Position plant to trigger detection
3. Wait for disease detection
4. Check: System notification appears
5. Check: Badge increases
6. Open list
7. Check: New notification in list
✅ PASS if notification appears automatically
```

---

## Debugging Tips

### If Badge Not Showing

1. **Check imports**: Verify `notification_provider.dart` imported
2. **Check Provider**: Open main.dart, verify `ChangeNotifierProvider(create: (_) => NotificationProvider())`
3. **Check Consumer**: Verify AppBar wrapped in `Consumer<NotificationProvider>`
4. **Check notifyListeners()**: Verify called after adding notification

### If Notification Not Saving

1. **Check SharedPreferences**: Verify in pubspec.yaml
2. **Check serialization**: Verify `toJson()` and `fromJson()` working
3. **Check permissions**: On Android/iOS, check storage permissions
4. **Check logs**: Look for errors in console

### If Navigation Fails

1. **Check route**: Verify `/notifications` in MaterialApp routes
2. **Check context**: Verify `context` available in navigation
3. **Check imports**: Verify NotificationListPage imported
4. **Check navigation**: Try using `context.go()` or `Navigator.of(context).pushNamed()`

### If Counts Wrong

1. **Check calculation**: Verify `_calculateUnreadCount()` called
2. **Check notifyListeners()**: Verify called after each operation
3. **Check Consumer**: Verify listening to provider correctly
4. **Check data**: Manually print `provider.notifications` to console

---

## Console Output to Look For

### Successful Initialization
```
✅ Notification service initialized
✅ Notification provider initialized
✅ Detection polling started
```

### When Adding Notification
```
✅ Notification added: Leaf Spot
```

### When Marking Read
```
(No explicit log, but unreadCount should decrease)
```

### When Deleting
```
✅ Notification deleted: [id]
```

### If Errors
```
❌ Error initializing notifications: [error message]
❌ Error adding notification: [error message]
```

---

## Quick Verification (2 Minutes)

1. **Run app**: `flutter run`
2. **Check badge**: Look for [🔔 0] in top-right
3. **Add test**: Tap FAB to add notification (or use Method 1)
4. **Check badge**: Should show [🔔 1]
5. **Tap icon**: Open notification list
6. **See list**: Should show your notification
7. **Done**: ✅ System is working!

---

## If Something's Wrong

| Problem | Check | Solution |
|---------|-------|----------|
| No badge showing | Consumer wrapper | Wrap AppBar in Consumer<NotificationProvider> |
| Badge doesn't update | notifyListeners() | Add notifyListeners() after changing state |
| Notification doesn't save | SharedPreferences | Check pubspec.yaml for shared_preferences |
| Navigation fails | Route definition | Add route: '/notifications': (context) => NotificationListPage() |
| App crashes | Errors | Look at console for full error stack trace |
| Count wrong | _calculateUnreadCount() | Call this after read/delete operations |
| Data lost on restart | Persistence | Verify NotificationHistoryService saves correctly |

---

**Your notification system is working correctly if all Phase checks pass!** ✅
