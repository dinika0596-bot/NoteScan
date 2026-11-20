import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notescan/features/auth/auth_screen.dart';

void main() {
  testWidgets('AuthScreen menampilkan form login dan opsi Masuk sebagai Tamu', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AuthScreen(),
      ),
    );

    // Verifikasi branding
    expect(find.text('NoteScan'), findsOneWidget);
    expect(find.text('Digitalisasi Catatan Cerdas Mahasiswa'), findsOneWidget);

    // Verifikasi kolom input login
    expect(find.byType(TextField), findsNWidgets(2)); // Email & Password
    expect(find.text('Masuk'), findsOneWidget);

    // Verifikasi opsi Guest Mode
    expect(find.text('Masuk sebagai Tamu (Coba Langsung)'), findsOneWidget);

    // Verifikasi toggle ke form pendaftaran
    final toggleButton = find.text('Belum punya akun? Daftar di sini');
    expect(toggleButton, findsOneWidget);

    // Tekan toggle pendaftaran
    await tester.tap(toggleButton);
    await tester.pumpAndSettle();

    // Sekarang harus ada 3 kolom input (Nama, Email, Password) dan tombol "Daftar Sekarang"
    expect(find.byType(TextField), findsNWidgets(3));
    expect(find.text('Daftar Sekarang'), findsOneWidget);
  });
}
