import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
import '../analytics/widgets/global_analytics_section.dart';
import '../teacher_essentials/retake_requests_screen.dart';

class TeacherDashboard extends ConsumerStatefulWidget {
  const TeacherDashboard({super.key});

  @override
  ConsumerState<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends ConsumerState<TeacherDashboard> {
  bool _sidebarOpen = false;
  String _selectedPage =
      'classes'; // 'classes' | 'analytics' | 'retake_requests'

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
              child: _buildSidebar(user),
            )
          : null,
      body: DashboardLayout(
        sidebarOpen: _sidebarOpen,
        isMobile: isMobile,
        topBar: DashboardTopBar(
          isMobile: isMobile,
          userName: user?.name,
          roleBadgeText: 'TEACHER',
          roleBadgeColor: const Color(0xFFFF9A2F),
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
            ref.invalidate(pendingRetakeRequestsProvider);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Refreshing dashboard data...'),
                duration: Duration(seconds: 1),
              ),
            );
          },
          onLogoutPressed: () => DashboardUtils.confirmLogout(context, ref),
        ),
        sidebar: _buildSidebar(user),
        mainContent: _selectedPage == 'analytics'
            ? const SingleChildScrollView(
                child: GlobalAnalyticsSection(),
              )
            : _selectedPage == 'retake_requests'
            ? const RetakeRequestsScreen()
            : classroomsAsync.when(
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

  Widget _buildSidebar(User? user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 20),
        DashboardSidebarItem(
          icon: Icons.menu_book_rounded,
          label: 'My Classes',
          selected: _selectedPage == 'classes',
          sidebarOpen: _sidebarOpen,
          onTap: () => setState(() => _selectedPage = 'classes'),
        ),
        DashboardSidebarItem(
          icon: Icons.analytics_rounded,
          label: 'Analytics',
          selected: _selectedPage == 'analytics',
          sidebarOpen: _sidebarOpen,
          onTap: () => setState(() => _selectedPage = 'analytics'),
        ),
        DashboardSidebarItem(
          icon: Icons.refresh,
          label: 'Retake Requests',
          selected: _selectedPage == 'retake_requests',
          sidebarOpen: _sidebarOpen,
          onTap: () => setState(() => _selectedPage = 'retake_requests'),
        ),
        const Spacer(),
        DashboardUtils.buildSidebarFooter(_sidebarOpen, user?.name ?? 'Teacher'),
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
          title: 'Teaching Classes',
          subtitle: 'Open your classes, monitor students, and manage join codes.',
        ),
        const SizedBox(height: 18),
        Expanded(
          child: classrooms.isEmpty
              ? _buildCreateCard(context, isMobile)
              : SingleChildScrollView(
                  child: Wrap(
                    spacing: isMobile ? 16 : 28,
                    runSpacing: isMobile ? 16 : 24,
                    children: [
                      for (final classroom in classrooms)
                        _buildClassCard(context, classroom, isMobile),
                      _buildCreateCard(context, isMobile),
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
      subtitle1: 'Students: ${classroom.studentsCount ?? 0}',
      subtitle2: 'Code: ${classroom.joinCode}',
      onTap: () => context.push('/classroom/${classroom.id}'),
      topGradient: const [
        Color(0xFFE5D8FF),
        Color(0xFFD6EAFF),
        Color(0xFFFBEAF0),
      ],
    );
  }

  Widget _buildCreateCard(BuildContext context, bool isMobile) {
    return DashboardActionCard(
      isMobile: isMobile,
      label: '+ Create classroom',
      onTap: () => _showCreateClassroomDialog(context),
    );
  }

  void _showCreateClassroomDialog(BuildContext context) {
    final nameController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Create Classroom',
          style: TextStyle(
            color: Color(0xFF364762),
            fontWeight: FontWeight.w900,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              cursorColor: const Color(0xFF4D62F0),
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w700,
              ),
              decoration: DashboardUtils.getDialogInputDecoration(
                'e.g. IT 301 SIA',
                Icons.class_rounded,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: descController,
              cursorColor: const Color(0xFF4D62F0),
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w700,
              ),
              decoration: DashboardUtils.getDialogInputDecoration(
                'e.g. TH 3 - 5 3213',
                Icons.description_outlined,
              ),
            ),
          ],
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
              if (nameController.text.isEmpty) return;

              try {
                await ClassroomActions(
                  ref,
                ).createClassroom(nameController.text, descController.text);
                if (!context.mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Classroom created successfully'),
                  ),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to create classroom: $e')),
                );
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
              'Create',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

}
