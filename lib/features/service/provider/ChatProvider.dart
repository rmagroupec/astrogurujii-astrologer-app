// lib/features/service/provider/ChatProvider.dart
//
// Changes (mirroring AudioCallProvider pattern):
// 1. ✅ Added minimize/expand state + isMinimized, isEnded getters
// 2. ✅ Added callerName, callerImage, channelId, sessionSeconds stored in provider
// 3. ✅ Session timer lives in provider (not screen) — persists across minimize/resume
// 4. ✅ initializeChat() stores caller info for overlay
// 5. ✅ minimize() / expand() / endChat() methods
// 6. ✅ disposeChat() only cancels subscriptions, does NOT end the call

import 'dart:async';
import 'dart:io';
import 'package:http_parser/http_parser.dart';

import 'package:astrologer_app/features/service/model/chat_message.dart';
import 'package:astrologer_app/features/service/service/ChatService.dart';
import 'package:astrologer_app/service/ChatCallStatusService.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:astrologer_app/features/service/active_call_store.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

class ChatProvider extends ChangeNotifier {
  final ChatService _chatService = ChatService();
  final _storage = const FlutterSecureStorage();
  final callStatusService = CallStatusService();
  String get senderId   => _senderId   ?? '';
  String get receiverId => _receiverId ?? '';

  static const String _baseUrl = "https://admin.astrogurujii.com";

  // ── Session identity ────────────────────────────────────────────────────────
  String? _groupId;
  String? _senderId;
  String? _receiverId;
  String? _senderName;

  // ✅ Stored for overlay display (mirrors AudioCallProvider.callerName/callerImage)
  String callerName  = '';
  String callerImage = '';
  String get channelId => _groupId ?? '';

  // ── Messages ────────────────────────────────────────────────────────────────
  List<ChatMessage> messages = [];

  // ── Upload state ────────────────────────────────────────────────────────────
  bool _isUploading = false;
  bool get isUploading => _isUploading;

  // ── Minimize state (mirrors AudioCallProvider) ──────────────────────────────
  bool _isMinimized = false;
  bool _isEnded     = false;

  bool get isMinimized => _isMinimized;
  bool get isEnded     => _isEnded;
  bool get isActive    => !_isEnded;

  // ── Session timer (lives in provider so it survives screen navigation) ──────
  Timer?    _sessionTimer;
  int       _sessionSeconds = 0;

  int    get sessionSeconds => _sessionSeconds;
  String get sessionDuration {
    final h   = _sessionSeconds ~/ 3600;
    final m   = (_sessionSeconds % 3600) ~/ 60;
    final sec = _sessionSeconds % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  // ── Chat ended ──────────────────────────────────────────────────────────────
  bool   _chatEnded = false;
  String _endReason = 'Chat has been ended by User';

  bool   get chatEnded => _chatEnded;
  String get endReason => _endReason;

  // ── Typing ──────────────────────────────────────────────────────────────────
  bool                isOtherTyping = false;
  StreamSubscription? _typingSub;
  Timer?              _typingDebounce;

  // ── Firebase subscription ───────────────────────────────────────────────────
  StreamSubscription? _messageSub;
StreamSubscription<DatabaseEvent>? _callSessionSub;
static const _dbUrl =
    'https://astrogurujii-production-default-rtdb.firebaseio.com/';

void listenCallSession(String channelId) {
  _callSessionSub?.cancel();
  final ref = FirebaseDatabase.instanceFor(
    app        : Firebase.app(),
    databaseURL: _dbUrl,
  ).ref().child('CallSession').child(channelId);

  _callSessionSub = ref.onValue.listen((event) {
    final data = event.snapshot.value;
    if (data == null) return;
    final map    = Map<String, dynamic>.from(data as Map);
    final status = (map['status'] ?? '') as String;

    if (['end_user', 'wallet_empty'].contains(status)) {
      // User ran out of wallet or ended from their side
      handleChatEnded('Chat ended by user');
    }
  });
}
  // ── INITIALIZE ──────────────────────────────────────────────────────────────
  void initializeChat(
    String groupId,
    String senderId,
    String receiverId, {
    String senderName  = '',
    String userName    = '',   // ✅ for overlay
    String userAvatar  = '',   // ✅ for overlay
  }) {
    // Guard: don't re-init if same session (resume from minimize)
    if (_groupId == groupId && _messageSub != null) return;

    _groupId    = groupId;
    _senderId   = senderId;
    _receiverId = receiverId;
    _senderName = senderName;
    callerName  = userName.isNotEmpty  ? userName  : senderName;
    callerImage = userAvatar;
    _isEnded    = false;
    _chatEnded  = false;
listenCallSession(groupId); 
    _listenMessages();
    _startSessionTimer();
  }

  // ── Session timer ───────────────────────────────────────────────────────────
  void _startSessionTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _sessionSeconds++;
      _safeNotify();
    });
  }

  void _stopSessionTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = null;
  }

  // ── Minimize / Expand (mirrors AudioCallProvider) ───────────────────────────
  void minimize() {
    _isMinimized = true;
    _safeNotify();
  }

  void expand() {
    _isMinimized = false;
    _safeNotify();
  }

  // ── Firebase listener ───────────────────────────────────────────────────────
  void _listenMessages() {
    if (_groupId == null || _senderId == null || _receiverId == null) return;
    _messageSub?.cancel();
    _messageSub = _chatService
        .getMessages(
          groupId   : _groupId!,
          senderId  : _senderId!,
          receiverId: _receiverId!,
        )
        .listen((list) {
      messages = list;
      _safeNotify();
    });
  }

  // ── Typing ──────────────────────────────────────────────────────────────────
  void listenTyping(String otherUserId) {
    if (_groupId == null) return;
    _typingSub?.cancel();
    _typingSub = _chatService
        .typingStream(groupId: _groupId!, userId: otherUserId)
        .listen((value) {
      isOtherTyping = value;
      _safeNotify();
    });
  }

  void setTyping(bool isTyping) {
    if (_groupId == null || _senderId == null) return;
    _typingDebounce?.cancel();
    _typingDebounce = Timer(const Duration(milliseconds: 400), () {
      _chatService.setTyping(
          groupId: _groupId!, userId: _senderId!, isTyping: isTyping);
    });
  }

  void markMessagesSeen() {
    if (_groupId == null || _senderId == null || _receiverId == null) return;
    for (final msg in messages) {
      if (msg.from != _senderId && !msg.seen) {
        _chatService.updateSeenStatus(
          path: 'Group/$_groupId/$_senderId/$_receiverId/${msg.messageId}',
        );
      }
    }
  }

  void handleChatEnded(String reason) {
    _chatEnded = true;
    _endReason = reason;
    _stopSessionTimer();
    _safeNotify();
  }

  // ── Send messages ───────────────────────────────────────────────────────────
  Future<void> sendTextMessage(String text) async {
    if (text.trim().isEmpty) return;
    if (_groupId == null || _senderId == null ||
        _receiverId == null || _senderName == null) return;
    await _chatService.sendMessage(
      groupId   : _groupId!,
      senderId  : _senderId!,
      receiverId: _receiverId!,
      senderName: _senderName!,
      message   : text,
      type      : 'text',
    );
  }

  Future<void> sendImageMessage({required String imageUrl}) async {
    if (_groupId == null || _senderId == null ||
        _receiverId == null || _senderName == null) return;
    await _chatService.sendMessage(
      groupId   : _groupId!,
      senderId  : _senderId!,
      receiverId: _receiverId!,
      senderName: _senderName!,
      message   : imageUrl,
      type      : 'image',
    );
  }

  Future<void> sendAudioMessage({required String audioUrl}) async {
    if (_groupId == null || _senderId == null ||
        _receiverId == null || _senderName == null) return;
    await _chatService.sendMessage(
      groupId   : _groupId!,
      senderId  : _senderId!,
      receiverId: _receiverId!,
      senderName: _senderName!,
      message   : audioUrl,
      type      : 'audio',
    );
  }

  // ── Upload file ─────────────────────────────────────────────────────────────
 static const _audioFieldName = 'image';  // ← adjust if needed
  static const _imageFieldName = 'file';        // ← adjust if needed
 
 Future<String?> uploadFile(File file, {required bool isAudio}) async {
    _isUploading = true;
    _safeNotify();
 
    try {
      final token = await _storage.read(key: 'auth_token') ?? '';
      if (token.isEmpty) {
        debugPrint('❌ uploadFile: no auth token');
        return null;
      }
 
      final endpoint = isAudio ? 'upload_mp3_file' : 'upload_a_image';
      final uri      = Uri.parse('$_baseUrl/astrologer_api/$endpoint');
 
      // ── MIME type ─────────────────────────────────────────────────────────
      final ext = file.path.split('.').last.toLowerCase();
      final MediaType mimeType;
      if (isAudio) {
        mimeType = switch (ext) {
          'mp3'  => MediaType('audio', 'mpeg'),
          'ogg'  => MediaType('audio', 'ogg'),
          'wav'  => MediaType('audio', 'wav'),
          'webm' => MediaType('audio', 'webm'),
          _      => MediaType('audio', 'mp4'),  // m4a / aac
        };
      } else {
        mimeType = switch (ext) {
          'png'  => MediaType('image', 'png'),
          'gif'  => MediaType('image', 'gif'),
          'webp' => MediaType('image', 'webp'),
          _      => MediaType('image', 'jpeg'),
        };
      }
 
      debugPrint('📤 uploadFile → $endpoint  mime=${mimeType.type}/${mimeType.subtype}');
 
      // ✅ Field name is "image" for BOTH endpoints (confirmed from server code)
      final request = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer $token'
        ..headers['Accept']        = 'application/json'
        ..files.add(await http.MultipartFile.fromPath(
          isAudio ? 'image' : 'file',        // ✅ server: mp3Upload.fields([{ name: "image" }])
          file.path,
          contentType: mimeType,
        ));
 
      final streamed = await request.send().timeout(const Duration(seconds: 60));
      final response = await http.Response.fromStream(streamed);
 
      debugPrint('📥 status=${response.statusCode} body=${response.body.length > 300 ? response.body.substring(0, 300) : response.body}');
 
      final ct = response.headers['content-type'] ?? '';
      if (!ct.contains('json')) {
        debugPrint('❌ uploadFile: non-JSON response');
        return null;
      }
 
      if (response.statusCode < 200 || response.statusCode >= 300) {
        debugPrint('❌ uploadFile: HTTP ${response.statusCode}');
        return null;
      }
 
      final Map<String, dynamic> data;
      try {
        data = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {
        debugPrint('❌ uploadFile: JSON parse failed');
        return null;
      }
 
      if (data['status'] == true) {
        // ✅ server returns "file_img" not "url" or "file"
        final url = data['file_img'] as String?;
        debugPrint('✅ uploadFile success: $url');
        return (url != null && url.isNotEmpty) ? url : null;
      }
 
      debugPrint('❌ uploadFile: server failure — $data');
      return null;
 
    } on TimeoutException {
      debugPrint('❌ uploadFile: timed out');
      return null;
    } catch (e, st) {
      debugPrint('❌ Upload error: $e\n$st');
      return null;
    } finally {
      _isUploading = false;
      _safeNotify();
    }
  }
 

  // ── End chat ────────────────────────────────────────────────────────────────
  Future<void> endChatApi(String channelId) async {
    if (_isEnded) return;
    _isEnded    = true;
    _isMinimized = false;
    await ActiveCallStore.clear();
    _callSessionSub?.cancel();
    _stopSessionTimer();
    await callStatusService.updateCallStatus(
        channelId: channelId, status: 'end_astro');
    _messageSub?.cancel();
    messages.clear();
    _chatEnded = true;
    _safeNotify();
  }

  // ── Format time ─────────────────────────────────────────────────────────────
  String formatTime(int timestamp) {
    if (timestamp == 0) return '';
    return DateFormat('hh:mm a')
        .format(DateTime.fromMillisecondsSinceEpoch(timestamp));
  }

  // ── Cancel subscriptions without ending call (used when screen disposes during minimize) ──
  void suspendListeners() {
    _typingSub?.cancel();
    // Keep _messageSub alive so messages still arrive while minimized
  }

  void resumeListeners(String otherUserId) {
    listenTyping(otherUserId);
    markMessagesSeen();
  }

  // ── Legacy compat ───────────────────────────────────────────────────────────
  void disposeChat() {
    _typingSub?.cancel();
    // DO NOT cancel _messageSub here — overlay may still be showing
    // endChatApi() cancels it when the session truly ends
  }

  void listenMessages() => _listenMessages();

  // ── Internal ─────────────────────────────────────────────────────────────────
  bool _disposed = false;

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _callSessionSub?.cancel();
    _stopSessionTimer();
    _typingDebounce?.cancel();
    _typingSub?.cancel();
    _messageSub?.cancel();
    super.dispose();
  }
}