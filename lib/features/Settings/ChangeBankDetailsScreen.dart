import 'package:flutter/material.dart';

class ChangeBankDetailsScreen extends StatelessWidget {
  const ChangeBankDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
     appBar: AppBar(
        title: Text("Enter Bank Details"),
        backgroundColor: Color(0xFFFCD417).withOpacity(0.25),
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _textField("Enter Account Number *"),
            _textField("Re-enter Account Number *"),
            _textField("Enter Bank Number *"),
            _textField("Account Holder Number *"),
            _textField("Enter IFSC Code *"),

            const SizedBox(height: 24),

            const Text(
              "Bank Account proof (Cancel Cheque / Pass Book) *",
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 12),

            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Center(
                child: OutlinedButton(
                  onPressed: () {
                    // File picker logic
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 10),
                  ),
                  child: const Text(
                    "Choose File",
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  // Submit logic
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD600),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  "Submit",
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _textField(String hint) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade400),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.black),
          ),
        ),
      ),
    );
  }
}
