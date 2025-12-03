import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../db/budget.dart';
import '../db/transaction.dart';
import '../Services/budget_service.dart';
import '../Services/hive_helper.dart';
import '../l10n/app_localizations.dart';
import '../Services/category_translator.dart';

class BudgetPage extends ConsumerStatefulWidget {
  const BudgetPage({super.key});

  @override
  ConsumerState<BudgetPage> createState() => _BudgetPageState();
}

class _BudgetPageState extends ConsumerState<BudgetPage> {
  final TextEditingController _budgetController = TextEditingController();
  final List<String> _expenseCategories = [
    'Shopping',
    'Food',
    'Phone',
    'Entertainment',
    'Education',
    'Beauty',
    'Sports',
    'Social',
    'Housing',
    'Electricity Bill',
    'Water Bill',
    'Clothes',
    'Travel',
    'Other Expenses',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await BudgetService.loadBudgetsFromFirebase();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _budgetController.dispose();
    super.dispose();
  }

  String _translateCategory(String category) {
    final key = CategoryTranslator.getTranslationKey(category);
    return CategoryTranslator.isTranslatable(category)
        ? AppLocalizations.of(context).t(key)
        : category;
  }

  Color _getCategoryColor(String category) {
    const colors = {
      'sheet.shopping': Color(0xFFFF6B6B),
      'sheet.food': Color(0xFFFF9F43),
      'sheet.phone': Color(0xFF5F27CD),
      'sheet.entertainment': Color(0xFFEE5A6F),
      'sheet.education': Color(0xFF0ABDE3),
      'sheet.beauty': Color(0xFFFECA57),
      'sheet.sports': Color(0xFF48DBFB),
      'sheet.social': Color(0xFF00D2D3),
      'sheet.housing': Color(0xFF54A0FF),
      'sheet.electricity': Color(0xFFFFA502),
      'sheet.water': Color(0xFF1DD1A1),
      'sheet.clothes': Color(0xFFC44569),
      'sheet.transport': Color(0xFF5F27CD),
      'sheet.other_expense': Color(0xFF636E72),
    };
    return colors[CategoryTranslator.getTranslationKey(category)] ??
        Colors.grey;
  }

  IconData _getCategoryIcon(String category) {
    const icons = {
      'Shopping': Icons.shopping_bag,
      'Food': Icons.restaurant,
      'Phone': Icons.phone_android,
      'Entertainment': Icons.movie,
      'Education': Icons.school,
      'Beauty': Icons.spa,
      'Sports': Icons.sports_soccer,
      'Social': Icons.people,
      'Housing': Icons.home,
      'Electricity Bill': Icons.electrical_services,
      'Water Bill': Icons.water_drop,
      'Clothes': Icons.checkroom,
      'Travel': Icons.directions_car,
      'Other Expenses': Icons.more_horiz,
    };
    return icons[category] ?? Icons.category;
  }

  void _showAddBudgetDialog(String? category, {BudgetModel? existingBudget}) {
    _budgetController.clear();

    if (existingBudget != null) {
      _budgetController.text = existingBudget.amount.toStringAsFixed(0);
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            category == null
                ? 'Đặt ngân sách tổng'
                : 'Đặt ngân sách cho ${_translateCategory(category)}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Dropdown for category selection (if no category provided)
                if (category == null)
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Chọn danh mục',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    items: _expenseCategories
                        .map(
                          (cat) => DropdownMenuItem(
                            value: cat,
                            child: Row(
                              children: [
                                Icon(_getCategoryIcon(cat), size: 20),
                                const SizedBox(width: 8),
                                Text(_translateCategory(cat)),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        Navigator.pop(ctx);
                        _showAddBudgetDialog(value);
                      }
                    },
                  ),

                // Budget amount field (if category is provided)
                if (category != null)
                  TextField(
                    controller: _budgetController,
                    keyboardType: TextInputType.number,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Nhập số tiền',
                      prefixText: '₫ ',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Hủy', style: TextStyle(color: Colors.grey[600])),
            ),
            if (category != null)
              ElevatedButton(
                onPressed: () async {
                  final amount = double.tryParse(_budgetController.text);
                  if (amount != null && amount > 0) {
                    await BudgetService.saveBudget(
                      category: category,
                      amount: amount,
                    );
                    _budgetController.clear();
                    if (mounted) {
                      Navigator.pop(ctx);
                      setState(() {});
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Đã đặt ngân sách ${_translateCategory(category)}',
                          ),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6B43FF),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Lưu'),
              ),
          ],
        ),
      ),
    );
  }

  void _showDeleteBudgetDialog(BudgetModel budget) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa ngân sách'),
        content: Text(
          'Bạn có chắc muốn xóa ngân sách cho ${_translateCategory(budget.category)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              await BudgetService.deleteBudget(budget);
              if (mounted) {
                Navigator.pop(ctx);
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã xóa ngân sách'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Ngân sách'),
        backgroundColor: const Color(0xFF6B43FF),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Tải lại',
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'clear') {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Xóa tất cả ngân sách'),
                    content: const Text(
                      'Bạn có chắc muốn xóa tất cả ngân sách? Hành động này không thể hoàn tác.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Hủy'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        child: const Text('Xóa tất cả'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await BudgetService.clearAllBudgets();
                  if (mounted) {
                    setState(() {});
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Đã xóa tất cả ngân sách'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.delete_sweep, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Xóa tất cả'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: FutureBuilder<List<Box>>(
        future: Future.wait([
          HiveHelper.getTransactionBox(),
          BudgetService.getBudgetBox(),
        ]),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          final transactionBox = snapshot.data![0] as Box<TransactionModel>;
          final budgetBox = snapshot.data![1] as Box<BudgetModel>;
          return ValueListenableBuilder(
            valueListenable: budgetBox.listenable(),
            builder: (context, Box<BudgetModel> box, _) {
              return FutureBuilder<List<BudgetModel>>(
                future: BudgetService.getCurrentMonthBudgets(),
                builder: (context, budgetSnapshot) {
                  if (!budgetSnapshot.hasData)
                    return const Center(child: CircularProgressIndicator());
                  final budgets = budgetSnapshot.data!;
                  return SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTotalOverview(budgets, transactionBox),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Ngân sách theo danh mục',
                                style: Theme.of(context).textTheme.titleLarge!
                                    .copyWith(fontWeight: FontWeight.bold),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.add_circle,
                                  color: Color(0xFF6B43FF),
                                ),
                                onPressed: () => _showAddBudgetDialog(null),
                                tooltip: 'Thêm ngân sách',
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (budgets.isEmpty)
                            this._buildEmptyState()
                          else
                            ...budgets.map(
                              (budget) =>
                                  _buildBudgetCard(budget, transactionBox),
                            ),
                          const SizedBox(height: 80),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddBudgetDialog(null),
        backgroundColor: const Color(0xFF6B43FF),
        icon: const Icon(Icons.add),
        label: const Text('Thêm ngân sách'),
      ),
    );
  }

  Widget _buildTotalOverview(
    List<BudgetModel> budgets,
    Box<TransactionModel> transactionBox,
  ) {
    double totalBudget = budgets.fold(0, (sum, b) => sum + b.amount);
    double totalSpent = 0;
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    for (var txn in transactionBox.values) {
      if (!txn.isIncome &&
          txn.date.isAfter(startOfMonth.subtract(const Duration(seconds: 1))) &&
          txn.date.isBefore(endOfMonth.add(const Duration(seconds: 1))))
        totalSpent += txn.amount;
    }
    final percentage = totalBudget > 0 ? (totalSpent / totalBudget) * 100 : 0.0;
    final remaining = totalBudget - totalSpent;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6B43FF), Color(0xFF8B5FFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6B43FF).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tổng ngân sách tháng này',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            totalBudget > 0
                ? '₫${totalBudget.toStringAsFixed(0)}'
                : 'Chưa đặt ngân sách',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (totalBudget > 0) ...[
            const SizedBox(height: 20),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: percentage / 100,
                minHeight: 10,
                backgroundColor: Colors.white30,
                valueColor: AlwaysStoppedAnimation<Color>(
                  percentage > 90
                      ? Colors.red
                      : percentage > 70
                      ? Colors.orange
                      : Colors.green,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Đã chi',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    Text(
                      '₫${totalSpent.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Còn lại',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    Text(
                      '₫${remaining.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: remaining >= 0 ? Colors.white : Colors.red[300],
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Phần trăm',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    Text(
                      '${percentage.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBudgetCard(
    BudgetModel budget,
    Box<TransactionModel> transactionBox,
  ) {
    return FutureBuilder<double>(
      future: BudgetService.getSpentAmountForCategory(
        budget.category,
        transactionBox,
        budget.month,
        budget.year,
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final spent = snapshot.data!;
        final percentage = budget.amount > 0
            ? (spent / budget.amount) * 100
            : 0.0;
        final remaining = budget.amount - spent;
        final warningLevel = BudgetService.getWarningLevel(
          spent,
          budget.amount,
        );
        Color progressColor, borderColor;
        IconData warningIcon;
        switch (warningLevel) {
          case 3:
            progressColor = borderColor = Colors.red;
            warningIcon = Icons.error;
            break;
          case 2:
            progressColor = borderColor = Colors.orange;
            warningIcon = Icons.warning_amber;
            break;
          case 1:
            progressColor = borderColor = Colors.yellow;
            warningIcon = Icons.info;
            break;
          default:
            progressColor = Colors.green;
            borderColor = Colors.green.withOpacity(0.3);
            warningIcon = Icons.check_circle;
        }
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 2),
            boxShadow: [
              BoxShadow(
                color: borderColor.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _getCategoryColor(
                        budget.category,
                      ).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _getCategoryIcon(budget.category),
                      color: _getCategoryColor(budget.category),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _translateCategory(budget.category),
                          style: Theme.of(context).textTheme.titleMedium!
                              .copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Ngân sách: ₫${budget.amount.toStringAsFixed(0)}',
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall!.copyWith(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  if (warningLevel > 0)
                    Icon(warningIcon, color: progressColor, size: 24),
                  IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        builder: (ctx) => SafeArea(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ListTile(
                                leading: const Icon(Icons.edit),
                                title: const Text('Chỉnh sửa'),
                                onTap: () {
                                  Navigator.pop(ctx);
                                  _showAddBudgetDialog(budget.category);
                                },
                              ),
                              ListTile(
                                leading: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                title: const Text(
                                  'Xóa',
                                  style: TextStyle(color: Colors.red),
                                ),
                                onTap: () {
                                  Navigator.pop(ctx);
                                  _showDeleteBudgetDialog(budget);
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: percentage > 100 ? 1.0 : percentage / 100,
                  minHeight: 8,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Đã chi',
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall!.copyWith(color: Colors.grey),
                      ),
                      Text(
                        '₫${spent.toStringAsFixed(0)}',
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          fontWeight: FontWeight.bold,
                          color: progressColor,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Phần trăm',
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall!.copyWith(color: Colors.grey),
                      ),
                      Text(
                        '${percentage.toStringAsFixed(1)}%',
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Còn lại',
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall!.copyWith(color: Colors.grey),
                      ),
                      Text(
                        '₫${remaining.toStringAsFixed(0)}',
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          fontWeight: FontWeight.bold,
                          color: remaining >= 0 ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (warningLevel > 0) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: progressColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: progressColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(warningIcon, color: progressColor, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          BudgetService.getWarningMessage(
                            warningLevel,
                            _translateCategory(budget.category),
                          ),
                          style: TextStyle(
                            color: progressColor,
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Chưa có ngân sách nào',
            style: Theme.of(context).textTheme.titleMedium!.copyWith(
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Nhấn nút "Thêm ngân sách" để bắt đầu',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium!.copyWith(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
