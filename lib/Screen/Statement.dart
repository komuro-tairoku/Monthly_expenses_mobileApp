import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:monthly_expenses_mobile_app/db/transaction.dart';

class Statement extends StatefulWidget {
  const Statement({super.key});

  @override
  State<Statement> createState() => _StatementState();
}

class _StatementState extends State<Statement> {
  DateTime _selectedDate = DateTime.now();

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final transactionBox = Hive.box<TransactionItem>('transactions');

    return Scaffold(
      appBar: AppBar(
        title: const Text("Báo cáo"),
        centerTitle: true,
        toolbarHeight: 80,
        actions: [
          IconButton(icon: const Icon(Icons.date_range), onPressed: _pickDate),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: transactionBox.listenable(),
        builder: (context, Box<TransactionItem> box, _) {
          final transactions = box.values.toList();

          // Tính tổng thu / chi
          double totalIncome = 0;
          double totalExpense = 0;

          for (var t in transactions) {
            if (t.isIncome) {
              totalIncome += t.amount;
            } else {
              totalExpense += t.amount;
            }
          }

          double total = totalIncome + totalExpense;

          return Column(
            children: [
              const SizedBox(height: 20),
              Text(
                "Ngày: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              // Luôn hiển thị PieChart
              SizedBox(
                height: 200,
                child: PieChart(
                  PieChartData(
                    sections: [
                      PieChartSectionData(
                        color: Colors.green,
                        value: totalIncome,
                        title:
                            "Thu\n${total == 0 ? 0 : (totalIncome / total * 100).toStringAsFixed(1)}%",
                        radius: 70,
                        titleStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      PieChartSectionData(
                        color: Colors.red,
                        value: totalExpense,
                        title:
                            "Chi\n${total == 0 ? 0 : (totalExpense / total * 100).toStringAsFixed(1)}%",
                        radius: 70,
                        titleStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    _buildSummaryRow("Tổng thu:", totalIncome, Colors.green),
                    const SizedBox(height: 10),
                    _buildSummaryRow("Tổng chi:", totalExpense, Colors.red),
                    const SizedBox(height: 10),
                    _buildSummaryRow(
                      "Còn lại:",
                      totalIncome - totalExpense,
                      Colors.blue,
                    ),
                  ],
                ),
              ),

              if (transactions.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    "Chưa có dữ liệu giao dịch",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        Text(
          "${amount.toStringAsFixed(0)} đ",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
