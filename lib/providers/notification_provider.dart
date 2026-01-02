import 'package:flutter/material.dart';
import '../services/notification_history_service.dart';
import 'package:agrisense/utils/app_log.dart';

/// Model for a notification alert
class NotificationAlert {
  final String id; // Unique identifier
  final String disease;
  final double confidence;
  final String timestamp;
  final String solution;
  bool isRead;

  NotificationAlert({
    required this.id,
    required this.disease,
    required this.confidence,
    required this.timestamp,
    required this.solution,
    this.isRead = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'disease': disease,
      'confidence': confidence,
      'timestamp': timestamp,
      'solution': solution,
      'isRead': isRead,
    };
  }

  factory NotificationAlert.fromJson(Map<String, dynamic> json) {
    return NotificationAlert(
      id: json['id'] as String,
      disease: json['disease'] as String,
      confidence: json['confidence'] as double,
      timestamp: json['timestamp'] as String,
      solution: json['solution'] as String? ?? '',
      isRead: json['isRead'] as bool? ?? false,
    );
  }
}

/// NotificationProvider manages all notification states
class NotificationProvider extends ChangeNotifier {
  final NotificationHistoryService _historyService = NotificationHistoryService();
  
  List<NotificationAlert> _notifications = [];
  int _unreadCount = 0;

  List<NotificationAlert> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  int get totalCount => _notifications.length;

  NotificationProvider() {
    _initializeNotifications();
  }

  /// Initialize notifications from storage
  Future<void> _initializeNotifications() async {
    try {
      _notifications = await _historyService.getNotifications();
      _calculateUnreadCount();
      notifyListeners();
    } catch (e) {
      appLog('Error initializing notifications: $e');
    }
  }

  /// Add a new notification (triggered when disease is detected)
  Future<void> addNotification({
    required String disease,
    required double confidence,
    required String solution,
  }) async {
    final notification = NotificationAlert(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      disease: disease,
      confidence: confidence,
      timestamp: DateTime.now().toString(),
      solution: solution,
      isRead: false,
    );

    _notifications.insert(0, notification); // Add at the beginning
    _calculateUnreadCount();

    // Save to persistent storage
    await _historyService.saveNotification(notification);

    notifyListeners();
    appLog('Notification added: $disease');
  }

  /// Mark a notification as read
  Future<void> markAsRead(String notificationId) async {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notifications[index].isRead = true;
      _calculateUnreadCount();
      
      // Update in persistent storage
      await _historyService.updateNotification(_notifications[index]);
      
      notifyListeners();
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    for (var notification in _notifications) {
      if (!notification.isRead) {
        notification.isRead = true;
        await _historyService.updateNotification(notification);
      }
    }
    _calculateUnreadCount();
    notifyListeners();
  }

  /// Delete a specific notification
  Future<void> deleteNotification(String notificationId) async {
    _notifications.removeWhere((n) => n.id == notificationId);
    _calculateUnreadCount();
    
    // Delete from persistent storage
    await _historyService.deleteNotification(notificationId);
    
    notifyListeners();
  }

  /// Clear all notifications
  Future<void> clearAllNotifications() async {
    _notifications.clear();
    _unreadCount = 0;
    
    // Clear from persistent storage
    await _historyService.clearAllNotifications();
    
    notifyListeners();
  }

  /// Calculate unread count
  void _calculateUnreadCount() {
    _unreadCount = _notifications.where((n) => !n.isRead).length;
  }

  /// Get notifications for a specific disease
  List<NotificationAlert> getNotificationsByDisease(String disease) {
    return _notifications.where((n) => n.disease == disease).toList();
  }

  /// Get unread notifications
  List<NotificationAlert> getUnreadNotifications() {
    return _notifications.where((n) => !n.isRead).toList();
  }
}
