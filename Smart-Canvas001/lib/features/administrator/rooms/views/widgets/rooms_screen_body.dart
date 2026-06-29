import 'package:flutter/material.dart';
import 'package:smart_canvas/core/utilies/sizes/sized_config.dart';
import 'package:smart_canvas/features/administrator/rooms/views/widgets/administrator_rooms_header.dart';
import 'package:smart_canvas/features/administrator/rooms/views/widgets/administrator_rooms_list_view.dart';

class RoomsScreenBody extends StatelessWidget {
  const RoomsScreenBody({super.key, this.canEdit = false});
  final bool canEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        children: [
          const AdministratorRoomsHeader(),
          SizedBox(height: SizeConfig.height * 0.02),
          AdministratorRoomsListView(canEdit: canEdit),
        ],
      ),
    );
  }
}
