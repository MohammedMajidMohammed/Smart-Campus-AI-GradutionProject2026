import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:smart_canvas/core/di/dependancy_injection.dart';
import 'package:smart_canvas/features/administrator/buildings/models/building_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'buildings_state.dart';

class BuildingsCubit extends Cubit<BuildingsState> {
  BuildingsCubit() : super(BuildingsInitial()) {
    getBuildings();
  }
  //-- variables --//
  List<BuildingModel> buildings = [];
  List<BuildingModel> filteredBuildings = [];
  String _currentQuery = '';
  final supabase = getIt<SupabaseClient>();

  //-- functions --//
  getBuildings() async {
    try {
      emit(GetBuildingsLoading());
      final response = await supabase.rpc(
        'get_buildings_with_college_and_years',
      );
      
      if (response == null) {
        buildings = [];
        filteredBuildings = [];
        emit(GetBuildingsSuccess());
        return;
      }

      final List buildingsList = response as List;
      
      if (buildingsList.isEmpty) {
        buildings = [];
        filteredBuildings = [];
        emit(GetBuildingsSuccess());
        return;
      }

      buildings = buildingsList.map((e) => BuildingModel.fromJson(e)).toList();
      
      // Explicitly sort by name to prevent reordering on refresh
      buildings.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      
      _applyFilter();
      emit(GetBuildingsSuccess());
    } catch (e) {
      log(e.toString());
      emit(GetBuildingsError(message: e.toString()));
    }
  }

  void _applyFilter() {
    if (_currentQuery.trim().isEmpty) {
      filteredBuildings = buildings;
      return;
    }
    final q = _currentQuery.trim().toLowerCase();
    filteredBuildings = buildings.where((building) {
      final nameMatch = building.name.toLowerCase().contains(q);
      final collegeMatch = (building.collegeModel?.name ?? '').toLowerCase().contains(q);
      final typeMatch = building.buildingType.name.toLowerCase().contains(q);
      return nameMatch || collegeMatch || typeMatch;
    }).toList();
  }

  void searchBuildings(String query) {
    _currentQuery = query;
    _applyFilter();
    emit(GetBuildingsSuccess());
  }
}
