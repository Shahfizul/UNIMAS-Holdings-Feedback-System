import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';
import '../screens/home/notification_screen.dart'; // Import your notification screen

// Widget that displays a bell icon with a red badge count for unread notifications.
// This is typically placed in the AppBar actions area.
class NotificationBadge extends StatelessWidget {
  final String userId;

  const NotificationBadge({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    // Listen to the stream of notifications for the current user in real-time.
    // This ensures the badge count updates immediately when a new notification arrives.
    return StreamBuilder<List<NotificationModel>>(
      stream: NotificationService().getUserNotifications(userId),
      builder: (context, snapshot) {
        // 1. Default Icon (Show plain icon while Loading or if Error)
        if (!snapshot.hasData) {
          return IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {},
          );
        }

        // 2. Calculate Unread Count
        // Filter the list to count only notifications where isRead is false
        int unreadCount = snapshot.data!.where((n) => !n.isRead).length;

        // Use a Stack to layer the red badge on top of the bell icon
        return Stack(
          alignment: Alignment.center,
          children: [
            // The Bell Icon Button
            IconButton(
              icon: const Icon(Icons.notifications),
              onPressed: () {
                // Navigate to the full Notification List Screen when tapped
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const NotificationScreen()),
                );
              },
            ),

            // The Red Badge (Only show if there are unread notifications)
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
                    // Limit display to '9+' if the count is very high to save space
                    unreadCount > 9 ? '9+' : '$unreadCount',
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