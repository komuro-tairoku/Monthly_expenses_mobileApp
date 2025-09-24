import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

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
          final allTransactions = box.values.toList();

          final transactions = allTransactions.where((t) {
            return t.date?.year == _selectedDate.year &&
                t.date?.month == _selectedDate.month &&
                t.date?.day == _selectedDate.day;
          }).toList();

          if (transactions.isEmpty) {
            return const Center(
              child: Text(
                "Không có giao dịch trong ngày này",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          // Nhóm theo category
          final Map<String, double> categoryTotals = {};
          for (var t in transactions) {
            final cat =
                t.category ?? (t.isIncome ? "Khác (Thu)" : "Khác (Chi)");
            categoryTotals[cat] = (categoryTotals[cat] ?? 0) + t.amount;
          }

          final total = categoryTotals.values.fold(0.0, (a, b) => a + b);

          //Tạo PieChart sections
          final colors = [
            Colors.green,
            Colors.red,
            Colors.blue,
            Colors.orange,
            Colors.purple,
            Colors.cyan,
            Colors.teal,
            Colors.amber,
            Colors.pink,
            Colors.indigo,
          ];

          final sections = <PieChartSectionData>[];
          int colorIndex = 0;

          categoryTotals.forEach((category, amount) {
            final percentage = (amount / total * 100);
            sections.add(
              PieChartSectionData(
                color: colors[colorIndex % colors.length],
                value: amount,
                radius: 70,
                title: "${percentage.toStringAsFixed(1)}%",
                titleStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            );
            colorIndex++;
          });

          return SingleChildScrollView(
            child: Column(
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

                // Biểu đồ
                SizedBox(
                  height: 250,
                  child: PieChart(PieChartData(sections: sections)),
                ),

                const SizedBox(height: 20),

                //Danh sách chi tiết
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: categoryTotals.entries.map((e) {
                      final color =
                          colors[categoryTotals.keys.toList().indexOf(e.key) %
                              colors.length];
                      return ListTile(
                        leading: CircleAvatar(backgroundColor: color),
                        title: Text(e.key),
                        trailing: Text(
                          "${e.value.toStringAsFixed(0)} đ",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
