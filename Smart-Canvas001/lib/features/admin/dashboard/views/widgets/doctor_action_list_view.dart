import 'package:flutter/material.dart';
import 'package:smart_canvas/core/components/animated_card.dart';
import 'package:smart_canvas/core/constants/app_constants.dart';
import 'package:smart_canvas/core/utilies/sizes/sized_config.dart';
import 'package:smart_canvas/core/utilies/extensions/app_extensions.dart';
import 'package:smart_canvas/features/admin/dashboard/views/widgets/doctor_action_card.dart';
class DoctorActionListView extends StatelessWidget {
  const DoctorActionListView({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    // Responsive grid count based on device type
    final crossAxisCount = SizeConfig.gridCount(
      mobile: 2,
      tablet: 3,
      desktop: 4,
    );

    // Responsive aspect ratio
    final aspectRatio = SizeConfig.responsive(
      mobile: 0.9,
      tablet: 0.85,
      desktop: 0.8,
    );

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: SizeConfig.maxContentWidth,
        ),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(
            horizontal: SizeConfig.horizontalPadding,
            vertical: SizeConfig.verticalPadding,
          ),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: SizeConfig.spacing(12),
            mainAxisSpacing: SizeConfig.spacing(12),
            childAspectRatio: aspectRatio,
          ),
          itemCount: AppConstants.doctorActions.length,
          itemBuilder: (context, index) => AnimatedCard(
            delay: Duration(milliseconds: 80 * index),
            onTap: () {
              context.pushScreen(AppConstants.doctorActions[index].route);
            },
            child: DoctorActionCard(
              doctorActionModel: AppConstants.doctorActions[index],
            ),
          ),
        ),
      ),
    );
  }
}
