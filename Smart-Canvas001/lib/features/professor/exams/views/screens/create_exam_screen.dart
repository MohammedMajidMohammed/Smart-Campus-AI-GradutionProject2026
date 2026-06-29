import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smart_canvas/core/utilies/colors/app_colors.dart';
import 'package:smart_canvas/features/professor/exams/models/exam_model.dart';
import 'package:smart_canvas/features/professor/exams/view_models/cubit/exams_cubit.dart';
import 'package:smart_canvas/features/professor/exams/views/screens/exam_questions_screen.dart';

class CreateExamScreen extends StatefulWidget {
  final ExamModel? exam;
  const CreateExamScreen({super.key, this.exam});

  @override
  State<CreateExamScreen> createState() => _CreateExamScreenState();
}

class _CreateExamScreenState extends State<CreateExamScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _durationController = TextEditingController(text: '60');

  String? _selectedSubjectId;
  DateTime _openAt = DateTime.now();
  DateTime _closeAt = DateTime.now().add(const Duration(hours: 2));
  bool _isLoading = false;
  List<Map<String, dynamic>> _subjects = [];
  bool _loadingSubjects = true;

  @override
  void initState() {
    super.initState();
    if (widget.exam != null) {
      _titleController.text = widget.exam!.title;
      _descriptionController.text = widget.exam!.description ?? '';
      _durationController.text = widget.exam!.durationMinutes.toString();
      _openAt = widget.exam!.openAt.toLocal();
      _closeAt = widget.exam!.closeAt.toLocal();
      _selectedSubjectId = widget.exam!.subjectId;
    }
    _loadSubjects();
  }

  Future<void> _loadSubjects() async {
    final cubit = ExamsCubit();
    final subjects = await cubit.loadProfessorSubjects();
    if (mounted) {
      setState(() {
        _subjects = subjects;
        _loadingSubjects = false;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gradColors = isDark
        ? [const Color(0xFF1E1B15), const Color(0xFF2A2720)]
        : [AppColors.kPrimaryColor, const Color(0xFF1E8449)];

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0E0A) : const Color(0xFFFAF9F5),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ──── PREMIUM HEADER ────
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            elevation: 0,
            backgroundColor: gradColors[0],
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              title: Text(
                widget.exam != null ? 'Edit Exam' : 'Create Exam',
                style: const TextStyle(
                  fontWeight: FontWeight.w900, 
                  fontSize: 22, 
                  letterSpacing: -0.5,
                  color: Colors.white,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(top: -50, right: -30,
                      child: Container(width: 180, height: 180,
                        decoration: BoxDecoration(shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.08)))),
                    Positioned(bottom: -20, left: -20,
                      child: Container(width: 120, height: 120,
                        decoration: BoxDecoration(shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.06)))),
                    Positioned(top: 40, right: 60,
                      child: Container(width: 50, height: 50,
                        decoration: BoxDecoration(shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.1)))),
                    // Center icon
                    Positioned(
                      right: 30, top: 50,
                      child: Icon(Icons.quiz_rounded, size: 80,
                        color: Colors.white.withValues(alpha: 0.08)),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ──── FORM ────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Subject
                    _sectionLabel('Subject', isDark),
                    const SizedBox(height: 8),
                    _buildSubjectDropdown(isDark),
                    const SizedBox(height: 24),

                    // Title
                    _sectionLabel('Exam Title', isDark),
                    const SizedBox(height: 8),
                    _buildField(
                      controller: _titleController,
                      hint: 'e.g. Midterm Exam - Chapter 1-5',
                      icon: Icons.title_rounded,
                      isDark: isDark,
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 24),

                    // Description
                    _sectionLabel('Description (Optional)', isDark),
                    const SizedBox(height: 8),
                    _buildField(
                      controller: _descriptionController,
                      hint: 'Instructions for students...',
                      icon: Icons.description_outlined,
                      isDark: isDark,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),

                    // Duration
                    _sectionLabel('Duration (minutes)', isDark),
                    const SizedBox(height: 8),
                    _buildField(
                      controller: _durationController,
                      hint: '60',
                      icon: Icons.timer_outlined,
                      isDark: isDark,
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        if (int.tryParse(v) == null) return 'Must be a number';
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Date pickers
                    Row(
                      children: [
                        Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _sectionLabel('Opens At', isDark),
                            const SizedBox(height: 8),
                            _buildDatePicker(_openAt, isDark, (dt) => setState(() => _openAt = dt)),
                          ],
                        )),
                        const SizedBox(width: 12),
                        Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _sectionLabel('Closes At', isDark),
                            const SizedBox(height: 8),
                            _buildDatePicker(_closeAt, isDark, (dt) => setState(() => _closeAt = dt)),
                          ],
                        )),
                      ],
                    ),
                    const SizedBox(height: 36),

                    // Create button
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: const LinearGradient(
                            colors: [AppColors.kPrimaryColor, Color(0xFF2ECC71)],
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
                          borderRadius: BorderRadius.circular(16),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: _isLoading ? null : _saveExam,
                            child: Center(
                              child: _isLoading
                                  ? const SizedBox(width: 22, height: 22,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                                  : Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.add_rounded, color: Colors.white, size: 22),
                                        const SizedBox(width: 8),
                                        Text(widget.exam != null ? 'Update Exam Details' : 'Create & Add Questions',
                                          style: const TextStyle(color: Colors.white,
                                            fontWeight: FontWeight.w700, fontSize: 16)),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label, bool isDark) {
    return Text(label, style: TextStyle(
      fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 0.3,
      color: isDark ? Colors.white60 : Colors.black54,
    ));
  }

  Widget _buildSubjectDropdown(bool isDark) {
    if (_loadingSubjects) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1B15) : Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: SizedBox(width: 20, height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.kPrimaryColor)),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1B15) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10, offset: const Offset(0, 3),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: _selectedSubjectId,
          hint: Text('Select Subject', style: TextStyle(
            color: isDark ? Colors.white30 : Colors.grey.shade400,
          )),
          dropdownColor: isDark ? const Color(0xFF1E1B15) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          icon: Icon(Icons.keyboard_arrow_down_rounded,
            color: isDark ? Colors.white30 : Colors.grey.shade400),
          items: _subjects.map((s) {
            return DropdownMenuItem<String>(
              value: s['id'].toString(),
              child: Text(s['name'].toString(), style: TextStyle(
                color: isDark ? Colors.white : AppColors.kPrimaryColor)),
            );
          }).toList(),
          onChanged: (v) {
            setState(() {
              _selectedSubjectId = v;
            });
          },
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required bool isDark,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: isDark ? Colors.white24 : Colors.grey.shade400),
        prefixIcon: Icon(icon, color: isDark ? Colors.white24 : Colors.grey.shade400, size: 20),
        filled: true,
        fillColor: isDark ? const Color(0xFF1E1B15) : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.kPrimaryColor, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildDatePicker(DateTime value, bool isDark, ValueChanged<DateTime> onChanged) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context, initialDate: value,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (date == null || !mounted) return;
        final time = await showTimePicker(
          context: context, initialTime: TimeOfDay.now(),
        );
        if (time == null) return;
        onChanged(DateTime(date.year, date.month, date.day, time.hour, time.minute));
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1B15) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade200,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
              blurRadius: 10, offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.calendar_today_rounded, size: 14,
                  color: AppColors.kPrimaryColor),
                const SizedBox(width: 6),
                Text(DateFormat('MMM dd, yyyy').format(value), style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                )),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.access_time_rounded, size: 14,
                  color: AppColors.kPrimaryColor),
                const SizedBox(width: 6),
                Text(DateFormat('hh:mm a').format(value), style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white54 : Colors.black54,
                )),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveExam() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSubjectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a subject'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    if (_closeAt.isBefore(_openAt)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Close time must be after open time'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final cubit = ExamsCubit();
    
    if (widget.exam != null) {
      // Edit Mode
      final success = await cubit.updateExam(
        examId: widget.exam!.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
        openAt: _openAt,
        closeAt: _closeAt,
        durationMinutes: int.parse(_durationController.text.trim()),
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Exam updated successfully'),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to update exam'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } else {
      // Create Mode
      final examId = await cubit.createExam(
        subjectId: _selectedSubjectId!,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
        openAt: _openAt,
        closeAt: _closeAt,
        durationMinutes: int.parse(_durationController.text.trim()),
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (examId != null) {
        Navigator.pushReplacement(context, MaterialPageRoute(
          builder: (_) => ExamQuestionsScreen(
            examId: examId, examTitle: _titleController.text.trim(),
          ),
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to create exam'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }
}
