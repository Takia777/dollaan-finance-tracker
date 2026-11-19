# 6. Panduan Setup (Windows)

Langkah lengkap menjalankan Dollaan dari nol sampai APK terpasang di tablet/HP Android. Ditulis untuk Windows 10/11, termasuk masalah yang benar-benar terjadi selama pengembangan.

## Daftar isi
- [6.1 Yang perlu disiapkan](#61-yang-perlu-disiapkan)
- [6.2 Install Flutter & Android SDK](#62-install-flutter--android-sdk)
- [6.3 Siapkan project](#63-siapkan-project)
- [6.4 Siapkan Supabase](#64-siapkan-supabase)
- [6.5 Hubungkan aplikasi ke Supabase](#65-hubungkan-aplikasi-ke-supabase)
- [6.6 Menjalankan aplikasi](#66-menjalankan-aplikasi)
- [6.7 Build & pasang APK](#67-build--pasang-apk)
- [6.8 Troubleshooting](#68-troubleshooting)
- [6.9 Sebelum publish ke GitHub](#69-sebelum-publish-ke-github)

---

## 6.1 Yang perlu disiapkan

| Kebutuhan | Keterangan |
| --- | --- |
| **Ruang disk** | ±15 GB kosong (Flutter, Android SDK, emulator, cache Gradle). Lihat [disk penuh](#disk-c-penuh--build-gagal) |
| **Flutter SDK** | 3.27 atau lebih baru (Dart 3.4+) |
| **Android Studio** | Untuk Android SDK dan emulator (tidak wajib dipakai untuk menulis kode) |
| **VS Code** | Editor, dengan ekstensi *Flutter* (otomatis memasang *Dart*) |
| **Git** | Untuk clone repo |
| **Akun Supabase** | Gratis, di [supabase.com](https://supabase.com) |
| **HP/tablet Android** | Opsional; bisa juga emulator atau browser Chrome |

> **Apa bedanya?** *Flutter SDK* = alat untuk membuat dan menjalankan aplikasi. *Android SDK* = alat dari Google untuk membangun aplikasi Android (dipakai Flutter di belakang layar). *IDE* (Android Studio, VS Code) = aplikasi editor tempat menulis kode.

## 6.2 Install Flutter & Android SDK

1. **Cek apakah Flutter sudah pernah terpasang.** Buka PowerShell:
   ```powershell
   flutter --version
   where.exe flutter
   ```
   Kalau muncul versi, Flutter sudah ada (cukup jalankan `flutter upgrade`). Kalau `not recognized`, lanjut ke langkah 2.
2. **Install Flutter.** Cara termudah: di VS Code, install ekstensi **Flutter** → `Ctrl+Shift+P` → *Flutter: New Project* → pilih *Download SDK*. Simpan di folder tanpa spasi, misalnya `D:\dev\flutter` (jangan di `C:\Program Files`). Izinkan VS Code menambahkannya ke PATH.
3. **Install Android Studio**, buka sekali, lalu ikuti *Setup Wizard* (memasang Android SDK, platform tools, dan emulator).
   Di *More Actions → SDK Manager → SDK Tools*, centang **Android SDK Command-line Tools**.
4. **Terima lisensi & periksa:**
   ```powershell
   flutter doctor --android-licenses   # ketik y untuk semua
   flutter doctor
   ```
   Targetnya centang hijau untuk *Flutter*, *Android toolchain*, dan *Chrome*. *Visual Studio* boleh merah (hanya untuk aplikasi desktop Windows).

## 6.3 Siapkan project

```powershell
git clone https://github.com/<username>/dollaan.git
cd dollaan
flutter create --org com.dollaan --project-name dollaan --platforms android,web .
flutter pub get
```

`flutter create .` hanya diperlukan **jika folder `android/` (atau `web/`) belum ada** di repo. Perintah ini membuat folder platform di project yang sudah ada **tanpa menimpa** `lib/` dan `pubspec.yaml`.

**Izin internet (wajib untuk APK).** Buka `android/app/src/main/AndroidManifest.xml` dan tambahkan baris ini tepat **di atas** `<application`:
```xml
<uses-permission android:name="android.permission.INTERNET"/>
```
Tanpa baris ini, aplikasi berjalan normal saat `flutter run` (mode debug), tetapi APK *release* tidak bisa terhubung ke Supabase.

## 6.4 Siapkan Supabase

1. Masuk ke [supabase.com/dashboard](https://supabase.com/dashboard) → **New project**.
   - *Name*: `dollaan`
   - *Database password*: buat dan simpan (tidak dipakai aplikasi, tapi dibutuhkan untuk akses database langsung)
   - *Region*: **Southeast Asia (Singapore)** — paling dekat dengan Indonesia
   - Tunggu ±2 menit sampai project siap.
2. **Jalankan skema.** Menu kiri **SQL Editor** → **New query** → salin seluruh isi [`supabase/schema.sql`](../supabase/schema.sql) → **Run**. Harus muncul *Success. No rows returned*.
   Periksa di **Table Editor**: ada tabel `profiles`, `wallets`, `goals`, `transactions`, `chat_messages`, masing-masing berlabel RLS aktif. Di **Storage** ada bucket `dollaan-images`.
3. **Aktifkan login email.** **Authentication → Sign In / Providers**:
   - Pastikan *Allow new users to sign up* aktif (bagian *User Signups*).
   - Untuk uji coba, **matikan *Confirm email*** (juga di bagian *User Signups*) agar akun langsung bisa dipakai tanpa membuka email.
   - Buka provider **Email** → pastikan *Enabled* → **Save**.
4. **Data API.** Biarkan pengaturan bawaan (*Settings → Data API*, schema `public` terekspos). Tidak ada yang perlu diisi.

## 6.5 Hubungkan aplikasi ke Supabase

Ambil dua nilai dari **Project Settings → API Keys** (atau tombol **Connect** di atas dashboard):

| Nilai | Contoh | Catatan |
| --- | --- | --- |
| **Project URL** | `https://abcdxyz.supabase.co` | Hanya alamat dasar, **tanpa** `/rest/v1` atau `/auth/v1` |
| **Publishable key** | `sb_publishable_...` | Atau *anon key* lama (`eyJhbGci...`) di tab *Legacy API Keys*. Keduanya boleh |

**Pilihan A — `--dart-define` (disarankan, key tidak masuk kode):**
```powershell
flutter run --dart-define=SUPABASE_URL=https://abcdxyz.supabase.co --dart-define=SUPABASE_ANON_KEY=sb_publishable_xxx
```
Agar tidak mengetik ulang, simpan perintah di file `run.ps1` lokal atau `.vscode/launch.json` — keduanya sudah diabaikan oleh `.gitignore`.

**Pilihan B — tulis langsung** di `lib/config.dart` pada `defaultValue`. Lebih praktis, tapi ingat [aturan sebelum publish](#69-sebelum-publish-ke-github).

> ❌ Jangan pernah memakai **secret key** / **service_role key**. Key itu melewati semua RLS dan hanya untuk server.

## 6.6 Menjalankan aplikasi

```powershell
flutter test            # 1. pastikan unit test lulus
flutter devices         # 2. lihat perangkat yang tersedia
flutter run -d chrome   # 3a. coba cepat di browser
flutter run             # 3b. ke HP/tablet (USB debugging) atau emulator
```

**Menjalankan di HP/tablet lewat kabel:**
1. *Settings → About → Software information* → ketuk **Build number** 7× sampai *Developer mode* aktif.
2. *Developer options* → aktifkan **USB debugging**.
3. Colok USB, izinkan dialog *Allow USB debugging* di perangkat. `flutter devices` akan menampilkannya.

Saat aplikasi berjalan, tekan `r` di terminal untuk *hot reload*, `R` untuk *hot restart*, `q` untuk keluar.

## 6.7 Build & pasang APK

```powershell
flutter build apk --release --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
```
Hasilnya di `build\app\outputs\flutter-apk\app-release.apk` (±20 MB). Untuk ukuran lebih kecil per arsitektur: `flutter build apk --split-per-abi` (pakai file `arm64-v8a` untuk perangkat modern).

**Memasang di tablet:**
- Kirim file APK lewat Google Drive / WhatsApp / kabel, buka di tablet → izinkan *Install unknown apps* untuk aplikasi pembuka → **Install**.
- Atau langsung lewat kabel: `flutter install`.
- Play Protect mungkin memperingatkan karena aplikasi tidak dari Play Store → *Install anyway*.

APK release ditandatangani dengan *debug key* bawaan Flutter — cukup untuk uji coba pribadi, tidak untuk Play Store.

## 6.8 Troubleshooting

### Disk C penuh → build gagal
**Gejala:** `flutter run -d chrome` atau build gagal dengan pesan seperti `There is not enough space on the disk` / `FileSystemException ... errno = 112`, padahal kode tidak berubah.

**Penyebab:** Flutter, Gradle, dan compiler menulis file sementara ke `C:\Users\<nama>\AppData\Local\Temp` dan cache ke folder user di C. Kalau drive C tinggal 0 byte, kompilasi gagal.

**Solusi:**
1. Kosongkan ruang C: *Settings → System → Storage → Temporary files*, Disk Cleanup (*Clean up system files*), hapus isi `%TEMP%`, kosongkan Recycle Bin.
2. Pindahkan folder sementara ke drive lain (misal D). Di PowerShell:
   ```powershell
   mkdir D:\Temp
   [Environment]::SetEnvironmentVariable("TEMP", "D:\Temp", "User")
   [Environment]::SetEnvironmentVariable("TMP",  "D:\Temp", "User")
   ```
   Tutup dan buka lagi VS Code/terminal.
3. Opsional: pindahkan cache Gradle dan pub ke D dengan variabel `GRADLE_USER_HOME=D:\gradle` dan `PUB_CACHE=D:\pub-cache`.
4. Jika ingin menggabungkan partisi (misal menghapus partisi E untuk menambah C), gunakan **Disk Management** (klik kanan tombol Start → *Disk Management*). *Extend Volume* pada C hanya bisa jika ruang kosong (*Unallocated*) berada **tepat di sebelah kanan** C. Pindahkan semua file dulu dan **backup** sebelum menghapus partisi.

### Login error 404
**Gejala:** muncul error 404 / `Not Found` saat login atau daftar.
**Penyebab:** `SUPABASE_URL` diisi dengan alamat yang salah, misalnya berakhiran `/rest/v1/` atau alamat dashboard.
**Solusi:** pakai alamat dasar saja: `https://<project-ref>.supabase.co`.

### `email_provider_disabled` / "Email signups are disabled" / "Email logins are disabled"
**Penyebab:** provider Email belum aktif atau pendaftaran baru dimatikan.
**Solusi:** *Authentication → Sign In / Providers* → aktifkan *Allow new users to sign up* → buka **Email** → *Enabled* → **Save** (perubahan belum berlaku sebelum disimpan).

### Daftar berhasil tapi tidak bisa login ("Email not confirmed")
**Penyebab:** *Confirm email* aktif, jadi akun harus dikonfirmasi lewat email dulu.
**Solusi:** buka email konfirmasi, atau matikan *Confirm email* untuk masa uji coba, atau konfirmasi manual di *Authentication → Users*.

### "Apakah data saya benar-benar masuk ke Supabase?"
Cek di **Table Editor → transactions** (atau tabel lain). Data dari semua pengguna terlihat di dashboard karena dashboard memakai akses admin; di aplikasi, RLS memastikan setiap pengguna hanya melihat datanya.

### `permission denied for table ...` / data kosong padahal sudah ada
Skema belum dijalankan lengkap (RLS aktif tanpa policy, atau *grants* untuk role `anon`/`authenticated` hilang). Jalankan ulang `schema.sql` (aman dijalankan berulang). Jika masih, periksa *Settings → Data API* bahwa schema `public` terekspos.

### APK tidak bisa terhubung, padahal `flutter run` lancar
Izin internet belum ditambahkan di `AndroidManifest.xml` (lihat [6.3](#63-siapkan-project)).

### Project Supabase "paused"
Project gratis dijeda otomatis setelah lama tidak aktif. Buka dashboard → **Restore project**.

## 6.9 Sebelum publish ke GitHub

Checklist:
- [ ] `lib/config.dart` berisi **placeholder** (`YOUR-PROJECT-ID`, `YOUR-ANON-KEY`), atau paling tidak hanya **publishable/anon key** — tidak pernah *secret/service_role key*.
- [ ] Tidak ada file `.env`, `key.properties`, `*.jks`, atau `google-services.json` yang ter-commit (sudah tercantum di `.gitignore`).
- [ ] Folder `build/` dan `.dart_tool/` tidak ikut (sudah diabaikan `.gitignore`).
- [ ] Screenshot tidak menampilkan email/data pribadi.

Kalau key sudah terlanjur ter-commit, menghapusnya di commit berikutnya **tidak cukup** (masih ada di riwayat Git). Buat key baru di Supabase (*API Keys → Create new*) dan nonaktifkan yang lama.

Lanjut ke **[7. Kendala & pelajaran →](07-challenges-and-lessons.md)**
