import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/models/question.dart';
import '../../../shared/providers/assessment_provider.dart';
import '../../../core/api/api_client.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/wizard_bottom_nav.dart';

class ManageQuestionsScreen extends ConsumerStatefulWidget {
  final String assessmentId;
  final String classroomId;
  const ManageQuestionsScreen({
    super.key,
    required this.assessmentId,
    required this.classroomId,
  });

  @override
  ConsumerState<ManageQuestionsScreen> createState() =>
      _ManageQuestionsScreenState();
}

class _ManageQuestionsScreenState extends ConsumerState<ManageQuestionsScreen> {
  late final int _assessmentIdInt;

  @override
  void initState() {
    super.initState();
    _assessmentIdInt = int.parse(widget.assessmentId);
  }

  void _refresh() {
    ref.invalidate(questionsProvider(_assessmentIdInt));
    ref.invalidate(assessmentDetailProvider(_assessmentIdInt));
  }

  Future<void> _deleteQuestion(int questionId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Question'),
        content: const Text('Are you sure you want to delete this question?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final api = ref.read(apiClientProvider);
        await api.delete('/questions/$questionId');
        _refresh();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
        }
      }
    }
  }

  void _showQuestionDialog([Question? question]) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => QuestionDialog(
        assessmentId: _assessmentIdInt,
        question: question,
        onSave: _refresh,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final questionsAsync = ref.watch(questionsProvider(_assessmentIdInt));

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9), // Light grayish-blue background
      appBar: AppBar(
        title: const Text(
          'Manage Questions',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF6E4CF5), // Violet AppBar
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: questionsAsync.when(
              data: (questions) => SingleChildScrollView(
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
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Questions List',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (questions.isEmpty)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(24.0),
                                child: Text(
                                  'No questions added yet.',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                            )
                          else
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: questions.length,
                              itemBuilder: (context, index) {
                                final q = questions[index];
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8F7FF), // Light lavender/purple
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 20,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              q.body,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18,
                                                color: Color(0xFF1E293B),
                                              ),
                                            ),
                                            const SizedBox(height: 12),
                                            Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 6,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFF6E4CF5).withOpacity(0.15),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Text(
                                                    q.type.toUpperCase(),
                                                    style: const TextStyle(
                                                      color: Color(0xFF6E4CF5),
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w800,
                                                      letterSpacing: 0.5,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Text(
                                                  '${q.points} pt${q.points > 1 ? 's' : ''}',
                                                  style: const TextStyle(
                                                    color: Color(0xFF6E4CF5),
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      _CircleActionButton(
                                        icon: Icons.edit_outlined,
                                        onPressed: () => _showQuestionDialog(q),
                                      ),
                                      const SizedBox(width: 8),
                                      _CircleActionButton(
                                        icon: Icons.delete_outline,
                                        onPressed: () => _deleteQuestion(q.id),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          const SizedBox(height: 24),
                          Center(
                            child: ElevatedButton.icon(
                              onPressed: () => _showQuestionDialog(),
                              icon: const Icon(Icons.add, size: 20),
                              label: const Text(
                                'Add Question',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6E4CF5),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
          WizardBottomNav(
            currentStep: 2,
            onBack: () => context.pop(),
            onNext: () {
              context.push(
                '/classrooms/${widget.classroomId}/assessments/${widget.assessmentId}/review',
              );
            },
            onStepTap: (step) {
              if (step == 1) {
                context.push(
                  '/classrooms/${widget.classroomId}/assessments/${widget.assessmentId}/edit',
                );
              } else if (step == 3) {
                context.push(
                  '/classrooms/${widget.classroomId}/assessments/${widget.assessmentId}/review',
                );
              }
            },
            nextText: 'Review',
          ),
        ],
      ),
    );
  }
}

class QuestionDialog extends ConsumerStatefulWidget {
  final int assessmentId;
  final Question? question;
  final VoidCallback onSave;

  const QuestionDialog({
    super.key,
    required this.assessmentId,
    this.question,
    required this.onSave,
  });

  @override
  ConsumerState<QuestionDialog> createState() => _QuestionDialogState();
}

class _QuestionDialogState extends ConsumerState<QuestionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _bodyController = TextEditingController();
  final _pointsController = TextEditingController(text: '1');
  String _type = 'multiple_choice';
  String _scoringMethod = 'exact';
  List<Map<String, dynamic>> _options = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.question != null) {
      _bodyController.text = widget.question!.body;
      _pointsController.text = widget.question!.points.toString();
      _type = widget.question!.type;
      _scoringMethod = widget.question!.scoringMethod;
      _options = widget.question!.options
          .map((o) => {'body': o.body, 'is_correct': o.isCorrect})
          .toList();
    } else {
      _resetOptions();
    }
  }

  void _resetOptions() {
    if (_type == 'multiple_choice' || _type == 'multiple_select') {
      _options = [
        {'body': '', 'is_correct': true},
        {'body': '', 'is_correct': false},
      ];
    } else if (_type == 'true_false') {
      _options = [
        {'body': 'True', 'is_correct': true},
        {'body': 'False', 'is_correct': false},
      ];
    } else {
      _options = [];
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_bodyController.text.trim().isEmpty) return;

    // Validation: ensure at least one correct option for non-essay questions
    if (_type != 'essay') {
      final hasCorrect = _options.any((o) => o['is_correct'] == true);
      if (!hasCorrect) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please mark at least one option as correct.')),
        );
        return;
      }
    }

    setState(() => _isSaving = true);

    try {
      final api = ref.read(apiClientProvider);
      final data = {
        'body': _bodyController.text.trim(),
        'type': _type,
        'points': int.tryParse(_pointsController.text) ?? 1,
        'scoring_method': _scoringMethod,
        if (_type != 'essay') 'options': _options,
      };

      if (widget.question == null) {
        await api.post(
          '/assessments/${widget.assessmentId}/questions',
          data: data,
        );
      } else {
        await api.put('/questions/${widget.question!.id}', data: data);
      }

      widget.onSave();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save: $e')));
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.question == null ? 'Add Question' : 'Edit Question'),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppTextField(
                  label: 'Question Body',
                  controller: _bodyController,
                  validator: (val) => val == null || val.trim().isEmpty
                      ? 'Please enter the question text'
                      : null,
                ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _type,
                decoration: const InputDecoration(labelText: 'Type'),
                items: const [
                  DropdownMenuItem(
                    value: 'multiple_choice',
                    child: Text('Multiple Choice'),
                  ),
                  DropdownMenuItem(
                    value: 'multiple_select',
                    child: Text('Multiple Select'),
                  ),
                  DropdownMenuItem(
                    value: 'true_false',
                    child: Text('True/False'),
                  ),
                  DropdownMenuItem(value: 'essay', child: Text('Essay')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _type = val;
                      _resetOptions();
                    });
                  }
                },
              ),
              if (_type == 'multiple_select') ...[
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _scoringMethod,
                  decoration: const InputDecoration(labelText: 'Scoring Method'),
                  items: const [
                    DropdownMenuItem(
                      value: 'exact',
                      child: Text('Exact Match (all correct required)'),
                    ),
                    DropdownMenuItem(
                      value: 'partial',
                      child: Text('Partial Credit (points per correct)'),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _scoringMethod = val;
                      });
                    }
                  },
                ),
              ],
              const SizedBox(height: 16),
              AppTextField(
                label: 'Points',
                controller: _pointsController,
                keyboardType: TextInputType.number,
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Enter points';
                  final pts = int.tryParse(val);
                  if (pts == null || pts < 1) return 'Must be a positive number';
                  return null;
                },
              ),
              if (_type != 'essay') ...[
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Options',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    if (_type == 'multiple_choice' || _type == 'multiple_select')
                      TextButton.icon(
                        onPressed: () => setState(
                          () => _options.add({'body': '', 'is_correct': false}),
                        ),
                        icon: const Icon(Icons.add),
                        label: const Text('Add Option'),
                      ),
                  ],
                ),
                ...List.generate(_options.length, (index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      children: [
                        if (_type == 'multiple_select')
                          Checkbox(
                            value: _options[index]['is_correct'],
                            activeColor: const Color(0xFF6E4CF5),
                            onChanged: (val) {
                              setState(() {
                                _options[index]['is_correct'] = val ?? false;
                              });
                            },
                          )
                        else
                          Radio<int>(
                            value: index,
                            activeColor: const Color(0xFF6E4CF5), // Violet Radio
                            groupValue: _options.indexWhere(
                              (o) => o['is_correct'] == true,
                            ),
                            onChanged: (val) {
                              if (val == null) return;
                              setState(() {
                                for (var i = 0; i < _options.length; i++) {
                                  _options[i]['is_correct'] = (i == val);
                                }
                              });
                            },
                          ),
                        Expanded(
                          child: TextFormField(
                            initialValue: _options[index]['body'],
                            decoration: InputDecoration(
                              hintText: 'Option ${index + 1}',
                            ),
                            onChanged: (val) => _options[index]['body'] = val,
                            validator: (val) => val == null || val.trim().isEmpty
                                ? 'Option is empty'
                                : null,
                          ),
                        ),
                        if ((_type == 'multiple_choice' || _type == 'multiple_select') &&
                            _options.length > 2)
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () =>
                                setState(() => _options.removeAt(index)),
                          ),
                      ],
                    ),
                  );
                }),
              ],
            ],
          ),
        ),
      ),
    ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6E4CF5),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}

class _CircleActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _CircleActionButton({
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: const Color(0xFF6E4CF5), size: 20),
        onPressed: onPressed,
      ),
    );
  }
}
