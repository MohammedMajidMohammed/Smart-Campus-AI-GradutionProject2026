import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:geolocator/geolocator.dart';
import 'package:smart_canvas/core/di/dependancy_injection.dart';
import 'package:smart_canvas/core/services/navigation_service.dart';
import 'package:smart_canvas/core/services/text_to_speech_service.dart';
import 'package:smart_canvas/features/student/navigation/view_models/cubit/navigation_cubit.dart';
import 'package:smart_canvas/features/student/navigation/views/widgets/navigation_overlay.dart';

class NavigationScreen extends StatelessWidget {
  final double destLat;
  final double destLng;
  final String destName;
  final int? destFloor;

  const NavigationScreen({
    super.key,
    required this.destLat,
    required this.destLng,
    required this.destName,
    this.destFloor,
  });

  @override
  Widget build(BuildContext context) {
    final localeCode = EasyLocalization.of(context)?.currentLocale?.languageCode ?? 
        Localizations.localeOf(context).languageCode;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocProvider(
      create: (context) => NavigationCubit(
        navService: getIt<NavigationService>(),
        ttsService: getIt<TextToSpeechService>(),
      )..startNavigation(
          destinationName: destName,
          destLat: destLat,
          destLng: destLng,
          destFloor: destFloor,
          localeCode: localeCode,
        ),
      child: Scaffold(
        body: Builder(
          builder: (context) {
            return Stack(
              children: [
                // Map Layer
                _NavigationMap(
                  destLat: destLat,
                  destLng: destLng,
                  destName: destName,
                  destFloor: destFloor,
                ),
                
                // Text Overlay (Glassmorphic)
                BlocBuilder<NavigationCubit, NavigationState>(
                  builder: (context, state) {
                    return NavigationOverlay(
                      onStop: () {
                        context.read<NavigationCubit>().stopNavigation();
                        Navigator.pop(context);
                      },
                    );
                  },
                ),

                // Back Button (Glassmorphic, styled nicely)
                Positioned(
                  top: 50,
                  left: 16,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isDark 
                              ? const Color(0xFF1E1B15).withValues(alpha: 0.8) 
                              : Colors.white.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
                            width: 1.5,
                          ),
                        ),
                        child: IconButton(
                          icon: Icon(Icons.arrow_back_rounded, color: isDark ? Colors.white : Colors.black87, size: 20),
                          onPressed: () {
                            context.read<NavigationCubit>().stopNavigation();
                            Navigator.pop(context);
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          }
        ),
      ),
    );
  }
}

class _NavigationMap extends StatefulWidget {
  final double destLat;
  final double destLng;
  final String destName;
  final int? destFloor;

  const _NavigationMap({
    required this.destLat,
    required this.destLng,
    required this.destName,
    this.destFloor,
  });

  @override
  State<_NavigationMap> createState() => _NavigationMapState();
}

class _NavigationMapState extends State<_NavigationMap> {
  GoogleMapController? _mapController;
  StreamSubscription<Position>? _positionSubscription;
  Position? _currentPosition;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  bool _is3dMode = true;
  MapType _currentMapType = MapType.normal;

  static const String _lightMapStyle = r'''
[
  {
    "featureType": "all",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#74787c"}]
  },
  {
    "featureType": "all",
    "elementType": "labels.text.stroke",
    "stylers": [{"visibility": "on"}, {"color": "#e6ebed"}]
  },
  {
    "featureType": "building",
    "elementType": "geometry.fill",
    "stylers": [{"color": "#ccd3d6"}]
  },
  {
    "featureType": "building",
    "elementType": "geometry.stroke",
    "stylers": [{"color": "#a8b5ba"}]
  },
  {
    "featureType": "landscape.man_made",
    "elementType": "geometry.fill",
    "stylers": [{"color": "#f7f9fa"}]
  },
  {
    "featureType": "road.local",
    "elementType": "geometry.fill",
    "stylers": [{"color": "#ffffff"}]
  },
  {
    "featureType": "road.local",
    "elementType": "geometry.stroke",
    "stylers": [{"color": "#e1e6e8"}]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry.fill",
    "stylers": [{"color": "#ffeb3b"}, {"lightness": 60}]
  },
  {
    "featureType": "road.arterial",
    "elementType": "geometry.fill",
    "stylers": [{"color": "#ffffff"}]
  },
  {
    "featureType": "poi.park",
    "elementType": "geometry.fill",
    "stylers": [{"color": "#d5ebd3"}]
  },
  {
    "featureType": "water",
    "elementType": "geometry.fill",
    "stylers": [{"color": "#c5e3f5"}]
  }
]
''';

  static const String _darkMapStyle = r'''
[
  {
    "featureType": "all",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#8d949b"}]
  },
  {
    "featureType": "all",
    "elementType": "labels.text.stroke",
    "stylers": [{"visibility": "on"}, {"color": "#1a1c1e"}]
  },
  {
    "featureType": "building",
    "elementType": "geometry.fill",
    "stylers": [{"color": "#2c3035"}]
  },
  {
    "featureType": "building",
    "elementType": "geometry.stroke",
    "stylers": [{"color": "#43484f"}]
  },
  {
    "featureType": "landscape.man_made",
    "elementType": "geometry.fill",
    "stylers": [{"color": "#121315"}]
  },
  {
    "featureType": "road",
    "elementType": "geometry.fill",
    "stylers": [{"color": "#212529"}]
  },
  {
    "featureType": "road",
    "elementType": "geometry.stroke",
    "stylers": [{"color": "#2c3035"}]
  },
  {
    "featureType": "poi.park",
    "elementType": "geometry.fill",
    "stylers": [{"color": "#1a2a1a"}]
  },
  {
    "featureType": "water",
    "elementType": "geometry.fill",
    "stylers": [{"color": "#0d1b2a"}]
  }
]
''';

  @override
  void initState() {
    super.initState();
    _markers.add(
      Marker(
        markerId: const MarkerId('destination'),
        position: LatLng(widget.destLat, widget.destLng),
        infoWindow: InfoWindow(title: 'destination'.tr()),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    );

    // Set up location stream listener for smooth camera transitions
    _positionSubscription = getIt<NavigationService>().positionStream.listen((position) {
      if (!mounted) return;
      setState(() {
        _currentPosition = position;
        _updateRoute();
      });

      if (_mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(position.latitude, position.longitude),
              zoom: 19.0,
              tilt: _is3dMode ? 45.0 : 0.0,
              bearing: position.heading,
            ),
          ),
        );
      }
    });
  }

  void _updateRoute() {
    if (_currentPosition == null) return;
    final userLatLng = LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
    final destLatLng = LatLng(widget.destLat, widget.destLng);

    // Draw glowing neon routing line
    _polylines.clear();
    
    // Outer semi-transparent glow path
    _polylines.add(
      Polyline(
        polylineId: const PolylineId('route_glow'),
        points: [userLatLng, destLatLng],
        color: const Color(0xFF2ECC71).withValues(alpha: 0.25),
        width: 14,
      ),
    );

    // Inner bright dashed path
    _polylines.add(
      Polyline(
        polylineId: const PolylineId('route_core'),
        points: [userLatLng, destLatLng],
        color: const Color(0xFF2ECC71),
        width: 6,
        patterns: [
          PatternItem.dash(20),
          PatternItem.gap(10),
        ],
      ),
    );

    // Update azure user marker
    _markers.removeWhere((m) => m.markerId.value == 'user_location');
    _markers.add(
      Marker(
        markerId: const MarkerId('user_location'),
        position: userLatLng,
        rotation: _currentPosition!.heading,
        flat: true,
        anchor: const Offset(0.5, 0.5),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      ),
    );
  }

  Widget _buildDirectionArrow() {
    if (_currentPosition == null) return const Icon(Icons.navigation, color: Color(0xFF2ECC71), size: 28);
    final bearing = Geolocator.bearingBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      widget.destLat,
      widget.destLng,
    );
    
    double relative = bearing - _currentPosition!.heading;
    double relativeRad = relative * (3.141592653589793 / 180.0);

    return Transform.rotate(
      angle: relativeRad,
      child: const Icon(
        Icons.navigation, 
        color: Color(0xFF2ECC71), 
        size: 32,
      ),
    );
  }

  String _getFloorLabel(int floor, String locale) {
    if (locale == 'ar') {
      if (floor == 0) return 'الدور الأرضي';
      if (floor == 1) return 'الدور الأول';
      if (floor == 2) return 'الدور الثاني';
      if (floor == 3) return 'الدور الثالث';
      if (floor == -1) return 'البدروم';
      return 'الدور $floor';
    } else {
      if (floor == 0) return 'Ground Floor';
      if (floor == 1) return '1st Floor';
      if (floor == 2) return '2nd Floor';
      if (floor == 3) return '3rd Floor';
      if (floor == -1) return 'Basement';
      return 'Floor $floor';
    }
  }

  Widget _buildGPSConsole(bool isDark) {
    if (_currentPosition == null) return const SizedBox.shrink();

    final localeCode = EasyLocalization.of(context)?.currentLocale?.languageCode ?? 'en';

    final distance = Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      widget.destLat,
      widget.destLng,
    );
    
    final distanceStr = distance < 1000
        ? '${distance.toStringAsFixed(0)} m'
        : '${(distance / 1000).toStringAsFixed(1)} km';

    final durationSeconds = distance / 1.4;
    final durationMinutes = (durationSeconds / 60).ceil();
    final durationStr = localeCode == 'ar'
        ? (durationMinutes == 1 ? 'دقيقة واحدة' : '$durationMinutes دقائق')
        : (durationMinutes == 1 ? '1 min' : '$durationMinutes mins');

    return BlocBuilder<NavigationCubit, NavigationState>(
      builder: (context, state) {
        final cubit = context.read<NavigationCubit>();
        final isMuted = cubit.isMuted;

        return ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: isDark 
                    ? const Color(0xFF0F0E0A).withValues(alpha: 0.8) 
                    : Colors.white.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Upper Console Row (Destination Name and Floor Badge)
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.destName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF0F0E0A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (widget.destFloor != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isDark
                                  ? [const Color(0xFF10B981).withValues(alpha: 0.3), const Color(0xFF059669).withValues(alpha: 0.3)]
                                  : [const Color(0xFF10B981).withValues(alpha: 0.15), const Color(0xFF059669).withValues(alpha: 0.15)],
                            ),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFF10B981).withValues(alpha: 0.4),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.layers_outlined, 
                                size: 12, 
                                color: isDark ? const Color(0xFF34D399) : const Color(0xFF059669),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _getFloorLabel(widget.destFloor!, localeCode),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? const Color(0xFF34D399) : const Color(0xFF059669),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 10),
                  Divider(
                    height: 1,
                    color: isDark ? Colors.white12 : Colors.black12,
                  ),
                  const SizedBox(height: 10),
                  // Lower Console Row (Direction Arrow, Walk Stats, Mute Button)
                  Row(
                    children: [
                      // Direction Arrow
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2ECC71).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: _buildDirectionArrow(),
                      ),
                      const SizedBox(width: 16),
                      
                      // Text Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              distanceStr,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: isDark ? Colors.white : const Color(0xFF0F0E0A),
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(
                                  Icons.directions_walk,
                                  size: 14,
                                  color: isDark ? Colors.white54 : Colors.grey.shade600,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  localeCode == 'ar'
                                      ? '$durationStr • سير على الأقدام'
                                      : '$durationStr • Walk',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white54 : Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      // Mute / Unmute Button
                      IconButton(
                        icon: Icon(
                          isMuted ? Icons.volume_off : Icons.volume_up,
                          color: isMuted ? Colors.redAccent : const Color(0xFF2ECC71),
                          size: 24,
                        ),
                        onPressed: () {
                          cubit.toggleMute();
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _recenter() {
    if (_currentPosition != null && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
            zoom: 19.0,
            tilt: _is3dMode ? 45.0 : 0.0,
            bearing: _currentPosition!.heading,
          ),
        ),
      );
    } else if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(widget.destLat, widget.destLng),
            zoom: 18.0,
            tilt: _is3dMode ? 45.0 : 0.0,
          ),
        ),
      );
    }
  }

  void _toggle3dMode() {
    setState(() {
      _is3dMode = !_is3dMode;
    });
    _recenter();
  }

  void _toggleMapType() {
    setState(() {
      _currentMapType = _currentMapType == MapType.normal
          ? MapType.hybrid
          : MapType.normal;
    });
  }

  Widget _buildMapControl({
    required IconData icon,
    required VoidCallback onPressed,
    required bool isDark,
    required String tooltip,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: isDark 
                ? const Color(0xFF1E1B15).withValues(alpha: 0.8) 
                : Colors.white.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.08),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: onPressed,
              child: Center(
                child: Icon(
                  icon,
                  color: isDark ? Colors.white : const Color(0xFF0F0E0A),
                  size: 22,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: LatLng(widget.destLat, widget.destLng), 
            zoom: 19.0,
            tilt: 45.0,
          ),
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          buildingsEnabled: true,
          markers: _markers,
          polylines: _polylines,
          mapType: _currentMapType,
          style: isDark ? _darkMapStyle : _lightMapStyle,
          onMapCreated: (controller) {
            _mapController = controller;
          },
        ),
        
        // Floating Map Controls on the right side
        Positioned(
          right: 16,
          top: 180,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildMapControl(
                icon: Icons.my_location_rounded,
                onPressed: _recenter,
                isDark: isDark,
                tooltip: 'recenter',
              ),
              const SizedBox(height: 12),
              _buildMapControl(
                icon: _is3dMode ? Icons.threed_rotation_rounded : Icons.crop_free_rounded,
                onPressed: _toggle3dMode,
                isDark: isDark,
                tooltip: _is3dMode ? '2D' : '3D',
              ),
              const SizedBox(height: 12),
              _buildMapControl(
                icon: _currentMapType == MapType.hybrid ? Icons.map_outlined : Icons.satellite_alt_outlined,
                onPressed: _toggleMapType,
                isDark: isDark,
                tooltip: 'map_type',
              ),
            ],
          ),
        ),

        // Glassmorphic GPS statistics overlay at the bottom
        if (_currentPosition != null)
          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: _buildGPSConsole(isDark),
          ),
      ],
    );
  }
}
