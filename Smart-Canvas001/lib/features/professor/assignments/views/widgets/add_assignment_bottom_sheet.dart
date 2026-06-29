import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:line_icons/line_icons.dart';
import 'package:smart_canvas/core/cache/cache_helper.dart';
import 'package:smart_canvas/core/di/dependancy_injection.dart';
import 'package:smart_canvas/features/professor/assignments/models/assignment_model.dart';
import 'package:smart_canvas/features/admin/subjects/models/subject_model.dart';
import 'package:smart_canvas/features/professor/assignments/view_models/doctor_assignment_cubit.dart';

class AddAssignmentBottomSheet extends StatefulWidget {
  final List<SubjectModel> subjects;
  final AssignmentModel? assignment;

  const AddAssignmentBottomSheet({
    super.key,
    required this.subjects,
    this.assignment,
  });

  @override
  State<AddAssignmentBottomSheet> createState() => _AddAssignmentBottomSheetState();
}

class _AddAssignmentBottomSheetState extends State<AddAssignmentBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _linkController;
  DateTime? _selectedDate;
  DateTime? _startDate;
  SubjectModel? _selectedSubject;
  File? _selectedFile;
  String? _fileExt;

  bool get isEditMode => widget.assignment != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.assignment?.title);
    _descriptionController = TextEditingController(text: widget.assignment?.description);
    _linkController = TextEditingController(text: widget.assignment?.link);
    _selectedDate = widget.assignment?.dueDate;
    _startDate = widget.assignment?.startDate ?? widget.assignment?.createdAt;
    
    if (isEditMode) {
      _selectedSubject = widget.subjects.firstWhere(
        (s) => s.id == widget.assignment!.subjectId,
        orElse: () => widget.subjects.first,
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isDue}) async {
    final initialDate = isDue 
        ? (_selectedDate ?? DateTime.now().add(const Duration(days: 7)))
        : (_startDate ?? DateTime.now());

    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFF2ECC71)),
        ),
        child: child!,
      ),
    );
    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initialDate),
      );
      if (time != null) {
        setState(() {
          if (isDue) {
            _selectedDate = DateTime(date.year, date.month, date.day, time.hour, time.minute);
          } else {
            _startDate = DateTime(date.year, date.month, date.day, time.hour, time.minute);
          }
        });
      }
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'png'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
        _fileExt = result.files.single.extension;
      });
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate() && _selectedDate != null && _selectedSubject != null) {
      final user = getIt<CacheHelper>().getUserModel();
      if (user == null) return;

      final assignment = AssignmentModel(
        id: isEditMode ? widget.assignment!.id : const Uuid().v4(),
        subjectId: _selectedSubject!.id,
        professorId: user.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        link: _linkController.text.trim().isEmpty ? null : _linkController.text.trim(),
        startDate: _startDate,
        dueDate: _selectedDate!,
        createdAt: isEditMode ? widget.assignment!.createdAt : DateTime.now(),
        fileUrl: isEditMode ? widget.assignment!.fileUrl : null,
      );

      if (isEditMode) {
        context.read<DoctorAssignmentCubit>().editAssignment(assignment, _selectedFile, _fileExt);
      } else {
        context.read<DoctorAssignmentCubit>().addAssignment(assignment, _selectedFile, _fileExt);
      }
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete required fields and select dates'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 24, right: 24, top: 12
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1B15) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 40,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle Bar
              Center(
                child: Container(
                  width: 50, height: 6,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(10)
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Header Section
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2ECC71).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      isEditMode ? LineIcons.edit : LineIcons.tasks, 
                      color: const Color(0xFF2ECC71), 
                      size: 28
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEditMode ? "Update Task" : "New Task",
                          style: TextStyle(
                            fontSize: 22, 
                            fontWeight: FontWeight.w900, 
                            color: isDark ? Colors.white : const Color(0xFF0F0E0A),
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isEditMode ? "Modify task details and dates" : "Create a new assignment for students",
                          style: TextStyle(
                            color: isDark ? Colors.white38 : Colors.grey.shade500, 
                            fontSize: 12, 
                            fontWeight: FontWeight.w600
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.close_rounded,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Title input
              TextFormField(
                controller: _titleController,
                style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1E1B15), fontWeight: FontWeight.w700),
                decoration: InputDecoration(
                  labelText: 'Task Title',
                  filled: true,
                  fillColor: isDark ? Colors.white.withValues(alpha: 0.02) : const Color(0xFFFAF9F5),
                  labelStyle: TextStyle(color: isDark ? Colors.white38 : Colors.grey.shade500, fontWeight: FontWeight.w600),
                  prefixIcon: const Icon(LineIcons.edit, color: Color(0xFF2ECC71)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade200, width: 1.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFF2ECC71), width: 2),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
                validator: (value) => value == null || value.trim().isEmpty ? 'Please enter a title' : null,
              ),
              const SizedBox(height: 18),

              // Description input
              TextFormField(
                controller: _descriptionController,
                style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1E1B15), fontWeight: FontWeight.w700),
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Description (Optional)',
                  filled: true,
                  fillColor: isDark ? Colors.white.withValues(alpha: 0.02) : const Color(0xFFFAF9F5),
                  labelStyle: TextStyle(color: isDark ? Colors.white38 : Colors.grey.shade500, fontWeight: FontWeight.w600),
                  prefixIcon: const Icon(LineIcons.alignLeft, color: Color(0xFF2ECC71)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade200, width: 1.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFF2ECC71), width: 2),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 18),

              // Link input
              TextFormField(
                controller: _linkController,
                style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1E1B15), fontWeight: FontWeight.w700),
                decoration: InputDecoration(
                  labelText: 'Reference Link (Optional)',
                  hintText: 'https://...',
                  filled: true,
                  fillColor: isDark ? Colors.white.withValues(alpha: 0.02) : const Color(0xFFFAF9F5),
                  labelStyle: TextStyle(color: isDark ? Colors.white38 : Colors.grey.shade500, fontWeight: FontWeight.w600),
                  prefixIcon: const Icon(LineIcons.link, color: Color(0xFF2ECC71)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade200, width: 1.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFF2ECC71), width: 2),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 18),

              // Subject Dropdown
              DropdownButtonFormField<SubjectModel>(
                initialValue: _selectedSubject,
                items: widget.subjects.map((s) => DropdownMenuItem(value: s, child: Text(s.name))).toList(),
                onChanged: (v) => setState(() => _selectedSubject = v),
                dropdownColor: isDark ? const Color(0xFF1E1B15) : Colors.white,
                style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1E1B15), fontWeight: FontWeight.w700),
                decoration: InputDecoration(
                  labelText: 'Target Subject',
                  filled: true,
                  fillColor: isDark ? Colors.white.withValues(alpha: 0.02) : const Color(0xFFFAF9F5),
                  labelStyle: TextStyle(color: isDark ? Colors.white38 : Colors.grey.shade500, fontWeight: FontWeight.w600),
                  prefixIcon: const Icon(LineIcons.book, color: Color(0xFF2ECC71)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade200, width: 1.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFF2ECC71), width: 2),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
                validator: (v) => v == null ? 'Please select a subject' : null,
              ),
              const SizedBox(height: 18),

              // Start & Due dates row
              Row(
                children: [
                  Expanded(
                    child: _buildActionTile(
                      icon: LineIcons.calendarCheck,
                      label: 'Start Date',
                      title: _startDate == null ? 'Select Start' : DateFormat('MMM dd, yyyy').format(_startDate!),
                      onTap: () => _pickDate(isDue: false),
                      isDark: isDark,
                      isActive: _startDate != null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildActionTile(
                      icon: LineIcons.calendarTimes,
                      label: 'Due Date',
                      title: _selectedDate == null ? 'Select Due' : DateFormat('MMM dd, yyyy').format(_selectedDate!),
                      onTap: () => _pickDate(isDue: true),
                      isDark: isDark,
                      isActive: _selectedDate != null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Attachment action card
              _buildActionTile(
                icon: LineIcons.paperclip,
                label: 'Reference Attachment (Optional)',
                title: _selectedFile == null 
                  ? (isEditMode && widget.assignment?.fileUrl != null ? 'Change Attachment' : 'Tap to Attach Reference') 
                  : _selectedFile!.path.split('/').last,
                onTap: _pickFile,
                isDark: isDark,
                isActive: _selectedFile != null || (isEditMode && widget.assignment?.fileUrl != null),
                onClear: _selectedFile != null ? () => setState(() => _selectedFile = null) : null,
              ),
              const SizedBox(height: 36),

              // Submit Button
              Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2ECC71), Color(0xFF1E8449)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2ECC71).withValues(alpha: 0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: _submit,
                  child: Text(
                    isEditMode ? "SAVE CHANGES" : "PUBLISH TASK", 
                    style: const TextStyle(
                      color: Colors.white, 
                      fontWeight: FontWeight.w900, 
                      fontSize: 16,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon, 
    required String label,
    required String title, 
    required VoidCallback onTap, 
    required bool isDark,
    bool isActive = false,
    VoidCallback? onClear,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isActive 
              ? const Color(0xFF2ECC71).withValues(alpha: 0.1) 
              : (isDark ? Colors.white.withValues(alpha: 0.02) : const Color(0xFFFAF9F5)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive 
                ? const Color(0xFF2ECC71).withValues(alpha: 0.3) 
                : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade200),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF2ECC71), size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white38 : Colors.grey.shade500,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    title, 
                    style: TextStyle(
                      fontWeight: FontWeight.w800, 
                      color: isActive 
                          ? (isDark ? Colors.white : const Color(0xFF1E1B15)) 
                          : Colors.grey.shade500,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (onClear != null)
              IconButton(
                icon: const Icon(LineIcons.times, size: 18, color: Colors.redAccent), 
                onPressed: onClear,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              )
            else
              const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 16),
          ],
        ),
      ),
    );
  }
}
