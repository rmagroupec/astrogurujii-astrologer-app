// lib/features/account/WalletScreen.dart

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
  bool                    isLoading    = true;
  WalletData?             data;
  OnlineStatus?           onlineStatus;
  List<WalletTransaction> transactions = [];

  // ── Filter state ─────────────────────────────────────────────────
  String     _selectedType = 'all'; // all | chat | audio | video | other
  DateTime?  _fromDate;
  DateTime?  _toDate;

  static const _typeOptions = <String, String>{
    'all'  : 'All',
    'chat' : 'Chat',
    'audio': 'Voice',
    'video': 'Video',
    'other': 'Others',
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  String? _fmt(DateTime? d) => d == null
      ? null
      : '${d.year.toString().padLeft(4,'0')}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    try {
      final walletResp = await ApiService().GetAstrologerWallet();
      final txResp     = await ApiService().GetAstrologerWalletTransaction(
        type    : _selectedType,
        fromDate: _fmt(_fromDate),
        toDate  : _fmt(_toDate),
      );

      setState(() {
        data         = walletResp.data;
        onlineStatus = walletResp.onlineStatus;
        transactions = txResp.results;
        isLoading    = false;
      });
    } catch (e) {
      debugPrint('WalletScreen error: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> _pickDateRange() async {
    final now   = DateTime.now();
    final range = await showDateRangePicker(
      context     : context,
      firstDate   : DateTime(now.year - 2),
      lastDate    : now,
      initialDateRange: (_fromDate != null && _toDate != null)
          ? DateTimeRange(start: _fromDate!, end: _toDate!)
          : null,
    );
    if (range != null) {
      setState(() {
        _fromDate = range.start;
        _toDate   = range.end;
      });
      _loadData();
    }
  }

  void _clearDateRange() {
    setState(() { _fromDate = null; _toDate = null; });
    _loadData();
  }

  void _showBreakup() {
    if (data == null) return;
    showModalBottomSheet(
      context           : context,
      isScrollControlled: true,
      backgroundColor   : Colors.transparent,
      builder           : (_) => _EarningBreakupSheet(data: data!),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c      = context.colors;
    final isDark = context.isDark;

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        elevation: 0,
        title: const Text('Wallet', style: TextStyle(fontWeight: FontWeight.w500)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: AppTheme.primaryYellow))
          : RefreshIndicator(
              onRefresh: _loadData,
              color    : AppTheme.primaryYellow,
              child    : ListView(
                padding: EdgeInsets.all(FigmaSize.w(16)),
                children: [

                  Row(
                    children: [
                      Expanded(
                        child: _EarningCard(
                          label : 'Available Balance',
                          amount: '₹ ${data?.myWallet ?? '0'}',
                          icon  : Icons.account_balance_wallet_outlined,
                          c: c, isDark: isDark, onTap: _showBreakup,
                        ),
                      ),
                      SizedBox(width: FigmaSize.w(12)),
                      Expanded(
                        child: _EarningCard(
                          label : 'Payable Amount',
                          amount: '₹ ${data?.payableAmount ?? '0'}',
                          icon  : Icons.payments_outlined,
                          c: c, isDark: isDark, onTap: _showBreakup,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: FigmaSize.h(12)),

                  _TdsCard(
                    tds       : data?.tds        ?? '0',
                    percentage: data?.percentage ?? '0',
                    wallet    : data?.myWallet   ?? '0',
                    c: c, isDark: isDark,
                  ),

                  SizedBox(height: FigmaSize.h(12)),
                  if ((data?.todayAdminDeductedBoost ?? 0) > 0 || (data?.todayEmergencyEarnings ?? 0) > 0)
  Padding(
    padding: EdgeInsets.only(top: FigmaSize.h(12)),
    child: _BoostEmergencyCard(data: data!, c: c, isDark: isDark),
  ),
 SizedBox(height: FigmaSize.h(12)),
                  if (onlineStatus != null)
                    _OnlineStatusCard(status: onlineStatus!, c: c, isDark: isDark),

                  SizedBox(height: FigmaSize.h(16)),

                  _BalanceCard(
                    title  : "Today's Earning",
                    balance: '₹ ${data?.todayAvailableBalance ?? '0'}',
                    payable: '₹ ${data?.todayPayableAmount    ?? '0'}',
                    c: c, isDark: isDark, onTap: _showBreakup,
                  ),

                  SizedBox(height: FigmaSize.h(12)),

                  _BalanceCard(
                    title  : "Today's Astromall",
                    balance: '₹ ${data?.todayAstromallAvailableBalance ?? '0'}',
                    payable: '₹ ${data?.todayAstromallPayableAmount    ?? '0'}',
                    c: c, isDark: isDark, onTap: _showBreakup,
                  ),

                  SizedBox(height: FigmaSize.h(20)),

                                   Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent Transactions',
                        style: TextStyle(fontSize: FigmaSize.w(16), fontWeight: FontWeight.bold, color: c.text),
                      ),
                      GestureDetector(
                        onTap: _pickDateRange,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.calendar_today_outlined, size: 16, color: c.subText),
                            SizedBox(width: FigmaSize.w(4)),
                            Text(
                              (_fromDate != null && _toDate != null)
                                  ? '${_fmt(_fromDate)} – ${_fmt(_toDate)}'
                                  : 'Filter by date',
                              style: TextStyle(fontSize: FigmaSize.w(12), color: c.subText),
                            ),
                            if (_fromDate != null) ...[
                              SizedBox(width: FigmaSize.w(4)),
                              GestureDetector(
                                onTap: _clearDateRange,
                                child: Icon(Icons.close, size: 14, color: c.subText),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: FigmaSize.h(10)),

                  // ── Type filter chips ────────────────────────────────
                  SizedBox(
                    height: FigmaSize.h(36),
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: _typeOptions.entries.map((e) {
                        final selected = _selectedType == e.key;
                        return Padding(
                          padding: EdgeInsets.only(right: FigmaSize.w(8)),
                          child: ChoiceChip(
                            label: Text(e.value, style: TextStyle(
                              fontSize  : FigmaSize.w(12),
                              fontWeight: FontWeight.w600,
                              color     : selected ? Colors.black : c.text,
                            )),
                            selected       : selected,
                            selectedColor  : AppTheme.primaryYellow,
                            backgroundColor: c.surface,
                            side: BorderSide(color: selected ? AppTheme.primaryYellow : c.divider),
                            onSelected: (_) {
                              setState(() => _selectedType = e.key);
                              _loadData();
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  SizedBox(height: FigmaSize.h(12)),
                  Divider(color: c.divider),
                  SizedBox(height: FigmaSize.h(8)),

                                   if (transactions.isEmpty)
                    Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: FigmaSize.h(24)),
                        child: Text(
                          (_selectedType != 'all' || _fromDate != null)
                              ? 'No transactions match this filter'
                              : 'No Transactions Available',
                          style: TextStyle(color: c.subText, fontWeight: FontWeight.w500),
                        ),
                      ),
                    )
                  else
                    ...transactions.map((t) => _TransactionCard(item: t, c: c, isDark: isDark)),
                ],
              ),
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// TRANSACTION CARD
// ─────────────────────────────────────────────────────────────────
// Replace _TransactionCard in WalletScreen.dart with this

class _TransactionCard extends StatelessWidget {
  final WalletTransaction item;
  final AppColors         c;
  final bool              isDark;

  const _TransactionCard({required this.item, required this.c, required this.isDark});

  bool get _isCredit => item.type.toLowerCase() == 'credit';

  // "Chat" / "Video Call" / "Voice Call"
  String get _typeLabel {
    final n = item.note.trim().toLowerCase();
    if (n == 'chat')  return 'Chat';
    if (n == 'video') return 'Video Call';
    if (n == 'audio') return 'Voice Call';
    if (n == 'admin') return 'Admin';
    if (n == 'bank')  return 'Bank Transfer';
    if (n == 'refer') return 'Referral';
    return item.note.isNotEmpty ? item.note : 'Transaction';
  }

  Color get _typeColor {
    final n = item.note.trim().toLowerCase();
    if (n == 'chat')  return const Color(0xFFE57373); // pinkish-red like image
    if (n == 'video') return const Color(0xFF7B1FA2);
    if (n == 'audio') return const Color(0xFF1565C0);
    return const Color(0xFFE65100);
  }

  // "Chat with Nihaar(AT-ZY4R63) for 5 minutes"
 String get _description {
  final n        = item.note.trim().toLowerCase();
  final name     = item.userName.isNotEmpty ? item.userName : 'User';
  final duration = item.callDuration > 0 ? ' for ${item.callDuration} minutes' : '';

  if (n == 'chat')  return 'Chat with $name$duration';
  if (n == 'video') return 'Video with $name$duration';
  if (n == 'audio') return 'Call with $name$duration';
  if (n == 'admin') return 'Admin Credit';
  if (n == 'bank')  return 'Bank Transfer';
  if (n == 'refer') return 'Referral Bonus';
  return name;
}

  // "12 Jun 26, 02:22 PM"
  String get _formattedDate {
    try {
      final dt = DateTime.parse(item.createdDate).toLocal();
      const months = ['Jan','Feb','Mar','Apr','May','Jun',
                      'Jul','Aug','Sep','Oct','Nov','Dec'];
      final h   = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final min = dt.minute.toString().padLeft(2, '0');
      final p   = dt.hour >= 12 ? 'PM' : 'AM';
      return '${dt.day} ${months[dt.month - 1]} ${dt.year.toString().substring(2)}, '
             '${h.toString().padLeft(2,'0')}:$min $p';
    } catch (_) {
      return item.createdDate;
    }
  }

  // short order id like "#356099143"
  String get _shortId {
    final id = item.id.isNotEmpty ? item.id : item.channelId;
    if (id.isEmpty) return '';
    // use last 9 chars as numeric-style ID
    final short = id.length > 9 ? id.substring(id.length - 9) : id;
    return '#$short';
  }

  @override
  Widget build(BuildContext context) {
    final amountColor = _isCredit ? const Color(0xFF2E7D32) : Colors.red;
    final hasUserId   = item.userId.isNotEmpty;

    return Container(
      margin: EdgeInsets.only(bottom: FigmaSize.h(1)),
      decoration: BoxDecoration(
        color : c.surface,
        border: Border(bottom: BorderSide(color: c.divider)),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: FigmaSize.w(16),
        vertical  : FigmaSize.h(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Call type label (Chat / Video Call) ────────────────────
          Text(
            _typeLabel,
            style: TextStyle(
              fontSize  : FigmaSize.w(13),
              fontWeight: FontWeight.w700,
              color     : _typeColor,
            ),
          ),

          SizedBox(height: FigmaSize.h(2)),

          // ── Order / Transaction ID ─────────────────────────────────
          if (_shortId.isNotEmpty)
            Text(
              _shortId,
              style: TextStyle(
                fontSize : FigmaSize.w(12),
                color    : c.text,
                fontWeight: FontWeight.w500,
              ),
            ),

          SizedBox(height: FigmaSize.h(4)),

          // ── Description + Amount row ───────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  _description,
                  style: TextStyle(
                    fontSize : FigmaSize.w(12),
                    color    : c.text,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              SizedBox(width: FigmaSize.w(8)),
              Text(
                '${_isCredit ? '+' : '-'}₹${item.amount}',
                style: TextStyle(
                  fontSize  : FigmaSize.w(14),
                  fontWeight: FontWeight.w700,
                  color     : amountColor,
                ),
              ),
            ],
          ),

          SizedBox(height: FigmaSize.h(4)),

          // ── UserId + Date row ──────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (hasUserId)
                Text(
                  'UserId : ${item.userId}',
                  style: TextStyle(fontSize: FigmaSize.w(11), color: c.subText),
                ),
              Text(
                _formattedDate,
                style: TextStyle(fontSize: FigmaSize.w(11), color: c.subText),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// EARNING BREAKUP SHEET
// ─────────────────────────────────────────────────────────────────
class _EarningBreakupSheet extends StatelessWidget {
  final WalletData data;
  const _EarningBreakupSheet({required this.data});

  @override
  Widget build(BuildContext context) {
    final isDark     = Theme.of(context).brightness == Brightness.dark;
    final wallet     = double.tryParse(data.myWallet)      ?? 0;
    final tds        = double.tryParse(data.tds)           ?? 0;
    final payable    = double.tryParse(data.payableAmount) ?? 0;
    final percentage = data.percentage;
    final pgCharge   = wallet * 0.025;
    final subTotal   = wallet - pgCharge;
    final bg         = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final textCol    = isDark ? Colors.white            : const Color(0xFF1A1A1A);
    final subCol     = isDark ? Colors.white60          : Colors.black54;
    final green      = const Color(0xFF4CAF50);
    final red        = const Color(0xFFE53935);
    final orange     = const Color(0xFFFF6D00);

    return Container(
      margin    : const EdgeInsets.fromLTRB(0, 60, 0, 0),
      decoration: BoxDecoration(color: bg, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text('Earning Breakup',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: orange))),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 32, height: 32,
                          decoration: BoxDecoration(color: isDark ? Colors.white12 : Colors.black12, shape: BoxShape.circle),
                          child: Icon(Icons.close, size: 18, color: textCol),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _SheetRow(label: 'Available Balance:', value: '₹${wallet.toStringAsFixed(0)}',
                      labelStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textCol),
                      valueColor: green, valueFontSize: 18),
                  const SizedBox(height: 12),
                  _SheetDetailRow(label: 'PG Charge:',
                      subtitle: '2.5% charge deducted by Payment Gateways for\naccepting online payments',
                      value: '- ₹${pgCharge.toStringAsFixed(0)}',
                      valueColor: red, textCol: textCol, subCol: subCol),
                  Divider(color: isDark ? Colors.white12 : Colors.black12, height: 24),
                  _SheetRow(label: 'Sub Total:', value: '₹${subTotal.toStringAsFixed(0)}',
                      labelStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textCol),
                      valueColor: green, valueFontSize: 18),
                  const SizedBox(height: 12),
                  _SheetDetailRow(label: 'Maintenance Fee:',
                      subtitle: '$percentage% of subtotal. Platform maintenance fee\ndeducted as per service agreement',
                      value: '- ₹${tds.toStringAsFixed(0)}',
                      valueColor: red, textCol: textCol, subCol: subCol),
                  const SizedBox(height: 10),
                  _SheetDetailRow(label: 'GST:',
                      subtitle: 'GST certificate mandatory for astrologers who\nearn more than INR 20 lacs per year',
                      value: '₹0',
                      valueColor: green, textCol: textCol, subCol: subCol),
                  Divider(color: isDark ? Colors.white12 : Colors.black12, height: 24),
                  _SheetRow(label: 'Payable Amount:', value: '₹${payable.toStringAsFixed(0)}',
                      labelStyle: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: green),
                      valueColor: green, valueFontSize: 22),
                  const SizedBox(height: 6),
                  Text('Final Amount that gets transferred to your bank\naccount on payout date',
                      style: TextStyle(fontSize: 12, color: subCol)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetRow extends StatelessWidget {
  final String label, value;
  final TextStyle labelStyle;
  final Color valueColor;
  final double valueFontSize;
  const _SheetRow({required this.label, required this.value, required this.labelStyle,
      required this.valueColor, required this.valueFontSize});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: labelStyle),
      Text(value, style: TextStyle(fontSize: valueFontSize, fontWeight: FontWeight.w700, color: valueColor)),
    ],
  );
}

class _SheetDetailRow extends StatelessWidget {
  final String label, subtitle, value;
  final Color  valueColor, textCol, subCol;
  const _SheetDetailRow({required this.label, required this.subtitle, required this.value,
      required this.valueColor, required this.textCol, required this.subCol});

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textCol)),
            const SizedBox(height: 3),
            Text(subtitle, style: TextStyle(fontSize: 11, color: subCol, height: 1.4)),
          ],
        ),
      ),
      const SizedBox(width: 12),
      Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: valueColor)),
    ],
  );
}

// ─────────────────────────────────────────────────────────────────
// EARNING CARD
// ─────────────────────────────────────────────────────────────────
class _EarningCard extends StatelessWidget {
  final String label, amount;
  final IconData icon;
  final AppColors c;
  final bool isDark;
  final VoidCallback onTap;
  const _EarningCard({required this.label, required this.amount, required this.icon,
      required this.c, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: EdgeInsets.all(FigmaSize.w(14)),
      decoration: BoxDecoration(
        color : AppTheme.primaryYellow.withOpacity(isDark ? 0.12 : 0.10),
        border: Border.all(color: isDark ? AppTheme.primaryYellow.withOpacity(0.40) : Colors.amber),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: FigmaSize.w(16), color: Colors.amber.shade700),
            SizedBox(width: FigmaSize.w(6)),
            Expanded(child: Text(label,
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: FigmaSize.w(12), color: c.text))),
            Icon(Icons.chevron_right, size: 16, color: c.subText),
          ]),
          SizedBox(height: FigmaSize.h(8)),
          Text(amount, style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold, fontSize: FigmaSize.w(18))),
        ],
      ),
    ),
  );
}

class _BoostEmergencyCard extends StatelessWidget {
  final WalletData data;
  final AppColors  c;
  final bool       isDark;
  const _BoostEmergencyCard({required this.data, required this.c, required this.isDark});

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.all(FigmaSize.w(14)),
    decoration: BoxDecoration(
      color : AppTheme.primaryYellow.withOpacity(isDark ? 0.12 : 0.10),
      border: Border.all(color: isDark ? AppTheme.primaryYellow.withOpacity(0.40) : Colors.amber),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Boost & Emergency Impact (Today)',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: FigmaSize.w(13), color: c.text)),
        SizedBox(height: FigmaSize.h(10)),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _MiniStat(
              label: 'From Emergency Calls',
              value: '₹ ${data.todayEmergencyEarnings.toStringAsFixed(2)}',
              c: c,
            ),
            _MiniStat(
              label: 'Extra Admin Cut (Boost)',
              value: '₹ ${data.todayAdminDeductedBoost.toStringAsFixed(2)}',
              c: c,
              valueColor: AppTheme.accentRed,
            ),
          ],
        ),
        SizedBox(height: FigmaSize.h(6)),
        Text(
          'Boost increases the platform\'s commission share on your active '
          'boosted service (chat/call/video) but never changes what your '
          'client pays. Emergency mode doubles your rate for clients — you '
          'earn more per minute while it\'s active.',
          style: TextStyle(fontSize: FigmaSize.w(11), color: c.subText, height: 1.4),
        ),
      ],
    ),
  );
}

class _MiniStat extends StatelessWidget {
  final String label, value;
  final AppColors c;
  final Color? valueColor;
  const _MiniStat({required this.label, required this.value, required this.c, this.valueColor});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: FigmaSize.w(10), color: c.subText)),
        SizedBox(height: FigmaSize.h(4)),
        Text(value, style: TextStyle(
          fontSize: FigmaSize.w(13), fontWeight: FontWeight.bold,
          color: valueColor ?? c.text,
        )),
      ],
    ),
  );
}
// ─────────────────────────────────────────────────────────────────
// TDS CARD
// ─────────────────────────────────────────────────────────────────
class _TdsCard extends StatelessWidget {
  final String tds, percentage, wallet;
  final AppColors c;
  final bool isDark;
  const _TdsCard({required this.tds, required this.percentage, required this.wallet,
      required this.c, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final net = (double.tryParse(wallet) ?? 0) - (double.tryParse(tds) ?? 0);
    return Container(
      padding: EdgeInsets.all(FigmaSize.w(14)),
      decoration: BoxDecoration(
        color : AppTheme.primaryYellow.withOpacity(isDark ? 0.12 : 0.10),
        border: Border.all(color: isDark ? AppTheme.primaryYellow.withOpacity(0.40) : Colors.amber),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Maintenance Breakdown',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: FigmaSize.w(13), color: c.text)),
          SizedBox(height: FigmaSize.h(10)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _TdsItem(label: 'Gross Wallet',              value: '₹ $wallet',                   c: c),
              _TdsItem(label: 'Maintenance ($percentage%)', value: '- ₹ $tds',
                  valueColor: AppTheme.accentRed, c: c),
              _TdsItem(label: 'Net Payable',               value: '₹ ${net.toStringAsFixed(2)}',
                  valueColor: Colors.green, c: c),
            ],
          ),
        ],
      ),
    );
  }
}

class _TdsItem extends StatelessWidget {
  final String label, value;
  final Color? valueColor;
  final AppColors c;
  const _TdsItem({required this.label, required this.value, required this.c, this.valueColor});

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(label, style: TextStyle(fontSize: FigmaSize.w(10), color: c.subText)),
      SizedBox(height: FigmaSize.h(4)),
      Text(value, style: TextStyle(fontSize: FigmaSize.w(13), fontWeight: FontWeight.bold, color: valueColor ?? c.text)),
    ],
  );
}

// ─────────────────────────────────────────────────────────────────
// ONLINE STATUS CARD
// ─────────────────────────────────────────────────────────────────
class _OnlineStatusCard extends StatelessWidget {
  final OnlineStatus status;
  final AppColors c;
  final bool isDark;
  const _OnlineStatusCard({required this.status, required this.c, required this.isDark});

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.all(FigmaSize.w(14)),
    decoration: BoxDecoration(
      color : AppTheme.primaryYellow.withOpacity(isDark ? 0.12 : 0.10),
      border: Border.all(color: isDark ? AppTheme.primaryYellow.withOpacity(0.40) : Colors.amber),
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

class _StatusDot extends StatelessWidget {
  final String label;
  final bool isOn;
  final AppColors c;
  const _StatusDot({required this.label, required this.isOn, required this.c});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(width: 8, height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: isOn ? Colors.green : c.subText)),
      SizedBox(width: FigmaSize.w(5)),
      Text(label, style: TextStyle(fontSize: FigmaSize.w(12), fontWeight: FontWeight.w500,
          color: isOn ? Colors.green : c.subText)),
    ],
  );
}

// ─────────────────────────────────────────────────────────────────
// BALANCE CARD
// ─────────────────────────────────────────────────────────────────
class _BalanceCard extends StatelessWidget {
  final String title, balance, payable;
  final AppColors c;
  final bool isDark;
  final VoidCallback onTap;
  const _BalanceCard({required this.title, required this.balance, required this.payable,
      required this.c, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: EdgeInsets.all(FigmaSize.w(14)),
      decoration: BoxDecoration(
        color : AppTheme.primaryYellow.withOpacity(isDark ? 0.12 : 0.10),
        border: Border.all(color: isDark ? AppTheme.primaryYellow.withOpacity(0.40) : Colors.amber.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: FigmaSize.w(13), color: c.text)),
          SizedBox(height: FigmaSize.h(10)),
          Row(
            children: [
              Expanded(child: _BalanceItem(label: 'Available Balance', value: balance, c: c)),
              Expanded(child: _BalanceItem(label: 'Payable Amount',    value: payable, c: c)),
              Icon(Icons.chevron_right, color: c.subText),
            ],
          ),
        ],
      ),
    ),
  );
}

class _BalanceItem extends StatelessWidget {
  final String label, value;
  final AppColors c;
  const _BalanceItem({required this.label, required this.value, required this.c});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: TextStyle(fontSize: FigmaSize.w(11), color: c.subText, fontWeight: FontWeight.w500)),
      SizedBox(height: FigmaSize.h(4)),
      Text(value, style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold, fontSize: FigmaSize.w(15))),
    ],
  );
}

// ─────────────────────────────────────────────────────────────────
// MODELS  (in AstrologerWalletModel.dart — shown here for reference)
// ─────────────────────────────────────────────────────────────────
// TransactionListResponse1 and WalletTransaction must be in
// lib/model/AstrologerWalletModel.dart — NOT here.