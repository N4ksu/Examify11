import 'package:flutter/material.dart';

class DashboardBanner extends StatelessWidget {
  final bool isMobile;
  final IconData icon;
  final List<Color> iconGradient;
  final String title;
  final String subtitle;

  const DashboardBanner({
    super.key,
    required this.isMobile,
    required this.icon,
    required this.iconGradient,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 14 : 22,
        vertical: isMobile ? 12 : 18,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.82),
            const Color(0xFFF7FBFF).withValues(alpha: 0.92),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD6E3EF)),
      ),
      child: Row(
        children: [
          Container(
            width: isMobile ? 38 : 46,
            height: isMobile ? 38 : 46,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: iconGradient,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: isMobile ? 20 : 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: const Color(0xFF6A7C97),
                    fontSize: isMobile ? 14 : 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: const Color(0xFF8B9AB1),
                    fontSize: isMobile ? 11 : 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
