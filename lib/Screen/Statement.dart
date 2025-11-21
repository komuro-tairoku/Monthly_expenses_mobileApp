import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../l10n/app_localizations.dart';
import '../Services/category_translator.dart';
import '../Services/transaction_service.dart';
import '../db/transaction.dart';

class Statement extends StatefulWidget {
  const Statement({super.key});

  @override
  State<Statement> createState() => _StatementState();
}

class _StatementState extends State<Statement> {
  DateTime _selectedDate = DateTime.now();
  String _filterType = 'day'; // day, week, month

  Future<Box<TransactionModel>> _openTransactionBox() async {
    return Hive.isBoxOpen('transactions')
        ? Hive.box<TransactionModel>('transactions')
        : await Hive.openBox<TransactionModel>('transactions');
  }

  String formatCurrency(double amount, {bool isIncome = false}) {
    final formatter = NumberFormat("#,###", "vi_VN");
    final formatted = formatter.format(amount.abs());
    return "${isIncome ? '+' : '-'}$formatted đ";
  }


 // Chuyển ngôn ngữ hiện tại

  String _translateCategory(String category) {
    final translationKey = CategoryTranslator.getTranslationKey(category);
    if (CategoryTranslator.isTranslatable(category)) {
      return AppLocalizations.of(context).t(translationKey);
    }
    return category;
  }

  Color _getCategoryColor(String category) {
    const Map<String, Color> categoryColors = {

      "sheet.shopping": Color(0xFFFF3B30),
      "sheet.food": Color(0xFFFF9500),
      "sheet.phone": Color(0xFFFFCC00),
      "sheet.entertainment": Color(0xFFAF52DE),
      "sheet.education": Color(0xFFFF2D55),
      "sheet.beauty": Color(0xFFFF6B81),
      "sheet.sports": Color(0xFFFF8C00),
      "sheet.social": Color(0xFFFFD60A),
      "sheet.housing": Color(0xFFFF5E3A),
      "sheet.electricity": Color(0xFFFF9500),
      "sheet.water": Color(0xFFFFC300),
      "sheet.clothes": Color(0xFFFF9F0A),
      "sheet.transport": Color(0xFFFF453A),
      "sheet.other_expense": Color(0xFFEA4C89),
      // Thu nhập (màu xanh)
      "sheet.salary": Color(0xFF34C759),
      "sheet.allowance": Color(0xFF32ADE6),
      "sheet.bonus": Color(0xFF30B0C7),
      "sheet.other_income": Color(0xFF007AFF),
    };
    final translationKey = CategoryTranslator.getTranslationKey(category);
    return categoryColors[translationKey] ?? Colors.grey;
  }

  //  chọn ngày

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  // LỌC TRANSACTIONS THEO KHOẢNG THỜI GIAN
  List<TransactionModel> _filterByDateRange(
      List<TransactionModel> allTxns,
      DateTime startDate,
      DateTime endDate,
      ) {
    return allTxns.where((txn) {
      return !txn.date.isBefore(startDate) && txn.date.isBefore(endDate);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {

    DateTime startDate;
    DateTime endDate;

    if (_filterType == 'week') {

      startDate = _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
      startDate = DateTime(startDate.year, startDate.month, startDate.day);
      endDate = startDate.add(const Duration(days: 7));
    } else if (_filterType == 'month') {

      startDate = DateTime(_selectedDate.year, _selectedDate.month, 1);
      endDate = DateTime(_selectedDate.year, _selectedDate.month + 1, 1);
    } else {

      startDate = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
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
            onSelected: (value) => setState(() => _filterType = value),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'day',
                child: Text(AppLocalizations.of(context).t('statement.filter_day')),
              ),
              PopupMenuItem(
                value: 'week',
                child: Text(AppLocalizations.of(context).t('statement.filter_week')),
              ),
              PopupMenuItem(
                value: 'month',
                child: Text(AppLocalizations.of(context).t('statement.filter_month')),
              ),
            ],
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: FutureBuilder<Box<TransactionModel>>(
        future: _openTransactionBox(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final box = snapshot.data!;

          return ValueListenableBuilder(
            valueListenable: box.listenable(),
            builder: (context, Box<TransactionModel> box, _) {
              // Lấy và lọc transactions
              final allTxns = TransactionService.getSortedTransactions(box);
              final transactions = _filterByDateRange(allTxns, startDate, endDate);

              if (transactions.isEmpty) {
                return SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 20),

                      _buildDateSelector(startDate, endDate),
                      const SizedBox(height: 20),
                      Text(
                        AppLocalizations.of(context).t('statement.no_data_range'),
                        style: const TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }

              final Map<String, double> totals = {};
              final Map<String, bool> types = {};

              for (final txn in transactions) {
                final cat = txn.category.isNotEmpty ? txn.category : txn.note;
                totals[cat] = (totals[cat] ?? 0) + txn.amount;
                types[cat] = txn.isIncome;
              }

              final total = totals.values.fold(0.0, (a, b) => a + b);

              if (total == 0) {
                return Center(
                  child: Text(
                    AppLocalizations.of(context).t('statement.no_data'),
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                );
              }
              final sections = totals.entries.map((entry) {
                final percent = entry.value / total * 100;
                return PieChartSectionData(
                  value: entry.value,
                  radius: 90,
                  color: _getCategoryColor(entry.key),
                  title: "${percent.toStringAsFixed(1)}%",
                  titleStyle: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList();
              return SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 20),

                    _buildDateSelector(startDate, endDate),

                    const SizedBox(height: 20),

                    SizedBox(
                      height: 280,
                      child: PieChart(
                        PieChartData(
                          sections: sections,
                          centerSpaceRadius: 45,
                          sectionsSpace: 2,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: totals.entries.map((entry) {
                          final color = _getCategoryColor(entry.key);
                          final isIncome = types[entry.key] ?? false;
                          return ListTile(
                            leading: CircleAvatar(backgroundColor: color),
                            title: Text(_translateCategory(entry.key)),
                            trailing: Text(
                              formatCurrency(entry.value, isIncome: isIncome),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isIncome ? Colors.green : Colors.red,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildDateSelector(DateTime startDate, DateTime endDate) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          gradient: isDark
              ? const LinearGradient(
            colors: [Color(0xFF6B43FF), Color(0xFF8B5FFF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
              : null,
          color: isDark ? null : const Color(0x8AFFFFFF),
          borderRadius: BorderRadius.circular(13),
          border: isDark ? null : Border.all(color: Colors.deepPurpleAccent),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? const Color(0xFF6B43FF).withOpacity(0.3)
                  : Colors.black.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      if (_filterType == 'day') {
                        _selectedDate = _selectedDate.subtract(const Duration(days: 1));
                      } else if (_filterType == 'week') {
                        _selectedDate = _selectedDate.subtract(const Duration(days: 7));
                      } else {
                        _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1, _selectedDate.day);
                      }
                    });
                  },
                  child: Icon(
                    Icons.chevron_left,
                    size: 32,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),

                // Hiển thị ngày được chọn
                Text(
                  DateFormat("dd/MM/yyyy (EEE)", "vi_VN").format(_selectedDate),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),

                GestureDetector(
                  onTap: () {
                    setState(() {
                      if (_filterType == 'day') {
                        _selectedDate = _selectedDate.add(const Duration(days: 1));
                      } else if (_filterType == 'week') {
                        _selectedDate = _selectedDate.add(const Duration(days: 7));
                      } else {
                        _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1, _selectedDate.day);
                      }
                    });
                  },
                  child: Icon(
                    Icons.chevron_right,
                    size: 32,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            Text(
              _buildTimeLabel(startDate, endDate),
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white70 : Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }


  String _buildTimeLabel(DateTime start, DateTime end) {
    if (_filterType == 'week') {
      return AppLocalizations.of(context)
          .t('statement.label_week')
          .replaceAll('{ds}', start.day.toString())
          .replaceAll('{ms}', start.month.toString())
          .replaceAll('{de}', end.subtract(const Duration(days: 1)).day.toString())
          .replaceAll('{me}', end.month.toString());
    }
    if (_filterType == 'month') {
      return AppLocalizations.of(context)
          .t('statement.label_month')
          .replaceAll('{m}', _selectedDate.month.toString())
          .replaceAll('{y}', _selectedDate.year.toString());
    }
    return AppLocalizations.of(context)
        .t('statement.label_day')
        .replaceAll('{d}', _selectedDate.day.toString())
        .replaceAll('{m}', _selectedDate.month.toString())
        .replaceAll('{y}', _selectedDate.year.toString());
  }
}