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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          Stack(
            children: [
              Container(height: 150, color: Theme.of(context).primaryColor),
              Positioned.fill(
                child: Center(
                  child: Text(
                    'Ghi Chú Thu Chi',
                    style: const TextStyle(
                      color: Color(0xFFE0E0E0),
                      fontSize: 28,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 38,
                right: 0,
                child: IconButton(
                  onPressed: () {},
                  icon: SvgPicture.asset(
                    'assets/icons/calendar.svg',
                    width: 38,
                    color: const Color(0xFFE0E0E0),
                  ),
                ),
              ),
            ],
          ),

          Expanded(
            child: ValueListenableBuilder(
              valueListenable: transactionBox.listenable(),
              builder: (context, Box<TransactionItem> box, _) {
                if (box.isEmpty) {
                  return const Center(
                    child: Text(
                      "Chưa có giao dịch nào",
                      style: TextStyle(fontSize: 16),
                    ),
                  );
                }

                final transactions = box.values
                    .toList()
                    .cast<TransactionItem>();

                return ListView.builder(
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
                            "${item.amount.toStringAsFixed(0)} đ",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: item.isIncome ? Colors.green : Colors.red,
                            ),
                          ),
                          onLongPress: () {
                            _showOptions(context, item, index);
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
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
                    const SnackBar(content: Text("Đã xóa giao dịch")),
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
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Số tiền"),
                style: Theme.of(context).textTheme.bodyMedium,
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
