import 'package:geolocator/geolocator.dart';
import 'package:smart_canvas/core/helper/location/location_permission.dart';

Future<Position> getCurrentLocation() async {
  bool serviceEnabled = await requestLocationPermission();
  if (serviceEnabled) {
    // For high accuracy, always fetch a fresh, highly accurate location instead of using stale last known positions
    Position position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        timeLimit: Duration(seconds: 12),
      ),
    );
    return position;
  } else {
    throw Exception('Location services are disabled.');
  }
}
