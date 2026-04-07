import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import '../../shared/providers/auth_provider.dart';

import '../../shared/providers/classroom_provider.dart';
import '../../shared/models/classroom.dart';
import '../../shared/models/announcement.dart';



class StreamTab extends ConsumerWidget {
  final String classroomId;
  final bool isMobile;
  const StreamTab({super.key, required this.classroomId, required this.isMobile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider.select((state) => state.user));
    final isTeacher = user?.role.name == 'teacher';

    final classroomAsync = ref.watch(classroomDetailProvider(classroomId));
    final announcementsAsync = ref.watch(announcementsProvider(classroomId));

    return Scaffold(
      backgroundColor: Colors.white,
      body: classroomAsync.when(
        data: (classroom) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(classroomDetailProvider(classroomId));
            ref.invalidate(announcementsProvider(classroomId));
            await ref.read(classroomDetailProvider(classroomId).future);
            await ref.read(announcementsProvider(classroomId).future);
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  isMobile ? 16 : 24,
                  16,
                  isMobile ? 16 : 24,
                  0,
                ),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    children: [
                      // Banner Section
                      _buildBanner(context, classroom, isTeacher, ref, isMobile),
                      const SizedBox(height: 24),

                      if (isMobile) ...[
                        // Mobile Layout: Header items
                        if (isTeacher) ...[
                          _buildClassCodeCard(context, classroom),
                          const SizedBox(height: 16),
                        ],
                        _buildUpcomingCard(context),
                        const SizedBox(height: 24),
                        _buildAnnouncementInput(context, isTeacher, ref),
                      ] else ...[
                        // Desktop Layout: Started in a Row, but we'll handle the announcements separately
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Left Column: Meet & Upcoming
                            SizedBox(
                              width: 200,
                              child: Column(
                                children: [
                                  if (isTeacher) ...[
                                    _buildClassCodeCard(context, classroom),
                                    const SizedBox(height: 16),
                                  ],
                                  _buildUpcomingCard(context),
                                ],
                              ),
                            ),
                            const SizedBox(width: 24),
                            // Right Column: Announcement Input Only (List will be outside)
                            Expanded(
                              child: _buildAnnouncementInput(context, isTeacher, ref),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),

              // Announcements List (Sliver for performance)
              announcementsAsync.when(
                data: (announcements) => _buildSliverAnnouncementList(
                  context,
                  isTeacher,
                  announcements,
                  ref,
                  isMobile,
                ),
                loading: () => const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                ),
                error: (err, stack) => SliverToBoxAdapter(
                  child: Center(child: Text('Error: $err')),
                ),
              ),
              
              // Bottom padding
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildBanner(
    BuildContext context,
    Classroom classroom,
    bool isTeacher,
    WidgetRef ref,
    bool isMobile,
  ) {
    return Container(
      width: double.infinity,
      height: isMobile ? 140 : 200, // Reduced from 240
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16), // Less rounded like GC
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Color(0xFF8821D3), // GC purple
            Color(0xFFA14AE8),
          ],
        ),
      ),
      child: Stack(
        children: [
          // Faint background waves
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.15),
                  Colors.transparent,
                  Colors.white.withValues(alpha: 0.05),
                ],
              ),
            ),
          ),
          Positioned(
            right: -40,
            top: -30,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  classroom.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: isMobile ? 24 : 32,
                  ),
                ),
                if (classroom.description != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    classroom.description!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w400, // Normal weight for subtitle
                    ),
                  ),
                ]
              ],
            ),
          ),
          if (isTeacher)
            Positioned(
              bottom: 16,
              right: 16,
              child: ElevatedButton.icon(
                onPressed: () =>
                    _showEditClassroomDialog(context, classroom, ref),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Customize', style: TextStyle(fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF8821D3), // Purple text
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildClassCodeCard(BuildContext context, Classroom classroom) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Class code',
                style: TextStyle(
                  color: Color(0xFF5F6368),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox.shrink(), // No more_vert in screenshot
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                classroom.joinCode,
                style: const TextStyle(
                  color: Color(0xFF8821D3),
                  fontSize: 26,
                  letterSpacing: 2.0,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              const Icon(Icons.content_copy, color: Color(0xFF5F6368), size: 18),
              const SizedBox(width: 14),
              const Icon(Icons.fullscreen, color: Color(0xFF5F6368), size: 20),
            ],
          ),
        ],
      ),
    );
  }

  void _showEditClassroomDialog(
    BuildContext context,
    Classroom classroom,
    WidgetRef ref,
  ) {
    final nameController = TextEditingController(text: classroom.name);
    final descController = TextEditingController(text: classroom.description);

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Edit Classroom Details',
          style: TextStyle(color: Color(0xFF3C4043), fontSize: 20, fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Classroom Name', style: TextStyle(color: Color(0xFF5F6368), fontSize: 12, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            TextField(
              controller: nameController,
              style: const TextStyle(color: Color(0xFF3C4043)),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFFF1F3F4),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Schedule/Description', style: TextStyle(color: Color(0xFF5F6368), fontSize: 12, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            TextField(
              controller: descController,
              style: const TextStyle(color: Color(0xFF3C4043)),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFFF1F3F4),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF5F6368))),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await ClassroomActions(ref).updateClassroom(
                  classroom.id,
                  nameController.text,
                  descController.text,
                );
                if (!dialogCtx.mounted) return;
                Navigator.pop(dialogCtx);
                ref.invalidate(classroomDetailProvider(classroomId));
              } catch (e) {
                if (!dialogCtx.mounted) return;
                ScaffoldMessenger.of(dialogCtx).showSnackBar(
                  SnackBar(content: Text('Failed to update classroom: $e')),
                );
              }

            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1967D2),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Save', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.calendar_today_outlined, size: 16, color: Color(0xFF5F6368)),
              SizedBox(width: 8),
              Text(
                'Upcoming',
                style: TextStyle(
                  color: Color(0xFF5F6368),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.green, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'No work due soon!',
                  style: TextStyle(
                    color: Color(0xFF3C4043),
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Align(
            alignment: Alignment.centerRight,
            child: InkWell(
              onTap: () {},
              child: const Text(
                'View all',
                style: TextStyle(
                  color: Color(0xFF8821D3),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnnouncementInput(
    BuildContext context,
    bool isTeacher,
    WidgetRef ref,
  ) {
    return _AnnouncementComposer(
      classroomId: classroomId,
      isTeacher: isTeacher,
      ref: ref,
    );
  }

  void _showPostAnnouncementDialog(
    BuildContext context,
    bool isTeacher,
    WidgetRef ref, {
    Announcement? announcement,
  }) {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) => _AnnouncementDialog(
        classroomId: classroomId,
        isTeacher: isTeacher,
        ref: ref,
        announcement: announcement,
      ),
    );
  }

  Widget _buildSliverAnnouncementList(
    BuildContext context,
    bool isTeacher,
    List<Announcement> announcements,
    WidgetRef ref,
    bool isMobile,
  ) {
    if (announcements.isEmpty) {
      return SliverToBoxAdapter(
        child: Center(
          child: Container(
            margin: const EdgeInsets.only(top: 24),
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              vertical: isMobile ? 40 : 64,
              horizontal: 24,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F3F4),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 32,
                    color: Color(0xFF5F6368),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'No announcements yet',
                  style: TextStyle(
                    color: Color(0xFF202124),
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Post announcements to share updates, materials,\nand messages with your class',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF5F6368),
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 24,
      ),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final ann = announcements[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: const Color(0xFF1967D2),
                          child: Text(
                            ann.teacher?.name[0] ?? '?',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              RichText(
                                text: TextSpan(
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF3C4043),
                                  ),
                                  children: [
                                    TextSpan(
                                      text: '${ann.teacher?.name ?? 'Teacher'} ',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF3C4043),
                                      ),
                                    ),
                                    TextSpan(
                                      text: ann.title,
                                      style: const TextStyle(
                                        color: Color(0xFF5F6368),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                DateFormat('MMM d, yyyy').format(ann.createdAt),
                                style: const TextStyle(
                                  color: Color(0xFF5F6368),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isTeacher)
                          PopupMenuButton<String>(
                            iconColor: const Color(0xFF5F6368),
                            onSelected: (value) async {
                              if (value == 'edit') {
                                _showPostAnnouncementDialog(
                                  context,
                                  isTeacher,
                                  ref,
                                  announcement: ann,
                                );
                              } else if (value == 'delete') {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    backgroundColor: Colors.white,
                                    surfaceTintColor: Colors.white,
                                    title: const Text(
                                      'Delete Announcement',
                                      style: TextStyle(color: Color(0xFF3C4043)),
                                    ),
                                    content: const Text(
                                      'Are you sure you want to delete this announcement?',
                                      style: TextStyle(color: Color(0xFF5F6368)),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, false),
                                        child: const Text(
                                          'Cancel',
                                          style: TextStyle(color: Color(0xFF5F6368)),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, true),
                                        child: const Text(
                                          'Delete',
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  await AnnouncementActions(
                                    ref,
                                    classroomId,
                                  ).delete(ann.id);
                                }
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Text('Edit'),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Text('Delete'),
                              ),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      ann.body,
                      style: const TextStyle(
                        color: Color(0xFF3C4043),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
          childCount: announcements.length,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stateful announcement dialog with attach-photo support
// ─────────────────────────────────────────────────────────────────────────────

class _AnnouncementDialog extends StatefulWidget {
  final String classroomId;
  final bool isTeacher;
  final WidgetRef ref;
  final Announcement? announcement;

  const _AnnouncementDialog({
    required this.classroomId,
    required this.isTeacher,
    required this.ref,
    this.announcement,
  });

  @override
  State<_AnnouncementDialog> createState() => _AnnouncementDialogState();
}

class _AnnouncementDialogState extends State<_AnnouncementDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _bodyController;
  final List<PlatformFile> _attachedImages = [];
  bool _isPosting = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.announcement != null ? widget.announcement!.title : '',
    );
    _bodyController = TextEditingController(
      text: widget.announcement?.body ?? '',
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
    );
    if (result != null) {
      setState(() {
        _attachedImages.addAll(result.files);
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _attachedImages.removeAt(index);
    });
  }

  Future<void> _submit() async {
    if (_bodyController.text.trim().isEmpty) return;
    setState(() => _isPosting = true);

    try {
      final actions = AnnouncementActions(widget.ref, widget.classroomId);
      if (widget.announcement != null) {
        await actions.update(
          widget.announcement!.id,
          _titleController.text,
          _bodyController.text,
        );
      } else {
        await actions.create(
          _titleController.text.isEmpty
              ? 'Class Update'
              : _titleController.text,
          _bodyController.text,
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to post: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.announcement != null;
    final dialogTitle = isEditing
        ? 'Edit Announcement'
        : (widget.isTeacher ? 'Post Announcement' : 'Write a comment');

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header ──────────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade200, width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 18,
                      backgroundColor: Color(0xFF1967D2),
                      child: Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        dialogTitle,
                        style: const TextStyle(
                          color: Color(0xFF3C4043),
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.close,
                        color: Color(0xFF5F6368),
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Body ─────────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title field (teacher only)
                    if (widget.isTeacher) ...[
                      _StyledField(
                        controller: _titleController,
                        hint: 'Title (e.g. Important Update)',
                        icon: Icons.title_rounded,
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Message field
                    _StyledField(
                      controller: _bodyController,
                      hint: "What's on your mind?",
                      icon: Icons.chat_bubble_outline_rounded,
                      maxLines: 5,
                    ),

                    // ── Attached images preview ──────────────────────────
                    if (_attachedImages.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      SizedBox(
                        height: 90,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _attachedImages.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(width: 10),
                          itemBuilder: (context, i) {
                            final file = _attachedImages[i];
                            return Stack(
                              clipBehavior: Clip.none,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: file.path != null
                                      ? Image.file(
                                          File(file.path!),
                                          width: 90,
                                          height: 90,
                                          fit: BoxFit.cover,
                                        )
                                      : Container(
                                          width: 90,
                                          height: 90,
                                          color: const Color(0xFFF1F3F4),
                                          child: const Icon(
                                            Icons.image,
                                            color: Colors.white54,
                                          ),
                                        ),
                                ),
                                Positioned(
                                  top: -6,
                                  right: -6,
                                  child: GestureDetector(
                                    onTap: () => _removeImage(i),
                                    child: Container(
                                      width: 22,
                                      height: 22,
                                      decoration: BoxDecoration(
                                        color: Colors.red.shade600,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 2,
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        color: Colors.white,
                                        size: 12,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // ── Toolbar + Post button ─────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Colors.grey.shade200, width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    // Attach photo button
                    _ToolbarButton(
                      icon: Icons.image_outlined,
                      label: 'Photo',
                      onTap: _pickImages,
                    ),
                    const SizedBox(width: 4),
                    // Attach file button (placeholder)
                    _ToolbarButton(
                      icon: Icons.attach_file_rounded,
                      label: 'File',
                      onTap: () async {
                        final result = await FilePicker.platform.pickFiles(
                          allowMultiple: true,
                        );
                        if (result != null) {
                          setState(() {
                            _attachedImages.addAll(
                              result.files.where((f) =>
                                  f.extension != null &&
                                  ['jpg', 'jpeg', 'png', 'gif', 'webp']
                                      .contains(
                                          f.extension!.toLowerCase())),
                            );
                          }); 
                        }
                      },
                    ),
                    const Spacer(),
                    // Cancel
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF5F6368),
                      ),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    // Post
                    FilledButton(
                      onPressed: _isPosting ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF1967D2),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isPosting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              isEditing ? 'Save' : 'Post',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable styled text field for the dialog
// ─────────────────────────────────────────────────────────────────────────────

class _StyledField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final int maxLines;

  const _StyledField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F3F4),
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(color: Color(0xFF3C4043), fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFF80868B), fontSize: 14),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 12, right: 8),
            child: Icon(icon, color: const Color(0xFF80868B), size: 18),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 40,
            minHeight: 0,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 14,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Toolbar attachment button
// ─────────────────────────────────────────────────────────────────────────────

class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ToolbarButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: const Color(0xFF6E4CF5)),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF6E4CF5),
                fontSize: 28,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Inline Announcement Composer
// ─────────────────────────────────────────────────────────────────────────────

class _AnnouncementComposer extends StatefulWidget {
  final String classroomId;
  final bool isTeacher;
  final WidgetRef ref;

  const _AnnouncementComposer({
    required this.classroomId,
    required this.isTeacher,
    required this.ref,
  });

  @override
  State<_AnnouncementComposer> createState() => _AnnouncementComposerState();
}

class _AnnouncementComposerState extends State<_AnnouncementComposer> {
  bool _isExpanded = false;
  late final TextEditingController _titleController;
  late final TextEditingController _bodyController;
  final List<PlatformFile> _attachedImages = [];
  bool _isPosting = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _bodyController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
    );
    if (result != null) {
      if (!_isExpanded) setState(() => _isExpanded = true);
      setState(() {
        _attachedImages.addAll(result.files);
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _attachedImages.removeAt(index);
    });
  }

  Future<void> _submit() async {
    if (_bodyController.text.trim().isEmpty) return;
    setState(() => _isPosting = true);

    try {
      final actions = AnnouncementActions(widget.ref, widget.classroomId);
      await actions.create(
        _titleController.text.isEmpty ? 'Class Update' : _titleController.text,
        _bodyController.text,
      );
      if (mounted) {
        setState(() {
          _isExpanded = false;
          _titleController.clear();
          _bodyController.clear();
          _attachedImages.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to post: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isExpanded) {
      return InkWell(
        onTap: () => setState(() => _isExpanded = true),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 4,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.grey.shade200,
                      child: const Icon(
                        Icons.person,
                        color: Color(0xFF5F6368),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        widget.isTeacher
                            ? 'Announce something to your class...'
                            : 'Communicate with your class...',
                        style: const TextStyle(
                          color: Color(0xFF5F6368),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: Colors.grey.shade200),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: const [
                    Icon(Icons.image_outlined, color: Color(0xFF5F6368), size: 20),
                    SizedBox(width: 20),
                    Icon(Icons.link, color: Color(0xFF5F6368), size: 20),
                    SizedBox(width: 20),
                    Icon(Icons.smart_display_outlined, color: Color(0xFF5F6368), size: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.isTeacher) ...[
                  _StyledField(
                    controller: _titleController,
                    hint: 'Title (e.g. Important Update)',
                    icon: Icons.title_rounded,
                  ),
                  const SizedBox(height: 12),
                ],
                _StyledField(
                  controller: _bodyController,
                  hint: "What's on your mind?",
                  icon: Icons.chat_bubble_outline_rounded,
                  maxLines: 4,
                ),
                if (_attachedImages.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 90,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _attachedImages.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 10),
                      itemBuilder: (context, i) {
                        final file = _attachedImages[i];
                        return Stack(
                          clipBehavior: Clip.none,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: file.path != null
                                  ? Image.file(
                                      File(file.path!),
                                      width: 90,
                                      height: 90,
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      width: 90,
                                      height: 90,
                                      color: const Color(0xFFF1F3F4),
                                      child: const Icon(
                                        Icons.image,
                                        color: Colors.white54,
                                      ),
                                    ),
                            ),
                            Positioned(
                              top: -6,
                              right: -6,
                              child: GestureDetector(
                                onTap: () => _removeImage(i),
                                child: Container(
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade600,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 12,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.grey.shade200, width: 1),
              ),
            ),
            child: Row(
              children: [
                _ToolbarButton(
                  icon: Icons.image_outlined,
                  label: 'Photo',
                  onTap: _pickImages,
                ),
                const SizedBox(width: 4),
                _ToolbarButton(
                  icon: Icons.attach_file_rounded,
                  label: 'File',
                  onTap: () async {
                    final result = await FilePicker.platform.pickFiles(
                      allowMultiple: true,
                    );
                    if (result != null) {
                      setState(() {
                        _attachedImages.addAll(
                          result.files.where((f) =>
                              f.extension != null &&
                              ['jpg', 'jpeg', 'png', 'gif', 'webp']
                                  .contains(f.extension!.toLowerCase())),
                        );
                      });
                    }
                  },
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => setState(() {
                    _isExpanded = false;
                    _titleController.clear();
                    _bodyController.clear();
                    _attachedImages.clear();
                  }),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF5F6368),
                  ),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _isPosting ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF1967D2),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isPosting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Post',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
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
}

