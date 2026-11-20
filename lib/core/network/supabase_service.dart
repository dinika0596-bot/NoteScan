import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../features/models/document_model.dart';
import '../../features/models/folder_model.dart';
import '../../features/models/chat_message_model.dart';
import '../constants/app_constants.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  SupabaseClient? _client;
  bool isGuest = false;

  // Local fallback caches for Guest mode
  final List<DocumentModel> _guestDocs = [];
  final List<FolderModel> _guestFolders = [
    FolderModel(
      id: 'default-folder',
      userId: AppConstants.guestUserId,
      name: 'Catatan Umum',
      colorHex: '#4F46E5',
      createdAt: DateTime.now(),
    )
  ];
  final Map<String, List<ChatMessageModel>> _guestChats = {};

  void init(SupabaseClient client) {
    _client = client;
  }

  SupabaseClient get client {
    if (_client == null) {
      throw Exception('Supabase client belum diinisialisasi.');
    }
    return _client!;
  }

  String get currentUserId {
    if (isGuest || _client?.auth.currentUser == null) {
      return AppConstants.guestUserId;
    }
    return _client!.auth.currentUser!.id;
  }

  String? get currentUserEmail {
    if (isGuest) return 'Tamu (Guest)';
    return _client?.auth.currentUser?.email;
  }

  // --- Auth Methods ---
  Future<AuthResponse?> signInWithEmail(String email, String password) async {
    isGuest = false;
    return await _client?.auth.signInWithPassword(email: email, password: password);
  }

  Future<AuthResponse?> signUpWithEmail(String email, String password, String name) async {
    isGuest = false;
    return await _client?.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': name, 'is_guest': false},
    );
  }

  Future<void> signInAsGuest() async {
    isGuest = true;
  }

  Future<void> signOut() async {
    isGuest = false;
    await _client?.auth.signOut();
  }

  // --- Folder Management ---
  Future<List<FolderModel>> getFolders() async {
    if (isGuest || _client == null) {
      return _guestFolders;
    }
    try {
      final response = await client
          .from('folders')
          .select()
          .eq('user_id', currentUserId)
          .order('created_at', ascending: false);

      final list = (response as List).map((e) => FolderModel.fromMap(e)).toList();
      return list;
    } catch (e) {
      debugPrint('Error getFolders: $e');
      return _guestFolders;
    }
  }

  Future<FolderModel> createFolder(String name, {String colorHex = '#4F46E5'}) async {
    final newFolder = FolderModel(
      id: const Uuid().v4(),
      userId: currentUserId,
      name: name,
      colorHex: colorHex,
      createdAt: DateTime.now(),
    );

    if (isGuest || _client == null) {
      _guestFolders.add(newFolder);
      return newFolder;
    }

    try {
      final data = await client.from('folders').insert(newFolder.toMap()).select().single();
      return FolderModel.fromMap(data);
    } catch (e) {
      debugPrint('Error createFolder: $e');
      _guestFolders.add(newFolder);
      return newFolder;
    }
  }

  // --- File Storage Upload ---
  Future<List<String>> uploadFiles(List<File> files) async {
    if (isGuest || _client == null) {
      // In guest or local mode, return local file paths as reference
      return files.map((f) => f.path).toList();
    }

    List<String> uploadedUrls = [];
    final userId = currentUserId;

    for (final file in files) {
      try {
        final ext = file.path.split('.').last;
        final fileName = '$userId/${const Uuid().v4()}.$ext';
        await client.storage.from(AppConstants.notesBucket).upload(fileName, file);
        final publicUrl = client.storage.from(AppConstants.notesBucket).getPublicUrl(fileName);
        uploadedUrls.add(publicUrl);
      } catch (e) {
        debugPrint('Upload error: $e. Fallback to local path.');
        uploadedUrls.add(file.path);
      }
    }
    return uploadedUrls;
  }

  // --- Document CRUD ---
  Future<List<DocumentModel>> getDocuments({String? searchQuery, String? folderId}) async {
    if (isGuest || _client == null) {
      var docs = List<DocumentModel>.from(_guestDocs);
      if (folderId != null) {
        docs = docs.where((d) => d.folderId == folderId).toList();
      }
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        docs = docs.where((d) => d.title.toLowerCase().contains(searchQuery.toLowerCase())).toList();
      }
      return docs;
    }

    try {
      var query = client.from('documents').select().eq('user_id', currentUserId);
      if (folderId != null) {
        query = query.eq('folder_id', folderId);
      }
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        query = query.ilike('title', '%$searchQuery%');
      }

      final response = await query.order('created_at', ascending: false);
      return (response as List).map((e) => DocumentModel.fromMap(e)).toList();
    } catch (e) {
      debugPrint('Error getDocuments: $e');
      return _guestDocs;
    }
  }

  Future<DocumentModel> saveDocument({
    required String title,
    required List<String> fileUrls,
    required String summary,
    required List<String> keyPoints,
    String? folderId,
  }) async {
    final doc = DocumentModel(
      id: const Uuid().v4(),
      userId: currentUserId,
      folderId: folderId,
      title: title,
      fileUrls: fileUrls,
      summary: summary,
      keyPoints: keyPoints,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    if (isGuest || _client == null) {
      _guestDocs.insert(0, doc);
      return doc;
    }

    try {
      final data = await client.from('documents').insert(doc.toMap()).select().single();
      return DocumentModel.fromMap(data);
    } catch (e) {
      debugPrint('Error saveDocument: $e');
      _guestDocs.insert(0, doc);
      return doc;
    }
  }

  Future<void> deleteDocument(String id) async {
    if (isGuest || _client == null) {
      _guestDocs.removeWhere((d) => d.id == id);
      _guestChats.remove(id);
      return;
    }

    try {
      await client.from('documents').delete().eq('id', id);
    } catch (e) {
      debugPrint('Error deleteDocument: $e');
      _guestDocs.removeWhere((d) => d.id == id);
    }
  }

  Future<void> updateDocumentTitle(String id, String newTitle, {String? folderId}) async {
    if (isGuest || _client == null) {
      final index = _guestDocs.indexWhere((d) => d.id == id);
      if (index != -1) {
        final old = _guestDocs[index];
        _guestDocs[index] = DocumentModel(
          id: old.id,
          userId: old.userId,
          folderId: folderId ?? old.folderId,
          title: newTitle,
          fileUrls: old.fileUrls,
          summary: old.summary,
          keyPoints: old.keyPoints,
          createdAt: old.createdAt,
          updatedAt: DateTime.now(),
        );
      }
      return;
    }

    try {
      final Map<String, dynamic> updateData = {'title': newTitle, 'updated_at': DateTime.now().toIso8601String()};
      if (folderId != null) updateData['folder_id'] = folderId;
      await client.from('documents').update(updateData).eq('id', id);
    } catch (e) {
      debugPrint('Error updateDocumentTitle: $e');
    }
  }

  // --- Document Chat Q&A ---
  Future<List<ChatMessageModel>> getChatHistory(String documentId) async {
    if (isGuest || _client == null) {
      return _guestChats[documentId] ?? [];
    }

    try {
      final response = await client
          .from('document_chats')
          .select()
          .eq('document_id', documentId)
          .order('created_at', ascending: true);

      return (response as List).map((e) => ChatMessageModel.fromMap(e)).toList();
    } catch (e) {
      debugPrint('Error getChatHistory: $e');
      return _guestChats[documentId] ?? [];
    }
  }

  Future<ChatMessageModel> sendChatMessage({
    required String documentId,
    required String role,
    required String message,
  }) async {
    final chat = ChatMessageModel(
      id: const Uuid().v4(),
      documentId: documentId,
      userId: currentUserId,
      role: role,
      message: message,
      createdAt: DateTime.now(),
    );

    if (isGuest || _client == null) {
      _guestChats.putIfAbsent(documentId, () => []);
      _guestChats[documentId]!.add(chat);
      return chat;
    }

    try {
      final data = await client.from('document_chats').insert(chat.toMap()).select().single();
      return ChatMessageModel.fromMap(data);
    } catch (e) {
      debugPrint('Error sendChatMessage: $e');
      _guestChats.putIfAbsent(documentId, () => []);
      _guestChats[documentId]!.add(chat);
      return chat;
    }
  }
}
