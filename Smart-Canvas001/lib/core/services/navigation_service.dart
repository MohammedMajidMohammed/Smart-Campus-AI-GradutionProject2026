import 'dart:async';
import 'dart:io';
import 'package:geolocator/geolocator.dart';

class NavigationService {
  StreamSubscription<Position>? _positionStreamSubscription;
  final StreamController<Position> _positionStreamController = StreamController<Position>.broadcast();

  Stream<Position> get positionStream => _positionStreamController.stream;

  Future<bool> checkPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  void startNavigation() {
    late final LocationSettings locationSettings;

    if (Platform.isAndroid) {
      locationSettings = AndroidSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 1, // Update every 1 meter
        intervalDuration: const Duration(seconds: 1), // Update every 1 second
      );
    } else if (Platform.isIOS) {
      locationSettings = AppleSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 1,
        activityType: ActivityType.fitness,
      );
    } else {
      locationSettings = const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 1,
      );
    }

    _positionStreamSubscription = Geolocator.getPositionStream(locationSettings: locationSettings).listen(
      (Position position) {
        _positionStreamController.add(position);
      },
      onError: (e) {
        print("Navigation Error: $e");
      },
    );
  }

  void stopNavigation() {
    _positionStreamSubscription?.cancel();
  }

  // Calculate bearing between two points
  double calculateBearing(double startLat, double startLng, double endLat, double endLng) {
    return Geolocator.bearingBetween(startLat, startLng, endLat, endLng);
  }

  // Calculate distance in meters
  double calculateDistance(double startLat, double startLng, double endLat, double endLng) {
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng);
  }

  // Prepare context string for AI
  String generateContext(Position userPos, String? destName, double? destLat, double? destLng, int? userFloor, int? destFloor) {
    String context = "User Location: [${userPos.latitude}, ${userPos.longitude}].";
    
    if (destName != null && destLat != null && destLng != null) {
      double distance = calculateDistance(userPos.latitude, userPos.longitude, destLat, destLng);
      context += " Destination: $destName ($distance meters away).";
    }

    if (userFloor != null) {
      context += " User Floor: $userFloor.";
    }
    
    if (destFloor != null) {
      context += " Destination Floor: $destFloor.";
    }

    return context;
  }
}
