import 'dart:convert';
import 'package:astrologer_app/features/Settings/components/notificationDetailModel.dart';
import 'package:astrologer_app/features/service/model/NotificationModel.dart';

import 'package:flutter/material.dart';
import 'package:astrologer_app/core/config/theme_config.dart';
import 'package:astrologer_app/service/apiService.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  bool isLoading = true;
  List<AstroNotification> list = [];

  @override
  void initState() {
    super.initState();
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    setState(() => isLoading = true);

    try {
      final res = await ApiService().AstrologerNotificatinList();
     
     setState(() {
        list = res.notifications;
     });
    } catch (_) {
      list = [];
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: AppBar(
        title: const Text("Notifications"),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : list.isEmpty
              ? const Center(child: Text("No notifications"))
              : ListView.builder(
                  itemCount: list.length,
                  itemBuilder: (_, i) => _notificationTile(list[i]),
                ),
    );
  }

  Widget _notificationTile(AstroNotification n) {
    return InkWell(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (_) => NotificationDetailModal(notification: n),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: n.isRead ? Colors.white : AppTheme.primaryColor.withOpacity(.08),
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 5),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppTheme.primaryColor.withOpacity(.15),
              child: Icon(
                Icons.notifications,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    n.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    n.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    n.addedOn,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            if (!n.isRead)
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}