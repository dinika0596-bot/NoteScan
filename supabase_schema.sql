-- ========================================================
-- NoteScan: Supabase Cloud Database Schema & RLS Setup
-- Jalankan skrip ini di SQL Editor pada Dashboard Supabase Anda
-- ========================================================

-- 1. Tabel Profil Pengguna (Sinkronisasi dengan auth.users)
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID REFERENCES auth.users ON DELETE CASCADE PRIMARY KEY,
    email TEXT,
    full_name TEXT,
    is_guest BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Trigger otomatis membuat profile saat user mendaftar
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.profiles (id, email, full_name, is_guest)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'full_name', 'Student User'),
    COALESCE((NEW.raw_user_meta_data->>'is_guest')::boolean, false)
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 2. Tabel Folder / Tag Kategori
CREATE TABLE IF NOT EXISTS public.folders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users ON DELETE CASCADE NOT NULL,
    name TEXT NOT NULL,
    color_hex TEXT DEFAULT '#4F46E5',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Tabel Dokumen Catatan
CREATE TABLE IF NOT EXISTS public.documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users ON DELETE CASCADE NOT NULL,
    folder_id UUID REFERENCES public.folders ON DELETE SET NULL,
    title TEXT NOT NULL,
    file_urls TEXT[] NOT NULL DEFAULT '{}',
    summary TEXT,
    key_points JSONB DEFAULT '[]'::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. Tabel Riwayat Chat Tanya Dokumen
CREATE TABLE IF NOT EXISTS public.document_chats (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    document_id UUID REFERENCES public.documents ON DELETE CASCADE NOT NULL,
    user_id UUID REFERENCES auth.users ON DELETE CASCADE NOT NULL,
    role TEXT NOT NULL CHECK (role IN ('user', 'model')),
    message TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indeks Kinerja
CREATE INDEX IF NOT EXISTS idx_documents_title ON public.documents (title);
CREATE INDEX IF NOT EXISTS idx_documents_user ON public.documents (user_id);
CREATE INDEX IF NOT EXISTS idx_document_chats_doc ON public.document_chats (document_id);

-- Aktifkan Row Level Security (RLS)
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.folders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.document_chats ENABLE ROW LEVEL SECURITY;

-- RLS Policies
DROP POLICY IF EXISTS "Users can manage own profile" ON public.profiles;
CREATE POLICY "Users can manage own profile" ON public.profiles
    FOR ALL USING (auth.uid() = id);

DROP POLICY IF EXISTS "Users can manage own folders" ON public.folders;
CREATE POLICY "Users can manage own folders" ON public.folders
    FOR ALL USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can manage own documents" ON public.documents;
CREATE POLICY "Users can manage own documents" ON public.documents
    FOR ALL USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can manage own chats" ON public.document_chats;
CREATE POLICY "Users can manage own chats" ON public.document_chats
    FOR ALL USING (auth.uid() = user_id);

-- Storage Bucket Setup (Storage -> Buckets -> Buat bucket 'notescan-files' (Private))
-- Policy Storage SQL (opsional):
-- INSERT INTO storage.buckets (id, name, public) VALUES ('notescan-files', 'notescan-files', false) ON CONFLICT DO NOTHING;
