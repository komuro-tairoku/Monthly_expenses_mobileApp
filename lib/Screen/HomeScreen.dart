import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:monthly_expenses_mobile_app/db/transaction.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Box<TransactionItem> transactionBox = Hive.box<TransactionItem>(
    'transactions',
  );

  String _formatAmount(double value) {
    return value.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: ValueListenableBuilder(
        valueListenable: transactionBox.listenable(),
        builder: (context, Box<TransactionItem> box, _) {
          final transactions = box.values.toList().cast<TransactionItem>();

          double totalIncome = 0;
          double totalExpense = 0;
          for (var t in transactions) {
            if (t.isIncome) {
              totalIncome += t.amount;
            } else {
              totalExpense += t.amount;
            }
          }
          double balance = totalIncome - totalExpense;

          return Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 18,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                ),
                child: SafeArea(
                  bottom: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Text(
                          'Ghi Chú Thu Chi',
                          style: const TextStyle(
                            color: Color(0xFFE0E0E0),
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildStatCard(
                            label: 'Tổng thu',
                            value: _formatAmount(totalIncome),
                            valueColor: Colors.greenAccent.shade400,
                            context: context,
                          ),
                          _buildStatCard(
                            label: 'Chi tiêu',
                            value: _formatAmount(totalExpense),
                            valueColor: Colors.redAccent.shade400,
                            context: context,
                          ),
                          _buildStatCard(
                            label: 'Còn lại',
                            value: _formatAmount(balance),
                            valueColor: Colors.white,
                            context: context,
                            emphasize: true,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (transactions.isEmpty)
                const Expanded(
                  child: Center(
                    child: Text(
                      "Chưa có giao dịch nào",
                      style: TextStyle(fontSize: 20),
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: transactions.length,
                    itemBuilder: (context, index) {
                      final item = transactions[index];

                      return Dismissible(
                        key: ValueKey(item.key),
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.only(left: 20),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        secondaryBackground: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (_) {
                          box.deleteAt(index);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Đã xóa giao dịch")),
                          );
                        },
                        child: Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: ListTile(
                            leading: Icon(
                              item.isIncome
                                  ? Icons.arrow_downward
                                  : Icons.arrow_upward,
                              color: item.isIncome ? Colors.green : Colors.red,
                            ),
                            title: Text(item.label),
                            subtitle: Text(
                              item.isIncome ? "Thu nhập" : "Chi tiêu",
                            ),
                            trailing: Text(
                              "${_formatAmount(item.amount)} đ",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: item.isIncome
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ),
                            onLongPress: () {
                              _showEditDialog(item, index);
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required Color valueColor,
    required BuildContext context,
    bool emphasize = false,
  }) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFFE0E0E0),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "$value đ",
              style: TextStyle(
                fontSize: 18,
                fontWeight: emphasize ? FontWeight.bold : FontWeight.w600,
                color: valueColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(TransactionItem item, int index) {
    final labelController = TextEditingController(text: item.label);
    final amountController = TextEditingController(
      text: item.amount.toString(),
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Sửa giao dịch"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: labelController,
                decoration: const InputDecoration(labelText: "Nội dung"),
              ),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Số tiền"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Hủy"),
            ),
            ElevatedButton(
              onPressed: () {
                final newLabel = labelController.text.trim();
                final newAmount = double.tryParse(amountController.text) ?? 0;

                final updated = TransactionItem(
                  label: newLabel.isNotEmpty ? newLabel : item.label,
                  amount: newAmount,
                  isIncome: item.isIncome,
                );

                transactionBox.putAt(index, updated);
                Navigator.pop(context);
              },
              child: const Text("Lưu"),
            ),
          ],
        );
      },
    );
  }
}
