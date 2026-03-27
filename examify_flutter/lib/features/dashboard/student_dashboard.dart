import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';

import '../../shared/models/user.dart';
import '../../shared/providers/auth_provider.dart';
import '../../shared/providers/classroom_provider.dart';

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
    final user = ref.watch(authProvider).user;
    return Scaffold(
      backgroundColor: const Color(0xFFEFF5FB),
      body: Stack(
        children: [
          Positioned.fill(child: _buildBodyBackground()),
          Column(
            children: [
              _buildTopBar(context, user),
              Expanded(
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOut,
                      width: _sidebarOpen ? 246 : 84,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          right: BorderSide(color: Color(0xFFD6E1EC)),
                        ),
                      ),
                      clipBehavior: Clip.hardEdge,
                      child: _buildSidebar(context, user),
                    ),
                    Expanded(
                      child: Container(
                        color: Colors.transparent,
                        padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
                        child: classroomsAsync.when(
                          data: (classrooms) =>
                              _buildClassesArea(context, classrooms),
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

  Widget _buildTopBar(BuildContext context, User? user) {
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
          Container(
            width: MediaQuery.of(context).size.width * 0.34,
            height: double.infinity,
            constraints: const BoxConstraints(minWidth: 240, maxWidth: 430),
            child: Row(
              children: [
                const SizedBox(width: 14),
                InkWell(
                  onTap: () {
                    setState(() {
                      _sidebarOpen = !_sidebarOpen;
                    });
                  },
                  child: const SizedBox(
                    width: 62,
                    height: 62,
                    child: Icon(
                      Icons.menu_rounded,
                      color: Colors.white,
                      size: 34,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Image.asset('assets/cite_logo.png', height: 44),
                const SizedBox(width: 10),
                Image.asset('assets/jmc_logo.png', height: 40),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'JOSE MARIA COLLEGE',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'OldEnglish',
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        'Foundation, Inc.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'Assured • Consistent • Quality Education',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 9,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF35C76F),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              'STUDENT',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 18),
          PopupMenuButton<String>(
            tooltip: 'Account',
            onSelected: (value) {
              if (value == 'profile') {
                context.push('/profile');
              }
              if (value == 'logout') {
                ref.read(authProvider.notifier).logout();
                context.go('/');
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
              radius: 22,
              backgroundColor: const Color(0xFFE7ECF3),
              child: Text(
                (user?.name.isNotEmpty == true ? user!.name[0] : 'S')
                    .toUpperCase(),
                style: const TextStyle(
                  color: Color(0xFF55657F),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(width: 18),
        ],
      ),
    );
  }

  Widget _buildSidebar(BuildContext context, User? user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 20),
        _buildSidebarItem(
          icon: Icons.school_rounded,
          label: 'My classes',
          selected: true,
          onTap: () {},
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
                const Text(
                  'Examify for JMC students',
                  textAlign: TextAlign.center,
                  style: TextStyle(
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
              width: 78,
              child: Icon(icon, color: const Color(0xFF8B98AE), size: 27),
            ),
            if (_sidebarOpen)
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: selected
                        ? const Color(0xFF2EA4EA)
                        : const Color(0xFF71819C),
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildClassesArea(BuildContext context, List classrooms) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
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
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF7049F4), Color(0xFF47A2FF)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.auto_stories_rounded,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 14),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Active Classes',
                    style: TextStyle(
                      color: Color(0xFF6A7C97),
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Open your JMC classes or join a new one.',
                    style: TextStyle(
                      color: Color(0xFF8B9AB1),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Expanded(
          child: Wrap(
            spacing: 28,
            runSpacing: 24,
            children: [
              for (final classroom in classrooms)
                _buildClassCard(context, classroom),
              _buildJoinCard(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildClassCard(BuildContext context, dynamic classroom) {
    final teacherName = classroom.teacher?.name ?? 'Unknown teacher';

    return InkWell(
      onTap: () => context.push('/classroom/${classroom.id}'),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 320,
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
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFFFADADA),
                    const Color(0xFFFBEAF0),
                    const Color(0xFFE8F3FF),
                  ],
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                ),
              ),
              child: Center(
                child: Image.asset('assets/cite_logo.png', height: 78),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    classroom.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF24364E),
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    teacherName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF73839D),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJoinCard() {
    return InkWell(
      onTap: () => _showJoinClassroomDialog(context, ref),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 320,
        height: 190,
        decoration: BoxDecoration(
          color: const Color(0xFFF3F8FD),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFFCCD8E3),
            width: 4,
            style: BorderStyle.solid,
          ),
        ),
        child: const Center(
          child: Text(
            '+ Join class',
            style: TextStyle(
              color: Color(0xFFAEBBCB),
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
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
          decoration: InputDecoration(
            hintText: 'Enter class code',
            filled: true,
            fillColor: const Color(0xFFF5F8FD),
            prefixIcon: const Icon(Icons.key_rounded),
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
