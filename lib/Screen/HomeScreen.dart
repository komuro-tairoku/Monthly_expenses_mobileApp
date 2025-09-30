import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _formatAmount(double value) {
    return value.toStringAsFixed(0);
  }

  String _formatDate(Timestamp? date) {
    if (date == null) return "Không rõ ngày";
    final d = date.toDate();
    return DateFormat('dd/MM/yyyy HH:mm').format(d);
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text("Chưa đăng nhập")));
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Ghi chú Thu Chi"),
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 2,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("transactions")
            .doc(user.uid)
            .collection("items")
            .orderBy("date", descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          double totalIncome = 0;
          double totalExpense = 0;
          double balance = 0;

          final transactions = snapshot.data?.docs ?? [];

          for (var doc in transactions) {
            final data = doc.data() as Map<String, dynamic>;
            final amount = (data['amount'] as num).toDouble();
            final isIncome = data['isIncome'] ?? false;
            if (isIncome) {
              totalIncome += amount;
            } else {
              totalExpense += amount;
            }
          }
          balance = totalIncome - totalExpense;

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

              // List giao dịch
              Expanded(
                child: snapshot.connectionState == ConnectionState.waiting
                    ? const Center(child: CircularProgressIndicator())
                    : transactions.isEmpty
                    ? const Center(
                        child: Text(
                          "Chưa có giao dịch nào",
                          style: TextStyle(fontSize: 20),
                        ),
                      )
                    : ListView.builder(
                        itemCount: transactions.length,
                        itemBuilder: (context, index) {
                          final doc = transactions[index];
                          final data = doc.data() as Map<String, dynamic>;
                          final isIncome = data['isIncome'] ?? false;

                          return Dismissible(
                            key: ValueKey(doc.id),
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
                            onDismissed: (_) {
                              FirebaseFirestore.instance
                                  .collection("transactions")
                                  .doc(user.uid)
                                  .collection("items")
                                  .doc(doc.id)
                                  .delete();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Đã xóa giao dịch"),
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
                                  isIncome
                                      ? Icons.arrow_downward
                                      : Icons.arrow_upward,
                                  color: isIncome ? Colors.green : Colors.red,
                                ),
                                title: Text(data['label'] ?? ""),
                                subtitle: Text(
                                  "${isIncome ? "Thu nhập" : "Chi tiêu"} • ${_formatDate(data['date'])}",
                                ),
                                trailing: Text(
                                  "${_formatAmount((data['amount'] as num).toDouble())} đ",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isIncome ? Colors.green : Colors.red,
                                  ),
                                ),
                                onLongPress: () {
                                  _showOptions(context, user.uid, doc.id, data);
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

  void _showOptions(
    BuildContext context,
    String uid,
    String docId,
    Map<String, dynamic> data,
  ) {
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
                  _showEditDialog(uid, docId, data);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text("Xóa"),
                onTap: () {
                  Navigator.pop(ctx);
                  FirebaseFirestore.instance
                      .collection("transactions")
                      .doc(uid)
                      .collection("items")
                      .doc(docId)
                      .delete();
                  ScaffoldMessenger.of(context).showSnackBar(
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

  void _showEditDialog(String uid, String docId, Map<String, dynamic> data) {
    final labelController = TextEditingController(text: data['label'] ?? "");
    final amountController = TextEditingController(
      text: (data['amount']).toString(),
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Sửa giao dịch"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: labelController,
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
              onPressed: () {
                final newLabel = labelController.text.trim();
                final newAmount =
                    double.tryParse(amountController.text.trim()) ?? 0;

                FirebaseFirestore.instance
                    .collection("transactions")
                    .doc(uid)
                    .collection("items")
                    .doc(docId)
                    .update({
                      "label": newLabel.isNotEmpty ? newLabel : data['label'],
                      "amount": newAmount,
                      "isIncome": data['isIncome'],
                      "category": data['category'],
                      "date": data['date'],
                    });

                Navigator.pop(context);
              },
              child: const Text("Lưu"),
            ),
          ],
        );
      },
    );
  }
}
