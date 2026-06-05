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
  OnlineStatus? onlineStatus;

  static const _yellow     = Color(0xFFFCD417);
  static const _lightCream = Color(0xFFFFFBE6);
  static const _bgCard     = Color(0xFFFEFBE6);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    try {
      final response = await ApiService().GetAstrologerWallet();
      setState(() {
        data         = response.data;
        onlineStatus = response.onlineStatus;
        isLoading    = false;
      });
    } catch (e) {
      debugPrint('❌ Wallet error: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: _lightCream,
        elevation: 0,
        foregroundColor: Colors.black,
        title: const Text(
          'Wallet',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w500),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: EdgeInsets.all(FigmaSize.w(16)),
                children: [

                  // ── Row 1: Wallet balance + Payable ─────────
                  Row(
                    children: [
                      Expanded(
                        child: _EarningCard(
                          label:  "Total Wallet",
                          amount: "₹ ${data?.myWallet ?? '0'}",
                          icon:   Icons.account_balance_wallet_outlined,
                        ),
                      ),
                      SizedBox(width: FigmaSize.w(12)),
                      Expanded(
                        child: _EarningCard(
                          label:  "Payable Amount",
                          amount: "₹ ${data?.payableAmount ?? '0'}",
                          icon:   Icons.payments_outlined,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: FigmaSize.h(12)),

                  // ── TDS info card ────────────────────────────
                  _TdsCard(
                    tds:        data?.tds        ?? '0',
                    percentage: data?.percentage ?? '0',
                    wallet:     data?.myWallet   ?? '0',
                  ),

                  SizedBox(height: FigmaSize.h(12)),

                  // ── Online status card ───────────────────────
                  if (onlineStatus != null)
                    _OnlineStatusCard(status: onlineStatus!),

                  SizedBox(height: FigmaSize.h(16)),

                  // ── Available / payable detail ───────────────
                  _buildBalanceCard(
                    title:    "Today's Earning",
                    balance:  "₹ ${data?.todayAvailableBalance ?? '0'}",
                    payable:  "₹ ${data?.todayPayableAmount ?? '0'}",
                    bgColor:  _bgCard,
                  ),

                  SizedBox(height: FigmaSize.h(12)),

                  _buildBalanceCard(
                    title:    "Today's Astromall",
                    balance:  "₹ ${data?.todayAstromallAvailableBalance ?? '0'}",
                    payable:  "₹ ${data?.todayAstromallPayableAmount ?? '0'}",
                    bgColor:  _bgCard,
                  ),

                  SizedBox(height: FigmaSize.h(40)),

                  Center(
                    child: Text(
                      "No Transactions Available",
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: FigmaSize.w(14),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // ── Balance detail card ──────────────────────────────────────
  Widget _buildBalanceCard({
    required String title,
    required String balance,
    required String payable,
    required Color bgColor,
  }) {
    return Container(
      padding: EdgeInsets.all(FigmaSize.w(14)),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(color: Colors.amber.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: FigmaSize.w(13),
              color: Colors.black87,
            ),
          ),
          SizedBox(height: FigmaSize.h(10)),
          Row(
            children: [
              Expanded(
                child: _BalanceItem(
                  label: "Available Balance",
                  value: balance,
                ),
              ),
              Expanded(
                child: _BalanceItem(
                  label: "Payable Amount",
                  value: payable,
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.black45),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// SUB-WIDGETS
// ─────────────────────────────────────────────────────────────────

class _EarningCard extends StatelessWidget {
  final String label;
  final String amount;
  final IconData icon;

  const _EarningCard({
    required this.label,
    required this.amount,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(FigmaSize.w(14)),
      decoration: BoxDecoration(
        color: const Color(0xFFFCD417).withOpacity(0.10),
        border: Border.all(color: Colors.amber),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: FigmaSize.w(16), color: Colors.amber.shade700),
              SizedBox(width: FigmaSize.w(6)),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: FigmaSize.w(12),
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: FigmaSize.h(8)),
          Text(
            amount,
            style: TextStyle(
              color: Colors.green.shade700,
              fontWeight: FontWeight.bold,
              fontSize: FigmaSize.w(18),
            ),
          ),
        ],
      ),
    );
  }
}

// ── TDS breakdown card ────────────────────────────────────────────
class _TdsCard extends StatelessWidget {
  final String tds;
  final String percentage;
  final String wallet;

  const _TdsCard({
    required this.tds,
    required this.percentage,
    required this.wallet,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(FigmaSize.w(14)),
      decoration: BoxDecoration(
        color: const Color(0xFFFCD417).withOpacity(0.10),
        border: Border.all(color: Colors.amber),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "TDS Breakdown",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: FigmaSize.w(13),
              color: Colors.black87,
            ),
          ),
          SizedBox(height: FigmaSize.h(10)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _TdsItem(label: "Gross Wallet",    value: "₹ $wallet"),
              _TdsItem(label: "TDS ($percentage%)", value: "- ₹ $tds",
                  valueColor: Colors.red),
              _TdsItem(label: "Net Payable",
                  value: "₹ ${(double.tryParse(wallet) ?? 0) - (double.tryParse(tds) ?? 0)}",
                  valueColor: Colors.green),
            ],
          ),
        ],
      ),
    );
  }
}

class _TdsItem extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _TdsItem({
    required this.label,
    required this.value,
    this.valueColor = Colors.black87,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label,
            style: TextStyle(
                fontSize: FigmaSize.w(10), color: Colors.black54)),
        SizedBox(height: FigmaSize.h(4)),
        Text(value,
            style: TextStyle(
                fontSize: FigmaSize.w(13),
                fontWeight: FontWeight.bold,
                color: valueColor)),
      ],
    );
  }
}

// ── Online status card ────────────────────────────────────────────
class _OnlineStatusCard extends StatelessWidget {
  final OnlineStatus status;
  const _OnlineStatusCard({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(FigmaSize.w(14)),
      decoration: BoxDecoration(
        color: const Color(0xFFFCD417).withOpacity(0.10),
        border: Border.all(color: Colors.amber),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatusDot(label: "Chat",  isOn: status.isChatOnline  == 'on'),
          _StatusDot(label: "Voice", isOn: status.isCallOnline  == 'on'),
          _StatusDot(label: "Video", isOn: status.isVideoOnline == 'on'),
        ],
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  final String label;
  final bool isOn;
  const _StatusDot({required this.label, required this.isOn});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8, height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isOn ? Colors.green : Colors.grey,
          ),
        ),
        SizedBox(width: FigmaSize.w(5)),
        Text(
          label,
          style: TextStyle(
            fontSize: FigmaSize.w(12),
            fontWeight: FontWeight.w500,
            color: isOn ? Colors.green : Colors.grey,
          ),
        ),
      ],
    );
  }
}

// ── Balance item ──────────────────────────────────────────────────
class _BalanceItem extends StatelessWidget {
  final String label;
  final String value;
  const _BalanceItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: FigmaSize.w(11), color: Colors.black54,
                fontWeight: FontWeight.w500)),
        SizedBox(height: FigmaSize.h(4)),
        Text(value,
            style: TextStyle(
                color: Colors.green.shade700,
                fontWeight: FontWeight.bold,
                fontSize: FigmaSize.w(15))),
      ],
    );
  }
}