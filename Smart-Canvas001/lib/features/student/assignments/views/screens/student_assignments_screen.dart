import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:line_icons/line_icons.dart';
import 'package:smart_canvas/features/professor/assignments/models/assignment_model.dart';
import 'package:smart_canvas/features/student/assignments/view_models/student_assignment_cubit.dart';
import 'package:smart_canvas/features/student/assignments/view_models/student_assignment_state.dart';

class StudentAssignmentsScreen extends StatelessWidget {
  const StudentAssignmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => StudentAssignmentCubit()..subscribeToAssignments(),
      child: const _StudentAssignmentsView(),
    );
  }
}

class _StudentAssignmentsView extends StatelessWidget {
  const _StudentAssignmentsView();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryGrad = isDark
        ? [const Color(0xFF1E1B15), const Color(0xFF2A2720)]
        : [const Color(0xFF1E8449), const Color(0xFF1E8449)];

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0E0A) : const Color(0xFFFAF9F5),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: primaryGrad[0],
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('My Assignments', style: TextStyle(fontWeight: FontWeight.bold)),
              background: Container(
                decoration: BoxDecoration(gradient: LinearGradient(colors: primaryGrad)),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: BlocBuilder<StudentAssignmentCubit, StudentAssignmentState>(
              builder: (context, state) {
                if (state is StudentAssignmentLoading) {
                  return const SliverFillRemaining(child: Center(child: CircularProgressIndicator()));
                }
                if (state is StudentAssignmentLoaded) {
                  if (state.assignments.isEmpty) {
                    return const SliverFillRemaining(child: Center(child: Text('No upcoming assignments')));
                  }
                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _StudentAssignmentCard(assignment: state.assignments[index], isDark: isDark),
                      childCount: state.assignments.length,
                    ),
                  );
                }
                return const SliverFillRemaining(child: SizedBox());
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StudentAssignmentCard extends StatelessWidget {
  final AssignmentModel assignment;
  final bool isDark;

  const _StudentAssignmentCard({required this.assignment, required this.isDark});

  Future<void> _handleSubmission(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'zip'],
    );

    if (result != null && result.files.single.path != null && context.mounted) {
      final file = File(result.files.single.path!);
      final ext = result.files.single.extension!;
      
      context.read<StudentAssignmentCubit>().submitAssignment(
        assignmentId: assignment.id,
        file: file,
        fileExt: ext,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1B15) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05), blurRadius: 10, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(assignment.title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                    Text(assignment.subjectName ?? 'Unknown Subject', style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: const Color(0xFF1E8449).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: const Text('ASSIGNMENT', style: TextStyle(color: Color(0xFF1E8449), fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('START DATE', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(DateFormat('MMM dd, yyyy').format(assignment.startDate ?? assignment.createdAt), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('DUE DATE', style: TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(DateFormat('MMM dd, yyyy').format(assignment.dueDate), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.redAccent)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () => _handleSubmission(context),
              icon: const Icon(LineIcons.upload, color: Colors.white, size: 20),
              label: const Text('SUBMIT SOLUTION', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2ECC71), 
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
