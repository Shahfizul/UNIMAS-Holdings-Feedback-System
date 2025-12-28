import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';
import '../screens/home/notification_screen.dart'; // Import your notification screen

class NotificationBadge extends StatelessWidget {
  final String userId;

  const NotificationBadge({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<NotificationModel>>(
      stream: NotificationService().getUserNotifications(userId),
      builder: (context, snapshot) {
        // 1. Default Icon (Loading or Error)
        if (!snapshot.hasData) {
          return IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {},
          );
        }

        // 2. Calculate Unread Count
        int unreadCount = snapshot.data!.where((n) => !n.isRead).length;

        return Stack(
          alignment: Alignment.center,
          children: [
            // The Bell Icon
            IconButton(
              icon: const Icon(Icons.notifications),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const NotificationScreen()),
                );
              },
            ),

            // The Red Badge (Only show if unread > 0)
            if (unreadCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    unreadCount > 9 ? '9+' : '$unreadCount', // Show '9+' if too many
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