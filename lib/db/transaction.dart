import 'package:hive/hive.dart';

part 'transaction.g.dart';

@HiveType(typeId: 1)
class Transaction extends HiveObject {
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
  bool isSynced;

  Transaction({
    required this.id,
    required this.category,
    required this.amount,
    required this.note,
    required this.date,
    this.isSynced = false,
  });
}
