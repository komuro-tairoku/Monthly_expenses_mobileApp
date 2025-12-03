import 'package:hive/hive.dart';

part 'budget.g.dart';

@HiveType(typeId: 1)
class BudgetModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String category;

  @HiveField(2)
  double amount;

  @HiveField(3)
  int month; // Tháng (1-12)

  @HiveField(4)
  int year; // Năm

  @HiveField(5)
  bool isSynced;

  @HiveField(6)
  DateTime createdAt;

  @HiveField(7)
  DateTime updatedAt;

  BudgetModel({
    required this.id,
    required this.category,
    required this.amount,
    required this.month,
    required this.year,
    this.isSynced = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category': category,
      'amount': amount,
      'month': month,
      'year': year,
      'isSynced': isSynced,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory BudgetModel.fromMap(Map<String, dynamic> map) {
    final now = DateTime.now();
    return BudgetModel(
      id: map['id']?.toString() ?? '',
      category: map['category']?.toString() ?? '',
      amount: _parseToDouble(map['amount']),
      month: map['month'] is int ? map['month'] : now.month,
      year: map['year'] is int ? map['year'] : now.year,
      isSynced: map['isSynced'] == true,
      createdAt: _parseToDateTime(map['createdAt']),
      updatedAt: _parseToDateTime(map['updatedAt']),
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
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    return DateTime.now();
  }
}
