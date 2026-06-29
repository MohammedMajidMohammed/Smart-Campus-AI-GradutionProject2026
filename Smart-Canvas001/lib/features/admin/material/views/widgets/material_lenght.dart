import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_canvas/core/components/custom_circular_progress_indecator.dart';
import 'package:smart_canvas/core/utilies/sizes/sized_config.dart';
import 'package:smart_canvas/core/utilies/styles/app_text_styles.dart';
import 'package:smart_canvas/features/admin/material/view_models/cubit/materials_cubit.dart';

class MaterialLenght extends StatelessWidget {
  const MaterialLenght({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        BlocBuilder<MaterialsCubit, MaterialsState>(
          buildWhen: (previous, current) =>
              current is GetMaterialsSuccess ||
              current is GetMaterialsLoading ||
              current is GetMaterialsFailure,
          builder: (context, state) {
            return state is GetMaterialsLoading
                ? CustomCircularProgresIndecator(
                    color: Colors.white,
                    height: SizeConfig.height * 0.02,
                    width: SizeConfig.width * 0.04,
                  )
                : Text(
                    context.read<MaterialsCubit>().materials.length.toString(),
                    style: AppTextStyles.title18WhiteW500,
                  );
          },
        ),
        Text("\tMaterials", style: AppTextStyles.title18WhiteW500),
      ],
    );
  }
}
