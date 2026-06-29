import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:smart_canvas/core/components/custom_circular_progress_indecator.dart';
import 'package:smart_canvas/core/components/custom_text_form_field_with_title.dart';
import 'package:smart_canvas/core/components/custom_drop_down_button_form_field.dart';
import 'package:smart_canvas/features/administrator/buildings/view_models/cubit/add_building_cubit.dart';
import 'package:smart_canvas/features/administrator/buildings/views/widgets/building_image.dart';
import 'package:smart_canvas/features/administrator/buildings/views/widgets/map_container.dart';
import 'package:smart_canvas/features/administrator/buildings/models/building_model.dart';
import 'package:line_icons/line_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AddBuildingForm extends StatelessWidget {
  const AddBuildingForm({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AddBuildingCubit>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Form(
      key: cubit.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          _buildEliteHeader(cubit, isDark),
          const SizedBox(height: 24),
          
          CustomTextFormFieldWithTitle(
            prefixIcon: LineIcons.building,
            title: 'name_label'.tr(),
            controller: cubit.buildingNameController,
            hintText: 'enter_building_name'.tr(),
          ).animate().fadeIn(delay: 100.ms).slideX(),
          const SizedBox(height: 16),
          
          const BuildingImage().animate().fadeIn(delay: 200.ms).slideX(),
          const SizedBox(height: 16),
          
          _buildBuildingTypeDropdown(cubit).animate().fadeIn(delay: 300.ms).slideX(),
          const SizedBox(height: 16),
          
          _buildCollegesDropdown(cubit).animate().fadeIn(delay: 400.ms).slideX(),
          const SizedBox(height: 16),
          
          const MapContainer().animate().fadeIn(delay: 500.ms).slideX(),
          
          const SizedBox(height: 35),
          _buildActionButtons(cubit, isDark).animate().fadeIn(delay: 600.ms).scale(),
          const SizedBox(height: 25),
        ],
      ),
    );
  }

  Widget _buildEliteHeader(AddBuildingCubit cubit, bool isDark) {
    final title = cubit.buildingToEdit != null ? 'edit_building_title'.tr() : 'add_new_building'.tr();
    
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF1E8449).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            LineIcons.building,
            color: Color(0xFF1E8449),
            size: 26,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : const Color(0xFF0F0E0A),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                cubit.buildingToEdit != null ? "Update building details" : "Configure a new campus building",
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white60 : Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBuildingTypeDropdown(AddBuildingCubit cubit) {
    return CustomDropDownButtonFormField(
      items: BuildingType.values.map((e) => e.name).toList(),
      hintText: 'select_building_type'.tr(),
      title: 'building_type_label'.tr(),
      onChanged: (value) => cubit.buildingType = value.toString(),
    );
  }

  Widget _buildCollegesDropdown(AddBuildingCubit cubit) {
    return BlocBuilder<AddBuildingCubit, AddBuildingState>(
      buildWhen: (previous, current) =>
          current is GetCollegesLoading || current is GetCollegesError || current is GetCollegesSuccess,
      builder: (context, state) {
        if (state is GetCollegesLoading) return const LinearProgressIndicator();
        return CustomDropDownButtonFormField(
          items: cubit.colleges,
          itemLabelBuilder: (e) => e.name,
          title: 'colleges_label'.tr(),
          hintText: 'select_college'.tr(),
          onChanged: (value) => cubit.collegeId = value!.id.toString(),
        );
      },
    );
  }

  Widget _buildActionButtons(AddBuildingCubit cubit, bool isDark) {
    return BlocBuilder<AddBuildingCubit, AddBuildingState>(
      builder: (context, state) {
        if (state is AddBuildingLoading) return const Center(child: CustomCircularProgresIndecator());
        
        return Container(
          width: double.infinity,
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(
              colors: [Color(0xFF1E8449), Color(0xFF2ECC71)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1E8449).withValues(alpha: 0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: () => cubit.saveBuilding(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(cubit.buildingToEdit != null ? LineIcons.save : LineIcons.plus, color: Colors.white),
                const SizedBox(width: 12),
                Text(
                  (cubit.buildingToEdit != null ? 'save_changes'.tr() : 'add_new_building'.tr()).toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
