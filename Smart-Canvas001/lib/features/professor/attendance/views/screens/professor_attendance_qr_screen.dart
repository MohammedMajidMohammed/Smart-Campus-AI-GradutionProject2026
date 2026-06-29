import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:smart_canvas/core/utilies/colors/app_colors.dart';
import 'package:smart_canvas/core/utilies/styles/app_text_styles.dart';
import 'package:smart_canvas/features/professor/attendance/view_models/cubit/professor_attendance_cubit.dart';

class ProfessorAttendanceQRScreen extends StatefulWidget {
  final String subjectName;
  final String subjectId;

  const ProfessorAttendanceQRScreen({
    super.key,
    required this.subjectName,
    required this.subjectId,
  });

  @override
  State<ProfessorAttendanceQRScreen> createState() => _ProfessorAttendanceQRScreenState();
}

class _ProfessorAttendanceQRScreenState extends State<ProfessorAttendanceQRScreen> {
  int _selectedWeek = 1;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ProfessorAttendanceCubit(),
      child: BlocConsumer<ProfessorAttendanceCubit, ProfessorAttendanceState>(
        listener: (context, state) {
          if (state is ProfessorAttendanceError) {
            final isSuccess = state.message.startsWith('Saved');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: isSuccess ? Colors.green : Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              title: Text("Smart Attendance: ${widget.subjectName}", style: AppTextStyles.title20BlackBold),
              elevation: 0,
              backgroundColor: Colors.transparent,
              leading: IconButton(
                icon: const Icon(Icons.close, color: Colors.black),
                onPressed: () {
                  context.read<ProfessorAttendanceCubit>().stopAttendanceSession();
                  Navigator.pop(context, true); // Return true to trigger refresh
                },
              ),
            ),
            body: Stack(
              children: [
                // Decorative Background Blobs
                Positioned(
                  top: -100,
                  right: -100,
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      color: AppColors.kPrimaryColor.withValues(alpha: 0.05),
                      shape: BoxShape.circle,
                    ),
                  ).animate().scale(duration: 2.seconds, curve: Curves.easeInOut),
                ),
                
                Center(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Week Selector - Show before session starts
                          if (state is ProfessorAttendanceInitial) ...[
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 20,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  const Icon(Icons.calendar_today_rounded, size: 48, color: AppColors.kPrimaryColor),
                                  const SizedBox(height: 16),
                                  Text("Select Week Number", style: AppTextStyles.title16Black),
                                  const SizedBox(height: 20),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      IconButton(
                                        onPressed: _selectedWeek > 1
                                            ? () => setState(() => _selectedWeek--)
                                            : null,
                                        icon: const Icon(Icons.remove_circle_outline),
                                        color: AppColors.kPrimaryColor,
                                        iconSize: 36,
                                      ),
                                      Container(
                                        width: 80,
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        decoration: BoxDecoration(
                                          color: AppColors.kPrimaryColor.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: Text(
                                          "$_selectedWeek",
                                          textAlign: TextAlign.center,
                                          style: AppTextStyles.title24WhiteBold.copyWith(
                                            color: AppColors.kPrimaryColor,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: _selectedWeek < 20
                                            ? () => setState(() => _selectedWeek++)
                                            : null,
                                        icon: const Icon(Icons.add_circle_outline),
                                        color: AppColors.kPrimaryColor,
                                        iconSize: 36,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 50,
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        context.read<ProfessorAttendanceCubit>().startAttendanceSession(
                                          subjectId: widget.subjectId,
                                          weekNumber: _selectedWeek,
                                        );
                                      },
                                      icon: const Icon(Icons.qr_code_2_rounded),
                                      label: const Text("Start Attendance Session"),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.kPrimaryColor,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ).animate().fadeIn().slideY(begin: 0.2),
                          ],

                          if (state is ProfessorAttendanceLoading)
                            const CircularProgressIndicator(),
                          
                          if (state is ProfessorAttendanceStarted) ...[
                            // Week Badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                "📆 Week $_selectedWeek",
                                style: AppTextStyles.title16Black.copyWith(color: Colors.orange[800]),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Live Count Badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              decoration: BoxDecoration(
                                color: AppColors.kPrimaryColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.people_alt_rounded, color: AppColors.kPrimaryColor),
                                  const SizedBox(width: 8),
                                  Text(
                                    "${state.attendeeCount} Students Present",
                                    style: AppTextStyles.title16Black.copyWith(color: AppColors.kPrimaryColor),
                                  ),
                                ],
                              ),
                            ).animate().fadeIn().slideY(begin: 0.2),
                            
                            const SizedBox(height: 40),
                            
                            // QR Section
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 30,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  QrImageView(
                                    data: state.token,
                                    version: QrVersions.auto,
                                    size: 280,
                                    gapless: false,
                                    eyeStyle: const QrEyeStyle(
                                      eyeShape: QrEyeShape.square,
                                      color: Colors.black,
                                    ),
                                    dataModuleStyle: const QrDataModuleStyle(
                                      dataModuleShape: QrDataModuleShape.square,
                                      color: Colors.black,
                                    ),
                                  ).animate(key: ValueKey(state.token))
                                   .shimmer(duration: 1.seconds, color: AppColors.kPrimaryColor.withValues(alpha: 0.3))
                                   .fadeIn(),
                                  
                                  const SizedBox(height: 10),
                                  Text(
                                    "QR refreshes every 5 mins",
                                    style: AppTextStyles.title14Black.copyWith(color: Colors.grey),
                                  ),
                                ],
                              ),
                            ).animate().scale(delay: 200.ms),
                            
                            const SizedBox(height: 40),
                            
                            // PIN Section
                            Text("Security PIN", style: AppTextStyles.title16Black.copyWith(color: Colors.grey)),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: state.pin.split('').map((char) => Container(
                                margin: const EdgeInsets.symmetric(horizontal: 5),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.kPrimaryColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  char,
                                  style: AppTextStyles.title24WhiteBold.copyWith(fontWeight: FontWeight.bold),
                                ),
                              )).toList(),
                            ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),
                            
                            const SizedBox(height: 30),

                            // Export Excel Button
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  context.read<ProfessorAttendanceCubit>().exportAttendanceExcel(
                                    widget.subjectName,
                                    _selectedWeek,
                                  );
                                },
                                icon: const Icon(Icons.file_download_outlined),
                                label: Text("Export Attendance (${state.attendeeCount} students)"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),
                            ).animate().fadeIn(delay: 600.ms),
                            
                            const SizedBox(height: 30),
                            
                            // Instruction
                            Text(
                              "Students must stay connected to University Wi-Fi to register successfully.",
                              textAlign: TextAlign.center,
                              style: AppTextStyles.title14Black.copyWith(color: Colors.grey),
                            ),
                          ],
                          
                          if (state is ProfessorAttendanceError)
                            Padding(
                              padding: const EdgeInsets.all(20),
                              child: Text("Error: ${state.message}", style: const TextStyle(color: Colors.red)),
                            ),
                        ],
                      ),
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
}
