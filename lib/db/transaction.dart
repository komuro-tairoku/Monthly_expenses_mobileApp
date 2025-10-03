import 'package:hive/hive.dart';

part 'transaction.g.dart';

@HiveType(typeId: 0)
class TransactionModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String category;

  @HiveField(2)
  double amount;

  @HiveField(3)
  String note;

  @HiveField(4)
  DateTime date;

  @HiveField(5)
  bool isIncome;

  @HiveField(6)
  bool isSynced;

  TransactionModel({
    required this.id,
    required this.category,
    required this.amount,
    required this.note,
    required this.date,
    required this.isIncome,
    this.isSynced = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category': category,
      'amount': amount,
      'note': note,
      'date': date.toIso8601String(),
      'isIncome': isIncome,
      'isSynced': isSynced,
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: (map['id'] == null) ? '' : map['id'].toString(),
      category: (map['category'] == null) ? '' : map['category'].toString(),
      amount: _parseToDouble(map['amount']),
      note: (map['note'] == null) ? '' : map['note'].toString(),
      date: _parseToDateTime(map['date']),
      isIncome: map['isIncome'] == true,
      isSynced: map['isSynced'] == true,
    );
  }

  static double _parseToDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static DateTime _parseToDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    if (value is int) {
      // assume milliseconds since epoch
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    return DateTime.now();
  }
}
