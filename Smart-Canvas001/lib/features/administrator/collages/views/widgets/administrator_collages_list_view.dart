import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_canvas/core/utilies/sizes/sized_config.dart';
import 'package:smart_canvas/features/administrator/collages/view_models/cubit/colleges_cubit.dart';
import 'package:smart_canvas/features/administrator/collages/views/widgets/collage_card.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:smart_canvas/features/administrator/collages/views/widgets/collage_details_model_bottom_sheet_body.dart';
import 'package:smart_canvas/features/administrator/collages/views/widgets/custom_failure_message.dart';

class AdministratorCollagesListView extends StatelessWidget {
  const AdministratorCollagesListView({super.key});

  @override
  Widget build(BuildContext screenContext) {
    return Expanded(
      child: BlocBuilder<CollegesCubit, CollegesState>(
        builder: (context, state) {
          if (state is GetCollegesLoading) {
            return const CustomLoadingIndecator();
          }
          if (state is GetCollegesError) {
            return CustomFailureMesage(errorMessage: state.message);
          }
          var colleges = screenContext.read<CollegesCubit>().filteredColleges;
          final isTablet = MediaQuery.of(context).size.width > 600;

          return GridView.builder(
            padding: EdgeInsets.fromLTRB(
              SizeConfig.width * 0.04,
              SizeConfig.height * 0.015,
              SizeConfig.width * 0.04,
              SizeConfig.height * 0.1, // Added bottom padding for FAB
            ),
            itemCount: colleges.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isTablet ? 2 : 1,
              mainAxisSpacing: 10,
              crossAxisSpacing: isTablet ? 20 : 0,
              mainAxisExtent: SizeConfig.height * 0.22, // Fixed height for cards
            ),
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    context: screenContext,
                    builder: (modalContext) {
                      return BlocProvider.value(
                        value: screenContext.read<CollegesCubit>(),
                        child: CollageDetailsModelBottomSheetBody(
                          collage: colleges[index],
                        ),
                      );
                    },
                  );
                },
                child: CollageCard(
                  key: Key(colleges[index].id),
                  collage: colleges[index],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class CustomLoadingIndecator extends StatelessWidget {
  const CustomLoadingIndecator({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: LoadingAnimationWidget.staggeredDotsWave(
        color: Colors.white,
        size: SizeConfig.width * 0.4,
      ),
    );
  }
}

