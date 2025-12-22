import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> notifications = [
      {
        "title": "Lost Pet Alert: Amman",
        "body":
            "Attention! A dog has been reported lost in your area (Amman, 7th Circle). Please keep an eye out.",
        "time": "10 min ago",
        "type": "lost_alert",
        "isRead": false,
      },
      {
        "title": "Potential Match Found!",
        "body":
            "Great news! A pet has been found in Irbid that matches your lost report. Tap to view details and contact the finder.",
        "time": "2 hours ago",
        "type": "found_match",
        "isRead": false,
      },
      {
        "title": "Adoption Request Update",
        "body":
            "Your request to adopt 'Luna' has been received and is under review.",
        "time": "1 day ago",
        "type": "adoption",
        "isRead": true,
      },
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Notifications",
          style:
              TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back,
                color: AppColors.textDark, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {},
            child: const Text("Mark all read",
                style: TextStyle(color: AppColors.primary)),
          )
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final item = notifications[index];
          return _buildNotificationCard(item);
        },
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> item) {
    bool isRead = item['isRead'];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isRead ? Colors.white : const Color(0xFFF5F9FF),
        border: Border.all(
          color:
              isRead ? Colors.grey[200]! : AppColors.primary.withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _getIconColor(item['type']).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getIconData(item['type']),
              color: _getIconColor(item['type']),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item['title'],
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight:
                              isRead ? FontWeight.w600 : FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                    if (!isRead)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  item['body'],
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textGrey,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  item['time'],
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[400],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getIconColor(String type) {
    switch (type) {
      case 'lost_alert':
        return Colors.redAccent;
      case 'found_match':
        return Colors.green;
      case 'adoption':
        return AppColors.primary;
      default:
        return Colors.grey;
    }
  }

  IconData _getIconData(String type) {
    switch (type) {
      case 'lost_alert':
        return Icons.warning_amber_rounded;
      case 'found_match':
        return Icons.check_circle_outline;
      case 'adoption':
        return Icons.pets;
      default:
        return Icons.notifications_outlined;
    }
  }
}
