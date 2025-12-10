import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notification_provider.dart';

class NotificationListPage extends StatefulWidget {
  const NotificationListPage({super.key});

  @override
  State<NotificationListPage> createState() => _NotificationListPageState();
}

class _NotificationListPageState extends State<NotificationListPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _animationController.forward();

    // Mark all as read when viewing the page
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NotificationProvider>(context, listen: false)
          .markAllAsRead();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: const Text(
          'Notifications',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, provider, child) {
              if (provider.notifications.isEmpty) {
                return const SizedBox();
              }
              return TextButton(
                onPressed: () {
                  _showClearConfirmation(context, provider);
                },
                child: Text(
                  'Clear All',
                  style: TextStyle(
                    color: Colors.red.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, provider, child) {
          if (provider.notifications.isEmpty) {
            return _buildEmptyState();
          }

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: 24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats bar
                  _buildStatsBar(provider),
                  const SizedBox(height: 24),

                  // Notifications list
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: provider.notifications.length,
                    itemBuilder: (context, index) {
                      return ScaleTransition(
                        scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                          CurvedAnimation(
                            parent: _animationController,
                            curve: Interval(
                              (index * 0.1).clamp(0, 1).toDouble(),
                              ((index + 1) * 0.1).clamp(0, 1).toDouble(),
                            ),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildNotificationCard(
                            context,
                            provider.notifications[index],
                            provider,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_none_rounded,
              size: 64,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Notifications',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Disease detections will appear here',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsBar(NotificationProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.green.shade50,
            Colors.blue.shade50,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.green.shade200,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            icon: Icons.notifications_active_rounded,
            label: 'Total',
            value: provider.totalCount.toString(),
            color: Colors.blue,
          ),
          _buildStatItem(
            icon: Icons.warning_rounded,
            label: 'Critical',
            value: provider.notifications
                .where((n) => n.confidence > 0.8)
                .length
                .toString(),
            color: Colors.red,
          ),
          _buildStatItem(
            icon: Icons.info_rounded,
            label: 'Info',
            value: provider.notifications
                .where((n) => n.confidence <= 0.8)
                .length
                .toString(),
            color: Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationCard(
    BuildContext context,
    NotificationAlert notification,
    NotificationProvider provider,
  ) {
    final confidenceColor = notification.confidence > 0.8
        ? Colors.red
        : notification.confidence > 0.6
            ? Colors.orange
            : Colors.yellow;

    final confidenceLevel = notification.confidence > 0.8
        ? 'Critical'
        : notification.confidence > 0.6
            ? 'Medium'
            : 'Low';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: notification.isRead
                ? Colors.grey.shade300
                : confidenceColor.withOpacity(0.5),
            width: notification.isRead ? 1 : 2,
          ),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: confidenceColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.health_and_safety_rounded,
              color: confidenceColor,
              size: 20,
            ),
          ),
          title: Text(
            notification.disease,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 6),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: confidenceColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '$confidenceLevel (${(notification.confidence * 100).toStringAsFixed(0)}%)',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: confidenceColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatTime(notification.timestamp),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: () {
                  provider.deleteNotification(notification.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Notification deleted'),
                      duration: const Duration(seconds: 2),
                      action: SnackBarAction(
                        label: 'Undo',
                        onPressed: () {
                          // You could implement undo functionality here
                        },
                      ),
                    ),
                  );
                },
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(8),
              ),
            ],
          ),
          onTap: () {
            _showNotificationDetails(context, notification);
          },
        ),
      ),
    );
  }

  void _showNotificationDetails(
    BuildContext context,
    NotificationAlert notification,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Disease Details',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            _buildDetailRow('Disease', notification.disease),
            const SizedBox(height: 12),
            _buildDetailRow(
              'Confidence',
              '${(notification.confidence * 100).toStringAsFixed(1)}%',
            ),
            const SizedBox(height: 12),
            _buildDetailRow('Detected At', _formatTime(notification.timestamp)),
            const SizedBox(height: 24),
            Text(
              'Recommendation',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Text(
                notification.solution.isEmpty
                    ? 'Check the app for detailed recommendations'
                    : notification.solution,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Close',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Colors.grey,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  void _showClearConfirmation(
    BuildContext context,
    NotificationProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Notifications?'),
        content: const Text(
          'This action cannot be undone. All notifications will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              provider.clearAllNotifications();
              Navigator.pop(context);
            },
            child: Text(
              'Clear',
              style: TextStyle(color: Colors.red.shade600),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inSeconds < 60) {
        return 'just now';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h ago';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}d ago';
      } else {
        return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
      }
    } catch (e) {
      return timestamp;
    }
  }
}
