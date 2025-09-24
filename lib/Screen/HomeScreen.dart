import 'package:flutter/material.dart';

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

  String _formatDate(DateTime? date) {
    if (date == null) return "Không rõ ngày";
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
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
                              "${item.isIncome ? "Thu nhập" : "Chi tiêu"} • ${_formatDate(item.date)}",
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
                              _showOptions(context, item, index);
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

  void _showOptions(BuildContext context, TransactionItem item, int index) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.blue),
                title: const Text("Sửa"),
                onTap: () {
                  Navigator.pop(ctx);
                  _showEditDialog(item, index);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text("Xóa"),
                onTap: () {
                  Navigator.pop(ctx);
                  transactionBox.deleteAt(index);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text("Đã xóa giao dịch"),
                      behavior: SnackBarBehavior.floating,
                      margin: const EdgeInsets.all(12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEditDialog(TransactionItem item, int index) {
    final labelController = TextEditingController(text: item.label);
    final amountController = TextEditingController(
      text: item.amount.toStringAsFixed(0),
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
                style: Theme.of(
                  context,
                ).textTheme.bodySmall!.copyWith(fontSize: 18),
              ),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Số tiền"),
                style: Theme.of(
                  context,
                ).textTheme.bodySmall!.copyWith(fontSize: 18),
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
                  category: item.category,
                  date: item.date,
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
