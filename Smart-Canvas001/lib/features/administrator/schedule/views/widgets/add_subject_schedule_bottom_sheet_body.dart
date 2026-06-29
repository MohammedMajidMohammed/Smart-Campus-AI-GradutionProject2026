import 'package:smart_canvas/core/components/custom_professional_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_canvas/core/utilies/extensions/app_extensions.dart';
import 'package:smart_canvas/features/administrator/schedule/view_models/cubit/add_subject_schedule_cubit.dart';
import 'package:smart_canvas/features/administrator/schedule/views/widgets/add_schedule_form.dart';

class AddSubjectScheduleModalBottomSheetBody extends StatelessWidget {
  const AddSubjectScheduleModalBottomSheetBody({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AddSubjectScheduleCubit, AddSubjectScheduleState>(
      listener: (context, state) {
        if (state is AddSubjectScheduleSuccess) {
          context.popScreen();
          CustomProfessionalDialog.showSuccess(
            context,
            title: 'Success',
            message: 'Subject added successfully',
          );
        }
        if (state is AddSubjectScheduleError) {
          CustomProfessionalDialog.showError(
            context,
            title: 'Error',
            message: state.message,
          );
        }
        if (state is SubjectScheduleAlreadyExists) {
          CustomProfessionalDialog.showWarning(
            context,
            title: 'Warning',
            message: "Subject schedule already exists",
          );
        }

        if (state is SelectSubject) {
          CustomProfessionalDialog.showWarning(
            context,
            title: 'Warning',
            message: "Please select subject",
          );
        }
        if (state is SelectDay) {
          CustomProfessionalDialog.showWarning(
            context,
            title: 'Warning',
            message: "Please select day",
          );
        }
        if (state is SelectDoctor) {
          CustomProfessionalDialog.showWarning(
            context,
            title: 'Warning',
            message: "Please select doctor",
          );
        }
        if (state is SelectTimeSlot) {
          CustomProfessionalDialog.showWarning(
            context,
            title: 'Warning',
            message: "Please select time slot",
          );
        }
      },
      child: DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.6,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(30),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 25,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsetsGeometry.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: const AddSubjectScheduleForm(),
              ),
            ),
          );
        },
      ),
    );
  }
}
