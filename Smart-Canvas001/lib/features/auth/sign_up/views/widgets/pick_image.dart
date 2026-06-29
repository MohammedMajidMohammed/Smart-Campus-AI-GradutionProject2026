import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_canvas/core/components/custom_icon_button.dart';
import 'package:smart_canvas/core/utilies/assets/images/app_images.dart';
import 'package:smart_canvas/core/utilies/colors/app_colors.dart';
import 'package:smart_canvas/core/utilies/sizes/sized_config.dart';
import 'package:smart_canvas/features/auth/sign_up/view_models/cubit/sign_up_cubit.dart';

class PickImage extends StatelessWidget {
  const PickImage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    var cubit = context.read<SignUpCubit>();
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Center(
          child: BlocBuilder<SignUpCubit, SignUpState>(
            buildWhen: (previous, current) => current is PickImageSuccess,
            builder: (context, state) {
              return CircleAvatar(
                radius: SizeConfig.width * 0.18,
                backgroundColor: AppColors.kPrimaryColor.withValues(alpha: 0.3),
                backgroundImage: cubit.image == null
                    ? const AssetImage(AppImages.buildingsImage)
                    : FileImage(cubit.image!),
              );
            },
          ),
        ),
        Positioned(
          bottom: -SizeConfig.height * 0.01,
          right: SizeConfig.width * 0.3,
          child: CustomIconButton(
            iconSize: SizeConfig.width * 0.06,
            backgroundColor: AppColors.kPrimaryColor,
            iconColor: Colors.white,
            icon: Icons.camera_alt_outlined,
            onPressed: () {
              cubit.pickProfileImage();
            },
            hPadding: SizeConfig.width * 0.02,
            vPadding: SizeConfig.height * 0.01,
          ),
        ),
      ],
    );
  }
}
