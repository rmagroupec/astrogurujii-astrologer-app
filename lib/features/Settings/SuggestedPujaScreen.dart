import 'package:astrologer_app/features/modal/PujaBookingModel.dart';
import 'package:flutter/material.dart';
import 'package:astrologer_app/core/config/theme_config.dart';
import 'package:astrologer_app/service/apiService.dart';


class PoojaBookingScreen extends StatefulWidget {
  const PoojaBookingScreen({super.key});

  @override
  State<PoojaBookingScreen> createState() => _PoojaBookingScreenState();
}

class _PoojaBookingScreenState extends State<PoojaBookingScreen> {
  bool isLoading = true;
  bool isError = false;
  List<PoojaBooking> bookings = [];

  @override
  void initState() {
    super.initState();
    fetchPoojaBookings();
  }

  /// ================================
  /// API CALL
  /// ================================
  Future<void> fetchPoojaBookings() async {
    setState(() {
      isLoading = true;
      isError = false;
    });

    try {
      final res = await ApiService().getPujaBooking();
      
     setState(() {
       
        bookings = res.data;
     });
    } catch (e) {
      isError = true;
      bookings = [];
    }

    setState(() => isLoading = false);
  }

  /// ================================
  /// START LIVE API
  /// ================================
  Future<void> startLivePooja(PoojaBooking booking) async {
    try {
      await ApiService().PoojaStartLive(
       booking.pujaBookingId.toString()
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Pooja started successfully")),
      );

      fetchPoojaBookings(); // refresh
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to start pooja")),
      );
    }
  }
  

  /// ================================
  /// UI
  /// ================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: AppBar(
        title: const Text("Pooja Bookings"),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: _body(),
    );
  }

  Widget _body() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (isError) {
      return Center(
        child: ElevatedButton(
          onPressed: fetchPoojaBookings,
          child: const Text("Retry"),
        ),
      );
    }

    if (bookings.isEmpty) {
      return const Center(child: Text("No Pooja Bookings Found"));
    }

    return RefreshIndicator(
      onRefresh: fetchPoojaBookings,
      child: ListView.builder(
        itemCount: bookings.length,
        itemBuilder: (_, i) => _bookingCard(bookings[i]),
      ),
    );
  }

  /// ================================
  /// BOOKING CARD
  /// ================================
  Widget _bookingCard(PoojaBooking b) {
    final bool canStartLive =
        b.paymentStatus == "Success" && b.isLive == false;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// HEADER
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                b.pujaType,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              _statusChip(b.paymentStatus),
            ],
          ),

          const SizedBox(height: 6),

          /// BOOKING ID
          Text(
            "Booking ID: ${b.pujaBookingId}",
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),

          const SizedBox(height: 10),

          /// DATE
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 14),
              const SizedBox(width: 6),
              Text(
                b.pujaDate.isEmpty ? "Date not assigned" : b.pujaDate,
                style: const TextStyle(fontSize: 13),
              ),
            ],
          ),

          /// TIME
          if (b.startTime.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                children: [
                  const Icon(Icons.access_time, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    "${b.startTime}${b.endTime.isNotEmpty ? " - ${b.endTime}" : ""}",
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 10),

          /// AMOUNT
          Text(
            "Amount: ₹${b.pujaAmount}",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),

          const SizedBox(height: 14),

          /// ACTION
          if (canStartLive)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                ),
                onPressed: () => startLivePooja(b),
                child: const Text(
                  "Start Live",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            )
          else if (b.isLive)
            _infoText("Live in progress")
          else
            _infoText("Waiting for payment"),
        ],
      ),
    );
  }

  Widget _statusChip(String status) {
    Color color;
    switch (status) {
      case "Success":
        color = Colors.green;
        break;
      case "Pending":
        color = Colors.orange;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _infoText(String text) {
    return Center(
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          color: Colors.grey,
        ),
      ),
    );
  }
}
