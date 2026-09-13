// lib/features/Settings/components/SettingsGridComponent.dart
// ── Theme-aware: zero hardcoded colors (all colors live in IconForSetting) ─────
// ── Zero logic changes ────────────────────────────────────────────────────────

import 'package:astrologer_app/core/utils/size_config.dart';
import 'package:astrologer_app/features/Settings/BankDetails.dart';
import 'package:astrologer_app/features/Settings/DownloadForm16A.dart';
import 'package:astrologer_app/features/Settings/GalleryScreen.dart';
import 'package:astrologer_app/features/Settings/ImportantContactScreen.dart';
import 'package:astrologer_app/features/Settings/Invoice.dart';
import 'package:astrologer_app/features/Settings/MyMembership.dart';
import 'package:astrologer_app/features/Settings/PaySlipScreen.dart';
import 'package:astrologer_app/features/Settings/PriceChangeRequest.dart';
import 'package:astrologer_app/features/Settings/ReferAstrologer.dart';
import 'package:astrologer_app/features/Settings/TermsAndConditions.dart';
import 'package:astrologer_app/features/Settings/TrainingVideos.dart';
import 'package:astrologer_app/features/Settings/UpdatePhoneNumber.dart';
import 'package:astrologer_app/features/Settings/UpdateBillingAddress.dart';
import 'package:astrologer_app/features/Settings/components/IconForSetting.dart';
import 'package:flutter/material.dart';

class SettingsIconGrid extends StatelessWidget {
  const SettingsIconGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> menuItems = [
      {
        'icon' : 'phone-call.svg',
        'label': 'Update Phone Number',
        'page' : const Updatephonenumber(),
      },
      // {
      //   'icon' : 'contact-book.svg',
      //   'label': 'Imp. Contacts to Saved',
      //   'page' : const ImportantNumberPage(),
      // },
      {
        'icon' : 'videos.svg',
        'label': 'Training Videos',
        'page' : const TrainingVideosScreen(),
      },
      {
        'icon' : 'terms-and-conditions.svg',
        'label': 'Terms & Conditions',
        'page' : const TermsAndConditionScreen(),
      },
      {
        'icon' : 'bank.svg',
        'label': 'Bank Details',
        'page' : const Bankdetails(),
      },
      {
        'icon' : 'price-tag.svg',
        'label': 'Price Change Request',
        'page' : const Pricechangerequest(),
      },
      // {
      //   'icon' : 'price-tag.svg',
      //   'label': 'Download Form 16A',
      //   'page' : const Downloadform16a(),
      // },
      {
        'icon' : 'download-file.svg',
        'label': 'Pay Slip',
        'page' : const Payslipscreen(),
      },
      {
        'icon' : 'membership.svg',
        'label': 'Membership',
        'page' : const Mymembership(),
      },
      {
        'icon' : 'review.svg',
        'label': 'Refer an Astrologer',
        'page' : const Referastrologer(),
      },
      {
        'icon' : 'gallery.svg',
        'label': 'Gallery',
        'page' : const Galleryscreen(),
      },
      {
        'icon' : 'bill.svg',
        'label': 'Update Billing Address',
        'page' : const UpdateBillingAddress(),
      },
      {
        'icon' : 'invoice.svg',
        'label': 'Invoice',
        'page' : const Invoice(),
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics   : const NeverScrollableScrollPhysics(),
      padding   : EdgeInsets.symmetric(horizontal: FigmaSize.w(10)),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount  : 3,
        mainAxisSpacing : FigmaSize.h(12),
        crossAxisSpacing: FigmaSize.w(21),
        childAspectRatio: 0.88,
      ),
      itemCount  : menuItems.length,
      itemBuilder: (context, index) {
        return IconForSetting(
          iconPath: 'assets/images/${menuItems[index]['icon']}',
          label   : menuItems[index]['label']!,
          onTap   : () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => menuItems[index]['page']),
          ),
        );
      },
    );
  }
}