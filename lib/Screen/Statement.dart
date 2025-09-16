import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class Statement extends StatefulWidget {
  const Statement({super.key});

  @override
  State<Statement> createState() => _StatementState();
}

class _StatementState extends State<Statement> {
  DateTime _selectedDate = DateTime.now();

  // Giả lập dữ liệu thu chi (có thể thay bằng dữ liệu DB sau này)
  double income = 5000000; // 5 triệu
  double expense = 3200000; // 3.2 triệu

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
        // 🔹 Sau này bạn có thể load dữ liệu thu chi theo ngày ở đây
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    double total = income + expense;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Báo cáo"),
        centerTitle: true,
        toolbarHeight: 80,
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: _pickDate,
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),

          // Hiển thị ngày đã chọn
          Text(
            "Ngày: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}",
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 20),

          // Biểu đồ hình tròn
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: [
                  PieChartSectionData(
                    color: Colors.green,
                    value: income,
                    title: "Thu\n${(income / total * 100).toStringAsFixed(1)}%",
                    radius: 70,
                    titleStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                  PieChartSectionData(
                    color: Colors.red,
                    value: expense,
                    title: "Chi\n${(expense / total * 100).toStringAsFixed(1)}%",
                    radius: 70,
                    titleStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 30),

          // Thống kê chi tiết
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                _buildSummaryRow("Tổng thu:", income, Colors.green),
                const SizedBox(height: 10),
                _buildSummaryRow("Tổng chi:", expense, Colors.red),
                const SizedBox(height: 10),
                _buildSummaryRow("Còn lại:", income - expense, Colors.blue),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        Text(
          "${amount.toStringAsFixed(0)} đ",
          style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }
}
