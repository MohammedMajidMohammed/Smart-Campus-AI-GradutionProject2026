import 'dart:async';
import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:smart_canvas/core/di/dependancy_injection.dart';
import 'package:smart_canvas/core/helper/location/get_current_location.dart';
import 'package:smart_canvas/core/helper/location/location_permission.dart';
import 'package:smart_canvas/core/helper/pick_image.dart';
import 'package:smart_canvas/core/network/supabase/database/add_data.dart';
import 'package:smart_canvas/core/network/supabase/storage/upload_file.dart';
import 'package:smart_canvas/features/administrator/collages/models/collage_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smart_canvas/features/administrator/buildings/models/building_model.dart';

part 'add_building_state.dart';

class AddBuildingCubit extends Cubit<AddBuildingState> {
  AddBuildingCubit() : super(AddBuildingInitial()) {
    init();
  }
  //-- variables --//
  final formKey = GlobalKey<FormState>();
  final buildingNameController = TextEditingController();
  Position? position, currentLocation;
  final supabase = getIt<SupabaseClient>();
  bool enableLocation = false;
  File? buildingImage;
  String? collegeId;
  String? buildingType;
  List<CollegeModel> colleges = [];
  Set<Marker> markers = {};
  final Completer<GoogleMapController> controller = Completer();
  CameraPosition? initialPosition;
  BuildingModel? buildingToEdit;
  
  //-- functions --//
  init() async {
    buildingToEdit = null; // Reset edit mode
    Future.wait([getColleges(), moveToCurrentLocation()]);
  }
  
  // Initialize Edit Mode
  initEdit(BuildingModel building) async {
    buildingToEdit = building;
    buildingNameController.text = building.name;
    collegeId = building.collegeModel?.id;
    buildingType = building.buildingType.name;
    
    // Set location
    position = Position(
      latitude: building.latitude,
      longitude: building.longitude,
      timestamp: DateTime.now(),
      accuracy: 1,
      altitude: 1,
      heading: 1,
      speed: 1,
      speedAccuracy: 1,
      altitudeAccuracy: 1,
      headingAccuracy: 1,
    );
    
    initialPosition = CameraPosition(
      target: LatLng(building.latitude, building.longitude),
      zoom: 19,
    );
    
    markers.add(
      Marker(
        markerId: const MarkerId('myLocation'),
        position: LatLng(building.latitude, building.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    );
    
    await getColleges(); // Ensure colleges are loaded
    // We don't get current location in edit mode to avoid overriding the building's location
    emit(GetCurrentLocationSuccess());
  }

  // get college
  Future<void> getColleges() async {
    try {
      emit(GetCollegesLoading());
      final response = await supabase.rpc('get_colleges_full');
      final List list = response as List;
      colleges = list.map((e) => CollegeModel.fromJson(e)).toList();
      emit(GetCollegesSuccess());
    } catch (e) {
      emit(GetCollegesError(message: e.toString()));
    }
  }

  // add marker
  addMarker({required LatLng position}) {
    markers.clear();
    this.position = Position(
      latitude: position.latitude,
      longitude: position.longitude,
      timestamp: DateTime.now(),
      accuracy: 1,
      altitude: 1,
      heading: 1,
      speed: 1,
      speedAccuracy: 1,
      altitudeAccuracy: 1,
      headingAccuracy: 1,
    );
    markers.add(
      Marker(
        markerId: const MarkerId('myLocation'),
        position: position,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    );
    emit(AddMarkerSuccess());
  }

  // get current location and move camera
  Future<void> moveToCurrentLocation() async {
    try {
      emit(GetCurrentLocationLoading());
      enableLocation = await requestLocationPermission();
      Position? loc;
      if (enableLocation == true) {
        try {
          loc = await getCurrentLocation();
        } catch (e) {
          debugPrint("Failed to fetch precise location for building: $e");
        }
      }
      
      final target = loc != null
          ? LatLng(loc.latitude, loc.longitude)
          : const LatLng(30.0444, 31.2357);

      initialPosition = CameraPosition(target: target, zoom: 16);
      addMarker(position: target);

      if (controller.isCompleted) {
        final googleMapController = await controller.future;
        googleMapController.animateCamera(CameraUpdate.newLatLng(target));
      }
      emit(GetCurrentLocationSuccess());
    } catch (e) {
      debugPrint("Unhandled building location error: $e");
      const target = LatLng(30.0444, 31.2357);
      initialPosition = const CameraPosition(target: target, zoom: 16);
      addMarker(position: target);
      emit(GetCurrentLocationSuccess());
    }
  }
  // pick image
  pickBuildingImage() async {
    try {
      final image = await pickImage(source: ImageSource.gallery);
      if (image != null) {
        buildingImage = image;
        emit(PickImageSuccess());
      }
    } on Exception catch (e) {
      emit(PickImageError(message: e.toString()));
    }
  }

  // save building (Add or Edit)
  saveBuilding() async {
    if (formKey.currentState!.validate()) {
      if (position == null) {
        emit(SelectLocation());
        return;
      }
      // For edit, image is optional (keep old one). For add, it's required.
      if (buildingToEdit == null && buildingImage == null) {
        emit(SelectBuildingImage());
        return;
      }
      if (collegeId == null) {
        emit(SelectCollege());
        return;
      }
      if (buildingType == null) {
        emit(SelectBuildingType());
        return;
      }
      
      try {
        emit(AddBuildingLoading());
        
        String? imageUrl;
        if (buildingImage != null) {
           imageUrl = await uploadFileToSupabaseStorage(file: buildingImage!, pucketName: "buildings");
        } else {
           imageUrl = buildingToEdit?.image;
        }

        final data = {
            "name": buildingNameController.text,
            "college_id": collegeId,
            "building_type": buildingType,
            "image": imageUrl,
            "latitude": position!.latitude,
            "longitude": position!.longitude,
        };

        if (buildingToEdit != null) {
          // UPDATE
          await supabase.from('buildings').update(data).eq('id', buildingToEdit!.id);
        } else {
          // INSERT
          await addData(tableName: "buildings", data: data);
        }
        
        emit(AddBuildingSuccess());
      } catch (e) {
        emit(AddBuildingError(message: e.toString()));
      }
    }
  }
}
