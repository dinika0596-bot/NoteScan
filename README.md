# NoteScan 📱📝

**NoteScan** adalah aplikasi mobile Android (Flutter) yang dirancang khusus untuk mahasiswa dan pelajar guna mendigitalisasi, meringkas, dan mendiskusikan catatan perkuliahan secara cerdas menggunakan kekuatan **Google Gemini Multimodal AI** dan cloud database **Supabase**.

---

## 🚀 Fitur Unggulan

1. **Pemindaian Dokumen Fleksibel & Multi-Halaman**:
   - Ambil foto catatan lembar fisik via kamera langsung.
   - Unggah beberapa foto sekaligus dari galeri.
   - Impor dokumen / slide perkuliahan berformat PDF.
2. **Analisis Cerdas Google Gemini Flash**:
   - Membaca tulisan tangan, rumus matematika, tabel, dan diagram.
   - **Ringkasan Singkat**: Intisari materi yang lugas dan padat.
   - **Poin-Poin Penting**: Konsep kunci bernomor urut untuk belajar cepat menjelang ujian.
3. **Tanya Dokumen (Interactive Q&A Chat)**:
   - Chatbot AI interaktif yang memahami isi catatan secara spesifik.
   - Tombol saran pertanyaan cepat (*quick prompt pills*).
   - Riwayat percakapan tersimpan rapi di Supabase Cloud.
4. **Pustaka Dokumen (Library)**:
   - Manajemen CRUD (buka catatan, ubah judul, hapus).
   - Pengelompokan Kategori / Folder sederhana (misal: Mata Kuliah).
   - Pencarian cepat berbasis judul catatan.
5. **Autentikasi & Mode Tamu**:
   - Masuk / Daftar via Supabase Auth (Email & Kata Sandi).
   - Opsi *Masuk sebagai Tamu* (Guest Mode) untuk langsung mencoba tanpa login.

---

## 🛠️ Struktur Proyek (Clean Architecture)

```
notescan/
├── android/app/src/main/AndroidManifest.xml  # Izin Kamera, Storage, Internet
├── lib/
│   ├── core/
│   │   ├── constants/                       # Warna tema, string konstanta
│   │   └── network/                         # SupabaseService & GeminiService
│   ├── features/
│   │   ├── auth/                            # Layar Login & Guest Mode
│   │   ├── dashboard/                       # Dashboard utama & aksi cepat
│   │   ├── scan/                            # Pratinjau multi-halaman & input metadata
│   │   ├── analysis/                        # Layar Ringkasan Singkat & Poin Penting
│   │   ├── chat/                            # Fitur Tanya Dokumen (Chat AI)
│   │   ├── library/                         # Pustaka dokumen, pencarian judul, filter folder
│   │   └── models/                          # DocumentModel, FolderModel, ChatMessageModel
│   └── main.dart                            # Titik masuk aplikasi & Splash Screen
├── .env.example                             # Template konfigurasi API
├── pubspec.yaml                             # Konfigurasi dependensi Flutter
└── supabase_schema.sql                      # Skrip DDL PostgreSQL & RLS Supabase
```

---

## ⚙️ Panduan Menjalankan Aplikasi

### 1. Persiapan Kredensial (.env)
Buka file `.env` di root proyek dan lengkapi kredensial Anda:
```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-supabase-anon-key
GEMINI_API_KEY=your-google-gemini-api-key
GEMINI_MODEL=gemini-1.5-flash
```

> **Catatan:** Jika file `.env` belum diisi, aplikasi tetap dapat dijalankan secara lancar menggunakan **Mode Demo / Tamu** bawaan.

### 2. Konfigurasi Database Supabase
1. Buka [Dashboard Supabase](https://supabase.com/dashboard).
2. Pilih proyek Anda, buka menu **SQL Editor**.
3. Buka file `supabase_schema.sql` pada proyek ini, salin seluruh isinya, dan klik **Run**.
4. Buka menu **Storage**, buat bucket baru bernama `notescan-files`.

### 3. Menjalankan Aplikasi di Android
Jalankan perintah berikut di terminal:
```bash
# Mengunduh dependensi
flutter pub get

# Menjalankan aplikasi pada perangkat Android / Emulator
flutter run
```

---

## 💡 Rekomendasi Workspace
Untuk pengalaman pengembangan terbaik di Antigravity IDE, buka direktori proyek ini sebagai workspace aktif:
`C:\Users\HP\.gemini\antigravity\scratch\notescan`
