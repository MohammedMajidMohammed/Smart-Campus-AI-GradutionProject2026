import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_canvas/core/components/custom_circular_progress_indecator.dart';
import 'package:smart_canvas/core/components/custom_drop_down_button_form_field.dart';
import 'package:smart_canvas/core/components/custom_text_form_field_with_title.dart';
import 'package:smart_canvas/features/administrator/rooms/models/room_model.dart';
import 'package:smart_canvas/features/administrator/rooms/view_models/cubit/add_room_cubit.dart';
import 'package:smart_canvas/features/administrator/rooms/views/widgets/room_image.dart';
import 'package:smart_canvas/features/administrator/rooms/views/widgets/room_map_container.dart';
import 'package:line_icons/line_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AddRoomForm extends StatelessWidget {
  const AddRoomForm({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AddRoomCubit>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Form(
      key: cubit.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          _buildEliteHeader(cubit, isDark),
          const SizedBox(height: 24),

          _buildBuildingsDropdown(cubit).animate().fadeIn(delay: 100.ms).slideX(),
          const SizedBox(height: 16),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 4,
                child: CustomTextFormFieldWithTitle(
                  prefixIcon: LineIcons.doorOpen,
                  title: 'room_name'.tr(),
                  controller: cubit.roomNameController,
                  hintText: 'room_name_hint'.tr(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: CustomTextFormFieldWithTitle(
                  prefixIcon: LineIcons.layerGroup,
                  title: 'floor'.tr(),
                  controller: cubit.floorNumberController,
                  hintText: 'floor_hint'.tr(),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ).animate().fadeIn(delay: 200.ms).slideX(),
          const SizedBox(height: 16),

          _buildRoomTypeDropdown(cubit).animate().fadeIn(delay: 300.ms).slideX(),
          const SizedBox(height: 16),

          _buildSideSelector(cubit, isDark).animate().fadeIn(delay: 400.ms).slideX(),
          const SizedBox(height: 20),

          const RoomImage().animate().fadeIn(delay: 500.ms).slideX(),
          const SizedBox(height: 20),
          
          const RoomMapContainer().animate().fadeIn(delay: 600.ms).slideX(),
          
          const SizedBox(height: 35),
          _buildActionButtons(cubit, isDark).animate().fadeIn(delay: 700.ms).scale(),
          const SizedBox(height: 25),
        ],
      ),
    );
  }

  Widget _buildEliteHeader(AddRoomCubit cubit, bool isDark) {
    final title = cubit.isEditMode ? 'edit_room'.tr() : 'create_room'.tr();
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF1E8449).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            LineIcons.doorOpen,
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
                  color: isDark ? Colors.white : Colors.black87,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                cubit.isEditMode ? "Modify room specifications" : "Define a new campus room",
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

  Widget _buildBuildingsDropdown(AddRoomCubit cubit) {
    return BlocBuilder<AddRoomCubit, AddRoomState>(
      buildWhen: (previous, current) =>
          current is GetBuildingsLoading || current is GetBuildingsError || current is GetBuildingsSuccess,
      builder: (context, state) {
        if (state is GetBuildingsLoading) return const LinearProgressIndicator();
        return CustomDropDownButtonFormField(
          items: cubit.buildings,
          value: cubit.buildingId != null && cubit.buildings.isNotEmpty
              ? cubit.buildings.firstWhere((e) => e.id.toString() == cubit.buildingId, orElse: () => cubit.buildings.first)
              : null,
          itemLabelBuilder: (e) => e.name,
          title: 'buildings'.tr(),
          hintText: 'select_building'.tr(),
          prefixIcon: LineIcons.building,
          onChanged: (value) => cubit.buildingId = value!.id.toString(),
        );
      },
    );
  }

  Widget _buildRoomTypeDropdown(AddRoomCubit cubit) {
    return CustomDropDownButtonFormField(
      items: RoomType.values.map((e) => e.label).toList(),
      value: cubit.roomType != null && RoomType.values.any((e) => e.name == cubit.roomType)
          ? RoomType.values.firstWhere((e) => e.name == cubit.roomType).label
          : null,
      hintText: 'select_type'.tr(),
      title: 'room_type'.tr(),
      prefixIcon: LineIcons.tags,
      onChanged: (value) {
        cubit.roomType = RoomType.values.firstWhere((e) => e.label == value).name;
      },
    );
  }

  Widget _buildSideSelector(AddRoomCubit cubit, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'room_side'.tr(), 
          style: TextStyle(
            fontSize: 16, 
            fontWeight: FontWeight.w800, 
            color: isDark ? Colors.white : const Color(0xFF1E1B15),
          ),
        ),
        const SizedBox(height: 12),
        StatefulBuilder(builder: (context, setState) {
          return Row(
            children: [
              _buildSideChip('left', 'side_left'.tr(), cubit, setState, isDark),
              const SizedBox(width: 12),
              _buildSideChip('center', 'side_center'.tr(), cubit, setState, isDark),
              const SizedBox(width: 12),
              _buildSideChip('right', 'side_right'.tr(), cubit, setState, isDark),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildSideChip(String value, String label, AddRoomCubit cubit, StateSetter setState, bool isDark) {
    bool isSelected = cubit.roomSide == value;
    final color = isSelected ? const Color(0xFF1E8449) : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05));
    
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => cubit.roomSide = isSelected ? null : value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? const Color(0xFF1E8449) : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : (isDark ? Colors.white54 : Colors.grey[700]),
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(AddRoomCubit cubit, bool isDark) {
    return BlocBuilder<AddRoomCubit, AddRoomState>(
      builder: (context, state) {
        if (state is AddRoomLoading) return const Center(child: CustomCircularProgresIndecator());
        
        return Container(
          width: double.infinity,
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(
              colors: [Color(0xFF1E8449), Color(0xFF1E8449)],
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
            onPressed: () => cubit.isEditMode ? cubit.updateRoom() : cubit.addRoom(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(cubit.isEditMode ? LineIcons.save : LineIcons.checkCircle, color: Colors.white),
                const SizedBox(width: 12),
                Text(
                  (cubit.isEditMode ? 'update_room'.tr() : 'create_room'.tr()).toUpperCase(),
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
