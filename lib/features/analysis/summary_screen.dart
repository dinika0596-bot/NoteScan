import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/supabase_service.dart';
import '../../core/network/gemini_service.dart';
import '../models/document_model.dart';
import '../chat/ask_document_screen.dart';

class SummaryScreen extends StatefulWidget {
  final DocumentModel? document;
  final List<File> initialFiles;
  final String? documentTitle;
  final String? folderId;

  const SummaryScreen({
    super.key,
    this.document,
    required this.initialFiles,
    this.documentTitle,
    this.folderId,
  });

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  final _geminiService = GeminiService();
  final _supabaseService = SupabaseService();

  bool _isAnalyzing = false;
  String _summary = '';
  List<String> _keyPoints = [];
  DocumentModel? _savedDoc;

  @override
  void initState() {
    super.initState();
    if (widget.document != null) {
      _savedDoc = widget.document;
      _summary = widget.document!.summary;
      _keyPoints = widget.document!.keyPoints;
    } else {
      _runAnalysis();
    }
  }

  Future<void> _runAnalysis() async {
    setState(() => _isAnalyzing = true);

    final result = await _geminiService.analyzeDocument(widget.initialFiles);

    // Otomatis unggah file dan simpan ke Supabase
    final uploadedUrls = await _supabaseService.uploadFiles(widget.initialFiles);
    final saved = await _supabaseService.saveDocument(
      title: widget.documentTitle ?? 'Catatan Pindai',
      fileUrls: uploadedUrls,
      summary: result.summary,
      keyPoints: result.keyPoints,
      folderId: widget.folderId,
    );

    if (mounted) {
      setState(() {
        _summary = result.summary;
        _keyPoints = result.keyPoints;
        _savedDoc = saved;
        _isAnalyzing = false;
      });
    }
  }

  void _copyToClipboard() {
    final text = '$_summary\n\nPoin-Poin Penting:\n${_keyPoints.map((p) => '- $p').join('\n')}';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ringkasan disalin ke papan klip!')),
    );
  }

  void _openAskDocument() {
    if (_savedDoc == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AskDocumentScreen(document: _savedDoc!),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = _savedDoc?.title ?? widget.documentTitle ?? 'Hasil Analisis';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          if (!_isAnalyzing)
            IconButton(
              icon: const Icon(Icons.copy),
              tooltip: 'Salin Ringkasan',
              onPressed: _copyToClipboard,
            ),
        ],
      ),
      body: _isAnalyzing
          ? Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(color: AppColors.primary, strokeWidth: 3),
                    const SizedBox(height: 24),
                    const Text(
                      'Gemini AI Sedang Menganalisis Dokumen...',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Mengekstrak tulisan tangan, rumus, merumuskan ringkasan singkat & poin-poin penting catatan.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badge Success
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, color: AppColors.success, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Analisis Dokumen Selesai',
                          style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Section Ringkasan Singkat
                  const Text(
                    'Ringkasan Singkat',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Text(
                      _summary,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.6,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Section Poin-Poin Penting
                  const Text(
                    'Poin-Poin Penting',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),

                  if (_keyPoints.isEmpty)
                    const Text('Tidak ada poin penting terdeteksi.', style: TextStyle(color: AppColors.textSecondary))
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _keyPoints.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.cardBorder),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                margin: const EdgeInsets.only(top: 2),
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                    color: AppColors.primaryDark,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _keyPoints[index],
                                  style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, height: 1.4),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                  const SizedBox(height: 36),

                  // Button Tanya Dokumen
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _openAskDocument,
                      icon: const Icon(Icons.forum, color: Colors.white),
                      label: const Text(
                        'Tanya Dokumen Ini (Chat AI)',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
