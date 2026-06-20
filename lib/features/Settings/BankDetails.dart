// lib/features/Settings/BankDetails.dart
// ── Theme-aware: AppColors + AppTheme tokens, zero hardcoded colors ───────────
// ── Zero logic changes ────────────────────────────────────────────────────────

import 'package:astrologer_app/core/config/theme_config.dart';
import 'package:astrologer_app/core/utils/size_config.dart';
import 'package:astrologer_app/core/widgets/ThemeGradientButton.dart';
import 'package:astrologer_app/features/Settings/ChangeBankDetailsScreen.dart';
import 'package:astrologer_app/model/BankAccountRequestModel.dart';
import 'package:astrologer_app/service/apiService.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class Bankdetails extends StatefulWidget {
  const Bankdetails({super.key});

  @override
  State<Bankdetails> createState() => _BankdetailsState();
}

class _BankdetailsState extends State<Bankdetails> {
  bool                 isLoading = true;
  List<BankAccRequest>? data;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    try {
      final response = await ApiService().AstroBankAccountList();
      setState(() {
        data      = response.bankAccRequest ?? [];
        isLoading = false;
      });
    } catch (e) {
      setState(() { data = []; isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        // Colors inherited from AppTheme automatically
        title: const Text('Bank Details'),
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
                  color: AppTheme.primaryYellow))
          : Padding(
              padding: EdgeInsetsGeometry.symmetric(
                horizontal: FigmaSize.w(27),
                vertical  : FigmaSize.h(11),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ── Info text ──────────────────────────────────────────
                  Text(
                    'Admin will take upto 7 days to complete this request. '
                    'Kindly do not follow up with customer support before 7 days.',
                    style: TextStyle(
                      fontSize  : FigmaSize.w(11),
                      fontWeight: FontWeight.w500,
                      color     : c.subText,
                    ),
                  ),
                  Divider(color: c.divider),

                  // ── Empty state ────────────────────────────────────────
                  if (data == null || data!.isEmpty)
                    Padding(
                      padding: EdgeInsets.symmetric(
                          vertical: FigmaSize.h(40)),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.account_balance_outlined,
                                size: 48,
                                color: c.subText.withOpacity(0.35)),
                            SizedBox(height: FigmaSize.h(12)),
                            Text(
                              'No bank details found',
                              style: TextStyle(
                                  fontSize: FigmaSize.w(13),
                                  color   : c.subText),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    // ── Bank details list ────────────────────────────────
                    ListView.builder(
                      shrinkWrap: true,
                      physics   : const NeverScrollableScrollPhysics(),
                      itemCount : data!.length,
                      itemBuilder: (context, index) {
                        final item = data![index];
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _InfoRow(label: 'Bank Account Name',
                                value: item.accountHolderName.toString(), c: c),
                            _InfoRow(label: 'Bank Account Number',
                                value: item.accountNo.toString(), c: c),
                            _InfoRow(label: 'Bank Name',
                                value: item.bank.toString(), c: c),
                            _InfoRow(label: 'IFSC Code',
                                value: item.ifsc.toString(), c: c),
                            _InfoRow(label: 'Creation Time',
                                value: item.createdAt.toString(), c: c),
                            _InfoRow(label: 'Status',
                                value: item.status.toString(), c: c),
                            SizedBox(height: FigmaSize.h(10)),
                            SvgPicture.asset('assets/images/image.svg'),
                            SizedBox(height: FigmaSize.h(17)),
                            Divider(color: c.divider),
                          ],
                        );
                      },
                    ),
                ],
              ),
            ),

      // ── Bottom button ───────────────────────────────────────────────────
      bottomNavigationBar: GradientButton(
        title: '+ Change bank details',
        onTap : () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const ChangeBankDetailsScreen()),
          );
          _loadData();
        },
      ),
    );
  }
}

// ── Info row ──────────────────────────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final String    label;
  final String    value;
  final AppColors c;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.c,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize  : FigmaSize.w(14),
            fontWeight: FontWeight.w700,
            color     : c.text,
            height    : 16 / FigmaSize.w(12),
          ),
        ),
        Text(
          ':  ',
          style: TextStyle(
            fontSize  : FigmaSize.w(14),
            fontWeight: FontWeight.w700,
            color     : c.subText,
            height    : 16 / FigmaSize.w(12),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize  : FigmaSize.w(14),
              fontWeight: FontWeight.w500,
              color     : c.subText,
              height    : 16 / FigmaSize.w(12),
            ),
          ),
        ),
      ],
    );
  }
}