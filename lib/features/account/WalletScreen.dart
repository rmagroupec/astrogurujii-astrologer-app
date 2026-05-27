import 'package:astrologer_app/core/utils/size_config.dart';
import 'package:astrologer_app/model/AstrologerWalletModel.dart';
import 'package:astrologer_app/service/apiService.dart';
import 'package:flutter/material.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {

  bool isLoading = true;
  WalletData? data;

  @override
  void initState() {
    super.initState();

    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final response = await ApiService().GetAstrologerWallet(); // your API
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
    const Color primaryYellow = Color(0xFFFFD700);
    const Color lightCream = Color(0xFFFFFBE6);
    const Color amberBorder = Colors.amber;
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: lightCream,
        elevation: 0,
        leading: const Icon(Icons.arrow_back, color: Colors.black),
        title: const Text(
          'Wallet',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w500),
        ),
      ),
      body: isLoading ? Center(child: CircularProgressIndicator(),) : ListView(
        padding: EdgeInsets.all(FigmaSize.w(16)),
        children: [
          // Top Row: Lifetime and Monthly Earnings
          Row(
            children: [
              Expanded(
                child: _buildEarningCard(
                  label: "Lifetime Earning",
                  amount: "₹ ${data?.lifetimeEarning}",
                  amountColor: Colors.green,
                  borderColor: amberBorder,
                ),
              ),
              SizedBox(width: FigmaSize.w(12)),
              Expanded(
                child: _buildEarningCard(
                  label: "Monthly Earning",
                  amount: "₹ ${data?.pendingEarning}",
                  amountColor: Colors.green,
                  borderColor: amberBorder,
                ),
              ),
            ],
          ),
          SizedBox(height: FigmaSize.h(16)),

          // Weekly Earnings and Rank
          _buildRankCard(amberBorder),

          SizedBox(height: FigmaSize.h(16)),

          // Date Filter Dropdown
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: FigmaSize.w(16),
              vertical: FigmaSize.h(12),
            ),
            decoration: BoxDecoration(
              border: Border.all(color: amberBorder),
              color: Color(0xFFFCD417).withOpacity(0.09),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Today",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: FigmaSize.w(16),
                    color: Colors.black,
                  ),
                ),
                Icon(Icons.arrow_drop_down),
              ],
            ),
          ),
          SizedBox(height: FigmaSize.h(16)),

          // Available Balance and Payable Amount sections
          _buildBalanceCard(
            title: null,
            bgColor: Color(0xFFFCD417).withOpacity(0.09),
          ),
          SizedBox(height: FigmaSize.h(16)),
          _buildBalanceCard(
            title: "Today's Astromall",
            bgColor: Color(0xFFFCD417).withOpacity(0.09),
          ),

          SizedBox(height: FigmaSize.h(40)),

          // Empty State Text
          Center(
            child: Text(
              "No Transactions Available",
              style: TextStyle(
                color: Colors.grey,
                fontSize: FigmaSize.w(16),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget for the top two square cards
  Widget _buildEarningCard({
    required String label,
    required String amount,
    required Color amountColor,
    required Color borderColor,
  }) {
    return Container(
      padding: EdgeInsets.all(FigmaSize.w(12)),
      decoration: BoxDecoration(
        color: Color(0xFFFCD417).withOpacity(0.09),
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: FigmaSize.w(14),
              color: Colors.black,
            ),
          ),
          SizedBox(height: FigmaSize.h(8)),
          Text(
            amount,
            style: TextStyle(
              color: amountColor,
              fontWeight: FontWeight.bold,
              fontSize: FigmaSize.w(18),
            ),
          ),
        ],
      ),
    );
  }

  // Widget for the Weekly Earnings / Rank section
  Widget _buildRankCard(Color borderColor) {
    return Container(
      padding: EdgeInsets.all(FigmaSize.w(12)),
      decoration: BoxDecoration(
        border: Border.all(color: borderColor),
        color: Color(0xFFFCD417).withOpacity(0.09),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Weekly Earnings",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: FigmaSize.h(4)),
              Text(
                "₹ ${data?.weeklyEarning}",
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: FigmaSize.w(18),
                ),
              ),
            ],
          ),
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "Rank",
                    style: TextStyle(
                      color: Colors.amber,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "${data?.rank}",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: FigmaSize.w(18),
                    ),
                  ),
                ],
              ),
              Icon(Icons.chevron_right, size: FigmaSize.w(30)),
            ],
          ),
        ],
      ),
    );
  }

  // Widget for the Balance/Payable rows
  Widget _buildBalanceCard({String? title, required Color bgColor}) {
    return Container(
      padding: EdgeInsets.all(FigmaSize.w(16)),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: FigmaSize.w(14),
                color: Colors.black,
              ),
            ),
            SizedBox(height: FigmaSize.h(12)),
          ],
          Row(
            children: [
              Expanded(child: _balanceItem("Available Balance", "₹ ${data?.todayAvailableBalance}")),
              Expanded(child: _balanceItem("Payable Amount", "₹ ${data?.todayPayableAmount}")),
              Icon(Icons.chevron_right, size: FigmaSize.w(30)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _balanceItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: FigmaSize.w(13),
            color: Colors.black,
          ),
        ),
        SizedBox(height: FigmaSize.h(4)),
        Text(
          value,
          style: TextStyle(
            color: Colors.green,
            fontWeight: FontWeight.bold,
            fontSize: FigmaSize.w(16),
          ),
        ),
      ],
    );
  }
}
