import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_canvas/features/administrator/buildings/views/widgets/add_floating_action_button.dart';
import 'package:smart_canvas/features/administrator/rooms/view_models/cubit/add_room_cubit.dart';
import 'package:smart_canvas/features/administrator/rooms/view_models/cubit/rooms_cubit.dart';
import 'package:smart_canvas/features/administrator/rooms/views/widgets/add_room_modal_bottom_sheet_body.dart';
import 'package:smart_canvas/features/administrator/rooms/views/widgets/rooms_screen_body.dart';
import 'package:smart_canvas/core/cache/cache_helper.dart';
import 'package:smart_canvas/core/di/dependancy_injection.dart';

class RoomsScreen extends StatelessWidget {
  const RoomsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = getIt<CacheHelper>().getUserModel();
    final String roleName = (user?.roleName ?? '').trim().toLowerCase();
    // Simplify: Allow editing by default on management screens unless explicitly restricted
    final bool isAdmin = roleName != 'student' && roleName != 'professor';

    return Scaffold(
      body: RoomsScreenBody(canEdit: isAdmin),
      floatingActionButton: isAdmin ? AddFloatingActionButton(
              onPressed: () {
                final roomsCubit = context.read<RoomsCubit>();
                showModalBottomSheet(
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  context: context,
                  builder: (context) => MultiBlocProvider(
                    providers: [
                      BlocProvider(create: (context) => AddRoomCubit()..init()),
                      BlocProvider.value(value: roomsCubit),
                    ],
                    child: const AddRoomModalBottomSheetBody(),
                  ),
                );
              },
      ) : null,
    );
  }
}
