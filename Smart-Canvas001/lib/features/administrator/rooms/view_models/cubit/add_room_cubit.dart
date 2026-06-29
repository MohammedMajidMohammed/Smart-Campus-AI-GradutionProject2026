import 'dart:async';
import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:smart_canvas/core/di/dependancy_injection.dart';
import 'package:smart_canvas/core/helper/location/get_current_location.dart' as LocationHelper;
import 'package:smart_canvas/core/helper/location/location_permission.dart';
import 'package:smart_canvas/core/helper/pick_image.dart';
import 'package:smart_canvas/core/network/supabase/database/add_data.dart';
import 'package:smart_canvas/core/network/supabase/storage/upload_file.dart';
import 'package:smart_canvas/features/administrator/buildings/models/building_model.dart';
import 'package:smart_canvas/features/administrator/rooms/models/room_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
part 'add_room_state.dart';

class AddRoomCubit extends Cubit<AddRoomState> {
  AddRoomCubit() : super(AddRoomInitial()) {
    initialPosition = const CameraPosition(
      target: LatLng(30.0444, 31.2357),
      zoom: 14,
    );
  }

  //-- variables --//
  final formKey = GlobalKey<FormState>();
  final roomNameController = TextEditingController();
  final floorNumberController = TextEditingController();
  Position? position, currentLocation;
  final supabase = getIt<SupabaseClient>();
  bool enableLocation = false;
  File? roomImage;
  String? buildingId;
  String? roomType;
  String? roomSide; 
  List<BuildingModel> buildings = [];
  Set<Marker> markers = {};
  final Completer<GoogleMapController> controller = Completer();
  CameraPosition? initialPosition;
  
  bool isEditMode = false;
  String? roomId;
  String? existingImageUrl;

  //-- functions --//
  init({RoomModel? room}) async {
    await getBuildings();
    if (room != null) {
      isEditMode = true;
      roomId = room.id.toString();
      roomNameController.text = room.name;
      floorNumberController.text = room.floorNumber.toString();
      buildingId = room.buildingModel?.id.toString();
      roomType = room.roomType.name;
      roomSide = room.side; 
      existingImageUrl = room.image;
      
      if (room.mapX != null && room.mapY != null) {
        final latLng = LatLng(room.mapX!, room.mapY!);
        position = Position(
          longitude: room.mapY!,
          latitude: room.mapX!,
          timestamp: DateTime.now(),
          accuracy: 1, altitude: 1, heading: 1, speed: 1, speedAccuracy: 1,
          altitudeAccuracy: 0, headingAccuracy: 0,
        );
        initialPosition = CameraPosition(target: latLng, zoom: 19);
        markers.add(
          Marker(
            markerId: const MarkerId('roomLocation'),
            position: latLng,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          ),
        );
      }
      emit(GetCurrentLocationSuccess());
    } else {
      await moveToCurrentLocation();
    }
  }

  initEdit(RoomModel room) => init(room: room);

  Future<void> getBuildings() async {
    try {
      emit(GetBuildingsLoading());
      final response = await supabase.rpc('get_buildings_with_college_and_years');
      final List list = response as List;
      buildings = list.map((e) => BuildingModel.fromJson(e)).toList();
      emit(GetBuildingsSuccess());
    } catch (e) {
      emit(GetBuildingsError(message: e.toString()));
    }
  }

  addMarker({required LatLng position}) {
    markers.clear();
    this.position = Position(
      latitude: position.latitude, longitude: position.longitude,
      timestamp: DateTime.now(), accuracy: 1, altitude: 1, heading: 1, speed: 1,
      speedAccuracy: 1, altitudeAccuracy: 1, headingAccuracy: 1,
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

  Future<void> moveToCurrentLocation() async {
    try {
      emit(GetCurrentLocationLoading());
      enableLocation = await requestLocationPermission();
      Position? loc;
      if (enableLocation == true) {
        try {
          loc = await LocationHelper.getCurrentLocation();
        } catch (e) {
          debugPrint("Failed to fetch precise location: $e");
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
      debugPrint("Unhandled location error: $e");
      const target = LatLng(30.0444, 31.2357);
      initialPosition = const CameraPosition(target: target, zoom: 16);
      addMarker(position: target);
      emit(GetCurrentLocationSuccess());
    }
  }

  pickRoomImage() async {
    try {
      final image = await pickImage(source: ImageSource.gallery);
      if (image != null) {
        roomImage = image;
        emit(PickImageSuccess());
      }
    } on Exception catch (e) {
      emit(PickImageError(message: e.toString()));
    }
  }

  updateRoom() async {
    if (formKey.currentState!.validate()) {
      if (position == null) { emit(SelectLocation()); return; }
      if (roomImage == null && existingImageUrl == null) { emit(SelectRoomImage()); return; }
      if (buildingId == null) { emit(SelectBuilding()); return; }
      if (roomType == null) { emit(SelectRoomType()); return; }
      try {
        emit(AddRoomLoading());
        dynamic imagePath = existingImageUrl;
        if (roomImage != null) { imagePath = await uploadFileToSupabaseStorage(file: roomImage!, pucketName: "rooms"); }
        await supabase.from("rooms").update({
            "name": roomNameController.text, "building_id": buildingId,
            "room_type": roomType, "floor_number": int.parse(floorNumberController.text),
            "side": roomSide, "image": imagePath,
            "map_x": position!.latitude, "map_y": position!.longitude,
          }).eq('id', roomId!);
        emit(AddRoomSuccess());
      } catch (e) { emit(AddRoomError(message: e.toString())); }
    }
  }

  addRoom() async {
    if (formKey.currentState!.validate()) {
      if (position == null) { emit(SelectLocation()); return; }
      if (roomImage == null) { emit(SelectRoomImage()); return; }
      if (buildingId == null) { emit(SelectBuilding()); return; }
      if (roomType == null) { emit(SelectRoomType()); return; }
      try {
        emit(AddRoomLoading());
        await addData(
          tableName: "rooms",
          data: {
            "name": roomNameController.text, "building_id": buildingId,
            "room_type": roomType, "floor_number": int.parse(floorNumberController.text),
            "side": roomSide, 
            "image": await uploadFileToSupabaseStorage(file: roomImage!, pucketName: "rooms"),
            "map_x": position!.latitude, "map_y": position!.longitude,
            "created_at": DateTime.now().toIso8601String(),
          },
        );
        emit(AddRoomSuccess());
      } catch (e) { emit(AddRoomError(message: e.toString())); }
    }
  }
}
