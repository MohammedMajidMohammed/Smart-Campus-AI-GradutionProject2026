import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_canvas/core/components/custom_circular_progress_indecator.dart';
import 'package:smart_canvas/core/components/custom_drop_down_button_form_field.dart';
import 'package:smart_canvas/core/components/custom_elevavted_button_with_title.dart';
import 'package:smart_canvas/core/components/custom_text_form_field_with_title.dart';
import 'package:smart_canvas/core/utilies/sizes/sized_config.dart';
import 'package:smart_canvas/features/administrator/collages/views/widgets/add_college_title.dart';
import 'package:smart_canvas/features/admin/subjects/view_models/cubit/add_subject_cubit.dart';
import 'package:smart_canvas/features/admin/subjects/views/widgets/select_college_academic_year.dart';

class AddSubjectForm extends StatelessWidget {
  const AddSubjectForm({super.key});

  @override
  Widget build(BuildContext context) {
    var cubit = context.read<AddSubjectCubit>();
    return Form(
      key: cubit.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AddTitle(icon: Icons.subject_outlined, title: 'Add New Subject'),
          SizedBox(height: SizeConfig.height * 0.04),
          CustomTextFormFieldWithTitle(
            prefixIcon: Icons.subject_outlined,
            title: 'Name',
            controller: cubit.subjectNameController,
            hintText: 'Enter subject name',
          ),
          SizedBox(height: SizeConfig.height * 0.02),
          BlocBuilder<AddSubjectCubit, AddSubjectState>(
            buildWhen: (previous, current) =>
                current is GetCollegesLoading ||
                current is GetCollegesError ||
                current is GetCollegesSuccess,
            builder: (context, state) {
              return state is GetCollegesLoading
                  ? const CustomCircularProgresIndecator()
                  : CustomDropDownButtonFormField(
                      items: cubit.colleges,
                      itemLabelBuilder: (e) => e.name,
                      title: 'Colleges',
                      hintText: 'Select college',
                      onChanged: (value) {
                        cubit.collegeId = value!.id.toString();
                        cubit.selectCollege(college: value);
                      },
                    );
            },
          ),
          SizedBox(height: SizeConfig.height * 0.02),
          SelectCollegeAcademicYear(cubit: cubit),
          SizedBox(height: SizeConfig.height * 0.04),
          BlocBuilder<AddSubjectCubit, AddSubjectState>(
            buildWhen: (previous, current) =>
                current is AddSubjectSuccess ||
                current is AddSubjectError ||
                current is AddSubjectLoading,
            builder: (context, state) {
              return state is AddSubjectLoading
                  ? const CustomCircularProgresIndecator()
                  : CustomElevatedButtonWithIcon(
                      onPressed: () {
                        cubit.addSubject();
                      },
                      title: 'Add Subject',
                      icon: Icons.add,
                      iconAlignment: IconAlignment.start,
                    );
            },
          ),
          SizedBox(height: SizeConfig.height * 0.05),
        ],
      ),
    );
  }
}
