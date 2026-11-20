class FolderModel {
  final String id;
  final String userId;
  final String name;
  final String colorHex;
  final DateTime createdAt;

  FolderModel({
    required this.id,
    required this.userId,
    required this.name,
    this.colorHex = '#4F46E5',
    required this.createdAt,
  });

  factory FolderModel.fromMap(Map<String, dynamic> map) {
    return FolderModel(
      id: map['id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? '',
      name: map['name'] ?? 'Folder',
      colorHex: map['color_hex'] ?? '#4F46E5',
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'color_hex': colorHex,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
