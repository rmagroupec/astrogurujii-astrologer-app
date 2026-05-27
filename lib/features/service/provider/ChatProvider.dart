import 'dart:async';

import 'package:astrologer_app/features/service/model/chat_message.dart';
import 'package:astrologer_app/features/service/service/ChatService.dart';
import 'package:astrologer_app/service/ChatCallStatusService.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ChatProvider extends ChangeNotifier {
  final ChatService _chatService = ChatService();

  String? _groupId;
  String? _senderId;
  String? _receiverId;
  String? _senderName;

  // Messages
  List<ChatMessage> messages = [];

  StreamSubscription? _messageSub;

  /// ✅ INITIALIZE CHAT (CALLED FROM ChatScreen)
  void initializeChat(
    String groupId,
    String senderId,
    String receiverId, {
    String senderName = "",
  }) {
    _groupId = groupId;
    _senderId = senderId;
    _receiverId = receiverId;
    _senderName = senderName;

    _listenMessages();
  }

  /// 🔥 REALTIME MESSAGE LISTENER
void _listenMessages() {
  if (_groupId == null || _senderId == null || _receiverId == null) return;

  _messageSub?.cancel();

  debugPrint("🟢 Listening on Group/$_groupId/$_senderId/$_receiverId");

  _messageSub = _chatService
      .getMessages(
        groupId: _groupId!,
        senderId: _senderId!,
        receiverId: _receiverId!,
      )
      .listen((list) {
    debugPrint("🟢 Messages received: ${list.length}");
    messages = list;
    notifyListeners();
  });
}
bool _chatEnded = false;
String _endReason = "Chat has been ended by User";

bool get chatEnded => _chatEnded;
String get endReason => _endReason;

void handleChatEnded(String reason) {
  _chatEnded = true;
  _endReason = reason;
  print("inside this");
  notifyListeners();
}


  /// ✅ SEND TEXT MESSAGE (USED BY UI)
  Future<void> sendTextMessage(String text) async {
    if (text.trim().isEmpty) return;

    if (_groupId == null ||
        _senderId == null ||
        _receiverId == null ||
        _senderName == null) {
      debugPrint("ChatProvider not initialized");
      return;
    }
    debugPrint("🟢 IDs OK -> $_groupId $_senderId $_receiverId");
    await _chatService.sendMessage(
      groupId: _groupId!,
      senderId: _senderId!,
      receiverId: _receiverId!,
      senderName: _senderName!,
      message: text,
      type: "text",
    );
  }

  /// ✅ SEND IMAGE MESSAGE
  Future<void> sendImageMessage({required String imageUrl}) async {
    if (_groupId == null ||
        _senderId == null ||
        _receiverId == null ||
        _senderName == null) {
      debugPrint("ChatProvider not initialized");
      return;
    }

    await _chatService.sendMessage(
      groupId: _groupId!,
      senderId: _senderId!,
      receiverId: _receiverId!,
      senderName: _senderName!,
      message: imageUrl,
      type: "image",
    );
  }final callStatusService = CallStatusService();

  /// ✅ END CHAT API (CALLED FROM END BUTTON)
  Future<void> endChatApi(String channelId) async {
    // Call backend API if needed
    // Example:
     await callStatusService.updateCallStatus(
      channelId: channelId,
      status: 'end_astro',
    );

    // Stop Firebase listener
    _messageSub?.cancel();
    messages.clear();
    notifyListeners();
  }

  /// 🕒 FORMAT TIME (USED IN UI)
  String formatTime(int timestamp) {
    if (timestamp == 0) return "";
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateFormat('hh:mm a').format(date);
  }

 @override
void dispose() {
  _typingDebounce?.cancel();
  _typingSub?.cancel();
  _messageSub?.cancel();
  super.dispose();
}


  void listenMessages() {
    if (_groupId == null || _senderId == null || _receiverId == null) {
      debugPrint("❌ Cannot listen, IDs missing");
      return;
    }

    _messageSub?.cancel();

    debugPrint("🟢 Listening on: Group/$_groupId/$_senderId/$_receiverId");

    _messageSub = _chatService
        .getMessages(
          groupId: _groupId!,
          senderId: _senderId!,
          receiverId: _receiverId!,
        )
        .listen((list) {
          debugPrint("🟢 Messages received: ${list.length}");
          messages = list;
          notifyListeners();
        });
  }
  bool isOtherTyping = false;
StreamSubscription? _typingSub;

Timer? _typingDebounce;



void listenTyping(String otherUserId) {
  if (_groupId == null) return;

  _typingSub?.cancel();
  _typingSub = _chatService
      .typingStream(groupId: _groupId!, userId: otherUserId)
      .listen((value) {
    isOtherTyping = value;
    notifyListeners();
  });
}

void setTyping(bool isTyping) {
  if (_groupId == null || _senderId == null) return;

  // Debounce typing updates (prevents spam)
  _typingDebounce?.cancel();
  _typingDebounce = Timer(const Duration(milliseconds: 400), () {
    _chatService.setTyping(
      groupId: _groupId!,
      userId: _senderId!,
      isTyping: isTyping,
    );
  });
}
void markMessagesSeen() {
  if (_groupId == null || _senderId == null || _receiverId == null) return;

  for (final msg in messages) {
    if (msg.from != _senderId && !msg.seen) {
      _chatService.updateSeenStatus(
        path:
            "Group/$_groupId/$_senderId/$_receiverId/${msg.messageId}",
      );
    }
  }
}
 void disposeChat() {
  _typingSub?.cancel();
  _messageSub?.cancel();
}


}
