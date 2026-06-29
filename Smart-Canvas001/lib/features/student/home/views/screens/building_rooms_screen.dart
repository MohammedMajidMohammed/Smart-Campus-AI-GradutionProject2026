import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_canvas/core/components/custom_circular_progress_indecator.dart';
import 'package:smart_canvas/core/utilies/colors/app_colors.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:smart_canvas/core/utilies/sizes/sized_config.dart';
import 'package:smart_canvas/core/utilies/styles/app_text_styles.dart';
import 'package:smart_canvas/features/administrator/buildings/models/building_model.dart';
import 'package:smart_canvas/features/administrator/collages/views/widgets/custom_failure_message.dart';
import 'package:smart_canvas/features/administrator/collages/views/widgets/search_and_filter.dart';
import 'package:smart_canvas/features/administrator/rooms/view_models/cubit/rooms_cubit.dart';
import 'package:smart_canvas/features/administrator/rooms/views/widgets/administrator_rooms_list_view.dart';
import 'package:smart_canvas/features/administrator/rooms/views/widgets/room_card.dart';
import 'package:smart_canvas/features/student/navigation/views/screens/navigation_screen.dart';

import 'package:smart_canvas/features/student/navigation/views/screens/student_indoor_map_screen.dart';

class BuildingRoomsScreen extends StatefulWidget {
  const BuildingRoomsScreen({super.key, required this.building});
  final BuildingModel building;

  @override
  State<BuildingRoomsScreen> createState() => _BuildingRoomsScreenState();
}

class _BuildingRoomsScreenState extends State<BuildingRoomsScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize RoomsCubit and filter by building
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RoomsCubit>()
        ..getRooms()
        ..filterByBuilding(widget.building.id.toString());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Custom Header with Building Info
            _buildHeader(context),
            
            // Rooms List
            Expanded(
              child: BlocBuilder<RoomsCubit, RoomsState>(
                builder: (context, state) {
                  if (state is GetRoomsLoading) {
                    return const Center(child: CustomCircularProgresIndecator());
                  }
                  if (state is GetRoomsFailure) {
                    return CustomFailureMesage(errorMessage: state.message);
                  }
                  
                  // Re-apply filter if needed or rely on filteredRooms from Cubit
                  // Since we called filterByBuilding, filteredRooms should be correct.
                  // However, if getRooms() is called again (e.g. refresh), filter might be lost if logic isn't persistent.
                  // For now, we rely on the initial filter call. 
                  // Ideally, filterByBuilding should set a state flag in Cubit, but for this simple screen:
                  var rooms = context.read<RoomsCubit>().filteredRooms
                      .where((r) => r.buildingModel?.id == widget.building.id)
                      .toList();

                  if (rooms.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.meeting_room_outlined, size: 80, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          Text("no_rooms_found".tr(), style: AppTextStyles.title16BlackW500.copyWith(color: Colors.grey[500])),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: EdgeInsets.symmetric(
                      horizontal: SizeConfig.width * 0.03,
                      vertical: SizeConfig.height * 0.02,
                    ),
                    itemCount: rooms.length,
                    itemBuilder: (context, index) {
                      final room = rooms[index];
                      return GestureDetector(
                        onTap: () {
                          // Show Details Bottom Sheet (reused from Admin)
                           showModalBottomSheet(
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            context: context,
                            builder: (context) {
                              // Pass the existing RoomCubit just in case, though RoomDetails doesn't strictly need it unless editing
                              return RoomDetailsBottomSheetBody(room: room);
                            },
                          );
                        },
                        child: RoomCard(room: room),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top Bar with Back Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87),
                  onPressed: () => Navigator.pop(context),
                ),
                Expanded(
                  child: Text(
                    widget.building.name,
                    style: AppTextStyles.title20BlackW700,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
               
              ],
            ),
          ),
          
          // Image and Search
          Padding(
            padding: EdgeInsets.symmetric(horizontal: SizeConfig.width * 0.04, vertical: 8),
            child: Column(
              children: [
                // Building Image Banner
                Container(
                  height: SizeConfig.height * 0.15,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    image: DecorationImage(
                      image: NetworkImage(widget.building.image),
                      fit: BoxFit.cover,
                      colorFilter: ColorFilter.mode(Colors.black.withValues(alpha: 0.3), BlendMode.darken),
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        bottom: 12,
                        left: 12,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                             Text(
                              widget.building.collegeModel?.abbreviation ?? 'General',
                              style: AppTextStyles.title14White.copyWith(fontWeight: FontWeight.bold, color: AppColors.kPrimaryColor),
                            ),
                            Text(
                              "building_locations".tr(),
                              style: AppTextStyles.title12White.copyWith(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                       Positioned(
                        bottom: 12,
                        right: 12,
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => StudentIndoorMapScreen(
                                      building: widget.building,
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.kPrimaryColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
                                ),
                                child: const Icon(
                                  Icons.layers,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () {
                                 Navigator.push(
                                   context,
                                   MaterialPageRoute(
                                     builder: (context) => NavigationScreen(
                                       destLat: widget.building.latitude,
                                       destLng: widget.building.longitude,
                                       destName: widget.building.name,
                                     ),
                                   ),
                                 );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2), // Glass effect
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
                                ),
                                child: const Icon(
                                  Icons.navigation,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
                SizedBox(height: SizeConfig.height * 0.02),
                // Search Bar
                SearchAndFilter(
                  hintText: "search_room_hint".tr(args: [widget.building.name]),
                  onChanged: (value) {
                    context.read<RoomsCubit>().searchRooms(value);
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
