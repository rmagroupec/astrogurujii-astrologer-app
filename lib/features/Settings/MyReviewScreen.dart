// lib/features/reviews/MyReviewsScreen.dart
// ── Theme-aware: AppColors + AppTheme tokens, zero hardcoded colors ───────────
// ── Responsive: FigmaSize preserved throughout ────────────────────────────────

import 'package:astrologer_app/core/config/theme_config.dart';
import 'package:astrologer_app/core/utils/size_config.dart';
import 'package:astrologer_app/model/ratingListModel.dart';
import 'package:astrologer_app/service/apiService.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class MyReviewsScreen extends StatefulWidget {
  const MyReviewsScreen({super.key});

  @override
  State<MyReviewsScreen> createState() => _MyReviewsScreenState();
}

class _MyReviewsScreenState extends State<MyReviewsScreen> {
  bool             isLoading = true;
  List<RatingItem> ratings   = [];

  @override
  void initState() {
    super.initState();
    _fetchRatings();
  }

  Future<void> _fetchRatings() async {
    try {
      final response = await ApiService().getReviewList();
      setState(() {
        ratings   = response.results;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      debugPrint('Rating API Error: $e');
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
          'My Reviews',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          // ── Pinned badge ──────────────────────────────────────────────
          Container(
            margin : EdgeInsets.only(right: FigmaSize.w(12)),
            padding: EdgeInsets.symmetric(
              horizontal: FigmaSize.w(14),
              vertical  : FigmaSize.h(5),
            ),
            decoration: BoxDecoration(
              color       : AppTheme.primaryYellow,
              borderRadius: BorderRadius.circular(20),
              border      : Border.all(
                color: Colors.black.withOpacity(0.10),
              ),
            ),
            child: Row(
              children: [
                SvgPicture.asset('assets/images/office-push-pin.svg'),
                SizedBox(width: FigmaSize.w(4)),
                Text(
                  'Pinned',
                  style: TextStyle(
                    fontSize  : FigmaSize.w(10),
                    fontWeight: FontWeight.w600,
                    color     : Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),

      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
                  color: AppTheme.primaryYellow))
          : RefreshIndicator(
              onRefresh: _fetchRatings,
              color    : AppTheme.primaryYellow,
              child    : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(FigmaSize.w(16)),
                child  : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // ── Flagged info row ────────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Flagged reviews ',
                              style: TextStyle(
                                fontSize  : FigmaSize.w(13),
                                fontWeight: FontWeight.w500,
                                color     : c.text,
                              ),
                            ),
                            Text(
                              '(excluding PO)',
                              style: TextStyle(
                                fontSize  : FigmaSize.w(9),
                                fontWeight: FontWeight.w500,
                                color     : c.subText,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '0/10',
                          style: TextStyle(
                            fontSize  : FigmaSize.w(13),
                            fontWeight: FontWeight.w600,
                            color     : c.text,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: FigmaSize.h(6)),

                    // ── Progress bar ────────────────────────────────────
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value          : 0.0,
                        minHeight      : FigmaSize.h(11),
                        backgroundColor: AppTheme.primaryYellow.withOpacity(
                            isDark ? 0.15 : 0.25),
                        valueColor     : AlwaysStoppedAnimation<Color>(
                          AppTheme.primaryYellow,
                        ),
                      ),
                    ),
                    SizedBox(height: FigmaSize.h(8)),

                    Text(
                      'System gives you Maximum 10 flags for your reviews every month. '
                      'Used balance will get reset rest day of the month',
                      style: TextStyle(
                        fontSize  : FigmaSize.w(10),
                        color     : c.subText,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    SizedBox(height: FigmaSize.h(16)),

                    // ── Filter chips ────────────────────────────────────
                    Row(
                      children: [
                        _FilterChip(label: 'ALL ⭐', c: c),
                        SizedBox(width: FigmaSize.w(8)),
                        _FilterChip(
                          label  : 'Astromall',
                          iconPath: 'assets/images/shopping-cart.svg',
                          c      : c,
                        ),
                        SizedBox(width: FigmaSize.w(8)),
                        _FilterChip(
                          label  : 'Pinned',
                          iconPath: 'assets/images/office-push-pin.svg',
                          c      : c,
                        ),
                      ],
                    ),

                    SizedBox(height: FigmaSize.h(16)),

                    // ── Review cards ────────────────────────────────────
                    if (ratings.isEmpty)
                      Center(
                        child: Padding(
                          padding: EdgeInsets.only(top: FigmaSize.h(40)),
                          child: Column(
                            children: [
                              Icon(Icons.rate_review_outlined,
                                  size : 56,
                                  color: c.subText.withOpacity(0.35)),
                              SizedBox(height: FigmaSize.h(12)),
                              Text('No reviews yet',
                                  style: TextStyle(
                                      color   : c.subText,
                                      fontSize: FigmaSize.w(14))),
                            ],
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics   : const NeverScrollableScrollPhysics(),
                        itemCount : ratings.length,
                        itemBuilder: (_, index) => _ReviewCard(
                          rating: ratings[index],
                          c     : c,
                          isDark: isDark,
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}

// ── Filter chip ───────────────────────────────────────────────────────────────
class _FilterChip extends StatelessWidget {
  final String  label;
  final String? iconPath;
  final AppColors c;

  const _FilterChip({required this.label, required this.c, this.iconPath});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: FigmaSize.w(12), vertical: FigmaSize.h(6)),
      decoration: BoxDecoration(
        color       : AppTheme.primaryYellow.withOpacity(
            context.isDark ? 0.15 : 0.0),
        border      : Border.all(color: AppTheme.primaryYellow),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (iconPath != null) ...[
            SvgPicture.asset(iconPath!,
                width : FigmaSize.w(12),
                height: FigmaSize.h(12)),
            SizedBox(width: FigmaSize.w(4)),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize  : FigmaSize.w(12),
              color     : c.text,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Review card ───────────────────────────────────────────────────────────────
class _ReviewCard extends StatelessWidget {
  final RatingItem rating;
  final AppColors  c;
  final bool       isDark;

  const _ReviewCard({
    required this.rating,
    required this.c,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin : EdgeInsets.only(bottom: FigmaSize.h(12)),
      padding: EdgeInsets.all(FigmaSize.w(12)),
      decoration: BoxDecoration(
        color       : c.surface,
        border      : Border.all(color: c.border),
        borderRadius: BorderRadius.circular(FigmaSize.w(12)),
        boxShadow   : isDark
            ? []
            : [
                BoxShadow(
                  color     : Colors.black.withOpacity(0.04),
                  blurRadius: 6,
                  offset    : const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Order ID ──────────────────────────────────────────────────
          Text(
            'Order ID : ${rating.id}',
            style: TextStyle(
              fontSize: FigmaSize.w(11),
              color   : c.subText,
            ),
          ),
          SizedBox(height: FigmaSize.h(8)),

          // ── Avatar + Name + Stars ─────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              Container(
                height   : FigmaSize.h(36),
                width    : FigmaSize.w(36),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape : BoxShape.circle,
                  border: Border.all(color: AppTheme.primaryYellow),
                  color : AppTheme.primaryYellow.withOpacity(
                      isDark ? 0.12 : 0.08),
                ),
                child: rating.profileImg.isNotEmpty
                    ? ClipOval(
                        child: Image.network(
                          rating.profileImg,
                          width : FigmaSize.w(36),
                          height: FigmaSize.h(36),
                          fit   : BoxFit.cover,
                          errorBuilder: (_, __, ___) => _InitialText(
                              rating.displayName, c),
                        ),
                      )
                    : _InitialText(rating.displayName, c),
              ),

              SizedBox(width: FigmaSize.w(10)),

              // Name + date + stars
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            rating.displayName,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize  : FigmaSize.w(14),
                              color     : c.text,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        // Stars
                        Row(
                          children: List.generate(5, (i) => Icon(
                            Icons.star,
                            size : 14,
                            color: i < rating.rating
                                ? Colors.amber
                                : c.border,
                          )),
                        ),
                      ],
                    ),
                    SizedBox(height: FigmaSize.h(2)),
                    Text(
                      'Chat : ${rating.createdDate}',
                      style: TextStyle(
                        fontSize  : FigmaSize.w(12),
                        color     : c.subText,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: FigmaSize.h(8)),

          // ── Review text ───────────────────────────────────────────────
          Text(
            rating.review.isNotEmpty ? rating.review : 'No Review',
            style: TextStyle(
              fontSize  : FigmaSize.w(12),
              color     : rating.review.isNotEmpty ? c.text : c.subText,
              fontWeight: FontWeight.w500,
              height    : 20 / FigmaSize.w(12),
            ),
          ),
          SizedBox(height: FigmaSize.h(12)),

          // ── Actions ───────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Restore button
              GestureDetector(
                onTap: () {},
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: FigmaSize.w(12),
                    vertical  : FigmaSize.h(6),
                  ),
                  decoration: BoxDecoration(
                    color       : AppTheme.primaryYellow,
                    borderRadius: BorderRadius.circular(FigmaSize.w(20)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.flag,
                          size : FigmaSize.w(14),
                          color: Colors.black),
                      SizedBox(width: FigmaSize.w(4)),
                      Text(
                        'Restore',
                        style: TextStyle(
                          fontSize  : FigmaSize.w(12),
                          fontWeight: FontWeight.w600,
                          color     : Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: FigmaSize.w(12)),
              // Delete button
              GestureDetector(
                onTap: () {},
                child: Text(
                  'Delete',
                  style: TextStyle(
                    fontSize  : FigmaSize.w(12),
                    color     : AppTheme.accentRed,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Avatar initial fallback ───────────────────────────────────────────────────
class _InitialText extends StatelessWidget {
  final String    displayName;
  final AppColors c;
  const _InitialText(this.displayName, this.c);

  @override
  Widget build(BuildContext context) {
    return Text(
      displayName.isNotEmpty ? displayName[0].toUpperCase() : 'K',
      style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize  : FigmaSize.w(14),
          color     : c.text),
    );
  }
}