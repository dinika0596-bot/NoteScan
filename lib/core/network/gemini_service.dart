import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeminiAnalysisResult {
  final String summary;
  final List<String> keyPoints;

  GeminiAnalysisResult({
    required this.summary,
    required this.keyPoints,
  });
}

class GeminiService {
  static final GeminiService _instance = GeminiService._internal();
  factory GeminiService() => _instance;
  GeminiService._internal();

  GenerativeModel? _model;
  String? _apiKey;

  void init() {
    _apiKey = dotenv.env['GEMINI_API_KEY'];
    final modelName = dotenv.env['GEMINI_MODEL'] ?? 'gemini-1.5-flash';

    if (_apiKey != null && _apiKey!.isNotEmpty && !_apiKey!.startsWith('placeholder')) {
      _model = GenerativeModel(
        model: modelName,
        apiKey: _apiKey!,
      );
    }
  }

  bool get isConfigured => _model != null;

  /// Menganalisis file dokumen (multi-halaman gambar/PDF) menggunakan Gemini Multimodal
  Future<GeminiAnalysisResult> analyzeDocument(List<File> imageFiles) async {
    if (!isConfigured) {
      // Mock Fallback jika API Key belum diisi
      await Future.delayed(const Duration(seconds: 2));
      return GeminiAnalysisResult(
        summary: 'Catatan ini merangkum materi perkuliahan terkait konsep-konsep kunci dan penerapannya secara terstruktur. Analisis visual menunjukkan diagram alur kerja dan formula pendukung yang penting untuk dipelajari.',
        keyPoints: [
          'Definisi dasar dan tujuan pembelajaran utama.',
          'Hubungan sebab-akibat antara variabel dalam catatan.',
          'Langkah-langkah sistematis penyelesaian studi kasus.',
          'Ringkasan rumus / persamaan penting yang dicatat.',
        ],
      );
    }

    try {
      final List<Part> parts = [];

      // Masukkan instruksi prompt khusus untuk mahasiswa
      const prompt = '''
Anda adalah asisten cerdas "NoteScan" untuk mahasiswa dan pelajar.
Tugas Anda adalah membaca dan menganalisis foto catatan pelajaran / dokumen multi-halaman ini secara teliti (termasuk tulisan tangan, tabel, diagram, atau teks cetak).

Berikan output dengan format berikut:
[RINGKASAN]
Tuliskan ringkasan singkat dan padat (maksimal 2-3 paragraf) yang menjelaskan intisari materi catatan ini dalam Bahasa Indonesia yang lugas dan mudah dipahami mahasiswa.

[POIN_PENTING]
- Tuliskan 3 hingga 6 poin-poin paling penting / konsep kunci / rumus / definisi esensial dalam bentuk bullet points (awali setiap baris poin dengan tanda strip "-").
''';

      parts.add(TextPart(prompt));

      // Tambahkan setiap file ke payload multimodal
      for (final file in imageFiles) {
        final bytes = await file.readAsBytes();
        final ext = file.path.split('.').last.toLowerCase();
        String mimeType = 'image/jpeg';
        if (ext == 'png') {
          mimeType = 'image/png';
        } else if (ext == 'webp') {
          mimeType = 'image/webp';
        } else if (ext == 'pdf') {
          mimeType = 'application/pdf';
        }
        parts.add(DataPart(mimeType, bytes));
      }

      final content = [Content.multi(parts)];
      
      // Menggunakan timeout 45 detik agar terhindar dari hang saat koneksi lambat
      final response = await _model!.generateContent(content).timeout(
        const Duration(seconds: 45),
        onTimeout: () => throw Exception('Permintaan analisis AI melebihi batas waktu (timeout).'),
      );
      final text = response.text ?? '';

      return parseGeminiResponse(text);
    } catch (e) {
      debugPrint('Gemini Error: $e');
      return GeminiAnalysisResult(
        summary: 'Catatan terdeteksi, namun terjadi kendala koneksi saat menghubungi AI: ${e.toString()}.\nSilakan periksa koneksi internet atau validitas GEMINI_API_KEY.',
        keyPoints: [
          'Dokumen fisik berhasil ditangkap dan disimpan.',
          'Pastikan format gambar jelas dan memiliki pencahayaan cukup.',
          'Periksa kuota atau kunci GEMINI_API_KEY pada berkas .env.',
        ],
      );
    }
  }

  /// Fitur "Tanya Dokumen" — Bertanya kepada Gemini berdasarkan dokumen & riwayat
  Future<String> askDocument({
    required String documentSummary,
    required List<String> keyPoints,
    required String question,
    List<Map<String, String>> chatHistory = const [],
  }) async {
    if (!isConfigured) {
      await Future.delayed(const Duration(milliseconds: 800));
      return 'Jawaban (Demo Mode): Berdasarkan ringkasan catatan Anda, konsep utama yang ditanyakan berkaitan erat dengan topik perkuliahan tersebut. Silakan masukkan GEMINI_API_KEY di file .env untuk jawaban analisis AI cerdas secara live.';
    }

    try {
      final historyPrompt = StringBuffer();
      for (final msg in chatHistory) {
        historyPrompt.writeln('${msg['role'] == 'user' ? 'Mahasiswa' : 'Asisten'}: ${msg['content']}');
      }

      final prompt = '''
Anda adalah Asisten Tanya Dokumen di aplikasi NoteScan.
Konteks Catatan Mahasiswa:
Ringkasan: $documentSummary
Poin Penting:
${keyPoints.map((p) => '- $p').join('\n')}

Riwayat Percakapan:
$historyPrompt

Pertanyaan Mahasiswa:
$question

Jawablah pertanyaan di atas secara langsung, ringkas, jelas, dan edukatif berdasarkan isi catatan dokumen tersebut dalam Bahasa Indonesia.
''';

      final response = await _model!.generateContent([Content.text(prompt)]).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw Exception('Waktu respon Tanya Dokumen habis.'),
      );
      return response.text ?? 'Maaf, tidak dapat menghasilkan jawaban.';
    } catch (e) {
      return 'Terjadi kendala saat menjawab pertanyaan: $e';
    }
  }

  /// Parser terstruktur respons teks Gemini (dibuat publik untuk mempermudah unit testing)
  GeminiAnalysisResult parseGeminiResponse(String rawText) {
    String summary = '';
    List<String> keyPoints = [];

    final cleanText = rawText.replaceAll('\r\n', '\n').trim();

    if (cleanText.contains('[RINGKASAN]') && cleanText.contains('[POIN_PENTING]')) {
      final parts = cleanText.split('[POIN_PENTING]');
      summary = parts[0].replaceAll('[RINGKASAN]', '').trim();

      if (parts.length > 1) {
        final pointsRaw = parts[1].trim().split('\n');
        for (var line in pointsRaw) {
          line = line.trim();
          if (line.startsWith('-') || line.startsWith('*')) {
            keyPoints.add(line.substring(1).trim());
          } else if (RegExp(r'^\d+[\.\)]').hasMatch(line)) {
            keyPoints.add(line.replaceFirst(RegExp(r'^\d+[\.\)]\s*'), '').trim());
          } else if (line.isNotEmpty) {
            keyPoints.add(line);
          }
        }
      }
    } else {
      // Fallback jika model menjawab dalam format teks bebas tanpa tag
      final lines = cleanText.split('\n').where((l) => l.trim().isNotEmpty).toList();
      if (lines.length > 2) {
        summary = lines.take(2).join('\n\n');
        keyPoints = lines.skip(2).map((l) => l.replaceAll(RegExp(r'^[-*\d\.\)]\s*'), '')).toList();
      } else {
        summary = cleanText;
        keyPoints = [
          'Konsep penting diekstrak dari catatan visual.',
          'Silakan gunakan fitur Tanya Dokumen untuk eksplorasi lebih lanjut.',
        ];
      }
    }

    return GeminiAnalysisResult(summary: summary, keyPoints: keyPoints);
  }
}
