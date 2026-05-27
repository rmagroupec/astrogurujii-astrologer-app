import 'package:astrologer_app/core/utils/size_config.dart';
import 'package:astrologer_app/features/Settings/UserNotesForPujaScreen.dart';
import 'package:astrologer_app/features/modal/PujaBookingModel.dart';
import 'package:astrologer_app/service/apiService.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class SuggestedPujaScreen extends StatefulWidget {
  const SuggestedPujaScreen({super.key});

  @override
  State<SuggestedPujaScreen> createState() => _SuggestedPujaScreenState();
}

class _SuggestedPujaScreenState extends State<SuggestedPujaScreen> {
  bool isLoading = true;
  List<PoojaBooking>? data;

  @override
  void initState() {
    super.initState();

    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final response = await ApiService().getPujaBooking(); // your API
      setState(() {
        data = response.data;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Suggested Pooja"),
        backgroundColor: Color(0xFFFCD417).withOpacity(0.25),
        foregroundColor: Colors.black,
      ),
      body: isLoading ? Center(child: CircularProgressIndicator(),) : Padding(
        padding: EdgeInsets.symmetric(
          vertical: FigmaSize.h(15),
          horizontal: FigmaSize.w(20),
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              ListView.builder(
                itemCount: 7,
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  return Column(
                    children: [
                      _suggestedPoojaCard(),
                      SizedBox(height: FigmaSize.h(16)),
                      Divider(color: Colors.black.withOpacity(0.1), height: 1),
                      SizedBox(height: FigmaSize.h(16)),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _suggestedPoojaCard() {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// LEFT CONTENT
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _labelText("Category Name", "VIP E-Pooja"),
                  _labelText("Product Name", "10 mahavidya ki pooja"),
                  _labelText("Name", "Jiya (ID - 2992627379)"),
                  _labelText("Perform by", "Narendra Singh"),

                  SizedBox(height: FigmaSize.h(4)),
                  Text(
                    "29-Sep-25, 01:54 AM",
                    style: TextStyle(
                      fontSize: FigmaSize.w(12),
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFD41000),
                    ),
                  ),

                  SizedBox(height: FigmaSize.h(6)),
                  Text(
                    "₹ 9000",
                    style: TextStyle(
                      fontSize: FigmaSize.w(13),
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  SizedBox(height: FigmaSize.h(6)),
                  _labelText("Type", "Paid Remedy", valueColor: Colors.red),
                  _labelText("Status", "Not Booked", valueColor: Colors.red),

                  SizedBox(height: FigmaSize.h(6)),
                  RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: FigmaSize.w(12),
                        color: Colors.black,
                      ),
                      children: const [
                        TextSpan(
                          text: "Description : ",
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        TextSpan(
                          text:
                              "Vaivashik Sukh Samriddhi ke liye aur vivaah rahi badhao ko dur karne ke liye",
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: FigmaSize.h(12)),

                  /// RED BUTTON
                ],
              ),
            ),

            SizedBox(width: FigmaSize.w(12)),

            /// RIGHT IMAGE + ICONS
            Column(
              children: [
                Container(
                  height: FigmaSize.h(80),
                  width: FigmaSize.w(80),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    image: DecorationImage(
                      image: NetworkImage("https://i.imgur.com/4Y9qZQZ.png"),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

                SizedBox(height: FigmaSize.h(12)),
              ],
            ),
          ],
        ),
        SizedBox(
          width: double.infinity,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: FigmaSize.w(16),
                  vertical: FigmaSize.h(8),
                ),
                decoration: BoxDecoration(
                  color: Color(0xFFD41000),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  "Suggest Next Remedy",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: FigmaSize.w(12),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Row(
                children: [
                  GestureDetector(
                    onTap: (){
                      Navigator.push(context, MaterialPageRoute(builder: (context) => Usernotesforpujascreen()));
                    },
                    child: SvgPicture.asset("assets/images/edit1.svg")),
                  SizedBox(width: FigmaSize.w(12)),
                  SvgPicture.asset("assets/images/delete.svg"),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _labelText(String title, String value, {Color? valueColor}) {
    return Padding(
      padding: EdgeInsets.only(bottom: FigmaSize.h(4)),
      child: RichText(
        text: TextSpan(
          style: TextStyle(fontSize: FigmaSize.w(12), color: Colors.black),
          children: [
            TextSpan(
              text: "$title : ",
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            TextSpan(
              text: value,
              style: TextStyle(
                color: valueColor ?? Colors.black,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

}
