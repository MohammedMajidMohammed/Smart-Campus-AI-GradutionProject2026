import 'package:flutter/material.dart';
import 'package:smart_canvas/core/utilies/sizes/sized_config.dart';
import 'package:smart_canvas/features/admin/material/views/widgets/doctor_material_header.dart';
import 'package:smart_canvas/features/admin/material/views/widgets/doctor_material_list_view.dart';

class MaterialsScreenBody extends StatelessWidget {
  const MaterialsScreenBody({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const DoctorMaterialsHeader(),
        SizedBox(height: SizeConfig.height * 0.03),
        const DoctorMaterialsListView(),
      ],
    );
  }
}

