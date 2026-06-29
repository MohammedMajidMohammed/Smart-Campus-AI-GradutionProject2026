import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:smart_canvas/core/di/dependancy_injection.dart';
import 'package:smart_canvas/features/administrator/rooms/models/room_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
part 'rooms_state.dart';

class RoomsCubit extends Cubit<RoomsState> {
  final String? initialBuildingId;

  RoomsCubit({this.initialBuildingId}) : super(RoomsInitial()) {
    _subscribeToRooms();
  }

  //-- variables --//
  List<RoomModel> rooms = [];
  List<RoomModel> filteredRooms = [];

  /// Persists the active search query across refreshes and realtime updates.
  String _currentQuery = '';

  final supabase = getIt<SupabaseClient>();

  // Stream Subscription
  // ignore: cancel_subscriptions
  late final RealtimeChannel _roomsChannel;

  @override
  Future<void> close() {
    supabase.removeChannel(_roomsChannel);
    return super.close();
  }

  //-- functions --//

  // 1. Subscribe to Realtime Updates
  void _subscribeToRooms() {
    getRooms(); // Initial fetch

    _roomsChannel = supabase.channel('public:rooms')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'rooms',
          callback: (payload) {
            getRooms(); // Re-fetch but search is preserved
          },
        )
        .subscribe();
  }

  getRooms() async {
    try {
      if (rooms.isEmpty) emit(GetRoomsLoading());
      final response = await supabase.rpc('get_rooms_with_building');

      if (response == null) {
        rooms = [];
        filteredRooms = [];
        emit(GetRoomsSuccess());
        return;
      }

      final List roomsList = response as List;
      rooms = roomsList.map((e) => RoomModel.fromJson(e)).toList();

      // Sort rooms: floor number ascending (floor 0 at the top, then 1, 2, 3...)
      rooms.sort((a, b) {
        int floorCompare = a.floorNumber.compareTo(b.floorNumber);
        if (floorCompare != 0) return floorCompare;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });

      // Re-apply the active search/filter after every fetch
      _applyFilter();

      emit(GetRoomsSuccess());
    } catch (e) {
      log("Error fetching rooms: $e");
      emit(GetRoomsFailure(message: e.toString()));
    }
  }

  /// Core filter logic — always called after any data change.
  void _applyFilter() {
    // Start with the building-scoped base list
    List<RoomModel> baseList = initialBuildingId != null
        ? rooms.where((r) => r.buildingModel?.id.toString() == initialBuildingId).toList()
        : rooms;

    if (_currentQuery.trim().isEmpty) {
      filteredRooms = baseList;
      return;
    }

    final q = _currentQuery.trim().toLowerCase();
    filteredRooms = baseList.where((room) {
      final nameMatch    = room.name.toLowerCase().contains(q);
      final buildingName = (room.buildingModel?.name ?? '').toLowerCase();
      final buildingMatch = buildingName.contains(q);
      final typeMatch    = room.roomType.name.toLowerCase().contains(q);
      final floorMatch   = 'floor ${room.floorNumber}'.contains(q) ||
                           room.floorNumber.toString() == q;
      return nameMatch || buildingMatch || typeMatch || floorMatch;
    }).toList();
  }

  void searchRooms(String query) {
    _currentQuery = query; // Persist for refresh
    _applyFilter();
    emit(GetRoomsSuccess());
  }

  void filterByBuilding(String buildingId) {
    filteredRooms = rooms
        .where((room) => room.buildingModel?.id.toString() == buildingId)
        .toList();
    emit(GetRoomsSuccess());
  }

  Future<void> deleteRoom(String roomId) async {
    try {
      emit(DeleteRoomLoading());
      await supabase.from('rooms').delete().eq('id', roomId);
      // Remove from local lists immediately for instant UI feedback
      rooms.removeWhere((r) => r.id.toString() == roomId);
      filteredRooms.removeWhere((r) => r.id.toString() == roomId);
      emit(DeleteRoomSuccess());
      emit(GetRoomsSuccess());
    } catch (e) {
      log('Error deleting room: $e');
      emit(DeleteRoomFailure(message: e.toString()));
    }
  }
}
