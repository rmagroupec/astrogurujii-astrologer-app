import 'package:astrologer_app/core/config/theme_config.dart';
import 'package:astrologer_app/core/utils/size_config.dart';
import 'package:flutter/material.dart';

class DarkStatsHeader extends StatelessWidget {
  final Color? color;
  const DarkStatsHeader({super.key, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding:  EdgeInsets.symmetric(vertical: FigmaSize.h(12), horizontal: FigmaSize.w(16)),
      decoration:  BoxDecoration(
        color: color == null ?  AppTheme.primaryColor : color ,
      ),
      child: Row(
        children: const [
          Expanded(
            child: _DarkStatColumn(
              value: "5 Cr+",
              label: "Happy Customers",
            ),
          ),

          _VerticalDivider(),

          Expanded(
            child: _DarkStatColumn(
              value: "100%",
              label: "Customer Privacy",
            ),
          ),

          _VerticalDivider(),

          Expanded(
            child: _DarkStatColumn(
              value: "1000+",
              label: "Top Astrologers Trusted",
            ),
          ),
        ],
      ),
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      width: 1,
      color: Colors.black,
    );
  }
}
class _DarkStatColumn extends StatelessWidget {
  final String value;
  final String label;

  const _DarkStatColumn({
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.black,
              ),
        ),
      ],
    );
  }
}
