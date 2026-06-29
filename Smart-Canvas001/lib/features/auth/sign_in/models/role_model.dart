class RoleModel {
  final String id;
  final String name;
  final DateTime createdAt;
  RoleModel({required this.id, required this.name, required this.createdAt});
  factory RoleModel.fromJson(Map<String, dynamic> json) => RoleModel(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? 'User',
    createdAt: json['created_at'] != null 
        ? DateTime.parse(json['created_at'] as String) 
        : DateTime.now(),
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'name': name,
    'created_at': createdAt.toIso8601String(),
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RoleModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
