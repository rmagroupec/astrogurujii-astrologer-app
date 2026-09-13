import 'package:astrologer_app/model/AstrologerGiftModel.dart';
import 'package:flutter/material.dart';
import 'package:astrologer_app/core/config/theme_config.dart';
import 'package:astrologer_app/service/apiService.dart';

class AstrologerGiftScreen extends StatefulWidget {
  final bool showAppBar;
  const AstrologerGiftScreen({super.key, this.showAppBar = true});

  @override
  State<AstrologerGiftScreen> createState() => _AstrologerGiftScreenState();
}

class _AstrologerGiftScreenState extends State<AstrologerGiftScreen> {
  bool isLoading = true;
  bool isError = false;
  List<AstrologerGift> gifts = [];

  @override
  void initState() {
    super.initState();
    fetchGifts();
  }

  Future<void> fetchGifts() async {
    setState(() {
      isLoading = true;
      isError = false;
    });

    try {
      final res = await ApiService().AstrologerGiftList();
      setState(() {
        gifts = res.gifts;
      });
    } catch (e) {
      isError = true;
      gifts = [];
    }

    setState(() => isLoading = false);
  }

  num get _totalEarned => gifts.fold(0, (sum, g) => sum + g.amount);

@override
  Widget build(BuildContext context) {
    final c = context.colors;

    if (!widget.showAppBar) {
      return Container(color: c.bg, child: _body(c));
    }

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        title: const Text('Received Gifts', style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: AppTheme.primaryYellow,
        foregroundColor: Colors.white,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [AppTheme.primaryYellow, Color(0xFF5B2569)],
            ),
          ),
        ),
      ),
      body: _body(c),
    );
  }

  Widget _body(AppColors c) {
    if (isLoading) {
      return Center(child: CircularProgressIndicator(color: AppTheme.primaryYellow));
    }

    if (isError) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.accentRed.withOpacity(0.10),
              ),
              child: Icon(Icons.error_outline_rounded, color: AppTheme.accentRed, size: 32),
            ),
            const SizedBox(height: 14),
            Text("Something went wrong", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: c.text)),
            const SizedBox(height: 4),
            Text("Couldn't load your gifts", style: TextStyle(fontSize: 12.5, color: c.subText)),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: fetchGifts,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryYellow,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
              child: const Text("Retry", style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );
    }

    if (gifts.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [AppTheme.primaryYellow.withOpacity(0.16), AppTheme.primaryYellow.withOpacity(0.16)],
                ),
              ),
              child: const Text('🎁', style: TextStyle(fontSize: 34)),
            ),
            const SizedBox(height: 16),
            Text("No gifts received yet", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: c.text)),
            const SizedBox(height: 4),
            Text("Gifts from your clients will show up here", style: TextStyle(fontSize: 12.5, color: c.subText)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: fetchGifts,
      color: AppTheme.primaryYellow,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(0, 14, 0, 10),
        itemCount: gifts.length + 1, // +1 for the summary header
        itemBuilder: (_, i) {
          if (i == 0) return _summaryCard(c);
          return _giftCard(gifts[i - 1], c);
        },
      ),
    );
  }

  Widget _summaryCard(AppColors c) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [AppTheme.primaryYellow, AppTheme.primaryYellow],
        ),
        boxShadow: [
          BoxShadow(color: AppTheme.primaryYellow.withOpacity(0.35), blurRadius: 18, offset: const Offset(0, 8)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.22),
              shape: BoxShape.circle,
            ),
            child: const Center(child: Text('🎁', style: TextStyle(fontSize: 26))),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Gift Earnings',
                  style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12.5, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 3),
                Text(
                  '₹${_totalEarned.toStringAsFixed(0)}',
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.22),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${gifts.length} ${gifts.length == 1 ? 'gift' : 'gifts'}',
              style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _giftCard(AstrologerGift g, AppColors c) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border),
        boxShadow: [
          BoxShadow(color: AppTheme.primaryYellow.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      padding: const EdgeInsets.all(13),
      child: Row(
        children: [
          _GradientAvatar(name: g.fromUser.name, imageUrl: g.fromUser.profileImg, size: 48),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  g.fromUser.name,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: c.text),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryYellow.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        g.gift.title,
                        style: TextStyle(fontSize: 11, color: AppTheme.primaryYellow, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                if (g.type == "live" && g.liveInfo != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.podcasts_rounded, size: 12, color: AppTheme.accentRed),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          g.liveInfo!.title,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 11, color: c.subText),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 5),
                Text(
                  _formatDate(g.createdAt),
                  style: TextStyle(fontSize: 10.5, color: c.subText),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (g.gift.image.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryYellow.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Image.network(g.gift.image, height: 30, width: 30),
                ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF2E9E5B), Color(0xFF1F7A44)]),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  "₹${g.amount}",
                  style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white, fontSize: 12.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) {
    return "${d.day}/${d.month}/${d.year}";
  }
}

class _GradientAvatar extends StatelessWidget {
  final String name;
  final String imageUrl;
  final double size;
  const _GradientAvatar({required this.name, required this.imageUrl, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      padding: const EdgeInsets.all(1.6),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [AppTheme.primaryYellow, AppTheme.primaryYellow],
        ),
      ),
      child: ClipOval(
        child: Container(
          color: Colors.white,
          child: imageUrl.isNotEmpty
              ? Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _initial(),
                )
              : _initial(),
        ),
      ),
    );
  }

  Widget _initial() => Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: size * 0.38, color: AppTheme.primaryYellow),
        ),
      );
}