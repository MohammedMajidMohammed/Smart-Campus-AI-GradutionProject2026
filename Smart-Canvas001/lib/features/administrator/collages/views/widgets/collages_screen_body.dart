import 'package:flutter/material.dart';
import 'package:smart_canvas/core/utilies/sizes/sized_config.dart';
import 'package:smart_canvas/features/administrator/collages/views/widgets/administrator_collages_header.dart';
import 'package:smart_canvas/features/administrator/collages/views/widgets/administrator_collages_list_view.dart';

class CollagesScreenBody extends StatelessWidget {
  const CollagesScreenBody({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const AdministratorCollagesHeader(),
        SizedBox(height: SizeConfig.height * 0.03),
        const AdministratorCollagesListView(),
      ],
    );
  }
}

