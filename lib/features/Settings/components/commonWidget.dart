import 'package:flutter/material.dart';

PreferredSizeWidget yellowAppBar(String title) {
  return AppBar(
    backgroundColor: const Color(0xFFFCD417),
    foregroundColor: Colors.black,
    elevation: 0,
    title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
  );
}

Widget offersInfo() => Padding(
  padding: const EdgeInsets.all(12),
  child: Text(
    "Loyal - Customers who have spoken with you for more than 15 min "
    "(including both call and chat )",
    style: const TextStyle(fontSize: 11),
  ),
);

Widget offersTabBar() => Container(
  color: const Color(0xFFFFF8E1),
  child: const TabBar(
    dividerColor: Colors.transparent,
    indicator: UnderlineTabIndicator(
      borderSide: BorderSide(color: Color(0xFFFCD417), width: 2),
    ),
    tabs: [
      Tab(text: "ALL OFFERS"),
      Tab(text: "HISTORY"),
    ],
  ),
);

Widget offerFilterChips() => Padding(
  padding: const EdgeInsets.all(12),
  child: Row(
    children: ["All", "50% Off", "20% Off", "75% Off"]
        .map((e) => Container(
              margin: const EdgeInsets.only(right: 8),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFFCD417)),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(e, style: const TextStyle(fontSize: 11)),
            ))
        .toList(),
  ),
);

Widget timeBox(String title, String value) => Expanded(
  child: Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      border: Border.all(color: Colors.grey.shade300),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(fontSize: 10, color: Colors.black54)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    ),
  ),
);
 Widget alwaysOnlineCard() {
  return Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      color: Colors.white,
      boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6),
      ],
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text("Sakshi (98997378)",
                style: TextStyle(fontWeight: FontWeight.w600)),
            SizedBox(height: 6),
            Text("Spent - 340"),
            Text("Last session - 22 Oct 2025, 04:47 PM",
                style: TextStyle(fontSize: 11)),
          ],
        ),
        Switch(value: false, onChanged: (_) {}),
      ],
    ),
  );
}
Widget searchField() {
  return TextField(
    decoration: InputDecoration(
      hintText: "Search by Name",
      prefixIcon: const Icon(Icons.search),
      contentPadding: const EdgeInsets.symmetric(vertical: 0),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
    ),
  );
}
Widget infoBox(String title, String value) {
  return Expanded(
    child: Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 11, color: Colors.black54),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    ),
  );
}
 Widget communityTabs({
  required int selectedIndex,
  required Function(int) onTabChange,
}) {
  final tabs = [
    {"title": "Followers", "count": "840"},
    {"title": "Favourites", "count": "10"},
    {"title": "Always Online", "count": "10"},
  ];

  return Container(
    color: const Color(0xFFFFF8E1),
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: List.generate(tabs.length, (index) {
        final isSelected = index == selectedIndex;

        return Expanded(
          child: GestureDetector(
            onTap: () => onTabChange(index), // 🔥 THIS WAS MISSING
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      tabs[index]['title']!,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFCD417),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        tabs[index]['count']!,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  height: 2,
                  width: 60,
                  color: isSelected
                      ? const Color(0xFFFCD417)
                      : Colors.transparent,
                ),
              ],
            ),
          ),
        );
      }),
    ),
  );
}
Widget historyOfferCard(bool inProgress) {
  return Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      border: Border.all(color: Colors.grey.shade300),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("50% off",
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: inProgress
                    ? Colors.blue.shade100
                    : Colors.green.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                inProgress ? "In Progress" : "Completed",
                style: TextStyle(
                  fontSize: 12,
                  color: inProgress ? Colors.blue : Colors.green,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            timeBox("Start Time", "02 Oct 25, 12:34 AM"),
            const SizedBox(width: 8),
            timeBox("End Time", "Currently active"),
          ],
        ),
      ],
    ),
  );
}



Widget communityUserCard() {
  return Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      color: Colors.white,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 6,
        )
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text("Dhan Singh (817381387)",
                style: TextStyle(fontWeight: FontWeight.w600)),
            Icon(Icons.favorite, color: Colors.red),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            infoBox("Spent with you", "₹ 4,930"),
            infoBox("Last Session", "01 Oct, 25"),
            infoBox("Remedies", "0"),
          ],
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () {},
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.red),
            foregroundColor: Colors.red,
          ),
          child: const Text("Assistant Chat"),
        )
      ],
    ),
  );
}
Widget alwaysOnlineInfo() {
  return Container(
    width: double.infinity,
    color: const Color(0xFFFFF8E1),
    padding: const EdgeInsets.all(12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Row(
          children: [
            Icon(
              Icons.wifi,
              color: Colors.red,
              size: 18,
            ),
            SizedBox(width: 6),
            Text(
              "Always Online",
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
        SizedBox(height: 6),
        Text(
          "This feature allows selected users to start a session with you "
          "even when you are offline. Use it to stay connected with your "
          "important users.",
          style: TextStyle(
            fontSize: 11,
            color: Colors.black87,
          ),
        ),
      ],
    ),
  );
}
Widget searchAndSort() {
  return Padding(
    padding: const EdgeInsets.all(12),
    child: Row(
      children: [
        Expanded(child: searchField()),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFFCD417),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: const [
              Icon(Icons.sort, size: 16),
              SizedBox(width: 4),
              Text(
                "Sort",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}



