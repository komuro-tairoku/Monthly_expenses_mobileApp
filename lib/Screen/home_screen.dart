import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../db/transaction.dart';
import '../Services/transaction_service.dart';
import '../Services/category_translator.dart';
import '../l10n/app_localizations.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final NumberFormat _amountFormatter = NumberFormat('#,##0', 'en_US');
  String _formatAmount(double value) => _amountFormatter.format(value);
  String _formatDate(DateTime date) =>
      DateFormat('dd/MM/yyyy HH:mm').format(date);

  Future<Box<TransactionModel>> _openTransactionBox() async {
    return Hive.isBoxOpen('transactions')
        ? Hive.box<TransactionModel>('transactions')
        : await Hive.openBox<TransactionModel>('transactions');
  }

  String _filterType = 'all';

  /// Translate category if it matches a known category, otherwise return original
  String _translateCategory(String category) {
    final translationKey = CategoryTranslator.getTranslationKey(category);
    if (CategoryTranslator.isTranslatable(category)) {
      return AppLocalizations.of(context).t(translationKey);
    }
    return category;
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(AppLocalizations.of(ctx).t('home.confirm_delete')),
            content: Text(AppLocalizations.of(ctx).t('home.are_you_sure')),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(
                  AppLocalizations.of(ctx).t('home.cancel'),
                  style: const TextStyle(color: Colors.black),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(
                  AppLocalizations.of(ctx).t('home.del'),
                  style: const TextStyle(color: Colors.black),
                ),
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
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            title: Text(
              AppLocalizations.of(context).t('home.title'),
              style: const TextStyle(fontSize: 30),
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
                  PopupMenuItem(
                    value: 'all',
                    child: Text(AppLocalizations.of(context).t('home.all')),
                  ),
                  PopupMenuItem(
                    value: 'income',
                    child: Text(
                      AppLocalizations.of(context).t("home.filter_income"),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'expense',
                    child: Text(
                      AppLocalizations.of(context).t("home.filter_espense"),
                    ),
                  ),
                ],
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 30),
                onSelected: (value) async {
                  if (value == 'delete_all') {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Xóa tất cả giao dịch'),
                        content: const Text(
                          'Bạn có chắc muốn xóa tất cả giao dịch? Hành động này không thể hoàn tác.',
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

                    if (confirm != true) return;

                    final box = Hive.box<TransactionModel>('transactions');

                    // ====== XÓA LOCAL ======
                    await box.clear(); // Xóa hết local
                    await box
                        .compact(); // Thu gọn file để chắc chắn không còn sót dữ liệu

                    // ====== XÓA FIREBASE ======
                    final user = FirebaseAuth.instance.currentUser;
                    if (user != null && !user.isAnonymous) {
                      try {
                        final ref = FirebaseFirestore.instance
                            .collection('transactions')
                            .doc(user.uid)
                            .collection('items');

                        final snapshot = await ref.get();

                        WriteBatch batch = FirebaseFirestore.instance.batch();

                        for (var doc in snapshot.docs) {
                          batch.delete(doc.reference);
                        }

                        await batch.commit();

                        print(
                          '🔥 Đã xóa sạch Firebase: ${snapshot.docs.length} giao dịch',
                        );
                      } catch (e) {
                        print('❌ Lỗi khi xóa Firebase: $e');
                      }
                    }

                    // ====== REFRESH UI ======
                    if (mounted) {
                      setState(() {});
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Đã xóa tất cả giao dịch thành công!'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    }
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'delete_all',
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
                        Text(
                          AppLocalizations.of(context).t('home.balance'),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
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
                              label: AppLocalizations.of(
                                context,
                              ).t('home.income'),
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
                              label: AppLocalizations.of(
                                context,
                              ).t('home.expense'),
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
                        ? Center(
                            child: Text(
                              AppLocalizations.of(
                                context,
                              ).t('home.no_transactions'),
                              style: const TextStyle(fontSize: 20),
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
                                  // Lưu references trước khi thực hiện async operation
                                  final scaffoldMessenger =
                                      ScaffoldMessenger.of(context);
                                  final localizations = AppLocalizations.of(
                                    context,
                                  );

                                  await TransactionService.deleteTransaction(
                                    txn,
                                  );

                                  scaffoldMessenger.showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        localizations.t("home.del_success"),
                                      ),
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
                                    title: Text(_translateCategory(txn.note)),
                                    subtitle: Text(
                                      "${txn.isIncome ? AppLocalizations.of(context).t("home.income") : AppLocalizations.of(context).t("home.expense")} • ${_formatDate(txn.date)}",
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
              title: Text(AppLocalizations.of(context).t("home.edit")),
              onTap: () {
                Navigator.pop(ctx);
                _showEditDialog(txn);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: Text(AppLocalizations.of(context).t("home.del")),
              onTap: () async {
                Navigator.pop(ctx);
                final confirmed = await _confirmDelete(context);
                if (!confirmed) return;

                // Lưu references trước khi thực hiện async operation
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                final localizations = AppLocalizations.of(context);

                await TransactionService.deleteTransaction(txn);

                scaffoldMessenger.showSnackBar(
                  SnackBar(content: Text(localizations.t("home.del_success"))),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(TransactionModel txn) {
    final noteController = TextEditingController(
      text: _translateCategory(txn.note),
    );
    final amountController = TextEditingController(
      text: _formatAmount(txn.amount),
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context).t("home.edit_transaction")),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: noteController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context).t("home.content"),
                ),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context).t("home.money"),
                ),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context).t("home.cancel")),
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
              child: Text(AppLocalizations.of(context).t("home.save")),
            ),
          ],
        );
      },
    );
  }
}
