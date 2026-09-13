import 'package:astrologer_app/features/service/model/chat_message.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class ChatService {
  /// SEND MESSAGE (TEXT / IMAGE)
 Future<void> sendMessage({
  required String groupId,
  required String senderId,
  required String receiverId,
  required String senderName,
  required String message,
  required String type,
}) async {
  debugPrint("🟢 Firebase send START");

  final timestamp = DateTime.now().millisecondsSinceEpoch;

  final db = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
        "https://astrogurujii-production-default-rtdb.firebaseio.com/",
  ).ref();

  final senderPath = 'Group/$groupId/$senderId/$receiverId';
  final receiverPath = 'Group/$groupId/$receiverId/$senderId';

  // 🔑 Generate ONE messageId
  final messageId = db.child(senderPath).push().key;

  if (messageId == null) {
    debugPrint("🔴 push() failed");
    return;
  }

  final chatMessage = ChatMessage(
    name: senderName,
    to: receiverId,
    from: senderId,
    message: message,
    type: type,
    messageId: messageId,
    dateTime: timestamp,
    seen: false,
  ).toJson();

  // ✅ WRITE SEPARATELY (NO ancestor conflict)
  await db.child('$senderPath/$messageId').set(chatMessage);
  await db.child('$receiverPath/$messageId').set(chatMessage);

  debugPrint("✅ Firebase send SUCCESS");
}

  /// LISTEN MESSAGES (REAL TIME)
  Stream<List<ChatMessage>> getMessages({
    required String groupId,
    required String senderId,
    required String receiverId,
  }) {
    final ref = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL:
          "https://astrogurujii-production-default-rtdb.firebaseio.com/",
    ).ref().child("Group").child(groupId).child(senderId).child(receiverId);

    return ref.orderByChild("date_time").onValue.map((event) {
      final data = event.snapshot.value;

      if (data == null) return [];

      final Map<dynamic, dynamic> map = data as Map<dynamic, dynamic>;

      final List<ChatMessage> list = map.values
          .map((e) => ChatMessage.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      // IMPORTANT: sort again (Firebase orderBy is not guaranteed)
      list.sort((a, b) => a.dateTime.compareTo(b.dateTime));

      return list;
    });
  }

  // ─────────────────────────────────────────────────────────────
// TYPING
// Uses the SAME Firebase Realtime Database as chat messages.
// ─────────────────────────────────────────────────────────────

static const String _dbUrl =
    "https://astrogurujii-production-default-rtdb.firebaseio.com/";

FirebaseDatabase get _database => FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: _dbUrl,
    );

Future<void> setTyping({
  required String groupId,
  required String userId,
  required bool isTyping,
}) async {
  if (groupId.trim().isEmpty || userId.trim().isEmpty) {
    debugPrint(
      "❌ setTyping skipped: groupId=$groupId userId=$userId",
    );
    return;
  }

  final path = "Typing/$groupId/$userId";

  try {
    debugPrint(
      "⌨️ TYPING WRITE → $path = $isTyping",
    );

    await _database.ref().child(path).set(isTyping);

    debugPrint(
      "✅ TYPING WRITE SUCCESS → $path = $isTyping",
    );
  } catch (e, stack) {
    debugPrint(
      "❌ TYPING WRITE FAILED → $path = $e",
    );
    debugPrint("$stack");
  }
}

Stream<bool> typingStream({
  required String groupId,
  required String userId,
}) {
  final path = "Typing/$groupId/$userId";

  debugPrint(
    "👂 TYPING LISTEN → $path",
  );

  return _database
      .ref()
      .child(path)
      .onValue
      .map((event) {
        final value = event.snapshot.value;

        debugPrint(
          "👂 TYPING EVENT → $path = $value",
        );

        return value == true;
      });
}

  Future<void> updateSeenStatus({required String path}) async {
    await FirebaseDatabase.instance.ref(path).update({"seen": true});
  }
}
