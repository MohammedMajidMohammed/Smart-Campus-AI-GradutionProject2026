import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_canvas/core/utilies/colors/app_colors.dart';
import 'package:smart_canvas/core/utilies/sizes/sized_config.dart';
import 'package:smart_canvas/core/utilies/styles/app_text_styles.dart';
import 'package:smart_canvas/features/administrator/buildings/views/widgets/wave_image.dart';
import 'package:smart_canvas/features/administrator/collages/views/widgets/search_and_filter.dart';
import 'package:smart_canvas/features/admin/schedule/view_models/cubit/schedules_cubit.dart';

class DoctorSchedulesHeader extends StatelessWidget {
  const DoctorSchedulesHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.kPrimaryColor,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(SizeConfig.width * 0.05),
          bottomRight: Radius.circular(SizeConfig.width * 0.05),
        ),
      ),
      child: Stack(
        children: [
          const WaveImage(),
          Padding(
            padding: EdgeInsets.only(
              top:
                  MediaQuery.of(context).padding.top + SizeConfig.height * 0.01,
              left: SizeConfig.width * 0.03,
              right: SizeConfig.width * 0.03,
              bottom: SizeConfig.height * 0.02,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Management Schedule",
                  style: AppTextStyles.title24WhiteW500,
                ),
                SizedBox(height: SizeConfig.height * 0.015),
                SearchAndFilter(
                  hintText: "Search for subjects",
                  onChanged: (value) {
                    context.read<DoctorSchedulesCubit>().searchSchedules(value);
                  },
                ),
                SizedBox(height: SizeConfig.height * 0.01),
                // RoomsLenght(),
                SizedBox(height: SizeConfig.height * 0.003),
                // BlocBuilder<RoomsCubit, RoomsState>(
                //   buildWhen: (previous, current) =>
                //       current is GetRoomsSuccess ||
                //       current is GetRoomsLoading ||
                //       current is GetRoomsFailure,
                //   builder: (context, state) {
                //     return state is GetRoomsLoading
                //         ? CustomCircularProgresIndecator(
                //             color: Colors.white,
                //             height: SizeConfig.height * 0.02,
                //             width: SizeConfig.width * 0.02,
                //           )
                //         : Row(
                //             mainAxisAlignment: MainAxisAlignment.spaceBetween,
                //             children: [
                //               Text(
                //                 DateFormat.yMMMd()
                //                     .format(
                //                       context
                //                           .read<RoomsCubit>()
                //                           .rooms
                //                           .last
                //                           .createdAt?? DateTime.now(),
                //                     )
                //                     .toString(),
                //                 style: AppTextStyles.title14White,
                //               ),
                //             ],
                //           );
                //   },
                // ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
