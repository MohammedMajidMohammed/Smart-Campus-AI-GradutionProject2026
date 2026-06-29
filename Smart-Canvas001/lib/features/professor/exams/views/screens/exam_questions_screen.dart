import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:smart_canvas/core/utilies/colors/app_colors.dart';
import 'package:smart_canvas/features/professor/exams/models/exam_question_model.dart';
import 'package:smart_canvas/features/professor/exams/view_models/cubit/exams_cubit.dart';

class ExamQuestionsScreen extends StatefulWidget {
  final String examId;
  final String examTitle;

  const ExamQuestionsScreen({
    super.key,
    required this.examId,
    required this.examTitle,
  });

  @override
  State<ExamQuestionsScreen> createState() => _ExamQuestionsScreenState();
}

class _ExamQuestionsScreenState extends State<ExamQuestionsScreen> {
  final _cubit = ExamsCubit();
  List<ExamQuestionModel> _questions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    setState(() => _isLoading = true);
    _questions = await _cubit.loadQuestions(widget.examId);
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0E0A) : const Color(0xFFFAF9F5),
      appBar: AppBar(
        title: Text(widget.examTitle, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 22, color: Colors.white, letterSpacing: -0.5)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark 
                  ? [const Color(0xFF1E1B15), const Color(0xFF2A2720)]
                  : [AppColors.kPrimaryColor, const Color(0xFF1E8449)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.format_list_bulleted_rounded, color: Colors.white, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      '${_questions.length} Q',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _questions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.kPrimaryColor.withValues(alpha: 0.1),
                        ),
                        child: const Icon(LineIcons.questionCircle,
                            size: 56, color: AppColors.kPrimaryColor),
                      ),
                      const SizedBox(height: 20),
                      Text('No Questions Yet',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87)),
                      const SizedBox(height: 8),
                      Text('Tap + to add questions',
                          style: TextStyle(color: isDark ? Colors.white54 : Colors.black45)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadQuestions,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _questions.length,
                    itemBuilder: (context, index) {
                      final q = _questions[index];
                      return _QuestionCard(
                        question: q,
                        index: index,
                        isDark: isDark,
                        onDelete: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (c) => AlertDialog(
                              title: const Text('Delete Question?'),
                              content: const Text('This action cannot be undone.'),
                              actions: [
                                TextButton(
                                    onPressed: () => Navigator.pop(c, false),
                                    child: const Text('Cancel')),
                                TextButton(
                                    onPressed: () => Navigator.pop(c, true),
                                    child: const Text('Delete',
                                        style: TextStyle(color: Colors.red))),
                              ],
                            ),
                          );
                          if (confirmed == true) {
                            await _cubit.deleteQuestion(q.id);
                            _loadQuestions();
                          }
                        },
                      );
                    },
                  ),
                ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [AppColors.kPrimaryColor, Color(0xFF1E8449)],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.kPrimaryColor.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () => _showAddQuestionDialog(context, isDark),
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  void _showAddQuestionDialog(BuildContext context, bool isDark) {
    final questionController = TextEditingController();
    final correctAnswerController = TextEditingController();
    final option1 = TextEditingController();
    final option2 = TextEditingController();
    final option3 = TextEditingController();
    final option4 = TextEditingController();
    final pointsController = TextEditingController(text: '1');
    String type = 'mcq';
    int selectedCorrectOptionIndex = -1;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1B15) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                // Handle
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.kPrimaryColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.dashboard_customize_rounded, color: AppColors.kPrimaryColor, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          'Add Question',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Type toggle
                      Container(
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0F0E0A) : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            _typeChip('MCQ', type == 'mcq', isDark, () {
                              setModalState(() => type = 'mcq');
                            }),
                            _typeChip('Essay', type == 'essay', isDark, () {
                              setModalState(() => type = 'essay');
                            }),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        // Question text
                        _dialogTextField(
                          controller: questionController,
                          label: 'Question Text',
                          hint: 'Enter the question...',
                          isDark: isDark,
                          maxLines: 3,
                        ),
                        const SizedBox(height: 16),

                        // Points
                        _dialogTextField(
                          controller: pointsController,
                          label: 'Points',
                          hint: '1',
                          isDark: isDark,
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 16),

                        if (type == 'mcq') ...[
                          // MCQ Options
                          Text(
                            'Options',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _dialogTextField(
                            controller: option1,
                            label: '',
                            hint: 'Option A Text...',
                            isDark: isDark,
                            prefixIcon: _buildOptionBadge('A', isDark),
                          ),
                          const SizedBox(height: 10),
                          _dialogTextField(
                            controller: option2,
                            label: '',
                            hint: 'Option B Text...',
                            isDark: isDark,
                            prefixIcon: _buildOptionBadge('B', isDark),
                          ),
                          const SizedBox(height: 10),
                          _dialogTextField(
                            controller: option3,
                            label: '',
                            hint: 'Option C Text...',
                            isDark: isDark,
                            prefixIcon: _buildOptionBadge('C', isDark),
                          ),
                          const SizedBox(height: 10),
                          _dialogTextField(
                            controller: option4,
                            label: '',
                            hint: 'Option D Text...',
                            isDark: isDark,
                            prefixIcon: _buildOptionBadge('D', isDark),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Select Correct Answer',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: List.generate(4, (index) {
                              final isSelected = selectedCorrectOptionIndex == index;
                              final letter = ['A', 'B', 'C', 'D'][index];
                              return Expanded(
                                child: Padding(
                                  padding: EdgeInsets.only(
                                    left: index == 0 ? 0 : 4,
                                    right: index == 3 ? 0 : 4,
                                  ),
                                  child: GestureDetector(
                                    onTap: () {
                                      setModalState(() {
                                        selectedCorrectOptionIndex = index;
                                      });
                                    },
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      height: 56,
                                      decoration: BoxDecoration(
                                        color: isSelected ? AppColors.kPrimaryColor : (isDark ? const Color(0xFF0F0E0A) : Colors.white),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: isSelected ? AppColors.kPrimaryColor : (isDark ? Colors.white12 : Colors.grey.shade300),
                                          width: isSelected ? 2 : 1.5,
                                        ),
                                        boxShadow: isSelected ? [
                                          BoxShadow(color: AppColors.kPrimaryColor.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))
                                        ] : [],
                                      ),
                                      child: Center(
                                        child: Text(
                                          letter,
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w900,
                                            color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black54),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ] else ...[
                          // Essay reference answer
                          _dialogTextField(
                            controller: correctAnswerController,
                            label: 'Reference Answer (Optional)',
                            hint: 'Provide the model answer for your reference during grading',
                            isDark: isDark,
                            maxLines: 4,
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.2)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.info_outline, size: 16, color: Color(0xFFF59E0B)),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Essay questions require manual grading by the professor.',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? Colors.white60 : Colors.black54,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),

                        // Add button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              gradient: const LinearGradient(
                                colors: [AppColors.kPrimaryColor, Color(0xFF1E8449)],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.kPrimaryColor.withValues(alpha: 0.35),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(14),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap: () async {
                                  if (questionController.text.trim().isEmpty) return;

                                  List<String>? options;
                                  if (type == 'mcq') {
                                    if (selectedCorrectOptionIndex == -1) return; // Must select an answer

                                    options = [
                                      option1.text.trim(),
                                      option2.text.trim(),
                                      option3.text.trim(),
                                      option4.text.trim(),
                                    ].where((o) => o.isNotEmpty).toList();

                                    if (options.length < 2) return;
                                    correctAnswerController.text = [option1.text, option2.text, option3.text, option4.text][selectedCorrectOptionIndex].trim();
                                  } else {
                                     if (correctAnswerController.text.trim().isEmpty) return;
                                  }

                                  final question = ExamQuestionModel(
                                    id: '',
                                    examId: widget.examId,
                                    questionType: type,
                                    questionText: questionController.text.trim(),
                                    options: options,
                                    correctAnswer: correctAnswerController.text.trim(),
                                    points: int.tryParse(pointsController.text) ?? 1,
                                    sortOrder: _questions.length,
                                  );

                                  final navigator = Navigator.of(context);
                                  final success = await _cubit.addQuestion(question);
                                  if (success && mounted) {
                                    navigator.pop();
                                    _loadQuestions();
                                  }
                                },
                                child: const Center(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.check, size: 20, color: Colors.white),
                                      SizedBox(width: 8),
                                      Text('Add Question',
                                          style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 15)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _typeChip(String label, bool selected, bool isDark, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.kPrimaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: selected ? [
            BoxShadow(color: AppColors.kPrimaryColor.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))
          ] : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: selected ? FontWeight.bold : FontWeight.w600,
            color: selected ? Colors.white : (isDark ? Colors.white54 : Colors.black54),
          ),
        ),
      ),
    );
  }

  Widget _dialogTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool isDark,
    int maxLines = 1,
    TextInputType? keyboardType,
    Widget? prefixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
          ),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: isDark ? Colors.white30 : Colors.grey.shade400, fontWeight: FontWeight.normal),
            filled: true,
            fillColor: isDark ? const Color(0xFF0F0E0A) : Colors.grey.shade50,
            prefixIcon: prefixIcon,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.kPrimaryColor, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildOptionBadge(String letter, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      child: Container(
        width: 36,
        decoration: BoxDecoration(
          color: AppColors.kPrimaryColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            letter,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              color: AppColors.kPrimaryColor,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  final ExamQuestionModel question;
  final int index;
  final bool isDark;
  final VoidCallback onDelete;

  const _QuestionCard({
    required this.question,
    required this.index,
    required this.isDark,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isMcq = question.isMcq;
    final accentColor = isMcq ? AppColors.kPrimaryColor : const Color(0xFFF59E0B);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1B15) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade200,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.02) : Colors.grey.shade50,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              border: Border(bottom: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100)),
            ),
            child: Row(
              children: [
                // Q Number Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [accentColor, accentColor.withValues(alpha: 0.8)]),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(color: accentColor.withValues(alpha: 0.3), blurRadius: 4, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Text(
                    'Q${index + 1}',
                    style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 13),
                  ),
                ),
                const SizedBox(width: 12),
                // Type Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: accentColor.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(isMcq ? Icons.radio_button_checked : Icons.edit_note, size: 12, color: accentColor),
                      const SizedBox(width: 4),
                      Text(
                        isMcq ? 'MCQ' : 'Essay',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: accentColor),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Points Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.star_rounded, size: 12, color: isDark ? Colors.white54 : Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        '${question.points} pts',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isDark ? Colors.white54 : Colors.grey.shade700),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Delete action
                Material(
                  color: Colors.transparent,
                  shape: const CircleBorder(),
                  child: InkWell(
                    onTap: onDelete,
                    customBorder: const CircleBorder(),
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Icon(Icons.delete_outline_rounded, color: Colors.red.shade400, size: 20),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Question Content
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  question.questionText,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black87,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                
                // MCQ Options
                if (isMcq && question.options != null)
                  ...question.options!.asMap().entries.map((entry) {
                    return _buildOptionItem(
                      optionText: entry.value,
                      optionIndex: entry.key,
                      isCorrect: entry.value == question.correctAnswer,
                      isDark: isDark,
                    );
                  }),
                  
                // Essay Answer
                if (!isMcq)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.03) : const Color(0xFFFAF9F5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade200),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(LineIcons.key, size: 18, color: isDark ? Colors.white54 : Colors.grey.shade500),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Reference Keywords',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white54 : Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                question.correctAnswer,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDark ? Colors.white70 : Colors.black87,
                                  fontWeight: FontWeight.w500,
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
        ],
      ),
    );
  }

  Widget _buildOptionItem({
    required String optionText, 
    required int optionIndex, 
    required bool isCorrect, 
    required bool isDark
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isCorrect
            ? AppColors.kPrimaryColor.withValues(alpha: 0.06)
            : (isDark ? const Color(0xFF0F0E0A) : Colors.white),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCorrect
              ? AppColors.kPrimaryColor.withValues(alpha: 0.4)
              : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade200),
          width: isCorrect ? 1.5 : 1,
        ),
        boxShadow: isCorrect || isDark ? [] : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isCorrect 
                  ? AppColors.kPrimaryColor 
                  : (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade100),
              shape: BoxShape.circle,
            ),
            child: Text(
              String.fromCharCode(65 + optionIndex),
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: isCorrect ? Colors.white : (isDark ? Colors.white70 : Colors.black54),
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              optionText,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontWeight: isCorrect ? FontWeight.w700 : FontWeight.w500,
                fontSize: 15,
              ),
            ),
          ),
          if (isCorrect) ...[
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.kPrimaryColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded, color: AppColors.kPrimaryColor, size: 16),
            ),
          ]
        ],
      ),
    );
  }
}
