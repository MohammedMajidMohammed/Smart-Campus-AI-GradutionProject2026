  import 'package:smart_canvas/features/administrator/buildings/models/building_model.dart';

  enum RoomType {
  hall,
  lab,
  office,
  classRoom,
  mensBathroom,
  womensBathroom,
  mensPrayerRoom,
  womensPrayerRoom,
  cafeteria,
  teacherAssistantOffice,
}

extension RoomTypeExtension on RoomType {
  String get label {
    switch (this) {
      case RoomType.hall:
        return 'Hall';
      case RoomType.lab:
        return 'Lab';
      case RoomType.office:
        return 'Office';
      case RoomType.classRoom:
        return 'Class Room';
      case RoomType.mensBathroom:
        return 'Men\'s Bathroom';
      case RoomType.womensBathroom:
        return 'Women\'s Bathroom';
      case RoomType.mensPrayerRoom:
        return 'Men\'s Prayer Room';
      case RoomType.womensPrayerRoom:
        return 'Women\'s Prayer Room';
      case RoomType.cafeteria:
        return 'Cafeteria';
      case RoomType.teacherAssistantOffice:
        return 'TA Office';
    }
  }
}

  class RoomModel {
    final String id;
    final BuildingModel? buildingModel;
    final String name;
    final String image;
    final RoomType roomType;
    final int floorNumber;
    final String? side; // left, right, center
    final double? mapX;
    final double? mapY;
    final DateTime? createdAt;

    RoomModel({
      required this.id,
      required this.image,
      this.buildingModel,
      required this.name,
      required this.roomType,
      this.floorNumber = 0,
      this.side,
      this.mapX,
      this.mapY,
      this.createdAt,
    });

    /// from Supabase / API
    factory RoomModel.fromJson(Map<String, dynamic> json) {
      return RoomModel(
        id: json['id']?.toString() ?? '',
        image: json['image']?.toString() ?? '',
        buildingModel: json['building'] != null
            ? BuildingModel.fromJson(json['building'])
            : null,
        name: json['name']?.toString() ?? '',
        roomType: RoomType.values.firstWhere(
          (type) => type.name == json['room_type']?.toString(),
          orElse: () => RoomType.office,
        ),
        floorNumber: json['floor_number'] ?? 0,
        side: json['side']?.toString(),
        mapX: (json['map_x'] as num?)?.toDouble(),
        mapY: (json['map_y'] as num?)?.toDouble(),
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'])
            : null,
      );
    }

    /// to Supabase / API
    Map<String, dynamic> toJson() {
      return {
        'id': id,
        'building': buildingModel?.toJson(),
        'image': image,
        'name': name,
        'room_type': roomType.name,
        'floor_number': floorNumber,
        'side': side,
        'map_x': mapX,
        'map_y': mapY,
        'created_at': createdAt?.toIso8601String(),
      };
    }

    @override
    bool operator ==(Object other) =>
        identical(this, other) ||
        other is RoomModel && runtimeType == other.runtimeType && id == other.id;

    @override
    int get hashCode => id.hashCode;
  }
