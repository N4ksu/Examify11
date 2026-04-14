import 'package:flutter/material.dart';

class DashboardLayout extends StatelessWidget {
  final Widget topBar;
  final Widget sidebar;
  final Widget mainContent;
  final bool sidebarOpen;
  final bool isMobile;

  const DashboardLayout({
    super.key,
    required this.topBar,
    required this.sidebar,
    required this.mainContent,
    required this.sidebarOpen,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(child: _buildBodyBackground()),
        Column(
          children: [
            topBar,
            Expanded(
              child: Row(
                children: [
                  if (!isMobile)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOut,
                      width: sidebarOpen ? 246 : 84,
                      clipBehavior: Clip.hardEdge,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          right: BorderSide(color: Color(0xFFD6E1EC)),
                        ),
                      ),
                      child: sidebar,
                    ),
                  Expanded(
                    child: Container(
                      color: Colors.transparent,
                      padding: EdgeInsets.fromLTRB(
                        isMobile ? 12 : 22,
                        18,
                        isMobile ? 12 : 22,
                        18,
                      ),
                      child: mainContent,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBodyBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF2F7FC), Color(0xFFEAF2F8)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 120,
            right: -40,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF8A62F4).withValues(alpha: 0.07),
              ),
            ),
          ),
          Positioned(
            bottom: -40,
            left: 180,
            child: Container(
              width: 300,
              height: 180,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(40),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFFB8D7FF).withValues(alpha: 0.10),
                    const Color(0xFFE7C7FF).withValues(alpha: 0.08),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
