import 'package:flutter/material.dart';
import 'package:smart_canvas/core/utilies/sizes/sized_config.dart';
import 'package:smart_canvas/features/administrator/buildings/views/widgets/administrator_buildings_header.dart';
import 'package:smart_canvas/features/administrator/buildings/views/widgets/administrator_buildings_list_view.dart';

class BuildingsScreenBody extends StatelessWidget {
  const BuildingsScreenBody({super.key, this.title, this.canEdit = false});
  final String? title;
  final bool canEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        children: [
          AdministratorBuildingsHeader(title: title),
          SizedBox(height: SizeConfig.height * 0.02),
          AdministratorBuildingsListView(canEdit: canEdit),
        ],
      ),
    );
  }
}
