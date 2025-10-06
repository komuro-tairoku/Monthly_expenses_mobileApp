import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../db/transaction.dart';
import '../Services/transaction_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final NumberFormat _amountFormatter = NumberFormat('#,##0', 'en_US');
  String _formatAmount(double value) => _amountFormatter.format(value);
  String _formatDate(DateTime date) =>
      DateFormat('dd/MM/yyyy HH:mm').format(date);

  Future<Box<TransactionModel>> _openTransactionBox() async {
    return Hive.isBoxOpen('transactions')
        ? Hive.box<TransactionModel>('transactions')
        : await Hive.openBox<TransactionModel>('transactions');
  }

  //biến lọc
  String _filterType = 'all';
  Future<bool> _confirmDelete(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Xác nhận xóa"),
            content: const Text("Bạn có chắc muốn xóa giao dịch này không?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text("Hủy", style: TextStyle(color: Colors.black),),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text("Xóa", style: TextStyle(color: Colors.black),),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Box<TransactionModel>>(
      future: _openTransactionBox(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final box = snapshot.data!;
        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            title: const Text(
              "Ghi chú Thu Chi",
              style: TextStyle(fontSize: 30),
            ),
            centerTitle: true,
            toolbarHeight: 80,
            backgroundColor: Colors.transparent,
            elevation: 2,
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF6B43FF), Color(0xFF8B5FFF)],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
              ),
            ),
            actions: [
              PopupMenuButton<String>(
                icon: const Icon(Icons.filter_list_alt, size: 30),
                onSelected: (value) {
                  setState(() {
                    _filterType = value;
                  });
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'all', child: Text("Tất cả")),
                  const PopupMenuItem(
                    value: 'income',
                    child: Text("Lọc Thu nhập"),
                  ),
                  const PopupMenuItem(
                    value: 'expense',
                    child: Text("Lọc Chi tiêu"),
                  ),
                ],
              ),
            ],
          ),
          body: ValueListenableBuilder(
            valueListenable: box.listenable(),
            builder: (context, Box<TransactionModel> box, _) {
              final allTxns = TransactionService.getSortedTransactions(box);

              final transactions = allTxns.where((txn) {
                if (_filterType == 'income') return txn.isIncome;
                if (_filterType == 'expense') return !txn.isIncome;
                return true;
              }).toList();

              final totals = TransactionService.calculateTotals(allTxns);
              final totalIncome = totals['income']!;
              final totalExpense = totals['expense']!;
              final balance = totals['balance']!;

              return Column(
                children: [
                  Container(
                    margin: const EdgeInsets.all(16),
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
                      children: [
                        const Text(
                          'Tổng số dư',
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${_formatAmount(balance)} đ',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatItem(
                              icon: Icons.arrow_downward,
                              label: 'Thu nhập',
                              amount: totalIncome,
                              color: Colors.greenAccent,
                            ),
                            Container(
                              height: 40,
                              width: 1,
                              color: Colors.white30,
                            ),
                            _buildStatItem(
                              icon: Icons.arrow_upward,
                              label: 'Chi tiêu',
                              amount: totalExpense,
                              color: Colors.redAccent,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: transactions.isEmpty
                        ? const Center(
                            child: Text(
                              "Không có giao dịch nào",
                              style: TextStyle(fontSize: 20),
                            ),
                          )
                        : ListView.builder(
                            itemCount: transactions.length,
                            itemBuilder: (context, index) {
                              final txn = transactions[index];
                              return Dismissible(
                                key: ValueKey(txn.id),
                                background: Container(
                                  color: Colors.red,
                                  alignment: Alignment.centerLeft,
                                  padding: const EdgeInsets.only(left: 20),
                                  child: const Icon(
                                    Icons.delete,
                                    color: Colors.white,
                                  ),
                                ),
                                secondaryBackground: Container(
                                  color: Colors.red,
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 20),
                                  child: const Icon(
                                    Icons.delete,
                                    color: Colors.white,
                                  ),
                                ),
                                confirmDismiss: (_) => _confirmDelete(context),
                                onDismissed: (_) async {
                                  await TransactionService.deleteTransaction(
                                    txn,
                                  );
                                  ScaffoldMessenger.of(
                                    _scaffoldKey.currentContext!,
                                  ).showSnackBar(
                                    SnackBar(
                                      content: const Text("Đã xóa giao dịch"),
                                      behavior: SnackBarBehavior.floating,
                                      margin: const EdgeInsets.all(12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  );
                                },
                                child: Card(
                                  color: Theme.of(context).cardColor,
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  child: ListTile(
                                    leading: Icon(
                                      txn.isIncome
                                          ? Icons.arrow_downward
                                          : Icons.arrow_upward,
                                      color: txn.isIncome
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                    title: Text(txn.note),
                                    subtitle: Text(
                                      "${txn.isIncome ? "Thu nhập" : "Chi tiêu"} • ${_formatDate(txn.date)}",
                                    ),
                                    trailing: Text(
                                      "${_formatAmount(txn.amount)} đ",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: txn.isIncome
                                            ? Colors.green
                                            : Colors.red,
                                      ),
                                    ),
                                    onLongPress: () =>
                                        _showOptions(context, txn),
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
      },
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required double amount,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        const SizedBox(height: 4),
        Text(
          '${_formatAmount(amount)} đ',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  void _showOptions(BuildContext context, TransactionModel txn) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.blue),
              title: const Text("Sửa"),
              onTap: () {
                Navigator.pop(ctx);
                _showEditDialog(txn);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text("Xóa"),
              onTap: () async {
                Navigator.pop(ctx);
                final confirmed = await _confirmDelete(context);
                if (!confirmed) return;
                await TransactionService.deleteTransaction(txn);
                ScaffoldMessenger.of(_scaffoldKey.currentContext!).showSnackBar(
                  const SnackBar(content: Text("Đã xóa giao dịch")),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(TransactionModel txn) {
    final noteController = TextEditingController(text: txn.note);
    final amountController = TextEditingController(
      text: _formatAmount(txn.amount),
    );

    showDialog(
      context: _scaffoldKey.currentContext!,
      builder: (context) {
        return AlertDialog(
          title: const Text("Sửa giao dịch"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: noteController,
                decoration: const InputDecoration(labelText: "Nội dung"),
              ),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Số tiền"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Hủy"),
            ),
            ElevatedButton(
              onPressed: () async {
                final newNote = noteController.text.trim();
                final raw = amountController.text.trim().replaceAll(',', '');
                final newAmount = double.tryParse(raw) ?? txn.amount;
                if (newNote.isNotEmpty) {
                  await TransactionService.updateTransaction(
                    txn,
                    newNote,
                    newAmount,
                  );
                  Navigator.pop(context);
                }
              },
              child: const Text("Lưu"),
            ),
          ],
        );
      },
    );
  }
}
