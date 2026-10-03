import 'package:get_storage/get_storage.dart';

/// Local coin transaction ledger (complements the server balance).
class CoinEntry {
  final int amount;
  final String reason;
  final DateTime at;

  const CoinEntry({required this.amount, required this.reason, required this.at});

  Map<String, dynamic> toJson() =>
      {'amount': amount, 'reason': reason, 'at': at.toIso8601String()};

  factory CoinEntry.fromJson(Map<String, dynamic> json) => CoinEntry(
        amount: (json['amount'] as num).toInt(),
        reason: '${json['reason'] ?? ''}',
        at: DateTime.tryParse('${json['at'] ?? ''}') ?? DateTime.now(),
      );
}

class CoinLedger {
  static const String _key = 'coin_ledger_v1';
  static const int _maxEntries = 100;

  final GetStorage box;

  CoinLedger({GetStorage? box}) : box = box ?? GetStorage();

  List<CoinEntry> entries() {
    final raw = box.read<List>(_key);
    if (raw == null) return const [];
    return raw
        .whereType<Map>()
        .map((m) => CoinEntry.fromJson(Map<String, dynamic>.from(m)))
        .toList()
      ..sort((a, b) => b.at.compareTo(a.at));
  }

  Future<void> record(int amount, String reason) async {
    final list = entries().toList();
    list.insert(0, CoinEntry(amount: amount, reason: reason, at: DateTime.now()));
    await box.write(
        _key, list.take(_maxEntries).map((e) => e.toJson()).toList());
  }
}
