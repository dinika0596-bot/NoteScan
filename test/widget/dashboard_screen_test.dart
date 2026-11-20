import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notescan/features/dashboard/dashboard_screen.dart';

void main() {
  testWidgets('DashboardScreen menampilkan kartu aksi cepat Kamera, Galeri, dan PDF', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: DashboardScreen(),
      ),
    );

    // Verifikasi App Bar & Branding
    expect(find.text('NoteScan'), findsOneWidget);

    // Tunggu load dokumen selesai (menggunakan pump)
    await tester.pump();

    // Verifikasi 3 Aksi Utama
    expect(find.text('Kamera'), findsOneWidget);
    expect(find.text('Galeri'), findsOneWidget);
    expect(find.text('File PDF'), findsOneWidget);

    // Verifikasi Bagian Catatan Terkini
    expect(find.text('Catatan Terkini'), findsOneWidget);
  });
}
