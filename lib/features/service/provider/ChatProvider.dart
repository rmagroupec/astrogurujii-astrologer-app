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
  Future<String?> uploadFile(File file, {required bool isAudio}) async {
    _isUploading = true;
    _safeNotify();
    try {
      final token = await _storage.read(key: 'auth_token') ?? '';
      final endpoint = isAudio ? 'upload_mp3_file' : 'upload_a_file';
      final uri = Uri.parse('$_baseUrl/astrologer_api/$endpoint');

      final request = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer $token'
        ..files.add(await http.MultipartFile.fromPath(
          isAudio ? 'audio' : 'file', file.path));

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      final data     = jsonDecode(response.body) as Map<String, dynamic>;

      if (data['result'] == true || data['status'] == true) {
        final url = (data['url'] ?? data['file']) as String?;
        return url;
      }
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
    _stopSessionTimer();
    _typingDebounce?.cancel();
    _typingSub?.cancel();
    _messageSub?.cancel();
    super.dispose();
  }
}