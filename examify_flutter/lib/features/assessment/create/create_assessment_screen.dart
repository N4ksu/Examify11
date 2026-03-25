import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';

import '../../../shared/widgets/app_text_field.dart';
import '../../../core/api/api_client.dart';
import '../../classroom/providers/course_outcomes_provider.dart';
import '../../../shared/providers/assessment_provider.dart';
import '../../../shared/widgets/wizard_bottom_nav.dart';

class CreateAssessmentScreen extends ConsumerStatefulWidget {
  final String classroomId;
  final String? assessmentId;
  const CreateAssessmentScreen({
    super.key,
    required this.classroomId,
    this.assessmentId,
  });

  @override
  ConsumerState<CreateAssessmentScreen> createState() =>
      _CreateAssessmentScreenState();
}

class _CreateAssessmentScreenState
    extends ConsumerState<CreateAssessmentScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _timeLimitController = TextEditingController(text: '60');
  bool _isSaving = false;
  int? _selectedOverallCourseOutcome;
  bool _showScore = true;
  bool _isEditing = false;
  String? _draftId;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.assessmentId != null;
    if (_isEditing) {
      _loadAssessmentData();
    }
  }

  Future<void> _loadAssessmentData() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final id = int.parse(widget.assessmentId!);
        final assessment = await ref.read(assessmentDetailProvider(id).future);
        _titleController.text = assessment.title;
        _descriptionController.text = assessment.description;
        _timeLimitController.text = assessment.timeLimitMinutes.toString();
        _selectedOverallCourseOutcome = assessment.courseOutcomeId;
        _showScore = assessment.showScore;
        if (mounted) setState(() {});
      } catch (e) {
        _showError('Failed to load assessment: $e');
      }
    });
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      _showError('Please enter an assessment title');
      return;
    }

    final timeLimitText = _timeLimitController.text.trim();
    final timeLimit = int.tryParse(timeLimitText);
    if (timeLimit == null || timeLimit < 1) {
      _showError('Time limit must be a positive number (at least 1 minute)');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final dio = ref.read(apiClientProvider);

      final data = {
        'title': _titleController.text,
        'description': _descriptionController.text,
        'type': 'exam',
        'time_limit_minutes': int.tryParse(_timeLimitController.text) ?? 60,
        'is_published': false,
        'course_outcome_id': _selectedOverallCourseOutcome,
        'show_score': _showScore,
      };

      final targetId = _isEditing ? widget.assessmentId : _draftId;
      final isUpdate = targetId != null;

      final response = isUpdate
          ? await dio.patch('/assessments/$targetId', data: data)
          : await dio.post(
              '/classrooms/${widget.classroomId}/assessments',
              data: data,
            );

      if (mounted) {
        final assessmentData = response.data;
        final assessmentId = isUpdate
            ? targetId
            : assessmentData['id'].toString();
            
        if (!isUpdate) {
          _draftId = assessmentId;
        }
        ref.invalidate(assessmentsProvider(int.parse(widget.classroomId)));
        ref.invalidate(assessmentDetailProvider(int.parse(assessmentId)));

        if (_isEditing) {
          context.push(
            '/classrooms/${widget.classroomId}/assessments/$assessmentId/manage-questions',
          );
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Assessment details updated')),
          );
        } else {
          context.push(
            '/classrooms/${widget.classroomId}/assessments/$assessmentId/manage-questions',
          );
          if (!isUpdate) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Assessment created successfully')),
            );
          }
        }
      }
    } on DioException catch (e) {
      _showError(
        'Failed to save assessment: ${e.response?.data['message'] ?? e.message}',
      );
    } catch (e) {
      _showError('An unexpected error occurred: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _buildBody();
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade800,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildBody() {
    final outcomesAsync = ref.watch(
      courseOutcomesProvider(int.parse(widget.classroomId)),
    );

    final theme = ThemeData.light().copyWith(
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF6E4CF5),
        surface: Colors.white,
        onSurface: Color(0xFF3C4043),
      ),
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF6E4CF5),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF1F3F4),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF6E4CF5), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        labelStyle: const TextStyle(color: Color(0xFF5F6368)),
        floatingLabelStyle: const TextStyle(color: Color(0xFF6E4CF5)),
      ),
      dividerColor: const Color(0xFFE8EAED),
    );

    return Theme(
      data: theme,
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F5F9),
        appBar: AppBar(
          title: Text(
            _isEditing ? 'Edit Assessment' : 'Create Assessment',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => context.pop(),
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppTextField(
                            controller: _titleController,
                            label: 'Assessment Title',
                            hint: 'e.g. Midterm Physics',
                          ),
                          const SizedBox(height: 16),
                          AppTextField(
                            controller: _descriptionController,
                            label: 'Description (Optional)',
                            hint: 'Enter instructions or details',
                          ),
                          const SizedBox(height: 16),
                          AppTextField(
                            controller: _timeLimitController,
                            label: 'Time Limit (Minutes)',
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 16),
                          outcomesAsync.when(
                            data: (outcomes) {
                              if (outcomes.isEmpty) return const SizedBox.shrink();
                              return DropdownButtonFormField<int>(
                                value: _selectedOverallCourseOutcome,
                                decoration: const InputDecoration(
                                  labelText: 'Overall Course Outcome (Optional)',
                                ),
                                items: [
                                  const DropdownMenuItem<int>(
                                    value: null,
                                    child: Text('None'),
                                  ),
                                  ...outcomes.map(
                                    (co) => DropdownMenuItem(
                                      value: co.id,
                                      child: Text(co.code),
                                    ),
                                  ),
                                ],
                                onChanged: (val) {
                                  setState(() => _selectedOverallCourseOutcome = val);
                                },
                              );
                            },
                            loading: () => const LinearProgressIndicator(),
                            error: (_, __) => const Text('Failed to load outcomes'),
                          ),
                          const SizedBox(height: 16),
                          SwitchListTile(
                            title: const Text(
                              'Show score to students after submission',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF3C4043),
                              ),
                            ),
                            subtitle: const Text(
                              'If disabled, students will only see a confirmation message.',
                            ),
                            value: _showScore,
                            activeColor: const Color(0xFF6E4CF5),
                            onChanged: (val) {
                              setState(() => _showScore = val);
                            },
                            contentPadding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            WizardBottomNav(
              currentStep: 1,
              onBack: () => context.pop(),
              onNext: _save,
              onStepTap: (step) {
                if (widget.assessmentId != null) {
                  if (step == 2) {
                    context.push(
                      '/classrooms/${widget.classroomId}/assessments/${widget.assessmentId}/manage-questions',
                    );
                  } else if (step == 3) {
                    context.push(
                      '/classrooms/${widget.classroomId}/assessments/${widget.assessmentId}/review',
                    );
                  }
                }
              },
              nextText: _isEditing ? 'Update' : 'Next',
              isNextLoading: _isSaving,
            ),
          ],
        ),
      ),
    );
  }
}
