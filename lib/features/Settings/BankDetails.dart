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
  bool isLoading = true;
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
        data = response.bankAccRequest ?? [];
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        data = [];
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Bank Details"),
        backgroundColor: Color(0xFFFCD417).withOpacity(0.25),
        foregroundColor: Colors.black,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: EdgeInsetsGeometry.symmetric(
                horizontal: FigmaSize.w(27),
                vertical: FigmaSize.h(11),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.all(FigmaSize.w(0)),
                    child: Text(
                      '''Admin will take upto 7 days to complete this request . kindly do not follow up with customer support before 7 days.''',
                      style: TextStyle(
                        fontSize: FigmaSize.w(11),
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  Divider(),
                  // ── Safe: show empty state when list is empty ──────────────
                  if (data == null || data!.isEmpty)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: FigmaSize.h(40)),
                      child: Center(
                        child: Text(
                          "No bank details found",
                          style: TextStyle(
                            fontSize: FigmaSize.w(13),
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: data!.length,
                      itemBuilder: (context, index) {
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _infoRow("Bank Account Name",   data![index].accountHolderName.toString()),
                            _infoRow("Bank Account Number", data![index].accountNo.toString()),
                            _infoRow("Bank Name",           data![index].bank.toString()),
                            _infoRow("IFSC Code",           data![index].ifsc.toString()),
                            _infoRow("Creation Time",       data![index].createdAt.toString()),
                            _infoRow("Status",              data![index].status.toString()),
                            SizedBox(height: FigmaSize.h(10)),
                            SvgPicture.asset("assets/images/image.svg"),
                            SizedBox(height: FigmaSize.h(17)),
                            Divider(),
                          ],
                        );
                      },
                    ),
                ],
              ),
            ),
      bottomNavigationBar: GradientButton(
        title: "+ Change bank details",
        onTap: () async {
          // ── Reload list when returning from ChangeBankDetailsScreen ───────
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ChangeBankDetailsScreen(),
            ),
          );
          _loadData();
        },
      ),
    );
  }

  Widget _infoRow(String keyText, String valueText) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          child: Text(
            "$keyText",
            style: TextStyle(
              fontSize: FigmaSize.w(14),
              fontWeight: FontWeight.w700,
              color: Colors.black,
              height: 16 / FigmaSize.w(12),
            ),
          ),
        ),
        Text(
          ":  ",
          style: TextStyle(
            fontSize: FigmaSize.w(14),
            fontWeight: FontWeight.w700,
            height: 16 / FigmaSize.w(12),
          ),
        ),
        Expanded(
          child: Text(
            valueText,
            style: TextStyle(
              fontSize: FigmaSize.w(14),
              fontWeight: FontWeight.w500,
              color: Colors.black,
              height: 16 / FigmaSize.w(12),
            ),
          ),
        ),
      ],
    );
  }
}