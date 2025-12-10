import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/notification_provider.dart';

/// Service to manage notification history persistence
class NotificationHistoryService {
  static const String _notificationKey = 'agrisense_notifications_history';
  static const int _maxStoredNotifications = 50; // Keep last 50 notifications

  /// Get all stored notifications
  Future<List<NotificationAlert>> getNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_notificationKey);

      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }

      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList
          .map((json) => NotificationAlert.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ Error loading notifications: $e');
      return [];
    }
  }

  /// Save a new notification
  Future<void> saveNotification(NotificationAlert notification) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get existing notifications
      final notifications = await getNotifications();
      
      // Add new notification at the beginning
      notifications.insert(0, notification);
      
      // Keep only the last N notifications
      if (notifications.length > _maxStoredNotifications) {
        notifications.removeRange(
          _maxStoredNotifications,
          notifications.length,
        );
      }

      // Convert to JSON and save
      final jsonList = notifications.map((n) => n.toJson()).toList();
      await prefs.setString(_notificationKey, jsonEncode(jsonList));
      
      print('✅ Notification saved: ${notification.disease}');
    } catch (e) {
      print('❌ Error saving notification: $e');
    }
  }

  /// Update an existing notification (e.g., mark as read)
  Future<void> updateNotification(NotificationAlert notification) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get all notifications
      final notifications = await getNotifications();
      
      // Find and update
      final index = notifications.indexWhere((n) => n.id == notification.id);
      if (index != -1) {
        notifications[index] = notification;
        
        // Save back
        final jsonList = notifications.map((n) => n.toJson()).toList();
        await prefs.setString(_notificationKey, jsonEncode(jsonList));
      }
    } catch (e) {
      print('❌ Error updating notification: $e');
    }
  }

  /// Delete a specific notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get all notifications
      final notifications = await getNotifications();
      
      // Remove the notification
      notifications.removeWhere((n) => n.id == notificationId);
      
      // Save back
      final jsonList = notifications.map((n) => n.toJson()).toList();
      await prefs.setString(_notificationKey, jsonEncode(jsonList));
      
      print('✅ Notification deleted: $notificationId');
    } catch (e) {
      print('❌ Error deleting notification: $e');
    }
  }

  /// Clear all notifications
  Future<void> clearAllNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_notificationKey);
      print('✅ All notifications cleared');
    } catch (e) {
      print('❌ Error clearing notifications: $e');
    }
  }

  /// Get notifications count
  Future<int> getNotificationCount() async {
    try {
      final notifications = await getNotifications();
      return notifications.length;
    } catch (e) {
      print('❌ Error getting notification count: $e');
      return 0;
    }
  }

  /// Get unread notifications count
  Future<int> getUnreadCount() async {
    try {
      final notifications = await getNotifications();
      return notifications.where((n) => !n.isRead).length;
    } catch (e) {
      print('❌ Error getting unread count: $e');
      return 0;
    }
  }
}
