import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_canvas/core/app_route/route_names.dart';
import 'package:smart_canvas/core/utilies/extensions/app_extensions.dart';
import 'package:smart_canvas/core/utilies/sizes/sized_config.dart';
import 'package:smart_canvas/features/administrator/collages/views/widgets/custom_failure_message.dart';
import 'package:smart_canvas/features/student/dashboard/view_models/college_data_cubit.dart';
import 'package:smart_canvas/features/student/dashboard/views/widgets/subject_card.dart';
import 'package:easy_localization/easy_localization.dart';

class StudentSubjectsGridView extends StatelessWidget {
  const StudentSubjectsGridView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CollegeDataCubit, CollegeDataState>(
        builder: (context, state) {
          if (state is CollegeDataLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is CollegeDataFailure) {
            return CustomFailureMesage(errorMessage: state.error);
          }
          final subjects = context.read<CollegeDataCubit>().filteredSubjects;
          if (subjects.isEmpty) {
            return Center(
              child: Text(
                'no_subjects_matched'.tr(),
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }
          
          // Determine grid configuration based on device type
          final crossAxisCount = SizeConfig.gridCount(
            mobile: 2,
            tablet: 3,
            desktop: 4,
          );
          
          // Calculate max width for tablet/desktop centering
          final maxWidth = SizeConfig.isTablet || SizeConfig.isDesktop
              ? SizeConfig.maxContentWidth
              : double.infinity;
          
          Widget gridWidget = GridView.builder(
            padding: EdgeInsets.all(SizeConfig.w(2)),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount, 
              crossAxisSpacing: SizeConfig.spacing(8),
              mainAxisSpacing: SizeConfig.spacing(8),
              childAspectRatio: SizeConfig.responsive(
                mobile: 1.6,
                tablet: 1.8,
                desktop: 2.0,
              ), 
              mainAxisExtent: SizeConfig.responsive(
                mobile: 135.0,
                tablet: 145.0,
                desktop: 155.0,
              ), 
            ),
            itemCount: subjects.length,
            itemBuilder: (context, index) {
              final subject = subjects[index];
              return SubjectCard(
                key: ValueKey(subject.id), 
                subject: subject,
                onTap: () {
                  context.pushScreen(
                    RouteNames.subjectDetailsScreen,
                    arguments: subject.toJson(),
                  );
                },
              );
            },
          );
          
          // Center the grid on tablet/desktop
          if (SizeConfig.isTablet || SizeConfig.isDesktop) {
            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: gridWidget,
              ),
            );
          }
          
          return gridWidget;
        },
      );
  }
}
