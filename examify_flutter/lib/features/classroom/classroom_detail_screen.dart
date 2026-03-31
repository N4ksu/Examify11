import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'stream_tab.dart';
import 'assessments_tab.dart';
import 'people_tab.dart';
import 'providers/assessment_status_provider.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/providers/classroom_provider.dart';
import '../../../shared/providers/assessment_provider.dart';
import '../retake/providers/retake_request_provider.dart';

class ClassroomDetailScreen extends ConsumerStatefulWidget {
  final String id;
  const ClassroomDetailScreen({super.key, required this.id});

  @override
  ConsumerState<ClassroomDetailScreen> createState() =>
      _ClassroomDetailScreenState();
}

class _ClassroomDetailScreenState extends ConsumerState<ClassroomDetailScreen> {
  int _selectedIndex = 0;
  bool _sidebarOpen = true;
  Timer? _pollTimer;
  List<int> _assessmentIds = [];

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    // Check if user is a student before starting the timer
    Future.microtask(() {
      final user = ref.read(authProvider).user;
      if (user?.role.name == 'student') {
        _pollTimer?.cancel(); // Ensure no duplicate timers
        _pollTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
          if (mounted && _assessmentIds.isNotEmpty) {
            for (final id in _assessmentIds) {
              ref.invalidate(assessmentStatusProvider(id));
              ref.invalidate(studentAttemptProvider(id));
              ref.invalidate(retakeRequestStatusProvider(id));
            }
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider.select((state) => state.user));
    final classroomAsync = ref.watch(classroomDetailProvider(widget.id));
    final assessmentsAsync = ref.watch(
      assessmentsProvider(int.parse(widget.id)),
    );

    // Update assessment IDs for polling
    assessmentsAsync.whenData((assessments) {
      final ids = assessments.map((a) => a.id).toList();
      // Only update if the list has changed to avoid unnecessary rebuilds
      if (_assessmentIds.length != ids.length ||
          !_assessmentIds.every((id) => ids.contains(id))) {
        Future.microtask(() {
          if (mounted) {
            setState(() {
              _assessmentIds = ids;
            });
          }
        });
      }
    });

    final screens = [
      StreamTab(classroomId: widget.id),
      AssessmentsTab(classroomId: widget.id),
      PeopleTab(classroomId: widget.id),
    ];

    final tabs = [
      {'icon': Icons.dashboard_outlined, 'label': 'Stream'},
      {'icon': Icons.assignment_outlined, 'label': 'Classwork'},
      {'icon': Icons.people_outline, 'label': 'People'},
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          // ── Top Bar ──────────────────────────────────────────────
          _buildTopBar(context, classroomAsync),

          // ── Body: Sidebar + Content ─────────────────────────────
          Expanded(
            child: Row(
              children: [
                // ── Collapsible Sidebar ───────────────────────────
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                  width: _sidebarOpen ? 240 : 0,
                  clipBehavior: Clip.hardEdge,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(right: BorderSide(color: Color(0xFFE8E8E8))),
                  ),
                  child: SizedBox(
                    width: 240,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Classroom name header
                        Padding(
                          padding: const EdgeInsets.fromLTRB(14, 16, 14, 10),
                          child: classroomAsync.when(
                            data: (classroom) => Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(0xFF8B1A24), // Maroon
                                  ),
                                  clipBehavior: Clip.hardEdge,
                                  child: Image.asset(
                                    'assets/cite_logo.webp',
                                    fit: BoxFit.contain,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Flexible(
                                  child: Text(
                                    classroom.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Color(0xFF7B1FA2),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            loading: () => const SizedBox.shrink(),
                            error: (_, _) => const SizedBox.shrink(),
                          ),
                        ),

                        // Navigation items
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.only(top: 4),
                            itemCount: tabs.length,
                            itemBuilder: (context, index) {
                              final isSelected = _selectedIndex == index;
                              final tab = tabs[index];
                              return _SidebarNavItem(
                                icon: tab['icon'] as IconData,
                                label: tab['label'] as String,
                                isSelected: isSelected,
                                showChevron: isSelected && index == 0,
                                onTap: () =>
                                    setState(() => _selectedIndex = index),
                              );
                            },
                          ),
                        ),

                        // User info at bottom
                        Container(
                          margin: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE8E8E8)),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: const Color(
                                  0xFF9068F5,
                                ), // Softer purple
                                child: Icon(
                                  Icons.email_outlined,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      user?.email ?? 'user@email.com',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF444444),
                                      ),
                                    ),
                                    const Text(
                                      'Signed in',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF999999),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Main Content Area ─────────────────────────────
                Expanded(
                  child: Container(
                    color: const Color(0xFFF5F5F5),
                    child: IndexedStack(
                      index: _selectedIndex,
                      children: screens,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, AsyncValue classroomAsync) {
    return Container(
      height: 92,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFF6A40F2), Color(0xFF8D43F0), Color(0xFFA74DE9)],
        ),
      ),
      child: Stack(
        children: [
          // Left actions + Logos + School Name
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      final role = ref.read(authProvider).user?.role.name;
                      context.go(role == 'teacher' ? '/teacher' : '/student');
                    }
                  },
                ),
                InkWell(
                  onTap: () => setState(() => _sidebarOpen = !_sidebarOpen),
                  child: const SizedBox(
                    width: 56,
                    height: 64,
                    child: Icon(Icons.menu, color: Colors.white, size: 24),
                  ),
                ),
                Image.asset('assets/cite_logo.webp', height: 44),
                const SizedBox(width: 8),
                Image.asset('assets/jmc_logo.webp', height: 40),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'JOSE MARIA COLLEGE',
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
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'Assured • Consistent • Quality Education',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 9,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Right actions
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (ref.watch(authProvider.select((state) => state.user))?.role.name == 'student')
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    tooltip: 'Refresh Status',
                    onPressed: () {
                      for (final id in _assessmentIds) {
                        ref.invalidate(assessmentStatusProvider(id));
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Status refreshed'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sidebar Navigation Item
// ─────────────────────────────────────────────────────────────────────────────

class _SidebarNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final bool showChevron;
  final VoidCallback onTap;

  const _SidebarNavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    this.showChevron = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 48,
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          border: isSelected
              ? Border.all(color: Colors.grey.shade300, width: 1.0)
              : null,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            const SizedBox(width: 16),
            Icon(
              icon,
              color: isSelected
                  ? const Color(0xFF7B1FA2)
                  : const Color(0xFF666666),
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? const Color(0xFF7B1FA2)
                      : const Color(0xFF444444),
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
            if (showChevron)
              const Icon(
                Icons.chevron_right,
                color: Color(0xFF7B1FA2),
                size: 20,
              ),
            const SizedBox(width: 12),
          ],
        ),
      ),
    );
  }
}
