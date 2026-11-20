import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/supabase_service.dart';
import '../models/folder_model.dart';
import '../analysis/summary_screen.dart';

class PreviewScreen extends StatefulWidget {
  final List<File> initialFiles;
  final bool isPdf;

  const PreviewScreen({
    super.key,
    required this.initialFiles,
    this.isPdf = false,
  });

  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen> {
  late List<File> _files;
  final _titleController = TextEditingController();
  final _supabaseService = SupabaseService();
  final _imagePicker = ImagePicker();

  List<FolderModel> _folders = [];
  String? _selectedFolderId;
  bool _isLoadingFolders = true;

  @override
  void initState() {
    super.initState();
    _files = List<File>.from(widget.initialFiles);
    _titleController.text = 'Catatan ${DateTime.now().day}/${DateTime.now().month}';
    _loadFolders();
  }

  Future<void> _loadFolders() async {
    final list = await _supabaseService.getFolders();
    if (mounted) {
      setState(() {
        _folders = list;
        if (_folders.isNotEmpty) {
          _selectedFolderId = _folders.first.id;
        }
        _isLoadingFolders = false;
      });
    }
  }

  Future<void> _addMorePages() async {
    final List<XFile> moreImages = await _imagePicker.pickMultiImage(imageQuality: 85);
    if (moreImages.isNotEmpty) {
      setState(() {
        _files.addAll(moreImages.map((x) => File(x.path)));
      });
    }
  }

  void _removePage(int index) {
    if (_files.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dokumen harus memiliki minimal 1 halaman.')),
      );
      return;
    }
    setState(() {
      _files.removeAt(index);
    });
  }

  void _proceedToAnalysis() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap masukkan judul catatan.')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SummaryScreen(
          initialFiles: _files,
          documentTitle: title,
          folderId: _selectedFolderId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Pratinjau Dokumen'),
        actions: [
          if (!widget.isPdf)
            IconButton(
              icon: const Icon(Icons.add_photo_alternate_outlined),
              tooltip: 'Tambah Halaman',
              onPressed: _addMorePages,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Metadata Input Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: 'Judul Catatan',
                      hintText: 'Contoh: Kalkulus Pertemuan 4',
                      prefixIcon: const Icon(Icons.edit_note),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (_isLoadingFolders)
                    const LinearProgressIndicator()
                  else
                    DropdownButtonFormField<String>(
                      value: _selectedFolderId,
                      decoration: InputDecoration(
                        labelText: 'Kategori / Folder',
                        prefixIcon: const Icon(Icons.folder_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: _folders.map((f) {
                        return DropdownMenuItem(
                          value: f.id,
                          child: Text(f.name),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedFolderId = val),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Header Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Halaman Dokumen (${_files.length})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (!widget.isPdf)
                  TextButton.icon(
                    onPressed: _addMorePages,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Tambah'),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Pages Grid
            if (widget.isPdf)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.picture_as_pdf, color: Colors.deepOrange, size: 48),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _files.first.path.split(Platform.pathSeparator).last,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Dokumen PDF siap dianalisis',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.75,
                ),
                itemCount: _files.length,
                itemBuilder: (context, index) {
                  return Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.cardBorder),
                          image: DecorationImage(
                            image: FileImage(_files[index]),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 6,
                        left: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.65),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Hal. ${index + 1}',
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 6,
                        right: 6,
                        child: InkWell(
                          onTap: () => _removePage(index),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close, size: 16, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            const SizedBox(height: 32),

            // Proceed Button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _proceedToAnalysis,
                icon: const Icon(Icons.auto_awesome, color: Colors.white),
                label: const Text(
                  'Mulai Analisis AI Sekarang',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
