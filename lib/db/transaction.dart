class TransactionItem {
  final String label;
  final double amount;
  final bool isIncome;

  TransactionItem({
    required this.label,
    required this.amount,
    required this.isIncome,
  });

  Map<String, dynamic> toMap() {
    return {'label': label, 'amount': amount, 'isIncome': isIncome};
  }

  factory TransactionItem.fromMap(Map<dynamic, dynamic> map) {
    return TransactionItem(
      label: map['label'],
      amount: map['amount'],
      isIncome: map['isIncome'],
    );
  }
}
