import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_canvas/core/components/custom_circular_progress_indecator.dart';
import 'package:smart_canvas/core/components/custom_drop_down_button_form_field.dart';
import 'package:smart_canvas/core/components/custom_elevavted_button_with_title.dart';
import 'package:smart_canvas/core/components/custom_text_form_field_with_title.dart';
import 'package:smart_canvas/core/utilies/sizes/sized_config.dart';
import 'package:smart_canvas/features/administrator/collages/views/widgets/add_college_title.dart';
import 'package:smart_canvas/features/admin/material/view_models/cubit/add_material_cubit.dart';

class AddMaterialForm extends StatelessWidget {
  const AddMaterialForm({super.key});

  @override
  Widget build(BuildContext context) {
    var cubit = context.read<AddMaterialCubit>();
    return Form(
      key: cubit.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AddTitle(icon: Icons.menu_book, title: 'Add New Material'),
          SizedBox(height: SizeConfig.height * 0.04),
          CustomTextFormFieldWithTitle(
            prefixIcon: Icons.menu_book,
            title: 'Name',
            controller: cubit.materialNameController,
            hintText: 'Enter material name',
          ),
          SizedBox(height: SizeConfig.height * 0.02),
          CustomTextFormFieldWithTitle(
            prefixIcon: Icons.description,
            title: 'Description',
            controller: cubit.materialDescriptionController,
            hintText: 'Enter material description',
            maxLines: 2,
          ),
          SizedBox(height: SizeConfig.height * 0.02),
          // File Picker Button
          BlocBuilder<AddMaterialCubit, AddMaterialState>(
            builder: (context, state) {
              final hasFile = cubit.selectedFile != null;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Material File',
                    style: TextStyle(
                      fontSize: SizeConfig.width * 0.04,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: SizeConfig.height * 0.01),
                  InkWell(
                    onTap: () => cubit.pickFile(),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: SizeConfig.width * 0.04,
                        vertical: SizeConfig.height * 0.015,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: hasFile ? Colors.green : Colors.grey.shade300,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        color: hasFile ? Colors.green.shade50 : Colors.grey.shade50,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            hasFile ? Icons.check_circle : Icons.upload_file,
                            color: hasFile ? Colors.green : Colors.grey.shade600,
                          ),
                          SizedBox(width: SizeConfig.width * 0.03),
                          Expanded(
                            child: Text(
                              hasFile
                                  ? cubit.selectedFileName ?? 'File selected'
                                  : 'Tap to select file (PDF, DOC, PPT, etc.)',
                              style: TextStyle(
                                color: hasFile ? Colors.green.shade700 : Colors.grey.shade600,
                                fontSize: SizeConfig.width * 0.035,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (hasFile)
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
                              onPressed: () => cubit.clearFile(),
                            ),
                        ],
                      ),
                    ),
                  ),
                  if (!hasFile)
                    Padding(
                      padding: EdgeInsets.only(top: SizeConfig.height * 0.005),
                      child: Text(
                        'Required: Please select a file to upload',
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: SizeConfig.width * 0.03,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          SizedBox(height: SizeConfig.height * 0.02),
          BlocBuilder<AddMaterialCubit, AddMaterialState>(
            buildWhen: (previous, current) =>
                current is GetSubjectsLoading ||
                current is GetSubjectsError ||
                current is GetSubjectsSuccess,
            builder: (context, state) {
              return state is GetSubjectsLoading
                  ? const CustomCircularProgresIndecator()
                  : CustomDropDownButtonFormField(
                      items: cubit.subjects,
                      itemLabelBuilder: (e) => e.name,
                      title: 'Subjects',
                      hintText: 'Select subject',
                      onChanged: (value) {
                        cubit.subjectId = value!.id.toString();
                      },
                    );
            },
          ),
          SizedBox(height: SizeConfig.height * 0.04),
          BlocBuilder<AddMaterialCubit, AddMaterialState>(
            buildWhen: (previous, current) =>
                current is AddMaterialSuccess ||
                current is AddMaterialError ||
                current is AddMaterialLoading,
            builder: (context, state) {
              return state is AddMaterialLoading
                  ? const CustomCircularProgresIndecator()
                  : CustomElevatedButtonWithIcon(
                      onPressed: () {
                        cubit.addMaterial();
                      },
                      title: 'Add Material',
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
