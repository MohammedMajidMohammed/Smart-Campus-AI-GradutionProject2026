class LocationCache {
  static final LocationCache _instance = LocationCache._internal();
  factory LocationCache() => _instance;
  LocationCache._internal();

  double? lat;
  double? lng;

  void setLocation(double lat, double lng) {
    this.lat = lat;
    this.lng = lng;
  }

  bool get hasLocation => lat != null && lng != null;
}
