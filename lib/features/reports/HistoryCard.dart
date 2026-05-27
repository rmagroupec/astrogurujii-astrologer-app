import 'package:astrologer_app/model/VideoCallHistoryModel.dart';
import 'package:astrologer_app/service/apiService.dart';
import 'package:flutter/material.dart';

class HistoryCard extends StatefulWidget {
  final String page;
  const HistoryCard({super.key, required this.page});

  @override
  State<HistoryCard> createState() => _HistoryCardState();
}

class _HistoryCardState extends State<HistoryCard> {
  List<VideoCallHistory> history = [];
  bool isLoading = false;

 @override
void initState() {
  super.initState();
  print("HistoryCard INIT → ${widget.page}");
  fetchHistoryList();
}


  /// Fetch API Data
  void fetchHistoryList() async {
    print("inside this");
    try {
      setState(() => isLoading = true);

      var response = await ApiService().VideoCallHistoryList(widget.page);
      print("Fetching for page: ${widget.page}");

      setState(() {
        history = response.data2;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      print("Exception: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return isLoading == true ? Center(child: CircularProgressIndicator(),) :
     ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: history.length,
      itemBuilder: (context, index) {
        final item = history[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(blurRadius: 8, color: Colors.black.withOpacity(.05)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// HEADER
              Row(
                children: [
                  const CircleAvatar(
                    radius: 10,
                    backgroundColor: Color(0xffFFD600),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "${item.callType} | ${item.status}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    "₹${item.totalAmount}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),
              Text(
                "Order id : #${item.id}",
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),

              const SizedBox(height: 10),

              buildRow("Name", item.userName.toString()),
              buildRow("Duration", "${item.callMin} Minutes"),
              buildRow("Rate", "₹${item.callRate}/min"),
              buildRow("Order Time", item.orderTime.toString()),

              const SizedBox(height: 12),

              Row(
                children: [
                  actionButton("Suggest Remedy"),
                  const SizedBox(width: 8),
                  actionButton("Open Kundli"),
                  const SizedBox(width: 8),
                  actionButton("Chat Assistant"),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget buildRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text("$title :", style: const TextStyle(fontSize: 12)),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }

  Widget actionButton(String text) {
    return Expanded(
      child: Container(
        height: 32,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.redAccent),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Text(
            text,
            style: const TextStyle(fontSize: 11, color: Colors.red),
          ),
        ),
      ),
    );
  }
}
