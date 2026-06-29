import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_canvas/features/administrator/rooms/view_models/cubit/add_room_cubit.dart';
import 'package:line_icons/line_icons.dart';

class RoomImage extends StatelessWidget {
  const RoomImage({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AddRoomCubit>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Room Image', 
          style: TextStyle(
            fontSize: 16, 
            fontWeight: FontWeight.w800, 
            color: isDark ? Colors.white : const Color(0xFF1E1B15),
          ),
        ),
        const SizedBox(height: 12),
        BlocBuilder<AddRoomCubit, AddRoomState>(
          buildWhen: (previous, current) => current is PickImageSuccess || current is PickImageError,
          builder: (context, state) {
            final hasImage = cubit.roomImage != null;
            
            return GestureDetector(
              onTap: () => cubit.pickRoomImage(),
              child: Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.05),
                    width: 1.5,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: hasImage
                      ? Image.file(cubit.roomImage!, fit: BoxFit.cover)
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E8449).withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(LineIcons.image, color: Color(0xFF1E8449), size: 32),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Capture room appearance',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? Colors.white54 : Colors.grey[600],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
