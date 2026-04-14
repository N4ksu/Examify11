import 'package:flutter/material.dart';

class DashboardClassCard extends StatelessWidget {
  final bool isMobile;
  final String title;
  final String subtitle1;
  final String subtitle2;
  final VoidCallback onTap;
  final List<Color> topGradient;

  const DashboardClassCard({
    super.key,
    required this.isMobile,
    required this.title,
    required this.subtitle1,
    required this.subtitle2,
    required this.onTap,
    required this.topGradient,
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
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE1E8F2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: isMobile ? 100 : 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: topGradient,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                ),
              ),
              child: Center(
                child: Image.asset(
                  'assets/cite_logo.webp',
                  height: isMobile ? 60 : 78,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF24364E),
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          subtitle1,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF73839D),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (subtitle2.isNotEmpty)
                        Text(
                          subtitle2,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF6E4CF5),
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
