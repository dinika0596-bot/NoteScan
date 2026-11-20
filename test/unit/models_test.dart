import 'package:flutter_test/flutter_test.dart';
import 'package:notescan/features/models/document_model.dart';
import 'package:notescan/features/models/folder_model.dart';
import 'package:notescan/features/models/chat_message_model.dart';

void main() {
  group('Models Serialization Unit Tests', () {
    test('DocumentModel fromMap and toMap', () {
      final now = DateTime.now();
      final docMap = {
        'id': 'doc-123',
        'user_id': 'user-abc',
        'folder_id': 'folder-xyz',
        'title': 'Kalkulus Integral',
        'file_urls': ['https://supabase.co/storage/file1.jpg', 'https://supabase.co/storage/file2.jpg'],
        'summary': 'Ringkasan integral parsial dan substitusi.',
        'key_points': ['Integral tak tentu', 'Teknik substitusi aljabar'],
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      };

      final doc = DocumentModel.fromMap(docMap);

      expect(doc.id, 'doc-123');
      expect(doc.userId, 'user-abc');
      expect(doc.folderId, 'folder-xyz');
      expect(doc.title, 'Kalkulus Integral');
      expect(doc.fileUrls.length, 2);
      expect(doc.keyPoints.length, 2);
      expect(doc.summary, contains('integral parsial'));

      final generatedMap = doc.toMap();
      expect(generatedMap['id'], 'doc-123');
      expect(generatedMap['title'], 'Kalkulus Integral');
      expect(generatedMap['file_urls'], isA<List>());
    });

    test('FolderModel fromMap and toMap', () {
      final now = DateTime.now();
      final folderMap = {
        'id': 'folder-1',
        'user_id': 'user-1',
        'name': 'Fisika Kuantum',
        'color_hex': '#10B981',
        'created_at': now.toIso8601String(),
      };

      final folder = FolderModel.fromMap(folderMap);

      expect(folder.id, 'folder-1');
      expect(folder.name, 'Fisika Kuantum');
      expect(folder.colorHex, '#10B981');

      final generatedMap = folder.toMap();
      expect(generatedMap['name'], 'Fisika Kuantum');
    });

    test('ChatMessageModel fromMap and toMap', () {
      final now = DateTime.now();
      final chatMap = {
        'id': 'chat-99',
        'document_id': 'doc-123',
        'user_id': 'user-1',
        'role': 'user',
        'message': 'Apa rumus energi foton?',
        'created_at': now.toIso8601String(),
      };

      final chat = ChatMessageModel.fromMap(chatMap);

      expect(chat.id, 'chat-99');
      expect(chat.documentId, 'doc-123');
      expect(chat.role, 'user');
      expect(chat.message, 'Apa rumus energi foton?');

      final generatedMap = chat.toMap();
      expect(generatedMap['message'], 'Apa rumus energi foton?');
    });
  });
}
