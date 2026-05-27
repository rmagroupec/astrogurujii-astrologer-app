import 'package:astrologer_app/core/config/theme_config.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AstrogurujiiSupportScreen extends StatelessWidget {
  const AstrogurujiiSupportScreen({super.key});

  static const String supportPhone = '+916394856756';
  static const String supportWhatsApp = '+916394856756';

  Future<void> _callSupport() async {
    final uri = Uri.parse('tel:$supportPhone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _whatsappSupport() async {
    final uri = Uri.parse(
      'https://wa.me/$supportWhatsApp?text=Hello%20DivinIQ%20Support',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        elevation: 0,
       foregroundColor: Colors.black,
              backgroundColor: AppTheme.primaryColor,
        centerTitle: true,
        title: const Text(
          'Astrogurujii Support',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Need Help?',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Our support team is always here for you',
              style: TextStyle(
                color: Colors.black54,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 30),

            /// 📞 CALL SUPPORT
            _supportCard(
              icon: Icons.call,
              title: 'Call Support',
              subtitle: supportPhone,
              color: Colors.green,
              onTap: _callSupport,
            ),

            const SizedBox(height: 18),

            /// 💬 WHATSAPP SUPPORT
            _supportCard(
              icon: Icons.chat_bubble_outline,
              title: 'WhatsApp Support',
              subtitle: 'Chat with us instantly',
              color: Colors.teal,
              onTap: _whatsappSupport,
            ),

            const Spacer(),

            /// 🔮 BRAND FOOTER
            const Center(
              child: Text(
                'DivinIQ – Your Divine Guide',
                style: TextStyle(
                  color: Colors.black38,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _supportCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: color.withOpacity(0.12),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
