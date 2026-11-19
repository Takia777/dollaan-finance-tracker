enum WalletType { bank, emoney, etoll, wallet }

WalletType walletTypeFrom(String? s) => WalletType.values.firstWhere(
      (t) => t.name == s,
      orElse: () => WalletType.wallet,
    );

String walletTypeLabel(WalletType t) => switch (t) {
      WalletType.bank => 'Bank card',
      WalletType.emoney => 'E-money',
      WalletType.etoll => 'E-toll',
      WalletType.wallet => 'Wallet',
    };

double _num(dynamic v) => v == null ? 0 : (v as num).toDouble();
DateTime _date(dynamic v) =>
    v == null ? DateTime.now() : DateTime.parse(v as String).toLocal();

class Profile {
  final String id;
  final String fullName;
  final String nickname;
  final String email;
  final String language;
  final String currency;
  final double monthlyBudget;
  final bool dailyReminder;
  final bool setupDone;

  const Profile({
    required this.id,
    required this.fullName,
    required this.nickname,
    required this.email,
    required this.language,
    required this.currency,
    required this.monthlyBudget,
    required this.dailyReminder,
    required this.setupDone,
  });

  String get displayName {
    if (nickname.trim().isNotEmpty) return nickname.trim();
    if (fullName.trim().isNotEmpty) return fullName.trim().split(' ').first;
    return 'there';
  }

  String get initial => displayName.isEmpty ? 'D' : displayName[0].toUpperCase();

  factory Profile.fromMap(Map<String, dynamic> m) => Profile(
        id: m['id'] as String,
        fullName: (m['full_name'] as String?) ?? '',
        nickname: (m['nickname'] as String?) ?? '',
        email: (m['email'] as String?) ?? '',
        language: (m['language'] as String?) ?? 'en',
        currency: (m['currency'] as String?) ?? 'IDR',
        monthlyBudget: _num(m['monthly_budget']),
        dailyReminder: (m['daily_reminder'] as bool?) ?? true,
        setupDone: (m['setup_done'] as bool?) ?? false,
      );
}

class Wallet {
  final String id;
  final String name;
  final WalletType type;
  final String color;
  final String? logoUrl;
  final String last4;
  final bool isMain;
  final double initialBalance;

  const Wallet({
    required this.id,
    required this.name,
    required this.type,
    required this.color,
    required this.logoUrl,
    required this.last4,
    required this.isMain,
    required this.initialBalance,
  });

  factory Wallet.fromMap(Map<String, dynamic> m) => Wallet(
        id: m['id'] as String,
        name: (m['name'] as String?) ?? 'Wallet',
        type: walletTypeFrom(m['type'] as String?),
        color: (m['color'] as String?) ?? 'unguTua',
        logoUrl: m['logo_url'] as String?,
        last4: (m['last4'] as String?) ?? '',
        isMain: (m['is_main'] as bool?) ?? false,
        initialBalance: _num(m['initial_balance']),
      );
}

enum TxnKind { topup, expense, transfer, goal }

TxnKind txnKindFrom(String? s) => TxnKind.values.firstWhere(
      (k) => k.name == s,
      orElse: () => TxnKind.expense,
    );

class Txn {
  final String id;
  final String walletId;
  final TxnKind kind;
  final double amount;
  final String? category;
  final String? note;
  final DateTime occurredAt;
  final String? toWalletId;
  final String? goalId;

  const Txn({
    required this.id,
    required this.walletId,
    required this.kind,
    required this.amount,
    required this.category,
    required this.note,
    required this.occurredAt,
    required this.toWalletId,
    required this.goalId,
  });

  factory Txn.fromMap(Map<String, dynamic> m) => Txn(
        id: m['id'] as String,
        walletId: m['wallet_id'] as String,
        kind: txnKindFrom(m['kind'] as String?),
        amount: _num(m['amount']),
        category: m['category'] as String?,
        note: m['note'] as String?,
        occurredAt: _date(m['occurred_at']),
        toWalletId: m['to_wallet_id'] as String?,
        goalId: m['goal_id'] as String?,
      );
}

class Goal {
  final String id;
  final String name;
  final String? imageUrl;
  final double target;
  final DateTime? targetDate;
  final String status; // active | reached | packed
  final bool autoSave;
  final DateTime createdAt;
  final DateTime? packedAt;

  const Goal({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.target,
    required this.targetDate,
    required this.status,
    required this.autoSave,
    required this.createdAt,
    required this.packedAt,
  });

  bool get isActive => status == 'active';
  bool get isReached => status == 'reached';
  bool get isPacked => status == 'packed';

  factory Goal.fromMap(Map<String, dynamic> m) => Goal(
        id: m['id'] as String,
        name: (m['name'] as String?) ?? 'Goal',
        imageUrl: m['image_url'] as String?,
        target: _num(m['target']),
        targetDate: m['target_date'] == null
            ? null
            : DateTime.parse(m['target_date'] as String),
        status: (m['status'] as String?) ?? 'active',
        autoSave: (m['auto_save'] as bool?) ?? false,
        createdAt: _date(m['created_at']),
        packedAt: m['packed_at'] == null ? null : _date(m['packed_at']),
      );
}

class ChatMsg {
  final String role; // user | bot
  final String content;
  final bool understood;
  final DateTime createdAt;

  const ChatMsg({
    required this.role,
    required this.content,
    required this.understood,
    required this.createdAt,
  });

  bool get fromUser => role == 'user';

  factory ChatMsg.fromMap(Map<String, dynamic> m) => ChatMsg(
        role: (m['role'] as String?) ?? 'bot',
        content: (m['content'] as String?) ?? '',
        understood: (m['understood'] as bool?) ?? true,
        createdAt: _date(m['created_at']),
      );
}
