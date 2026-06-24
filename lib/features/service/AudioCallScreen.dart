// lib/features/service/AudioCallScreen.dart
// ── UI redesigned to match images ─────────────────────────────────────────────
// ── Theme-aware: light/dark via AppColors ─────────────────────────────────────
// ── Zero functional changes ───────────────────────────────────────────────────

import 'package:astrologer_app/core/config/theme_config.dart';
import 'package:astrologer_app/features/service/provider/audio_call_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:astrologer_app/MainNavScreen.dart';

class AudioCallScreen extends StatefulWidget {
  final String channelId;
  final String token;
  final String callerName;
  final String callerImage;
  final bool   resumed;

  // Extra user info for info panel (all optional — empty string = not shown)
  final String userName;
  final String userId;
  final String gender;
  final String dob;
  final String pob;
  final String remainingTime;

  const AudioCallScreen({
    super.key,
    required this.channelId,
    required this.token,
    this.callerName    = 'User',
    this.callerImage   = '',
    this.resumed       = false,
    this.userName      = '',
    this.userId        = '',
    this.gender        = '',
    this.dob           = '',
    this.pob           = '',
    this.remainingTime = '',
  });

  @override
  State<AudioCallScreen> createState() => _AudioCallScreenState();
}

class _AudioCallScreenState extends State<AudioCallScreen>
    with SingleTickerProviderStateMixin {

  bool _initDone     = false;
  bool _endShown     = false;
  bool _endScheduled = false;
  bool _showInfo     = false;

  late AnimationController _waveCtrl;

  static const _gold       = Color(0xFFE6A817);
  static const _bgLight    = Color(0xFFF5EBD8);
  static const _cardLight  = Color(0xFFEDE3D5);
  static const _darkText   = Color(0xFF2C2C2C);
  static const _red        = Color(0xFFD41000);

  @override
  void initState() {
    super.initState();
    _waveCtrl = AnimationController(
      vsync   : this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }
@override
void didChangeDependencies() {
  super.didChangeDependencies();
  if (_initDone) return;
  _initDone = true;

  final provider = context.read<AudioCallProvider>();
  if (widget.resumed) {
    provider.expand();
    provider.rewireCallback(
      onEnded: (reason) { debugPrint('📞 [resumed] onEnded: $reason'); _doEnd(); },
    );
    // ✅ Re-sync Firebase timer on resume
    if (provider.channelId.isNotEmpty) {
      provider.listenCallSession(provider.channelId);
    }
  } else {
    provider.init(
      channelId : widget.channelId,
      token     : widget.token,
      name      : widget.callerName,
      image     : widget.callerImage,
      onEnded   : (reason) { debugPrint('📞 onEnded: $reason'); _doEnd(); },
    );
  }
}
  @override
  void dispose() {
    _waveCtrl.dispose();
    super.dispose();
  }

  void _minimize() {
    if (_endShown) return;
    context.read<AudioCallProvider>().minimize();
    Navigator.of(context).pop();
  }

  void _onEndPressed() {
    if (_endShown) return;
    final c = context.colors;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: c.surface,
        shape  : RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title  : Text('End Call',
            style: TextStyle(fontWeight: FontWeight.bold, color: c.text)),
        content: Text('Are you sure you want to end this call?',
            style: TextStyle(color: c.subText)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: c.subText)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () { Navigator.pop(context); _doEnd(); },
            child: const Text('End', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _doEnd() async {
    if (_endShown || !mounted) return;
    _endShown = true;
    if (_waveCtrl.isAnimating) _waveCtrl.stop();

    final provider = context.read<AudioCallProvider>();
    await provider.end();
    if (!mounted) return;

    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    await showModalBottomSheet(
      context           : context,
      isDismissible     : false,
      enableDrag        : false,
      isScrollControlled: true,
      backgroundColor   : Colors.transparent,
      builder           : (_) => _RatingSheet(
        callerName : widget.callerName,
        callerImage: widget.callerImage,
        duration   : provider.duration,
        onDone: (_) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c           = context.colors;
    final isDark      = context.isDark;
    final provider    = context.watch<AudioCallProvider>();
    final isConnected = provider.remoteJoined;

    if (provider.isEnded && !_endShown && !_endScheduled) {
      _endScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _doEnd());
    }
    if (isConnected && _waveCtrl.isAnimating)              _waveCtrl.stop();
    else if (!isConnected && !_endShown && !_waveCtrl.isAnimating) _waveCtrl.repeat();

    final displayName = widget.userName.isNotEmpty ? widget.userName : widget.callerName;

    return WillPopScope(
      onWillPop: () async {
        
        Navigator.push(context,
                      MaterialPageRoute(
                          builder: (_) =>  MainNavScreen()));
         return false; },
      child: Scaffold(
        backgroundColor: isDark ? c.bg : _bgLight,
        body: SafeArea(
          child: Column(
            children: [

              // ── Top bar ─────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: (){
                        Navigator.push(context,
                      MaterialPageRoute(
                          builder: (_) =>  MainNavScreen()));
                      },
                      child: Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDark
                              ? c.toggleBg
                              : Colors.black.withOpacity(0.08),
                        ),
                        child: Icon(Icons.arrow_back_ios_new,
                            color: isDark ? Colors.white : _darkText,
                            size: 16),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text(displayName,
                              style: TextStyle(
                                  fontSize  : 16,
                                  fontWeight: FontWeight.w700,
                                  color     : isDark ? Colors.white : _darkText)),
                          isConnected
    ? (provider.isTimerReady
        ? Text(
            provider.duration,
            style: TextStyle(
                fontSize: 13,
                color   : Colors.green.shade700),
          )
        : Row(mainAxisSize: MainAxisSize.min, children: [
            SizedBox(
              width: 10, height: 10,
              child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color      : Colors.grey.shade500),
            ),
            const SizedBox(width: 5),
            Text('Syncing…',
                style: TextStyle(
                    fontSize: 11,
                    color   : Colors.grey.shade500)),
          ]))
    : Text(
        'Connecting…',
        style: TextStyle(
            fontSize: 13,
            color   : Colors.grey.shade500),
      ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _showInfo = !_showInfo),
                      child: Container(
                        width : 36, height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _showInfo
                              ? _gold
                              : _gold.withOpacity(0.20),
                        ),
                        child: Icon(Icons.info_outline,
                            color: _showInfo ? Colors.white : _gold,
                            size: 20),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Main content ─────────────────────────────────────────────
              Expanded(
                child: _showInfo && isConnected
                    ? _InfoPanel(
                        image        : widget.callerImage,
                        displayName  : displayName,
                        userId       : widget.userId,
                        gender       : widget.gender,
                        dob          : widget.dob,
                        pob          : widget.pob,
                        remainingTime: widget.remainingTime.isNotEmpty
                            ? widget.remainingTime
                            : provider.duration,
                        isDark       : isDark,
                        c            : c,
                      )
                    : _AvatarCard(
                        image      : widget.callerImage,
                        name       : displayName,
                        isConnected: isConnected,
                        waveCtrl   : _waveCtrl,
                        isDark     : isDark,
                      ),
              ),

              // ── Controls ─────────────────────────────────────────────────
              Container(
                margin : const EdgeInsets.fromLTRB(16, 0, 16, 0),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color       : isDark ? c.surface : _cardLight,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _CtrlBtn(
                      icon  : provider.speakerOn
                          ? Icons.volume_up_rounded
                          : Icons.volume_off_rounded,
                      label : provider.speakerOn ? 'Speaker' : 'Earpiece',
                      active: provider.speakerOn,
                      onTap : () => provider.toggleSpeaker(),
                      isDark: isDark,
                      c     : c,
                    ),
                    GestureDetector(
                      onTap: _onEndPressed,
                      child: Container(
                        width : 58, height: 58,
                        decoration: BoxDecoration(
                          shape    : BoxShape.circle,
                          color    : Colors.red.shade600,
                          boxShadow: [
                            BoxShadow(
                              color     : Colors.red.withOpacity(0.35),
                              blurRadius: 14,
                              offset    : const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.call_end_rounded,
                            color: Colors.white, size: 28),
                      ),
                    ),
                    _CtrlBtn(
                      icon  : provider.muted
                          ? Icons.mic_off_rounded
                          : Icons.mic_rounded,
                      label : provider.muted ? 'Unmute' : 'Mute',
                      active: provider.muted,
                      onTap : () => provider.toggleMute(),
                      isDark: isDark,
                      c     : c,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Avatar card ───────────────────────────────────────────────────────────────
class _AvatarCard extends StatelessWidget {
  final String              image;
  final String              name;
  final bool                isConnected;
  final AnimationController waveCtrl;
  final bool                isDark;

  static const _gold = Color(0xFFE6A817);

  const _AvatarCard({
    required this.image,
    required this.name,
    required this.isConnected,
    required this.waveCtrl,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedBuilder(
        animation: waveCtrl,
        builder: (_, child) {
          final scale = !isConnected
              ? 1.0 + 0.04 * (0.5 - (waveCtrl.value - 0.5).abs())
              : 1.0;
          return Transform.scale(scale: scale, child: child);
        },
        child: Container(
          width : 200, height: 200,
          decoration: BoxDecoration(
            shape : BoxShape.circle,
            border: Border.all(color: _gold, width: 4),
            color : _gold.withOpacity(isDark ? 0.20 : 0.12),
          ),
          child: ClipOval(
            child: image.isNotEmpty
                ? Image.network(image, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _fallback())
                : _fallback(),
          ),
        ),
      ),
    );
  }

  Widget _fallback() => Container(
    color: _gold.withOpacity(0.15),
    child: const Icon(Icons.person, color: _gold, size: 80),
  );
}

// ── Info panel ────────────────────────────────────────────────────────────────
class _InfoPanel extends StatelessWidget {
  final String     image;
  final String     displayName;
  final String     userId;
  final String     gender;
  final String     dob;
  final String     pob;
  final String     remainingTime;
  final bool       isDark;
  final AppColors  c;

  static const _gold    = Color(0xFFE6A817);
  static const _darkText= Color(0xFF2C2C2C);
  static const _red     = Color(0xFFD41000);

  const _InfoPanel({
    required this.image,
    required this.displayName,
    required this.userId,
    required this.gender,
    required this.dob,
    required this.pob,
    required this.remainingTime,
    required this.isDark,
    required this.c,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [

          // Avatar
          Container(
            width : 110, height: 110,
            decoration: BoxDecoration(
              shape : BoxShape.circle,
              border: Border.all(color: _gold, width: 3),
            ),
            child: ClipOval(
              child: image.isNotEmpty
                  ? Image.network(image, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _fallback())
                  : _fallback(),
            ),
          ),

          const SizedBox(height: 10),

          // Remaining time
          Text(
            'Remaining time : $remainingTime',
            style: TextStyle(
                fontSize  : 14,
                fontWeight: FontWeight.w600,
                color     : isDark ? Colors.white : _darkText),
          ),

          const SizedBox(height: 12),

          // Info card
          Container(
            width  : double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color       : isDark
                  ? c.surface
                  : Colors.white.withOpacity(0.85),
              borderRadius: BorderRadius.circular(12),
              border      : Border.all(
                  color: isDark ? c.border : const Color(0xFFE0D8CC)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InfoRow(
                    label: 'Name',
                    value: '$displayName${userId.isNotEmpty ? " ($userId)" : ""}',
                    labelColor: _red,
                    c: c),
                _InfoRow(
                    label: 'Gender',
                    value: gender.isNotEmpty ? gender : '—',
                    labelColor: _red,
                    c: c),
                _InfoRow(
                    label: 'DOB',
                    value: dob.isNotEmpty ? dob : '—',
                    labelColor: _red,
                    c: c),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _InfoRow(
                          label: 'POB',
                          value: pob.isNotEmpty ? pob : '—',
                          labelColor: _red,
                          c: c),
                    ),
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: pob));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content : Text('Copied'),
                              duration: Duration(seconds: 1)));
                      },
                      child: const Padding(
                        padding: EdgeInsets.only(left: 8, top: 2),
                        child: Icon(Icons.copy_rounded,
                            size: 16, color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Suggest -Remedy',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Open Kundli',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Add / View Notes
          Row(
            children: [
              const Icon(Icons.note_alt_outlined, size: 16, color: _red),
              const SizedBox(width: 6),
              const Text('Add / View Notes',
                  style: TextStyle(
                      color     : _red,
                      fontSize  : 13,
                      fontWeight: FontWeight.w500)),
            ],
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _fallback() => Container(
    color: _gold.withOpacity(0.15),
    child: const Icon(Icons.person, color: _gold, size: 50),
  );
}

// ── Info row ──────────────────────────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final String     label;
  final String     value;
  final Color      labelColor;
  final AppColors  c;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.labelColor,
    required this.c,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: RichText(
        text: TextSpan(
          style: TextStyle(fontSize: 13, color: c.text),
          children: [
            TextSpan(
              text : '$label : ',
              style: TextStyle(
                  color     : labelColor,
                  fontWeight: FontWeight.w700),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}

// ── Control button ────────────────────────────────────────────────────────────
class _CtrlBtn extends StatelessWidget {
  final IconData     icon;
  final String       label;
  final bool         active;
  final VoidCallback onTap;
  final bool         isDark;
  final AppColors    c;

  const _CtrlBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.isDark,
    required this.c,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width : 52, height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark
                  ? c.toggleBg
                  : Colors.white.withOpacity(0.6),
            ),
            child: Icon(icon,
                color: active ? Colors.grey.shade700 : Colors.grey.shade500,
                size: 24),
          ),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  color   : isDark ? c.subText : const Color(0xFF555555))),
        ],
      ),
    );
  }
}

// ── Rating sheet ──────────────────────────────────────────────────────────────
class _RatingSheet extends StatefulWidget {
  final String callerName;
  final String callerImage;
  final String duration;
  final void Function(int) onDone;

  const _RatingSheet({
    required this.callerName,
    required this.callerImage,
    required this.duration,
    required this.onDone,
  });

  @override
  State<_RatingSheet> createState() => _RatingSheetState();
}

class _RatingSheetState extends State<_RatingSheet> {
  int  _rating     = 0;
  bool _submitting = false;
  final _ctrl      = TextEditingController();
  static const _labels = ['', 'Poor', 'Fair', 'Good', 'Very Good', 'Excellent'];

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Container(
      decoration: BoxDecoration(
        color       : c.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
          top   : 24, left: 24, right: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [

        Container(width: 40, height: 4,
            decoration: BoxDecoration(
                color      : c.border,
                borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 20),

        Container(
          padding   : const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color       : Colors.red.shade50,
            borderRadius: BorderRadius.circular(20),
            border      : Border.all(color: Colors.red.shade200),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.call_end, size: 14, color: Colors.red.shade400),
            const SizedBox(width: 6),
            Text('Call Ended',
                style: TextStyle(
                    color     : Colors.red.shade400,
                    fontWeight: FontWeight.w600,
                    fontSize  : 12)),
          ]),
        ),
        const SizedBox(height: 20),

        CircleAvatar(
          radius         : 40,
          backgroundColor: Colors.grey.shade200,
          backgroundImage: widget.callerImage.isNotEmpty
              ? NetworkImage(widget.callerImage) : null,
          child: widget.callerImage.isEmpty
              ? const Icon(Icons.person, size: 40, color: Colors.grey) : null,
        ),
        const SizedBox(height: 10),
        Text(widget.callerName,
            style: TextStyle(
                fontSize  : 18,
                fontWeight: FontWeight.bold,
                color     : c.text)),
        const SizedBox(height: 4),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.call, size: 13, color: Colors.grey),
          const SizedBox(width: 4),
          Text('Audio · ${widget.duration}',
              style: TextStyle(color: c.subText, fontSize: 13)),
        ]),

        const SizedBox(height: 20),
        Text('Rate Your Experience',
            style: TextStyle(
                fontSize  : 17,
                fontWeight: FontWeight.bold,
                color     : c.text)),
        const SizedBox(height: 12),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (i) {
            final star = i + 1;
            return GestureDetector(
              onTap: () => setState(() => _rating = star),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: Icon(
                  star <= _rating ? Icons.star : Icons.star_border,
                  color: const Color(0xFFE6A817), size: 38),
              ),
            );
          }),
        ),
        if (_rating > 0) ...[
          const SizedBox(height: 4),
          Text(_labels[_rating],
              style: const TextStyle(
                  color     : Color(0xFFE6A817),
                  fontWeight: FontWeight.w600)),
        ],
        const SizedBox(height: 16),

        TextField(
          controller: _ctrl,
          maxLines  : 3,
          style     : TextStyle(color: c.text),
          decoration: InputDecoration(
            hintText  : 'Leave a comment (optional)',
            hintStyle : TextStyle(color: c.subText),
            filled    : true,
            fillColor : c.toggleBg,
            border    : OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide  : BorderSide.none),
          ),
        ),
        const SizedBox(height: 20),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _submitting ? null : () async {
              if (_rating == 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Please select a star rating.')));
                return;
              }
              setState(() => _submitting = true);
              await Future.delayed(const Duration(milliseconds: 400));
              widget.onDone(_rating);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE6A817),
              foregroundColor: Colors.white,
              padding        : const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: _submitting
                ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Text('Submit Review',
                    style: TextStyle(
                        fontSize  : 16,
                        fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: () => widget.onDone(0),
          child: Text('Skip',
              style: TextStyle(color: c.subText, fontSize: 14)),
        ),
      ]),
    );
  }
}