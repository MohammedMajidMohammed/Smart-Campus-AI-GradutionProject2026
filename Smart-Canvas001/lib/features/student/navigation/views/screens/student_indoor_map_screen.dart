import 'dart:collection';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:smart_canvas/core/utilies/colors/app_colors.dart';
import 'package:smart_canvas/features/administrator/rooms/models/room_model.dart';
import 'package:smart_canvas/features/administrator/rooms/view_models/cubit/rooms_cubit.dart';
import 'package:smart_canvas/features/administrator/buildings/models/building_model.dart';
import 'package:smart_canvas/core/di/dependancy_injection.dart';
import 'package:smart_canvas/core/services/text_to_speech_service.dart';

class StudentIndoorMapScreen extends StatelessWidget {
  final BuildingModel building;
  const StudentIndoorMapScreen({super.key, required this.building});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => RoomsCubit(initialBuildingId: building.id.toString()),
      child: _StudentIndoorMapScreenContent(building: building),
    );
  }
}

class _StudentIndoorMapScreenContent extends StatefulWidget {
  final BuildingModel building;
  const _StudentIndoorMapScreenContent({required this.building});

  @override
  State<_StudentIndoorMapScreenContent> createState() => _StudentIndoorMapScreenContentState();
}

class _StudentIndoorMapScreenContentState extends State<_StudentIndoorMapScreenContent> {
  RoomModel? _startRoom;
  RoomModel? _destRoom;
  RoomModel? _focusedRoom; // Selected room tapped on map or searched
  int _selectedFloor = 0;
  List<RoomModel> _buildingRooms = [];
  List<int> _availableFloors = [0];

  List<String> _pathSteps = []; // List of room/node IDs representing the path
  String? _navigationInstruction;

  final TextEditingController _searchController = TextEditingController();
  List<RoomModel> _searchResults = [];
  
  final TransformationController _transformationController = TransformationController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RoomsCubit>().getRooms();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  void _zoom(double factor) {
    final Matrix4 matrix = _transformationController.value.clone();
    final double currentScale = matrix.getMaxScaleOnAxis();
    final double targetScale = (currentScale * factor).clamp(0.5, 8.0);
    final double scaleChange = targetScale / currentScale;
    
    // Scale matrix relative to the center of the canvas coordinates
    matrix.scaleByDouble(scaleChange, scaleChange, 1.0, 1.0);
    
    setState(() {
      _transformationController.value = matrix;
    });
  }

  void _resetZoom() {
    setState(() {
      _transformationController.value = Matrix4.identity();
    });
  }

  Widget _buildZoomButton({required IconData icon, required VoidCallback onPressed, required bool isDark}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 36,
          height: 36,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.kPrimaryColor, size: 20),
        ),
      ),
    );
  }

  void _setupRooms(List<RoomModel> allRooms) {
    // 1. Filter rooms by the current building ID
    var filtered = allRooms
        .where((r) => r.buildingModel?.id == widget.building.id)
        .toList();

    // 2. Extra safety prefix check: Filter out rooms that don't match the building letter name prefix 
    // to prevent database misassociation (e.g. room A3Clab1 having Building B's ID)
    final bName = widget.building.name.trim().toLowerCase();
    String? currentBuildingLetter;
    if (bName.contains('building a') || bName == 'a') {
      currentBuildingLetter = 'a';
    } else if (bName.contains('building b') || bName == 'b') {
      currentBuildingLetter = 'b';
    } else if (bName.contains('building c') || bName == 'c') {
      currentBuildingLetter = 'c';
    } else if (bName.contains('building d') || bName == 'd') {
      currentBuildingLetter = 'd';
    }
    
    if (currentBuildingLetter != null) {
      final allLetters = {'a', 'b', 'c', 'd'};
      final foreignLetters = allLetters.difference({currentBuildingLetter});
      final regexPattern = '^([${foreignLetters.join()}])\\d';
      final regex = RegExp(regexPattern, caseSensitive: false);
      
      filtered = filtered.where((r) {
        return !regex.hasMatch(r.name.trim());
      }).toList();
    }
    
    // 3. Deduplicate rooms with identical normalized names on the same floor
    final Set<String> uniqueKeys = {};
    final List<RoomModel> deduplicated = [];
    for (final r in filtered) {
      final normName = r.name.toLowerCase().replaceAll(RegExp(r'\s+|_|-'), '');
      final key = '${r.floorNumber}_$normName';
      if (!uniqueKeys.contains(key)) {
        uniqueKeys.add(key);
        deduplicated.add(r);
      }
    }
    filtered = deduplicated;
    
    if (filtered.isNotEmpty && _buildingRooms.isEmpty) {
      // Get unique floors sorted
      final floors = filtered.map((r) => r.floorNumber).toSet().toList()..sort();
      setState(() {
        _buildingRooms = filtered;
        _availableFloors = floors;
        if (!_availableFloors.contains(_selectedFloor)) {
          _selectedFloor = _availableFloors.first;
        }
      });
    }
  }

  // Generate coordinates for rooms dynamically (ignores invalid GPS coords)
  Map<String, Offset> _generateRoomCoords(List<RoomModel> floorRooms) {
    final Map<String, Offset> coords = {};
    
    // Sort floorRooms to ensure alphabetical stability
    final sortedRooms = List<RoomModel>.from(floorRooms)..sort((a, b) => a.name.compareTo(b.name));

    // Lists for categorization
    final List<RoomModel> halls = [];
    final List<RoomModel> leftRestrooms = [];
    final List<RoomModel> rightRestrooms = [];
    final List<RoomModel> leftClassroomsInner = [];
    final List<RoomModel> rightClassroomsInner = [];
    final List<RoomModel> leftOuterRooms = [];
    final List<RoomModel> rightOuterRooms = [];
    
    RoomModel? clab1Room;
    RoomModel? leftLabBottom;
    RoomModel? rightLabBottom;

    for (final room in sortedRooms) {
      final nameLower = room.name.toLowerCase().replaceAll(RegExp(r'\s+|_|-'), '');
      
      // 1. Halls
      if (room.roomType == RoomType.hall || nameLower.contains('hall') || nameLower.contains('lh')) {
        halls.add(room);
        continue;
      }
      
      // 2. Clab1 / Lab1 (Center top of inner block)
      if (nameLower.contains('clab1') || nameLower.contains('lab1') || (room.roomType == RoomType.lab && room.side?.toLowerCase() == 'center')) {
        if (clab1Room == null) {
          clab1Room = room;
          continue;
        }
      }
      
      final side = room.side?.toLowerCase() ?? '';
      
      final bool isLeft;
      if (side == 'left') {
        isLeft = true;
      } else if (side == 'right') {
        isLeft = false;
      } else {
        isLeft = room.id.hashCode % 2 == 0;
      }

      final isRestroom = room.roomType == RoomType.mensBathroom ||
                         room.roomType == RoomType.womensBathroom ||
                         nameLower.contains('toilet') ||
                         nameLower.contains('wc') ||
                         nameLower.contains('bathroom') ||
                         nameLower.contains('restroom');

      if (isLeft) {
        if (isRestroom) {
          leftRestrooms.add(room);
        } else {
          final isLab = room.roomType == RoomType.lab;
          if (isLab && leftLabBottom == null) {
            leftLabBottom = room;
          } else if (room.roomType == RoomType.classRoom && leftClassroomsInner.isEmpty) {
            leftClassroomsInner.add(room);
          } else {
            leftOuterRooms.add(room);
          }
        }
      } else {
        if (isRestroom) {
          rightRestrooms.add(room);
        } else {
          final isLab = room.roomType == RoomType.lab;
          if (isLab && rightLabBottom == null) {
            rightLabBottom = room;
          } else if (room.roomType == RoomType.classRoom && rightClassroomsInner.isEmpty) {
            rightClassroomsInner.add(room);
          } else {
            rightOuterRooms.add(room);
          }
        }
      }
    }

    // Now assign coordinates based on the hand-drawn sketch layout!
    
    // 1. Halls (Top outer wall, above corridor)
    if (halls.isNotEmpty) coords[halls[0].id] = const Offset(0.12, 0.12);
    if (halls.length >= 2) coords[halls[1].id] = const Offset(0.88, 0.12);
    if (halls.length >= 3) {
      for (int i = 2; i < halls.length; i++) {
        coords[halls[i].id] = Offset(0.30 + i * 0.10, 0.12);
      }
    }

    // 2. clab 1 (Center top of inner block)
    if (clab1Room != null) {
      coords[clab1Room.id] = const Offset(0.50, 0.32);
    }

    // 3. Left Wing Outer Wall (X = 0.12)
    // Restrooms first at the top
    for (int i = 0; i < leftRestrooms.length; i++) {
      coords[leftRestrooms[i].id] = Offset(0.12, 0.30 + i * 0.11);
    }
    // Outer rooms below restrooms
    for (int i = 0; i < leftOuterRooms.length; i++) {
      coords[leftOuterRooms[i].id] = Offset(0.12, 0.30 + (leftRestrooms.length + i) * 0.11);
    }

    // 4. Right Wing Outer Wall (X = 0.88)
    // Restrooms first at the top
    for (int i = 0; i < rightRestrooms.length; i++) {
      coords[rightRestrooms[i].id] = Offset(0.88, 0.30 + i * 0.11);
    }
    // Outer rooms below restrooms
    for (int i = 0; i < rightOuterRooms.length; i++) {
      coords[rightOuterRooms[i].id] = Offset(0.88, 0.30 + (rightRestrooms.length + i) * 0.11);
    }

    // 5. Left/Right Inner Courtyard Walls (facing vertical corridors)
    for (final rm in leftClassroomsInner) {
      coords[rm.id] = const Offset(0.32, 0.55);
    }
    for (final rm in rightClassroomsInner) {
      coords[rm.id] = const Offset(0.68, 0.55);
    }

    // 6. Bottom labs (X = 0.22, Y = 0.92 and X = 0.78, Y = 0.92)
    if (leftLabBottom != null) {
      coords[leftLabBottom.id] = const Offset(0.22, 0.92);
    }
    if (rightLabBottom != null) {
      coords[rightLabBottom.id] = const Offset(0.78, 0.92);
    }

    // Hardcoded Stairs & Elevators
    coords['L_STAIRS'] = const Offset(0.32, 0.32);         // Inner Left Stairs
    coords['R_STAIRS'] = const Offset(0.68, 0.32);         // Inner Right Stairs
    coords['L_ELEVATOR'] = const Offset(0.41, 0.32);       // Inner Left Elevator
    coords['R_ELEVATOR'] = const Offset(0.59, 0.32);       // Inner Right Elevator
    
    // Fixed sequential placement for outer elevators and stairs below rooms to prevent overlaps and keep layout stable
    coords['L_ELEVATOR_OUTER'] = const Offset(0.12, 0.63);
    coords['L_STAIRS_OUTER'] = const Offset(0.12, 0.74);
    coords['R_ELEVATOR_OUTER'] = const Offset(0.88, 0.63);
    coords['R_STAIRS_OUTER'] = const Offset(0.88, 0.74);

    return coords;
  }

  // Build a local navigation graph for pathfinding on a single floor
  Map<String, List<String>> _buildLocalGraph(List<RoomModel> floorRooms, Map<String, Offset> coords) {
    final Map<String, List<String>> graph = {};
    
    // Create U-shaped corridor nodes
    final List<String> allCorridorNodes = [];
    
    // 1. Left Wing Corridor (vertical, x = 0.22, y running downwards from 0.85 to 0.25)
    for (int i = 1; i <= 5; i++) {
      final nodeId = 'L_CORR_$i';
      allCorridorNodes.add(nodeId);
      coords[nodeId] = Offset(0.22, 0.85 - (i - 1) * 0.15);
    }

    // 2. Right Wing Corridor (vertical, x = 0.78, y running downwards from 0.85 to 0.25)
    for (int i = 1; i <= 5; i++) {
      final nodeId = 'R_CORR_$i';
      allCorridorNodes.add(nodeId);
      coords[nodeId] = Offset(0.78, 0.85 - (i - 1) * 0.15);
    }

    // 3. Top Connector Corridor (horizontal, y = 0.22, x = 0.22 to 0.78)
    for (int i = 1; i <= 5; i++) {
      final nodeId = 'B_CORR_$i';
      allCorridorNodes.add(nodeId);
      coords[nodeId] = Offset(0.22 + (i - 1) * 0.14, 0.22);
    }

    // Connect Left Corridor nodes chain
    for (int i = 1; i < 5; i++) {
      final n1 = 'L_CORR_$i';
      final n2 = 'L_CORR_${i + 1}';
      graph.putIfAbsent(n1, () => []).add(n2);
      graph.putIfAbsent(n2, () => []).add(n1);
    }

    // Connect Right Corridor nodes chain
    for (int i = 1; i < 5; i++) {
      final n1 = 'R_CORR_$i';
      final n2 = 'R_CORR_${i + 1}';
      graph.putIfAbsent(n1, () => []).add(n2);
      graph.putIfAbsent(n2, () => []).add(n1);
    }

    // Connect Bottom Corridor nodes chain
    for (int i = 1; i < 5; i++) {
      final n1 = 'B_CORR_$i';
      final n2 = 'B_CORR_${i + 1}';
      graph.putIfAbsent(n1, () => []).add(n2);
      graph.putIfAbsent(n2, () => []).add(n1);
    }

    // Connect Corners
    // L_CORR_5 connects to B_CORR_1
    graph.putIfAbsent('L_CORR_5', () => []).add('B_CORR_1');
    graph.putIfAbsent('B_CORR_1', () => []).add('L_CORR_5');

    // R_CORR_5 connects to B_CORR_5
    graph.putIfAbsent('R_CORR_5', () => []).add('B_CORR_5');
    graph.putIfAbsent('B_CORR_5', () => []).add('R_CORR_5');

    final List<String> specialNodes = [
      'L_STAIRS', 'R_STAIRS', 'L_ELEVATOR', 'R_ELEVATOR',
      'L_STAIRS_OUTER', 'R_STAIRS_OUTER', 'L_ELEVATOR_OUTER', 'R_ELEVATOR_OUTER'
    ];
    for (final node in specialNodes) {
      final nodePt = coords[node];
      if (nodePt != null) {
        String closestCorr = 'L_CORR_1';
        double minDist = 999999.0;
        for (final corrNode in allCorridorNodes) {
          final corrPt = coords[corrNode];
          if (corrPt != null) {
            final dist = (nodePt.dx - corrPt.dx) * (nodePt.dx - corrPt.dx) + (nodePt.dy - corrPt.dy) * (nodePt.dy - corrPt.dy);
            if (dist < minDist) {
              minDist = dist;
              closestCorr = corrNode;
            }
          }
        }
        graph.putIfAbsent(node, () => []).add(closestCorr);
        graph.putIfAbsent(closestCorr, () => []).add(node);
      }
    }

    // Connect each room to its closest corridor node
    for (final room in floorRooms) {
      final roomPt = coords[room.id];
      if (roomPt == null) continue;

      String closestCorridor = 'B_CORR_3';
      double minD = 999999.0;
      for (final node in allCorridorNodes) {
        final nodePt = coords[node];
        if (nodePt != null) {
          final dist = (roomPt.dx - nodePt.dx) * (roomPt.dx - nodePt.dx) + (roomPt.dy - nodePt.dy) * (roomPt.dy - nodePt.dy);
          if (dist < minD) {
            minD = dist;
            closestCorridor = node;
          }
        }
      }

      graph.putIfAbsent(room.id, () => []).add(closestCorridor);
      graph.putIfAbsent(closestCorridor, () => []).add(room.id);
    }

    return graph;
  }

  // BFS Pathfinding Algorithm
  List<String>? _bfs(String startId, String destId, Map<String, List<String>> graph) {
    if (startId == destId) return [startId];
    if (!graph.containsKey(startId) || !graph.containsKey(destId)) return null;

    final queue = Queue<List<String>>();
    final visited = <String>{startId};
    queue.add([startId]);

    while (queue.isNotEmpty) {
      final path = queue.removeFirst();
      final node = path.last;
      final neighbors = graph[node] ?? [];

      for (final neighbor in neighbors) {
        if (visited.contains(neighbor)) continue;
        final newPath = [...path, neighbor];
        if (neighbor == destId) return newPath;
        visited.add(neighbor);
        queue.add(newPath);
      }
    }
    return null;
  }

  void _calculatePath() {
    if (_startRoom == null || _destRoom == null) {
      setState(() {
        _pathSteps = [];
        _navigationInstruction = null;
      });
      return;
    }

    final isArabic = context.locale.languageCode == 'ar';

    // 1. Same Floor Pathfinding
    if (_startRoom!.floorNumber == _destRoom!.floorNumber) {
      final floorRooms = _buildingRooms.where((r) => r.floorNumber == _startRoom!.floorNumber).toList();
      final coords = _generateRoomCoords(floorRooms);
      final graph = _buildLocalGraph(floorRooms, coords);

      final path = _bfs(_startRoom!.id, _destRoom!.id, graph);
      setState(() {
        _selectedFloor = _startRoom!.floorNumber;
        if (path != null) {
          _pathSteps = path;
          _navigationInstruction = isArabic
              ? "امشِ في الممر للوصول إلى ${_destRoom!.name}"
              : "Walk along the corridor to reach ${_destRoom!.name}";
        } else {
          _pathSteps = [];
          _navigationInstruction = isArabic
              ? "تعذر حساب المسار."
              : "Could not calculate path.";
        }
      });
    } 
    // 2. Different Floor Pathfinding (uses Stairs transition)
    else {
      setState(() {
        _selectedFloor = _startRoom!.floorNumber;
        
        final startFloorRooms = _buildingRooms.where((r) => r.floorNumber == _startRoom!.floorNumber).toList();
        final startCoords = _generateRoomCoords(startFloorRooms);
        final startGraph = _buildLocalGraph(startFloorRooms, startCoords);
        
        // Find closest stairs on the start floor
        final startPt = startCoords[_startRoom!.id];
        String chosenStairs = 'L_STAIRS';
        if (startPt != null) {
          final stairsList = ['L_STAIRS', 'R_STAIRS', 'L_STAIRS_OUTER', 'R_STAIRS_OUTER'];
          double minDist = 999999.0;
          for (final stairsKey in stairsList) {
            final stairsPt = startCoords[stairsKey];
            if (stairsPt != null) {
              final dist = (startPt.dx - stairsPt.dx) * (startPt.dx - stairsPt.dx) + (startPt.dy - stairsPt.dy) * (startPt.dy - stairsPt.dy);
              if (dist < minDist) {
                minDist = dist;
                chosenStairs = stairsKey;
              }
            }
          }
        }

        final pathToStairs = _bfs(_startRoom!.id, chosenStairs, startGraph);

        if (pathToStairs != null) {
          _pathSteps = pathToStairs;
          _navigationInstruction = isArabic
              ? "اذهب إلى السلالم للصعود/النزول إلى الطابق ${_destRoom!.floorNumber}"
              : "Go to Stairs to change to Floor ${_destRoom!.floorNumber}";
        } else {
          _pathSteps = [];
          _navigationInstruction = isArabic
              ? "تعذر العثور على مسار للسلالم."
              : "Could not find path to stairs.";
        }
      });
    }

    if (_navigationInstruction != null) {
      _speakCurrentInstruction(isArabic);
    }
  }

  void _onRoomTapped(RoomModel room) {
    setState(() {
      _focusedRoom = room;
    });
  }

  void _onSearchSelect(RoomModel room) {
    setState(() {
      _selectedFloor = room.floorNumber;
      _focusedRoom = room;
      _searchController.clear();
      _searchResults = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = context.locale.languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.kBackgroundColorDark : AppColors.kBackgroundColorLight,
      appBar: AppBar(
        title: Text(
          isArabic ? "الملاحة الداخلية" : "Indoor Navigation",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 0.5),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.primaryGradient,
          ),
        ),
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 3,
        shadowColor: AppColors.kPrimaryColor.withValues(alpha: 0.3),
      ),
      body: BlocConsumer<RoomsCubit, RoomsState>(
        listener: (context, state) {
          if (state is GetRoomsSuccess) {
            _setupRooms(context.read<RoomsCubit>().rooms);
          }
        },
        builder: (context, state) {
          if (state is GetRoomsLoading && _buildingRooms.isEmpty) {
            return const Center(child: CircularProgressIndicator(color: AppColors.kPrimaryColor));
          }

          // Fallback to fetch rooms if loaded but setup hasn't run
          final cubitRooms = context.read<RoomsCubit>().rooms;
          if (cubitRooms.isNotEmpty && _buildingRooms.isEmpty) {
            _setupRooms(cubitRooms);
          }

          if (_buildingRooms.isEmpty) {
            return Center(
              child: Text(
                isArabic ? "لا توجد قاعات مسجلة لهذا المبنى." : "No rooms registered for this building.",
                style: const TextStyle(fontSize: 16),
              ),
            );
          }

          final rawFloorRooms = _buildingRooms.where((r) => r.floorNumber == _selectedFloor).toList();
          final Set<String> seenNames = {};
          final List<RoomModel> floorRooms = [];
          for (final r in rawFloorRooms) {
            final normName = r.name.toLowerCase().replaceAll(RegExp(r'\s+|_|-'), '');
            if (!seenNames.contains(normName)) {
              seenNames.add(normName);
              floorRooms.add(r);
            }
          }
          final coords = _generateRoomCoords(floorRooms);
          final graph = _buildLocalGraph(floorRooms, coords);

          return Stack(
            children: [
              // Map View + Panel selectors
              Column(
                children: [
                  // 1. Modern Floating Search & Route Selector
                  _buildTopSearchAndSelectors(isArabic, isDark),

                  // 2. Navigation Instruction Box
                  if (_navigationInstruction != null) _buildInstructionCard(isDark, isArabic),

                  // 3. Floor Selector (Tabs)
                  _buildFloorSelector(isArabic, isDark),

                  // 4. Interactive Blueprint Map View
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 90),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0B0F19) : Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: isDark ? const Color(0xFF1E293B) : Colors.grey[200]!,
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.05),
                              blurRadius: 25,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(26),
                          child: Stack(
                            children: [
                              // Interactive map canvas
                              InteractiveViewer(
                                transformationController: _transformationController,
                                maxScale: 8.0,
                                minScale: 0.5,
                                boundaryMargin: const EdgeInsets.all(120),
                                key: ValueKey('$_selectedFloor-${_pathSteps.join("-")}-$isDark-${_focusedRoom?.id}'),
                                child: Center(
                                  child: LayoutBuilder(
                                    builder: (context, constraints) {
                                      final W = constraints.maxWidth;
                                      final H = constraints.maxHeight;
                                      final wScaled = W - 100.0;
                                      final hScaled = H - 100.0;
                                      
                                      double scaleX(double x) => 50.0 + x * wScaled;
                                      double scaleY(double y) => 50.0 + y * hScaled;
                                      
                                      return Container(
                                        width: W,
                                        height: H,
                                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                        child: GestureDetector(
                                          onTapUp: (details) {
                                            final localOffset = details.localPosition;
                                            RoomModel? tappedRoom;
                                            
                                            for (final room in floorRooms) {
                                              final center = coords[room.id];
                                              if (center == null) continue;
                                              
                                              final rx = scaleX(center.dx);
                                              final ry = scaleY(center.dy);
                                              
                                              final isHorizontalWing = center.dy < 0.35;
                                              final roomW = isHorizontalWing ? (0.08 * wScaled) : (0.06 * wScaled);
                                              final roomH = isHorizontalWing ? (0.065 * hScaled) : (0.065 * hScaled);
                                              
                                              final rect = Rect.fromCenter(
                                                center: Offset(rx, ry),
                                                width: roomW,
                                                height: roomH,
                                              );
                                              
                                              if (rect.contains(localOffset)) {
                                                tappedRoom = room;
                                                break;
                                              }
                                            }

                                            if (tappedRoom != null) {
                                              _onRoomTapped(tappedRoom);
                                            } else {
                                              setState(() {
                                                _focusedRoom = null;
                                              });
                                            }
                                          },
                                          child: CustomPaint(
                                            size: Size(W, H),
                                            painter: IndoorMapPainter(
                                              rooms: floorRooms,
                                              coords: coords,
                                              graph: graph,
                                              path: _pathSteps,
                                              selectedFloor: _selectedFloor,
                                              isDark: isDark,
                                              isArabic: isArabic,
                                              focusedRoom: _focusedRoom,
                                              startRoom: _startRoom,
                                              destRoom: _destRoom,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              // Floating Zoom Controls
                              Positioned(
                                top: 12,
                                right: isArabic ? null : 12,
                                left: isArabic ? 12 : null,
                                child: Column(
                                  children: [
                                    _buildZoomButton(
                                      icon: Icons.add_rounded,
                                      onPressed: () => _zoom(1.4),
                                      isDark: isDark,
                                    ),
                                    const SizedBox(height: 8),
                                    _buildZoomButton(
                                      icon: Icons.remove_rounded,
                                      onPressed: () => _zoom(0.7),
                                      isDark: isDark,
                                    ),
                                    const SizedBox(height: 8),
                                    _buildZoomButton(
                                      icon: Icons.restart_alt_rounded,
                                      onPressed: _resetZoom,
                                      isDark: isDark,
                                    ),
                                  ],
                                ),
                              ),
                              // Floating Map Legend
                              Positioned(
                                bottom: 12,
                                left: isArabic ? null : 12,
                                right: isArabic ? 12 : null,
                                child: _buildLegendCard(isDark, isArabic),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // 5. Sliding Room Details bottom sheet
              if (_focusedRoom != null)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: _buildFocusedRoomSheet(isArabic, isDark),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTopSearchAndSelectors(bool isArabic, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Search Bar
          TextFormField(
            controller: _searchController,
            style: TextStyle(color: isDark ? Colors.white : Colors.black87),
            decoration: InputDecoration(
              hintText: isArabic ? "ابحث عن قاعة (مثال: B1Lab4)..." : "Search for a room (e.g. B1Lab4)...",
              hintStyle: TextStyle(color: isDark ? Colors.white60 : Colors.black45),
              prefixIcon: const Icon(Icons.search_rounded, color: AppColors.kPrimaryColor),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, color: Colors.grey),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchResults = [];
                        });
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              filled: true,
              fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: const BorderSide(color: AppColors.kPrimaryColor, width: 2.0),
              ),
            ),
            onChanged: (val) {
              if (val.trim().isEmpty) {
                setState(() {
                  _searchResults = [];
                });
                return;
              }
              setState(() {
                _searchResults = _buildingRooms
                    .where((r) => r.name.toLowerCase().contains(val.toLowerCase().trim()))
                    .toList();
              });
            },
          ),
          
          // Search Results Dropdown List
          if (_searchResults.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 8),
              constraints: const BoxConstraints(maxHeight: 180),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? Colors.white12 : Colors.grey[300]!),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: _searchResults.length,
                separatorBuilder: (c, i) => Divider(height: 1, color: isDark ? Colors.white10 : Colors.grey[200]),
                itemBuilder: (context, index) {
                  final room = _searchResults[index];
                  IconData icon;
                  switch (room.roomType) {
                    case RoomType.lab: icon = Icons.computer; break;
                    case RoomType.classRoom: icon = Icons.school; break;
                    case RoomType.mensBathroom:
                    case RoomType.womensBathroom: icon = Icons.wc; break;
                    case RoomType.office:
                    case RoomType.teacherAssistantOffice: icon = Icons.work; break;
                    case RoomType.cafeteria: icon = Icons.local_cafe; break;
                    case RoomType.hall: icon = Icons.meeting_room; break;
                    case RoomType.mensPrayerRoom:
                    case RoomType.womensPrayerRoom: icon = Icons.place; break;
                  }
                  return ListTile(
                    leading: Icon(icon, color: AppColors.kPrimaryColor, size: 20),
                    title: Text(room.name, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      isArabic 
                        ? "الطابق ${room.floorNumber == 0 ? 'الأرضي' : room.floorNumber} • ${room.side == 'left' ? 'الجانب الأيسر' : room.side == 'right' ? 'الجانب الأيمن' : 'الوسط'}"
                        : "Floor ${room.floorNumber == 0 ? 'G' : room.floorNumber} • ${room.side ?? 'Center'}",
                      style: TextStyle(color: isDark ? Colors.white60 : Colors.black54, fontSize: 12),
                    ),
                    onTap: () => _onSearchSelect(room),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _speakCurrentInstruction(bool isArabic) async {
    if (_navigationInstruction == null) return;
    try {
      final tts = getIt<TextToSpeechService>();
      await tts.setLanguage(isArabic ? 'ar' : 'en-US');
      await tts.speak(_navigationInstruction!);
    } catch (e) {
      debugPrint("Error speaking TTS: $e");
    }
  }

  Widget _buildInstructionCard(bool isDark, bool isArabic) {
    final showFloorChange = _destRoom != null && _selectedFloor != _destRoom!.floorNumber;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.kPrimaryColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.kPrimaryColor.withValues(alpha: 0.25), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.kPrimaryColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.navigation_rounded, color: AppColors.kPrimaryColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isArabic ? "توجيهات المسار" : "Route Instructions",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _navigationInstruction!,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: isDark ? Colors.green[200] : AppColors.kSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, thickness: 0.5, color: Colors.black12),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Speaker button (Voice Guidance)
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.kPrimaryColor.withValues(alpha: 0.1),
                  padding: const EdgeInsets.all(8),
                ),
                icon: const Icon(Icons.volume_up_rounded, color: AppColors.kPrimaryColor, size: 20),
                onPressed: () => _speakCurrentInstruction(isArabic),
                tooltip: isArabic ? "استماع للتوجيهات" : "Listen to directions",
              ),
              const SizedBox(width: 8),
              if (showFloorChange) ...[
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.kPrimaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  icon: Icon(
                    _selectedFloor < _destRoom!.floorNumber ? Icons.arrow_upward : Icons.arrow_downward, 
                    size: 16,
                  ),
                  label: Text(
                    isArabic 
                      ? "انتقل للدور ${_destRoom!.floorNumber}" 
                      : "Go to Floor ${_destRoom!.floorNumber}",
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    setState(() {
                      _selectedFloor = _destRoom!.floorNumber;
                      // Calculate path on destination floor from STAIRS to room
                      final destFloorRooms = _buildingRooms.where((r) => r.floorNumber == _destRoom!.floorNumber).toList();
                      final destCoords = _generateRoomCoords(destFloorRooms);
                      final destGraph = _buildLocalGraph(destFloorRooms, destCoords);
                      
                      // Use same stairs that start floor path ended with, or closest to dest
                      String chosenStairs = 'L_STAIRS';
                      final allStairs = {'L_STAIRS', 'R_STAIRS', 'L_STAIRS_OUTER', 'R_STAIRS_OUTER'};
                      if (_pathSteps.isNotEmpty && allStairs.contains(_pathSteps.last)) {
                        chosenStairs = _pathSteps.last;
                      } else {
                        final destPt = destCoords[_destRoom!.id];
                        if (destPt != null) {
                          final stairsList = ['L_STAIRS', 'R_STAIRS', 'L_STAIRS_OUTER', 'R_STAIRS_OUTER'];
                          double minDist = 999999.0;
                          for (final stairsKey in stairsList) {
                            final stairsPt = destCoords[stairsKey];
                            if (stairsPt != null) {
                              final dist = (destPt.dx - stairsPt.dx) * (destPt.dx - stairsPt.dx) + (destPt.dy - stairsPt.dy) * (destPt.dy - stairsPt.dy);
                              if (dist < minDist) {
                                minDist = dist;
                                chosenStairs = stairsKey;
                              }
                            }
                          }
                        }
                      }

                      final pathFromStairs = _bfs(chosenStairs, _destRoom!.id, destGraph);
                      if (pathFromStairs != null) {
                        _pathSteps = pathFromStairs;
                      }
                      
                      // Auto speak new instruction on floor change
                      _speakCurrentInstruction(isArabic);
                    });
                  },
                ),
                const SizedBox(width: 8),
              ],
              // Finish Route Button
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                icon: const Icon(Icons.stop_rounded, size: 16),
                label: Text(
                  isArabic ? "إنهاء المسار" : "End Route",
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  setState(() {
                    _startRoom = null;
                    _destRoom = null;
                    _pathSteps = [];
                    _navigationInstruction = null;
                  });
                  // Stop speaking
                  getIt<TextToSpeechService>().stop();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFloorSelector(bool isArabic, bool isDark) {
    return Container(
      height: 60,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _availableFloors.length,
        itemBuilder: (context, index) {
          final floor = _availableFloors[index];
          final isSelected = _selectedFloor == floor;
          final isStartFloor = _startRoom?.floorNumber == floor;
          final isDestFloor = _destRoom?.floorNumber == floor;
          
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedFloor = floor;
                  _transformationController.value = Matrix4.identity();
                  if (_startRoom != null && _destRoom != null) {
                    _calculatePath();
                  }
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  gradient: isSelected ? AppColors.primaryGradient : null,
                  color: isSelected 
                      ? null 
                      : (isDark ? const Color(0xFF1E293B) : Colors.white),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected 
                        ? Colors.transparent 
                        : (isDark ? Colors.white10 : Colors.grey[200]!),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isSelected 
                          ? AppColors.kPrimaryColor.withValues(alpha: 0.3) 
                          : Colors.black.withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: isSelected ? const Offset(0, 4) : const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isStartFloor || isDestFloor) ...[
                      Icon(
                        isStartFloor ? Icons.play_circle_fill_rounded : Icons.flag_rounded,
                        size: 14,
                        color: isSelected ? Colors.white : (isStartFloor ? Colors.blue : Colors.red),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      floor == 0 
                          ? (isArabic ? "الأرضي" : "Ground") 
                          : "${isArabic ? 'الطابق' : 'Floor'} $floor",
                      style: TextStyle(
                        color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLegendCard(bool isDark, bool isArabic) {
    Widget legendItem(Color color, String text) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            text, 
            style: TextStyle(
              fontSize: 10, 
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white70 : Colors.black54
            )
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isDark 
            ? const Color(0xFF1E293B).withValues(alpha: 0.85) 
            : Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Wrap(
        spacing: 14,
        runSpacing: 6,
        alignment: WrapAlignment.center,
        children: [
          legendItem(isDark ? const Color(0xFF148F77).withValues(alpha: 0.3) : const Color(0xFFE8F8F5), isArabic ? "مختبر" : "Lab"),
          legendItem(isDark ? const Color(0xFF2E86C1).withValues(alpha: 0.3) : const Color(0xFFEBF5FB), isArabic ? "قاعة" : "Class"),
          legendItem(isDark ? const Color(0xFFEC7063).withValues(alpha: 0.3) : const Color(0xFFFDEDEC), isArabic ? "حمام" : "Restroom"),
          legendItem(isDark ? const Color(0xFFF39C12).withValues(alpha: 0.3) : const Color(0xFFFEF9E7), isArabic ? "مكتب" : "Office"),
          legendItem(isDark ? const Color(0xFF8E44AD).withValues(alpha: 0.3) : const Color(0xFFF5EEF8), isArabic ? "مدرج" : "Hall"),
        ],
      ),
    );
  }

  Widget _buildFocusedRoomSheet(bool isArabic, bool isDark) {
    final room = _focusedRoom!;
    String roomTypeLabel = room.roomType.name;
    IconData icon = Icons.door_front_door;
    Color typeColor = Colors.grey;

    switch (room.roomType) {
      case RoomType.lab: 
        roomTypeLabel = isArabic ? "مختبر" : "Laboratory"; 
        icon = Icons.science;
        typeColor = Colors.teal;
        break;
      case RoomType.classRoom: 
        roomTypeLabel = isArabic ? "قاعة محاضرات" : "Classroom"; 
        icon = Icons.school;
        typeColor = Colors.blue;
        break;
      case RoomType.mensBathroom:
      case RoomType.womensBathroom: 
        roomTypeLabel = isArabic ? "دورات مياه" : "Restroom"; 
        icon = Icons.wc;
        typeColor = Colors.redAccent;
        break;
      case RoomType.office:
      case RoomType.teacherAssistantOffice: 
        roomTypeLabel = isArabic ? "مكتب أعضاء التدريس" : "Office"; 
        icon = Icons.work;
        typeColor = Colors.orange;
        break;
      case RoomType.cafeteria: 
        roomTypeLabel = isArabic ? "كافتيريا" : "Cafeteria"; 
        icon = Icons.local_cafe;
        typeColor = Colors.brown;
        break;
      case RoomType.hall: 
        roomTypeLabel = isArabic ? "صالة / مدرج" : "Lecture Hall"; 
        icon = Icons.meeting_room;
        typeColor = Colors.purple;
        break;
      case RoomType.mensPrayerRoom:
      case RoomType.womensPrayerRoom:
        roomTypeLabel = isArabic ? "مصلى" : "Prayer Room";
        icon = Icons.place;
        typeColor = Colors.green[800]!;
        break;
    }

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 1),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: const AlwaysStoppedAnimation(1.0),
        curve: Curves.easeOutBack,
      )),
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppColors.kPrimaryColor.withValues(alpha: 0.25),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 15,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Room Image
                if (room.image.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: 90,
                      height: 90,
                      color: isDark ? const Color(0xFF0F172A) : Colors.grey[200],
                      child: Image.network(
                        room.image,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(child: Icon(Icons.broken_image, color: Colors.grey, size: 28));
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                        },
                      ),
                    ),
                  )
                else
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: AppColors.kPrimaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Icon(Icons.meeting_room, color: AppColors.kPrimaryColor, size: 36),
                    ),
                  ),
                
                const SizedBox(width: 16),
                
                // Room Details Text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              room.name,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 20, color: Colors.grey),
                            onPressed: () {
                              setState(() {
                                _focusedRoom = null;
                              });
                            },
                          ),
                        ],
                      ),
                      
                      // Badges
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          // Type Badge
                          Chip(
                            avatar: Icon(icon, color: Colors.white, size: 12),
                            label: Text(roomTypeLabel, style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                            backgroundColor: typeColor,
                            padding: EdgeInsets.zero,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          // Floor Badge
                          Chip(
                            label: Text(
                              room.floorNumber == 0 
                                ? (isArabic ? "الأرضي" : "Ground Fl") 
                                : "${isArabic ? 'الدور' : 'Floor'} ${room.floorNumber}", 
                              style: TextStyle(fontSize: 10, color: isDark ? Colors.white70 : Colors.black87, fontWeight: FontWeight.bold),
                            ),
                            backgroundColor: isDark ? Colors.white12 : Colors.grey[200],
                            padding: EdgeInsets.zero,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Actions
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.play_circle_fill_rounded, size: 18),
                    label: Text(
                      isArabic ? "تعيين كبداية" : "Set as Start",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    onPressed: () {
                      setState(() {
                        _startRoom = room;
                        _calculatePath();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.kPrimaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.flag_rounded, size: 18),
                    label: Text(
                      isArabic ? "تعيين كوجهة" : "Set as Destination",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    onPressed: () {
                      setState(() {
                        _destRoom = room;
                        _calculatePath();
                      });
                    },
                  ),
                ),
              ],
            ),
            
            if (_startRoom != null || _destRoom != null) ...[
              const SizedBox(height: 8),
              Center(
                child: TextButton.icon(
                  icon: const Icon(Icons.restart_alt_rounded, color: Colors.redAccent, size: 16),
                  label: Text(
                    isArabic ? "إعادة تعيين المسار" : "Reset Route",
                    style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  onPressed: () {
                    setState(() {
                      _startRoom = null;
                      _destRoom = null;
                      _pathSteps = [];
                      _navigationInstruction = null;
                    });
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class IndoorMapPainter extends CustomPainter {
  final List<RoomModel> rooms;
  final Map<String, Offset> coords;
  final Map<String, List<String>> graph;
  final List<String> path;
  final int selectedFloor;
  final bool isDark;
  final bool isArabic;
  final RoomModel? focusedRoom;
  final RoomModel? startRoom;
  final RoomModel? destRoom;

  IndoorMapPainter({
    required this.rooms,
    required this.coords,
    required this.graph,
    required this.path,
    required this.selectedFloor,
    required this.isDark,
    required this.isArabic,
    this.focusedRoom,
    this.startRoom,
    this.destRoom,
  });

  int _getRoomIconCodePoint(RoomType type) {
    switch (type) {
      case RoomType.lab: return Icons.computer.codePoint;
      case RoomType.classRoom: return Icons.school.codePoint;
      case RoomType.mensBathroom:
      case RoomType.womensBathroom: return Icons.wc.codePoint;
      case RoomType.office:
      case RoomType.teacherAssistantOffice: return Icons.work.codePoint;
      case RoomType.cafeteria: return Icons.local_cafe.codePoint;
      case RoomType.hall: return Icons.meeting_room.codePoint;
      case RoomType.mensPrayerRoom:
      case RoomType.womensPrayerRoom: return Icons.place.codePoint;
    }
  }

  String _getShortRoomName(String name) {
    if (name.length > 11) {
      return '${name.substring(0, 9)}..';
    }
    return name;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final W = size.width;
    final H = size.height;

    // Margin setup (50 pixels on all sides)
    const double margin = 50.0;
    final double wScaled = W - (margin * 2);
    final double hScaled = H - (margin * 2);

    double scaleX(double x) => margin + x * wScaled;
    double scaleY(double y) => margin + y * hScaled;
    Offset scaleOffset(Offset offset) => Offset(scaleX(offset.dx), scaleY(offset.dy));

    // 1. Draw Blueprint Graph Paper Background (CAD look)
    final gridPaint = Paint()
      ..color = isDark ? Colors.blueGrey.withValues(alpha: 0.05) : Colors.blueGrey.withValues(alpha: 0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    for (double i = margin; i <= W - margin; i += 25) {
      canvas.drawLine(Offset(i, margin), Offset(i, H - margin), gridPaint);
    }
    for (double i = margin; i <= H - margin; i += 25) {
      canvas.drawLine(Offset(margin, i), Offset(W - margin, i), gridPaint);
    }

    // 2. Circle grid markers and dimension lines removed for a clean blueprint design

    // 4. Draw U-shaped Hallway Corridor Background & Guidelines
    final corridorPaint = Paint()
      ..color = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)
      ..style = PaintingStyle.fill;
    
    final leftCorridor = Rect.fromLTRB(scaleX(0.18), scaleY(0.22), scaleX(0.26), scaleY(0.88));
    final rightCorridor = Rect.fromLTRB(scaleX(0.74), scaleY(0.22), scaleX(0.82), scaleY(0.88));
    final topCorridor = Rect.fromLTRB(scaleX(0.18), scaleY(0.18), scaleX(0.82), scaleY(0.26));
    
    canvas.drawRect(leftCorridor, corridorPaint);
    canvas.drawRect(rightCorridor, corridorPaint);
    canvas.drawRect(topCorridor, corridorPaint);

    final dashPaint = Paint()
      ..color = isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(scaleX(0.22), scaleY(0.22)), Offset(scaleX(0.22), scaleY(0.88)), dashPaint);
    canvas.drawLine(Offset(scaleX(0.78), scaleY(0.22)), Offset(scaleX(0.78), scaleY(0.88)), dashPaint);
    canvas.drawLine(Offset(scaleX(0.22), scaleY(0.22)), Offset(scaleX(0.78), scaleY(0.22)), dashPaint);

    // 5. Draw Corridor Partition Walls (Thick CAD borders)
    final corridorWallPaint = Paint()
      ..color = isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    // Outer U boundaries
    canvas.drawLine(Offset(scaleX(0.18), scaleY(0.88)), Offset(scaleX(0.18), scaleY(0.18)), corridorWallPaint);
    canvas.drawLine(Offset(scaleX(0.82), scaleY(0.88)), Offset(scaleX(0.82), scaleY(0.18)), corridorWallPaint);
    canvas.drawLine(Offset(scaleX(0.18), scaleY(0.18)), Offset(scaleX(0.82), scaleY(0.18)), corridorWallPaint);
    canvas.drawLine(Offset(scaleX(0.18), scaleY(0.88)), Offset(scaleX(0.26), scaleY(0.88)), corridorWallPaint);
    canvas.drawLine(Offset(scaleX(0.74), scaleY(0.88)), Offset(scaleX(0.82), scaleY(0.88)), corridorWallPaint);

    // Inner U boundaries (courtyard)
    canvas.drawLine(Offset(scaleX(0.26), scaleY(0.88)), Offset(scaleX(0.26), scaleY(0.26)), corridorWallPaint);
    canvas.drawLine(Offset(scaleX(0.74), scaleY(0.88)), Offset(scaleX(0.74), scaleY(0.26)), corridorWallPaint);
    canvas.drawLine(Offset(scaleX(0.26), scaleY(0.26)), Offset(scaleX(0.74), scaleY(0.26)), corridorWallPaint);

    // Paints for detailed room interior items
    final detailColor = isDark ? Colors.white.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.12);
    final detailFillColor = isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03);

    final deskPaint = Paint()
      ..color = detailColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    final deskFillPaint = Paint()
      ..color = detailFillColor
      ..style = PaintingStyle.fill;
    final chairPaint = Paint()
      ..color = detailColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    final blackboardPaint = Paint()
      ..color = isDark ? Colors.tealAccent.withValues(alpha: 0.3) : Colors.green[800]!.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    final podiumPaint = Paint()
      ..color = detailColor
      ..style = PaintingStyle.fill;
    final computerPaint = Paint()
      ..color = isDark ? Colors.cyan.withValues(alpha: 0.4) : Colors.blueGrey.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final keyboardPaint = Paint()
      ..color = detailColor
      ..style = PaintingStyle.fill;
    final plantPaint = Paint()
      ..color = Colors.green.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;
    final plantPotPaint = Paint()
      ..color = Colors.orange.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;
    final sinkLinePaint = Paint()
      ..color = detailColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    final sinkPaint = Paint()
      ..color = isDark ? Colors.blue.withValues(alpha: 0.3) : Colors.blue.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;
    final toiletPaint = Paint()
      ..color = detailColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    final stallWallPaint = Paint()
      ..color = detailColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // 6. Draw Rooms, Interior Details, Windows, and Doors
    for (final room in rooms) {
      final center = coords[room.id];
      if (center == null) continue;

      final rx = scaleX(center.dx);
      final ry = scaleY(center.dy);

      final isHorizontalWing = center.dy < 0.35;
      final roomW = isHorizontalWing ? (0.08 * wScaled) : (0.06 * wScaled);
      final roomH = isHorizontalWing ? (0.065 * hScaled) : (0.065 * hScaled);

      final roomRect = Rect.fromCenter(
        center: Offset(rx, ry),
        width: roomW,
        height: roomH,
      );

      final isRoomOnPath = path.contains(room.id);
      final isStart = startRoom?.id == room.id;
      final isDest = destRoom?.id == room.id;
      final isFocused = focusedRoom?.id == room.id;

      // Color scheme adapted to state & light/dark mode
      Color fillCol = isDark ? const Color(0xFF1E293B) : Colors.white;
      Color borderCol = isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1);

      if (isStart) {
        fillCol = Colors.blue.withValues(alpha: isDark ? 0.25 : 0.12);
        borderCol = Colors.blue;
      } else if (isDest) {
        fillCol = Colors.red.withValues(alpha: isDark ? 0.25 : 0.12);
        borderCol = Colors.red;
      } else if (isFocused) {
        fillCol = AppColors.kPrimaryColor.withValues(alpha: isDark ? 0.25 : 0.12);
        borderCol = AppColors.kPrimaryColor;
      } else if (isRoomOnPath) {
        fillCol = AppColors.kPrimaryColor.withValues(alpha: isDark ? 0.12 : 0.06);
        borderCol = AppColors.kPrimaryColor.withValues(alpha: 0.6);
      } else {
        // Soft pastel colors matching room types
        switch (room.roomType) {
          case RoomType.lab:
            fillCol = isDark ? const Color(0x1F148F77) : const Color(0xFFE8F8F5);
            borderCol = isDark ? const Color(0x4D148F77) : const Color(0xB3A2D9CE);
            break;
          case RoomType.classRoom:
            fillCol = isDark ? const Color(0x1F2E86C1) : const Color(0xFFEBF5FB);
            borderCol = isDark ? const Color(0x4D2E86C1) : const Color(0xB3AED6F1);
            break;
          case RoomType.mensBathroom:
          case RoomType.womensBathroom:
            fillCol = isDark ? const Color(0x1FEC7063) : const Color(0xFFFDEDEC);
            borderCol = isDark ? const Color(0x4DEC7063) : const Color(0xB3F5B7B1);
            break;
          case RoomType.office:
          case RoomType.teacherAssistantOffice:
            fillCol = isDark ? const Color(0x1FF39C12) : const Color(0xFFFEF9E7);
            borderCol = isDark ? const Color(0x4DF39C12) : const Color(0xB3F9E79F);
            break;
          case RoomType.cafeteria:
            fillCol = isDark ? const Color(0x1FD35400) : const Color(0xFFFBEEE6);
            borderCol = isDark ? const Color(0x4DD35400) : const Color(0xB3EDBB99);
            break;
          case RoomType.hall:
            fillCol = isDark ? const Color(0x1F8E44AD) : const Color(0xFFF5EEF8);
            borderCol = isDark ? const Color(0x4D8E44AD) : const Color(0xB3D7BDE2);
            break;
          case RoomType.mensPrayerRoom:
          case RoomType.womensPrayerRoom:
            fillCol = isDark ? const Color(0x1F1E8449) : const Color(0xFFEBF5FB);
            borderCol = isDark ? const Color(0x4D1E8449) : const Color(0xB3A2D9CE);
            break;
        }
      }

      if (isFocused || isStart || isDest) {
        canvas.drawShadow(
          Path()..addRRect(RRect.fromRectAndRadius(roomRect, const Radius.circular(8))),
          Colors.black,
          isDark ? 5.0 : 3.0,
          true,
        );
      }

      // Draw Room Background block
      final fillPaint = Paint()
        ..color = fillCol
        ..style = PaintingStyle.fill;
      canvas.drawRRect(RRect.fromRectAndRadius(roomRect, const Radius.circular(8)), fillPaint);

      // Draw Room Interior Furniture / Textures
      canvas.save();
      canvas.clipRRect(RRect.fromRectAndRadius(roomRect, const Radius.circular(8)));
      
      switch (room.roomType) {
        case RoomType.hall:
          final centerSeatX = rx;
          final centerSeatY = ry - roomH / 2 + roomH * 0.08;
          final double stageY = ry - roomH / 2 + roomH * 0.22;
          
          canvas.drawLine(Offset(rx - roomW * 0.3, stageY), Offset(rx + roomW * 0.3, stageY), blackboardPaint);
          canvas.drawRect(Rect.fromCenter(center: Offset(rx, stageY + roomH * 0.1), width: roomW * 0.1, height: roomH * 0.08), podiumPaint);

          final double minRadius = roomH * 0.3;
          final double maxRadius = roomH * 0.7;
          final double stepRadius = (maxRadius - minRadius) / 2.0;
          for (double radius = minRadius; radius <= maxRadius; radius += stepRadius > 0 ? stepRadius : 1.0) {
            final rect = Rect.fromCircle(center: Offset(centerSeatX, centerSeatY), radius: radius);
            canvas.drawArc(rect, 0.2 * pi, 0.6 * pi, false, deskPaint);
            for (double angle = 0.25 * pi; angle <= 0.75 * pi; angle += 0.12 * pi) {
              final chairX = centerSeatX + radius * cos(angle);
              final chairY = centerSeatY + radius * sin(angle);
              canvas.drawCircle(Offset(chairX, chairY), (roomW * 0.02).clamp(1.0, 2.0), chairPaint);
            }
          }
          break;

        case RoomType.classRoom:
          final boardY = ry - roomH / 2 + roomH * 0.1;
          canvas.drawLine(Offset(rx - roomW * 0.25, boardY), Offset(rx + roomW * 0.25, boardY), blackboardPaint);

          final startX = rx - roomW * 0.25;
          final startY = ry - roomH * 0.15;
          final stepX = roomW * 0.25;
          final stepY = roomH * 0.25;
          for (int row = 0; row < 3; row++) {
            for (int col = 0; col < 3; col++) {
              final deskX = startX + col * stepX;
              final deskY = startY + row * stepY;
              canvas.drawRRect(
                RRect.fromRectAndRadius(
                  Rect.fromLTWH(deskX - roomW * 0.06, deskY - roomH * 0.03, roomW * 0.12, roomH * 0.06),
                  const Radius.circular(0.5),
                ),
                deskPaint,
              );
              canvas.drawCircle(Offset(deskX, deskY + roomH * 0.08), (roomW * 0.015).clamp(0.8, 1.5), chairPaint);
            }
          }
          break;

        case RoomType.lab:
          final startY = ry - roomH * 0.25;
          final stepY = roomH * 0.45;
          for (int table = 0; table < 2; table++) {
            final tY = startY + table * stepY;
            canvas.drawRect(Rect.fromCenter(center: Offset(rx, tY), width: roomW * 0.8, height: roomH * 0.06), deskFillPaint);
            canvas.drawRect(Rect.fromCenter(center: Offset(rx, tY), width: roomW * 0.8, height: roomH * 0.06), deskPaint);
            
            final double compStartX = rx - (roomW * 0.8) / 2 + roomW * 0.08;
            final double compStepX = roomW * 0.16;
            const int compCount = 5;
            for (int c = 0; c < compCount; c++) {
              final cX = compStartX + c * compStepX;
              canvas.drawLine(Offset(cX - roomW * 0.04, tY - roomH * 0.02), Offset(cX + roomW * 0.04, tY - roomH * 0.02), computerPaint);
              canvas.drawRect(Rect.fromCenter(center: Offset(cX, tY + roomH * 0.03), width: roomW * 0.05, height: roomH * 0.025), keyboardPaint);
            }
          }
          break;

        case RoomType.office:
        case RoomType.teacherAssistantOffice:
          final deskPath = Path()
            ..moveTo(rx - roomW / 2 + roomW * 0.08, ry - roomH / 2 + roomH * 0.1)
            ..lineTo(rx - roomW / 2 + roomW * 0.28, ry - roomH / 2 + roomH * 0.1)
            ..lineTo(rx - roomW / 2 + roomW * 0.28, ry - roomH / 2 + roomH * 0.22)
            ..lineTo(rx - roomW / 2 + roomW * 0.16, ry - roomH / 2 + roomH * 0.22)
            ..lineTo(rx - roomW / 2 + roomW * 0.16, ry - roomH / 2 + roomH * 0.38)
            ..lineTo(rx - roomW / 2 + roomW * 0.08, ry - roomH / 2 + roomH * 0.38)
            ..close();
          canvas.drawPath(deskPath, deskPaint);
          
          canvas.drawCircle(Offset(rx - roomW / 2 + roomW * 0.15, ry - roomH / 2 + roomH * 0.26), (roomW * 0.03).clamp(1.5, 3.0), chairPaint);
          canvas.drawCircle(Offset(rx + roomW * 0.15, ry - roomH * 0.12), (roomW * 0.02).clamp(1.0, 2.5), chairPaint);
          canvas.drawCircle(Offset(rx + roomW * 0.15, ry + roomH * 0.12), (roomW * 0.02).clamp(1.0, 2.5), chairPaint);
          
          canvas.drawCircle(Offset(rx + roomW / 2 - roomW * 0.12, ry - roomH / 2 + roomH * 0.18), (roomW * 0.03).clamp(1.5, 3.0), plantPaint);
          canvas.drawCircle(Offset(rx + roomW / 2 - roomW * 0.12, ry - roomH / 2 + roomH * 0.18), (roomW * 0.015).clamp(0.8, 1.5), plantPotPaint);
          break;

        case RoomType.mensBathroom:
        case RoomType.womensBathroom:
          final double sinkY = ry - roomH / 2 + roomH * 0.15;
          canvas.drawLine(Offset(rx - roomW * 0.25, sinkY), Offset(rx + roomW * 0.25, sinkY), sinkLinePaint);
          final double sinkStep = roomW * 0.16;
          for (double sX = rx - roomW * 0.16; sX <= rx + roomW * 0.16; sX += sinkStep) {
            canvas.drawCircle(Offset(sX, sinkY - roomH * 0.05), (roomW * 0.025).clamp(1.0, 2.5), sinkPaint);
          }
          
          final double stallStartY = ry - roomH * 0.08;
          final double stallW = roomW * 0.14;
          final double stallH = roomH * 0.32;
          final double stallStep = roomW * 0.17;
          for (int stall = 0; stall < 3; stall++) {
            final double sX = rx - roomW * 0.22 + stall * stallStep;
            canvas.drawRect(Rect.fromLTWH(sX, stallStartY, stallW, stallH), stallWallPaint);
            canvas.drawCircle(Offset(sX + stallW / 2, stallStartY + stallH / 2), (roomW * 0.02).clamp(1.0, 2.5), toiletPaint);
          }
          break;

        default:
          break;
      }
      canvas.restore();

      // Draw Room exterior wall Windows (Blue CAD double lines)
      final windowPaint = Paint()
        ..color = const Color(0xFF38BDF8) // cyan/sky blue architectural window color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;

      // Determine exterior wall relative positions
      if (center.dx < 0.20) {
        // Left wall is exterior
        canvas.drawLine(Offset(rx - roomW / 2 + 2, ry - roomH / 3), Offset(rx - roomW / 2 + 2, ry + roomH / 3), windowPaint);
        canvas.drawLine(Offset(rx - roomW / 2 - 1, ry - roomH / 3), Offset(rx - roomW / 2 - 1, ry + roomH / 3), windowPaint);
      } else if (center.dx > 0.80) {
        // Right wall is exterior
        canvas.drawLine(Offset(rx + roomW / 2 - 2, ry - roomH / 3), Offset(rx + roomW / 2 - 2, ry + roomH / 3), windowPaint);
        canvas.drawLine(Offset(rx + roomW / 2 + 1, ry - roomH / 3), Offset(rx + roomW / 2 + 1, ry + roomH / 3), windowPaint);
      } else if (center.dy < 0.20) {
        // Top wall is exterior
        canvas.drawLine(Offset(rx - roomW / 3, ry - roomH / 2 + 2), Offset(rx + roomW / 3, ry - roomH / 2 + 2), windowPaint);
        canvas.drawLine(Offset(rx - roomW / 3, ry - roomH / 2 - 1), Offset(rx + roomW / 3, ry - roomH / 2 - 1), windowPaint);
      }

      // Draw Room boundaries outline
      final borderPaint = Paint()
        ..color = borderCol
        ..style = PaintingStyle.stroke
        ..strokeWidth = (isFocused || isStart || isDest) ? 2.5 : 1.5;
      canvas.drawRRect(RRect.fromRectAndRadius(roomRect, const Radius.circular(8)), borderPaint);

      // Draw dynamic MaterialIcons icon
      final iconCodePoint = _getRoomIconCodePoint(room.roomType);
      final iconPainter = TextPainter(
        text: TextSpan(
          text: String.fromCharCode(iconCodePoint),
          style: TextStyle(
            color: isRoomOnPath || isStart || isDest || isFocused
                ? (isStart ? Colors.blue : isDest ? Colors.redAccent : AppColors.kPrimaryColor)
                : (isDark ? Colors.white60 : Colors.black45),
            fontSize: (0.018 * wScaled).clamp(10.0, 16.0),
            fontFamily: 'MaterialIcons',
          ),
        ),
        textDirection: ui.TextDirection.ltr,
      )..layout();
      iconPainter.paint(canvas, Offset(rx - iconPainter.width / 2, ry - roomH * 0.22));

      // Draw Room Name Label
      final namePainter = TextPainter(
        text: TextSpan(
          text: _getShortRoomName(room.name),
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: isFocused || isRoomOnPath || isStart || isDest ? FontWeight.bold : FontWeight.w500,
            fontSize: (0.01 * wScaled).clamp(7.5, 9.5),
          ),
        ),
        textDirection: ui.TextDirection.ltr,
      )..layout();
      namePainter.paint(canvas, Offset(rx - namePainter.width / 2, ry + roomH * 0.12));

      // Draw Doors & Swing arcs (Clearing walls so doors swing open realistically)
      final double doorLen = (0.015 * wScaled).clamp(8.0, 14.0);
      final doorLinePaint = Paint()
        ..color = isDark ? Colors.blueGrey[400]! : Colors.blueGrey[600]!
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      final clearPaint = Paint()
        ..color = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)
        ..style = PaintingStyle.fill;

      final arcPaint = Paint()
        ..color = isDark ? Colors.white30 : Colors.black26
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;

      if (isHorizontalWing) {
        // Top Connector doors on top or bottom corridor interfaces
        final doorOnBottom = center.dy < 0.22;
        final doorY = doorOnBottom ? ry + roomH / 2 : ry - roomH / 2;
        final pivotX = rx - doorLen / 2;
        final endX = rx + doorLen / 2;

        // Clear corridor/room wall partition segment
        canvas.drawRect(Rect.fromLTWH(pivotX - 1, doorY - 3, doorLen + 2, 6), clearPaint);

        if (doorOnBottom) {
          // Swing inwards (upwards)
          final doorOpenOffset = Offset(pivotX + doorLen * 0.707, doorY - doorLen * 0.707);
          canvas.drawLine(Offset(pivotX, doorY), doorOpenOffset, doorLinePaint);
          final path = Path()
            ..moveTo(endX, doorY)
            ..arcToPoint(doorOpenOffset, radius: Radius.circular(doorLen), clockwise: false);
          canvas.drawPath(path, arcPaint);
        } else {
          // Swing inwards (downwards)
          final doorOpenOffset = Offset(pivotX + doorLen * 0.707, doorY + doorLen * 0.707);
          canvas.drawLine(Offset(pivotX, doorY), doorOpenOffset, doorLinePaint);
          final path = Path()
            ..moveTo(endX, doorY)
            ..arcToPoint(doorOpenOffset, radius: Radius.circular(doorLen), clockwise: true);
          canvas.drawPath(path, arcPaint);
        }
      } else {
        // Left/Right wings vertical corridors interface
        final isLeftWing = center.dx < 0.50;
        final corrX = isLeftWing ? 0.22 : 0.78;
        final doorOnRight = center.dx < corrX;
        final doorX = doorOnRight ? rx + roomW / 2 : rx - roomW / 2;
        final pivotY = ry - doorLen / 2;
        final endY = ry + doorLen / 2;

        // Clear partition walls
        canvas.drawRect(Rect.fromLTWH(doorX - 3, pivotY - 1, 6, doorLen + 2), clearPaint);

        if (doorOnRight) {
          // Swing inwards (leftwards)
          final doorOpenOffset = Offset(doorX - doorLen * 0.707, pivotY + doorLen * 0.707);
          canvas.drawLine(Offset(doorX, pivotY), doorOpenOffset, doorLinePaint);
          final path = Path()
            ..moveTo(doorX, endY)
            ..arcToPoint(doorOpenOffset, radius: Radius.circular(doorLen), clockwise: true);
          canvas.drawPath(path, arcPaint);
        } else {
          // Swing inwards (rightwards)
          final doorOpenOffset = Offset(doorX + doorLen * 0.707, pivotY + doorLen * 0.707);
          canvas.drawLine(Offset(doorX, pivotY), doorOpenOffset, doorLinePaint);
          final path = Path()
            ..moveTo(doorX, endY)
            ..arcToPoint(doorOpenOffset, radius: Radius.circular(doorLen), clockwise: false);
          canvas.drawPath(path, arcPaint);
        }
      }
    }

    // 7. Draw Double Stairs (Left & Right wing stairwells)
    final stairNodes = ['L_STAIRS', 'R_STAIRS', 'L_STAIRS_OUTER', 'R_STAIRS_OUTER'];
    for (final stairsKey in stairNodes) {
      final stairsCenter = coords[stairsKey];
      if (stairsCenter != null) {
        final sx = scaleX(stairsCenter.dx);
        final sy = scaleY(stairsCenter.dy);
        final stairsW = 0.06 * wScaled;
        final stairsH = 0.065 * hScaled;
        
        final rect = Rect.fromCenter(center: Offset(sx, sy), width: stairsW, height: stairsH);
        final isStairsOnPath = path.contains(stairsKey);

        final fillPaint = Paint()
          ..color = isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)
          ..style = PaintingStyle.fill;
        canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(6)), fillPaint);

        final borderPaint = Paint()
          ..color = isStairsOnPath ? AppColors.kPrimaryColor : (isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1))
          ..style = PaintingStyle.stroke
          ..strokeWidth = isStairsOnPath ? 2.5 : 1.5;
        canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(6)), borderPaint);

        // Steps lines
        final stepsPaint = Paint()
          ..color = isDark ? Colors.white12 : Colors.black12
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0;
        final double stepGap = stairsH / 6.0;
        for (double y = sy - stairsH / 2 + stepGap; y < sy + stairsH / 2; y += stepGap) {
          canvas.drawLine(Offset(sx - stairsW / 2 + 4, y), Offset(sx + stairsW / 2 - 4, y), stepsPaint);
        }

        // Icon & Label
        final stairsIconPainter = TextPainter(
          text: TextSpan(
            text: String.fromCharCode(Icons.stairs.codePoint),
            style: TextStyle(
              color: isStairsOnPath ? AppColors.kPrimaryColor : (isDark ? Colors.white60 : Colors.black45),
              fontSize: (0.018 * wScaled).clamp(10.0, 14.0),
              fontFamily: 'MaterialIcons',
            ),
          ),
          textDirection: ui.TextDirection.ltr,
        )..layout();
        stairsIconPainter.paint(canvas, Offset(sx - stairsIconPainter.width / 2, sy - stairsH / 4));

        final stairsLabelPainter = TextPainter(
          text: TextSpan(
            text: isArabic ? "سلالم" : "Stairs",
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black54,
              fontWeight: FontWeight.bold,
              fontSize: (0.01 * wScaled).clamp(8.0, 10.0),
            ),
          ),
          textDirection: ui.TextDirection.ltr,
        )..layout();
        stairsLabelPainter.paint(canvas, Offset(sx - stairsLabelPainter.width / 2, sy + stairsH / 6));
      }
    }

    // 8. Draw Double Elevators (Left & Right wing lift shafts)
    final elevatorNodes = ['L_ELEVATOR', 'R_ELEVATOR', 'L_ELEVATOR_OUTER', 'R_ELEVATOR_OUTER'];
    for (final elevatorKey in elevatorNodes) {
      final elevatorCenter = coords[elevatorKey];
      if (elevatorCenter != null) {
        final ex = scaleX(elevatorCenter.dx);
        final ey = scaleY(elevatorCenter.dy);
        final elevatorW = 0.06 * wScaled;
        final elevatorH = 0.065 * hScaled;
        
        final rect = Rect.fromCenter(center: Offset(ex, ey), width: elevatorW, height: elevatorH);
        final isElevatorOnPath = path.contains(elevatorKey);

        final fillPaint = Paint()
          ..color = isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)
          ..style = PaintingStyle.fill;
        canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(6)), fillPaint);

        final borderPaint = Paint()
          ..color = isElevatorOnPath ? AppColors.kPrimaryColor : (isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1))
          ..style = PaintingStyle.stroke
          ..strokeWidth = isElevatorOnPath ? 2.5 : 1.5;
        canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(6)), borderPaint);

        // X cross lines (CAD elevator shaft texture)
        final xPaint = Paint()
          ..color = isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0;
        canvas.drawLine(Offset(ex - elevatorW / 2 + 5, ey - elevatorH / 2 + 5), Offset(ex + elevatorW / 2 - 5, ey + elevatorH / 2 - 5), xPaint);
        canvas.drawLine(Offset(ex - elevatorW / 2 + 5, ey + elevatorH / 2 - 5), Offset(ex + elevatorW / 2 - 5, ey - elevatorH / 2 + 5), xPaint);

        // Center split door line
        final doorPaint = Paint()
          ..color = isDark ? Colors.white30 : Colors.black38
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;
        canvas.drawLine(Offset(ex - elevatorW / 4, ey), Offset(ex + elevatorW / 4, ey), doorPaint);
        canvas.drawLine(Offset(ex - elevatorW / 4, ey - elevatorH * 0.08), Offset(ex - elevatorW / 4, ey + elevatorH * 0.08), doorPaint);
        canvas.drawLine(Offset(ex + elevatorW / 4, ey - elevatorH * 0.08), Offset(ex + elevatorW / 4, ey + elevatorH * 0.08), doorPaint);

        // Icon & Label
        final elevatorIconPainter = TextPainter(
          text: TextSpan(
            text: String.fromCharCode(Icons.elevator.codePoint),
            style: TextStyle(
              color: isElevatorOnPath ? AppColors.kPrimaryColor : (isDark ? Colors.white60 : Colors.black45),
              fontSize: (0.018 * wScaled).clamp(10.0, 14.0),
              fontFamily: 'MaterialIcons',
            ),
          ),
          textDirection: ui.TextDirection.ltr,
        )..layout();
        elevatorIconPainter.paint(canvas, Offset(ex - elevatorIconPainter.width / 2, ey - elevatorH / 4));

        final elevatorLabelPainter = TextPainter(
          text: TextSpan(
            text: isArabic ? "مصعد" : "Elevator",
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black54,
              fontWeight: FontWeight.bold,
              fontSize: (0.01 * wScaled).clamp(8.0, 10.0),
            ),
          ),
          textDirection: ui.TextDirection.ltr,
        )..layout();
        elevatorLabelPainter.paint(canvas, Offset(ex - elevatorLabelPainter.width / 2, ey + elevatorH / 6));
      }
    }

    // 9. Draw Navigation Route Path (glowing neon lines with directional chevrons)
    if (path.length >= 2) {
      final pathPaint = Paint()
        ..color = AppColors.kPrimaryColor
        ..strokeWidth = 4.0
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      final glowPaint = Paint()
        ..color = AppColors.kPrimaryColor.withValues(alpha: 0.25)
        ..strokeWidth = 12.0
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      final drawnPath = Path();
      bool first = true;
      for (final nodeId in path) {
        final pt = coords[nodeId];
        if (pt == null) continue;
        final scaledPt = scaleOffset(pt);
        if (first) {
          drawnPath.moveTo(scaledPt.dx, scaledPt.dy);
          first = false;
        } else {
          drawnPath.lineTo(scaledPt.dx, scaledPt.dy);
        }
      }

      canvas.drawPath(drawnPath, glowPaint);
      canvas.drawPath(drawnPath, pathPaint);

      // Flow direction chevrons
      for (int i = 0; i < path.length - 1; i++) {
        final p1 = coords[path[i]];
        final p2 = coords[path[i + 1]];
        if (p1 == null || p2 == null) continue;

        final start = scaleOffset(p1);
        final end = scaleOffset(p2);

        final mid = Offset((start.dx + end.dx) / 2, (start.dy + end.dy) / 2);
        final angle = atan2(end.dy - start.dy, end.dx - start.dx);

        const arrowSize = 6.0;
        final arrowPath = Path()
          ..moveTo(mid.dx - arrowSize * cos(angle - pi / 6), mid.dy - arrowSize * sin(angle - pi / 6))
          ..lineTo(mid.dx, mid.dy)
          ..lineTo(mid.dx - arrowSize * cos(angle + pi / 6), mid.dy - arrowSize * sin(angle + pi / 6));

        final arrowPaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..strokeWidth = 2.0;
        canvas.drawPath(arrowPath, arrowPaint);
      }
    }

    // 10. Draw Start & Destination Marker Pins (with shadows)
    if (path.isNotEmpty) {
      final startNode = path.first;
      final startPt = coords[startNode];
      if (startPt != null) {
        final scaledPt = scaleOffset(startPt);
        final sx = scaledPt.dx;
        final sy = scaledPt.dy;

        final startCore = Paint()
          ..color = Colors.blue[600]!
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(sx, sy), 5.0, startCore);

        final startRing = Paint()
          ..color = Colors.blue.withValues(alpha: 0.3)
          ..strokeWidth = 2.5
          ..style = PaintingStyle.stroke;
        canvas.drawCircle(Offset(sx, sy), 10.0, startRing);
      }

      final destNode = path.last;
      final destPt = coords[destNode];
      if (destPt != null && destNode != 'L_STAIRS' && destNode != 'R_STAIRS') {
        final scaledPt = scaleOffset(destPt);
        final dx = scaledPt.dx;
        final dy = scaledPt.dy;

        final pinPainter = TextPainter(
          text: TextSpan(
            text: String.fromCharCode(Icons.location_on.codePoint),
            style: TextStyle(
              color: Colors.redAccent[700],
              fontSize: 24,
              fontFamily: 'MaterialIcons',
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  offset: const Offset(0, 1.5),
                  blurRadius: 3.0,
                ),
              ],
            ),
          ),
          textDirection: ui.TextDirection.ltr,
        )..layout();
        pinPainter.paint(canvas, Offset(dx - pinPainter.width / 2, dy - 24));
      }
    }
  }

  @override
  bool hitTest(Offset position) => true;

  @override
  bool shouldRepaint(covariant IndoorMapPainter oldDelegate) =>
      oldDelegate.rooms != rooms ||
      oldDelegate.path != path ||
      oldDelegate.selectedFloor != selectedFloor ||
      oldDelegate.isDark != isDark ||
      oldDelegate.focusedRoom != focusedRoom ||
      oldDelegate.startRoom != startRoom ||
      oldDelegate.destRoom != destRoom;
}
