import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_canvas/core/components/custom_circular_progress_indecator.dart';
import 'package:smart_canvas/core/utilies/sizes/sized_config.dart';
import 'package:smart_canvas/core/utilies/styles/app_text_styles.dart';
import 'package:smart_canvas/features/admin/subjects/view_models/cubit/subjects_cubit.dart';

class SubjectLenght extends StatelessWidget {
  const SubjectLenght({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        BlocBuilder<SubjectsCubit, SubjectsState>(
          buildWhen: (previous, current) =>
              current is GetSubjectsSuccess ||
              current is GetSubjectsLoading ||
              current is GetSubjectsFailure,
          builder: (context, state) {
            return state is GetSubjectsLoading
                ? CustomCircularProgresIndecator(
                    color: Colors.white,
                    height: SizeConfig.height * 0.02,
                    width: SizeConfig.width * 0.04,
                  )
                : Text(
                    context.read<SubjectsCubit>().subjects.length.toString(),
                    style: AppTextStyles.title18WhiteW500,
                  );
          },
        ),
        Text("\tSubjects", style: AppTextStyles.title18WhiteW500),
      ],
    );
  }
}
