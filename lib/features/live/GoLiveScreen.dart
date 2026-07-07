// lib/features/live/GoLiveScreen.dart
import 'dart:async';
import 'dart:convert';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:astrologer_app/core/config/theme_config.dart';
import 'package:astrologer_app/MainNavScreen.dart';
import 'package:astrologer_app/core/widgets/ThemeGradientButton.dart';
import 'package:astrologer_app/model/AstrologerLiveEventsListModel.dart';
import 'package:astrologer_app/service/apiClient.dart';
import 'package:astrologer_app/service/liveService.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_database/ui/firebase_animated_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum _PrivateCallState { none, pending, active }

class GoLiveScreen extends StatefulWidget {
  final LiveEventData? event;
  final String chatFontSize;
  const GoLiveScreen({super.key, this.event, this.chatFontSize = 'Medium'});

  @override
  State<GoLiveScreen> createState() => _GoLiveScreenState();
}

class _GoLiveScreenState extends State<GoLiveScreen>
    with WidgetsBindingObserver {
  static const _appId  = "8782e154141a4c0bbc8acaa3004d21f2";
  static const _dbUrl  = "https://astrogurujii-production-default-rtdb.firebaseio.com/";
int _liveLocalUid = 0; // actual uid assigned by Agora on join
  // ── Main engine ──────────────────────────────────────────────────────────
  RtcEngine? _engine;
  bool _engineReady = false;
  bool _isLive      = false;
  bool _isLoading   = false;
  bool _micOn       = true;
  bool _camOn       = true;

  // ── Viewer count ──────────────────────────────────────────────────────────
  int _viewerCount = 0;
  StreamSubscription<DatabaseEvent>? _viewerSub;
  DatabaseReference? _viewerRef;

  // ── Chat ──────────────────────────────────────────────────────────────────
  double _resolvedFontSize(double sw) {
    switch (widget.chatFontSize) {
      case 'Small': return sw * 0.026;
      case 'Large': return sw * 0.038;
      default:      return sw * 0.031;
    }
  }

  final TextEditingController _msgCtrl  = TextEditingController();
  final FocusNode             _msgFocus = FocusNode();
  DatabaseReference? _chatRef;
  String _astroId   = '';
  String _astroName = '';
  bool   _chatReady = false;
  bool   _showChat  = true;

  // ── Private call ──────────────────────────────────────────────────────────
  _PrivateCallState _privateState     = _PrivateCallState.none;
  String            _privateChannelId = '';
  String            _privateUserName  = '';
  bool              _privateMicMuted  = false;
  int?              _privateUid;      // uid used for joinChannelEx
  StreamSubscription<DatabaseEvent>? _privateSub;
  Timer?            _debitTimer;
  int               _callSeconds = 0;
  Timer?            _callTimer;

  String _authToken = '';
  final ApiClient _client = ApiClient();

  // ── Helpers ───────────────────────────────────────────────────────────────
  String get _liveChannelId {
    final ch = widget.event?.channelId ?? '';
    return ch.isNotEmpty ? ch : (widget.event?.id ?? 'live_default');
  }

  DatabaseReference get _db => FirebaseDatabase.instanceFor(
      app: Firebase.app(), databaseURL: _dbUrl).ref();

  RtcEngineEx get _engineEx => _engine as RtcEngineEx;

  // ── Lifecycle ─────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _boot();
  }

  Future<void> _boot() async {
    await _loadUser();
    await _initAgora();
    _initFirebase();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _engine?.muteLocalVideoStream(true);
    } else if (state == AppLifecycleState.resumed) {
      if (_camOn) _engine?.muteLocalVideoStream(false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _viewerSub?.cancel();
    _privateSub?.cancel();
    _debitTimer?.cancel();
    _callTimer?.cancel();
    _msgCtrl.dispose();
    _msgFocus.dispose();
    _engine?.stopPreview();
    _engine?.leaveChannel();
    _engine?.release();
    super.dispose();
  }

  Future<void> _loadUser() async {
    final p = await SharedPreferences.getInstance();
    _astroId   = p.getString('astro_id')   ?? '';
    _astroName = p.getString('astro_name') ?? 'Astrologer';
    _authToken = p.getString('token')      ?? '';
  }

  // ── Agora init ────────────────────────────────────────────────────────────
  Future<void> _initAgora() async {
    _engine = createAgoraRtcEngine();
    await _engine!.initialize(const RtcEngineContext(
      appId         : _appId,
      channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
    ));

    _engine!.registerEventHandler(RtcEngineEventHandler(
      onJoinChannelSuccess: (conn, elapsed) {
        if (conn.channelId == _liveChannelId) {
          _liveLocalUid = conn.localUid ?? 0;
          debugPrint('✅ Live joined with uid: $_liveLocalUid');
          if (_camOn) {
      _engine?.startPreview();
    }
        }
      },
      onUserJoined: (conn, uid, __) {
        if (conn.channelId == _liveChannelId) {
          _viewerRef?.child(uid.toString()).set(true);
        }
      },
      onUserOffline: (conn, uid, __) {
        if (conn.channelId == _liveChannelId) {
          _viewerRef?.child(uid.toString()).remove();
        } else if (conn.channelId == _privateChannelId &&
            _privateState == _PrivateCallState.active) {
          // User dropped from private channel → end call
          _endPrivateCall();
        }
      },
      onError: (code, msg) => debugPrint('❌ Agora $code: $msg'),
    ));

    await _engine!.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
    await _engine!.enableVideo();
    await _engine!.enableAudio();
    await _engine!.startPreview();
    if (mounted) setState(() => _engineReady = true);
  }

  // ── Firebase init ─────────────────────────────────────────────────────────
  void _initFirebase() {
    _chatRef   = _db.child('GroupLive').child(_liveChannelId);
    _viewerRef = _db.child('LiveViewers').child(_liveChannelId);

    _viewerSub = _viewerRef!.onValue.listen((event) {
      final val   = event.snapshot.value;
      final count = (val is Map) ? val.length : 0;
      if (mounted) setState(() => _viewerCount = count);
    });

    _privateSub = _db
        .child('LivePrivateCall')
        .child(_liveChannelId)
        .onValue
        .listen(_onPrivateCallSnapshot);

    if (mounted) setState(() => _chatReady = true);
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  PRIVATE CALL — ASTROLOGER SIDE
  // ══════════════════════════════════════════════════════════════════════════

  void _onPrivateCallSnapshot(DatabaseEvent event) {
    if (!mounted) return;
    final val = event.snapshot.value;
    if (val == null) {
      if (_privateState == _PrivateCallState.active) {
        _cleanupPrivateCall(notify: false);
      }
      if (mounted) setState(() => _privateState = _PrivateCallState.none);
      return;
    }
    final data   = Map<String, dynamic>.from(val as Map);
    final status = data['status'] as String? ?? '';

    if (status == 'pending' && _privateState == _PrivateCallState.none) {
      _privateChannelId = data['channel_id'] as String? ?? '';
      _privateUserName  = data['user_name']  as String? ?? 'User';
      if (mounted) setState(() => _privateState = _PrivateCallState.pending);
      _showIncomingCallOverlay();
    } else if (status == 'ended' && _privateState == _PrivateCallState.active) {
      _cleanupPrivateCall(notify: false);
      if (mounted) setState(() => _privateState = _PrivateCallState.none);
    }
  }

  void _showIncomingCallOverlay() {
    showModalBottomSheet(
      context        : context,
      isDismissible  : false,
      enableDrag     : false,
      backgroundColor: Colors.transparent,
      builder: (_) => _IncomingCallSheet(
        userName : _privateUserName,
        onAccept : () { Navigator.pop(context); _acceptPrivateCall(); },
        onDecline: () { Navigator.pop(context); _rejectPrivateCall(); },
      ),
    );
  }

  // ── Accept ────────────────────────────────────────────────────────────────
  Future<void> _acceptPrivateCall() async {
    if (_privateChannelId.isEmpty) return;

    // 1. Tell server — this flips Call status to accept_astro and writes
    //    CallSession to Firebase so the user-side countdown can start
    final ok = await _callStatusUpdate(_privateChannelId, 'accept_astro');
    if (!ok) {
      _toast('Failed to accept call', error: true);
      _db.child('LivePrivateCall').child(_liveChannelId)
          .update({'status': 'rejected'});
      if (mounted) setState(() => _privateState = _PrivateCallState.none);
      return;
    }

    // 2. Tell user via Firebase that we accepted
    _db.child('LivePrivateCall').child(_liveChannelId)
        .update({'status': 'accepted'});

    // 3. Mute public audio so viewers don't hear private conversation
    //    Video stays ON — viewers keep watching the live stream
   // Mute only the publish on main channel using Ex version
// so device mic hardware stays active for private channel
try {
      await (_engine as RtcEngineEx).updateChannelMediaOptionsEx(
        options: const ChannelMediaOptions(
          publishMicrophoneTrack: false,
          publishCameraTrack    : true,
        ),
        connection: RtcConnection(
          channelId: _liveChannelId,
          localUid : _liveLocalUid, // stored from onJoinChannelSuccess
        ),
      );
    } catch (e) {
      debugPrint('❌ mute public mic error: $e — continuing anyway');
      // Non-fatal: private call still works, public just hears astrologer too
    }

    // Force speaker so astrologer can hear user
    await _engine?.setEnableSpeakerphone(true);
    // 4. Join the private channel as a SECOND CONNECTION on the SAME engine
    //    using joinChannelEx (requires agora_rtc_engine 6.x)
    _privateUid = DateTime.now().millisecondsSinceEpoch % 100000 + 1000;
    final privToken = await _fetchAgoraToken(_privateChannelId);

    try {
      await _engineEx.joinChannelEx(
        token     : privToken,
        connection: RtcConnection(
          channelId: _privateChannelId,
          localUid : _privateUid!,
        ),
        options: const ChannelMediaOptions(
          publishMicrophoneTrack: true,
          publishCameraTrack    : true,
          autoSubscribeAudio    : true,
          autoSubscribeVideo    : false,
          clientRoleType        : ClientRoleType.clientRoleBroadcaster,
          channelProfile        : ChannelProfileType.channelProfileCommunication,
        ),
      );
    } catch (e) {
      debugPrint('❌ joinChannelEx error: $e');
      // Restore public audio if join failed
      await _engine?.muteLocalAudioStream(!_micOn);
      _toast('Failed to connect private call', error: true);
      _db.child('LivePrivateCall').child(_liveChannelId)
          .update({'status': 'rejected'});
      if (mounted) setState(() => _privateState = _PrivateCallState.none);
      return;
    }
// after joinChannelEx succeeds:
    await _engine?.setEnableSpeakerphone(true);
    _startDebitTimer();
    _startCallTimer();
    if (mounted) setState(() => _privateState = _PrivateCallState.active);
    await _postSystemMsg('🔒 Private call started');
   
   
  }

  // ── Reject ────────────────────────────────────────────────────────────────
  Future<void> _rejectPrivateCall() async {
    if (_privateChannelId.isNotEmpty) {
      await _callStatusUpdate(_privateChannelId, 'reject_astro');
    }
    _db.child('LivePrivateCall').child(_liveChannelId)
        .update({'status': 'rejected'});
    if (mounted) setState(() {
      _privateState     = _PrivateCallState.none;
      _privateChannelId = '';
    });
  }

  // ── End ───────────────────────────────────────────────────────────────────
  Future<void> _endPrivateCall() async {
    await _cleanupPrivateCall(notify: true);
    if (mounted) setState(() => _privateState = _PrivateCallState.none);
  }

  // ── Cleanup ───────────────────────────────────────────────────────────────
  Future<void> _cleanupPrivateCall({required bool notify}) async {
  _debitTimer?.cancel();
  _debitTimer = null;
  _callTimer?.cancel();
  _callTimer  = null;

  if (notify && _privateChannelId.isNotEmpty) {
    await _callStatusUpdate(_privateChannelId, 'end_astro');
    _db.child('LivePrivateCall').child(_liveChannelId)
        .update({'status': 'ended'});
  }

  // Step 1: Leave private channel
  if (_privateUid != null && _privateChannelId.isNotEmpty) {
    try {
      await _engineEx.leaveChannelEx(
        connection: RtcConnection(
          channelId: _privateChannelId,
          localUid : _privateUid!,
        ),
      );
    } catch (e) {
      debugPrint('❌ leaveChannelEx error: $e');
    }
  }

  _privateUid       = null;
  _privateChannelId = '';
  _privateUserName  = '';
  _privateMicMuted  = false;
  _callSeconds      = 0;

  await _engine?.setEnableSpeakerphone(false);

  // Step 2: Leave main channel completely
  try {
    await _engine?.leaveChannel();
  } catch (e) {
    debugPrint('❌ leaveChannel error: $e');
  }

  // Step 3: Wait for Agora to fully teardown
  await Future.delayed(const Duration(milliseconds: 500));

  // Step 4: Rejoin main live channel as broadcaster
  try {
    final token = await _fetchAgoraToken(_liveChannelId);
    await _engine?.joinChannel(
      token    : token,
      channelId: _liveChannelId,
      uid      : _liveLocalUid,   // use same uid as before
      options  : ChannelMediaOptions(
        clientRoleType        : ClientRoleType.clientRoleBroadcaster,
        channelProfile        : ChannelProfileType.channelProfileLiveBroadcasting,
        publishCameraTrack    : _camOn,
        publishMicrophoneTrack: _micOn,
        autoSubscribeVideo    : false,
        autoSubscribeAudio    : false,
      ),
    );
    debugPrint('✅ Rejoined live channel after private call');
  } catch (e) {
    debugPrint('❌ rejoin error: $e');
  }

  await _postSystemMsg('🔓 Private call ended');
}

  // ── Mic toggle (private channel only) ────────────────────────────────────
  Future<void> _togglePrivateMic() async {
  _privateMicMuted = !_privateMicMuted;
  
  // Toggle mic on private channel only via Ex
  if (_privateChannelId.isNotEmpty && _privateUid != null) {
    try {
      await _engineEx.updateChannelMediaOptionsEx(
        options: ChannelMediaOptions(
          publishMicrophoneTrack: !_privateMicMuted,
        ),
        connection: RtcConnection(
          channelId: _privateChannelId,
          localUid : _privateUid!,
        ),
      );
    } catch (e) {
      debugPrint('❌ togglePrivateMic error: $e');
    }
  }
  if (mounted) setState(() {});
}

  // ── Timers ────────────────────────────────────────────────────────────────
  void _startCallTimer() {
    _callSeconds = 0;
    _callTimer?.cancel();
    _callTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _callSeconds++);
    });
  }

  String get _callDurationLabel {
    final h = _callSeconds ~/ 3600;
    final m = (_callSeconds % 3600) ~/ 60;
    final s = _callSeconds % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _startDebitTimer() {
    _debitTimer?.cancel();
    _debitTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (_privateChannelId.isNotEmpty) _debitUserPerMinute(_privateChannelId);
    });
  }

  // ── Backend helpers ───────────────────────────────────────────────────────
  Future<bool> _callStatusUpdate(String channelId, String status) async {
    try {
      final resp = await _client.post(
        'astrologer_api/call_status_update',
        {'channel_id': channelId, 'status': status},
      );
      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body);
        debugPrint('📞 call_status_update [$status] → ${body['status']}');
        return body['status'] == true;
      }
    } catch (e) {
      debugPrint('call_status_update error: $e');
    }
    return false;
  }

  Future<void> _debitUserPerMinute(String channelId) async {
    try {
      await _client.post(
        'astrologer_api/debit_user_amount_per_minute',
        {'channel_id': channelId},
      );
    } catch (e) {
      debugPrint('debit error: $e');
    }
  }

  Future<String> _fetchAgoraToken(String channelId) async {
    try {
      final resp = await _client.post(
        'user_api/agora_token',
        {'channel_id': channelId},
      );
      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body);
        if (body['status'] == true) return body['token'] as String? ?? '';
      }
    } catch (e) {
      debugPrint('agora_token error: $e');
    }
    return '';
  }

  // ── Live controls ─────────────────────────────────────────────────────────
  Future<void> _startLive() async {
    if (widget.event?.id == null) {
      _toast('No event ID found', error: true);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final body = await Liveservice().LiveStart(widget.event!.id!);
      if (!mounted) return;
      if (body['status'] == true) {
        final agoraToken = body['token'] as String? ?? '';
        await _engine!.joinChannel(
          token    : agoraToken,
          channelId: _liveChannelId,
          uid      : 0,
          options  : const ChannelMediaOptions(
            clientRoleType        : ClientRoleType.clientRoleBroadcaster,
            channelProfile        : ChannelProfileType.channelProfileLiveBroadcasting,
            publishCameraTrack    : true,
            publishMicrophoneTrack: true,
            autoSubscribeVideo    : false,
            autoSubscribeAudio    : false,
          ),
        );
        await _postSystemMsg('🔴 Live session started!');
        if (mounted) setState(() => _isLive = true);
      } else {
        _toast(body['message'] ?? 'Cannot go live right now', error: true);
      }
    } catch (e) {
      if (mounted) _toast('Error: $e', error: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _endLive() async {
    setState(() => _isLoading = true);
    try {
      if (_privateState == _PrivateCallState.active) {
        await _cleanupPrivateCall(notify: true);
      }
      await _engine?.leaveChannel();
      await _viewerRef?.remove();
      await _postSystemMsg('⏹ Live session ended.');
      final body = await Liveservice().LiveEnd(widget.event!.id!);
      if (!mounted) return;
      if (body['status'] == true) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const MainNavScreen()),
          (route) => false,
        );
      } else {
        setState(() { _isLive = false; _isLoading = false; });
        _toast(body['message'] ?? 'Failed to end live', error: true);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _confirmEnd() async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (_) {
        final c = context.colors;
        return AlertDialog(
          backgroundColor: c.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('End Live Session?',
              style: TextStyle(color: c.text, fontWeight: FontWeight.w700)),
          content: Text('Viewers will be disconnected. Are you sure?',
              style: TextStyle(color: c.subText)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel',
                  style: TextStyle(
                      color: AppTheme.primaryYellow,
                      fontWeight: FontWeight.w600)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('End Live',
                  style: TextStyle(
                      color: Colors.red, fontWeight: FontWeight.w600)),
            ),
          ],
        );
      },
    );
    if (yes == true) _endLive();
  }

  // Main mic — always controls public channel only
  Future<void> _toggleMic() async {
    _micOn = !_micOn;
    // Only affect public channel if no private call active
    if (_privateState != _PrivateCallState.active) {
      await _engine?.muteLocalAudioStream(!_micOn);
    }
    setState(() {});
  }

  Future<void> _toggleCam() async {
    _camOn = !_camOn;
    await _engine?.muteLocalVideoStream(!_camOn);
    setState(() {});
  }

  Future<void> _sendMessage() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    _msgCtrl.clear();
    _msgFocus.unfocus();
    await _writeChat(name: _astroName, message: text, isSystem: false);
  }

  Future<void> _postSystemMsg(String msg) async =>
      _writeChat(name: 'System', message: msg, isSystem: true);

  Future<void> _writeChat({
    required String name,
    required String message,
    required bool isSystem,
  }) async {
    if (_chatRef == null) return;
    final ref = _chatRef!.push();
    await ref.set({
      'from'      : isSystem ? 'system' : _astroId,
      'name'      : name,
      'message'   : message,
      'message_id': ref.key,
      'date_time' : DateTime.now().millisecondsSinceEpoch,
      'is_system' : isSystem,
    });
  }

  void _toast(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content        : Text(msg),
      backgroundColor: error ? AppTheme.accentRed : Colors.green.shade700,
      behavior       : SnackBarBehavior.floating,
      shape          : RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10)),
    ));
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  BUILD
  // ══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final mq  = MediaQuery.of(context);
    final sw  = mq.size.width;
    final sh  = mq.size.height;
    final top = mq.padding.top;
    final bot = mq.padding.bottom;

    return WillPopScope(
      onWillPop: () async {
        if (_isLive) { _confirmEnd(); return false; }
        return true;
      },
      child: Scaffold(
        backgroundColor         : Colors.black,
        resizeToAvoidBottomInset: true,
        body: Stack(children: [

          // LAYER 1: camera feed
          Positioned.fill(
            child: _engineReady && _engine != null
                ? AgoraVideoView(
                    controller: VideoViewController(
                      rtcEngine        : _engine!,
                      canvas           : const VideoCanvas(uid: 0),
                      useFlutterTexture: true,
                    ),
                  )
                : Container(
                    color: const Color(0xFF0D0D1A),
                    child: Center(child: CircularProgressIndicator(
                        color: AppTheme.primaryYellow)),
                  ),
          ),

          // LAYER 2: top gradient
          Positioned(
            top: 0, left: 0, right: 0, height: sh * 0.25,
            child: Container(decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin : Alignment.topCenter,
                end   : Alignment.bottomCenter,
                colors: [Colors.black87, Colors.transparent],
              ),
            )),
          ),

          // LAYER 3: bottom gradient
          Positioned(
            bottom: 0, left: 0, right: 0, height: sh * 0.42,
            child: Container(decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin : Alignment.bottomCenter,
                end   : Alignment.topCenter,
                colors: [Colors.black, Colors.transparent],
              ),
            )),
          ),

          // LAYER 4: top bar
          Positioned(
            top  : top + 12,
            left : sw * 0.04,
            right: sw * 0.04,
            child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
              GestureDetector(
                onTap: () =>
                    _isLive ? _confirmEnd() : Navigator.pop(context),
                child: Container(
                  padding   : const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color            : Colors.black45,
                      borderRadius     : BorderRadius.circular(50)),
                  child: const Icon(Icons.arrow_back_ios_new,
                      color: Colors.white, size: 18),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.event?.title ?? 'Live Session',
                    maxLines : 1,
                    overflow : TextOverflow.ellipsis,
                    style: TextStyle(
                      color      : Colors.white,
                      fontSize   : sw * 0.042,
                      fontWeight : FontWeight.bold,
                      shadows    : const [
                        Shadow(color: Colors.black54, blurRadius: 8)
                      ],
                    ),
                  ),
                  if ((widget.event?.liveDate ?? '').isNotEmpty)
                    Text(
                      '${widget.event!.liveDate}  '
                      '${widget.event!.startTime ?? ''}',
                      style: TextStyle(
                          color   : Colors.white60,
                          fontSize: sw * 0.030),
                    ),
                ],
              )),
              if (_isLive) ...[
                _LiveBadge(sw: sw),
                const SizedBox(width: 8)
              ],
              if (_isLive) ...[
                _ViewerBadge(count: _viewerCount, sw: sw),
                const SizedBox(width: 8)
              ],
              GestureDetector(
                onTap: () => setState(() => _showChat = !_showChat),
                child: Container(
                  padding   : const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color       : Colors.black45,
                      borderRadius: BorderRadius.circular(50)),
                  child: Icon(
                    _showChat
                        ? Icons.chat_bubble_rounded
                        : Icons.chat_bubble_outline_rounded,
                    color: Colors.white,
                    size : sw * 0.052,
                  ),
                ),
              ),
            ]),
          ),

          // LAYER 4b: private call badge
          if (_privateState == _PrivateCallState.active)
            Positioned(
              top  : top + 80,
              left : sw * 0.04,
              right: sw * 0.04,
              child: _PrivateCallBadge(
                sw          : sw,
                userName    : _privateUserName,
                micMuted    : _privateMicMuted,
                callDuration: _callDurationLabel,
                onMicTap    : _togglePrivateMic,
                onEndTap    : _endPrivateCall,
              ),
            ),

          // LAYER 5: SVG face frame
          if (!_isLive)
            Positioned(
              top: sh * 0.16, left: 0, right: 0,
              child: Center(child: SizedBox(
                height: sh * 0.36, width: sw * 0.70,
                child: Stack(children: [
                  Positioned.fill(child: SvgPicture.asset(
                      'assets/images/go_live.svg',
                      fit: BoxFit.contain)),
                  Positioned(
                    bottom: sh * 0.04, left: 0, right: 0,
                    child: const Center(child: Text('Face Here',
                        style: TextStyle(
                          color     : Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize  : 15,
                          shadows   : [
                            Shadow(color: Colors.black, blurRadius: 4)
                          ],
                        ))),
                  ),
                ]),
              )),
            ),

          // LAYER 6: chat messages
          if (_isLive && _showChat && _chatReady && _chatRef != null)
            Positioned(
              bottom: bot + sh * 0.155,
              left  : sw * 0.03,
              width : sw * 0.64,
              height: sh * 0.28,
              child: ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  begin : Alignment.topCenter,
                  end   : Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.white],
                  stops : [0.0, 0.25],
                ).createShader(bounds),
                blendMode: BlendMode.dstIn,
                child    : FirebaseAnimatedList(
                  query  : _chatRef!
                      .orderByChild('date_time')
                      .limitToLast(50),
                  reverse: true,
                  physics: const ClampingScrollPhysics(),
                  itemBuilder: (_, snap, __, ___) {
                    final raw = snap.value;
                    if (raw == null) return const SizedBox.shrink();
                    final data = Map<String, dynamic>.from(
                        raw as Map<dynamic, dynamic>);
                    final isMe     = data['from']      == _astroId;
                    final isSystem = data['is_system'] == true;
                    return Padding(
                      padding: EdgeInsets.only(bottom: sh * 0.007),
                      child: _ChatBubble(
                        name    : data['name']    ?? '',
                        message : data['message'] ?? '',
                        isMe    : isMe,
                        isSystem: isSystem,
                        sw      : sw,
                        fontSize: _resolvedFontSize(sw),
                      ),
                    );
                  },
                ),
              ),
            ),

          // LAYER 7: chat input
          if (_isLive)
            Positioned(
              bottom: bot + sh * 0.12,
              left  : sw * 0.03,
              right : sw * 0.03,
              child : _ChatInput(
                controller: _msgCtrl,
                focusNode : _msgFocus,
                onSend    : _sendMessage,
                sw        : sw,
                sh        : sh,
              ),
            ),

          // LAYER 8: bottom controls
          Positioned(
            bottom: bot + sh * 0.015,
            left  : sw * 0.03,
            right : sw * 0.03,
            child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
              _ControlButton(
                svgPath: 'assets/images/mic.svg',
                active : _micOn,
                onTap  : _isLoading ? null : _toggleMic,
                size   : sw * 0.14,
              ),
              SizedBox(width: sw * 0.03),
              _ControlButton(
                svgPath: 'assets/images/video-camera.svg',
                active : _camOn,
                onTap  : _isLoading ? null : _toggleCam,
                size   : sw * 0.14,
              ),
              SizedBox(width: sw * 0.03),
              Expanded(child: GradientButton(
                height      : sw * 0.14,
                title       : _isLoading
                    ? 'Please wait...'
                    : _isLive
                        ? 'End Live'
                        : 'Click to Go Live',
                onTap       : _isLoading
                    ? () {}
                    : _isLive
                        ? _confirmEnd
                        : _startLive,
                borderRadius: BorderRadius.circular(12),
              )),
            ]),
          ),

          // LAYER 9: loading overlay
          if (_isLoading)
            Positioned.fill(child: Container(
              color: Colors.black54,
              child: Center(child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                CircularProgressIndicator(color: AppTheme.primaryYellow),
                const SizedBox(height: 12),
                const Text('Please wait...',
                    style: TextStyle(color: Colors.white70, fontSize: 14)),
              ])),
            )),
        ]),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  INCOMING CALL SHEET
// ══════════════════════════════════════════════════════════════════════════════
class _IncomingCallSheet extends StatelessWidget {
  final String       userName;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  const _IncomingCallSheet({
    required this.userName,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    return Container(
      margin    : EdgeInsets.symmetric(horizontal: sw * 0.04, vertical: 12),
      padding   : EdgeInsets.symmetric(horizontal: sw * 0.05, vertical: 18),
      decoration: BoxDecoration(
        color       : const Color(0xFF1C1C2E),
        borderRadius: BorderRadius.circular(20),
        boxShadow   : [BoxShadow(
            color     : Colors.black.withOpacity(0.5),
            blurRadius: 20,
            offset    : const Offset(0, -4))],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.white24,
                borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 16),
        Row(children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color : Colors.green.withOpacity(0.15),
              shape : BoxShape.circle,
              border: Border.all(
                  color: Colors.green.withOpacity(0.4), width: 2),
            ),
            child: const Icon(Icons.call_rounded,
                color: Colors.green, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Text(userName,
                style: const TextStyle(
                    color     : Colors.white,
                    fontSize  : 16,
                    fontWeight: FontWeight.bold),
                maxLines : 1,
                overflow : TextOverflow.ellipsis),
            const SizedBox(height: 3),
            Row(children: [
              const Icon(Icons.lock_outline,
                  color: Colors.orangeAccent, size: 13),
              const SizedBox(width: 4),
              Text('Incoming private audio call',
                  style: TextStyle(
                      color   : Colors.white.withOpacity(0.6),
                      fontSize: 12)),
            ]),
          ])),
        ]),
        const SizedBox(height: 18),
        Row(children: [
          Expanded(child: GestureDetector(
            onTap: onDecline,
            child: Container(
              height    : 48,
              decoration: BoxDecoration(
                color       : AppTheme.accentRed.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
                border      : Border.all(
                    color: AppTheme.accentRed.withOpacity(0.5)),
              ),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                Icon(Icons.call_end_rounded,
                    color: AppTheme.accentRed, size: 18),
                const SizedBox(width: 8),
                Text('Decline',
                    style: TextStyle(
                        color     : AppTheme.accentRed,
                        fontWeight: FontWeight.w600)),
              ]),
            ),
          )),
          SizedBox(width: sw * 0.03),
          Expanded(child: GestureDetector(
            onTap: onAccept,
            child: Container(
              height    : 48,
              decoration: BoxDecoration(
                color       : Colors.green,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                Icon(Icons.call_rounded, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text('Accept',
                    style: TextStyle(
                        color     : Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize  : 15)),
              ]),
            ),
          )),
        ]),
        const SizedBox(height: 6),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  PRIVATE CALL BADGE
// ══════════════════════════════════════════════════════════════════════════════
class _PrivateCallBadge extends StatelessWidget {
  final double sw;
  final String userName;
  final bool   micMuted;
  final String callDuration;
  final VoidCallback onMicTap;
  final VoidCallback onEndTap;

  const _PrivateCallBadge({
    required this.sw,
    required this.userName,
    required this.micMuted,
    required this.callDuration,
    required this.onMicTap,
    required this.onEndTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding   : EdgeInsets.symmetric(
          horizontal: sw * 0.03, vertical: sw * 0.018),
      decoration: BoxDecoration(
        color       : Colors.black.withOpacity(0.70),
        borderRadius: BorderRadius.circular(16),
        border      : Border.all(
            color: AppTheme.primaryYellow.withOpacity(0.4), width: 1),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: sw * 0.07, height: sw * 0.07,
          decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.2),
              shape: BoxShape.circle),
          child: const Icon(Icons.call_rounded,
              color: Colors.green, size: 16),
        ),
        SizedBox(width: sw * 0.025),
        Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize      : MainAxisSize.min,
            children: [
          Text(userName,
              style: TextStyle(
                  color     : Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize  : sw * 0.028)),
          Row(children: [
            const Icon(Icons.lock_outline,
                color: Colors.orangeAccent, size: 11),
            const SizedBox(width: 4),
            Text(callDuration,
                style: TextStyle(
                    color     : AppTheme.primaryYellow,
                    fontWeight: FontWeight.bold,
                    fontSize  : sw * 0.026)),
          ]),
        ]),
        SizedBox(width: sw * 0.03),
        GestureDetector(
          onTap: onMicTap,
          child: Container(
            padding   : const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: micMuted
                  ? AppTheme.accentRed.withOpacity(0.2)
                  : Colors.white12,
              shape: BoxShape.circle,
            ),
            child: Icon(
              micMuted ? Icons.mic_off : Icons.mic,
              color: micMuted ? AppTheme.accentRed : Colors.white,
              size : sw * 0.04,
            ),
          ),
        ),
        SizedBox(width: sw * 0.02),
        GestureDetector(
          onTap: onEndTap,
          child: Container(
            padding   : const EdgeInsets.all(6),
            decoration: BoxDecoration(
                color: AppTheme.accentRed.withOpacity(0.2),
                shape: BoxShape.circle),
            child: Icon(Icons.call_end_rounded,
                color: AppTheme.accentRed, size: sw * 0.04),
          ),
        ),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  SUB WIDGETS
// ══════════════════════════════════════════════════════════════════════════════
class _LiveBadge extends StatelessWidget {
  final double sw;
  const _LiveBadge({required this.sw});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding   : EdgeInsets.symmetric(horizontal: sw * 0.025, vertical: 4),
      decoration: BoxDecoration(
        color       : AppTheme.accentRed,
        borderRadius: BorderRadius.circular(20),
        boxShadow   : [BoxShadow(
            color     : AppTheme.accentRed.withOpacity(0.5),
            blurRadius: 8,
            spreadRadius: 1)],
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.circle, color: Colors.white, size: 7),
        SizedBox(width: sw * 0.01),
        Text('LIVE',
            style: TextStyle(
                color      : Colors.white,
                fontSize   : sw * 0.028,
                fontWeight : FontWeight.bold,
                letterSpacing: 1)),
      ]),
    );
  }
}

class _ViewerBadge extends StatelessWidget {
  final int count; final double sw;
  const _ViewerBadge({required this.count, required this.sw});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding   : EdgeInsets.symmetric(horizontal: sw * 0.025, vertical: 4),
      decoration: BoxDecoration(
        color : Colors.black54,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.remove_red_eye_outlined,
            color: Colors.white70, size: sw * 0.038),
        SizedBox(width: sw * 0.012),
        Text('$count',
            style: TextStyle(
                color     : Colors.white,
                fontSize  : sw * 0.032,
                fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final String name, message;
  final bool   isMe, isSystem;
  final double sw, fontSize;
  const _ChatBubble({
    required this.name,
    required this.message,
    required this.isMe,
    required this.isSystem,
    required this.sw,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    if (isSystem) {
      return Center(child: Container(
        padding   : EdgeInsets.symmetric(
            horizontal: sw * 0.03, vertical: 3),
        decoration: BoxDecoration(
            color       : Colors.black45,
            borderRadius: BorderRadius.circular(20)),
        child: Text(message,
            style: TextStyle(
                color   : Colors.white54,
                fontSize: fontSize * 0.9)),
      ));
    }
    return Container(
      padding   : EdgeInsets.symmetric(
          horizontal: sw * 0.03, vertical: sw * 0.012),
      decoration: BoxDecoration(
          color       : Colors.black.withOpacity(0.45),
          borderRadius: BorderRadius.circular(20)),
      child: RichText(text: TextSpan(children: [
        TextSpan(
            text : '$name  ',
            style: TextStyle(
                color     : isMe
                    ? AppTheme.primaryYellow
                    : Colors.lightBlueAccent,
                fontSize  : fontSize,
                fontWeight: FontWeight.bold)),
        TextSpan(
            text : message,
            style: TextStyle(
                color   : Colors.white,
                fontSize: sw * 0.031)),
      ])),
    );
  }
}

class _ChatInput extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode             focusNode;
  final VoidCallback          onSend;
  final double sw, sh;
  const _ChatInput({
    required this.controller,
    required this.focusNode,
    required this.onSend,
    required this.sw,
    required this.sh,
  });

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(child: Container(
        height   : sh * 0.052,
        padding  : EdgeInsets.symmetric(horizontal: sw * 0.04),
        decoration: BoxDecoration(
          color       : Colors.black.withOpacity(0.60),
          borderRadius: BorderRadius.circular(30),
          border      : Border.all(color: Colors.white24),
        ),
        child: TextField(
          controller: controller,
          focusNode : focusNode,
          style     : TextStyle(
              color: Colors.white, fontSize: sw * 0.034),
          decoration: InputDecoration(
            hintText      : 'Say something...',
            hintStyle     : TextStyle(
                color   : Colors.white38,
                fontSize: sw * 0.032),
            border        : InputBorder.none,
            isDense       : true,
            contentPadding: EdgeInsets.symmetric(
                vertical: sh * 0.014),
          ),
          onSubmitted: (_) => onSend(),
        ),
      )),
      SizedBox(width: sw * 0.025),
      GestureDetector(
        onTap: onSend,
        child: Container(
          width     : sh * 0.052,
          height    : sh * 0.052,
          decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.primaryYellow),
          child: Icon(Icons.send_rounded,
              color: Colors.black, size: sw * 0.045),
        ),
      ),
    ]);
  }
}

class _ControlButton extends StatelessWidget {
  final String    svgPath;
  final bool      active;
  final VoidCallback? onTap;
  final double    size;
  const _ControlButton({
    required this.svgPath,
    required this.active,
    required this.onTap,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration : const Duration(milliseconds: 200),
        width    : size,
        height   : size,
        padding  : EdgeInsets.all(size * 0.22),
        decoration: BoxDecoration(
          shape    : BoxShape.circle,
          color    : active ? Colors.white : AppTheme.accentRed,
          boxShadow: [BoxShadow(
            color     : (active ? Colors.white : AppTheme.accentRed)
                .withOpacity(0.25),
            blurRadius: 8,
            offset    : const Offset(0, 3),
          )],
        ),
        child: SvgPicture.asset(svgPath,
            colorFilter: ColorFilter.mode(
                active ? Colors.black : Colors.white,
                BlendMode.srcIn)),
      ),
    );
  }
}