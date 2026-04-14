import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';

import '../../shared/models/user.dart';
import '../../shared/providers/auth_provider.dart';
import '../../shared/providers/classroom_provider.dart';
import '../../shared/widgets/dashboard/dashboard_layout.dart';
import '../../shared/widgets/dashboard/dashboard_top_bar.dart';
import '../../shared/widgets/dashboard/dashboard_sidebar_item.dart';
import '../../shared/widgets/dashboard/dashboard_banner.dart';
import '../../shared/widgets/dashboard/dashboard_action_card.dart';
import '../../shared/widgets/dashboard/dashboard_class_card.dart';
import '../../shared/widgets/dashboard/dashboard_utils.dart';

class StudentDashboard extends ConsumerStatefulWidget {
  const StudentDashboard({super.key});

  @override
  ConsumerState<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends ConsumerState<StudentDashboard> {
  bool _sidebarOpen = false;

  @override
  Widget build(BuildContext context) {
    final classroomsAsync = ref.watch(classroomsProvider);
    final user = ref.watch(authProvider.select((state) => state.user));
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 900;

    return Scaffold(
      backgroundColor: const Color(0xFFEFF5FB),
      drawer: isMobile
          ? Drawer(
              width: 246,
              backgroundColor: Colors.white,
              child: _buildSidebar(context, user),
            )
          : null,
      body: DashboardLayout(
        sidebarOpen: _sidebarOpen,
        isMobile: isMobile,
        topBar: DashboardTopBar(
          isMobile: isMobile,
          userName: user?.name,
          roleBadgeText: 'STUDENT',
          roleBadgeColor: const Color(0xFF35C76F),
          onMenuPressed: () {
            if (isMobile) {
              Scaffold.of(context).openDrawer();
            } else {
              setState(() {
                _sidebarOpen = !_sidebarOpen;
              });
            }
          },
          onRefreshPressed: () {
            ref.invalidate(classroomsProvider);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Refreshing dashboard data...'),
                duration: Duration(seconds: 1),
              ),
            );
          },
          onLogoutPressed: () => DashboardUtils.confirmLogout(context, ref),
        ),
        sidebar: _buildSidebar(context, user),
        mainContent: classroomsAsync.when(
          data: (classrooms) =>
              _buildClassesArea(context, classrooms, isMobile),
          loading: () => const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF6E4CF5),
            ),
          ),
          error: (err, stack) => Center(
            child: Text(
              'Something went wrong: $err',
              style: const TextStyle(
                color: Color(0xFF5D6C84),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSidebar(BuildContext context, User? user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 20),
        DashboardSidebarItem(
          icon: Icons.school_rounded,
          label: 'My classes',
          selected: true,
          sidebarOpen: _sidebarOpen,
          onTap: () {},
        ),
        const Spacer(),
        DashboardUtils.buildSidebarFooter(_sidebarOpen, 'Examify for JMC students'),
      ],
    );
  }

  Widget _buildClassesArea(BuildContext context, List classrooms, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DashboardBanner(
          isMobile: isMobile,
          icon: Icons.auto_stories_rounded,
          iconGradient: const [Color(0xFF7049F4), Color(0xFF47A2FF)],
          title: 'Active Classes',
          subtitle: 'Open your JMC classes or join a new one.',
        ),
        const SizedBox(height: 18),
        Expanded(
          child: SingleChildScrollView(
            child: Wrap(
              spacing: isMobile ? 16 : 28,
              runSpacing: isMobile ? 16 : 24,
              children: [
                for (final classroom in classrooms)
                  _buildClassCard(context, classroom, isMobile),
                _buildJoinCard(isMobile),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildClassCard(BuildContext context, dynamic classroom, bool isMobile) {
    return DashboardClassCard(
      isMobile: isMobile,
      title: classroom.name,
      subtitle1: classroom.teacher?.name ?? 'Unknown teacher',
      subtitle2: '',
      onTap: () => context.push('/classroom/${classroom.id}'),
      topGradient: const [
        Color(0xFFFADADA),
        Color(0xFFFBEAF0),
        Color(0xFFE8F3FF),
      ],
    );
  }

  Widget _buildJoinCard(bool isMobile) {
    return DashboardActionCard(
      isMobile: isMobile,
      label: '+ Join class',
      onTap: () => _showJoinClassroomDialog(context, ref),
    );
  }

  void _showJoinClassroomDialog(BuildContext context, WidgetRef ref) {
    final codeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Join Classroom',
          style: TextStyle(
            color: Color(0xFF364762),
            fontWeight: FontWeight.w900,
          ),
        ),
        content: TextField(
          controller: codeController,
          cursorColor: const Color(0xFF4D62F0),
          style: const TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
          decoration: DashboardUtils.getDialogInputDecoration(
            'Enter class code',
            Icons.key_rounded,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: Color(0xFF6B7B95),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (codeController.text.isEmpty) return;

              try {
                final response = await ClassroomActions(
                  ref,
                ).joinClassroom(codeController.text);
                if (!context.mounted) return;

                final msg =
                    response.data['message'] ?? 'Classroom joined successfully';
                Navigator.pop(context);
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(msg)));
              } catch (e) {
                if (!context.mounted) return;
                String errorMsg = 'Failed to join classroom: $e';
                if (e is DioException && e.response?.data != null) {
                  final data = e.response!.data;
                  if (data is Map && data.containsKey('message')) {
                    errorMsg = data['message'];
                  }
                }
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(errorMsg)));
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6E4CF5),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              'Join',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

}
