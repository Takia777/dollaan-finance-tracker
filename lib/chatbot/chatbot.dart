import '../models.dart';

/// Chatbot rule-based Dollaan.
///
/// Hanya memahami 4 perintah: catat pemasukan, catat pengeluaran,
/// transfer antar wallet, dan ringkasan bulanan. Kalimat lain dibalas
/// dengan pesan "belum mengerti".
enum BotIntent { income, expense, transfer, summary, help, unknown }

class ParsedCommand {
  BotIntent intent;
  double? amount;
  String? category;
  Wallet? wallet; // wallet sumber (atau wallet tujuan untuk pemasukan)
  Wallet? toWallet; // khusus transfer
  String note;
  DateTime when;
  bool lastMonth; // khusus ringkasan

  ParsedCommand({
    required this.intent,
    this.amount,
    this.category,
    this.wallet,
    this.toWallet,
    this.note = '',
    DateTime? when,
    this.lastMonth = false,
  }) : when = when ?? DateTime.now();

  /// Data apa yang masih kurang sebelum transaksi bisa dibuat.
  String? get missing {
    if (intent == BotIntent.income ||
        intent == BotIntent.expense ||
        intent == BotIntent.transfer) {
      if (amount == null) return 'amount';
      if (wallet == null) return 'wallet';
      if (intent == BotIntent.transfer && toWallet == null) return 'toWallet';
    }
    return null;
  }
}

class ChatParser {
  static final _amountRe =
      RegExp(r'(?:rp\.?\s*)?(\d+(?:[.,]\d+)*)\s*(rb|ribu|k|jt|juta)?(?![a-z])');

  static const _summaryWords = [
    'rekap', 'ringkasan', 'summary', 'laporan', 'pengeluaranku', 'habis berapa',
  ];
  static const _transferWords = [
    'pindah', 'pindahin', 'transfer', 'tf ', 'kirim ke', 'tabung ke', 'mutasi', 'geser',
  ];
  static const _incomeWords = [
    'dapat', 'dapet', 'gajian', 'gaji', 'top up', 'topup', 'masuk', 'dikasih',
    'terima', 'uang saku', 'nemu', 'bonus', 'jualan', 'jual ', 'pemasukan',
  ];
  static const _expenseWords = [
    'beli', 'bayar', 'jajan', 'habis', 'keluar', 'makan', 'ngopi', 'isi bensin',
    'belanja', 'traktir', 'pengeluaran', 'nonton', 'langganan',
  ];

  static const _expenseCategoryWords = <String, List<String>>{
    'Food': [
      'makan', 'nasi', 'kopi', 'ngopi', 'jajan', 'minum', 'bakso', 'mie', 'ayam',
      'snack', 'sarapan', 'lunch', 'dinner', 'martabak', 'padang', 'boba', 'roti',
    ],
    'Transport': [
      'gojek', 'grab', 'ojol', 'bensin', 'bus', 'kereta', 'parkir', 'tol ', 'e-toll', 'angkot',
      'transport', 'krl', 'taksi', 'travel',
    ],
    'Shopping': ['baju', 'sepatu', 'belanja', 'shopee', 'tokopedia', 'skincare', 'kaos', 'tas'],
    'Bills': ['listrik', 'wifi', 'internet', 'pulsa', 'kuota', 'token', 'kos ', 'sewa', 'tagihan', 'pdam'],
    'Fun': ['nonton', 'film', 'game', 'konser', 'karaoke', 'netflix', 'spotify', 'langganan'],
    'Gift': ['kado', 'hadiah', 'traktir', 'sumbangan'],
    'Study': ['buku', 'fotokopi', 'print', 'kuliah', 'ukt', 'kursus', 'praktikum'],
  };

  static const _incomeCategoryWords = <String, List<String>>{
    'Salary': ['gaji', 'gajian', 'honor', 'upah'],
    'Allowance': ['uang saku', 'dikasih', 'kiriman', 'ortu', 'mama', 'papa', 'jajan bulanan'],
    'Side hustle': ['jual', 'jualan', 'freelance', 'proyek', 'project', 'komisi'],
    'Found on street': ['nemu', 'menemukan', 'jalan'],
    'Falling from heaven': ['bonus', 'rezeki', 'hoki', 'menang', 'hadiah', 'thr'],
  };

  static String normalize(String text) =>
      text.toLowerCase().replaceAll(RegExp(r'[!?;"]'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();

  /// "25rb" → 25000, "1,5jt" → 1500000, "Rp 25.000" → 25000.
  /// Angka kecil (< 100) diabaikan supaya "sneakers #2" tidak dianggap nominal.
  static double? parseAmount(String text) {
    final t = normalize(text);
    for (final m in _amountRe.allMatches(t)) {
      final raw = m.group(1)!;
      final unit = m.group(2);
      double? value;
      if (unit == 'jt' || unit == 'juta') {
        final n = double.tryParse(raw.replaceAll(',', '.'));
        if (n != null) value = n * 1000000;
      } else if (unit == 'rb' || unit == 'ribu' || unit == 'k') {
        final n = double.tryParse(raw.replaceAll(',', '.'));
        if (n != null) value = n * 1000;
      } else {
        value = double.tryParse(raw.replaceAll(RegExp(r'[.,]'), ''));
      }
      if (value != null && value >= 100) return value.roundToDouble();
    }
    return null;
  }

  static bool _hasAny(String t, List<String> words) => words.any(t.contains);

  static BotIntent detectIntent(String text) {
    final t = normalize(text);
    if (t.isEmpty) return BotIntent.unknown;
    if (_hasAny(t, _summaryWords)) return BotIntent.summary;
    if (_hasAny(t, _transferWords)) return BotIntent.transfer;
    if (_hasAny(t, _incomeWords)) return BotIntent.income;
    if (_hasAny(t, _expenseWords)) return BotIntent.expense;
    if (RegExp(r'^(halo|hai|hi|hello|hey|help|bantuan|tolong|bisa apa|menu)\b').hasMatch(t)) {
      return BotIntent.help;
    }
    // Ada nominal tapi tanpa kata kerja → anggap pengeluaran ("kopi 20rb").
    if (parseAmount(t) != null) return BotIntent.expense;
    return BotIntent.unknown;
  }

  static String detectCategory(String text, BotIntent intent) {
    final t = normalize(text);
    final map = intent == BotIntent.income ? _incomeCategoryWords : _expenseCategoryWords;
    for (final entry in map.entries) {
      if (_hasAny(t, entry.value)) return entry.key;
    }
    return 'Other';
  }

  /// Cari wallet yang disebut di kalimat, urut sesuai posisi kemunculannya.
  static List<(Wallet, int)> findWallets(String text, List<Wallet> wallets) {
    final t = normalize(text);
    final found = <(Wallet, int)>[];
    for (final w in wallets) {
      final name = w.name.toLowerCase().trim();
      var idx = name.isEmpty ? -1 : t.indexOf(name);
      if (idx < 0 && w.last4.isNotEmpty) idx = t.indexOf(w.last4);
      if (idx >= 0) found.add((w, idx));
    }
    found.sort((a, b) => a.$2.compareTo(b.$2));
    return found;
  }

  static Wallet? _main(List<Wallet> wallets) {
    for (final w in wallets) {
      if (w.isMain) return w;
    }
    return wallets.isEmpty ? null : wallets.first;
  }

  static ParsedCommand parse(String raw, List<Wallet> wallets) {
    final t = normalize(raw);
    final intent = detectIntent(t);
    final cmd = ParsedCommand(intent: intent, note: _cleanNote(raw));

    if (t.contains('kemarin')) {
      cmd.when = DateTime.now().subtract(const Duration(days: 1));
    }

    switch (intent) {
      case BotIntent.summary:
        cmd.lastMonth = t.contains('bulan lalu');
      case BotIntent.income:
      case BotIntent.expense:
        {
          cmd.amount = parseAmount(t);
          cmd.category = detectCategory(t, intent);
          final found = findWallets(t, wallets);
          cmd.wallet = found.isNotEmpty ? found.first.$1 : _main(wallets);
        }
      case BotIntent.transfer:
        {
        cmd.amount = parseAmount(t);
        cmd.category = 'Transfer';
        final found = findWallets(t, wallets);
        if (found.length >= 2) {
          var from = found[0];
          var to = found[1];
          final dari = t.indexOf('dari');
          final ke = t.indexOf(' ke ');
          // "pindahin ke savings dari main wallet" → urutannya dibalik.
          if (dari >= 0 && ke >= 0 && ke < dari) {
            from = found[1];
            to = found[0];
          }
          cmd.wallet = from.$1;
          cmd.toWallet = to.$1;
        } else if (found.length == 1) {
          final w = found.first.$1;
          final saysTo = t.contains('ke ${w.name.toLowerCase()}');
          if (saysTo) {
            cmd.toWallet = w;
            final main = _main(wallets);
            cmd.wallet = (main != null && main.id != w.id) ? main : null;
          } else {
            cmd.wallet = w;
          }
        } else {
          cmd.wallet = _main(wallets);
        }
        }
      case BotIntent.help:
      case BotIntent.unknown:
        break;
    }
    return cmd;
  }

  static String _cleanNote(String raw) {
    final s = raw.trim();
    if (s.isEmpty) return s;
    final short = s.length > 60 ? '${s.substring(0, 60)}…' : s;
    return short[0].toUpperCase() + short.substring(1);
  }
}

const botFallback =
    'Maaf, aku belum mengerti 🙏 Dollaan masih dalam tahap pengembangan.\n'
    'Saat ini aku bisa:\n'
    '• catat pengeluaran — "beli kopi 20rb"\n'
    '• catat pemasukan — "dapat uang saku 500rb"\n'
    '• pindah dana — "pindahin 200rb dari main wallet ke savings"\n'
    '• ringkasan — "rekap bulan ini"';

const botHelp = 'Halo! Aku Dollaan Bot. Ketik saja transaksimu seperti ngobrol biasa:\n'
    '• "beli nasi padang 25rb"\n'
    '• "gajian 3jt ke main wallet"\n'
    '• "pindahin 200rb ke savings"\n'
    '• "rekap bulan ini"';
