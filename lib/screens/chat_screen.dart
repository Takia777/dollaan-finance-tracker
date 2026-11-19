import 'package:flutter/material.dart';

import '../categories.dart';
import '../chatbot/chatbot.dart';
import '../models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../ui/widgets.dart';
import '../utils/format.dart';

/// Layar chatbot rule-based. Bisa mencatat transaksi lewat chat dan membuat ringkasan bulanan.
class ChatScreen extends StatefulWidget {
  final String? initialMessage;
  const ChatScreen({super.key, this.initialMessage});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _Bubble {
  final ChatMsg msg;
  final ParsedCommand? draft; // kartu konfirmasi
  bool resolved;
  _Bubble(this.msg, {this.draft}) : resolved = false;
}

class _ChatScreenState extends State<ChatScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  late final List<_Bubble> _bubbles = [for (final m in app.chat) _Bubble(m)];

  /// Perintah yang masih menunggu jawaban (nominal / wallet).
  ParsedCommand? _pending;

  @override
  void initState() {
    super.initState();
    if (_bubbles.isEmpty) {
      _bubbles.add(_Bubble(_botMsg('Hi ${app.profile?.displayName ?? ''}! $botHelp')));
    }
    final first = widget.initialMessage;
    if (first != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _send(first));
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => _toBottom());
    }
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  ChatMsg _botMsg(String text, {bool understood = true}) =>
      ChatMsg(role: 'bot', content: text, understood: understood, createdAt: DateTime.now());

  void _toBottom() {
    if (!_scroll.hasClients) return;
    _scroll.animateTo(
      _scroll.position.maxScrollExtent + 200,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  void _bot(String text, {bool understood = true, ParsedCommand? draft}) {
    final msg = _botMsg(text, understood: understood);
    setState(() => _bubbles.add(_Bubble(msg, draft: draft)));
    app.addChat(msg);
  }

  Future<void> _send(String raw) async {
    final text = raw.trim();
    if (text.isEmpty) return;
    _input.clear();
    final userMsg = ChatMsg(role: 'user', content: text, understood: true, createdAt: DateTime.now());
    setState(() => _bubbles.add(_Bubble(userMsg)));
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;

    // Simpan pesan pengguna dulu supaya urutan riwayat chat benar.
    final understood = _pending != null || ChatParser.detectIntent(text) != BotIntent.unknown;
    await app.addChat(ChatMsg(role: 'user', content: text, understood: understood, createdAt: userMsg.createdAt));
    if (!mounted) return;

    if (_pending != null && _fillPending(text)) {
      // Jawaban untuk pertanyaan sebelumnya (nominal / wallet).
    } else {
      _pending = null;
      _handle(ChatParser.parse(text, app.wallets));
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _toBottom());
  }

  /// Mengisi data yang kurang dari jawaban pengguna. `false` kalau bukan jawaban.
  bool _fillPending(String text) {
    final cmd = _pending!;
    final need = cmd.missing;
    if (need == 'amount') {
      final a = ChatParser.parseAmount(text);
      if (a == null) return false;
      cmd.amount = a;
    } else if (need == 'wallet' || need == 'toWallet') {
      final found = ChatParser.findWallets(text, app.wallets);
      if (found.isEmpty) return false;
      if (need == 'wallet') {
        cmd.wallet = found.first.$1;
      } else {
        cmd.toWallet = found.first.$1;
      }
    } else {
      return false;
    }
    _handle(cmd);
    return true;
  }

  void _handle(ParsedCommand cmd) {
    switch (cmd.intent) {
      case BotIntent.unknown:
        _bot(botFallback, understood: false);
        return;
      case BotIntent.help:
        _bot(botHelp);
        return;
      case BotIntent.summary:
        _bot(_summary(cmd.lastMonth));
        return;
      case BotIntent.income:
      case BotIntent.expense:
      case BotIntent.transfer:
        break;
    }
    if (app.wallets.isEmpty) {
      _bot('Kamu belum punya wallet. Tambahkan dulu lewat tombol + di Home ya.');
      return;
    }
    switch (cmd.missing) {
      case 'amount':
        _pending = cmd;
        _bot('Berapa nominalnya? (contoh: 25rb)');
      case 'wallet':
        _pending = cmd;
        _bot('Dari wallet mana? ${app.wallets.map((w) => w.name).join(' / ')}');
      case 'toWallet':
        _pending = cmd;
        final options = app.wallets.where((w) => w.id != cmd.wallet?.id).map((w) => w.name).join(' / ');
        _bot('Mau dipindah ke wallet mana? $options');
      default:
        _pending = null;
        if (cmd.intent == BotIntent.transfer && cmd.wallet!.id == cmd.toWallet!.id) {
          _bot('Wallet asal dan tujuan sama. Coba sebutkan dua wallet yang berbeda ya.');
          return;
        }
        _bot('Cek dulu ya, sudah benar?', draft: cmd);
    }
  }

  String _summary(bool lastMonth) {
    final now = DateTime.now();
    final start = lastMonth ? DateTime(now.year, now.month - 1, 1) : monthStart(now);
    final end = DateTime(start.year, start.month + 1, 1);
    final prevStart = DateTime(start.year, start.month - 1, 1);
    final income = app.incomeBetween(start, end);
    final expense = app.expenseBetween(start, end);
    final prevExpense = app.expenseBetween(prevStart, start);
    final cats = app.expenseByCategory(start, end);
    final saved = app.txnsBetween(start, end)
        .where((t) => t.kind == TxnKind.goal)
        .fold<double>(0, (s, t) => s + t.amount);
    if (income == 0 && expense == 0 && saved == 0) {
      return 'Belum ada transaksi di ${monthYear(start)}. Coba catat dulu, misalnya "beli kopi 20rb".';
    }
    final b = StringBuffer('Ringkasan ${monthYear(start)}:\n');
    b.writeln('• Pemasukan: ${rupiah(income)}');
    b.writeln('• Pengeluaran: ${rupiah(expense)}');
    b.writeln('• Ditabung ke goal: ${rupiah(saved)}');
    b.writeln('• Sisa: ${rupiah(income - expense - saved)}');
    if (cats.isNotEmpty) {
      final top = cats.first;
      final pct = expense == 0 ? 0 : (top.value / expense * 100).round();
      b.writeln('Pengeluaran terbesar: ${top.key} (${rupiah(top.value)}, $pct%).');
    }
    if (prevExpense > 0) {
      final diff = (expense - prevExpense) / prevExpense * 100;
      b.write(diff <= 0
          ? 'Pengeluaranmu turun ${diff.abs().round()}% dibanding bulan sebelumnya. Mantap! 🎉'
          : 'Pengeluaranmu naik ${diff.round()}% dibanding bulan sebelumnya. Yuk sedikit direm 🙂');
    }
    return b.toString().trim();
  }

  Future<void> _confirm(_Bubble bubble) async {
    final cmd = bubble.draft!;
    setState(() => bubble.resolved = true);
    try {
      final kind = switch (cmd.intent) {
        BotIntent.income => TxnKind.topup,
        BotIntent.transfer => TxnKind.transfer,
        _ => TxnKind.expense,
      };
      await app.addTxn(
        walletId: cmd.wallet!.id,
        kind: kind,
        amount: cmd.amount!,
        category: cmd.category,
        note: cmd.intent == BotIntent.transfer ? null : cmd.note,
        occurredAt: cmd.when,
        toWalletId: cmd.toWallet?.id,
      );
      final w = app.walletById(cmd.wallet!.id);
      _bot('Tersimpan ✅ Saldo ${w?.name ?? 'wallet'} sekarang ${rupiah(app.balanceOf(cmd.wallet!.id))}.');
    } catch (e) {
      setState(() => bubble.resolved = false);
      _bot('Gagal menyimpan: ${friendlyError(e)}');
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _toBottom());
  }

  void _cancel(_Bubble bubble) {
    setState(() => bubble.resolved = true);
    _bot('Oke, dibatalkan.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: Row(
                children: [
                  CircleBtn(icon: Icons.chevron_left_rounded, onTap: () => Navigator.pop(context)),
                  const SizedBox(width: 12),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.tosca,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.kuning, width: 2),
                    ),
                    child: const Icon(Icons.auto_awesome_rounded, color: AppColors.putih, size: 22),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Dollaan Bot', style: ts(16, FontWeight.w700)),
                        Text('Beta · catat transaksi lewat chat', style: ts(11, FontWeight.w500, AppColors.muted)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                itemCount: _bubbles.length,
                itemBuilder: (_, i) => _bubbleView(_bubbles[i]),
              ),
            ),
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  for (final s in const ['beli kopi 20rb', 'dapat uang saku 500rb', 'pindahin 100rb ke savings', 'rekap bulan ini'])
                    Padding(
                      padding: const EdgeInsets.only(right: 8, bottom: 6),
                      child: ActionChip(
                        label: Text(s, style: ts(12, FontWeight.w700, AppColors.tosca)),
                        backgroundColor: AppColors.putih,
                        side: BorderSide(color: AppColors.tosca.o(0.4)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        onPressed: () => _send(s),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 4, 6, 4),
                decoration: BoxDecoration(
                  color: AppColors.putih,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [BoxShadow(color: AppColors.unguTua.o(0.08), blurRadius: 16, offset: const Offset(0, 4))],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _input,
                        textInputAction: TextInputAction.send,
                        onSubmitted: _send,
                        style: ts(14, FontWeight.w500),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Ketik transaksimu… (contoh: beli kopi 20rb)',
                          hintStyle: ts(13, FontWeight.w500, AppColors.muted),
                        ),
                      ),
                    ),
                    CircleBtn(
                      icon: Icons.send_rounded,
                      bg: AppColors.tosca,
                      fg: AppColors.putih,
                      size: 42,
                      onTap: () => _send(_input.text),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bubbleView(_Bubble b) {
    final me = b.msg.fromUser;
    return Align(
      alignment: me ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: me ? AppColors.unguTua : AppColors.putih,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(me ? 20 : 6),
            topRight: const Radius.circular(20),
            bottomLeft: const Radius.circular(20),
            bottomRight: Radius.circular(me ? 6 : 20),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(b.msg.content, style: ts(13, FontWeight.w500, me ? AppColors.putih : AppColors.unguTua)),
            if (b.draft != null) ...[
              const SizedBox(height: 10),
              _draftCard(b),
            ],
          ],
        ),
      ),
    );
  }

  Widget _draftCard(_Bubble b) {
    final cmd = b.draft!;
    final income = cmd.intent == BotIntent.income;
    final transfer = cmd.intent == BotIntent.transfer;
    final cat = categoryByName(cmd.category, income: income);
    final title = transfer ? 'Transfer' : (income ? 'Top Up' : 'Expense');
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.sakura, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconBubble(icon: transfer ? Icons.swap_horiz_rounded : cat.icon, color: transfer ? AppColors.ungu : cat.color, size: 36),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: ts(12, FontWeight.w600, AppColors.muted)),
                    Text(rupiah(cmd.amount ?? 0), style: ts(18, FontWeight.w800)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (!transfer) _row('Category', cat.name),
          _row(transfer ? 'From' : (income ? 'To wallet' : 'From wallet'), cmd.wallet?.name ?? '-'),
          if (transfer) _row('To', cmd.toWallet?.name ?? '-'),
          _row('When', dayOnly(cmd.when) == dayOnly(DateTime.now()) ? 'Today' : shortDate(cmd.when)),
          const SizedBox(height: 10),
          if (b.resolved)
            Text('✓ Done', style: ts(12, FontWeight.w700, AppColors.tosca))
          else
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => _cancel(b),
                    child: Text('Batal', style: ts(13, FontWeight.w700, AppColors.muted)),
                  ),
                ),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.unguTua,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => _confirm(b),
                    child: Text('Simpan', style: ts(13, FontWeight.w700, AppColors.putih)),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _row(String k, String v) => Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Row(
          children: [
            Text(k, style: ts(12, FontWeight.w500, AppColors.muted)),
            const Spacer(),
            Text(v, style: ts(12, FontWeight.w700)),
          ],
        ),
      );
}
