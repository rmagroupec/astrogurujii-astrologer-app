import 'package:astrologer_app/core/utils/size_config.dart';
import 'package:astrologer_app/model/ratingListModel.dart';
import 'package:astrologer_app/service/apiService.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class MyReviewsScreen extends StatefulWidget {
  const MyReviewsScreen({super.key});

  @override
  State<MyReviewsScreen> createState() => _MyReviewsScreenState();
}

class _MyReviewsScreenState extends State<MyReviewsScreen> {


  bool isLoading = true;
  List<RatingItem> ratings = [];

  @override
  void initState() {
    super.initState();
    _fetchRatings();
  }

Future<void> _fetchRatings() async {
  try {
    final response = await ApiService().getReviewList();

    setState(() {
      ratings = response.results;
      isLoading = false;
    });
  } catch (e) {
    setState(() => isLoading = false);
    debugPrint("Rating API Error: $e");
  }
}

  @override
  Widget build(BuildContext context) {

    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFFCD417).withOpacity(0.25),
        foregroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          "My Reviews",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          Container(
            margin: EdgeInsets.only(right: FigmaSize.w(12)),
            padding: EdgeInsets.symmetric(
              horizontal: FigmaSize.w(14),
              vertical: FigmaSize.h(5),
            ),
            decoration: BoxDecoration(
              color: Color(0xFFFEDF30),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                width: 1,
                color: Color(0xFFA0A0A0).withOpacity(0.30),
              ),
            ),
            child: Row(
              children: [
                SvgPicture.asset("assets/images/office-push-pin.svg"),
                SizedBox(width: FigmaSize.w(4)),
                Text(
                  "Pinned",
                  style: TextStyle(
                    fontSize: FigmaSize.w(10),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),

      body: isLoading ? Center(child: CircularProgressIndicator(),) : SingleChildScrollView(
        padding: EdgeInsets.all(FigmaSize.w(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔹 Flagged info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      "Flagged reviews ",
                      style: TextStyle(
                        fontSize: FigmaSize.w(13),
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      "(excluding PO)",
                      style: TextStyle(
                        fontSize: FigmaSize.w(9),
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
                Text(
                  "0/10",
                  style: TextStyle(
                    fontSize: FigmaSize.w(13),
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            SizedBox(height: FigmaSize.h(6)),
            LinearProgressIndicator(
              value: 0.0,
              minHeight: FigmaSize.h(11),
              backgroundColor: Color(0xFFFCD417).withOpacity(0.25),
              valueColor: AlwaysStoppedAnimation<Color>(
                Color(0xFFFCD417).withOpacity(0.25),
              ),
            ),
            SizedBox(height: FigmaSize.h(8)),
            Text(
              "System gives you Maximum 10 flags for your reviews every month. Used balance will get reset rest day of the month",
              style: TextStyle(
                fontSize: FigmaSize.w(10),
                color: Colors.black,
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 16),

            // 🔹 Filter Chips
            Row(
              children: [
                _chip("ALL ⭐", false, ""),
                const SizedBox(width: 8),
                _chip("Astromall", true, "assets/images/shopping-cart.svg"),
                const SizedBox(width: 8),
                _chip("Pinned", true, "assets/images/shopping-cart.svg"),
              ],
            ),

            const SizedBox(height: 16),

            // 🔹 Review Cards
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: ratings.length,
              itemBuilder: (context, index) {
              return _reviewCard(ratings[index]);
            })
          ],
        ),
      ),
    );
  }

  // 🔹 Filter chip
  Widget _chip(String label, bool isIcon, String icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFFCD417)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          if (isIcon) SvgPicture.asset(icon),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  // 🔹 Review card
  Widget _reviewCard(RatingItem rating) {
    return Container(
      margin: EdgeInsets.only(bottom: FigmaSize.h(12)),
      padding: EdgeInsets.all(FigmaSize.w(12)),
      decoration: BoxDecoration(
        border: Border.all(color: Color(0xFFE7E7E7)),
        borderRadius: BorderRadius.circular(FigmaSize.w(12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Order ID : ${rating.id}",
            style: TextStyle(
              fontSize: FigmaSize.w(11),
              color: Color(0xFF666666),
            ),
          ),
          SizedBox(height: FigmaSize.h(8)),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              Container(
  height: FigmaSize.h(36),
  width: FigmaSize.w(36),
  alignment: Alignment.center,
  decoration: BoxDecoration(
    shape: BoxShape.circle,
    border: Border.all(color: const Color(0xFFFCD417)),
  ),
  child: (rating.profileImg.isNotEmpty)
      ? ClipOval(
          child: Image.network(
            rating.profileImg,
            width: FigmaSize.w(36),
            height: FigmaSize.h(36),
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) {
              return Text(
                rating.displayName.isNotEmpty
                    ? rating.displayName[0].toUpperCase()
                    : 'K',
                style: const TextStyle(fontWeight: FontWeight.w600),
              );
            },
          ),
        )
      : Text(
          rating.displayName.isNotEmpty
              ? rating.displayName[0].toUpperCase()
              : 'K',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
),

              SizedBox(width: FigmaSize.w(10)),

              // Review details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          rating.displayName,
                          style: TextStyle(
                            fontSize: FigmaSize.w(14),
                            color: Colors.black,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Row(
                          children: List.generate(
                            5,
                            (index) => Icon(
                              Icons.star,
                              size: 14,
                              color: index < rating.rating
                                  ? Colors.amber
                                  : Colors.grey.shade300,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: FigmaSize.h(2)),
                    Text(
                      "Chat : ${rating.createdDate}",
                      style: TextStyle(
                        fontSize: FigmaSize.w(12),
                        color: Colors.black,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: FigmaSize.h(6)),
                  ],
                ),
              ),
            ],
          ),
          Text(
            rating.review != "" ? rating.review : "No Review",
            style: TextStyle(
              fontSize: FigmaSize.w(12),
              color: Colors.black,
              fontWeight: FontWeight.w500,
              height: 20 / FigmaSize.w(12),
            ),
          ),
          SizedBox(height: FigmaSize.h(12)),

          // Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: FigmaSize.w(12),
                  vertical: FigmaSize.h(6),
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFCD417),
                  borderRadius: BorderRadius.circular(FigmaSize.w(20)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.flag, size: FigmaSize.w(14)),
                    SizedBox(width: FigmaSize.w(4)),
                    Text(
                      "Restore",
                      style: TextStyle(
                        fontSize: FigmaSize.w(12),
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: FigmaSize.w(12)),
              Text(
                "Delete",
                style: TextStyle(
                  fontSize: FigmaSize.w(12),
                  color: Colors.black,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
