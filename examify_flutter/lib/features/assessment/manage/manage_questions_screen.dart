// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/models/question.dart';
import '../../../shared/providers/assessment_provider.dart';
import '../../../core/api/api_client.dart';
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
                            color: Colors.black.withValues(alpha: 0.02),
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
                                                    color: const Color(0xFF6E4CF5).withValues(alpha: 0.15),
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
    return Theme(
      data: ThemeData.light().copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6E4CF5),
          primary: const Color(0xFF6E4CF5),
          surface: Colors.white,
        ),
        textTheme: Theme.of(context).textTheme.apply(
          bodyColor: const Color(0xFF1E293B),
          displayColor: const Color(0xFF1E293B),
        ),
      ),
      child: AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF6E4CF5).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add_circle_outline,
                color: Color(0xFF6E4CF5),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              widget.question == null ? 'Add Question' : 'Edit Question',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 600,
          child: SingleChildScrollView(
            child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Question Body',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _bodyController,
                      maxLines: 2,
                      style: const TextStyle(color: Color(0xFF1E293B)),
                      decoration: InputDecoration(
                        hintText: 'Enter your question here...',
                        filled: true,
                        fillColor: const Color(0xFF6E4CF5).withOpacity(0.03),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: const BorderSide(color: Color(0xFF6E4CF5), width: 1.5),
                        ),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty
                          ? 'Please enter the question text'
                          : null,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Question Type',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _type,
                      style: const TextStyle(color: Color(0xFF1E293B), fontSize: 16),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFF6E4CF5).withOpacity(0.03),
                        prefixIcon: const Icon(Icons.category_outlined, size: 20, color: Color(0xFF6E4CF5)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: const BorderSide(color: Color(0xFF6E4CF5), width: 1.5),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'multiple_choice', child: Text('Multiple Choice')),
                        DropdownMenuItem(value: 'multiple_select', child: Text('Multiple Select')),
                        DropdownMenuItem(value: 'true_false', child: Text('True/False')),
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
                  ],
                ),
                if (_type == 'multiple_select') ...[
                  const SizedBox(height: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Scoring Method',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _scoringMethod,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color(0xFF6E4CF5).withOpacity(0.03),
                          prefixIcon: const Icon(Icons.score_outlined, size: 20, color: Color(0xFF6E4CF5)),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: const BorderSide(color: Color(0xFF6E4CF5), width: 1.5),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'exact', child: Text('Exact Match')),
                          DropdownMenuItem(value: 'partial', child: Text('Partial Credit')),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _scoringMethod = val);
                        },
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Points',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _pointsController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Color(0xFF1E293B)),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFF6E4CF5).withOpacity(0.03),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: const BorderSide(color: Color(0xFF6E4CF5), width: 1.5),
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Enter points';
                        final pts = int.tryParse(val);
                        if (pts == null || pts < 1) return 'Must be a positive number';
                        return null;
                      },
                    ),
                  ],
                ),
              if (_type != 'essay') ...[
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Options',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    if (_type == 'multiple_choice' || _type == 'multiple_select')
                      InkWell(
                        onTap: () => setState(
                          () => _options.add({'body': '', 'is_correct': false}),
                        ),
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF6E4CF5).withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.add, size: 16, color: Color(0xFF6E4CF5)),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Add Option',
                                style: TextStyle(
                                  color: Color(0xFF6E4CF5),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                ...List.generate(_options.length, (index) {
                  final isCorrect = _options[index]['is_correct'];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isCorrect ? const Color(0xFF6E4CF5).withOpacity(0.05) : Colors.transparent,
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(
                        color: isCorrect ? const Color(0xFF6E4CF5) : const Color(0xFFE2E8F0),
                        width: isCorrect ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        if (_type == 'multiple_select')
                          Checkbox(
                            value: isCorrect,
                            activeColor: const Color(0xFF6E4CF5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            onChanged: (val) {
                              setState(() {
                                _options[index]['is_correct'] = val ?? false;
                              });
                            },
                          )
                        else
                          Radio<int>(
                            value: index,
                            activeColor: const Color(0xFF6E4CF5),
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
                            style: const TextStyle(color: Color(0xFF1E293B), fontSize: 15),
                            decoration: InputDecoration(
                              hintText: 'Option ${index + 1}',
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              filled: false,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                            ),
                            onChanged: (val) => _options[index]['body'] = val,
                            validator: (val) => val == null || val.trim().isEmpty
                                ? 'Option is empty'
                                : null,
                          ),
                        ),
                        if ((_type == 'multiple_choice' || _type == 'multiple_select') &&
                            _options.length > 2)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: IconButton(
                              icon: const Icon(Icons.remove_circle_outline, color: Color(0xFFEF4444), size: 20),
                              onPressed: () =>
                                  setState(() => _options.removeAt(index)),
                            ),
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
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      actions: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Color(0xFF1E293B),
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
            const SizedBox(width: 16),
            ElevatedButton(
              onPressed: _isSaving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6E4CF5),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
                shape: const StadiumBorder(),
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
                  : const Text(
                      'Save Question',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        letterSpacing: 0.5,
                      ),
                    ),
            ),
          ],
        ),
      ],
    ),
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
