import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_canvas/core/components/custom_circular_progress_indecator.dart';
import 'package:smart_canvas/core/utilies/sizes/sized_config.dart';
import 'package:smart_canvas/core/utilies/styles/app_text_styles.dart';
import 'package:smart_canvas/features/administrator/buildings/view_models/cubit/buildings_cubit.dart';

class BuildingsLenght extends StatelessWidget {
  const BuildingsLenght({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        BlocBuilder<BuildingsCubit, BuildingsState>(
          buildWhen: (previous, current) =>
              current is GetBuildingsSuccess ||
              current is GetBuildingsLoading ||
              current is GetBuildingsError,
          builder: (context, state) {
            return state is GetBuildingsLoading
                ? CustomCircularProgresIndecator(
                    color: Colors.white,
                    height: SizeConfig.height * 0.02,
                    width: SizeConfig.width * 0.02,
                  )
                : Text(
                    context.read<BuildingsCubit>().buildings.length.toString(),
                    style: AppTextStyles.title18WhiteW500,
                  );
          },
        ),
        Text("\tBuildings", style: AppTextStyles.title18WhiteW500),
      ],
    );
  }
}
