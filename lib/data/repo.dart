import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../config.dart';
import '../models.dart';

/// Semua komunikasi dengan Supabase ada di sini.
class Repo {
  SupabaseClient get _db => Supabase.instance.client;

  User? get currentUser => _db.auth.currentUser;
  String get uid => _db.auth.currentUser!.id;

  // ---------------- Auth ----------------
  Future<void> signIn(String email, String password) async {
    await _db.auth.signInWithPassword(email: email, password: password);
  }

  /// Mengembalikan `true` kalau Supabase meminta konfirmasi email dulu.
  Future<bool> signUp(String email, String password, String fullName) async {
    final res = await _db.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName},
    );
    return res.session == null;
  }

  Future<void> signOut() => _db.auth.signOut();

  // ---------------- Profile ----------------
  Future<Profile?> profile() async {
    final row = await _db.from('profiles').select().eq('id', uid).maybeSingle();
    return row == null ? null : Profile.fromMap(row);
  }

  Future<void> saveProfile(Map<String, dynamic> data) async {
    await _db.from('profiles').upsert({
      'id': uid,
      'email': currentUser?.email,
      ...data,
    });
  }

  // ---------------- Wallets ----------------
  Future<List<Wallet>> wallets() async {
    final rows = await _db.from('wallets').select().order('created_at');
    return rows.map(Wallet.fromMap).toList();
  }

  Future<Wallet> insertWallet(Map<String, dynamic> data) async {
    final row = await _db.from('wallets').insert(data).select().single();
    return Wallet.fromMap(row);
  }

  Future<void> updateWallet(String id, Map<String, dynamic> data) async {
    await _db.from('wallets').update(data).eq('id', id);
  }

  Future<void> clearMainWallet() async {
    await _db.from('wallets').update({'is_main': false}).eq('user_id', uid);
  }

  Future<void> deleteWallet(String id) async {
    await _db.from('wallets').delete().eq('id', id);
  }

  // ---------------- Transactions ----------------
  Future<List<Txn>> transactions() async {
    final rows = await _db
        .from('transactions')
        .select()
        .order('occurred_at', ascending: false);
    return rows.map(Txn.fromMap).toList();
  }

  Future<Txn> insertTxn(Map<String, dynamic> data) async {
    final row = await _db.from('transactions').insert(data).select().single();
    return Txn.fromMap(row);
  }

  Future<void> deleteTxn(String id) async {
    await _db.from('transactions').delete().eq('id', id);
  }

  // ---------------- Goals ----------------
  Future<List<Goal>> goals() async {
    final rows = await _db.from('goals').select().order('created_at');
    return rows.map(Goal.fromMap).toList();
  }

  Future<Goal> insertGoal(Map<String, dynamic> data) async {
    final row = await _db.from('goals').insert(data).select().single();
    return Goal.fromMap(row);
  }

  Future<Goal> updateGoal(String id, Map<String, dynamic> data) async {
    final row =
        await _db.from('goals').update(data).eq('id', id).select().single();
    return Goal.fromMap(row);
  }

  Future<void> deleteGoal(String id) async {
    await _db.from('goals').delete().eq('id', id);
  }

  // ---------------- Chat ----------------
  Future<List<ChatMsg>> chat() async {
    final rows = await _db
        .from('chat_messages')
        .select()
        .order('created_at', ascending: false)
        .limit(100);
    return rows.map(ChatMsg.fromMap).toList().reversed.toList();
  }

  Future<void> insertChat(String role, String content, bool understood) async {
    await _db.from('chat_messages').insert({
      'role': role,
      'content': content,
      'understood': understood,
    });
  }

  // ---------------- Storage ----------------
  /// Upload gambar ke bucket dan kembalikan URL publiknya.
  Future<String> uploadImage(Uint8List bytes, String folder, String ext) async {
    final cleanExt = ext.toLowerCase().replaceAll('.', '');
    final path = '$uid/$folder/${DateTime.now().millisecondsSinceEpoch}.$cleanExt';
    await _db.storage.from(AppConfig.storageBucket).uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            contentType: cleanExt == 'png' ? 'image/png' : 'image/jpeg',
            upsert: true,
          ),
        );
    return _db.storage.from(AppConfig.storageBucket).getPublicUrl(path);
  }
}
