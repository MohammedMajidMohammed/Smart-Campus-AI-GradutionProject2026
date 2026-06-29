import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:smart_canvas/features/administrator/rooms/models/room_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_canvas/features/administrator/rooms/view_models/cubit/add_room_cubit.dart';
import 'package:smart_canvas/features/administrator/rooms/view_models/cubit/rooms_cubit.dart';
import 'package:smart_canvas/features/administrator/rooms/views/widgets/add_room_modal_bottom_sheet_body.dart';
import 'package:smart_canvas/features/student/navigation/views/screens/navigation_screen.dart';
import 'package:smart_canvas/features/student/navigation/views/screens/student_indoor_map_screen.dart';
import 'package:smart_canvas/core/utilies/colors/app_colors.dart';

class RoomCard extends StatelessWidget {
  final RoomModel room;
  final bool canEdit;
  const RoomCard({super.key, required this.room, this.canEdit = false});

  void _showNavigationTypeDialog(BuildContext context) {
    final isArabic = EasyLocalization.of(context)?.locale.languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.kPrimaryColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.explore_rounded,
                    color: AppColors.kPrimaryColor,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  isArabic ? "اختر طريقة الملاحة" : "Select Navigation Mode",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  isArabic 
                      ? "هل ترغب في تحديد موقع المبنى أم الملاحة الداخلية؟" 
                      : "Would you like to locate the building or navigate inside?",
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                _buildDialogOption(
                  context: dialogContext,
                  icon: Icons.map_rounded,
                  title: isArabic ? "ملاحة خارجية (خريطة الجامعة)" : "Outdoor Navigation (Campus Map)",
                  subtitle: isArabic ? "عرض اتجاهات الوصول إلى المبنى" : "Get directions to the building",
                  color: Colors.blue[600]!,
                  isDark: isDark,
                  onTap: () {
                    Navigator.pop(dialogContext);
                    if (room.mapX != null && room.mapY != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => NavigationScreen(
                            destLat: room.mapX!,
                            destLng: room.mapY!,
                            destName: room.name,
                            destFloor: room.floorNumber,
                          ),
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(height: 12),
                _buildDialogOption(
                  context: dialogContext,
                  icon: Icons.layers_rounded,
                  title: isArabic ? "ملاحة داخلية (مخطط الطوابق)" : "Indoor Navigation (Floor Plan)",
                  subtitle: isArabic ? "التوجيه من قاعة لقاعة داخل المبنى" : "Navigate room-to-room inside",
                  color: AppColors.kPrimaryColor,
                  isDark: isDark,
                  isEnabled: room.buildingModel != null,
                  onTap: () {
                    Navigator.pop(dialogContext);
                    if (room.buildingModel != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => StudentIndoorMapScreen(
                            building: room.buildingModel!,
                          ),
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(
                    isArabic ? "إلغاء" : "Cancel",
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDialogOption({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required bool isDark,
    bool isEnabled = true,
    required VoidCallback onTap,
  }) {
    return Opacity(
      opacity: isEnabled ? 1.0 : 0.5,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: 0.15),
            width: 1.5,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: isEnabled ? onTap : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 10,
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: isDark ? Colors.white24 : Colors.black26,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getTypeColor() {
    switch (room.roomType) {
      case RoomType.hall: return const Color(0xFF10B981);
      case RoomType.lab: return const Color(0xFF2ECC71);
      case RoomType.office: return const Color(0xFFF59E0B);
      case RoomType.classRoom: return const Color(0xFF8B5CF6);
      default: return const Color(0xFF1E8449);
    }
  }

  IconData _getTypeIcon() {
    switch (room.roomType) {
      case RoomType.lab: return Icons.biotech_rounded;
      case RoomType.office: return Icons.badge_rounded;
      case RoomType.hall: return Icons.event_seat_rounded;
      default: return Icons.meeting_room_rounded;
    }
  }

  void _openEditModal(BuildContext context) {
    final roomsCubit = context.read<RoomsCubit>();
    showModalBottomSheet(
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      context: context,
      builder: (context) => MultiBlocProvider(
        providers: [
          BlocProvider(create: (context) => AddRoomCubit()..initEdit(room)),
          BlocProvider.value(value: roomsCubit),
        ],
        child: const AddRoomModalBottomSheetBody(),
      ),
    );
  }

  void _showDeleteConfirmDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final roomsCubit = context.read<RoomsCubit>();
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
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
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Are you sure you want to delete "${room.name}"? This action cannot be undone.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
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
                      child: Text('Cancel', style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(dialogContext);
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
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color mainColor = _getTypeColor();

    final sideValue = room.side?.trim().toLowerCase();
    final bool hasSide = sideValue != null && sideValue.isNotEmpty;

    final card = Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1B15) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            offset: const Offset(0, 8),
            blurRadius: 20,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              if (room.mapX != null && room.mapY != null) {
                _showNavigationTypeDialog(context);
              } else if (room.buildingModel != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StudentIndoorMapScreen(
                      building: room.buildingModel!,
                    ),
                  ),
                );
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  _buildIconStack(mainColor, hasSide, sideValue),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTopRow(mainColor, hasSide, sideValue),
                        const SizedBox(height: 4),
                        Text(
                          room.name,
                          style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white : const Color(0xFF1E1B15),
                            letterSpacing: -0.5,
                          ),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        _buildDetailsRow(isDark, room),
                        if (canEdit) ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              _buildActionIcon(
                                context,
                                icon: Icons.edit_note_rounded,
                                color: mainColor,
                                onTap: () => _openEditModal(context),
                              ),
                              const SizedBox(width: 6),
                              _buildActionIcon(
                                context,
                                icon: Icons.delete_outline_rounded,
                                color: Colors.red,
                                onTap: () => _showDeleteConfirmDialog(context),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (!canEdit) return card;

    return Dismissible(
      key: Key('dismiss_${room.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        _showDeleteConfirmDialog(context);
        return false; // actual delete handled in dialog
      },
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.delete_outline_rounded, color: Colors.white, size: 28),
            SizedBox(height: 4),
            Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
          ],
        ),
      ),
      child: card,
    );
  }

  Widget _buildIconStack(Color mainColor, bool hasSide, String? sideValue) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 70, width: 70,
          decoration: BoxDecoration(
            color: mainColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Icon(_getTypeIcon(), size: 30, color: mainColor),
        ),
        if (hasSide)
          Positioned(
            top: -2, left: -2,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: mainColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2.0),
              ),
              child: Icon(
                sideValue == 'left' ? Icons.west_rounded : 
                sideValue == 'right' ? Icons.east_rounded : 
                Icons.center_focus_strong_rounded,
                size: 10, color: Colors.white,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTopRow(Color mainColor, bool hasSide, String? sideValue) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Row(
            children: [
              Text(
                room.roomType.name.toUpperCase(),
                style: TextStyle(
                  fontSize: 8, fontWeight: FontWeight.w900,
                  color: mainColor, letterSpacing: 1.0,
                ),
              ),
              if (hasSide) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: mainColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    sideValue!.toUpperCase(),
                    style: TextStyle(fontSize: 7, fontWeight: FontWeight.w900, color: mainColor),
                  ),
                ),
              ],
            ],
          ),
        ),
        Icon(Icons.arrow_forward_ios_rounded, size: 10, color: Colors.grey.withValues(alpha: 0.3)),
      ],
    );
  }

  Widget _buildDetailsRow(bool isDark, RoomModel room) {
    return Row(
      children: [
        Expanded(child: _buildDetailItem(Icons.business_rounded, room.buildingModel?.name ?? 'Facility', isDark)),
        const SizedBox(width: 8),
        _buildDetailItem(Icons.layers_rounded, '${'floor'.tr()} ${room.floorNumber}', isDark),
      ],
    );
  }

  Widget _buildDetailItem(IconData icon, String text, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: Colors.grey[400]),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: isDark ? Colors.white54 : Colors.grey[600]),
            maxLines: 1, overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildActionIcon(BuildContext context, {required IconData icon, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }
}