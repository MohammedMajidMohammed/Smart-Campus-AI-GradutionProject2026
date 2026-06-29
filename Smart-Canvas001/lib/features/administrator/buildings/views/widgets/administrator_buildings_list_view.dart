import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_canvas/core/utilies/colors/app_colors.dart';
import 'package:smart_canvas/core/utilies/sizes/sized_config.dart';
import 'package:smart_canvas/features/administrator/buildings/models/building_model.dart';
import 'package:smart_canvas/features/administrator/buildings/view_models/cubit/buildings_cubit.dart';
import 'package:smart_canvas/features/administrator/buildings/views/widgets/buildings_card.dart';
import 'package:smart_canvas/features/administrator/collages/models/collage_model.dart';
import 'package:smart_canvas/features/administrator/collages/views/widgets/administrator_collages_list_view.dart';
import 'package:smart_canvas/features/administrator/collages/views/widgets/custom_failure_message.dart';
import 'package:smart_canvas/features/administrator/buildings/view_models/cubit/add_building_cubit.dart';
import 'package:smart_canvas/features/administrator/buildings/views/widgets/add_building_modal_bottom_sheet_body.dart';
import 'package:smart_canvas/features/student/navigation/views/screens/navigation_screen.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:smart_canvas/core/app_route/route_names.dart';

class AdministratorBuildingsListView extends StatelessWidget {
  const AdministratorBuildingsListView({super.key, this.canEdit = false});
  final bool canEdit;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: BlocBuilder<BuildingsCubit, BuildingsState>(
        builder: (context, state) {
          if (state is GetBuildingsLoading) {
            return const CustomLoadingIndecator();
          }
          if (state is GetBuildingsError) {
            return CustomFailureMesage(errorMessage: state.message);
          }
          var buildings = context.read<BuildingsCubit>().filteredBuildings;
          return ListView.builder(
            padding: EdgeInsets.symmetric(
              horizontal: SizeConfig.width * 0.025,
              vertical: SizeConfig.height * 0.015,
            ),
            itemCount: buildings.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    RouteNames.roomsScreen,
                    arguments: buildings[index].id,
                  );
                },
                child: BuildingCard(
                  key: Key(buildings[index].id.toString()),
                  building: buildings[index],
                  canEdit: canEdit,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class BuildingDetailsBottomSheetBody extends StatelessWidget {
  const BuildingDetailsBottomSheetBody({super.key, required this.building, this.canEdit = false});
  final BuildingModel building;
  final bool canEdit;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 25,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Stack(
            children: [
              SingleChildScrollView(
                controller: scrollController,
                padding: EdgeInsets.fromLTRB(
                  SizeConfig.width * 0.04,
                  SizeConfig.height * 0.05,
                  SizeConfig.width * 0.04,
                  SizeConfig.height * 0.02,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle bar with primary accent
                    Center(
                      child: Container(
                        margin: EdgeInsets.symmetric(
                          vertical: SizeConfig.height * 0.01,
                        ),
                        width: 50,
                        height: 5,
                        decoration: BoxDecoration(
                          color: AppColors.kPrimaryColor.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                    // Building Image with overlay and primary border
                    Center(
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(25),
                            child: Container(
                              width: double.infinity,
                              height: SizeConfig.height * 0.28,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(25),
                                border: Border.all(
                                  color: AppColors.kPrimaryColor.withValues(alpha: 
                                    0.3,
                                  ),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.kPrimaryColor.withValues(alpha: 
                                      0.2,
                                    ),
                                    blurRadius: 15,
                                    offset: const Offset(5, 10),
                                  ),
                                ],
                              ),
                              child: Image.network(
                                building.image,
                                fit: BoxFit.cover,
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Container(
                                        height: SizeConfig.height * 0.28,
                                        color: Colors.grey.shade200,
                                        child: const Center(
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  AppColors.kPrimaryColor,
                                                ),
                                          ),
                                        ),
                                      );
                                    },
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    height: SizeConfig.height * 0.28,
                                    color: Colors.grey.shade200,
                                    child: const Icon(
                                      Icons.apartment_outlined,
                                      size: 80,
                                      color: Colors.grey,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          // Building type badge with primary color
                          Positioned(
                            bottom: 10,
                            right: 10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                                ),
                              decoration: BoxDecoration(
                                color: AppColors.kPrimaryColor,
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.business_center,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    building.buildingType.name.toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: SizeConfig.height * 0.025),
                    // Building Name and College Abbreviation with primary accent
                    Center(
                      child: Column(
                        children: [
                          Text(
                            building.name,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: SizeConfig.width * 0.065,
                              fontWeight: FontWeight.w800,
                              color: Colors.black87,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: SizeConfig.height * 0.035),
                    // College Section Widget
                    _CollegeSection(college: building.collegeModel),
                    SizedBox(height: SizeConfig.height * 0.02),
                    // Location Section Widget
                    // Created At Section Widget
                    _CreatedAtSection(
                      createdAt: building.createdAt ?? DateTime.now(),
                    ),
                    SizedBox(height: SizeConfig.height * 0.06),
                  ],
                ),
              ),
              // Close and Navigate Buttons
              Positioned(
                top: SizeConfig.height * 0.015,
                right: SizeConfig.width * 0.04,
                child: Row(
                  children: [
                    // Navigate Button
                    GestureDetector(
                      onTap: () {
                         Navigator.pop(context); // Close details
                         // Navigate to NavigationScreen
                         Navigator.push(
                           context,
                           MaterialPageRoute(
                             builder: (context) => NavigationScreen(
                               destLat: building.latitude,
                               destLng: building.longitude,
                               destName: building.name,
                             ),
                           ),
                         );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.kPrimaryColor, // Primary color for emphasis
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.kPrimaryColor.withValues(alpha: 0.4),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.navigation,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                    SizedBox(width: SizeConfig.width * 0.03),
                    
                    // Close Button
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.kPrimaryColor.withValues(alpha: 0.5),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.kPrimaryColor.withValues(alpha: 0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.close,
                          color: AppColors.kPrimaryColor,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Edit Button (Top Left)
              if (canEdit)
                Positioned(
                  top: SizeConfig.height * 0.015,
                  left: SizeConfig.width * 0.04,
                  child: GestureDetector(
                    onTap: () {
                      showModalBottomSheet(
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        context: context,
                        builder: (context) => BlocProvider(
                          create: (context) => AddBuildingCubit()..initEdit(building),
                          child: const AddBuildingModalBottomSheetBody(),
                        ),
                      ).then((value) {
                        if (context.mounted) {
                          context.read<BuildingsCubit>().getBuildings();
                        }
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.kPrimaryColor, // Solid primary for edit
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.kPrimaryColor.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.edit,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

// Widget for College Section
class _CollegeSection extends StatelessWidget {
  const _CollegeSection({required this.college});
  final CollegeModel? college;

  @override
  Widget build(BuildContext context) {
    if (college == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title: 'college_lbl'.tr()),
        SizedBox(height: SizeConfig.height * 0.015),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(SizeConfig.width * 0.035),
          decoration: BoxDecoration(
            color: AppColors.kPrimaryColor.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.kPrimaryColor.withValues(alpha: 0.2)),
            boxShadow: [
              BoxShadow(
                color: AppColors.kPrimaryColor.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: AppColors.kPrimaryColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.school, color: Colors.white, size: 20),
              ),
              SizedBox(width: SizeConfig.width * 0.03),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      college!.name,
                      style: TextStyle(
                        fontSize: SizeConfig.width * 0.045,
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      college!.abbreviation,
                      style: TextStyle(
                        fontSize: SizeConfig.width * 0.035,
                        color: AppColors.kPrimaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
// Widget for Created At Section (updated with primary)
class _CreatedAtSection extends StatelessWidget {
  const _CreatedAtSection({required this.createdAt});
  final DateTime createdAt;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title: 'created_at'.tr()),
        SizedBox(height: SizeConfig.height * 0.015),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(SizeConfig.width * 0.04),
          decoration: BoxDecoration(
            color: AppColors.kPrimaryColor.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.kPrimaryColor.withValues(alpha: 0.2)),
            boxShadow: [
              BoxShadow(
                color: AppColors.kPrimaryColor.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: AppColors.kPrimaryColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.calendar_today,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              SizedBox(width: SizeConfig.width * 0.03),
              Expanded(
                child: Text(
                  'created_on'.tr(args: [createdAt.toLocal().toString().split(' ')[0]]),
                  style: TextStyle(
                    fontSize: SizeConfig.width * 0.045,
                    color: AppColors.kPrimaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Widget for Section Title (updated with primary)
class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 5,
          height: SizeConfig.height * 0.03,
          decoration: BoxDecoration(
            color: AppColors.kPrimaryColor,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        SizedBox(width: SizeConfig.width * 0.025),
        Text(
          title,
          style: TextStyle(
            fontSize: SizeConfig.width * 0.055,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}
