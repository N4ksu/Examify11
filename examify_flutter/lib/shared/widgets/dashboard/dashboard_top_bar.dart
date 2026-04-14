import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DashboardTopBar extends StatelessWidget {
  final bool isMobile;
  final String? userName;
  final String roleBadgeText;
  final Color roleBadgeColor;
  final VoidCallback onMenuPressed;
  final VoidCallback onRefreshPressed;
  final VoidCallback onLogoutPressed;

  const DashboardTopBar({
    super.key,
    required this.isMobile,
    required this.userName,
    required this.roleBadgeText,
    required this.roleBadgeColor,
    required this.onMenuPressed,
    required this.onRefreshPressed,
    required this.onLogoutPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 92,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFF6A40F2), Color(0xFF8D43F0), Color(0xFFA74DE9)],
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(
                    Icons.menu_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                  onPressed: onMenuPressed,
                ),
                const SizedBox(width: 4),
                Image.asset('assets/cite_logo.webp', height: isMobile ? 32 : 44),
                const SizedBox(width: 6),
                Image.asset('assets/jmc_logo.webp', height: isMobile ? 30 : 40),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'JOSE MARIA COLLEGE',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'OldEnglish',
                          letterSpacing: 0.5,
                        ),
                      ),
                      if (!isMobile) ...[
                        Text(
                          'Foundation, Inc.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          'Assured • Consistent • Quality Education',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 9,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (!isMobile) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: roleBadgeColor,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                roleBadgeText.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          IconButton(
            icon: Icon(
              Icons.refresh_rounded,
              color: Colors.white,
              size: isMobile ? 24 : 28,
            ),
            tooltip: 'Refresh All Data',
            onPressed: onRefreshPressed,
          ),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            tooltip: 'Account',
            onSelected: (value) {
              if (value == 'profile') context.push('/profile');
              if (value == 'logout') onLogoutPressed();
            },
            itemBuilder: (context) => const [
              PopupMenuItem<String>(
                value: 'profile',
                child: ListTile(
                  leading: Icon(Icons.person_outline_rounded),
                  title: Text('My Account'),
                ),
              ),
              PopupMenuItem<String>(
                value: 'logout',
                child: ListTile(
                  leading: Icon(Icons.logout_rounded),
                  title: Text('Logout'),
                ),
              ),
            ],
            child: CircleAvatar(
              radius: isMobile ? 18 : 22,
              backgroundColor: const Color(0xFFE7ECF3),
              child: Text(
                (userName?.isNotEmpty == true ? userName![0] : roleBadgeText[0])
                    .toUpperCase(),
                style: TextStyle(
                  color: const Color(0xFF55657F),
                  fontSize: isMobile ? 14 : 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
        ],
      ),
    );
  }
}
