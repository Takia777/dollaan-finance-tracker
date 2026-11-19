import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import '../data/repo.dart';
import '../models.dart';
import '../utils/format.dart';

/// Satu-satunya sumber data aplikasi. Layar memakai `ListenableBuilder(listenable: app, ...)`
/// supaya otomatis diperbarui setiap data berubah.
final app = AppState();

class AppState extends ChangeNotifier {
  final repo = Repo();

  Profile? profile;
  List<Wallet> wallets = [];
  List<Txn> txns = [];
  List<Goal> goals = [];
  List<ChatMsg> chat = [];
  bool loading = false;

  /// Tab aktif di bottom nav: 0 Home, 1 Goals, 2 Statistic, 3 Settings.
  final tab = ValueNotifier<int>(0);

  Future<void> loadAll() async {
    loading = true;
    notifyListeners();
    try {
      final results = await Future.wait<Object?>([
        repo.profile(),
        repo.wallets(),
        repo.transactions(),
        repo.goals(),
        repo.chat(),
      ]);
      profile = results[0] as Profile?;
      wallets = results[1] as List<Wallet>;
      txns = results[2] as List<Txn>;
      goals = results[3] as List<Goal>;
      chat = results[4] as List<ChatMsg>;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  void clear() {
    profile = null;
    wallets = [];
    txns = [];
    goals = [];
    chat = [];
    tab.value = 0;
    notifyListeners();
  }

  // ======================= Wallets & balance =======================
  Wallet? walletById(String? id) {
    for (final w in wallets) {
      if (w.id == id) return w;
    }
    return null;
  }

  Wallet? get mainWallet {
    for (final w in wallets) {
      if (w.isMain) return w;
    }
    return wallets.isEmpty ? null : wallets.first;
  }

  double balanceOf(String walletId) {
    final w = walletById(walletId);
    var b = w?.initialBalance ?? 0;
    for (final t in txns) {
      if (t.walletId == walletId) {
        if (t.kind == TxnKind.topup) {
          b += t.amount;
        } else {
          b -= t.amount; // expense, goal, transfer keluar
        }
      }
      if (t.kind == TxnKind.transfer && t.toWalletId == walletId) {
        b += t.amount; // transfer masuk
      }
    }
    return b;
  }

  double get totalBalance =>
      wallets.fold(0.0, (sum, w) => sum + balanceOf(w.id));

  // ======================= Periods & statistics =======================
  List<Txn> txnsBetween(DateTime start, DateTime end) => txns
      .where((t) => !t.occurredAt.isBefore(start) && t.occurredAt.isBefore(end))
      .toList();

  double incomeBetween(DateTime start, DateTime end) => txnsBetween(start, end)
      .where((t) => t.kind == TxnKind.topup)
      .fold(0.0, (s, t) => s + t.amount);

  double expenseBetween(DateTime start, DateTime end) => txnsBetween(start, end)
      .where((t) => t.kind == TxnKind.expense)
      .fold(0.0, (s, t) => s + t.amount);

  /// Pemasukan dikurangi pengeluaran bulan ini.
  double get thisMonthNet {
    final start = monthStart(DateTime.now());
    final end = DateTime(start.year, start.month + 1, 1);
    return incomeBetween(start, end) - expenseBetween(start, end);
  }

  /// Persentase perubahan net bulan ini dibanding bulan lalu (null kalau belum ada data).
  double? get monthGrowthPct {
    final start = monthStart(DateTime.now());
    final prevStart = DateTime(start.year, start.month - 1, 1);
    final prev = incomeBetween(prevStart, start) - expenseBetween(prevStart, start);
    if (prev == 0) return null;
    return (thisMonthNet - prev) / prev.abs() * 100;
  }

  /// Total pengeluaran per kategori, diurutkan dari yang terbesar.
  List<MapEntry<String, double>> expenseByCategory(DateTime start, DateTime end) {
    final map = <String, double>{};
    for (final t in txnsBetween(start, end)) {
      if (t.kind != TxnKind.expense) continue;
      final key = t.category ?? 'Other';
      map[key] = (map[key] ?? 0) + t.amount;
    }
    final list = map.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return list;
  }

  Map<String, int> expenseCountByCategory(DateTime start, DateTime end) {
    final map = <String, int>{};
    for (final t in txnsBetween(start, end)) {
      if (t.kind != TxnKind.expense) continue;
      final key = t.category ?? 'Other';
      map[key] = (map[key] ?? 0) + 1;
    }
    return map;
  }

  // ======================= Goals =======================
  List<Goal> get activeGoals => goals.where((g) => !g.isPacked).toList();
  List<Goal> get packedGoals => goals.where((g) => g.isPacked).toList();

  Goal? goalById(String id) {
    for (final g in goals) {
      if (g.id == id) return g;
    }
    return null;
  }

  List<Txn> goalDeposits(String goalId) =>
      txns.where((t) => t.kind == TxnKind.goal && t.goalId == goalId).toList();

  double goalSaved(String goalId) =>
      goalDeposits(goalId).fold(0.0, (s, t) => s + t.amount);

  double goalProgress(Goal g) =>
      g.target <= 0 ? 0 : (goalSaved(g.id) / g.target).clamp(0.0, 1.0);

  double get totalSaved => txns
      .where((t) => t.kind == TxnKind.goal)
      .fold(0.0, (s, t) => s + t.amount);

  /// Jumlah setoran goal per hari (untuk heatmap).
  Map<DateTime, double> savingByDay() {
    final map = <DateTime, double>{};
    for (final t in txns) {
      if (t.kind != TxnKind.goal) continue;
      final d = dayOnly(t.occurredAt);
      map[d] = (map[d] ?? 0) + t.amount;
    }
    return map;
  }

  /// Berapa hari berturut-turut pengguna menabung ke goal.
  int get streakDays {
    final days = savingByDay().keys.toSet();
    var day = dayOnly(DateTime.now());
    if (!days.contains(day)) day = day.subtract(const Duration(days: 1));
    var count = 0;
    while (days.contains(day)) {
      count++;
      day = day.subtract(const Duration(days: 1));
    }
    return count;
  }

  // ======================= Mutations =======================
  Future<void> saveProfile(Map<String, dynamic> data) async {
    await repo.saveProfile(data);
    profile = await repo.profile();
    notifyListeners();
  }

  Future<Wallet> addWallet({
    required String name,
    required WalletType type,
    required String color,
    required String last4,
    required double initialBalance,
    required bool isMain,
    Uint8List? logoBytes,
    String logoExt = 'png',
  }) async {
    final makeMain = isMain || wallets.isEmpty;
    if (makeMain && wallets.isNotEmpty) {
      await repo.clearMainWallet();
    }
    String? logoUrl;
    if (logoBytes != null) {
      logoUrl = await repo.uploadImage(logoBytes, 'logos', logoExt);
    }
    await repo.insertWallet({
      'name': name,
      'type': type.name,
      'color': color,
      'last4': last4,
      'initial_balance': initialBalance,
      'is_main': makeMain,
      'logo_url': logoUrl,
    });
    wallets = await repo.wallets();
    notifyListeners();
    return wallets.last;
  }

  Future<void> setMainWallet(String walletId) async {
    await repo.clearMainWallet();
    await repo.updateWallet(walletId, {'is_main': true});
    wallets = await repo.wallets();
    notifyListeners();
  }

  Future<void> deleteWallet(String walletId) async {
    await repo.deleteWallet(walletId);
    wallets = await repo.wallets();
    txns = await repo.transactions();
    notifyListeners();
  }

  Future<Txn> addTxn({
    required String walletId,
    required TxnKind kind,
    required double amount,
    String? category,
    String? note,
    DateTime? occurredAt,
    String? toWalletId,
    String? goalId,
  }) async {
    final txn = await repo.insertTxn({
      'wallet_id': walletId,
      'kind': kind.name,
      'amount': amount,
      'category': category,
      'note': (note == null || note.trim().isEmpty) ? null : note.trim(),
      'occurred_at': (occurredAt ?? DateTime.now()).toUtc().toIso8601String(),
      'to_wallet_id': toWalletId,
      'goal_id': goalId,
    });
    txns = [txn, ...txns]..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
    notifyListeners();
    return txn;
  }

  Future<void> deleteTxn(String id) async {
    await repo.deleteTxn(id);
    txns = txns.where((t) => t.id != id).toList();
    notifyListeners();
  }

  Future<Goal> createGoal({
    required String name,
    required double target,
    DateTime? targetDate,
    bool autoSave = false,
    Uint8List? imageBytes,
    String imageExt = 'jpg',
  }) async {
    String? imageUrl;
    if (imageBytes != null) {
      imageUrl = await repo.uploadImage(imageBytes, 'goals', imageExt);
    }
    final goal = await repo.insertGoal({
      'name': name,
      'target': target,
      'target_date': targetDate == null
          ? null
          : '${targetDate.year.toString().padLeft(4, '0')}-${targetDate.month.toString().padLeft(2, '0')}-${targetDate.day.toString().padLeft(2, '0')}',
      'auto_save': autoSave,
      'image_url': imageUrl,
    });
    goals = [...goals, goal];
    notifyListeners();
    return goal;
  }

  /// Setor dana dari wallet ke goal. Mengembalikan `true` kalau goal baru saja tercapai.
  Future<bool> depositToGoal(Goal goal, String walletId, double amount) async {
    await addTxn(
      walletId: walletId,
      kind: TxnKind.goal,
      amount: amount,
      category: 'Saving',
      note: goal.name,
      goalId: goal.id,
    );
    if (goal.isActive && goalSaved(goal.id) >= goal.target) {
      await _replaceGoal(await repo.updateGoal(goal.id, {'status': 'reached'}));
      return true;
    }
    return false;
  }

  Future<void> packGoal(Goal goal) async {
    await _replaceGoal(await repo.updateGoal(goal.id, {
      'status': 'packed',
      'packed_at': DateTime.now().toUtc().toIso8601String(),
    }));
  }

  Future<void> deleteGoal(Goal goal) async {
    await repo.deleteGoal(goal.id);
    goals = goals.where((g) => g.id != goal.id).toList();
    txns = txns.where((t) => t.goalId != goal.id).toList();
    notifyListeners();
  }

  Future<void> _replaceGoal(Goal updated) async {
    goals = [for (final g in goals) g.id == updated.id ? updated : g];
    notifyListeners();
  }

  Future<void> addChat(ChatMsg msg) async {
    chat = [...chat, msg];
    notifyListeners();
    try {
      await repo.insertChat(msg.role, msg.content, msg.understood);
    } catch (_) {
      // Riwayat chat bukan data penting; abaikan kalau gagal tersimpan.
    }
  }
}
