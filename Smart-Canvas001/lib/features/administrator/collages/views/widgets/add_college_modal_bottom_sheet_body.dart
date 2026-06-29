import 'package:smart_canvas/core/components/custom_professional_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_canvas/core/utilies/extensions/app_extensions.dart';
import 'package:smart_canvas/features/administrator/collages/view_models/cubit/add_college_cubit.dart';
import 'package:smart_canvas/features/administrator/collages/views/widgets/add_collage_form.dart';

class AddCollageBottomSheet extends StatelessWidget {
  const AddCollageBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AddCollegeCubit, AddCollegeState>(
      listener: (context, state) {
        if (state is AddCollegeSuccess) {
          final isEdit = context.read<AddCollegeCubit>().collegeId != null;
          
          if (isEdit) {
            Navigator.of(context).pop(); // Pop Modal
            Navigator.of(context).pop(); // Pop Detail View
          } else {
            context.popScreen(); // Pop Modal only
          }

          CustomProfessionalDialog.showSuccess(
            context,
            title: 'Success',
            message: 'College saved successfully',
          );
        }
        if (state is AddCollegeError) {
          CustomProfessionalDialog.showError(
            context,
            title: 'Error',
            message: state.message,
          );
        }
        if (state is SelectCollageImage) {
          CustomProfessionalDialog.showWarning(
            context,
            title: 'Warning',
            message: "Please select college image",
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
                child: const AddCollageForm(),
              ),
            ),
          );
        },
      ),
    );
  }
}
