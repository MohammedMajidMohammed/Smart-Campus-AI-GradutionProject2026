import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:line_icons/line_icons.dart';
import 'package:smart_canvas/features/online_sessions/models/online_session_model.dart';
import 'package:smart_canvas/features/online_sessions/view_models/cubit/online_sessions_cubit.dart';
import 'package:smart_canvas/features/admin/subjects/models/subject_model.dart';
import 'package:smart_canvas/core/cache/cache_helper.dart';
import 'package:smart_canvas/core/di/dependancy_injection.dart';

class CreateOnlineSessionDialog extends StatefulWidget {
  final OnlineSessionModel? sessionToEdit;

  const CreateOnlineSessionDialog({super.key, this.sessionToEdit});

  @override
  State<CreateOnlineSessionDialog> createState() => _CreateOnlineSessionDialogState();
}

class _CreateOnlineSessionDialogState extends State<CreateOnlineSessionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _linkController = TextEditingController();
  final _durationController = TextEditingController(text: '60');
  
  SubjectModel? _selectedSubject;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.fromDateTime(DateTime.now());
  bool _subjectsInitialized = false;

  @override
  void initState() {
    super.initState();
    context.read<OnlineSessionsCubit>().loadProfessorSubjects();
    
    if (widget.sessionToEdit != null) {
      _titleController.text = widget.sessionToEdit!.title;
      _linkController.text = widget.sessionToEdit!.meetingLink;
      _durationController.text = widget.sessionToEdit!.durationMinutes.toString();
      _selectedDate = widget.sessionToEdit!.startTime;
      _selectedTime = TimeOfDay.fromDateTime(widget.sessionToEdit!.startTime);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _linkController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.sessionToEdit != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 24,
        right: 24,
        top: 12,
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
                  width: 50,
                  height: 6,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Header section
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2ECC71).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      isEditing ? LineIcons.edit : LineIcons.video,
                      color: const Color(0xFF2ECC71),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEditing ? 'Update Session' : 'Schedule Session',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white : const Color(0xFF0F0E0A),
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isEditing ? 'Modify virtual class details' : 'Set up a new virtual class/lecture',
                          style: TextStyle(
                            color: isDark ? Colors.white38 : Colors.grey.shade500,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
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
              
              // Subject Dropdown
              BlocBuilder<OnlineSessionsCubit, OnlineSessionsState>(
                builder: (context, state) {
                  List<SubjectModel> subjects = [];
                  if (state is OnlineSessionsSubjectsLoaded) {
                    subjects = state.subjects;
                    
                    if (isEditing && !_subjectsInitialized && subjects.isNotEmpty) {
                      try {
                        _selectedSubject = subjects.firstWhere((s) => s.id == widget.sessionToEdit!.subjectId);
                      } catch (_) {}
                      _subjectsInitialized = true;
                    }
                  }
                  
                  return DropdownButtonFormField<SubjectModel>(
                    dropdownColor: isDark ? const Color(0xFF1E1B15) : Colors.white,
                    style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1E1B15), fontWeight: FontWeight.w700),
                    decoration: InputDecoration(
                      labelText: 'Select Subject',
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
                    initialValue: _selectedSubject,
                    items: subjects.map((s) {
                      return DropdownMenuItem(
                        value: s,
                        child: Text(s.name),
                      );
                    }).toList(),
                    onChanged: (value) => setState(() => _selectedSubject = value),
                    validator: (value) => value == null ? 'Please select a subject' : null,
                  );
                },
              ),
              const SizedBox(height: 18),
              
              // Title field
              TextFormField(
                controller: _titleController,
                style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1E1B15), fontWeight: FontWeight.w700),
                decoration: InputDecoration(
                  labelText: 'Session Title',
                  filled: true,
                  fillColor: isDark ? Colors.white.withValues(alpha: 0.02) : const Color(0xFFFAF9F5),
                  labelStyle: TextStyle(color: isDark ? Colors.white38 : Colors.grey.shade500, fontWeight: FontWeight.w600),
                  prefixIcon: const Icon(LineIcons.heading, color: Color(0xFF2ECC71)),
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
                validator: (value) => value == null || value.isEmpty ? 'Please enter a title' : null,
              ),
              const SizedBox(height: 18),
              
              // Link field
              TextFormField(
                controller: _linkController,
                style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1E1B15), fontWeight: FontWeight.w700),
                decoration: InputDecoration(
                  labelText: 'Meeting Link',
                  hintText: 'https://meet.google.com/...',
                  filled: true,
                  fillColor: isDark ? Colors.white.withValues(alpha: 0.02) : const Color(0xFFFAF9F5),
                  hintStyle: TextStyle(color: isDark ? Colors.white24 : Colors.grey.shade400),
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
                validator: (value) => value == null || value.isEmpty ? 'Please enter the link' : null,
              ),
              const SizedBox(height: 18),
              
              // Date & Time Row
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _pickDate,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withValues(alpha: 0.02) : const Color(0xFFFAF9F5),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade200,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(LineIcons.calendar, color: Color(0xFF2ECC71), size: 24),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Date',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: isDark ? Colors.white38 : Colors.grey.shade500,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    DateFormat('yyyy-MM-dd').format(_selectedDate),
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: isDark ? Colors.white : const Color(0xFF1E1B15),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: _pickTime,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withValues(alpha: 0.02) : const Color(0xFFFAF9F5),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade200,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(LineIcons.clock, color: Color(0xFF2ECC71), size: 24),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Time',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: isDark ? Colors.white38 : Colors.grey.shade500,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _selectedTime.format(context),
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: isDark ? Colors.white : const Color(0xFF1E1B15),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              
              // Duration field
              TextFormField(
                controller: _durationController,
                keyboardType: TextInputType.number,
                style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1E1B15), fontWeight: FontWeight.w700),
                decoration: InputDecoration(
                  labelText: 'Duration (minutes)',
                  filled: true,
                  fillColor: isDark ? Colors.white.withValues(alpha: 0.02) : const Color(0xFFFAF9F5),
                  labelStyle: TextStyle(color: isDark ? Colors.white38 : Colors.grey.shade500, fontWeight: FontWeight.w600),
                  prefixIcon: const Icon(LineIcons.history, color: Color(0xFF2ECC71)),
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
                validator: (value) => value == null || value.isEmpty ? 'Please enter duration' : null,
              ),
              const SizedBox(height: 36),
              
              // Action Button
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
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      final user = getIt<CacheHelper>().getUserModel();
                      final startTime = DateTime(
                        _selectedDate.year,
                        _selectedDate.month,
                        _selectedDate.day,
                        _selectedTime.hour,
                        _selectedTime.minute,
                      );
                      
                      final session = OnlineSessionModel(
                        id: isEditing ? widget.sessionToEdit!.id : '',
                        professorId: user!.id,
                        subjectId: _selectedSubject!.id,
                        title: _titleController.text.trim(),
                        meetingLink: _linkController.text.trim(),
                        startTime: startTime,
                        durationMinutes: int.parse(_durationController.text),
                        createdAt: isEditing ? widget.sessionToEdit!.createdAt : DateTime.now(),
                      );
                      
                      if (isEditing) {
                        context.read<OnlineSessionsCubit>().updateSession(session);
                      } else {
                        context.read<OnlineSessionsCubit>().createSession(session);
                      }
                      Navigator.pop(context);
                    }
                  },
                  child: Text(
                    isEditing ? 'UPDATE SESSION' : 'CREATE SESSION', 
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
}
