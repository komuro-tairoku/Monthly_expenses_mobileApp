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

          const SizedBox(height: 16),

          // 🔹 Danh sách giao dịch từ Hive
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
                    return Card(
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
                        subtitle: Text(item.isIncome ? "Thu nhập" : "Chi tiêu"),
                        trailing: Text(
                          "${item.amount.toStringAsFixed(0)} đ",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: item.isIncome ? Colors.green : Colors.red,
                          ),
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
}
