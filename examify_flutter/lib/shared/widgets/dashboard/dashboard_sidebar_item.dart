import 'package:flutter/material.dart';

class DashboardSidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final bool sidebarOpen;
  final Widget? trailing;
  final VoidCallback onTap;

  const DashboardSidebarItem({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.sidebarOpen,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 76,
        width: double.infinity,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE7F6FF) : Colors.white,
          border: Border(
            left: BorderSide(
              color: selected ? const Color(0xFF2EA4EA) : Colors.transparent,
              width: 6,
            ),
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 72,
              child: Center(
                child: Icon(icon, color: const Color(0xFF8B98AE), size: 27),
              ),
            ),
            if (sidebarOpen) ...[
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected
                        ? const Color(0xFF2EA4EA)
                        : const Color(0xFF71819C),
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              trailing ?? const SizedBox.shrink(),
              const SizedBox(width: 8),
            ],
          ],
        ),
      ),
    );
  }
}
