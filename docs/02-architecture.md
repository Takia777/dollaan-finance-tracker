# 2. Arsitektur

Dokumen ini menjelaskan gambaran besar Dollaan: komponen sistem, lapisan kode, navigasi, dan bagaimana data mengalir dari layar ke database lalu kembali lagi.

## Daftar isi
- [2.1 Gambaran sistem](#21-gambaran-sistem)
- [2.2 Lapisan kode](#22-lapisan-kode)
- [2.3 State management](#23-state-management)
- [2.4 Alur saat aplikasi dibuka](#24-alur-saat-aplikasi-dibuka)
- [2.5 Peta navigasi](#25-peta-navigasi)
- [2.6 Contoh alur data](#26-contoh-alur-data)
- [2.7 Keputusan arsitektur & trade-off](#27-keputusan-arsitektur--trade-off)

---

## 2.1 Gambaran sistem

```mermaid
flowchart TB
    subgraph Device["📱 Aplikasi Flutter (APK di tablet / HP)"]
        UI["Screens & widgets<br/>(lib/screens, lib/ui)"]
        ST["AppState<br/>ChangeNotifier"]
        BOT["Chatbot rule-based<br/>(lib/chatbot)"]
        RP["Repo<br/>(lib/data/repo.dart)"]
        UI <--> ST
        UI --> BOT
        BOT --> ST
        ST --> RP
    end
    subgraph Cloud["☁️ Supabase (region Singapore)"]
        AUTH["Auth<br/>email + password"]
        DB[("PostgreSQL<br/>+ Row Level Security")]
        STO["Storage<br/>bucket dollaan-images"]
    end
    RP -- "HTTPS · supabase_flutter" --> AUTH
    RP -- "REST (PostgREST)" --> DB
    RP -- "upload / public URL" --> STO
```

Poin pentingnya:

- **Tidak ada server buatan sendiri.** Supabase menyediakan database, login, dan penyimpanan file. Aplikasi berbicara langsung ke Supabase lewat library `supabase_flutter`.
- **Keamanan ada di database**, bukan di aplikasi. Setiap tabel punya aturan *Row Level Security* (RLS) sehingga pengguna hanya bisa membaca dan mengubah datanya sendiri — walaupun *publishable/anon key* tertanam di APK.
- **Chatbot berjalan di perangkat.** Tidak ada panggilan ke layanan AI, jadi tidak ada biaya per pesan.

## 2.2 Lapisan kode

```
lib/
├─ main.dart               ← titik masuk
├─ config.dart             ← konfigurasi (URL & key)
├─ theme.dart              ← palet warna, font, helper gaya
├─ models.dart             ← tipe data (Profile, Wallet, Txn, Goal, ChatMsg)
├─ categories.dart         ← data statis kategori
├─ utils/format.dart       ← format Rupiah & tanggal
├─ data/repo.dart          ← LAPISAN DATA: semua query Supabase
├─ state/app_state.dart    ← LAPISAN STATE/LOGIKA: data di memori + perhitungan
├─ chatbot/chatbot.dart    ← LOGIKA chatbot (murni Dart, mudah dites)
├─ ui/                     ← LAPISAN UI umum: widget, kartu, painter
└─ screens/                ← LAPISAN UI: satu file per layar
```

Aturan ketergantungan (dependency) dijaga searah:

```mermaid
flowchart LR
    screens --> ui
    screens --> state
    screens --> chatbot
    ui --> state
    state --> data
    data --> models
    state --> models
    chatbot --> models
```

- **Layar tidak pernah memanggil Supabase langsung.** Semua lewat `app` (AppState), yang memakai `Repo`.
- **`chatbot.dart` tidak bergantung pada Flutter.** Ia hanya memakai `models.dart`, sehingga bisa diuji dengan unit test biasa.
- **Perhitungan (saldo, statistik, streak) ada di AppState**, bukan di widget. Widget hanya menampilkan.

## 2.3 State management

Dollaan memakai pola paling sederhana yang disediakan Flutter: satu objek `ChangeNotifier` global.

```dart
// lib/state/app_state.dart
final app = AppState();

class AppState extends ChangeNotifier {
  Profile? profile;
  List<Wallet> wallets = [];
  List<Txn> txns = [];
  List<Goal> goals = [];
  ...
  Future<Txn> addTxn(...) async {
    final txn = await repo.insertTxn({...});   // 1. simpan ke Supabase
    txns = [txn, ...txns];                    // 2. perbarui data di memori
    notifyListeners();                        // 3. beri tahu semua layar
    return txn;
  }
}
```

Layar yang perlu ikut berubah membungkus tampilannya dengan `ListenableBuilder`:

```dart
ListenableBuilder(
  listenable: app,
  builder: (context, _) => BalanceText(app.totalBalance),
);
```

```mermaid
sequenceDiagram
    participant W as Widget (ListenableBuilder)
    participant A as AppState
    participant R as Repo
    participant S as Supabase
    W->>A: app.addTxn(...)
    A->>R: insertTxn(map)
    R->>S: INSERT ... RETURNING *
    S-->>R: baris baru
    R-->>A: Txn
    A->>A: txns = [txn, ...txns]
    A-->>W: notifyListeners()
    W->>W: build ulang → saldo baru tampil
```

**Kenapa bukan Riverpod/Bloc?** Untuk developer solo dan ukuran aplikasi ini, `ChangeNotifier` cukup, tanpa dependensi tambahan dan tanpa konsep baru yang harus dipelajari dulu. Kelemahannya: semua layar yang mendengarkan `app` ikut di-build ulang saat apa pun berubah. Untuk skala Dollaan ini tidak terasa. Kalau aplikasi membesar, `AppState` bisa dipecah (misalnya `WalletStore`, `GoalStore`) atau dipindah ke Riverpod tanpa mengubah `Repo`.

## 2.4 Alur saat aplikasi dibuka

```mermaid
flowchart TD
    A([Aplikasi dibuka]) --> B[main: Supabase.initialize]
    B --> C[SplashScreen · tunggu 1,2 detik]
    C --> D{Onboarding<br/>sudah dilihat?}
    D -- belum --> E[OnboardingScreen] --> F[AuthScreen]
    D -- sudah --> G{Ada sesi login?}
    G -- tidak --> F
    G -- ya --> H[app.loadAll]
    F -- login / daftar --> H
    H --> I{profile.setupDone?}
    I -- belum --> J[SetupScreen 3 langkah] --> K[Shell]
    I -- sudah --> K[Shell · Home]
```

- Status "sudah onboarding" disimpan di perangkat dengan `shared_preferences`.
- Sesi login disimpan otomatis oleh `supabase_flutter`, jadi pengguna tidak perlu login ulang setiap membuka aplikasi.
- `setup_done` disimpan di tabel `profiles`, sehingga setup tidak muncul lagi di perangkat lain.

## 2.5 Peta navigasi

```mermaid
flowchart LR
    Shell --> Home & Goals & Statistic & Settings
    Shell -- tombol tengah --> Chat[ChatScreen]

    Home --> Profile & Notifications & TopUp[Top Up] & Transfer & Expense & AddWallet[Add Wallet]
    Home -- More --> MoreSheet[More sheet]
    MoreSheet -- Saving mode --> Goals

    Goals --> GoalDetail[Goal detail] & NewGoal[New goal] & Achievements
    GoalDetail -- Add money, target tercapai --> GoalReached[Goal reached]
    GoalReached -- Pack it --> Pack[Pack animation] --> Achievements

    Statistic -- menu ⋮ Summarize --> Chat
    Settings --> Profile
```

`Shell` memakai `IndexedStack` sehingga keempat tab tetap "hidup" saat berpindah (posisi scroll tidak hilang). Tab aktif disimpan di `app.tab` (`ValueNotifier<int>`), sehingga layar lain bisa berpindah tab — misalnya kartu *Saving mode* di sheet More menjalankan `app.tab.value = 1`.

## 2.6 Contoh alur data

### Mencatat pengeluaran lewat layar Expense

```mermaid
sequenceDiagram
    actor U as Pengguna
    participant T as TransactionScreen
    participant A as AppState
    participant DB as Supabase (transactions)
    U->>T: pilih wallet, isi Rp 25.000, kategori Food
    U->>T: tekan "Save expense"
    T->>A: addTxn(kind: expense, amount: 25000, ...)
    A->>DB: INSERT (user_id diisi otomatis = auth.uid())
    DB-->>A: baris tersimpan
    A-->>T: notifyListeners → Home & Statistic ikut berubah
    T-->>U: kembali ke Home + snackbar "Expense saved!"
```

### Menabung ke goal sampai tercapai

```mermaid
sequenceDiagram
    actor U as Pengguna
    participant D as GoalDetailScreen
    participant A as AppState
    participant DB as Supabase
    U->>D: Add money Rp 200.000 dari Main Wallet
    D->>A: depositToGoal(goal, walletId, 200000)
    A->>DB: INSERT transactions (kind: goal, goal_id)
    A->>A: goalSaved(goal) >= target?
    alt target tercapai
        A->>DB: UPDATE goals SET status = 'reached'
        D-->>U: buka layar "Goal reached!"
    else belum
        D-->>U: snackbar "Saved Rp 200.000"
    end
```

### Mencatat lewat chatbot
Lihat diagram lengkap di [5. Chatbot](05-chatbot.md).

## 2.7 Keputusan arsitektur & trade-off

| Keputusan | Keuntungan | Kekurangan / risiko |
| --- | --- | --- |
| Supabase sebagai backend | Tanpa server sendiri, SQL penuh, paket gratis | Butuh internet; project gratis bisa di-*pause* jika lama tidak aktif |
| Saldo **dihitung** dari transaksi (tidak disimpan) | Saldo selalu konsisten dengan riwayat; hapus transaksi = saldo otomatis benar | Perhitungan di sisi aplikasi; untuk ribuan transaksi sebaiknya dipindah ke *view* SQL |
| Semua data dimuat sekali (`loadAll`) | Kode sederhana, layar cepat setelah dimuat | Tidak cocok untuk data sangat besar; perlu pagination nanti |
| Chatbot di perangkat | Gratis, cepat, bisa dites tanpa jaringan | Hanya memahami pola yang sudah ditulis |
| Notifikasi dihitung dari data (in-app) | Tidak perlu server push | Tidak muncul saat aplikasi tertutup |
| `ChangeNotifier` global | Mudah dipahami | Rebuild lebih luas dari perlu |

Lanjut ke **[3. Database →](03-database.md)**
