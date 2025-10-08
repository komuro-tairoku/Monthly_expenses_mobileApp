import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../l10n/app_localizations.dart';

class Statement extends StatefulWidget {
  const Statement({super.key});

  @override
  State<Statement> createState() => _StatementState();
}

class _StatementState extends State<Statement> {
  DateTime _selectedDate = DateTime.now();
  String _filterType = 'day'; // day | week | month

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
    DateTime startDate;
    DateTime endDate;

    if (_filterType == 'week') {
      startDate = _selectedDate.subtract(
        Duration(days: _selectedDate.weekday - 1),
      );
      endDate = startDate.add(const Duration(days: 7));
    } else if (_filterType == 'month') {
      startDate = DateTime(_selectedDate.year, _selectedDate.month, 1);
      endDate = DateTime(_selectedDate.year, _selectedDate.month + 1, 1);
    } else {
      startDate = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
      );
      endDate = startDate.add(const Duration(days: 1));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context).t('statement.title'),
          style: const TextStyle(fontSize: 26),
        ),
        centerTitle: true,
        toolbarHeight: 80,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6B43FF), Color(0xFF8B5FFF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.calendar_month, color: Colors.white, size: 28),
          onPressed: _pickDate,
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_alt, color: Colors.white, size: 28),
            onSelected: (value) {
              setState(() {
                _filterType = value;
              });
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'day',
                child: Text(
                  AppLocalizations.of(context).t('statement.filter_day'),
                ),
              ),
              PopupMenuItem(
                value: 'week',
                child: Text(
                  AppLocalizations.of(context).t('statement.filter_week'),
                ),
              ),
              PopupMenuItem(
                value: 'month',
                child: Text(
                  AppLocalizations.of(context).t('statement.filter_month'),
                ),
              ),
            ],
          ),
          const SizedBox(width: 10),
        ],
      ),

      // === BODY ===
      body: Builder(
        builder: (context) {
          final user = FirebaseAuth.instance.currentUser;

          // 🔹 Nếu chưa đăng nhập (guest)
          if (user == null) {
            return Center(
              child: Text(
                AppLocalizations.of(
                  context,
                ).t('statement.login_required'), // từ file vi.json
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            );
          }

          // 🔹 Nếu đã đăng nhập
          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection("transactions")
                .doc(user.uid)
                .collection('items')
                .where(
                  "date",
                  isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
                )
                .where("date", isLessThan: Timestamp.fromDate(endDate))
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Text(
                    AppLocalizations.of(context).t('statement.no_data_range'),
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                );
              }

              final transactions = snapshot.data!.docs
                  .map<Map<String, dynamic>>((doc) {
                    final Map<String, dynamic> data = doc.data();
                    double amount = 0.0;
                    final amtRaw = data['amount'];
                    if (amtRaw is num) {
                      amount = amtRaw.toDouble();
                    } else if (amtRaw is String) {
                      amount =
                          double.tryParse(amtRaw.replaceAll(',', '')) ?? 0.0;
                    }

                    final category = (data['category'] ?? 'Khác').toString();
                    final isIncome = data['isIncome'] == true;

                    return {
                      'amount': amount,
                      'category': category,
                      'isIncome': isIncome,
                    };
                  })
                  .toList();

              final Map<String, double> categoryTotals = {};
              for (final t in transactions) {
                final category = (t['category'] as String?) ?? 'Khác';
                final amount = (t['amount'] as double?) ?? 0.0;
                categoryTotals[category] =
                    (categoryTotals[category] ?? 0) + amount;
              }

              final total = categoryTotals.values.fold(0.0, (a, b) => a + b);
              if (total <= 0) {
                return Center(
                  child: Text(
                    AppLocalizations.of(context).t('statement.no_data'),
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                );
              }

              final Map<String, Color> categoryColors = {
                "Mua sắm": Color(0xFFFF3B30),
                "Ăn uống": Color(0xFFFF9500),
                "Điện thoại": Color(0xFFFFCC00),
                "Giải trí": Color(0xFFAF52DE),
                "Giáo dục": Color(0xFFFF2D55),
                "Sắc đẹp": Color(0xFFFF6B81),
                "Thể thao": Color(0xFFFF8C00),
                "Xã hội": Color(0xFFFFD60A),
                "Nhà ở": Color(0xFFFF5E3A),
                "Tiền điện": Color(0xFFFF9500),
                "Tiền nước": Color(0xFFFFC300),
                "Quần áo": Color(0xFFFF9F0A),
                "Đi lại": Color(0xFFFF453A),
                "Chi khác": Color(0xFFEA4C89),
                "Tiền lương": Color(0xFF34C759),
                "Phụ cấp": Color(0xFF32ADE6),
                "Thưởng": Color(0xFF30B0C7),
                "Thu khác": Color(0xFF007AFF),
              };

              final sections = <PieChartSectionData>[];
              categoryTotals.forEach((category, amount) {
                final percentage = (amount / total * 100);
                final color = categoryColors[category] ?? Colors.grey;

                sections.add(
                  PieChartSectionData(
                    color: color,
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
              });

              String timeLabel = '';
              if (_filterType == 'week') {
                timeLabel = AppLocalizations.of(context)
                    .t('statement.label_week')
                    .replaceAll('{ds}', startDate.day.toString())
                    .replaceAll('{ms}', startDate.month.toString())
                    .replaceAll(
                      '{de}',
                      endDate.subtract(const Duration(days: 1)).day.toString(),
                    )
                    .replaceAll('{me}', endDate.month.toString());
              } else if (_filterType == 'month') {
                timeLabel = AppLocalizations.of(context)
                    .t('statement.label_month')
                    .replaceAll('{m}', _selectedDate.month.toString())
                    .replaceAll('{y}', _selectedDate.year.toString());
              } else {
                timeLabel = AppLocalizations.of(context)
                    .t('statement.label_day')
                    .replaceAll('{d}', _selectedDate.day.toString())
                    .replaceAll('{m}', _selectedDate.month.toString())
                    .replaceAll('{y}', _selectedDate.year.toString());
              }

              return SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    Text(
                      timeLabel,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 250,
                      child: PieChart(
                        PieChartData(
                          sections: sections,
                          centerSpaceRadius: 40,
                          sectionsSpace: 2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: categoryTotals.entries.map((entry) {
                          final color =
                              categoryColors[entry.key] ?? Colors.grey;
                          return ListTile(
                            leading: CircleAvatar(backgroundColor: color),
                            title: Text(entry.key),
                            trailing: Text(
                              "${entry.value.toStringAsFixed(0)} đ",
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
          );
        },
      ),
    );
  }
}
