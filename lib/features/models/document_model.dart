class DocumentModel {
  final String id;
  final String userId;
  final String? folderId;
  final String title;
  final List<String> fileUrls;
  final String summary;
  final List<String> keyPoints;
  final DateTime createdAt;
  final DateTime updatedAt;

  DocumentModel({
    required this.id,
    required this.userId,
    this.folderId,
    required this.title,
    required this.fileUrls,
    required this.summary,
    required this.keyPoints,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DocumentModel.fromMap(Map<String, dynamic> map) {
    List<String> parsedFiles = [];
    if (map['file_urls'] != null) {
      parsedFiles = List<String>.from(map['file_urls']);
    }

    List<String> parsedPoints = [];
    if (map['key_points'] != null) {
      if (map['key_points'] is List) {
        parsedPoints = (map['key_points'] as List).map((e) => e.toString()).toList();
      }
    }

    return DocumentModel(
      id: map['id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? '',
      folderId: map['folder_id']?.toString(),
      title: map['title'] ?? 'Tanpa Judul',
      fileUrls: parsedFiles,
      summary: map['summary'] ?? '',
      keyPoints: parsedPoints,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at']) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'folder_id': folderId,
      'title': title,
      'file_urls': fileUrls,
      'summary': summary,
      'key_points': keyPoints,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
