import 'package:astrologer_app/core/utils/size_config.dart';
import 'package:flutter/material.dart';



class SupportChatScreen extends StatelessWidget {
  const SupportChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white, // Yellow header
        elevation: 0,
        leading: const Icon(Icons.arrow_back, color: Colors.black),
        title: const Text(
          'Support Chat',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
      ),
      body: Column(
        children: [
          // List of Tickets
          Expanded(
            child: ListView(
              children: const [
                TicketTile(
                  ticketNo: '#189927',
                  message: 'Meri I\'d kabtk shuru hogi',
                  dateTime: '22 Oct 25, 04:44 PM',
                  status: 'OPEN',
                  statusColor: Colors.green,
                ),
                
                TicketTile(
                  ticketNo: '#189927',
                  message: 'Meri I\'d kabtk shuru hogi',
                  dateTime: '22 Oct 25, 04:44 PM',
                  status: 'Closed',
                  statusColor: Colors.red,
                ),
              ],
            ),
          ),

          // Footer info and Button
          Padding(
            padding:  EdgeInsets.all(FigmaSize.w(16)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                 Text(
                  'Data shown for last 3 days only',
                  style: TextStyle(color: Colors.grey, fontSize: FigmaSize.w(14)),
                ),
                 SizedBox(height: FigmaSize.h(16)),
                SizedBox(
                  width: double.infinity,
                  height: FigmaSize.h(55),
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD700),
                      foregroundColor: Colors.black,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4), // Slightly rounded like the image
                      ),
                    ),
                    child:  Text(
                      'Create New Chat',
                      style: TextStyle(fontSize: FigmaSize.w(18), fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class TicketTile extends StatelessWidget {
  final String ticketNo;
  final String message;
  final String dateTime;
  final String status;
  final Color statusColor;

  const TicketTile({
    super.key,
    required this.ticketNo,
    required this.message,
    required this.dateTime,
    required this.status,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:  EdgeInsets.symmetric(horizontal: FigmaSize.w(16), vertical: FigmaSize.h(12)),
      decoration: const BoxDecoration(
        color: Color(0xFFFFFBE6), // Light cream background
        border: Border(
          bottom: BorderSide(color: Color(0xFFFFE082), width: 1),
        ),
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              
              RichText(
                text: TextSpan(
                  style: TextStyle(color: Colors.black, fontSize: FigmaSize.w(14)),
                  children: [
                    const TextSpan(text: 'Ticket No. '),
                    TextSpan(
                      text: ticketNo,
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: FigmaSize.h(8)),
              Text(
                message,
                style: TextStyle(fontSize: FigmaSize.w(15), fontWeight: FontWeight.w500),
              ),
              SizedBox(height: FigmaSize.h(8)),
              Text(
                dateTime,
                style: TextStyle(color: Colors.black54, fontSize: FigmaSize.w(13)),
              ),
              
            ],
          ),
          Positioned(
            right: 0,
            top: 0,
            child: Text(
              status,
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.bold,
                fontSize: FigmaSize.w(14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}