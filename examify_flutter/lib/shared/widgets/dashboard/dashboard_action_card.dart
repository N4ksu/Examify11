import 'package:flutter/material.dart';

class DashboardActionCard extends StatelessWidget {
  final bool isMobile;
  final String label;
  final VoidCallback onTap;

  const DashboardActionCard({
    super.key,
    required this.isMobile,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cardWidth = isMobile
        ? (MediaQuery.of(context).size.width - 40)
        : 320.0;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: cardWidth,
        height: isMobile ? 120 : 190,
        decoration: BoxDecoration(
          color: const Color(0xFFF3F8FD),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFFCCD8E3),
            width: 4,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: const Color(0xFFAEBBCB),
              fontSize: isMobile ? 16 : 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}
