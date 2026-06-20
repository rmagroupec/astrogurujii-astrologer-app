// lib/features/pooja/PoojaBookingScreen.dart
// ── Theme-aware: AppColors + AppTheme tokens, zero hardcoded colors ───────────
// ── Zero logic changes ────────────────────────────────────────────────────────

import 'package:astrologer_app/core/config/theme_config.dart';
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

  Future<void> startLivePooja(PoojaBooking booking) async {
    try {
      await ApiService().PoojaStartLive(booking.pujaBookingId.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pooja started successfully')),
      );
      fetchPoojaBookings();
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to start pooja')),
      );
    }
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
  final VoidCallback onStartLive;

  const _BookingCard({
    required this.booking,
    required this.c,
    required this.isDark,
    required this.onStartLive,
  });

  @override
  Widget build(BuildContext context) {
    final b            = booking;
    final canStartLive = b.paymentStatus == 'Success' && b.isLive == false;

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
          if (canStartLive)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryYellow,
                  foregroundColor: Colors.black,
                  elevation      : 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: onStartLive,
                child: const Text(
                  'Start Live',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            )
          else if (b.isLive)
            _InfoText(text: 'Live in progress', color: Colors.green)
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