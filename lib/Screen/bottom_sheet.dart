import 'dart:async';
import 'package:animated_toggle_switch/animated_toggle_switch.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../db/transaction.dart';
import '../Services/hive_helper.dart';

class bottomSheet extends StatefulWidget {
  const bottomSheet({super.key});

  @override
  State<bottomSheet> createState() => _BottomSheetState();
}

class _BottomSheetState extends State<bottomSheet> {
  int value = 0;
  final PageController _pageController = PageController();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  String _amountRaw = "";
  String? selectedCategory;
  String note = "";

  String _formatWithCommas(String digits) {
    if (digits.isEmpty) return '0';
    // remove any non-digit just in case
    final s = digits.replaceAll(RegExp(r'[^0-9]'), '');
    if (s.isEmpty) return '0';
    final buffer = StringBuffer();
    int len = s.length;
    int firstGroup = len % 3;
    if (firstGroup == 0) firstGroup = 3;
    buffer.write(s.substring(0, firstGroup));
    for (int i = firstGroup; i < len; i += 3) {
      buffer.write(',');
      buffer.write(s.substring(i, i + 3));
    }
    return buffer.toString();
  }

  final List<Map<String, dynamic>> chiOptions = [
    {"icon": Icons.shopping_cart, "label": "Mua sắm"},
    {"icon": Icons.fastfood, "label": "Đồ ăn"},
    {"icon": Icons.phone_android, "label": "Điện thoại"},
    {"icon": Icons.sports_esports, "label": "Giải trí"},
    {"icon": Icons.school, "label": "Giáo dục"},
    {"icon": Icons.brush, "label": "Sắc đẹp"},
    {"icon": Icons.sports_soccer, "label": "Thể thao"},
    {"icon": Icons.people, "label": "Xã hội"},
    {"icon": Icons.directions_bus, "label": "Vận tải"},
    {"icon": Icons.checkroom, "label": "Quần áo"},
    {"icon": Icons.directions_car, "label": "Xe hơi"},
    {"icon": Icons.local_bar, "label": "Rượu"},
  ];

  final List<Map<String, dynamic>> thuOptions = [
    {"icon": Icons.payments, "label": "Tiền lương"},
    {"icon": Icons.card_giftcard, "label": "Phụ cấp"},
    {"icon": Icons.star, "label": "Thưởng"},
  ];

  @override
  void initState() {
    super.initState();

    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      results,
    ) {
      if (results.isNotEmpty && results.first != ConnectivityResult.none) {
        Future.delayed(const Duration(milliseconds: 500), () {
          _syncUnsyncedTransactions();
        });
      }
    });
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _syncUnsyncedTransactions() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final connectivityResults = await Connectivity().checkConnectivity();
      if (connectivityResults.isEmpty ||
          connectivityResults.first == ConnectivityResult.none)
        return;

      final box = await HiveHelper.getTransactionBox();
      final unsynced = box.values.where((t) => !t.isSynced).toList();
      if (unsynced.isEmpty) return;
      Future(() async {
        try {
          final batch = FirebaseFirestore.instance.batch();
          for (var txn in unsynced) {
            final docRef = FirebaseFirestore.instance
                .collection('transactions')
                .doc(user.uid)
                .collection('items')
                .doc(txn.id);

            batch.set(docRef, {
              'id': txn.id,
              'category': txn.category,
              'amount': txn.amount,
              'note': txn.note,
              'label': txn.note,
              'date': Timestamp.fromDate(txn.date),
              'isIncome': txn.isIncome,
            }, SetOptions(merge: true));
          }
          await batch.commit();
        } catch (_) {}
      });
    } catch (e) {}
  }

  Future<void> _saveTransaction(TransactionModel txn) async {
    final box = await HiveHelper.getTransactionBox();
    box.put(txn.id, txn);

    Future(() async {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      try {
        final connectivityResults = await Connectivity().checkConnectivity();
        if (connectivityResults.isEmpty ||
            connectivityResults.first == ConnectivityResult.none)
          return;

        await FirebaseFirestore.instance
            .collection('transactions')
            .doc(user.uid)
            .collection('items')
            .doc(txn.id)
            .set({
              'id': txn.id,
              'category': txn.category,
              'amount': txn.amount,
              'note': txn.note,
              'label': txn.note,
              'date': Timestamp.fromDate(txn.date),
              'isIncome': txn.isIncome,
            }, SetOptions(merge: true));
      } catch (_) {}
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
      ),
      child: SizedBox(
        height: MediaQuery.of(context).size.height,
        child: Column(
          children: [
            Container(
              height: 150,
              decoration: const BoxDecoration(color: Color(0xFF6B43FF)),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    top: 50,
                    child: Column(
                      children: [
                        const Text(
                          'Thêm Thu - Chi',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        AnimatedToggleSwitch<int>.size(
                          animationDuration: const Duration(milliseconds: 300),
                          current: value,
                          values: const [0, 1],
                          indicatorSize: const Size(100, 35),
                          borderWidth: 5,
                          style: ToggleStyle(
                            borderColor: Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            indicatorColor: Colors.grey.shade300,
                          ),
                          styleBuilder: (i) =>
                              ToggleStyle(indicatorColor: Colors.green[600]),
                          iconBuilder: (i) => Center(
                            child: Text(
                              i == 0 ? "Tiền Chi" : "Tiền Thu",
                              style: Theme.of(
                                context,
                              ).textTheme.bodySmall?.copyWith(fontSize: 17),
                            ),
                          ),
                          onChanged: (i) {
                            setState(() => value = i);
                            _pageController.animateToPage(
                              i,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 0,
                    top: 35,
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.arrow_back_ios_new,
                        size: 25,
                        color: Color(0xFFE0E0E0),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (i) => setState(() => value = i),
                children: [
                  buildOptionGrid(chiOptions),
                  buildOptionGrid(thuOptions),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildOptionGrid(List<Map<String, dynamic>> options) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemCount: options.length,
      itemBuilder: (context, index) {
        final option = options[index];
        return GestureDetector(
          onTap: () {
            _showAmountSheet(option['label']);
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Theme.of(context).cardColor,
                child: Icon(
                  option['icon'],
                  size: 28,
                  color: const Color(0xFF6B43FF),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                option['label'],
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAmountSheet(String category) {
    setState(() => selectedCategory = category);
    _amountRaw = "";
    note = "";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            void addNumber(String num) {
              setModalState(() => _amountRaw += num);
            }

            void deleteNumber() {
              if (_amountRaw.isNotEmpty) {
                setModalState(
                  () => _amountRaw = _amountRaw.substring(
                    0,
                    _amountRaw.length - 1,
                  ),
                );
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Danh mục: $category",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _formatWithCommas(_amountRaw),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: "Ghi chú",
                      labelStyle: TextStyle(fontSize: 20),
                    ),
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium!.copyWith(fontSize: 20),
                    onChanged: (val) => note = val,
                  ),
                  const SizedBox(height: 16),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: 12,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 1.5,
                        ),
                    itemBuilder: (context, index) {
                      if (index == 9) {
                        return TextButton(
                          onPressed: deleteNumber,
                          child: const Icon(Icons.backspace),
                        );
                      } else if (index == 10) {
                        return TextButton(
                          onPressed: () => addNumber("0"),
                          child: const Text("0"),
                        );
                      } else if (index == 11) {
                        return ElevatedButton(
                          onPressed: () {
                            if (_amountRaw.isNotEmpty &&
                                double.tryParse(_amountRaw) != null &&
                                double.parse(_amountRaw) > 0 &&
                                selectedCategory != null) {
                              final txn = TransactionModel(
                                id: DateTime.now().millisecondsSinceEpoch
                                    .toString(),
                                note: note.isNotEmpty
                                    ? note
                                    : selectedCategory!,
                                amount: double.parse(_amountRaw),
                                isIncome: value == 1,
                                category: selectedCategory!,
                                date: DateTime.now(),
                                isSynced: false,
                              );

                              // Fire and forget: persist locally and upload in background
                              _saveTransaction(txn);

                              if (mounted) {
                                // Close sheets and show snackbar
                                Navigator.of(context).pop();
                                Navigator.of(context).pop();

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        const Icon(
                                          Icons.check_circle,
                                          color: Colors.white,
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          value == 1
                                              ? "Đã thêm thu nhập!"
                                              : "Đã thêm chi tiêu!",
                                        ),
                                      ],
                                    ),
                                    backgroundColor: Colors.green.shade600,
                                    behavior: SnackBarBehavior.floating,
                                    margin: const EdgeInsets.all(16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              }
                            }
                          },
                          child: const Icon(Icons.check),
                        );
                      }
                      return TextButton(
                        onPressed: () => addNumber("${index + 1}"),
                        child: Text(
                          "${index + 1}",
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
