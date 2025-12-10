# Notification System - Code Examples

## Example 1: Manual Notification (For Testing)

Add this code anywhere to manually trigger a notification:

```dart
import 'package:provider/provider.dart';
import 'providers/notification_provider.dart';

// Inside any widget's build method or event handler:
ElevatedButton(
  onPressed: () async {
    final notificationProvider = 
        Provider.of<NotificationProvider>(context, listen: false);
    
    await notificationProvider.addNotification(
      disease: 'Test Leaf Spot',
      confidence: 0.85,
      solution: 'Apply copper-based fungicide spray every 7 days',
    );
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notification added!')),
    );
  },
  child: const Text('Add Test Notification'),
)
```

---

## Example 2: Display Unread Count in Custom Widget

```dart
import 'package:provider/provider.dart';
import 'providers/notification_provider.dart';

class NotificationBadge extends StatelessWidget {
  const NotificationBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, provider, child) {
        if (provider.unreadCount == 0) {
          return const Icon(Icons.notifications_outlined);
        }
        
        return Stack(
          children: [
            const Icon(Icons.notifications),
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                child: Text(
                  '${provider.unreadCount}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
```

---

## Example 3: Notification List with Custom Filtering

```dart
import 'package:provider/provider.dart';
import 'providers/notification_provider.dart';

class CriticalNotificationsOnly extends StatelessWidget {
  const CriticalNotificationsOnly({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, provider, child) {
        // Filter only critical notifications (> 80% confidence)
        final criticalNotifications = provider.notifications
            .where((n) => n.confidence > 0.8)
            .toList();
        
        return ListView.builder(
          itemCount: criticalNotifications.length,
          itemBuilder: (context, index) {
            final notification = criticalNotifications[index];
            
            return ListTile(
              leading: const Icon(Icons.warning, color: Colors.red),
              title: Text(notification.disease),
              subtitle: Text(
                '${(notification.confidence * 100).toStringAsFixed(0)}% confidence',
              ),
              trailing: Text(
                '${notification.confidence > 0.9 ? '🔥' : '⚠️'}',
              ),
            );
          },
        );
      },
    );
  }
}
```

---

## Example 4: Notification Stats Dashboard

```dart
import 'package:provider/provider.dart';
import 'providers/notification_provider.dart';

class NotificationStats extends StatelessWidget {
  const NotificationStats({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, provider, child) {
        final total = provider.totalCount;
        final critical = provider.notifications
            .where((n) => n.confidence > 0.8)
            .length;
        final unread = provider.unreadCount;
        
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStat('Total', total.toString(), Colors.blue),
                _buildStat('Critical', critical.toString(), Colors.red),
                _buildStat('Unread', unread.toString(), Colors.orange),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
```

---

## Example 5: Get Notifications by Disease Type

```dart
import 'package:provider/provider.dart';
import 'providers/notification_provider.dart';

class LeafSpotNotifications extends StatelessWidget {
  const LeafSpotNotifications({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, provider, child) {
        // Get only Leaf Spot notifications
        final leafSpotNotifications = 
            provider.getNotificationsByDisease('Leaf Spot');
        
        return Column(
          children: [
            Text('Leaf Spot Detections: ${leafSpotNotifications.length}'),
            ListView.builder(
              shrinkWrap: true,
              itemCount: leafSpotNotifications.length,
              itemBuilder: (context, index) {
                final notification = leafSpotNotifications[index];
                
                return ListTile(
                  title: Text(notification.disease),
                  subtitle: Text(
                    'Detected: ${notification.timestamp}',
                  ),
                  trailing: Text(
                    '${(notification.confidence * 100).toStringAsFixed(0)}%',
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}
```

---

## Example 6: Action Menu for Notifications

```dart
import 'package:provider/provider.dart';
import 'providers/notification_provider.dart';

class NotificationActions extends StatelessWidget {
  const NotificationActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, provider, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(
              onPressed: () async {
                await provider.markAllAsRead();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All marked as read')),
                );
              },
              icon: const Icon(Icons.done_all),
              label: const Text('Mark All Read'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Clear All?'),
                    content: const Text('Delete all notifications permanently?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
                
                if (confirmed ?? false) {
                  await provider.clearAllNotifications();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('All notifications cleared')),
                    );
                  }
                }
              },
              icon: const Icon(Icons.delete_sweep),
              label: const Text('Clear All'),
            ),
          ],
        );
      },
    );
  }
}
```

---

## Example 7: Unread Notifications Only View

```dart
import 'package:provider/provider.dart';
import 'providers/notification_provider.dart';

class UnreadNotificationsOnly extends StatelessWidget {
  const UnreadNotificationsOnly({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, provider, child) {
        final unreadNotifications = provider.getUnreadNotifications();
        
        if (unreadNotifications.isEmpty) {
          return const Center(
            child: Text('No unread notifications'),
          );
        }
        
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                '${unreadNotifications.length} Unread Alerts',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: unreadNotifications.length,
                itemBuilder: (context, index) {
                  final notification = unreadNotifications[index];
                  
                  return Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      border: Border.all(color: Colors.blue),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListTile(
                      title: Text(
                        notification.disease,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(notification.solution),
                      onTap: () async {
                        // Mark as read when tapped
                        await provider.markAsRead(notification.id);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
```

---

## Example 8: Notification History Export

```dart
import 'package:provider/provider.dart';
import 'providers/notification_provider.dart';

class ExportNotifications extends StatelessWidget {
  const ExportNotifications({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, provider, child) {
        return ElevatedButton.icon(
          onPressed: () {
            // Generate CSV format
            final csv = _generateCSV(provider.notifications);
            
            // Copy to clipboard or share
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Export Notifications'),
                content: SingleChildScrollView(
                  child: Text(csv),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ],
              ),
            );
          },
          icon: const Icon(Icons.download),
          label: const Text('Export as CSV'),
        );
      },
    );
  }

  String _generateCSV(List<NotificationAlert> notifications) {
    final buffer = StringBuffer();
    buffer.writeln('Disease,Confidence,Timestamp,Solution,Read');
    
    for (final notification in notifications) {
      buffer.writeln(
        '${notification.disease},'
        '${notification.confidence},'
        '${notification.timestamp},'
        '"${notification.solution}",'
        '${notification.isRead}',
      );
    }
    
    return buffer.toString();
  }
}
```

---

## Example 9: Real-time Notification Counter

```dart
import 'package:provider/provider.dart';
import 'providers/notification_provider.dart';

class NotificationCounter extends StatelessWidget {
  const NotificationCounter({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, provider, child) {
        return GestureDetector(
          onTap: () => Navigator.pushNamed(context, '/notifications'),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  '${provider.unreadCount}',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 8),
                const Text('New Alerts'),
                const SizedBox(height: 12),
                Text(
                  'Tap to view all (Total: ${provider.totalCount})',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
```

---

## Example 10: Animated Notification Indicator

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/notification_provider.dart';

class AnimatedNotificationIndicator extends StatefulWidget {
  const AnimatedNotificationIndicator({super.key});

  @override
  State<AnimatedNotificationIndicator> createState() => 
      _AnimatedNotificationIndicatorState();
}

class _AnimatedNotificationIndicatorState 
    extends State<AnimatedNotificationIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, provider, child) {
        if (provider.unreadCount == 0) {
          return const SizedBox();
        }

        return GestureDetector(
          onTap: () => Navigator.pushNamed(context, '/notifications'),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Pulse animation
              ScaleTransition(
                scale: Tween(begin: 1.0, end: 1.2).animate(_controller),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              // Icon
              Icon(
                Icons.notifications,
                color: Colors.red,
                size: 28,
              ),
              // Badge count
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${provider.unreadCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
```

---

## Usage Tips

### ✅ Do:
- Use `Consumer<NotificationProvider>` for reactive UI updates
- Check `unreadCount` for badge display
- Use `markAllAsRead()` when opening notification list
- Filter notifications by confidence for priority handling

### ❌ Don't:
- Don't directly modify `notifications` list from UI
- Don't forget to `await` async methods
- Don't access provider during build without Consumer/watch

### 🎯 Best Practices:
- Use `Provider.of(..., listen: false)` for one-time operations
- Use `Consumer` for continuous reactive UI
- Call `markAsRead()` when user views notification details
- Implement proper error handling around persistence

---

That's it! You now have 10 complete, working examples of the notification system!
