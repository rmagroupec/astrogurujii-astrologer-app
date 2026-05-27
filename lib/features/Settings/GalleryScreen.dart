import 'package:astrologer_app/core/utils/size_config.dart';
import 'package:astrologer_app/core/widgets/CustomSwitchButton.dart';
import 'package:astrologer_app/core/widgets/ThemeGradientButton.dart';
import 'package:astrologer_app/model/AstrologerGalleryModel.dart';
import 'package:astrologer_app/service/apiService.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class Galleryscreen extends StatefulWidget {
  const Galleryscreen({super.key});

  @override
  State<Galleryscreen> createState() => _GalleryscreenState();
}

class _GalleryscreenState extends State<Galleryscreen> {
  bool isLoading = true;
  List<AstrologerGalleryItem>? data;

  @override
  void initState() {
    super.initState();

    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final response = await ApiService().getGalleryList(); // your API
      setState(() {
        data = response.results;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Gallery"),
        backgroundColor: Color(0xFFFCD417).withOpacity(0.25),
        foregroundColor: Colors.black,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: EdgeInsets.all(FigmaSize.w(0)),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsetsGeometry.symmetric(
                      horizontal: FigmaSize.w(27),
                      vertical: FigmaSize.h(11),
                    ),
                    child: Text(
                      '''Admin Takes upto7 days to approved the image your shall be visible to customer when you enable at leasr 3 images''',
                      style: TextStyle(
                        fontSize: FigmaSize.w(11),
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  Expanded(
                    child: DefaultTabController(
                      length: 2,
                      child: Column(
                        children: [
                          Container(
                            color: Color(0xFFFCD417).withOpacity(0.10),
                            child: TabBar(
                              dividerColor: Colors.transparent,
                              indicatorSize: TabBarIndicatorSize.tab,
                              labelColor: Colors.black,
                              unselectedLabelColor: Colors.black,
                              indicator: const UnderlineTabIndicator(
                                borderSide: BorderSide(
                                  color: Color(0xFFFCD417),
                                  width: 2,
                                ),
                                // insets: EdgeInsets.symmetric(horizontal: 24),
                              ),
                              tabs: [
                                Tab(text: "Profile Gallery"),
                                Tab(text: "Live event DP"),
                              ],
                            ),
                          ),

                          Expanded(
                            child: TabBarView(
                              children: [
                                GridView.builder(
                                  shrinkWrap: true,
                                  padding: EdgeInsets.all(12),
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 2, // 🔥 2 in a row
                                        crossAxisSpacing: 12,
                                        mainAxisSpacing: 12,
                                        childAspectRatio:
                                            0.72, // adjust for image height
                                      ),
                                  itemCount: data!.length, // number of images
                                  itemBuilder: (context, index) {
                                    return _galleryCard(data![index]);
                                  },
                                ),

                                GridView.builder(
                                  shrinkWrap: true,
                                  padding: EdgeInsets.all(12),
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 2, // 🔥 2 in a row
                                        crossAxisSpacing: 12,
                                        mainAxisSpacing: 12,
                                        childAspectRatio:
                                            0.72, // adjust for image height
                                      ),
                                  itemCount: data!.length, // number of images
                                  itemBuilder: (context, index) {
                                    return _galleryCard(data![index]);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: GradientButton(
        title: "+ Upload Image",
        onTap: () {
          // your action here
        },
      ),
    );
  }

  Widget _galleryCard(AstrologerGalleryItem item) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(8),
              ),
              child: Image.network(
                item.file, // your image
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Bottom actions
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Verified badge
                Row(
                  children: [
                    Text(
                      "Verified",
                      style: TextStyle(
                        fontSize: FigmaSize.w(13),
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(width: FigmaSize.w(4)),
                    Icon(Icons.verified, size: 15, color: Colors.green),
                  ],
                ),

                // Switch + delete
                Row(
                  children: [
                    CustomToggleSwitch(
                      height: 18,
                      width: 45,
                      value: true,
                      onChanged: (val) {
                        // handle toggle
                      },
                    ),
                    SizedBox(width: FigmaSize.w(6)),
                    SvgPicture.asset(
                      "assets/images/delete.svg",
                      height: FigmaSize.h(16),
                      width: FigmaSize.w(16),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
