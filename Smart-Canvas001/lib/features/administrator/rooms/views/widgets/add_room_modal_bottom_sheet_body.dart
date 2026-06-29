import 'package:smart_canvas/core/components/custom_professional_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_canvas/core/utilies/extensions/app_extensions.dart';
import 'package:smart_canvas/features/administrator/rooms/view_models/cubit/add_room_cubit.dart';
import 'package:smart_canvas/features/administrator/rooms/view_models/cubit/rooms_cubit.dart';
import 'package:smart_canvas/features/administrator/rooms/views/widgets/add_room_form.dart';

class AddRoomModalBottomSheetBody extends StatelessWidget {
  const AddRoomModalBottomSheetBody({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return BlocListener<AddRoomCubit, AddRoomState>(
      listener: (context, state) {
        if (state is AddRoomSuccess) {
          context.read<RoomsCubit>().getRooms();
          context.popScreen();
          CustomProfessionalDialog.showSuccess(
            context,
            title: 'Success',
            message: 'Room saved successfully',
          );
        }
        if (state is AddRoomError) {
          CustomProfessionalDialog.showError(
            context,
            title: 'Error',
            message: state.message,
          );
        }
      },
      child: DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F0E0A) : const Color(0xFFFAF9F5),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 40,
                  offset: const Offset(0, -10),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildHandle(isDark),
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: const AddRoomForm(),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHandle(bool isDark) {
    return Container(
      margin: const EdgeInsets.only(top: 12, bottom: 8),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: isDark ? Colors.white24 : Colors.black12,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
