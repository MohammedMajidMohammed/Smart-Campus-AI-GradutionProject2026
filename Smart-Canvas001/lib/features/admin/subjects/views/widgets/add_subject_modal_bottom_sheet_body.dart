import 'package:smart_canvas/core/components/custom_professional_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_canvas/core/utilies/extensions/app_extensions.dart';
import 'package:smart_canvas/core/utilies/sizes/sized_config.dart';
import 'package:smart_canvas/features/admin/subjects/view_models/cubit/add_subject_cubit.dart';
import 'package:smart_canvas/features/admin/subjects/views/widgets/add_subject_form.dart';

class AddSubjectModalBottomSheetBody extends StatelessWidget {
  const AddSubjectModalBottomSheetBody({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AddSubjectCubit, AddSubjectState>(
      listener: (context, state) {  
        if (state is AddSubjectSuccess) {
          context.popScreen();
          CustomProfessionalDialog.showSuccess(
            context,
            title: 'Success',
            message: 'Subject added successfully',
          );
        }
        if (state is AddSubjectError) {
          CustomProfessionalDialog.showError(
            context,
            title: 'Error',
            message: state.message,
          );
        }
        if (state is SelectCollege) {
          CustomProfessionalDialog.showWarning(
            context,
            title: 'Warning',
            message: "Please select college",
          );
        }
        if (state is SelectAcademicYear) {
          CustomProfessionalDialog.showWarning(
            context,
            title: 'Warning',
            message: "Please select academic year",
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
                padding: EdgeInsets.fromLTRB(
                  SizeConfig.width * 0.04,
                  SizeConfig.height * 0.06,
                  SizeConfig.width * 0.04,
                  SizeConfig.height * 0.00,
                ),
                child: const AddSubjectForm(),
              ),
            ),
          );
        },
      ),
    );
  }
}
