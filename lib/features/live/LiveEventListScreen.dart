import 'dart:convert';

import 'package:astrologer_app/core/utils/size_config.dart';
import 'package:astrologer_app/core/widgets/app_gradient_button.dart';
import 'package:astrologer_app/features/live/GoLiveScreen.dart';
import 'package:astrologer_app/features/live/ScheduleLiveEvents.dart';
import 'package:astrologer_app/model/AstrologerLiveEventsListModel.dart';
import 'package:astrologer_app/service/apiService.dart';
import 'package:astrologer_app/service/apiClient.dart';
import 'package:flutter/material.dart';

class LiveEventListScreen extends StatefulWidget {
  const LiveEventListScreen({super.key});

  @override
  State<LiveEventListScreen> createState() => _LiveEventListScreenState();
}

class _LiveEventListScreenState extends State<LiveEventListScreen> {
  bool isLoading      = true;
  bool isGoingLive    = false;   // loading state for "Go Live Now"
  List<LiveEventData>? data;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // ── Load scheduled events ─────────────────────────────────────
  Future<void> _loadData() async {
    setState(() => isLoading = true);
    try {
      final response = await ApiService().LiveEventsList();
      print("✅ LiveEventsList: ${response.data?.length} items");
      setState(() {
        data      = response.data;
        isLoading = false;
      });
    } catch (e) {
      print("❌ LiveEventsList error: $e");
      setState(() => isLoading = false);
    }
  }

  // ── Go Live Now: create instant event then navigate ───────────
  Future<void> _goLiveNow() async {
    setState(() => isGoingLive = true);

    try {
      final now = DateTime.now();

      // Format today as YYYY-MM-DD
      final liveDate =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      // Format current time as H:MM AM/PM
      final hour   = now.hour % 12 == 0 ? 12 : now.hour % 12;
      final minute = now.minute.toString().padLeft(2, '0');
      final period = now.hour >= 12 ? 'PM' : 'AM';
      final startTime = '$hour:$minute $period';

      // End time = start + 2 hours
      final endHour   = (now.hour + 2) % 24;
      final endPeriod = endHour >= 12 ? 'PM' : 'AM';
      final endTime   =
          '${endHour % 12 == 0 ? 12 : endHour % 12}:$minute $endPeriod';

      // Create the live event via go_live API
      final client   = ApiClient();
      final response = await client.post(
        'astrologer_api/go_live',
        {
          'title':        'Instant Live',
          'start_time':   startTime,
          'end_time':     endTime,
          'live_date':    liveDate,
          'recurringDay': 'customDate',
        },
        isAuthRequired: true,
      );

      final body = jsonDecode(response.body);
      print('go_live instant response: $body');

      if (!mounted) return;

      if (body['status'] == true) {
        // Fetch the newly created event so we have its _id and channel_id
        final listResponse = await ApiService().LiveEventsList();

        if (!mounted) return;

        // The latest event is first (sorted by Created_date desc)
        final newEvent = listResponse.data?.isNotEmpty == true
            ? listResponse.data!.first
            : null;

        // Navigate to GoLiveScreen with the fresh event
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => GoLiveScreen(event: newEvent),
          ),
        );

        // Refresh list on return
        _loadData();
      } else {
        _showSnack(body['message'] ?? 'Failed to create live', error: true);
      }
    } catch (e) {
      print('❌ _goLiveNow error: $e');
      if (mounted) _showSnack('Error: $e', error: true);
    } finally {
      if (mounted) setState(() => isGoingLive = false);
    }
  }

  void _showSnack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? Colors.red.shade700 : Colors.green.shade700,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  // ── Build ─────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Live Events"),
        backgroundColor: const Color(0xFFFCD417).withOpacity(0.25),
        foregroundColor: Colors.black,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : (data == null || data!.isEmpty)
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.live_tv_outlined,
                          size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      const Text(
                        "No upcoming live events",
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Schedule one or tap Go Live Now",
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                )
              : Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: FigmaSize.h(15),
                    horizontal: FigmaSize.w(20),
                  ),
                  child: ListView.builder(
                    itemCount: data!.length,
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemBuilder: (context, index) {
                      final event = data![index];
                      return _EventCard(
                        event: event,
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => GoLiveScreen(event: event),
                            ),
                          );
                          _loadData();
                        },
                      );
                    },
                  ),
                ),

      // ── Bottom bar ───────────────────────────────────────────
      bottomNavigationBar: Container(
        color: Colors.transparent,
        padding: EdgeInsets.symmetric(horizontal: FigmaSize.w(16)),
        margin: const EdgeInsets.only(bottom: 10),
        width: double.infinity,
        height: FigmaSize.h(56),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Schedule Event
            AppGradientButton(
              title: "Schedule Event",
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const Scheduleliveevents(),
                  ),
                ).then((_) => _loadData());
              },
              width: FigmaSize.designWidth / 2.6,
            ),

            // Go Live Now — creates instant event then navigates
            isGoingLive
                ? SizedBox(
                    width: FigmaSize.designWidth / 2.6,
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFFCD417),
                        strokeWidth: 2.5,
                      ),
                    ),
                  )
                : AppGradientButton(
                    title: "Go Live Now",
                    onPressed: _goLiveNow,
                    width: FigmaSize.designWidth / 2.6,
                  ),
          ],
        ),
      ),
    );
  }
}

// ── Event card extracted as a clean widget ─────────────────────
class _EventCard extends StatelessWidget {
  final LiveEventData event;
  final VoidCallback onTap;

  const _EventCard({required this.event, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: FigmaSize.h(116),
        width: double.infinity,
        margin: EdgeInsets.only(bottom: FigmaSize.h(14)),
        child: Stack(
          children: [
            // Background image
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: const DecorationImage(
                    image: AssetImage(
                      "assets/images/4002487859e231b42e4088d553cfb27222391230.png",
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),

            // Dark overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.black.withOpacity(0.60),
                ),
              ),
            ),

            // Content
            Positioned.fill(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: FigmaSize.w(13),
                  vertical: FigmaSize.h(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      event.title ?? "Live Session",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: FigmaSize.w(17),
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFD41000),
                      ),
                    ),
                    Text(
                      event.startTime ?? "-",
                      style: TextStyle(
                        fontSize: FigmaSize.w(12),
                        height: 24 / FigmaSize.w(12),
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      "On ${event.liveDate ?? '-'}",
                      style: TextStyle(
                        fontSize: FigmaSize.w(12),
                        height: 24 / FigmaSize.w(12),
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          margin: const EdgeInsets.only(right: 5),
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                        Text(
                          event.status ?? '-',
                          style: TextStyle(
                            fontSize: FigmaSize.w(12),
                            height: 24 / FigmaSize.w(12),
                            fontWeight: FontWeight.w500,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Arrow
            Positioned(
              right: FigmaSize.w(12),
              top: 0,
              bottom: 0,
              child: const Icon(
                Icons.arrow_forward_ios,
                color: Colors.white54,
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}