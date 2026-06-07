// lib/features/service/ChatScreen.dart
//
// Changes (provider-based minimize, mirrors AudioCallScreen):
// 1. ✅ Session timer lives in ChatProvider — screen just reads provider.sessionDuration
// 2. ✅ Back press / arrow → provider.minimize() + Navigator.pop()
// 3. ✅ Resume: ChangeNotifierProvider.value reuses same provider instance
// 4. ✅ dispose() never calls disposeChat() — provider manages its own lifetime
// 5. ✅ resumed flag skips re-initializeChat() to avoid double Firebase subscribe

import 'dart:io';

import 'package:astrologer_app/features/service/provider/ChatProvider.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:async';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';

// ─────────────────────────────────────────────────────────────────────────────
// TOAST
// ─────────────────────────────────────────────────────────────────────────────
enum _ToastType { success, error, info, warning }

void showTopToast(BuildContext context, String message,
    {_ToastType type = _ToastType.info,
    Duration duration = const Duration(seconds: 3)}) {
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _TopToast(
      message  : message,
      type     : type,
      duration : duration,
      onDismiss: () { if (entry.mounted) entry.remove(); },
    ),
  );
  Overlay.of(context).insert(entry);
}

class _TopToast extends StatefulWidget {
  final String message;
  final _ToastType type;
  final Duration duration;
  final VoidCallback onDismiss;
  const _TopToast({
    required this.message, required this.type,
    required this.duration, required this.onDismiss,
  });
  @override
  State<_TopToast> createState() => _TopToastState();
}

class _TopToastState extends State<_TopToast>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<Offset>   _slide;
  late Animation<double>   _fade;

  @override
  void initState() {
    super.initState();
    _ctrl  = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 350));
    _slide = Tween<Offset>(begin: const Offset(0.5, -1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));
    _fade  = Tween<double>(begin: 0, end: 1).animate(_ctrl);
    _ctrl.forward();
    Future.delayed(widget.duration, () async {
      if (mounted) { await _ctrl.reverse(); widget.onDismiss(); }
    });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Color get _bgColor => switch (widget.type) {
    _ToastType.success => const Color(0xFF2E7D32),
    _ToastType.error   => const Color(0xFFC62828),
    _ToastType.warning => const Color(0xFFE65100),
    _ToastType.info    => const Color(0xFF1565C0),
  };

  IconData get _icon => switch (widget.type) {
    _ToastType.success => Icons.check_circle_outline,
    _ToastType.error   => Icons.error_outline,
    _ToastType.warning => Icons.warning_amber_outlined,
    _ToastType.info    => Icons.info_outline,
  };

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Positioned(
      top: topPad + 8, right: 12, left: 12,
      child: SlideTransition(
        position: _slide,
        child: FadeTransition(
          opacity: _fade,
          child: Material(
            color: Colors.transparent,
            child: GestureDetector(
              onTap: () => _ctrl.reverse().then((_) => widget.onDismiss()),
              child: Container(
                padding   : const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color       : _bgColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow   : [BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 12, offset: const Offset(0, 4))],
                ),
                child: Row(children: [
                  Icon(_icon, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Expanded(child: Text(widget.message,
                      style: const TextStyle(color: Colors.white,
                          fontSize: 13, fontWeight: FontWeight.w500))),
                  const SizedBox(width: 6),
                  const Icon(Icons.close, color: Colors.white70, size: 16),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CHAT SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class ChatScreen extends StatefulWidget {
  final String channelId;
  final String astroId;
  final String userId;
  final String userName;
  final String userAvatar;

  /// ✅ true when navigated back from mini overlay — skip re-initializeChat()
  final bool resumed;

  const ChatScreen({
    super.key,
    required this.channelId,
    required this.astroId,
    required this.userId,
    required this.userName,
    required this.userAvatar,
    this.resumed = false,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  // Recording only — timer/session live in provider now
  final AudioRecorder _recorder        = AudioRecorder();
  bool   _isRecording                  = false;
  int    _recordingSeconds             = 0;
  Timer? _recordingTimer;
  String? _recordingPath;

  bool _endFlowShown = false;

  void _toast(String msg, {_ToastType type = _ToastType.info}) {
    if (!mounted) return;
    showTopToast(context, msg, type: type);
  }

  bool _containsRestrictedContent(String text) {
    final phone = RegExp(r'(\+?\d[\d\s\-]{6,14}\d)');
    final email = RegExp(r'[\w\.\+\-]+@[\w\-]+\.[a-zA-Z]{2,}');
    final url   = RegExp(
        r'(https?://|www\.)[^\s]+|[a-zA-Z0-9\-]+\.(com|net|org|in|io|co)[^\s]*',
        caseSensitive: false);
    return phone.hasMatch(text) || email.hasMatch(text) || url.hasMatch(text);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = context.read<ChatProvider>();

      if (!widget.resumed) {
        // Fresh session — provider initialises Firebase + timer
        p.initializeChat(
          widget.channelId,
          widget.astroId,
          widget.userId,
          senderName : widget.userName,
          userName   : widget.userName,
          userAvatar : widget.userAvatar,
        );
        p.listenTyping(widget.userId);
        p.markMessagesSeen();
      } else {
        // Resumed — reattach listeners that were suspended during minimize
        p.expand();
        p.resumeListeners(widget.userId);
      }

      p.addListener(_onProviderChange);
    });
  }

  void _onProviderChange() {
    final p = context.read<ChatProvider>();
    if (p.chatEnded && !_endFlowShown) {
      _triggerEndFlow(reason: p.endReason, selfEnded: false);
    }
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _recorder.dispose();
    final p = context.read<ChatProvider>();
    p.removeListener(_onProviderChange);
    // ✅ Never disposeChat() here — provider lifetime is managed by NavigationManager
    super.dispose();
  }

  // ── Minimize ────────────────────────────────────────────────────────────────
  void _minimize() {
    if (_endFlowShown) return;
    context.read<ChatProvider>().minimize(); // provider notifies overlay
    Navigator.of(context).pop();
  }

  // ── End flow ────────────────────────────────────────────────────────────────
  Future<void> _triggerEndFlow({
    required String reason,
    required bool   selfEnded,
  }) async {
    if (_endFlowShown) return;
    _endFlowShown = true;
    FocusScope.of(context).unfocus();

    if (selfEnded) {
      await context.read<ChatProvider>().endChatApi(widget.channelId);
    }
    if (!mounted) return;
    await _showRatingSheet(reason: reason);
  }

  Future<void> _showRatingSheet({required String reason}) async {
    final p = context.read<ChatProvider>();
    await showModalBottomSheet(
      context            : context,
      isDismissible      : false,
      enableDrag         : false,
      isScrollControlled : true,
      backgroundColor    : Colors.transparent,
      builder: (_) => _ChatRatingSheet(
        userName   : widget.userName,
        userAvatar : widget.userAvatar,
        sessionTime: p.sessionDuration,
        endReason  : reason,
        channelId  : widget.channelId,
        onDone     : () {
          Navigator.pop(context);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showEndChatDialog(BuildContext ctx) {
    showDialog(
      context           : ctx,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape  : RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title  : const Text('End Chat',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to end this chat session?'),
        actions: [
          TextButton(
            child    : const Text('Cancel', style: TextStyle(color: Colors.grey)),
            onPressed: () => Navigator.pop(ctx),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child    : const Text('End Chat',
                style: TextStyle(color: Colors.white)),
            onPressed: () {
              Navigator.pop(ctx);
              _triggerEndFlow(reason: 'Chat ended by you', selfEnded: true);
            },
          ),
        ],
      ),
    );
  }

  // ── Image picker ────────────────────────────────────────────────────────────
  Future<void> _showImageSourceSheet() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape  : const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Wrap(children: [
            ListTile(
              leading: const CircleAvatar(backgroundColor: Color(0xFFEBC351),
                  child: Icon(Icons.camera_alt, color: Colors.black)),
              title    : const Text('Camera',
                  style: TextStyle(fontWeight: FontWeight.w500)),
              onTap    : () => Navigator.pop(sheetCtx, ImageSource.camera),
            ),
            ListTile(
              leading: const CircleAvatar(backgroundColor: Color(0xFFEBC351),
                  child: Icon(Icons.photo_library, color: Colors.black)),
              title    : const Text('Gallery',
                  style: TextStyle(fontWeight: FontWeight.w500)),
              onTap    : () => Navigator.pop(sheetCtx, ImageSource.gallery),
            ),
          ]),
        ),
      ),
    );
    if (source == null) return;
    await _pickAndSendImage(source);
  }

  Future<void> _pickAndSendImage(ImageSource source) async {
    if (source == ImageSource.camera) {
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        if (status.isPermanentlyDenied) {
          _toast('Camera permission permanently denied. Open Settings.',
              type: _ToastType.error);
          openAppSettings();
        } else {
          _toast('Camera permission denied.', type: _ToastType.error);
        }
        return;
      }
    } else {
      if (Platform.isAndroid) {
        final status = await Permission.photos.request();
        if (status.isPermanentlyDenied) {
          _toast('Gallery permission permanently denied. Open Settings.',
              type: _ToastType.error);
          openAppSettings();
          return;
        }
      } else {
        final status = await Permission.photos.request();
        if (!status.isGranted && !status.isLimited) {
          if (status.isPermanentlyDenied) {
            _toast('Gallery permission permanently denied. Open Settings.',
                type: _ToastType.error);
            openAppSettings();
          } else {
            _toast('Gallery permission denied.', type: _ToastType.error);
          }
          return;
        }
      }
    }
    try {
      final picked = await ImagePicker().pickImage(source: source, imageQuality: 80);
      if (picked == null || !mounted) return;
      final p   = context.read<ChatProvider>();
      final url = await p.uploadFile(File(picked.path), isAudio: false);
      if (url != null) {
        await p.sendImageMessage(imageUrl: url);
        _toast('Image sent!', type: _ToastType.success);
      } else {
        _toast('Image upload failed.', type: _ToastType.error);
      }
    } catch (e) {
      _toast('Error picking image: $e', type: _ToastType.error);
    }
  }

  // ── Audio recording ─────────────────────────────────────────────────────────
  Future<void> _startRecording() async {
    var mic = await Permission.microphone.status;
    if (!mic.isGranted) mic = await Permission.microphone.request();
    if (!mic.isGranted) {
      if (mic.isPermanentlyDenied) {
        _toast('Microphone permanently denied.', type: _ToastType.error);
        openAppSettings();
      } else {
        _toast('Microphone permission denied.', type: _ToastType.error);
      }
      return;
    }
    if (!await _recorder.hasPermission()) {
      _toast('Cannot access microphone.', type: _ToastType.error);
      return;
    }
    try {
      final dir = await getTemporaryDirectory();
      _recordingPath =
          '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _recorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc,
            bitRate: 128000, sampleRate: 44100, numChannels: 1),
        path: _recordingPath!,
      );
      setState(() { _isRecording = true; _recordingSeconds = 0; });
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        setState(() => _recordingSeconds++);
      });
      _toast('Recording started…', type: _ToastType.info);
    } catch (e) {
      _toast('Failed to start recording: $e', type: _ToastType.error);
    }
  }

  Future<void> _stopAndSendRecording() async {
    _recordingTimer?.cancel();
    try {
      final path = await _recorder.stop();
      setState(() => _isRecording = false);
      final filePath = path ?? _recordingPath;
      if (filePath == null) { _toast('No recording found.', type: _ToastType.error); return; }
      final file = File(filePath);
      if (!await file.exists()) { _toast('Recording file missing.', type: _ToastType.error); return; }
      if (await file.length() < 1000) {
        _toast('Recording too short.', type: _ToastType.warning); return;
      }
      if (!mounted) return;
      final p = context.read<ChatProvider>();
      _toast('Uploading voice message…', type: _ToastType.info);
      final url = await p.uploadFile(file, isAudio: true);
      if (url != null) {
        await p.sendAudioMessage(audioUrl: url);
        _toast('Voice message sent!', type: _ToastType.success);
      } else {
        _toast('Audio upload failed.', type: _ToastType.error);
      }
    } catch (e) {
      setState(() => _isRecording = false);
      _toast('Recording error: $e', type: _ToastType.error);
    }
  }

  String _fmtRecording(int s) =>
      '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';

  // ── Build ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (!_endFlowShown) { _minimize(); return false; }
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar         : _buildAppBar(),
        body           : Column(children: [
          _buildLoyaltyBanner(),
          Consumer<ChatProvider>(
            builder: (_, chat, __) => chat.isOtherTyping
                ? const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Typing…',
                          style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          Expanded(child: _MessageList(astroId: widget.astroId)),
          _buildInputBar(),
        ]),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final duration = context.watch<ChatProvider>().sessionDuration;
    return AppBar(
      backgroundColor: const Color(0xFFEBC351),
      elevation      : 0,
      // ✅ Arrow down = minimize (mirrors AudioCallScreen)
      leading: IconButton(
        icon     : const Icon(Icons.keyboard_arrow_down, color: Colors.black),
        tooltip  : 'Minimize',
        onPressed: _endFlowShown ? null : _minimize,
      ),
      titleSpacing: 0,
      title: Row(children: [
        CircleAvatar(
          radius         : 20,
          backgroundColor: Colors.grey.shade300,
          child: ClipOval(child: Image.network(widget.userAvatar,
              fit: BoxFit.cover, width: 40, height: 40,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.person, color: Colors.grey))),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.userName,
                  style: const TextStyle(color: Colors.black, fontSize: 15,
                      fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis),
              Row(children: [
                const Icon(Icons.timer_outlined, size: 12, color: Colors.black87),
                const SizedBox(width: 3),
                // ✅ Reads from provider — live without setState
                Text(duration,
                    style: const TextStyle(color: Colors.black87, fontSize: 11,
                        fontWeight: FontWeight.w600)),
                const SizedBox(width: 8),
                Container(width: 7, height: 7,
                    decoration: const BoxDecoration(
                        color: Colors.green, shape: BoxShape.circle)),
                const SizedBox(width: 3),
                const Text('Live',
                    style: TextStyle(color: Colors.green, fontSize: 11)),
              ]),
            ],
          ),
        ),
      ]),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: TextButton(
            onPressed: () => _showEndChatDialog(context),
            child: Container(
              padding   : const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                  color: Colors.red, borderRadius: BorderRadius.circular(20)),
              child: const Text('End',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoyaltyBanner() => Container(
        color  : const Color(0xFFFFF8E1),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child  : const Row(children: [
          Icon(Icons.star, color: Colors.orange, size: 18),
          SizedBox(width: 8),
          Expanded(child: Text(
            'Yay! Just 08:16 minutes more to become a loyal user.',
            style: TextStyle(color: Colors.brown, fontSize: 12),
          )),
        ]),
      );

  Widget _buildInputBar() {
    final chat = context.watch<ChatProvider>();
    final _messageController = _ChatScreenState._ctrl;

    if (chat.chatEnded) {
      return Container(
        padding  : const EdgeInsets.all(12),
        alignment: Alignment.center,
        color    : Colors.grey.shade100,
        child    : const Text('Chat ended',
            style: TextStyle(color: Colors.grey, fontSize: 13)),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(4, 6, 8, 6),
      decoration: BoxDecoration(
        color    : Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06),
            blurRadius: 6, offset: const Offset(0, -2))],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Row(children: [
          IconButton(
            icon     : const Icon(Icons.sentiment_satisfied_alt, color: Colors.grey),
            onPressed: () {},
          ),
          IconButton(
            icon     : const Icon(Icons.attach_file, color: Colors.grey),
            onPressed: chat.isUploading ? null : _showImageSourceSheet,
          ),
          Expanded(
            child: _isRecording
                ? Container(
                    padding   : const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color       : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(24),
                      border      : Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(children: [
                      const _PulsingDot(),
                      const SizedBox(width: 8),
                      Text('🎙 ${_fmtRecording(_recordingSeconds)}',
                          style: const TextStyle(color: Colors.red,
                              fontWeight: FontWeight.w600, fontSize: 14)),
                      const Spacer(),
                      const Text('Tap ■ to send',
                          style: TextStyle(fontSize: 10, color: Colors.grey)),
                    ]),
                  )
                : TextFormField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText      : 'Type a message…',
                      border        : InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 4),
                    ),
                    onChanged: (v) =>
                        context.read<ChatProvider>().setTyping(v.isNotEmpty),
                  ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: _isRecording ? _stopAndSendRecording : _startRecording,
            child: AnimatedContainer(
              duration  : const Duration(milliseconds: 200),
              width: 40, height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isRecording ? Colors.red : Colors.green,
              ),
              child: Center(
                child: _isRecording
                    ? const Icon(Icons.stop, color: Colors.white, size: 20)
                    : const Icon(Icons.mic,  color: Colors.white, size: 20),
              ),
            ),
          ),
          const SizedBox(width: 6),
          if (!_isRecording)
            CircleAvatar(
              backgroundColor: const Color(0xFFEBC351),
              child: chat.isUploading
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.black))
                  : IconButton(
                      icon     : const Icon(Icons.send, color: Colors.black),
                      onPressed: () {
                        final text = _messageController.text.trim();
                        if (text.isEmpty) return;
                        if (_containsRestrictedContent(text)) {
                          _toast('Sharing phone numbers, emails or links is not allowed.',
                              type: _ToastType.warning);
                          return;
                        }
                        context.read<ChatProvider>().sendTextMessage(text);
                        _messageController.clear();
                      },
                    ),
            ),
        ]),
        Padding(
          padding: const EdgeInsets.only(top: 2, bottom: 2),
          child: Text(
            'Tap 🎤 to record  •  Tap ■ to send voice  •  Tap 📎 for image',
            style: TextStyle(fontSize: 9, color: Colors.grey.shade400),
            textAlign: TextAlign.center,
          ),
        ),
      ]),
    );
  }

  // ✅ Static controller so it persists across rebuilds within same state
  static final _ctrl = TextEditingController();
}

// =============================================================================
// RATING SHEET
// =============================================================================
class _ChatRatingSheet extends StatefulWidget {
  final String userName, userAvatar, sessionTime, endReason, channelId;
  final VoidCallback onDone;
  const _ChatRatingSheet({
    required this.userName, required this.userAvatar,
    required this.sessionTime, required this.endReason,
    required this.channelId, required this.onDone,
  });
  @override
  State<_ChatRatingSheet> createState() => _ChatRatingSheetState();
}

class _ChatRatingSheetState extends State<_ChatRatingSheet> {
  int  _stars     = 0;
  final _reviewCtrl = TextEditingController();
  bool _submitting  = false;
  static const _labels = ['', 'Poor', 'Fair', 'Good', 'Very Good', 'Excellent'];
  @override void dispose() { _reviewCtrl.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (_stars == 0) {
      showTopToast(context, 'Please select a star rating.', type: _ToastType.warning);
      return;
    }
    setState(() => _submitting = true);
    await Future.delayed(const Duration(milliseconds: 500));
    showTopToast(context, 'Thank you for your rating!', type: _ToastType.success);
    setState(() => _submitting = false);
    await Future.delayed(const Duration(milliseconds: 600));
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    final bi = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding: EdgeInsets.only(left: 20, right: 20, top: 24, bottom: 24 + bi),
      decoration: const BoxDecoration(color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 20),
        Container(
          padding   : const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(color: const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFEBC351))),
          child: Row(children: [
            Container(width: 52, height: 52,
                decoration: BoxDecoration(shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFEBC351), width: 2)),
                child: ClipOval(child: Image.network(widget.userAvatar,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(color: const Color(0xFFEBC351),
                        child: const Icon(Icons.person, color: Colors.white))))),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(widget.userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 2),
              Row(children: [
                const Icon(Icons.chat_bubble_outline, size: 12, color: Colors.brown),
                const SizedBox(width: 4),
                Text('Chat · ${widget.sessionTime}',
                    style: const TextStyle(fontSize: 12, color: Colors.brown)),
              ]),
            ])),
            Container(
              padding   : const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12)),
              child: const Text('Ended',
                  style: TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.w600)),
            ),
          ]),
        ),
        const SizedBox(height: 24),
        const Text('Rate Your Experience',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text('How was your chat with ${widget.userName}?',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (i) {
            final s = i + 1;
            return GestureDetector(
              onTap: () => setState(() => _stars = s),
              child: Padding(padding: const EdgeInsets.all(4),
                child: Icon(
                  _stars >= s ? Icons.star_rounded : Icons.star_outline_rounded,
                  size: 44,
                  color: _stars >= s ? const Color(0xFFEBC351) : Colors.grey.shade300,
                )),
            );
          }),
        ),
        if (_stars > 0) Padding(padding: const EdgeInsets.only(top: 6),
          child: Text(_labels[_stars],
              style: const TextStyle(color: Color(0xFFEBC351),
                  fontWeight: FontWeight.w600, fontSize: 14))),
        const SizedBox(height: 20),
        TextField(controller: _reviewCtrl, maxLines: 3, maxLength: 300,
          decoration: InputDecoration(
            hintText     : 'Write your review (optional)…',
            hintStyle    : TextStyle(color: Colors.grey.shade400, fontSize: 13),
            filled       : true, fillColor: Colors.grey.shade50,
            border       : OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFEBC351))),
            contentPadding: const EdgeInsets.all(12),
          )),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side   : BorderSide(color: Colors.grey.shade300),
              shape  : RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _submitting ? null : widget.onDone,
            child: const Text('Skip', style: TextStyle(color: Colors.grey)),
          )),
          const SizedBox(width: 12),
          Expanded(flex: 2, child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding        : const EdgeInsets.symmetric(vertical: 14),
              backgroundColor: const Color(0xFFEBC351),
              shape          : RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            onPressed: _submitting ? null : _submit,
            child: _submitting
                ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                : const Text('Submit Rating',
                    style: TextStyle(color: Colors.black,
                        fontWeight: FontWeight.bold, fontSize: 15)),
          )),
        ]),
      ]),
    );
  }
}

// =============================================================================
// PULSING DOT
// =============================================================================
class _PulsingDot extends StatefulWidget {
  const _PulsingDot();
  @override State<_PulsingDot> createState() => _PulsingDotState();
}
class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _anim;
  @override void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 700))..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 1.0).animate(_ctrl);
  }
  @override void dispose() { _ctrl.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => FadeTransition(
    opacity: _anim,
    child: Container(width: 10, height: 10,
        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
  );
}

// =============================================================================
// MESSAGE LIST
// =============================================================================
class _MessageList extends StatefulWidget {
  final String astroId;
  const _MessageList({required this.astroId});
  @override State<_MessageList> createState() => _MessageListState();
}

class _MessageListState extends State<_MessageList> {
  String? _previewUrl;
  final ScrollController _scrollCtrl = ScrollController();
  int _prevCount = 0;

  @override void dispose() { _scrollCtrl.dispose(); super.dispose(); }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Consumer<ChatProvider>(
        builder: (context, chat, _) {
          final total = chat.messages.length + (chat.isUploading ? 1 : 0);
          if (total > _prevCount) { _prevCount = total; _scrollToBottom(); }

          return ListView.builder(
            controller: _scrollCtrl,
            padding   : const EdgeInsets.only(bottom: 10),
            itemCount : chat.messages.length + (chat.isUploading ? 1 : 0),
            itemBuilder: (context, index) {
              if (chat.isUploading && index == chat.messages.length) {
                return Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    margin  : const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    padding : const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(color: const Color(0xFFFFF9C4),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade200)),
                    child: const Row(mainAxisSize: MainAxisSize.min,
                        children: [_BouncingDots()]),
                  ),
                );
              }
              final msg  = chat.messages[index];
              final isMe = msg.from == widget.astroId;
              return Align(
                alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin     : const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  padding    : const EdgeInsets.all(12),
                  constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75),
                  decoration : BoxDecoration(
                    color       : isMe ? const Color(0xFFFFF9C4) : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border      : Border.all(color: Colors.grey.shade200),
                    boxShadow   : [BoxShadow(
                        color: Colors.black.withOpacity(0.05), blurRadius: 3)],
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _buildContent(msg.type, msg.message),
                    const SizedBox(height: 4),
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      Text(chat.formatTime(msg.dateTime),
                          style: const TextStyle(fontSize: 10, color: Colors.grey)),
                      if (isMe) Icon(Icons.done_all, size: 14,
                          color: msg.seen ? Colors.blue : Colors.grey),
                    ]),
                  ]),
                ),
              );
            },
          );
        },
      ),
      if (_previewUrl != null)
        GestureDetector(
          onTap: () => setState(() => _previewUrl = null),
          child: Container(color: Colors.black,
            child: Center(child: InteractiveViewer(
              child: Image.network(_previewUrl!, fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                      Icons.broken_image, color: Colors.white, size: 48)),
            )),
          ),
        ),
    ]);
  }

  Widget _buildContent(String type, String message) {
    switch (type) {
      case 'image':
        return GestureDetector(
          onTap: () => setState(() => _previewUrl = message),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(message, width: 200, fit: BoxFit.cover,
              loadingBuilder: (_, child, p) {
                if (p == null) return child;
                return SizedBox(width: 200, height: 140,
                  child: Center(child: CircularProgressIndicator(
                    value: p.expectedTotalBytes != null
                        ? p.cumulativeBytesLoaded / p.expectedTotalBytes! : null,
                    strokeWidth: 2)));
              },
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.broken_image, size: 48, color: Colors.grey)),
          ),
        );
      case 'audio':
        return _AudioPlayerWidget(url: message);
      default:
        return Text(message, style: const TextStyle(color: Colors.black));
    }
  }
}

// =============================================================================
// AUDIO PLAYER
// =============================================================================
class _AudioPlayerWidget extends StatefulWidget {
  final String url;
  const _AudioPlayerWidget({required this.url});
  @override State<_AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}
class _AudioPlayerWidgetState extends State<_AudioPlayerWidget> {
  final _player  = AudioPlayer();
  bool _loading  = true, _hasError = false, _playing = false;
  Duration _pos  = Duration.zero, _dur = Duration.zero;
  final List<StreamSubscription> _subs = [];
  @override void initState() { super.initState(); _init(); }
  Future<void> _init() async {
    try {
      final dur = await _player.setUrl(widget.url);
      if (mounted) setState(() { _dur = dur ?? Duration.zero; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _loading = false; _hasError = true; }); return;
    }
    _subs.add(_player.positionStream.listen((p) {
      if (mounted) setState(() => _pos = p); }));
    _subs.add(_player.durationStream.listen((d) {
      if (mounted && d != null) setState(() => _dur = d); }));
    _subs.add(_player.playerStateStream.listen((s) {
      if (s.processingState == ProcessingState.completed && mounted) {
        setState(() { _playing = false; _pos = Duration.zero; });
        _player.seek(Duration.zero); _player.pause();
      }
    }));
  }
  @override void dispose() {
    for (final s in _subs) s.cancel(); _player.dispose(); super.dispose(); }
  Future<void> _toggle() async {
    if (_loading || _hasError) return;
    if (_playing) { await _player.pause(); setState(() => _playing = false); }
    else          { await _player.play();  setState(() => _playing = true);  }
  }
  String _fmt(Duration d) =>
      '${d.inMinutes.remainder(60).toString().padLeft(2, '0')}:'
      '${d.inSeconds.remainder(60).toString().padLeft(2, '0')}';
  @override
  Widget build(BuildContext context) {
    final progress = _dur.inMilliseconds > 0
        ? (_pos.inMilliseconds / _dur.inMilliseconds).clamp(0.0, 1.0) : 0.0;
    if (_hasError) return const Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.error_outline, color: Colors.red, size: 20), SizedBox(width: 6),
      Text('Audio unavailable', style: TextStyle(fontSize: 12, color: Colors.red))]);
    return Row(mainAxisSize: MainAxisSize.min, children: [
      GestureDetector(onTap: _toggle,
        child: Container(width: 36, height: 36,
          decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.orange.shade100),
          child: _loading
              ? const Padding(padding: EdgeInsets.all(8),
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.orange))
              : Icon(_playing ? Icons.pause : Icons.play_arrow,
                  color: Colors.orange, size: 22))),
      const SizedBox(width: 8),
      SizedBox(width: 130, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ClipRRect(borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(value: progress,
              backgroundColor: Colors.grey.shade300, color: Colors.orange, minHeight: 4)),
        const SizedBox(height: 4),
        Text('${_fmt(_pos)} / ${_fmt(_dur)}',
            style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ])),
    ]);
  }
}

// =============================================================================
// BOUNCING DOTS
// =============================================================================
class _BouncingDots extends StatefulWidget {
  const _BouncingDots();
  @override State<_BouncingDots> createState() => _BouncingDotsState();
}
class _BouncingDotsState extends State<_BouncingDots> with TickerProviderStateMixin {
  late List<AnimationController> _ctrls;
  late List<Animation<double>>   _anims;
  @override void initState() {
    super.initState();
    _ctrls = List.generate(3, (i) {
      final c = AnimationController(vsync: this,
          duration: const Duration(milliseconds: 500));
      Future.delayed(Duration(milliseconds: i * 150),
          () => mounted ? c.repeat(reverse: true) : null);
      return c;
    });
    _anims = _ctrls.map((c) => Tween<double>(begin: 0, end: -6).animate(c)).toList();
  }
  @override void dispose() { for (final c in _ctrls) c.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min,
    children: List.generate(3, (i) => AnimatedBuilder(animation: _anims[i],
      builder: (_, __) => Transform.translate(offset: Offset(0, _anims[i].value),
        child: Container(margin: const EdgeInsets.symmetric(horizontal: 3),
            width: 8, height: 8,
            decoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle))))));
}