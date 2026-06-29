class ChatRoomModel {
  final String id;
  final String type; // 'private_admin_prof', 'college_group'
  final String targetId; // prof_id or college_id
  final DateTime createdAt;

  ChatRoomModel({
    required this.id,
    required this.type,
    required this.targetId,
    required this.createdAt,
  });

  factory ChatRoomModel.fromJson(Map<String, dynamic> json) {
    return ChatRoomModel(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      targetId: json['target_id']?.toString() ?? '',
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'type': type,
      'target_id': targetId,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
