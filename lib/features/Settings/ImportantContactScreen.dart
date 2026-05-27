import 'package:flutter/material.dart';

class ImportantNumberPage extends StatelessWidget {
  const ImportantNumberPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFD600),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Important Number",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "You will get call and chat alerts from these numbers. "
              "save these number to avoid any confusion",
              style: TextStyle(
                fontSize: 13,
                color: Colors.black87,
              ),
            ),

            const SizedBox(height: 24),

            _section(
              title: "App Call",
              numbers:
                  "+91 7615976021, +91 7615976021, +91 7615976021,\n"
                  "+91 7615976021, +91 7615976021, +91 7615976021,\n"
                  "+91 7615976021, +91 7615976021, +91 7615976021,\n"
                  "+91 7615976021, +91 7615976021, +91 7615976021,\n"
                  "+91 7615976021, +91 7615976021, +91 7615976021",
              onAdd: () {},
            ),

            const SizedBox(height: 24),

            _section(
              title: "App Chat Alert",
              numbers:
                  "+91 7615976021, +91 7615976021, +91 7615976021,\n"
                  "+91 7615976021, +91 7615976021, +91 7615976021,\n"
                  "+91 7615976021, +91 7615976021, +91 7615976021,\n"
                  "+91 7615976021, +91 7615976021, +91 7615976021,\n"
                  "+91 7615976021, +91 7615976021, +91 7615976021",
              onAdd: () {},
            ),

            const SizedBox(height: 24),

            _section(
              title: "App Admin Support",
              numbers:
                  "+91 7615976021, +91 7615976021, +91 7615976021,\n"
                  "+91 7615976021, +91 7615976021",
              onAdd: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _section({
    required String title,
    required String numbers,
    required VoidCallback onAdd,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          numbers,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade700,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 40,
          child: ElevatedButton(
            onPressed: onAdd,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD600),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              "Add Contact",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Divider(color: Colors.grey.shade300),
      ],
    );
  }
}
