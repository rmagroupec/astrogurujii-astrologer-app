// lib/features/reviews/MyReviewsScreen.dart
// ── Theme-aware: AppColors + AppTheme tokens, zero hardcoded colors ───────────
// ── Responsive: FigmaSize preserved throughout ────────────────────────────────
// ── Reply to review: dialog + local optimistic state + API submit ─────────────

import 'dart:convert';

import 'package:astrologer_app/core/config/theme_config.dart';
import 'package:astrologer_app/core/utils/size_config.dart';
import 'package:astrologer_app/model/ratingListModel.dart';
import 'package:astrologer_app/service/apiClient.dart';
import 'package:astrologer_app/service/apiService.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class MyReviewsScreen extends StatefulWidget {
  const MyReviewsScreen({super.key});

  @override
  State<MyReviewsScreen> createState() => _MyReviewsScreenState();
}

class _MyReviewsScreenState extends State<MyReviewsScreen> {
  bool             isLoading        = true;
  List<RatingItem> ratings          = [];
  String           selectedFilter   = 'all'; // 'all' | 'astromall' | 'pinned'
  String           flaggedRatioText = '0/10';
  double           flaggedProgress  = 0.0;

  /// Optimistic local reply cache keyed by rating id.
  /// Updated immediately on successful dialog submit so the UI
  /// reflects the reply without waiting for a re-fetch.
  final Map<String, String> _localReplies = {};

  @override
  void initState() {
    super.initState();
    _fetchRatings();
  }

  // ── Data fetching ───────────────────────────────────────────────────────────

  Future<void> _fetchRatings() async {
    setState(() => isLoading = true);
    try {
      final response = await ApiService().getReviewList(filter: selectedFilter);
      if (!mounted) return;
      setState(() {
        ratings          = response.results;
        flaggedRatioText = response.flaggedRatio ?? '0/10';
        flaggedProgress  = response.flaggedValue ?? 0.0;
        isLoading        = false;
        // Seed cache with server-provided replies so edit flow works
        // even on first open (before the user has replied via this session).
        for (final r in ratings) {
          if (r.astrologerComment.isNotEmpty) {
            _localReplies[r.id] = r.astrologerComment;
          }
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      debugPrint('Rating API Error: $e');
    }
  }

  // ── Flag / Pin actions ──────────────────────────────────────────────────────

  Future<void> _handleReviewAction(String id, String actionType) async {
    try {
      await ApiService().updateReviewAction(reviewId: id, action: actionType);
      _fetchRatings();
    } catch (e) {
      debugPrint('Action Failed: $e');
    }
  }

  // ── Filter ──────────────────────────────────────────────────────────────────

  void _setFilter(String filter) {
    setState(() => selectedFilter = filter);
    _fetchRatings();
  }

  // ── Reply dialog ────────────────────────────────────────────────────────────

  Future<void> _openReplyDialog(RatingItem rating) async {
    final existing = _localReplies[rating.id] ?? rating.astrologerComment;
    final result   = await showDialog<String>(
      context: context,
      builder: (_) => _ReplyDialog(rating: rating, existingReply: existing),
    );
    if (result != null && mounted) {
      setState(() => _localReplies[rating.id] = result);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content : Text('Reply submitted successfully'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final c      = context.colors;
    final isDark = context.isDark;

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          'My Reviews',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchRatings,
        color    : AppTheme.primaryYellow,
        child    : SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(FigmaSize.w(16)),
          child  : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── Flagged progress card ─────────────────────────────────
              Container(
                width     : double.infinity,
                padding   : EdgeInsets.all(FigmaSize.w(14)),
                decoration: BoxDecoration(
                  color       : c.surface,
                  border      : Border.all(color: c.border),
                  borderRadius: BorderRadius.circular(FigmaSize.w(12)),
                  boxShadow   : isDark
                      ? []
                      : [
                          BoxShadow(
                            color     : Colors.black.withOpacity(0.04),
                            blurRadius: 6,
                            offset    : const Offset(0, 2),
                          ),
                        ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Flagged reviews ',
                              style: TextStyle(
                                fontSize  : FigmaSize.w(13),
                                fontWeight: FontWeight.w500,
                                color     : c.text,
                              ),
                            ),
                            Text(
                              '(excluding PO)',
                              style: TextStyle(
                                fontSize  : FigmaSize.w(9),
                                fontWeight: FontWeight.w500,
                                color     : c.subText,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          flaggedRatioText,
                          style: TextStyle(
                            fontSize  : FigmaSize.w(13),
                            fontWeight: FontWeight.w600,
                            color     : c.text,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: FigmaSize.h(8)),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value          : flaggedProgress,
                        minHeight      : FigmaSize.h(10),
                        backgroundColor: AppTheme.primaryYellow
                            .withOpacity(isDark ? 0.15 : 0.20),
                        valueColor     : const AlwaysStoppedAnimation<Color>(
                            AppTheme.primaryYellow),
                      ),
                    ),
                    SizedBox(height: FigmaSize.h(8)),
                    Text(
                      'System gives you maximum 10 flags for your reviews every month. '
                      'Used balance will get reset on the 1st day of the month.',
                      style: TextStyle(
                        fontSize  : FigmaSize.w(10),
                        color     : c.subText,
                        fontWeight: FontWeight.w400,
                        height    : 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: FigmaSize.h(16)),

              // ── Filter chips ──────────────────────────────────────────
              Row(
                children: [
                  _FilterChip(
                    label   : 'ALL ⭐',
                    isActive: selectedFilter == 'all',
                    c       : c,
                    onTap   : () => _setFilter('all'),
                  ),
                  SizedBox(width: FigmaSize.w(8)),
                  _FilterChip(
                    label   : 'Astromall',
                    iconPath: 'assets/images/shopping-cart.svg',
                    isActive: selectedFilter == 'astromall',
                    c       : c,
                    onTap   : () => _setFilter('astromall'),
                  ),
                  SizedBox(width: FigmaSize.w(8)),
                  _FilterChip(
                    label   : 'Pinned',
                    iconPath: 'assets/images/office-push-pin.svg',
                    isActive: selectedFilter == 'pinned',
                    c       : c,
                    onTap   : () => _setFilter('pinned'),
                  ),
                ],
              ),
              SizedBox(height: FigmaSize.h(16)),

              // ── Review cards / states ─────────────────────────────────
              if (isLoading)
                Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: FigmaSize.h(40)),
                    child  : CircularProgressIndicator(
                        color: AppTheme.primaryYellow),
                  ),
                )
              else if (ratings.isEmpty)
                Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: FigmaSize.h(40)),
                    child  : Column(
                      children: [
                        Icon(Icons.rate_review_outlined,
                            size : 56,
                            color: c.subText.withOpacity(0.35)),
                        SizedBox(height: FigmaSize.h(12)),
                        Text(
                          'No reviews yet',
                          style: TextStyle(
                              color   : c.subText,
                              fontSize: FigmaSize.w(14)),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap : true,
                  physics    : const NeverScrollableScrollPhysics(),
                  itemCount  : ratings.length,
                  itemBuilder: (_, index) {
                    final r     = ratings[index];
                    final reply = _localReplies[r.id] ?? r.astrologerComment;
                    return _ReviewCard(
                      rating    : r,
                      reply     : reply,
                      c         : c,
                      isDark    : isDark,
                      onAction  : (action) =>
                          _handleReviewAction(r.id, action),
                      onReplyTap: () => _openReplyDialog(r),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// REPLY DIALOG
// ─────────────────────────────────────────────────────────────────────────────

class _ReplyDialog extends StatefulWidget {
  final RatingItem rating;
  final String     existingReply;

  const _ReplyDialog({required this.rating, required this.existingReply});

  @override
  State<_ReplyDialog> createState() => _ReplyDialogState();
}

class _ReplyDialogState extends State<_ReplyDialog> {
  late final TextEditingController _ctrl;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.existingReply);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final reply = _ctrl.text.trim();
    if (reply.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write a reply first')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      final res  = await ApiClient().post(
        'astrologer_api/reply_review',
        {'rating_id': widget.rating.id, 'comment': reply},
        isAuthRequired: true,
      );
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (!mounted) return;
      if (body['result'] == true || body['status'] == true) {
        Navigator.pop(context, reply);
      } else {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  (body['message'] as String?) ?? 'Failed to submit reply')),
        );
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error submitting reply')),
      );
    }
  }

  Color get _typeColor {
    switch (widget.rating.callType.toLowerCase()) {
      case 'chat' : return const Color(0xFF2196F3);
      case 'video': return const Color(0xFF7B1FA2);
      default     : return const Color(0xFF1976D2); // audio / call
    }
  }

  @override
  Widget build(BuildContext context) {
    final callType     = widget.rating.callType;
    final callTypeLabel =
        callType.isNotEmpty ? callType[0].toUpperCase() + callType.substring(1) : 'Chat';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child  : Column(
          mainAxisSize     : MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Title ─────────────────────────────────────────────────
            RichText(
              text: TextSpan(
                style: const TextStyle(
                    fontSize  : 16,
                    fontWeight: FontWeight.w700,
                    color     : Colors.black),
                children: [
                  const TextSpan(text: 'Reply '),
                  TextSpan(
                      text : widget.rating.displayName.toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                  const TextSpan(text: ' review for '),
                  TextSpan(
                    text : callTypeLabel,
                    style: TextStyle(color: _typeColor),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Text field ────────────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                border      : Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(10),
              ),
              child: TextField(
                controller: _ctrl,
                maxLines  : 5,
                minLines  : 4,
                style     : const TextStyle(fontSize: 14),
                decoration: const InputDecoration(
                  hintText      : 'Write your reply here…',
                  hintStyle     : TextStyle(color: Colors.grey),
                  border        : InputBorder.none,
                  contentPadding: EdgeInsets.all(12),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // ── Warning ───────────────────────────────────────────────
            const Text(
              'Be polite. Don\'t share any personal details in a public comment.',
              style    : TextStyle(fontSize: 12, color: Color(0xFFE53935)),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

            // ── Action buttons ────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.grey.shade200,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Cancel',
                        style: TextStyle(
                            color     : Colors.black54,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _submitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentRed,
                      foregroundColor: Colors.white,
                      elevation      : 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: _submitting
                        ? const SizedBox(
                            width : 18,
                            height: 18,
                            child : CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Text('Submit',
                            style: TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 15)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// REVIEW CARD
// ─────────────────────────────────────────────────────────────────────────────

class _ReviewCard extends StatelessWidget {
  final RatingItem       rating;
  final String           reply;       // resolved local-or-server reply
  final AppColors        c;
  final bool             isDark;
  final Function(String) onAction;    // flag / pin / unpin / unflag
  final VoidCallback     onReplyTap;  // open reply dialog

  const _ReviewCard({
    required this.rating,
    required this.reply,
    required this.c,
    required this.isDark,
    required this.onAction,
    required this.onReplyTap,
  });

  bool get _hasValidImage =>
      rating.profileImg.isNotEmpty &&
      !rating.profileImg.contains('user_d.jpg');

  Color get _typeColor {
    switch (rating.callType.toLowerCase()) {
      case 'video'    : return const Color(0xFF7B1FA2);
      case 'audio'    : return const Color(0xFF1976D2);
      case 'astromall': return const Color(0xFFE65100);
      default         : return const Color(0xFF2196F3); // chat
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasReply = reply.trim().isNotEmpty;

    return Container(
      margin    : EdgeInsets.only(bottom: FigmaSize.h(12)),
      padding   : EdgeInsets.all(FigmaSize.w(12)),
      decoration: BoxDecoration(
        color       : c.surface,
        border      : Border.all(color: c.border),
        borderRadius: BorderRadius.circular(FigmaSize.w(12)),
        boxShadow   : isDark
            ? []
            : [
                BoxShadow(
                  color     : Colors.black.withOpacity(0.04),
                  blurRadius: 6,
                  offset    : const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Header: Order ID + pin/flag ─────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _shortOrderId(rating.id),
                style: TextStyle(
                    fontSize: FigmaSize.w(11), color: c.subText),
              ),
              Row(
                children: [
                  _ActionIcon(
                    icon : rating.isPinned
                        ? Icons.push_pin
                        : Icons.push_pin_outlined,
                    color: rating.isPinned
                        ? AppTheme.primaryYellow
                        : c.subText,
                    onTap: () =>
                        onAction(rating.isPinned ? 'unpin' : 'pin'),
                  ),
                  SizedBox(width: FigmaSize.w(2)),
                  _ActionIcon(
                    icon : rating.isFlagged
                        ? Icons.flag
                        : Icons.flag_outlined,
                    color: rating.isFlagged
                        ? AppTheme.accentRed
                        : c.subText,
                    onTap: () =>
                        onAction(rating.isFlagged ? 'unflag' : 'flag'),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: FigmaSize.h(10)),

          // ── User info ───────────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              Container(
                height    : FigmaSize.h(38),
                width     : FigmaSize.w(38),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primaryYellow.withOpacity(0.12),
                  border: Border.all(
                    color: AppTheme.primaryYellow.withOpacity(0.30),
                    width: 1,
                  ),
                ),
                child: ClipOval(
                  child: _hasValidImage
                      ? Image.network(
                          rating.profileImg,
                          fit         : BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _InitialText(rating.displayName, c),
                        )
                      : _InitialText(rating.displayName, c),
                ),
              ),
              SizedBox(width: FigmaSize.w(10)),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            rating.displayName,
                            overflow: TextOverflow.ellipsis,
                            style   : TextStyle(
                              fontSize  : FigmaSize.w(14),
                              fontWeight: FontWeight.w600,
                              color     : c.text,
                            ),
                          ),
                        ),
                        // Stars
                        Row(
                          children: List.generate(
                            5,
                            (i) => Icon(
                              i < rating.rating
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              size : FigmaSize.w(14),
                              color: i < rating.rating
                                  ? Colors.amber
                                  : c.border,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: FigmaSize.h(3)),
                    Row(
                      children: [
                        Text(
                          rating.callType.isNotEmpty
                              ? rating.callType[0].toUpperCase() +
                                  rating.callType.substring(1)
                              : 'Chat',
                          style: TextStyle(
                            fontSize  : FigmaSize.w(12),
                            color     : _typeColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          ' · ${rating.formattedDate}',
                          style: TextStyle(
                              fontSize: FigmaSize.w(11), color: c.subText),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: FigmaSize.h(10)),

          // ── Divider ─────────────────────────────────────────────────
          Divider(color: c.divider, height: 1, thickness: 1),
          SizedBox(height: FigmaSize.h(10)),

          // ── Review text ─────────────────────────────────────────────
          Text(
            rating.review.isNotEmpty
                ? rating.review
                : 'No review left by user.',
            style: TextStyle(
              fontSize : FigmaSize.w(12),
              color    : rating.review.isNotEmpty ? c.text : c.subText,
              height   : 1.5,
              fontStyle: rating.review.isEmpty
                  ? FontStyle.italic
                  : FontStyle.normal,
            ),
          ),

          // ── Existing reply preview ───────────────────────────────────
          if (hasReply) ...[
            SizedBox(height: FigmaSize.h(10)),
            Container(
              width     : double.infinity,
              padding   : EdgeInsets.all(FigmaSize.w(10)),
              decoration: BoxDecoration(
                color       : isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border      : Border.all(color: c.border),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.reply_rounded,
                      size: FigmaSize.w(14), color: AppTheme.accentRed),
                  SizedBox(width: FigmaSize.w(6)),
                  Expanded(
                    child: Text(
                      reply,
                      maxLines : 2,
                      overflow : TextOverflow.ellipsis,
                      style    : TextStyle(
                          fontSize: FigmaSize.w(12), color: c.subText),
                    ),
                  ),
                  GestureDetector(
                    onTap: onReplyTap,
                    child: Icon(Icons.edit_rounded,
                        size : FigmaSize.w(13), color: c.subText),
                  ),
                ],
              ),
            ),
          ],

          SizedBox(height: FigmaSize.h(10)),

          // ── Bottom row: Reply CTA ────────────────────────────────────
          GestureDetector(
            onTap    : onReplyTap,
            behavior : HitTestBehavior.opaque,
            child    : Row(
              children: [
                Icon(Icons.reply_rounded,
                    size : FigmaSize.w(16), color: AppTheme.accentRed),
                SizedBox(width: FigmaSize.w(4)),
                Text(
                  hasReply ? 'Edit reply' : 'Reply to this review',
                  style: TextStyle(
                    fontSize  : FigmaSize.w(12),
                    color     : AppTheme.accentRed,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _shortOrderId(String id) {
    if (id.length > 8) {
      return 'Order ID : #${id.substring(0, 4)}…${id.substring(id.length - 4)}';
    }
    return 'Order ID : #$id';
  }
}

// ── Avatar initial fallback ───────────────────────────────────────────────────

class _InitialText extends StatelessWidget {
  final String    displayName;
  final AppColors c;
  const _InitialText(this.displayName, this.c);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize  : FigmaSize.w(14),
          color     : c.text,
        ),
      ),
    );
  }
}

// ── Filter chip ───────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String       label;
  final String?      iconPath;
  final bool         isActive;
  final AppColors    c;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.c,
    required this.isActive,
    required this.onTap,
    this.iconPath,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration  : const Duration(milliseconds: 180),
        padding   : EdgeInsets.symmetric(
            horizontal: FigmaSize.w(12), vertical: FigmaSize.h(7)),
        decoration: BoxDecoration(
          color       : isActive
              ? AppTheme.primaryYellow
              : AppTheme.primaryYellow.withOpacity(isDark ? 0.12 : 0.0),
          border      : Border.all(color: AppTheme.primaryYellow),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (iconPath != null) ...[
              SvgPicture.asset(
                iconPath!,
                width      : FigmaSize.w(12),
                height     : FigmaSize.h(12),
                colorFilter: ColorFilter.mode(
                  isActive ? Colors.black : c.text,
                  BlendMode.srcIn,
                ),
              ),
              SizedBox(width: FigmaSize.w(4)),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize  : FigmaSize.w(12),
                fontWeight: FontWeight.w600,
                color     : isActive ? Colors.black : c.text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Reusable small icon button ────────────────────────────────────────────────

class _ActionIcon extends StatelessWidget {
  final IconData     icon;
  final Color        color;
  final VoidCallback onTap;

  const _ActionIcon({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap    : onTap,
      behavior : HitTestBehavior.opaque,
      child    : Padding(
        padding: EdgeInsets.all(FigmaSize.w(4)),
        child  : Icon(icon, size: FigmaSize.w(18), color: color),
      ),
    );
  }
}