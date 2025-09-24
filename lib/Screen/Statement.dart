import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
    final startOfDay = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return Scaffold(
      appBar: AppBar(
        title: const Text("Báo cáo"),
        centerTitle: true,
        toolbarHeight: 80,
        actions: [
          IconButton(icon: const Icon(Icons.date_range), onPressed: _pickDate),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("transactions")
            .where("date", isGreaterThanOrEqualTo: startOfDay.toIso8601String())
            .where("date", isLessThan: endOfDay.toIso8601String())
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "Không có giao dịch trong ngày này",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          // Lấy dữ liệu transactions từ Firestore
          final transactions = snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return {
              "amount": (data["amount"] as num).toDouble(),
              "category": data["category"] ?? "Khác",
              "isIncome": data["isIncome"] ?? false,
            };
          }).toList();

          // Nhóm theo category
          final Map<String, double> categoryTotals = {};
          for (var t in transactions) {
            final cat =
                t["category"] ?? (t["isIncome"] ? "Khác (Thu)" : "Khác (Chi)");
            categoryTotals[cat] =
                (categoryTotals[cat] ?? 0) + (t["amount"] as double);
          }

          final total = categoryTotals.values.fold(0.0, (a, b) => a + b);

          // Tạo PieChart sections
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

                // Danh sách chi tiết
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
