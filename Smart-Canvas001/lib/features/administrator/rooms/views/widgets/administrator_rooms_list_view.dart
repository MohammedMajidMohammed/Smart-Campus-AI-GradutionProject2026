import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_canvas/core/utilies/colors/app_colors.dart';
import 'package:smart_canvas/core/utilies/sizes/sized_config.dart';
import 'package:smart_canvas/features/administrator/buildings/models/building_model.dart';
import 'package:smart_canvas/features/administrator/collages/views/widgets/administrator_collages_list_view.dart';
import 'package:smart_canvas/features/administrator/collages/views/widgets/custom_failure_message.dart';
import 'package:smart_canvas/features/administrator/rooms/models/room_model.dart';
import 'package:smart_canvas/features/administrator/rooms/view_models/cubit/rooms_cubit.dart';
import 'package:smart_canvas/features/administrator/rooms/views/widgets/room_card.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:smart_canvas/features/administrator/rooms/views/widgets/add_room_modal_bottom_sheet_body.dart';
import 'package:smart_canvas/features/administrator/rooms/view_models/cubit/add_room_cubit.dart';
import 'package:smart_canvas/features/student/navigation/views/screens/navigation_screen.dart';
import 'package:easy_localization/easy_localization.dart';

class AdministratorRoomsListView extends StatelessWidget {
  const AdministratorRoomsListView({super.key, this.canEdit = false});
  final bool canEdit;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: BlocBuilder<RoomsCubit, RoomsState>(
        builder: (context, state) {
          if (state is GetRoomsLoading) {
            return const CustomLoadingIndecator();
          }
          if (state is GetRoomsFailure) {
            return CustomFailureMesage(errorMessage: state.message);
          }
          var rooms = context.read<RoomsCubit>().filteredRooms;
          return RefreshIndicator(
            onRefresh: () async => context.read<RoomsCubit>().getRooms(),
            backgroundColor: AppColors.kPrimaryColor,
            color: Colors.white,
            child: ListView.builder(
              padding: EdgeInsets.symmetric(
                horizontal: SizeConfig.w(2.5),
                vertical: SizeConfig.h(1.5),
              ),
              itemCount: rooms.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    final roomsCubit = context.read<RoomsCubit>();
                    showModalBottomSheet(
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      context: context,
                      builder: (context) {
                        return BlocProvider.value(
                          value: roomsCubit,
                          child: RoomDetailsBottomSheetBody(
                            room: rooms[index],
                            canEdit: canEdit,
                          ),
                        );
                      },
                    );
                  },
                  child: RoomCard(
                    key: Key(rooms[index].id.toString()),
                    room: rooms[index],
                    canEdit: canEdit,
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}


class RoomDetailsBottomSheetBody extends StatelessWidget {
  const RoomDetailsBottomSheetBody({super.key, required this.room, this.canEdit = false});
  final RoomModel room;
  final bool canEdit;

  // دالة للحصول على لون النوع (فخم حسب النوع)
  Color _getTypeColor() {
    switch (room.roomType) {
      case RoomType.hall:
        return Colors.green;
      case RoomType.lab:
        return Colors.blue;
      case RoomType.office:
        return Colors.brown;
      case RoomType.classRoom:
        return Colors.orange;
      case RoomType.mensBathroom:
        return Colors.blueGrey;
      case RoomType.womensBathroom:
        return Colors.pink;
      case RoomType.mensPrayerRoom:
        return Colors.teal;
      case RoomType.womensPrayerRoom:
        return Colors.purple;
      case RoomType.cafeteria:
        return Colors.deepOrange;
      case RoomType.teacherAssistantOffice:
        return Colors.amber;
    }
  }

  // دالة للحصول على أيقونة النوع
  IconData _getTypeIcon() {
    switch (room.roomType) {
      case RoomType.hall:
        return Icons.event_seat;
      case RoomType.lab:
        return Icons.science;
      case RoomType.office:
        return Icons.work;
      case RoomType.classRoom:
        return Icons.class_outlined;
      case RoomType.mensBathroom:
        return Icons.man;
      case RoomType.womensBathroom:
        return Icons.woman;
      case RoomType.mensPrayerRoom:
        return Icons.mosque;
      case RoomType.womensPrayerRoom:
        return Icons.mosque;
      case RoomType.cafeteria:
        return Icons.restaurant;
      case RoomType.teacherAssistantOffice:
        return Icons.support_agent;
    }
  }

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
                  SizeConfig.w(4),
                  SizeConfig.h(5),
                  SizeConfig.w(4),
                  SizeConfig.h(2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle bar with primary accent
                    Center(
                      child: Container(
                        margin: EdgeInsets.symmetric(
                          vertical: SizeConfig.h(1),
                        ),
                        width: 50,
                        height: 5,
                        decoration: BoxDecoration(
                          color: AppColors.kPrimaryColor.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                    // Room Image/Placeholder with overlay and primary border
                    Center(
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(25),
                            child: Container(
                              width: double.infinity,
                              height: SizeConfig.h(28),
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
                              child: Container(
                                decoration: BoxDecoration(
                                  image: DecorationImage(
                                    image: NetworkImage(room.image),
                                    fit: BoxFit.cover,
                                  )
                                ),
                                child: const Center(
                                  
                                ),
                              ),
                            ),
                          ),
                          // Room type badge with primary color
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
                                  Icon(
                                    _getTypeIcon(),
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    room.roomType.name.toUpperCase(),
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
                    SizedBox(height: SizeConfig.h(2.5)),
                    // Room Name with primary accent
                    Center(
                      child: Column(
                        children: [
                          Text(
                            room.name,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: SizeConfig.fontSize(24),
                              fontWeight: FontWeight.w800,
                              color: Colors.black87,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: SizeConfig.h(3.5)),
                    // Room Type Section Widget
                    _RoomTypeSection(roomType: room.roomType, typeColor: _getTypeColor(), typeIcon: _getTypeIcon()),
                    SizedBox(height: SizeConfig.h(2)),
                    // Floor Section Widget
                    _FloorSection(floorNumber: room.floorNumber),
                    if (room.side != null) ...[
                      SizedBox(height: SizeConfig.h(2)),
                      _SideSection(side: room.side!),
                    ],
                    SizedBox(height: SizeConfig.h(2)),
                    // Building Section Widget
                    _BuildingSection(building: room.buildingModel),
                    SizedBox(height: SizeConfig.h(2)),
                    // Map Section
                    _MapSection(
                      room: room,
                      onTap: () {
                        final roomsCubit = context.read<RoomsCubit>();
                        Navigator.pop(context); // Close details
                        showModalBottomSheet(
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          context: context,
                          builder: (context) => MultiBlocProvider(
                            providers: [
                              BlocProvider(
                                create: (context) => AddRoomCubit()..init(room: room),
                              ),
                              BlocProvider.value(value: roomsCubit),
                            ],
                            child: const AddRoomModalBottomSheetBody(),
                          ),
                        );
                      },
                    ),
                    SizedBox(height: SizeConfig.h(2)),
                    // Created At Section Widget
                    _CreatedAtSection(
                      createdAt: room.createdAt ?? DateTime.now(),
                    ),
                    SizedBox(height: SizeConfig.h(6)),
                  ],
                ),
              ),
              // Close and Edit Buttons
              Positioned(
                top: SizeConfig.h(1.5),
                right: SizeConfig.w(4),
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
                               destLat: room.mapX ?? 30.0444,
                               destLng: room.mapY ?? 31.2357,
                               destName: room.name,
                               destFloor: room.floorNumber,
                             ),
                           ),
                         );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.kPrimaryColor,
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
                    SizedBox(width: SizeConfig.w(3)),

                    if (canEdit) ...[
                      GestureDetector(
                        onTap: () {
                            Navigator.pop(context); // Close details
                           final roomsCubit = context.read<RoomsCubit>();
                           showModalBottomSheet(
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            context: context,
                            builder: (context) => MultiBlocProvider(
                              providers: [
                                BlocProvider(
                                  create: (context) => AddRoomCubit()..init(room: room),
                                ),
                                BlocProvider.value(value: roomsCubit),
                              ],
                              child: const AddRoomModalBottomSheetBody(),
                            ),
                          );
                        },
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
                            Icons.edit,
                            color: AppColors.kPrimaryColor,
                            size: 24,
                          ),
                        ),
                      ),
                      SizedBox(width: SizeConfig.w(3)),
                      // Delete Button
                      GestureDetector(
                        onTap: () {
                          final roomsCubit = context.read<RoomsCubit>();
                          showDialog(
                            context: context,
                            builder: (dialogContext) => Dialog(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                              backgroundColor: Colors.white,
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: Colors.red.withValues(alpha: 0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 32),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Delete Room?',
                                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Are you sure you want to delete "${room.name}"? This cannot be undone.',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontSize: 13, color: Colors.black54),
                                    ),
                                    const SizedBox(height: 24),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: OutlinedButton(
                                            onPressed: () => Navigator.pop(dialogContext),
                                            style: OutlinedButton.styleFrom(
                                              side: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                              padding: const EdgeInsets.symmetric(vertical: 12),
                                            ),
                                            child: const Text('Cancel', style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold)),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: ElevatedButton(
                                            onPressed: () {
                                              Navigator.pop(dialogContext);
                                              Navigator.pop(context); // close bottom sheet
                                              roomsCubit.deleteRoom(room.id.toString());
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.red,
                                              foregroundColor: Colors.white,
                                              elevation: 0,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                              padding: const EdgeInsets.symmetric(vertical: 12),
                                            ),
                                            child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.bold)),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.red.withValues(alpha: 0.4),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withValues(alpha: 0.15),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.delete_outline_rounded,
                            color: Colors.red,
                            size: 24,
                          ),
                        ),
                      ),
                      SizedBox(width: SizeConfig.w(3)),
                    ],
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

            ],
          ),
        );
      },
    );
  }
}

// Widget for Room Type Section
class _RoomTypeSection extends StatelessWidget {
  const _RoomTypeSection({
    required this.roomType,
    required this.typeColor,
    required this.typeIcon,
  });
  final RoomType roomType;
  final Color typeColor;
  final IconData typeIcon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title: 'room_type'.tr()),
        SizedBox(height: SizeConfig.h(1.5)),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(SizeConfig.w(3.5)),
          decoration: BoxDecoration(
            color: typeColor.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: typeColor.withValues(alpha: 0.2)),
            boxShadow: [
              BoxShadow(
                color: typeColor.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: typeColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(typeIcon, color: Colors.white, size: 20),
              ),
              SizedBox(width: SizeConfig.w(3)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      roomType.name.toUpperCase(),
                      style: TextStyle(
                        fontSize: SizeConfig.fontSize(16),
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
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

// Widget for Floor Section
class _FloorSection extends StatelessWidget {
  const _FloorSection({required this.floorNumber});
  final int floorNumber;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title: 'floor'.tr()),
        SizedBox(height: SizeConfig.h(1.5)),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(SizeConfig.w(3.5)),
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
                child: const Icon(Icons.layers, color: Colors.white, size: 20),
              ),
              SizedBox(width: SizeConfig.w(3)),
              Expanded(
                child: Text(
                  '${'floor'.tr()} $floorNumber',
                  style: TextStyle(
                    fontSize: SizeConfig.fontSize(16),
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

// Widget for Room Side Section (New)
class _SideSection extends StatelessWidget {
  const _SideSection({required this.side});
  final String side;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title: 'room_side'.tr()),
        SizedBox(height: SizeConfig.h(1.5)),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(SizeConfig.w(3.5)),
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
                child: const Icon(Icons.unfold_more_rounded, color: Colors.white, size: 20),
              ),
              SizedBox(width: SizeConfig.w(3)),
              Expanded(
                child: Text(
                  'side_$side'.tr(),
                  style: TextStyle(
                    fontSize: SizeConfig.fontSize(16),
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

// Widget for Building Section
class _BuildingSection extends StatelessWidget {
  const _BuildingSection({required this.building});
  final BuildingModel? building;

  @override
  Widget build(BuildContext context) {
    if (building == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title: 'buildings_action'.tr()),
        SizedBox(height: SizeConfig.h(1.5)),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(SizeConfig.w(3.5)),
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
                child: const Icon(Icons.apartment, color: Colors.white, size: 20),
              ),
              SizedBox(width: SizeConfig.w(3)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      building!.name,
                      style: TextStyle(
                        fontSize: SizeConfig.fontSize(16),
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
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
        SizedBox(height: SizeConfig.h(1.5)),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(SizeConfig.w(4)),
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
              SizedBox(width: SizeConfig.w(3)),
              Expanded(
                child: Text(
                  'created_on'.tr(args: [createdAt.toLocal().toString().split(' ')[0]]),
                  style: TextStyle(
                    fontSize: SizeConfig.fontSize(16),
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
          height: SizeConfig.h(3),
          decoration: BoxDecoration(
            color: AppColors.kPrimaryColor,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        SizedBox(width: SizeConfig.w(2.5)),
        Text(
          title,
          style: TextStyle(
            fontSize: SizeConfig.fontSize(18),
            fontWeight: FontWeight.w700,
            color: Colors.black87,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}

// Widget for Map Section
class _MapSection extends StatelessWidget {
  const _MapSection({required this.room, required this.onTap});
  final RoomModel room;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Default location if none exists (Cairo)
    final lat = room.mapX ?? 30.0444; 
    final lng = room.mapY ?? 31.2357;
    final position = LatLng(lat, lng);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _SectionTitle(title: 'Location'),
          ],
        ),
        SizedBox(height: SizeConfig.h(1.5)),
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: SizeConfig.h(20),
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.kPrimaryColor.withValues(alpha: 0.2)),
              boxShadow: [
                BoxShadow(
                   color: Colors.black.withValues(alpha: 0.05),
                   blurRadius: 10,
                   offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  GoogleMap(
                    liteModeEnabled: true,
                    mapType: MapType.normal,
                    initialCameraPosition: CameraPosition(
                      target: position,
                      zoom: 17,
                    ),
                    markers: {
                      Marker(
                        markerId: const MarkerId('room_location'),
                        position: position,
                      ),
                    },
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                    onTap: (_) => onTap(), 
                  ),
                  Container(
                     color: Colors.transparent, // Invisible cover to capture taps over lite map if needed
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}