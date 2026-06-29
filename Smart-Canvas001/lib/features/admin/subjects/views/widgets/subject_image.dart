import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_canvas/core/components/custom_icon_button.dart';
import 'package:smart_canvas/core/utilies/colors/app_colors.dart';
import 'package:smart_canvas/core/utilies/sizes/sized_config.dart';
import 'package:smart_canvas/core/utilies/styles/app_text_styles.dart';
import 'package:smart_canvas/features/administrator/rooms/view_models/cubit/add_room_cubit.dart';

class RoomImage extends StatelessWidget {
  const RoomImage({super.key});

  @override
  Widget build(BuildContext context) {
    var cubit = context.read<AddRoomCubit>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Room Image', style: AppTextStyles.title18BlackW600),
        SizedBox(height: SizeConfig.height * 0.006),
        Stack(
          children: [
            Container(
              clipBehavior: Clip.antiAlias,
              height: SizeConfig.height * 0.2,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.kPrimaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: BlocBuilder<AddRoomCubit, AddRoomState>(
                buildWhen: (previous, current) =>
                    current is PickImageSuccess || current is PickImageError,
                builder: (context, state) {
                  return cubit.roomImage != null
                      ? Image.file(cubit.roomImage!, fit: BoxFit.cover)
                      : Center(
                          child: Text(
                            'Upload room image',
                            style: AppTextStyles.title16PrimaryColorW500,
                          ),
                        );
                },
              ),
            ),
            Positioned(
              right: SizeConfig.width * 0.03,
              bottom: SizeConfig.height * 0.01,
              child: CustomIconButton(
                backgroundColor: AppColors.kPrimaryColor,
                iconColor: Colors.white,
                icon: Icons.camera_alt_outlined,
                iconSize: SizeConfig.width * 0.07,
                onPressed: () {
                  cubit.pickRoomImage();
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}
