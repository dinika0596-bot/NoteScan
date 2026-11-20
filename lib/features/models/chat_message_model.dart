class ChatMessageModel {
  final String id;
  final String documentId;
  final String userId;
  final String role; // 'user' or 'model'
  final String message;
  final DateTime createdAt;

  ChatMessageModel({
    required this.id,
    required this.documentId,
    required this.userId,
    required this.role,
    required this.message,
    required this.createdAt,
  });

  factory ChatMessageModel.fromMap(Map<String, dynamic> map) {
    return ChatMessageModel(
      id: map['id']?.toString() ?? '',
      documentId: map['document_id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? '',
      role: map['role'] ?? 'user',
      message: map['message'] ?? '',
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'document_id': documentId,
      'user_id': userId,
      'role': role,
      'message': message,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
