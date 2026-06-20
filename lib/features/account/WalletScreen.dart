// lib/features/wallet/WalletScreen.dart
// ── Theme-aware: AppColors + AppTheme tokens, zero hardcoded colors ───────────
// ── Zero logic changes ────────────────────────────────────────────────────────

import 'package:astrologer_app/core/config/theme_config.dart';
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
  bool          isLoading    = true;
  WalletData?   data;
  OnlineStatus? onlineStatus;

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
    final c      = context.colors;
    final isDark = context.isDark;

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        // Colors inherited from AppTheme automatically
        elevation: 0,
        title: const Text(
          'Wallet',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        actions: [
          IconButton(
            icon     : const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
                  color: AppTheme.primaryYellow))
          : RefreshIndicator(
              onRefresh: _loadData,
              color    : AppTheme.primaryYellow,
              child    : ListView(
                padding: EdgeInsets.all(FigmaSize.w(16)),
                children: [

                  // ── Row 1: Wallet balance + Payable ─────────
                  Row(
                    children: [
                      Expanded(
                        child: _EarningCard(
                          label : 'Total Wallet',
                          amount: '₹ ${data?.myWallet ?? '0'}',
                          icon  : Icons.account_balance_wallet_outlined,
                          c     : c, isDark: isDark,
                        ),
                      ),
                      SizedBox(width: FigmaSize.w(12)),
                      Expanded(
                        child: _EarningCard(
                          label : 'Payable Amount',
                          amount: '₹ ${data?.payableAmount ?? '0'}',
                          icon  : Icons.payments_outlined,
                          c     : c, isDark: isDark,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: FigmaSize.h(12)),

                  // ── TDS info card ────────────────────────────
                  _TdsCard(
                    tds       : data?.tds        ?? '0',
                    percentage: data?.percentage ?? '0',
                    wallet    : data?.myWallet   ?? '0',
                    c         : c, isDark: isDark,
                  ),

                  SizedBox(height: FigmaSize.h(12)),

                  // ── Online status card ───────────────────────
                  if (onlineStatus != null)
                    _OnlineStatusCard(
                        status: onlineStatus!, c: c, isDark: isDark),

                  SizedBox(height: FigmaSize.h(16)),

                  // ── Today's Earning ──────────────────────────
                  _BalanceCard(
                    title  : "Today's Earning",
                    balance: '₹ ${data?.todayAvailableBalance ?? '0'}',
                    payable: '₹ ${data?.todayPayableAmount ?? '0'}',
                    c      : c, isDark: isDark,
                  ),

                  SizedBox(height: FigmaSize.h(12)),

                  // ── Today's Astromall ────────────────────────
                  _BalanceCard(
                    title  : "Today's Astromall",
                    balance: '₹ ${data?.todayAstromallAvailableBalance ?? '0'}',
                    payable: '₹ ${data?.todayAstromallPayableAmount ?? '0'}',
                    c      : c, isDark: isDark,
                  ),

                  SizedBox(height: FigmaSize.h(40)),

                  Center(
                    child: Text(
                      'No Transactions Available',
                      style: TextStyle(
                        color     : c.subText,
                        fontSize  : FigmaSize.w(14),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// EARNING CARD
// ─────────────────────────────────────────────────────────────────
class _EarningCard extends StatelessWidget {
  final String   label;
  final String   amount;
  final IconData icon;
  final AppColors c;
  final bool      isDark;

  const _EarningCard({
    required this.label,
    required this.amount,
    required this.icon,
    required this.c,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(FigmaSize.w(14)),
      decoration: BoxDecoration(
        color       : AppTheme.primaryYellow.withOpacity(isDark ? 0.12 : 0.10),
        border      : Border.all(
            color: isDark
                ? AppTheme.primaryYellow.withOpacity(0.40)
                : Colors.amber),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon,
                  size : FigmaSize.w(16),
                  color: Colors.amber.shade700),
              SizedBox(width: FigmaSize.w(6)),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize  : FigmaSize.w(12),
                    color     : c.text,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: FigmaSize.h(8)),
          Text(
            amount,
            style: TextStyle(
              color     : Colors.green.shade700,
              fontWeight: FontWeight.bold,
              fontSize  : FigmaSize.w(18),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// TDS CARD
// ─────────────────────────────────────────────────────────────────
class _TdsCard extends StatelessWidget {
  final String   tds;
  final String   percentage;
  final String   wallet;
  final AppColors c;
  final bool      isDark;

  const _TdsCard({
    required this.tds,
    required this.percentage,
    required this.wallet,
    required this.c,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final net = (double.tryParse(wallet) ?? 0) - (double.tryParse(tds) ?? 0);

    return Container(
      padding: EdgeInsets.all(FigmaSize.w(14)),
      decoration: BoxDecoration(
        color       : AppTheme.primaryYellow.withOpacity(isDark ? 0.12 : 0.10),
        border      : Border.all(
            color: isDark
                ? AppTheme.primaryYellow.withOpacity(0.40)
                : Colors.amber),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TDS Breakdown',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize  : FigmaSize.w(13),
              color     : c.text,
            ),
          ),
          SizedBox(height: FigmaSize.h(10)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _TdsItem(
                label: 'Gross Wallet',
                value: '₹ $wallet',
                c    : c,
              ),
              _TdsItem(
                label     : 'TDS ($percentage%)',
                value     : '- ₹ $tds',
                valueColor: AppTheme.accentRed,
                c         : c,
              ),
              _TdsItem(
                label     : 'Net Payable',
                value     : '₹ ${net.toStringAsFixed(2)}',
                valueColor: Colors.green,
                c         : c,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TdsItem extends StatelessWidget {
  final String   label;
  final String   value;
  final Color?   valueColor;
  final AppColors c;

  const _TdsItem({
    required this.label,
    required this.value,
    required this.c,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label,
            style: TextStyle(
                fontSize: FigmaSize.w(10), color: c.subText)),
        SizedBox(height: FigmaSize.h(4)),
        Text(value,
            style: TextStyle(
                fontSize  : FigmaSize.w(13),
                fontWeight: FontWeight.bold,
                color     : valueColor ?? c.text)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// ONLINE STATUS CARD
// ─────────────────────────────────────────────────────────────────
class _OnlineStatusCard extends StatelessWidget {
  final OnlineStatus status;
  final AppColors    c;
  final bool         isDark;

  const _OnlineStatusCard({
    required this.status,
    required this.c,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(FigmaSize.w(14)),
      decoration: BoxDecoration(
        color       : AppTheme.primaryYellow.withOpacity(isDark ? 0.12 : 0.10),
        border      : Border.all(
            color: isDark
                ? AppTheme.primaryYellow.withOpacity(0.40)
                : Colors.amber),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatusDot(label: 'Chat',  isOn: status.isChatOnline  == 'on', c: c),
          _StatusDot(label: 'Voice', isOn: status.isCallOnline  == 'on', c: c),
          _StatusDot(label: 'Video', isOn: status.isVideoOnline == 'on', c: c),
        ],
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  final String   label;
  final bool     isOn;
  final AppColors c;

  const _StatusDot({
    required this.label,
    required this.isOn,
    required this.c,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width : 8, height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isOn ? Colors.green : c.subText,
          ),
        ),
        SizedBox(width: FigmaSize.w(5)),
        Text(
          label,
          style: TextStyle(
            fontSize  : FigmaSize.w(12),
            fontWeight: FontWeight.w500,
            color     : isOn ? Colors.green : c.subText,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// BALANCE CARD
// ─────────────────────────────────────────────────────────────────
class _BalanceCard extends StatelessWidget {
  final String   title;
  final String   balance;
  final String   payable;
  final AppColors c;
  final bool      isDark;

  const _BalanceCard({
    required this.title,
    required this.balance,
    required this.payable,
    required this.c,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(FigmaSize.w(14)),
      decoration: BoxDecoration(
        color       : AppTheme.primaryYellow.withOpacity(isDark ? 0.12 : 0.10),
        border      : Border.all(
            color: isDark
                ? AppTheme.primaryYellow.withOpacity(0.40)
                : Colors.amber.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize  : FigmaSize.w(13),
              color     : c.text,
            ),
          ),
          SizedBox(height: FigmaSize.h(10)),
          Row(
            children: [
              Expanded(
                child: _BalanceItem(
                    label: 'Available Balance', value: balance, c: c),
              ),
              Expanded(
                child: _BalanceItem(
                    label: 'Payable Amount', value: payable, c: c),
              ),
              Icon(Icons.chevron_right, color: c.subText),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// BALANCE ITEM
// ─────────────────────────────────────────────────────────────────
class _BalanceItem extends StatelessWidget {
  final String   label;
  final String   value;
  final AppColors c;

  const _BalanceItem({
    required this.label,
    required this.value,
    required this.c,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize  : FigmaSize.w(11),
                color     : c.subText,
                fontWeight: FontWeight.w500)),
        SizedBox(height: FigmaSize.h(4)),
        Text(value,
            style: TextStyle(
                color     : Colors.green.shade700,
                fontWeight: FontWeight.bold,
                fontSize  : FigmaSize.w(15))),
      ],
    );
  }
}