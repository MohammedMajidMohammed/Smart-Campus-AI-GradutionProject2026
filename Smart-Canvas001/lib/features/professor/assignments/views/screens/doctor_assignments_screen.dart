import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:line_icons/line_icons.dart';
import 'package:smart_canvas/core/di/dependancy_injection.dart';
import 'package:smart_canvas/features/professor/assignments/models/assignment_model.dart';
import 'package:smart_canvas/features/professor/assignments/view_models/doctor_assignment_cubit.dart';
import 'package:smart_canvas/features/professor/assignments/view_models/doctor_assignment_state.dart';
import 'package:smart_canvas/features/professor/assignments/services/assignments_service.dart';
import 'package:smart_canvas/features/professor/assignments/views/widgets/add_assignment_bottom_sheet.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:smart_canvas/core/utilies/sizes/sized_config.dart';

class DoctorAssignmentsScreen extends StatelessWidget {
  const DoctorAssignmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => DoctorAssignmentCubit(getIt<AssignmentsService>())..loadAssignmentsAndSubjects(),
      child: const _DoctorAssignmentsView(),
    );
  }
}

class _DoctorAssignmentsView extends StatelessWidget {
  const _DoctorAssignmentsView();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0E0A) : const Color(0xFFFAF9F5),
      body: Stack(
        children: [
          // Immersive Header
          _buildPremiumHeader(context, isDark),
          
          SafeArea(
            child: Column(
              children: [
                SizedBox(height: SizeConfig.h(18)), // Adjustment for stack header
                Expanded(
                  child: BlocListener<DoctorAssignmentCubit, DoctorAssignmentState>(
                    listener: (context, state) {
                      if (state is DoctorAssignmentActionSuccess) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(state.message), 
                            backgroundColor: Colors.green,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      } else if (state is DoctorAssignmentError) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(state.message), 
                            backgroundColor: Colors.redAccent,
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 4),
                          ),
                        );
                      }
                    },
                    child: BlocBuilder<DoctorAssignmentCubit, DoctorAssignmentState>(
                      builder: (context, state) {
                        if (state is DoctorAssignmentLoading) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (state is DoctorAssignmentLoaded) {
                          if (state.assignments.isEmpty) {
                            return _buildEmptyState(isDark);
                          }
                          return ListView.builder(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                            itemCount: state.assignments.length,
                            itemBuilder: (context, index) => _AssignmentCard(
                              assignment: state.assignments[index], 
                              isDark: isDark
                            ).animate().fadeIn(delay: (100 * index).ms).slideY(begin: 0.1),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFAB(context),
    );
  }

  Widget _buildPremiumHeader(BuildContext context, bool isDark) {
    return Container(
      width: double.infinity,
      height: SizeConfig.h(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark 
              ? [const Color(0xFF1E1B15), const Color(0xFF0F0E0A)]
              : [const Color(0xFF1E8449), const Color(0xFF2ECC71)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
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
          Positioned(
            top: -40, 
            left: -40, 
            child: Container(
              width: 200, 
              height: 200, 
              decoration: BoxDecoration(
                shape: BoxShape.circle, 
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Positioned(
            bottom: -30, 
            right: -20, 
            child: Container(
              width: 150, 
              height: 150, 
              decoration: BoxDecoration(
                shape: BoxShape.circle, 
                color: Colors.white.withValues(alpha: 0.03),
              ),
            ),
          ),
          
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          padding: const EdgeInsets.all(10),
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        'Assignments',
                        style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: -0.8),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Create and track your student tasks',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LineIcons.tasks, size: 80, color: Colors.grey.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          const Text(
            'No assignments created yet', 
            style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w700, fontSize: 16),
          ),
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _buildFAB(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
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
      child: FloatingActionButton.extended(
        onPressed: () => _showAddAssignmentSheet(context),
        backgroundColor: Colors.transparent,
        elevation: 0,
        highlightElevation: 0,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'New Task', 
          style: TextStyle(
            fontWeight: FontWeight.w900, 
            color: Colors.white,
            fontSize: 14,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }

  void _showAddAssignmentSheet(BuildContext context, {AssignmentModel? assignment}) {
    final state = context.read<DoctorAssignmentCubit>().state;
    if (state is DoctorAssignmentLoaded) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => BlocProvider.value(
          value: context.read<DoctorAssignmentCubit>(),
          child: AddAssignmentBottomSheet(
            subjects: state.subjects,
            assignment: assignment,
          ),
        ),
      );
    }
  }
}

class _AssignmentCard extends StatelessWidget {
  final AssignmentModel assignment;
  final bool isDark;

  const _AssignmentCard({required this.assignment, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final isExpired = assignment.dueDate.isBefore(DateTime.now());
    final statusColor = isExpired ? const Color(0xFFEF4444) : const Color(0xFF10B981);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1B15) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05), 
            blurRadius: 15, 
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.05),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showAddAssignmentSheet(context, assignment: assignment),
          borderRadius: BorderRadius.circular(28),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(LineIcons.clipboardList, color: statusColor, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            assignment.title,
                            style: TextStyle(
                              fontWeight: FontWeight.w900, 
                              fontSize: 17, 
                              color: isDark ? Colors.white : const Color(0xFF1E1B15),
                            ),
                            maxLines: 1, 
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            assignment.subjectName ?? 'Unknown Subject',
                            style: TextStyle(
                              color: isDark ? Colors.white38 : Colors.grey.shade500, 
                              fontSize: 12, 
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _statusBadge(isExpired ? 'EXPIRED' : 'ACTIVE', statusColor),
                    const SizedBox(width: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: const Icon(LineIcons.trash, color: Colors.redAccent, size: 20),
                        onPressed: () => _showDeleteDialog(context),
                        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.03) : const Color(0xFFFAF9F5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? Colors.white.withValues(alpha: 0.02) : Colors.grey.shade100,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(LineIcons.calendarCheck, size: 16, color: Color(0xFF1E8449)),
                            const SizedBox(width: 8),
                            Text(
                              'Start: ${DateFormat('MMM dd').format(assignment.startDate ?? assignment.createdAt)}',
                              style: TextStyle(
                                color: isDark ? Colors.white70 : const Color(0xFF2A2720), 
                                fontWeight: FontWeight.w700, 
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 1.5, 
                        height: 12, 
                        color: isDark ? Colors.white10 : Colors.grey.shade200, 
                        margin: const EdgeInsets.symmetric(horizontal: 10),
                      ),
                      Expanded(
                        child: Row(
                          children: [
                            Icon(LineIcons.calendarTimes, size: 16, color: statusColor),
                            const SizedBox(width: 8),
                            Text(
                              'Due: ${DateFormat('MMM dd').format(assignment.dueDate)}',
                              style: TextStyle(
                                color: isDark ? Colors.white70 : const Color(0xFF2A2720), 
                                fontWeight: FontWeight.w800, 
                                fontSize: 11,
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
        ),
      ),
    );
  }

  void _showAddAssignmentSheet(BuildContext context, {AssignmentModel? assignment}) {
    final state = context.read<DoctorAssignmentCubit>().state;
    if (state is DoctorAssignmentLoaded) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => BlocProvider.value(
          value: context.read<DoctorAssignmentCubit>(),
          child: AddAssignmentBottomSheet(
            subjects: state.subjects,
            assignment: assignment,
          ),
        ),
      );
    }
  }

  void _showDeleteDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1B15) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 24),
            ),
            const SizedBox(width: 12),
            Text(
              'Delete Task?',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : const Color(0xFF0F0E0A),
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to delete this task? This action cannot be undone.',
          style: TextStyle(
            color: isDark ? Colors.white70 : Colors.grey.shade600,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark ? Colors.white60 : Colors.grey.shade600,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<DoctorAssignmentCubit>().deleteAssignment(assignment.id);
              Navigator.pop(dialogContext);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
      child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900)),
    );
  }
}
