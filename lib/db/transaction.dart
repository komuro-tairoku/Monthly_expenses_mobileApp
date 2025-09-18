import 'package:hive/hive.dart';

part 'transaction.g.dart';

@HiveType(typeId: 0)
class TransactionItem extends HiveObject {
  @HiveField(0)
  final String label;

  @HiveField(1)
  final double amount;

  @HiveField(2)
  final bool isIncome;

  @HiveField(3)
  final String? category;

  @HiveField(4)
  final DateTime? date;

  TransactionItem({
    required this.label,
    required this.amount,
    required this.isIncome,
    this.category,
    DateTime? date,
  }) : date = date ?? DateTime.now();
}
