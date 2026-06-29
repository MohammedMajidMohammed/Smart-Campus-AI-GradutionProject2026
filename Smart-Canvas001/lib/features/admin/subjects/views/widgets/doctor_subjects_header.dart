import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:smart_canvas/core/components/custom_circular_progress_indecator.dart';
import 'package:smart_canvas/core/utilies/colors/app_colors.dart';
import 'package:smart_canvas/core/utilies/sizes/sized_config.dart';
import 'package:smart_canvas/core/utilies/styles/app_text_styles.dart';
import 'package:smart_canvas/features/administrator/buildings/views/widgets/wave_image.dart';
import 'package:smart_canvas/features/administrator/collages/views/widgets/search_and_filter.dart';
import 'package:smart_canvas/features/admin/subjects/view_models/cubit/subjects_cubit.dart';
import 'package:smart_canvas/features/admin/subjects/views/widgets/subject_lenght.dart';

class DoctorSubjectsHeader extends StatelessWidget {
  const DoctorSubjectsHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.kPrimaryColor,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(SizeConfig.w(5)),
          bottomRight: Radius.circular(SizeConfig.w(5)),
        ),
      ),
      child: Stack(
        children: [
          const WaveImage(),
          Padding(
            padding: EdgeInsets.only(
              top:
                  MediaQuery.of(context).padding.top + SizeConfig.h(1),
              left: SizeConfig.w(3),
              right: SizeConfig.w(3),
              bottom: SizeConfig.h(2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Management Subjects",
                  style: AppTextStyles.title24WhiteW500,
                ),
                SizedBox(height: SizeConfig.h(1.5)),
                SearchAndFilter(
                  hintText: "Search for subject",
                  onChanged: (value) {
                    context.read<SubjectsCubit>().searchSubjects(value);
                  },
                ),
                SizedBox(height: SizeConfig.h(1)),
                const SubjectLenght(),
                SizedBox(height: SizeConfig.h(0.3)),
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
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                DateFormat.yMMMd()
                                    .format(
                                      context
                                          .read<SubjectsCubit>()
                                          .subjects
                                          .last
                                          .createdAt?? DateTime.now(),
                                    )
                                    .toString(),
                                style: AppTextStyles.title14White,
                              ),
                            ],
                          );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
