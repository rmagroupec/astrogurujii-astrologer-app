// lib/features/live/WaitlistScreen.dart
// Zero UI changes — only the itemCount is fixed to use real data,
// null-safety guards added, empty state added, and pull-to-refresh wired.

import 'package:astrologer_app/core/utils/size_config.dart';
import 'package:astrologer_app/model/WaitingListResponseModel.dart';
import 'package:astrologer_app/service/apiService.dart';
import 'package:flutter/material.dart';

class Waitlistscreen extends StatefulWidget {
  const Waitlistscreen({super.key});

  @override
  State<Waitlistscreen> createState() => _WaitlistscreenState();
}

class _WaitlistscreenState extends State<Waitlistscreen> {
  bool            isLoading = true;
  String?         _error;
  List<UserChatData> data   = [];   // never null — avoids data! crashes

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() { isLoading = true; _error = null; });
    try {
      final response = await ApiService().WaitingUserList();
      if (!mounted) return;
      setState(() {
        data      = response.data2 ?? [];
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error    = e.toString().replaceFirst('Exception: ', '');
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title          : Text("Waitlist"),
        backgroundColor: Color(0xFFFCD417).withOpacity(0.25),
        foregroundColor: Colors.black,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : _error != null
              // ── error state ────────────────────────────────────────────
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline,
                          color: Colors.red, size: 40),
                      SizedBox(height: FigmaSize.h(12)),
                      Text(_error!,
                          style      : const TextStyle(color: Colors.red),
                          textAlign  : TextAlign.center),
                      SizedBox(height: FigmaSize.h(12)),
                      TextButton.icon(
                        onPressed: _loadData,
                        icon     : const Icon(Icons.refresh),
                        label    : const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : data.isEmpty
                  // ── empty state ─────────────────────────────────────────
                  ? Center(
                      child: Text(
                        'No users in the waitlist.',
                        style: TextStyle(
                            color   : Colors.grey,
                            fontSize: FigmaSize.w(14)),
                      ),
                    )
                  // ── list ────────────────────────────────────────────────
                  : RefreshIndicator(
                      onRefresh: _loadData,
                      color    : const Color(0xFFFCD417),
                      child    : Padding(
                        padding: EdgeInsets.symmetric(
                          vertical  : FigmaSize.h(15),
                          horizontal: FigmaSize.w(20),
                        ),
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child  : Column(
                            children: [
                              ListView.builder(
                                // ← fixed: was hardcoded 7
                                itemCount  : data.length,
                                shrinkWrap : true,
                                physics    : const NeverScrollableScrollPhysics(),
                                itemBuilder: (context, index) {
                                  final item = data[index];
                                  return Container(
                                    margin : EdgeInsets.only(
                                        bottom: FigmaSize.h(16)),
                                    padding: EdgeInsets.symmetric(
                                      vertical  : FigmaSize.h(16),
                                      horizontal: FigmaSize.w(16),
                                    ),
                                    decoration: BoxDecoration(
                                      color       : Colors.white,
                                      border      : Border.all(
                                          color: Color(0xFFE7E7E7), width: 1),
                                      borderRadius:
                                          BorderRadius.circular(FigmaSize.w(10)),
                                    ),
                                    child: Column(
                                      mainAxisAlignment : MainAxisAlignment.start,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            // ── Avatar ─────────────────
                                            Container(
                                              height    : FigmaSize.h(40),
                                              width     : FigmaSize.w(40),
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                image: DecorationImage(
                                                  image: NetworkImage(
                                                    item.image?.isNotEmpty == true
                                                        ? item.image!
                                                        : 'https://i.pravatar.cc/150',
                                                  ),
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                            ),
                                            SizedBox(width: FigmaSize.w(8)),
                                            // ── Name + ID ──────────────
                                            Text(
                                              "${item.name ?? ''}",
                                              style: TextStyle(
                                                fontSize  : FigmaSize.w(14),
                                                fontWeight: FontWeight.w600,
                                                color     : Colors.black,
                                              ),
                                            ),
                                            SizedBox(width: FigmaSize.w(4)),
                                            Text(
                                              "(#${item.id ?? ''})",
                                              style: TextStyle(
                                                fontSize  : FigmaSize.w(14),
                                                fontWeight: FontWeight.w600,
                                                color     : Color(0xFF666666),
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: FigmaSize.h(10)),
                                        Text(
                                          "${item.createdAt ?? ''}",
                                          style: TextStyle(
                                            fontSize  : FigmaSize.w(12),
                                            fontWeight: FontWeight.w600,
                                            color     : Color(0xFFD41000),
                                          ),
                                        ),
                                        SizedBox(height: FigmaSize.h(8)),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            _infoRow("Name",
                                                item.name ?? ''),
                                            _infoRow(
                                              "Type",
                                              (item.type?.isNotEmpty == true)
                                                  ? item.type!
                                                  : "Chat",
                                            ),
                                            _infoRow("Token", "1"),
                                            _infoRow("Duration", "8 Mins"),
                                          ],
                                        ),
                                        SizedBox(height: FigmaSize.h(8)),
                                        Container(
                                          width  : FigmaSize.w(137),
                                          padding: EdgeInsets.symmetric(
                                            vertical  : FigmaSize.h(4),
                                            horizontal: FigmaSize.w(23),
                                          ),
                                          decoration: BoxDecoration(
                                            color        : Color(0xFFEEEEEE),
                                            borderRadius :
                                                BorderRadius.circular(15),
                                          ),
                                          child: Center(
                                            child: Text(
                                              "Start Offline Session",
                                              style: TextStyle(
                                                fontSize  : FigmaSize.w(9),
                                                fontWeight: FontWeight.bold,
                                                color     : Colors.black,
                                                height    :
                                                    24 / FigmaSize.w(12),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
    );
  }

  Widget _infoRow(String keyText, String valueText) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: FigmaSize.w(70),
          child: Text(
            "$keyText",
            style: TextStyle(
              fontSize  : FigmaSize.w(12),
              fontWeight: FontWeight.w500,
              color     : Colors.black,
              height    : 16 / FigmaSize.w(12),
            ),
          ),
        ),
        Text(
          ":  ",
          style: TextStyle(
            fontSize  : FigmaSize.w(12),
            fontWeight: FontWeight.w500,
            height    : 16 / FigmaSize.w(12),
          ),
        ),
        Expanded(
          child: Text(
            valueText,
            style: TextStyle(
              fontSize  : FigmaSize.w(12),
              fontWeight: FontWeight.bold,
              color     : Colors.black,
              height    : 16 / FigmaSize.w(12),
            ),
          ),
        ),
      ],
    );
  }
}