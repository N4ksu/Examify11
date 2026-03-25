import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/teacher_essentials_service.dart';

class BulkUploadScreen extends ConsumerStatefulWidget {
  final int classroomId;
  const BulkUploadScreen({super.key, required this.classroomId});

  @override
  ConsumerState<BulkUploadScreen> createState() => _BulkUploadScreenState();
}

class _BulkUploadScreenState extends ConsumerState<BulkUploadScreen> {
  bool _isUploading = false;
  double _progress = 0;
  String? _statusMessage;

  Future<void> _pickAndUploadFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'xlsx', 'xls'],
    );

    if (result != null) {
      final file = File(result.files.single.path!);
      setState(() {
        _isUploading = true;
        _progress = 0.5;
        _statusMessage = 'Uploading ${result.files.single.name}...';
      });

      try {
        await ref
            .read(teacherEssentialsServiceProvider)
            .uploadStudents(file, widget.classroomId);
        setState(() {
          _progress = 1.0;
          _statusMessage = 'Import successful!';
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Students imported successfully!')),
          );
        }
      } catch (e) {
        setState(() {
          _isUploading = false;
          _statusMessage = 'Error: $e';
        });
      } finally {
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _isUploading = false;
              _progress = 0;
            });
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F7FC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF6E4CF5),
        foregroundColor: Colors.white,
        title: const Text(
          'Bulk Student Upload',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: const Color(0xFFD8E3EF)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF223B6A).withOpacity(0.08),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF6E4CF5),
                          Color(0xFF49A5FF),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(
                      Icons.upload_file_rounded,
                      size: 42,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Upload Student CSV',
                    style: TextStyle(
                      color: Color(0xFF2F3E58),
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Format: name, email, student_id, section',
                    style: TextStyle(
                      color: Color(0xFF7B8AA2),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 32),
                  if (_isUploading) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: _progress,
                        minHeight: 12,
                        backgroundColor: const Color(0xFFE7EEF6),
                        valueColor: const AlwaysStoppedAnimation(Color(0xFF6E4CF5)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _statusMessage ?? '',
                      style: const TextStyle(
                        color: Color(0xFF5F708A),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ] else
                    ElevatedButton.icon(
                      onPressed: _pickAndUploadFile,
                      icon: const Icon(Icons.add),
                      label: const Text('Select File'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6E4CF5),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
