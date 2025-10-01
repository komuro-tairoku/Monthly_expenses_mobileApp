import 'dart:async';
import 'package:animated_toggle_switch/animated_toggle_switch.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive/hive.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../db/transaction.dart';

class bottomSheet extends StatefulWidget {
  const bottomSheet({super.key});

  @override
  State<bottomSheet> createState() => _bottomSheetState();
}

class _bottomSheetState extends State<bottomSheet> {
  int value = 0;
  final PageController _pageController = PageController();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  String amount = "";
  String? selectedCategory;
  String note = "";

  Box<TransactionModel> get transactionBox =>
      Hive.box<TransactionModel>('transactions');

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
    _syncUnsyncedTransactions();

    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      results,
    ) {
      if (results.isNotEmpty && results.first != ConnectivityResult.none) {
        _syncUnsyncedTransactions();
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
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        debugPrint("Không có kết nối mạng");
        return;
      }

      final unsynced = transactionBox.values.where((t) => !t.isSynced).toList();

      if (unsynced.isEmpty) {
        debugPrint("Không có transaction nào cần sync");
        return;
      }

      debugPrint("Đang sync ${unsynced.length} transaction...");

      for (var txn in unsynced) {
        try {
          await FirebaseFirestore.instance
              .collection('transactions')
              .doc(user.uid)
              .collection('items')
              .doc(txn.id) // 👉 dùng id làm docId
              .set({
                'id': txn.id,
                'category': txn.category,
                'amount': txn.amount,
                'note': txn.note,
                'label': txn.note,
                'date': Timestamp.fromDate(txn.date),
                'isIncome': txn.isIncome,
              }, SetOptions(merge: true));

          txn.isSynced = true;
          await txn.save();

          debugPrint("Đã sync transaction: ${txn.id}");
        } catch (e) {
          debugPrint("Lỗi sync transaction ${txn.id}: $e");
        }
      }

      debugPrint("Hoàn tất sync!");
    } catch (e) {
      debugPrint("Lỗi khi sync: $e");
    }
  }

  Future<void> _saveTransaction(TransactionModel txn) async {
    await transactionBox.add(txn);
    debugPrint("Đã lưu vào Hive");

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final connectivityResult = await Connectivity().checkConnectivity();

        if (connectivityResult.isEmpty ||
            connectivityResult.first == ConnectivityResult.none) {
          debugPrint("Offline - sẽ sync sau");
          return;
        }

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
            });

        txn.isSynced = true;
        await txn.save();
        debugPrint("Đã sync lên Firebase ngay");
      } catch (e) {
        debugPrint("Không sync được, sẽ thử lại sau: $e");
      }
    }
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
    amount = "";
    note = "";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            void addNumber(String num) {
              setModalState(() => amount += num);
            }

            void deleteNumber() {
              if (amount.isNotEmpty) {
                setModalState(
                  () => amount = amount.substring(0, amount.length - 1),
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
                    amount.isEmpty ? "0" : amount,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium!.copyWith(fontSize: 20),
                    decoration: const InputDecoration(labelText: "Ghi chú"),
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
                          onPressed: () async {
                            if (amount.isNotEmpty &&
                                double.tryParse(amount) != null &&
                                double.parse(amount) > 0 &&
                                selectedCategory != null) {
                              final txn = TransactionModel(
                                id: DateTime.now().millisecondsSinceEpoch
                                    .toString(),
                                note: note.isNotEmpty
                                    ? note
                                    : selectedCategory!,
                                amount: double.parse(amount),
                                isIncome: value == 1,
                                category: selectedCategory!,
                                date: DateTime.now(),
                                isSynced: false,
                              );

                              await _saveTransaction(txn);

                              if (mounted) {
                                final connectivityResult = await Connectivity()
                                    .checkConnectivity();
                                final isOnline =
                                    connectivityResult.isNotEmpty &&
                                    connectivityResult.first !=
                                        ConnectivityResult.none;

                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text("Thành công"),
                                    content: Text(
                                      value == 1
                                          ? "Đã thêm thu nhập!}"
                                          : "Đã thêm chi tiêu!",
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(ctx).pop();
                                          Navigator.of(context).pop();
                                          Navigator.of(context).pop();
                                        },
                                        child: const Text("OK"),
                                      ),
                                    ],
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
