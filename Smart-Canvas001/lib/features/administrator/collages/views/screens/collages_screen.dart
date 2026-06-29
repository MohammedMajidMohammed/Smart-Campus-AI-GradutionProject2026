import 'package:flutter/material.dart';
import 'package:smart_canvas/features/administrator/collages/views/widgets/add_collage_floating_action_button.dart';
import 'package:smart_canvas/features/administrator/collages/views/widgets/collages_screen_body.dart';

class CollagesScreen extends StatelessWidget {
  const CollagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: CollagesScreenBody(),
      floatingActionButton: AddCollageFloatingActionButton(),
    );
  }
}


