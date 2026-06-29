class AcademicYearModel {
  final String id;
  final String name;
  final DateTime createdAt;
  final String? collegeId; // Added for manual joining

  AcademicYearModel({
    required this.id,
    required this.name,
    required this.createdAt,
    this.collegeId,
  });

  factory AcademicYearModel.fromJson(Map<String, dynamic> json) {
    return AcademicYearModel(
      id: json['id'],
      name: json['name'],
      createdAt: DateTime.parse(json['created_at']),
      collegeId: json['college_id'] ?? json['collage_id'], // Map from DB (handle typo)
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'college_id': collegeId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AcademicYearModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
