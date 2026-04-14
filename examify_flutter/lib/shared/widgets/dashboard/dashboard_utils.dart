import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';

class DashboardUtils {
  static Widget buildSidebarFooter(bool sidebarOpen, String text) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 1,
            width: double.infinity,
            color: const Color(0xFFD6E1EC),
          ),
          if (sidebarOpen) ...[
            const SizedBox(height: 10),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF5F6D84),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  static Future<void> confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF6E4CF5), width: 2),
        ),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: Color(0xFF6E4CF5)),
            SizedBox(width: 8),
            Text(
              'Confirm Log Out',
              style: TextStyle(
                color: Color(0xFF6E4CF5),
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        content: const Text(
          'Are you sure you want to log out of your account?',
          style: TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.w600),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF5F6D84), fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF3EDFF),
              foregroundColor: const Color(0xFF5A285A),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: const BorderSide(color: Color(0xFF6E4CF5), width: 1.5),
              ),
            ),
            child: const Text('Log Out', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      ref.read(authProvider.notifier).logout();
    }
  }

  static InputDecoration getDialogInputDecoration(String hintText, IconData icon) {
    return InputDecoration(
      hintText: hintText,
      filled: true,
      fillColor: const Color(0xFFF5F8FD),
      prefixIcon: Icon(icon),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFD4DEEB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: Color(0xFF4D62F0),
          width: 1.6,
        ),
      ),
    );
  }
}
