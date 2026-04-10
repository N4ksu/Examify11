import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../shared/models/user.dart';
import '../../shared/providers/auth_provider.dart';
import '../../shared/providers/classroom_provider.dart';
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
      body: Stack(
        children: [
          Positioned.fill(child: _buildBodyBackground()),
          Column(
            children: [
              _buildTopBar(context, user, isMobile),
              Expanded(
                child: Row(
                  children: [
                    if (!isMobile)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOut,
                        width: _sidebarOpen ? 246 : 84,
                        clipBehavior: Clip.hardEdge,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          border: Border(
                            right: BorderSide(color: Color(0xFFD6E1EC)),
                          ),
                        ),
                        child: _buildSidebar(user),
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
                        child: _selectedPage == 'analytics'
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
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
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

  Widget _buildTopBar(BuildContext context, User? user, bool isMobile) {
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
                Builder(
                  builder: (context) => IconButton(
                    icon: const Icon(
                      Icons.menu_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                    onPressed: () {
                      if (isMobile) {
                        Scaffold.of(context).openDrawer();
                      } else {
                        setState(() {
                          _sidebarOpen = !_sidebarOpen;
                        });
                      }
                    },
                  ),
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
                color: const Color(0xFFFF9A2F),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text(
                'TEACHER',
                style: TextStyle(
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
            onPressed: () {
              ref.invalidate(classroomsProvider);
              ref.invalidate(pendingRetakeRequestsProvider);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Refreshing dashboard data...'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            tooltip: 'Account',
            onSelected: (value) {
              if (value == 'profile') context.push('/profile');
              if (value == 'logout') {
                _confirmLogout();
              }
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
                (user?.name.isNotEmpty == true ? user!.name[0] : 'T')
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

  Widget _buildSidebar(User? user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 20),
        _buildSidebarItem(
          icon: Icons.menu_book_rounded,
          label: 'My Classes',
          selected: _selectedPage == 'classes',
          onTap: () => setState(() => _selectedPage = 'classes'),
        ),
        _buildSidebarItem(
          icon: Icons.analytics_rounded,
          label: 'Analytics',
          selected: _selectedPage == 'analytics',
          onTap: () => setState(() => _selectedPage = 'analytics'),
        ),
        _buildSidebarItem(
          icon: Icons.refresh,
          label: 'Retake Requests',
          selected: _selectedPage == 'retake_requests',
          onTap: () => setState(() => _selectedPage = 'retake_requests'),
        ),
        const Spacer(),
        Container(
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
              if (_sidebarOpen) ...[
                const SizedBox(height: 10),
                Text(
                  user?.name ?? 'Teacher',
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
        ),
      ],
    );
  }

  Widget _buildSidebarItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool selected = false,
    Widget? trailing,
  }) {
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
            if (_sidebarOpen) ...[
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

  Widget _buildClassesArea(BuildContext context, List classrooms, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
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
              DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF7049F4), Color(0xFF47A2FF)],
                  ),
                  borderRadius: BorderRadius.all(Radius.circular(14)),
                ),
                child: SizedBox(
                  width: isMobile ? 38 : 46,
                  height: isMobile ? 38 : 46,
                  child: Icon(
                    Icons.auto_stories_rounded,
                    color: Colors.white,
                    size: isMobile ? 20 : 24,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Teaching Classes',
                      style: TextStyle(
                        color: const Color(0xFF6A7C97),
                        fontSize: isMobile ? 14 : 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Open your classes, monitor students, and manage join codes.',
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
    final cardWidth = isMobile
        ? (MediaQuery.of(context).size.width - 40)
        : 320.0;

    return InkWell(
      onTap: () => context.push('/classroom/${classroom.id}'),
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
              height: isMobile ? 90 : 110,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFE5D8FF),
                    Color(0xFFD6EAFF),
                    Color(0xFFFBEAF0),
                  ],
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                ),
              ),
              child: Center(
                child: Image.asset(
                  'assets/cite_logo.webp',
                  height: isMobile ? 54 : 68,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    classroom.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF24364E),
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Students: ${classroom.studentsCount ?? 0}',
                        style: const TextStyle(
                          color: Color(0xFF73839D),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Code: ${classroom.joinCode}',
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

  Widget _buildCreateCard(BuildContext context, bool isMobile) {
    final cardWidth = isMobile
        ? (MediaQuery.of(context).size.width - 40)
        : 320.0;

    return InkWell(
      onTap: () => _showCreateClassroomDialog(context),
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
            '+ Create classroom',
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
              decoration: InputDecoration(
                hintText: 'e.g. IT 301 SIA',
                filled: true,
                fillColor: const Color(0xFFF5F8FD),
                prefixIcon: const Icon(Icons.class_rounded),
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
              decoration: InputDecoration(
                hintText: 'e.g. TH 3 - 5 3213',
                filled: true,
                fillColor: const Color(0xFFF5F8FD),
                prefixIcon: const Icon(Icons.description_outlined),
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

  Future<void> _confirmLogout() async {
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
              foregroundColor: const Color(0xFF5A285A), // Dark text instead of white!
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

    if (confirm == true && mounted) {
      ref.read(authProvider.notifier).logout();
      context.go('/');
    }
  }
}
