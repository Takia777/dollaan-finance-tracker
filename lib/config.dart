/// Isi dua nilai ini dengan data dari Supabase:
/// Dashboard → Project Settings → API → "Project URL" dan "anon public key".
///
/// Anon key memang aman diletakkan di aplikasi, karena data tetap dilindungi
/// Row Level Security (lihat supabase/schema.sql).
///
/// Alternatif tanpa mengubah file ini:
/// flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
class AppConfig {
  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://GANTI-PROJECT-ID.supabase.co',
  );
  static const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_GANTI_DENGAN_KEY_KAMU',
  );

  static const storageBucket = 'dollaan-images';
}
