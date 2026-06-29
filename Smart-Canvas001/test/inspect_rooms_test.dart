import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smart_canvas/core/constants/app_constants.dart';

void main() {
  test('inspect rooms and buildings', () async {
    final supabase = SupabaseClient(
      AppConstants.supabaseUrl,
      AppConstants.supabaseAnonKey,
    );
    
    try {
      final response = await supabase.from('rooms').select('*, buildings(*)');
      print('--- ROOMS IN DATABASE ---');
      for (var row in response) {
        final roomName = row['name'];
        final buildingId = row['building_id'];
        final buildingName = row['buildings']?['name'];
        final floorNumber = row['floor_number'];
        final side = row['side'];
        print('Room: $roomName, Floor: $floorNumber, Side: $side, BuildingID: $buildingId, BuildingName: $buildingName');
      }
    } catch (e) {
      print('Rooms query error: $e');
    }
  });
}
