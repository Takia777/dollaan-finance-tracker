import 'package:dollaan/chatbot/chatbot.dart';
import 'package:dollaan/models.dart';
import 'package:flutter_test/flutter_test.dart';

Wallet _w(String id, String name, {bool main = false, String last4 = ''}) => Wallet(
      id: id,
      name: name,
      type: WalletType.bank,
      color: 'unguTua',
      logoUrl: null,
      last4: last4,
      isMain: main,
      initialBalance: 0,
    );

void main() {
  final wallets = [
    _w('1', 'Main Wallet', main: true, last4: '1081'),
    _w('2', 'Savings', last4: '0336'),
    _w('3', 'Tap card'),
  ];

  group('parseAmount', () {
    test('ribuan & jutaan', () {
      expect(ChatParser.parseAmount('beli kopi 20rb'), 20000);
      expect(ChatParser.parseAmount('makan 25 ribu'), 25000);
      expect(ChatParser.parseAmount('jajan 15k'), 15000);
      expect(ChatParser.parseAmount('gajian 3jt'), 3000000);
      expect(ChatParser.parseAmount('bonus 1,5jt'), 1500000);
      expect(ChatParser.parseAmount('bayar Rp 25.000'), 25000);
      expect(ChatParser.parseAmount('bayar 1.250.000'), 1250000);
    });
    test('angka kecil diabaikan', () {
      expect(ChatParser.parseAmount('nabung buat sneakers #2'), isNull);
    });
  });

  group('intent', () {
    test('pengeluaran', () {
      final c = ChatParser.parse('beli nasi padang 25rb', wallets);
      expect(c.intent, BotIntent.expense);
      expect(c.amount, 25000);
      expect(c.category, 'Food');
      expect(c.wallet?.id, '1');
    });
    test('pemasukan', () {
      final c = ChatParser.parse('dapat uang saku 500rb ke savings', wallets);
      expect(c.intent, BotIntent.income);
      expect(c.category, 'Allowance');
      expect(c.wallet?.id, '2');
    });
    test('transfer dua wallet', () {
      final c = ChatParser.parse('pindahin 200rb dari main wallet ke savings', wallets);
      expect(c.intent, BotIntent.transfer);
      expect(c.wallet?.id, '1');
      expect(c.toWallet?.id, '2');
      expect(c.missing, isNull);
    });
    test('transfer urutan terbalik', () {
      final c = ChatParser.parse('transfer 50rb ke savings dari tap card', wallets);
      expect(c.wallet?.id, '3');
      expect(c.toWallet?.id, '2');
    });
    test('transfer hanya tujuan → dari main wallet', () {
      final c = ChatParser.parse('pindahin 100rb ke savings', wallets);
      expect(c.wallet?.id, '1');
      expect(c.toWallet?.id, '2');
    });
    test('ringkasan', () {
      expect(ChatParser.parse('rekap bulan ini dong', wallets).intent, BotIntent.summary);
      expect(ChatParser.parse('ringkasan bulan lalu', wallets).lastMonth, isTrue);
    });
    test('tidak dikenali', () {
      expect(ChatParser.parse('rekomendasi saham dong', wallets).intent, BotIntent.unknown);
    });
    test('nominal kurang', () {
      final c = ChatParser.parse('beli kopi', wallets);
      expect(c.intent, BotIntent.expense);
      expect(c.missing, 'amount');
    });
  });
}
