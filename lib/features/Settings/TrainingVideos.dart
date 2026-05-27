import 'package:astrologer_app/core/utils/size_config.dart';
import 'package:flutter/material.dart';

class Trainingvideos extends StatefulWidget {
  const Trainingvideos({super.key});

  @override
  State<Trainingvideos> createState() => _TrainingvideosState();
}

class _TrainingvideosState extends State<Trainingvideos> {
  List<String> category = ["Call/Chat", "Emergency Session", "Astromall"];
  int isSelected = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Training Videos"),
        backgroundColor: Color(0xFFFCD417).withOpacity(0.25),
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Row(
              children: List.generate(category.length, (index) {
                final bool selected = isSelected == index;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      isSelected = index;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.all(10),
                    padding: EdgeInsets.symmetric(
                      horizontal: FigmaSize.w(12),
                      vertical: FigmaSize.h(7),
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(50),
                      border: Border.all(
                        color: selected ? Color(0xFFFCD417) : Color(0xFFE7E7E7),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          category[index],
                          style: TextStyle(
                            fontSize: FigmaSize.w(13),
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),

            SizedBox(height: FigmaSize.h(10)),
            ListView.builder(
              itemBuilder: (context, index) {
                return Container(
                  margin: EdgeInsets.symmetric(
                    horizontal: FigmaSize.w(17),
                    vertical: FigmaSize.h(10),
                  ),
                  height: FigmaSize.h(189),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage(
                        "https://marketplace.canva.com/EAFOSCtQ7p0/2/0/1600w/canva-orange-and-white-modern-find-your-dream-house-banner-6F7OhzOb6W8.jpg",
                      ),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: Container(
                      width: double.infinity,
                      height: FigmaSize.h(40),

                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF000000).withOpacity(0.09),
                            offset: const Offset(0, 4),
                            blurRadius: 4,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      padding: EdgeInsets.all(FigmaSize.w(12)),
                      child: Text(
                        "Training Video ${index + 1}",
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: FigmaSize.w(13),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                );
              },
              itemCount: 5,
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
            ),
          ],
        ),
      ),
    );
  }
}
