import 'package:flutter/material.dart';
import 'package:smart_canvas/core/utilies/colors/app_colors.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock Data
    final notifications = [
      {'title': 'Welcome to Smart Campus', 'time': '2 hours ago', 'isUnread': true},
      {'title': 'Your profile was updated', 'time': '1 day ago', 'isUnread': false},
      {'title': 'New semester schedule available', 'time': '2 days ago', 'isUnread': false},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications"),
        centerTitle: true,
      ),
      body: notifications.isEmpty
          ? const Center(child: Text("No notifications yet"))
          : ListView.separated(
              itemCount: notifications.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final item = notifications[index];
                final isUnread = item['isUnread'] as bool;
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isUnread ? AppColors.kPrimaryColor : Colors.grey[300],
                    child: Icon(
                      Icons.notifications, 
                      color: isUnread ? Colors.white : Colors.grey[600]
                    ),
                  ),
                  title: Text(
                    item['title'] as String,
                    style: TextStyle(
                      fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  subtitle: Text(item['time'] as String),
                  trailing: isUnread 
                      ? const Icon(Icons.circle, size: 10, color: AppColors.kPrimaryColor)
                      : null,
                );
              },
            ),
    );
  }
}
