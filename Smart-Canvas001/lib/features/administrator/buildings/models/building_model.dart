import 'package:smart_canvas/features/administrator/collages/models/collage_model.dart';

enum BuildingType { educational, lab, admin }

class BuildingModel {
  final String id;
  final String name;
  final CollegeModel? collegeModel;
  final String image;
  final BuildingType buildingType;
  final double latitude;
  final double longitude;
  final DateTime? createdAt;

  BuildingModel({
    required this.id,
    required this.name,
    required this.collegeModel,
    required this.image,
    required this.buildingType,
    required this.latitude,
    required this.longitude,
    this.createdAt,
  });

  factory BuildingModel.fromJson(Map<String, dynamic> json) {
    return BuildingModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      image: json['image']?.toString() ?? '',
      collegeModel: json['college'] != null
          ? CollegeModel.fromJson(json['college'])
          : null,
      buildingType: BuildingType.values.firstWhere(
        (element) => element.name == json['building_type']?.toString(),
        orElse: () => BuildingType.educational,
      ),
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  // تحويل إلى JSON (لـ API أو Supabase)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'image': image,
      'college': collegeModel?.toJson(),
      'building_type': buildingType.name,
      'latitude': latitude,
      'longitude': longitude,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
