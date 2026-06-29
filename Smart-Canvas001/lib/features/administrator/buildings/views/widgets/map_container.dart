import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:smart_canvas/features/administrator/buildings/view_models/cubit/add_building_cubit.dart';
import 'package:smart_canvas/features/administrator/collages/views/widgets/administrator_collages_list_view.dart';
import 'package:smart_canvas/features/administrator/collages/views/widgets/custom_failure_message.dart';
import 'package:line_icons/line_icons.dart';

class MapContainer extends StatelessWidget {
  const MapContainer({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AddBuildingCubit>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Campus Location', 
          style: TextStyle(
            fontSize: 16, 
            fontWeight: FontWeight.w800, 
            color: isDark ? Colors.white : const Color(0xFF1E1B15),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 250,
          width: double.infinity,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F0E0A) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.05),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BlocBuilder<AddBuildingCubit, AddBuildingState>(
              buildWhen: (previous, current) =>
                  current is GetCurrentLocationLoading ||
                  current is GetCurrentLocationError ||
                  current is GetCurrentLocationSuccess ||
                  current is AddMarkerSuccess,
              builder: (context, state) {
                if (state is GetCurrentLocationLoading) return const Center(child: CustomLoadingIndecator());
                if (state is GetCurrentLocationError) return CustomFailureMesage(errorMessage: state.message);
                if (cubit.initialPosition == null) return const Center(child: CustomLoadingIndecator());

                return Stack(
                  children: [
                    GoogleMap(
                      mapType: MapType.normal,
                      initialCameraPosition: cubit.initialPosition!,
                      onMapCreated: (GoogleMapController controller) {
                        if (!cubit.controller.isCompleted) cubit.controller.complete(controller);
                      },
                      onTap: (LatLng position) => cubit.addMarker(position: position),
                      markers: cubit.markers,
                      myLocationEnabled: true,
                      myLocationButtonEnabled: false,
                    ),
                    _buildMapOverlay(cubit),
                    _buildMyLocationButton(cubit),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMapOverlay(AddBuildingCubit cubit) {
    return Positioned(
      top: 16, left: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4)],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LineIcons.mapMarker, size: 14, color: Color(0xFF1E8449)),
            const SizedBox(width: 8),
            Text(
              cubit.markers.isEmpty ? "Tap to set location" : "Coordinates locked",
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF0F0E0A)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMyLocationButton(AddBuildingCubit cubit) {
    return Positioned(
      bottom: 16, right: 16,
      child: GestureDetector(
        onTap: () => cubit.moveToCurrentLocation(),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF1E8449),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1E8449).withValues(alpha: 0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(LineIcons.locationArrow, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}
