import 'package:astrologer_app/core/utils/size_config.dart';
import 'package:flutter/material.dart';

class Invoice extends StatefulWidget {
  const Invoice({super.key});

  @override
  State<Invoice> createState() => _InvoiceState();
}

class _InvoiceState extends State<Invoice> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Invoice"),
        backgroundColor: Color(0xFFFCD417).withOpacity(0.25),
        foregroundColor: Colors.black,
      ),
      body: invoiceBody(),
    );
  }

  Widget invoiceBody() {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        vertical: FigmaSize.h(30),
        horizontal: FigmaSize.w(35),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Month Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "September 2025",
                style: TextStyle(
                  fontSize: FigmaSize.w(16),
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              Icon(Icons.keyboard_arrow_up),
            ],
          ),

          SizedBox(height: FigmaSize.h(17)),

          // Progress Status
          invoiceStatusBar(),

          SizedBox(height: FigmaSize.h(17)),

          // Earnings Card
          Container(
            width: double.infinity,

            decoration: BoxDecoration(
              border: Border.all(color: Color(0xFFE7E7E7)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: FigmaSize.w(12),
                    vertical: FigmaSize.h(17),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Earnings",
                        style: TextStyle(
                          fontSize: FigmaSize.w(12),
                          color: Color(0xFF717171),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "₹ 7371.97",
                        style: TextStyle(
                          fontSize: FigmaSize.w(20),
                          fontWeight: FontWeight.w600,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: FigmaSize.h(30)),

                // Download Invoice Button
                Container(
                  padding: EdgeInsets.symmetric(
                    vertical: FigmaSize.h(8),
                    horizontal: FigmaSize.w(12),
                  ),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(8),
                      bottomRight: Radius.circular(8),
                    ),
                    border: Border.all(color: Colors.green),
                  ),
                  child: InkWell(
                    onTap: () {
                      // download invoice
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Download Invoice",
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.download, color: Colors.green),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: FigmaSize.h(20)),
          Divider(color: const Color(0xFF000000).withOpacity(0.06), height: 1),
          SizedBox(height: FigmaSize.h(14)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                "August 2025",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              Icon(Icons.keyboard_arrow_down),
            ],
          ),
          SizedBox(height: FigmaSize.h(14)),
          Divider(color: const Color(0xFF000000).withOpacity(0.06), height: 1),

          // Next Month (Collapsed)
        ],
      ),
    );
  }

  Widget invoiceStatusBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Dots + Lines
        Row(
          children: [
            _dot(isActive: true),
            _line(isActive: true),
            _dot(isActive: true),
            _line(isActive: false),
            _dot(isActive: false),
          ],
        ),

        SizedBox(height: FigmaSize.h(9)),

        // Labels
        Row(
          children: [
            Expanded(
              child: Text(
                "Processing",
                textAlign: TextAlign.left,
                style: TextStyle(
                  fontSize: FigmaSize.w(12),
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
            ),
            Expanded(
              child: Text(
                "In Processing",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: FigmaSize.w(12),
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
            ),
            Expanded(
              child: Text(
                "Completed",
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: FigmaSize.w(12),
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _dot({required bool isActive}) {
    return Container(
      width: FigmaSize.w(11),
      height: FigmaSize.h(11),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(
          color: isActive ? Colors.green : Colors.grey.shade300,
          width: 2,
        ),
      ),
    );
  }

  Widget _line({required bool isActive}) {
    return Expanded(
      child: Container(
        height: FigmaSize.h(3),
        color: isActive ? Colors.green : Colors.grey.shade300,
      ),
    );
  }
}
