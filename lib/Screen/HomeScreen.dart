import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../db/transaction.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ✅ Thêm GlobalKey để có context ổn định
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  String _formatAmount(double value) {
    return value.toStringAsFixed(0);
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  Future<void> _deleteTransaction(TransactionModel txn) async {
    final user = FirebaseAuth.instance.currentUser;
    await txn.delete();

    if (txn.isSynced && user != null) {
      try {
        await FirebaseFirestore.instance
            .collection('transactions')
            .doc(user.uid)
            .collection('items')
            .doc(txn.id)
            .delete();
      } catch (e) {
        debugPrint("❌ Lỗi xóa từ Firebase: $e");
        txn.isSynced = false;
        await txn.save();
      }
    }
  }

  Future<void> _updateTransaction(
    TransactionModel txn,
    String newNote,
    double newAmount,
  ) async {
    final user = FirebaseAuth.instance.currentUser;

    txn.note = newNote;
    txn.amount = newAmount;
    await txn.save();
    if (txn.isSynced && user != null) {
      try {
        final ref = FirebaseFirestore.instance
            .collection('transactions')
            .doc(user.uid)
            .collection('items')
            .doc(txn.id);

        await ref.update({
          'note': newNote,
          'label': newNote,
          'amount': newAmount,
        });
      } catch (e) {
        debugPrint("❌ Lỗi cập nhật Firebase: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey, // ✅ Gắn key vào Scaffold
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Ghi chú Thu Chi"),
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 2,
      ),
      body: ValueListenableBuilder(
        valueListenable: Hive.box<TransactionModel>(
          'transactions',
        ).listenable(),
        builder: (context, Box<TransactionModel> box, _) {
          final transactions = box.values.toList()
            ..sort((a, b) => b.date.compareTo(a.date));

          double totalIncome = 0;
          double totalExpense = 0;

          for (var txn in transactions) {
            if (txn.isIncome) {
              totalIncome += txn.amount;
            } else {
              totalExpense += txn.amount;
            }
          }

          final balance = totalIncome - totalExpense;

          return Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 18,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                ),
                child: SafeArea(
                  bottom: false,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStatCard(
                        label: 'Tổng thu',
                        value: _formatAmount(totalIncome),
                        valueColor: Colors.greenAccent.shade400,
                        context: context,
                      ),
                      _buildStatCard(
                        label: 'Chi tiêu',
                        value: _formatAmount(totalExpense),
                        valueColor: Colors.redAccent.shade400,
                        context: context,
                      ),
                      _buildStatCard(
                        label: 'Còn lại',
                        value: _formatAmount(balance),
                        valueColor: Colors.white,
                        context: context,
                        emphasize: true,
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: transactions.isEmpty
                    ? const Center(
                        child: Text(
                          "Chưa có giao dịch nào",
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
                            onDismissed: (_) async {
                              await _deleteTransaction(txn);

                              final messenger = ScaffoldMessenger.of(
                                _scaffoldKey.currentContext!,
                              );
                              messenger.showSnackBar(
                                SnackBar(
                                  content: const Text("Đã xóa giao dịch"),
                                  behavior: SnackBarBehavior.floating,
                                  margin: const EdgeInsets.all(12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  duration: const Duration(seconds: 2),
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
                                onLongPress: () {
                                  _showOptions(context, txn);
                                },
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
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required Color valueColor,
    required BuildContext context,
    bool emphasize = false,
  }) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFFE0E0E0),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "$value đ",
              style: TextStyle(
                fontSize: 18,
                fontWeight: emphasize ? FontWeight.bold : FontWeight.w600,
                color: valueColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showOptions(BuildContext context, TransactionModel txn) {
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
                  _showEditDialog(txn);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text("Xóa"),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _deleteTransaction(txn);
                  final messenger = ScaffoldMessenger.of(
                    _scaffoldKey.currentContext!,
                  );
                  messenger.showSnackBar(
                    SnackBar(
                      content: const Text("Đã xóa giao dịch"),
                      behavior: SnackBarBehavior.floating,
                      margin: const EdgeInsets.all(12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEditDialog(TransactionModel txn) {
    final noteController = TextEditingController(text: txn.note);
    final amountController = TextEditingController(text: txn.amount.toString());

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
              onPressed: () async {
                final newNote = noteController.text.trim();
                final newAmount =
                    double.tryParse(amountController.text.trim()) ?? txn.amount;

                if (newNote.isNotEmpty) {
                  await _updateTransaction(txn, newNote, newAmount);
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
