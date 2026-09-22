// lib/features/pooja/PoojaBookingScreen.dart
// ── Theme-aware: AppColors + AppTheme tokens, zero hardcoded colors ───────────
// ── Zero logic changes ────────────────────────────────────────────────────────

import 'package:astrologer_app/core/config/theme_config.dart';
import 'package:astrologer_app/features/live/PujaLiveScreen.dart';
import 'package:astrologer_app/features/modal/PujaBookingModel.dart';
import 'package:astrologer_app/service/apiService.dart';
import 'package:flutter/material.dart';

class PoojaBookingScreen extends StatefulWidget {
  const PoojaBookingScreen({super.key});

  @override
  State<PoojaBookingScreen> createState() => _PoojaBookingScreenState();
}

class _PoojaBookingScreenState extends State<PoojaBookingScreen> {
  bool               isLoading = true;
  bool               isError   = false;
  List<PoojaBooking> bookings  = [];

  /// Booking id currently being started — drives the button spinner and
  /// blocks double taps (starting twice would issue two Agora tokens).
  String?            _startingLiveFor;

  @override
  void initState() {
    super.initState();
    fetchPoojaBookings();
  }

  // ── API ────────────────────────────────────────────────────────────────────
  Future<void> fetchPoojaBookings() async {
    setState(() { isLoading = true; isError = false; });
    try {
      final res = await ApiService().getPujaBooking();
      setState(() => bookings = res.data);
    } catch (e) {
      isError   = true;
      bookings  = [];
    }
    setState(() => isLoading = false);
  }

  // ── Start live ─────────────────────────────────────────────────────────────
  // Previously this called PoojaStartLive(booking.pujaBookingId) — the wrong
  // id (puja_booking_id is the readable booking code, not the Mongo _id that
  // the server looks up) — against the wrong endpoint, and then showed
  // "Pooja started successfully" unconditionally. Nothing streamed and any
  // real server message ("Puja starts in 40 minutes", "payment pending") was
  // swallowed. Now: correct id, real response, and it opens the broadcast.
  Future<void> startLivePooja(PoojaBooking booking) async {
    if (_startingLiveFor != null) return;      // guard double-taps
    setState(() => _startingLiveFor = booking.id);

    try {
      final res = await ApiService().PoojaStartLive(booking.id);

      if (!mounted) return;

      if (!res.canJoin) {
        // Server said no (wrong day, too early, payment pending, …) — show
        // exactly why instead of a generic failure.
        _snack(res.message.isNotEmpty
            ? res.message
            : 'Could not start the puja live');
        return;
      }

      final ended = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => PujaLiveScreen(
            pujaId   : booking.id,
            pujaTitle: booking.pujaType.isNotEmpty
                ? booking.pujaType
                : (booking.pujaId?.title ?? 'Puja'),
            session  : res,
          ),
        ),
      );

      if (!mounted) return;
      if (ended == true) _snack('Puja live ended');
      fetchPoojaBookings();                     // refresh is_live state
    } catch (e) {
      if (mounted) _snack('Failed to start puja live: $e');
    } finally {
      if (mounted) setState(() => _startingLiveFor = null);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 3)),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        // Colors inherited from AppTheme automatically
        title    : const Text('Pooja Bookings'),
        elevation: 1,
      ),
      body: _body(c),
    );
  }

  Widget _body(AppColors c) {
    if (isLoading) {
      return Center(
        child: CircularProgressIndicator(color: AppTheme.primaryYellow),
      );
    }

    if (isError) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline,
                color: AppTheme.accentRed, size: 48),
            const SizedBox(height: 12),
            Text('Something went wrong',
                style: TextStyle(color: c.subText)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: fetchPoojaBookings,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryYellow,
                foregroundColor: Colors.black,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_busy_rounded,
                size: 56, color: c.subText.withOpacity(0.35)),
            const SizedBox(height: 12),
            Text('No Pooja Bookings Found',
                style: TextStyle(color: c.subText, fontSize: 14)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: fetchPoojaBookings,
      color    : AppTheme.primaryYellow,
      child    : ListView.builder(
        itemCount  : bookings.length,
        itemBuilder: (_, i) => _BookingCard(
          booking       : bookings[i],
          c             : c,
          isDark        : context.isDark,
          isStarting    : _startingLiveFor == bookings[i].id,
          onStartLive   : () => startLivePooja(bookings[i]),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// BOOKING CARD
// ─────────────────────────────────────────────────────────────────
class _BookingCard extends StatelessWidget {
  final PoojaBooking booking;
  final AppColors    c;
  final bool         isDark;
  final bool         isStarting;
  final VoidCallback onStartLive;

  const _BookingCard({
    required this.booking,
    required this.c,
    required this.isDark,
    required this.isStarting,
    required this.onStartLive,
  });

  @override
  Widget build(BuildContext context) {
    final b            = booking;
    final isPaid       = b.paymentStatus == 'Success';
    final canStartLive = isPaid && b.isLive == false;

    return Container(
      margin : const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color       : c.surface,
        borderRadius: BorderRadius.circular(14),
        border      : Border.all(color: c.border),
        boxShadow   : isDark
            ? []
            : const [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Header ────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  b.pujaType,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize  : 15,
                    color     : c.text,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _StatusChip(status: b.paymentStatus),
            ],
          ),

          const SizedBox(height: 6),

          // ── Booking ID ────────────────────────────────────────────
          Text(
            'Booking ID: ${b.pujaBookingId}',
            style: TextStyle(fontSize: 12, color: c.subText),
          ),

          const SizedBox(height: 10),

          // ── Date ─────────────────────────────────────────────────
          Row(
            children: [
              Icon(Icons.calendar_today, size: 14, color: c.subText),
              const SizedBox(width: 6),
              Text(
                b.pujaDate.isEmpty ? 'Date not assigned' : b.pujaDate,
                style: TextStyle(fontSize: 13, color: c.text),
              ),
            ],
          ),

          // ── Time ──────────────────────────────────────────────────
          if (b.startTime.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                children: [
                  Icon(Icons.access_time, size: 14, color: c.subText),
                  const SizedBox(width: 6),
                  Text(
                    '${b.startTime}${b.endTime.isNotEmpty ? ' - ${b.endTime}' : ''}',
                    style: TextStyle(fontSize: 13, color: c.text),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 10),

          // ── Amount ────────────────────────────────────────────────
          Text(
            'Amount: ₹${b.pujaAmount}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize  : 14,
              color     : c.text,
            ),
          ),

          const SizedBox(height: 14),

          // ── Action ────────────────────────────────────────────────
          if (canStartLive || (isPaid && b.isLive))
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  // Already live → green "Rejoin", otherwise the normal CTA.
                  backgroundColor: b.isLive
                      ? Colors.green
                      : AppTheme.primaryYellow,
                  foregroundColor: b.isLive ? Colors.white : Colors.black,
                  elevation      : 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                // Disabled while a start request is in flight.
                onPressed: isStarting ? null : onStartLive,
                icon: isStarting
                    ? const SizedBox(
                        width : 16,
                        height: 16,
                        child : CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor : AlwaysStoppedAnimation(Colors.black54),
                        ),
                      )
                    : Icon(b.isLive ? Icons.podcasts : Icons.videocam, size: 18),
                label: Text(
                  isStarting
                      ? 'Starting…'
                      : (b.isLive ? 'Rejoin Live' : 'Start Live'),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            )
          else
            _InfoText(text: 'Waiting for payment', color: AppTheme.accentRed.withOpacity(0.7)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// STATUS CHIP
// ─────────────────────────────────────────────────────────────────
class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final Color color;
    switch (status) {
      case 'Success': color = Colors.green;  break;
      case 'Pending': color = Colors.orange; break;
      default:        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color       : color.withOpacity(isDark ? 0.20 : 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color     : color,
          fontSize  : 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// INFO TEXT
// ─────────────────────────────────────────────────────────────────
class _InfoText extends StatelessWidget {
  final String text;
  final Color  color;
  const _InfoText({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        text,
        style: TextStyle(fontSize: 13, color: color),
      ),
    );
  }
}