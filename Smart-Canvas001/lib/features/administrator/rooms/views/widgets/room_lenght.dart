import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_canvas/core/components/custom_circular_progress_indecator.dart';
import 'package:smart_canvas/core/utilies/sizes/sized_config.dart';
import 'package:smart_canvas/core/utilies/styles/app_text_styles.dart';
import 'package:smart_canvas/features/administrator/rooms/view_models/cubit/rooms_cubit.dart';

class RoomsLenght extends StatelessWidget {
  const RoomsLenght({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        BlocBuilder<RoomsCubit, RoomsState>(
          buildWhen: (previous, current) =>
              current is GetRoomsSuccess ||
              current is GetRoomsLoading ||
              current is GetRoomsFailure,
          builder: (context, state) {
            return state is GetRoomsLoading
                ? CustomCircularProgresIndecator(
                    color: Colors.white,
                    height: SizeConfig.height * 0.02,
                    width: SizeConfig.width * 0.02,
                  )
                : Text(
                    context.read<RoomsCubit>().rooms.length.toString(),
                    style: AppTextStyles.title18WhiteW500,
                  );
          },
        ),
        Text("\tRooms", style: AppTextStyles.title18WhiteW500),
      ],
    );
  }
}
