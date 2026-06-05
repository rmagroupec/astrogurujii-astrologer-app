import 'dart:async';
import 'dart:io';

import 'package:astrologer_app/features/service/model/chat_message.dart';
import 'package:astrologer_app/features/service/service/ChatService.dart';
import 'package:astrologer_app/service/ChatCallStatusService.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:convert';

class ChatProvider extends ChangeNotifier {
  final ChatService _chatService = ChatService();
  final _storage = const FlutterSecureStorage();

  static const String _baseUrl = "https://admin.astrogurujii.com";

  String? _groupId;
  String? _senderId;
  String? _receiverId;
  String? _senderName;

  // Messages
  List<ChatMessage> messages = [];

  // ✅ Upload loading state (shown as animated dots in UI)
  bool isUploading = false;

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
  }

  /// ✅ SEND AUDIO MESSAGE
  

  // ─────────────────────────────────────────────────────────────────────────
  // ✅ UPLOAD FILE (IMAGE or AUDIO) → returns public URL or null on failure
  // Mirrors the React version: tries upload_mp3_file for audio, upload_a_file
  // for images, with a fallback to upload_a_file for audio too.
  // ─────────────────────────────────────────────────────────────────────────
 bool _isUploading = false;
 
  Future<String?> uploadFile(File file, {required bool isAudio}) async {
    _isUploading = true;
    notifyListeners();
 
    try {
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'auth_token');
 
      // ── Choose endpoint ────────────────────────────────────────────────────
      // ✅ Use the SAME endpoint for both — adjust if your API has separate ones
      final endpoint = isAudio
          ? 'https://admin.astrogurujii.com/astrologer_api/upload_mp3_file'
          : 'https://admin.astrogurujii.com/astrologer_api/upload_a_image';
 
      final uri = Uri.parse(endpoint);
      final request = http.MultipartRequest('POST', uri);
 
      // ── Auth header ────────────────────────────────────────────────────────
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }
 
      // ── File field ─────────────────────────────────────────────────────────
      final fileName = isAudio
          ? 'voice_${DateTime.now().millisecondsSinceEpoch}.mp3'   // ✅ .mp3
          : 'image_${DateTime.now().millisecondsSinceEpoch}.jpg';
 
      final mimeType = isAudio ? 'audio/mpeg' : 'image/jpeg';      // ✅ correct MIME
 
      // The field name must match what your server expects.
      // Common names: "file", "image", "audio", "mp3_file"
      // Check your backend — here we use "file" as default:
      final fieldName = isAudio ? 'image' : 'file';
 
      request.files.add(
        await http.MultipartFile.fromPath(
          fieldName,
          file.path,
          filename: fileName,
          contentType: http.MediaType.parse(mimeType),
        ),
      );
 
      debugPrint('🚀 Uploading to: $endpoint');
      debugPrint('   Field: $fieldName | File: $fileName | MIME: $mimeType');
 
      final streamed = await request.send().timeout(
        const Duration(seconds: 60),
        onTimeout: () => throw Exception('Upload timed out'),
      );
      final response = await http.Response.fromStream(streamed);
 
      debugPrint('📡 HTTP ${response.statusCode}');
      debugPrint('📦 Raw body: ${response.body}');
 
      // ── Guard against HTML error pages ────────────────────────────────────
      if (response.body.trim().startsWith('<')) {
        debugPrint('❌ Server returned HTML — check endpoint / auth token');
        return null;
      }
 
      final data = jsonDecode(response.body);
      debugPrint('✅ Parsed response: $data');
 
      if (data['status'] == true) {
        // Your server returns the URL in "file_img"
        final url = (data['file_img'] ?? data['url'] ?? data['file']) as String?;
        debugPrint('🔗 File URL: $url');
        return url;
      } else {
        debugPrint('❌ Upload failed: ${data['message']}');
        return null;
      }
    } catch (e, st) {
      debugPrint('❌ Upload error: $e');
      debugPrint(st.toString());
      return null;
    } finally {
      _isUploading = false;
      notifyListeners();
    }
  }
 
// ─────────────────────────────────────────────────────────────────────────────
// Also add sendAudioMessage if it's missing from your ChatProvider:
// ─────────────────────────────────────────────────────────────────────────────
 
  Future<void> sendAudioMessage({required String audioUrl}) async {
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
      message: audioUrl,
      type: "audio",
    );
  }

  final callStatusService = CallStatusService();

  /// ✅ END CHAT API (CALLED FROM END BUTTON)
  Future<void> endChatApi(String channelId) async {
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