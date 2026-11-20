import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/supabase_service.dart';
import '../models/document_model.dart';
import '../models/folder_model.dart';
import '../analysis/summary_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final _supabaseService = SupabaseService();
  final _searchController = TextEditingController();

  List<DocumentModel> _documents = [];
  List<FolderModel> _folders = [];
  String? _selectedFolderId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final folders = await _supabaseService.getFolders();
    final docs = await _supabaseService.getDocuments(
      searchQuery: _searchController.text.trim(),
      folderId: _selectedFolderId,
    );

    if (mounted) {
      setState(() {
        _folders = folders;
        _documents = docs;
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged(String val) {
    _loadData();
  }

  Future<void> _showAddFolderDialog() async {
    final folderNameCtrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Buat Kategori / Folder Baru'),
        content: TextField(
          controller: folderNameCtrl,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Nama Folder (Misal: Fisika Dasar)',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              final name = folderNameCtrl.text.trim();
              if (name.isNotEmpty) {
                await _supabaseService.createFolder(name);
                if (mounted) Navigator.pop(ctx);
                _loadData();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Simpan', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _showRenameDialog(DocumentModel doc) async {
    final titleCtrl = TextEditingController(text: doc.title);
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ubah Judul Catatan'),
        content: TextField(
          controller: titleCtrl,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Judul Baru',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              final newTitle = titleCtrl.text.trim();
              if (newTitle.isNotEmpty) {
                await _supabaseService.updateDocumentTitle(doc.id, newTitle);
                if (mounted) Navigator.pop(ctx);
                _loadData();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Perbarui', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(DocumentModel doc) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Catatan?'),
        content: Text('Apakah Anda yakin ingin menghapus "${doc.title}"? Tindakan ini tidak dapat dibatalkan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _supabaseService.deleteDocument(doc.id);
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Pustaka Dokumen'),
        actions: [
          IconButton(
            icon: const Icon(Icons.create_new_folder_outlined),
            tooltip: 'Tambah Folder',
            onPressed: _showAddFolderDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Cari judul catatan...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _loadData();
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.cardBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.cardBorder),
                ),
              ),
            ),
          ),

          // Folder / Category Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('Semua'),
                  selected: _selectedFolderId == null,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedFolderId = null);
                      _loadData();
                    }
                  },
                ),
                const SizedBox(width: 8),
                ..._folders.map((f) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(f.name),
                      selected: _selectedFolderId == f.id,
                      onSelected: (selected) {
                        setState(() => _selectedFolderId = selected ? f.id : null);
                        _loadData();
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Document List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _documents.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.folder_open, size: 54, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            const Text(
                              'Tidak ada catatan ditemukan',
                              style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Sesuaikan kata kunci pencarian atau pindai catatan baru.',
                              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _documents.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final doc = _documents[index];
                          return Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: const BorderSide(color: AppColors.cardBorder),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              leading: CircleAvatar(
                                backgroundColor: AppColors.primaryLight.withOpacity(0.2),
                                child: const Icon(Icons.description, color: AppColors.primary),
                              ),
                              title: Text(
                                doc.title,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                doc.summary,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                              trailing: PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
                                onSelected: (action) {
                                  if (action == 'rename') {
                                    _showRenameDialog(doc);
                                  } else if (action == 'delete') {
                                    _confirmDelete(doc);
                                  }
                                },
                                itemBuilder: (ctx) => [
                                  const PopupMenuItem(
                                    value: 'rename',
                                    child: Row(
                                      children: [
                                        Icon(Icons.edit, size: 18),
                                        SizedBox(width: 8),
                                        Text('Ubah Judul'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete, size: 18, color: Colors.red),
                                        SizedBox(width: 8),
                                        Text('Hapus', style: TextStyle(color: Colors.red)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => SummaryScreen(
                                      document: doc,
                                      initialFiles: const [],
                                    ),
                                  ),
                                ).then((_) => _loadData());
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
