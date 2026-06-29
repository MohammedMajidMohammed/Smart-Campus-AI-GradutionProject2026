import 'package:flutter/material.dart';
import 'package:smart_canvas/features/administrator/dashboard/views/widgets/administrator_dashboard_screen_body.dart';

class AdministratorDashboardScreen extends StatelessWidget {
  const AdministratorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      extendBodyBehindAppBar: true,
      body: SafeArea(
        child: AdministratorDashboardScreenBody(),
      ),
    );
  }
}

