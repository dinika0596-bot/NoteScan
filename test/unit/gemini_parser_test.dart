import 'package:flutter_test/flutter_test.dart';
import 'package:notescan/core/network/gemini_service.dart';

void main() {
  group('GeminiService - Parser Unit Tests', () {
    late GeminiService geminiService;

    setUp(() {
      geminiService = GeminiService();
    });

    test('Harus mem-parse format standar [RINGKASAN] dan [POIN_PENTING] dengan benar', () {
      const rawOutput = '''
[RINGKASAN]
Ini adalah ringkasan catatan kuliah fisika mengenai hukum termodinamika pertama dan kekekalan energi.

[POIN_PENTING]
- Energi tidak dapat diciptakan atau dimusnahkan.
- Kalor yang masuk sama dengan perubahan energi dalam ditambah kerja.
- Rumus: Delta U = Q - W.
''';

      final result = geminiService.parseGeminiResponse(rawOutput);

      expect(result.summary, contains('hukum termodinamika pertama'));
      expect(result.keyPoints.length, 3);
      expect(result.keyPoints[0], 'Energi tidak dapat diciptakan atau dimusnahkan.');
      expect(result.keyPoints[2], 'Rumus: Delta U = Q - W.');
    });

    test('Harus mampu mem-parse poin penting dengan format penomoran angka atau bintang', () {
      const rawOutput = '''
[RINGKASAN]
Ringkasan tentang biologi sel dan struktur membran.

[POIN_PENTING]
1. Membran sel tersusun dari lapisan fosfolipid ganda.
2. Protein transmembran berfungsi sebagai reseptor dan saluran.
* Kolesterol menjaga fluiditas membran pada berbagai suhu.
''';

      final result = geminiService.parseGeminiResponse(rawOutput);

      expect(result.summary, contains('biologi sel'));
      expect(result.keyPoints.length, 3);
      expect(result.keyPoints[0], 'Membran sel tersusun dari lapisan fosfolipid ganda.');
      expect(result.keyPoints[1], 'Protein transmembran berfungsi sebagai reseptor dan saluran.');
      expect(result.keyPoints[2], 'Kolesterol menjaga fluiditas membran pada berbagai suhu.');
    });

    test('Harus memberikan fallback anggun jika respons AI tidak memiliki tag header', () {
      const rawOutput = '''
Catatan ini berisi ringkasan kalkulus diferensial.
Turunan fungsi menunjukkan laju perubahan sesaat.
Rumus turunan fungsi pangkat: d/dx(x^n) = n*x^(n-1).
Aturan rantai digunakan untuk fungsi komposisi.
''';

      final result = geminiService.parseGeminiResponse(rawOutput);

      expect(result.summary.isNotEmpty, true);
      expect(result.keyPoints.isNotEmpty, true);
    });
  });
}
