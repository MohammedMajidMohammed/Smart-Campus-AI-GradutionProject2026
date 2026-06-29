import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:line_icons/line_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:smart_canvas/core/utilies/sizes/sized_config.dart';
import 'package:smart_canvas/features/admin/subjects/models/subject_model.dart';
import 'package:smart_canvas/features/professor/attendance/view_models/cubit/professor_attendance_cubit.dart';

class QrAttendanceScreen extends StatelessWidget {
  final String? preselectedSubjectId;
  const QrAttendanceScreen({super.key, this.preselectedSubjectId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ProfessorAttendanceCubit()..getProfessorSubjects(),
      child: QrAttendanceScreenBody(preselectedSubjectId: preselectedSubjectId),
    );
  }
}

class QrAttendanceScreenBody extends StatefulWidget {
  final String? preselectedSubjectId;
  const QrAttendanceScreenBody({super.key, this.preselectedSubjectId});

  @override
  State<QrAttendanceScreenBody> createState() => _QrAttendanceScreenBodyState();
}

class _QrAttendanceScreenBodyState extends State<QrAttendanceScreenBody> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedSubjectId;
  final TextEditingController _weekController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedSubjectId = widget.preselectedSubjectId;
  }

  @override
  void dispose() {
    _weekController.dispose();
    super.dispose();
  }

  void _onGenerate(BuildContext context) {
    if (_formKey.currentState!.validate() && _selectedSubjectId != null) {
      context.read<ProfessorAttendanceCubit>().startAttendanceSession(
        subjectId: _selectedSubjectId!,
        weekNumber: int.tryParse(_weekController.text) ?? 1,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a subject and enter week number"), backgroundColor: Colors.redAccent),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0E0A) : const Color(0xFFFAF9F5),
      body: BlocConsumer<ProfessorAttendanceCubit, ProfessorAttendanceState>(
        listener: (context, state) {
          if (state is ProfessorAttendanceError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.redAccent),
            );
          }
        },
        builder: (context, state) {
          return Stack(
            children: [
              // Immersive Header
              _buildPremiumHeader(context, state, isDark),
              
              SafeArea(
                child: Column(
                  children: [
                    SizedBox(height: SizeConfig.h(20)), // Offset for stack header
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                        child: Form(
                          key: _formKey,
                          child: state is ProfessorAttendanceStarted 
                            ? _buildActiveSessionView(context, state, isDark)
                            : _buildSetupView(context, state, isDark),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPremiumHeader(BuildContext context, ProfessorAttendanceState state, bool isDark) {
    final bool isActive = state is ProfessorAttendanceStarted;
    
    return Container(
      width: double.infinity,
      height: SizeConfig.h(30),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark 
            ? [const Color(0xFF1E1B15), const Color(0xFF0F0E0A)]
            : [const Color(0xFF1E8449), const Color(0xFF2ECC71)],
        ),
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(40), bottomRight: Radius.circular(40)),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : const Color(0xFF1E8449)).withValues(alpha: 0.2), 
            blurRadius: 20, 
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Academic Shield Concentric Watermark
          Positioned(
            right: -30,
            top: -20,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.04), width: 1.5),
              ),
              child: Center(
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withValues(alpha: 0.02), width: 1),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.school_outlined, 
                      size: 55, 
                      color: Colors.white.withValues(alpha: 0.04),
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          Positioned(
            top: -45, 
            left: -45, 
            child: Container(
              width: 220, 
              height: 220, 
              decoration: BoxDecoration(
                shape: BoxShape.circle, 
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Positioned(
            bottom: -35, 
            right: -25, 
            child: Container(
              width: 160, 
              height: 160, 
              decoration: BoxDecoration(
                shape: BoxShape.circle, 
                color: Colors.white.withValues(alpha: 0.03),
              ),
            ),
          ),
          
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.white.withValues(alpha: 0.2),
                                padding: const EdgeInsets.all(10),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Attendance System',
                                style: TextStyle(
                                  color: Colors.white, 
                                  fontSize: 18, 
                                  fontWeight: FontWeight.w900, 
                                  letterSpacing: -0.5,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Active badge status
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isActive ? Colors.green.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isActive ? LineIcons.broadcastTower : LineIcons.qrcode, 
                              color: isActive ? Colors.greenAccent : Colors.white70, 
                              size: 14
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isActive ? "ACTIVE" : "GENERATOR",
                              style: TextStyle(
                                color: isActive ? Colors.greenAccent : Colors.white70, 
                                fontSize: 9, 
                                fontWeight: FontWeight.w900, 
                                letterSpacing: 0.5
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Attendance Tracking",
                    style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -1.0),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isActive 
                      ? "Students are currently scanning the code" 
                      : "Generate a secure QR code for student check-in",
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ],
      ).animate().fadeIn().slideY(begin: -0.05),
    );
  }

  Widget _buildSetupView(BuildContext context, ProfessorAttendanceState state, bool isDark) {
    return Column(
      children: [
        // 1. Immersive Secure Guide Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1B15) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
            border: Border.all(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade200.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E8449).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.security_rounded,
                  color: Color(0xFF1E8449),
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Secure Check-In Verification",
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        color: isDark ? Colors.white : const Color(0xFF1E1B15),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "QR codes are dynamically encrypted with timestamp tokens to prevent student proxy attendance sharing.",
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white38 : Colors.grey.shade500,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // 2. Main Config Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1B15) : Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                blurRadius: 25,
                offset: const Offset(0, 12),
              ),
            ],
            border: Border.all(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade200.withValues(alpha: 0.5),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(LineIcons.cog, color: Color(0xFF1E8449), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    "Session Configuration",
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      color: isDark ? Colors.white70 : const Color(0xFF2A2720),
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              _buildSubjectSelector(state, isDark),
              const SizedBox(height: 20),
              
              // Custom styled label for Week Number
              Text(
                "Week Number",
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white54 : Colors.grey.shade600,
                  fontSize: 12,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _weekController,
                keyboardType: TextInputType.number,
                style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1E1B15), fontWeight: FontWeight.w700),
                decoration: InputDecoration(
                  hintText: 'e.g. 1, 2, 3...',
                  hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                  filled: true,
                  fillColor: isDark ? Colors.white.withValues(alpha: 0.02) : const Color(0xFFFAF9F5),
                  prefixIcon: const Icon(LineIcons.hashtag, color: Color(0xFF2ECC71)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade200, width: 1.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFF2ECC71), width: 2),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                validator: (value) => value == null || value.trim().isEmpty ? 'Please enter week number' : null,
              ),
              const SizedBox(height: 28),
              
              // Generate Button
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
                  onPressed: () => _onGenerate(context),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        state is ProfessorAttendanceLoading ? Icons.hourglass_empty : Icons.qr_code_scanner_rounded,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        state is ProfessorAttendanceLoading ? "PREPARING..." : "GENERATE SECURE QR", 
                        style: const TextStyle(
                          color: Colors.white, 
                          fontWeight: FontWeight.w900, 
                          fontSize: 15,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildSubjectSelector(ProfessorAttendanceState state, bool isDark) {
    final cubit = context.read<ProfessorAttendanceCubit>();
    final List<SubjectModel> subjects = cubit.professorSubjects;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Target Course",
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white54 : Colors.grey.shade600,
            fontSize: 12,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: subjects.any((s) => s.id == _selectedSubjectId) ? _selectedSubjectId : null,
          items: subjects.map((s) {
            return DropdownMenuItem(
              value: s.id, 
              child: Text(s.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold))
            );
          }).toList(),
          onChanged: (val) => setState(() => _selectedSubjectId = val),
          dropdownColor: isDark ? const Color(0xFF1E1B15) : Colors.white,
          style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1E1B15), fontWeight: FontWeight.w700),
          decoration: InputDecoration(
            prefixIcon: const Icon(LineIcons.book, color: Color(0xFF2ECC71)),
            filled: true,
            fillColor: isDark ? Colors.white.withValues(alpha: 0.02) : const Color(0xFFFAF9F5),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade200, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFF2ECC71), width: 2),
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            hintText: state is ProfessorAttendanceLoading ? "Loading schedule..." : (subjects.isEmpty ? "No subjects in schedule" : "Choose from your schedule..."),
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          ),
          validator: (v) => v == null ? 'Please select a subject' : null,
        ),
      ],
    );
  }

  Widget _buildActiveSessionView(BuildContext context, ProfessorAttendanceStarted state, bool isDark) {
    final cubit = context.read<ProfessorAttendanceCubit>();
    
    final qrDataRaw = {
      "token": state.token,
      "pin": state.pin,
      "sessionId": cubit.sessionId,
    };
    final String qrData = jsonEncode(qrDataRaw);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1B15) : Colors.white,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
            ],
            border: Border.all(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.05),
            ),
          ),
          child: Column(
            children: [
              Text(
                "SCAN TO CHECK-IN",
                style: TextStyle(fontWeight: FontWeight.w900, color: isDark ? Colors.white38 : Colors.grey.shade400, fontSize: 12, letterSpacing: 2.0),
              ),
              const SizedBox(height: 24),
              QrImageView(
                data: qrData,
                version: QrVersions.auto,
                size: 260.0,
                eyeStyle: QrEyeStyle(eyeShape: QrEyeShape.square, color: isDark ? Colors.white : const Color(0xFF2ECC71)),
                dataModuleStyle: QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: isDark ? Colors.white : const Color(0xFF0F0E0A),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _statBadge("ATTENDEES", state.attendeeCount.toString(), LineIcons.users, Colors.blue),
                  const SizedBox(width: 16),
                  _statBadge("PIN CODE", state.pin, LineIcons.key, Colors.orange),
                ],
              ),
            ],
          ),
        ).animate().scale(curve: Curves.elasticOut, duration: 800.ms),
        const SizedBox(height: 40),
        Row(
          children: [
            Expanded(
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.redAccent.withValues(alpha: 0.1),
                ),
                child: TextButton.icon(
                  onPressed: () => cubit.stopAttendanceSession(),
                  icon: const Icon(Icons.stop_rounded, color: Colors.redAccent),
                  label: const Text(
                    "STOP", 
                    style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.green.withValues(alpha: 0.1),
                ),
                child: TextButton.icon(
                  onPressed: () {
                    final subjectName = cubit.professorSubjects.firstWhere((s) => s.id == _selectedSubjectId).name;
                    cubit.exportAttendanceExcel(subjectName, int.parse(_weekController.text));
                  },
                  icon: const Icon(LineIcons.excelFile, color: Colors.green),
                  label: const Text(
                    "EXPORT", 
                    style: TextStyle(color: Colors.green, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                  ),
                ),
              ),
            ),
          ],
        ).animate().fadeIn(delay: 500.ms),
      ],
    );
  }

  Widget _statBadge(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
            ],
          ),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
        ],
      ),
    );
  }
}
