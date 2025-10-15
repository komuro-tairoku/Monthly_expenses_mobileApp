import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../db/transaction.dart';
import '../Services/hive_helper.dart';
import '../l10n/app_localizations.dart';

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
    {"icon": Icons.shopping_cart, "labelKey": "sheet.shopping"},
    {"icon": Icons.fastfood, "labelKey": "sheet.food"},
    {"icon": Icons.phone_android, "labelKey": "sheet.phone"},
    {"icon": Icons.sports_esports, "labelKey": "sheet.entertainment"},
    {"icon": Icons.school, "labelKey": "sheet.education"},
    {"icon": Icons.brush, "labelKey": "sheet.beauty"},
    {"icon": Icons.sports_soccer, "labelKey": "sheet.sports"},
    {"icon": Icons.people, "labelKey": "sheet.social"},
    {"icon": Icons.home, "labelKey": "sheet.housing"},
    {"icon": Icons.electric_bolt_outlined, "labelKey": "sheet.electricity"},
    {"icon": Icons.water_drop_rounded, "labelKey": "sheet.water"},
    {"icon": Icons.checkroom, "labelKey": "sheet.clothes"},
    {"icon": Icons.directions_car, "labelKey": "sheet.transport"},
    {"icon": Icons.add, "labelKey": "sheet.other_expense"},
  ];

  final List<Map<String, dynamic>> thuOptions = [
    {"icon": Icons.payments, "labelKey": "sheet.salary"},
    {"icon": Icons.card_giftcard, "labelKey": "sheet.allowance"},
    {"icon": Icons.star, "labelKey": "sheet.bonus"},
    {"icon": Icons.add, "labelKey": "sheet.other_income"},
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

    // 🔹 Kiểm tra guest mode
    if (user == null || user.isAnonymous) {
      print("🟡 Guest mode: không sync Firebase");
      return;
    }

    try {
      final connectivityResults = await Connectivity().checkConnectivity();
      if (connectivityResults.isEmpty ||
          connectivityResults.first == ConnectivityResult.none) {
        return;
      }

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

          for (var txn in unsynced) {
            txn.isSynced = true;
            await txn.save();
          }
          print("✅ Đã sync ${unsynced.length} giao dịch");
        } catch (e) {
          print("❌ Lỗi khi sync: $e");
        }
      });
    } catch (e) {
      print("❌ Lỗi trong _syncUnsyncedTransactions: $e");
    }
  }

  Future<void> _saveTransaction(TransactionModel txn) async {
    final box = await HiveHelper.getTransactionBox();
    box.put(txn.id, txn);

    final user = FirebaseAuth.instance.currentUser;

    if (user == null || user.isAnonymous) {
      print("🟡 Guest mode: chỉ lưu local, không sync Firebase");
      return;
    }

    Future(() async {
      try {
        final connectivityResults = await Connectivity().checkConnectivity();
        if (connectivityResults.isEmpty ||
            connectivityResults.first == ConnectivityResult.none) {
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
            }, SetOptions(merge: true));

        txn.isSynced = true;
        await txn.save();
        print("✅ Đã sync giao dịch lên Firebase");
      } catch (e) {
        print("❌ Lỗi khi sync Firebase: $e");
      }
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
              height: 180,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [const Color(0xFF6B43FF), const Color(0xFF8B5FFF)],
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    top: 50,
                    child: Column(
                      children: [
                        Text(
                          AppLocalizations.of(
                            context,
                          ).t("sheet.add_transaction"),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildToggleButton(
                                context,
                                label: AppLocalizations.of(
                                  context,
                                ).t('sheet.expense'),
                                icon: Icons.arrow_upward_rounded,
                                isSelected: value == 0,
                                color: Colors.red.shade400,
                                onTap: () {
                                  setState(() => value = 0);
                                  _pageController.animateToPage(
                                    0,
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                  );
                                },
                              ),
                              const SizedBox(width: 8),
                              _buildToggleButton(
                                context,
                                label: AppLocalizations.of(
                                  context,
                                ).t('sheet.income'),
                                icon: Icons.arrow_downward_rounded,
                                isSelected: value == 1,
                                color: Colors.green.shade400,
                                onTap: () {
                                  setState(() => value = 1);
                                  _pageController.animateToPage(
                                    1,
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 8,
                    top: 40,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => Navigator.pop(context),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          child: const Icon(
                            Icons.arrow_back_ios_new,
                            size: 24,
                            color: Colors.white,
                          ),
                        ),
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
        final String label = AppLocalizations.of(
          context,
        ).t(option['labelKey'] ?? '');
        return GestureDetector(
          onTap: () {
            // Pass the translated label for display, but we'll store it properly
            _showAmountSheet(label);
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
                label,
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

    final noteController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            void addNumber(String num) {
              setModalState(() => _amountRaw += num);
            }

            void deleteNumber() {
              if (_amountRaw.isNotEmpty) {
                setModalState(() {
                  _amountRaw = _amountRaw.substring(0, _amountRaw.length - 1);
                });
              }
            }

            List<int> getSuggestions() {
              if (_amountRaw.isEmpty) return [];
              final currentValue = int.tryParse(_amountRaw);
              if (currentValue == null) return [];

              if (currentValue <= 1000) {
                return [
                  currentValue * 1000,
                  currentValue * 10000,
                  currentValue * 100000,
                ];
              }
              return [];
            }

            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 20,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 16),

                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6B43FF).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            category,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF6B43FF),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFF6B43FF).withOpacity(0.2),
                              width: 2,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _formatWithCommas(_amountRaw),
                                style: Theme.of(context).textTheme.bodySmall!
                                    .copyWith(
                                      fontSize: 36,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "đ",
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w500,
                                  color:
                                      Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.grey.shade400
                                      : Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        if (getSuggestions().isNotEmpty)
                          Container(
                            height: 45,
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: getSuggestions().length,
                              itemBuilder: (context, index) {
                                final amount = getSuggestions()[index];
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: InkWell(
                                    onTap: () => setModalState(
                                      () => _amountRaw = amount.toString(),
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            const Color(
                                              0xFF6B43FF,
                                            ).withOpacity(0.1),
                                            const Color(
                                              0xFF6B43FF,
                                            ).withOpacity(0.05),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: const Color(
                                            0xFF6B43FF,
                                          ).withOpacity(0.2),
                                        ),
                                      ),
                                      child: Text(
                                        _formatWithCommas(amount.toString()),
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF6B43FF),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),

                        TextField(
                          controller: noteController,
                          decoration: InputDecoration(
                            labelText: AppLocalizations.of(
                              context,
                            ).t('sheet.note'),
                            labelStyle: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 20,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            prefixIcon: Icon(
                              Icons.edit_note,
                              color: Colors.grey.shade600,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium!.copyWith(fontSize: 20),
                          onChanged: (val) => note = val,
                        ),
                        const SizedBox(height: 20),

                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, -2),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: List.generate(3, (i) {
                                  return Expanded(
                                    child: _buildKeyButton(
                                      context,
                                      "${i + 1}",
                                      () => addNumber("${i + 1}"),
                                    ),
                                  );
                                }),
                              ),
                              const SizedBox(height: 12),

                              Row(
                                children: List.generate(3, (i) {
                                  return Expanded(
                                    child: _buildKeyButton(
                                      context,
                                      "${i + 4}",
                                      () => addNumber("${i + 4}"),
                                    ),
                                  );
                                }),
                              ),
                              const SizedBox(height: 12),

                              Row(
                                children: List.generate(3, (i) {
                                  return Expanded(
                                    child: _buildKeyButton(
                                      context,
                                      "${i + 7}",
                                      () => addNumber("${i + 7}"),
                                    ),
                                  );
                                }),
                              ),
                              const SizedBox(height: 12),

                              Row(
                                children: [
                                  Expanded(
                                    child: _buildKeyButton(
                                      context,
                                      null,
                                      deleteNumber,
                                      icon: Icons.backspace_outlined,
                                      color: Colors.red.shade400,
                                    ),
                                  ),
                                  Expanded(
                                    child: _buildKeyButton(
                                      context,
                                      "0",
                                      () => addNumber("0"),
                                    ),
                                  ),
                                  Expanded(
                                    child: _buildKeyButton(
                                      context,
                                      null,
                                      () {
                                        if (_amountRaw.isNotEmpty &&
                                            double.tryParse(_amountRaw) !=
                                                null &&
                                            double.parse(_amountRaw) > 0 &&
                                            selectedCategory != null) {
                                          final txn = TransactionModel(
                                            id: DateTime.now()
                                                .millisecondsSinceEpoch
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

                                          _saveTransaction(txn);

                                          if (mounted) {
                                            Navigator.of(context).pop();
                                            Navigator.of(context).pop();

                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
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
                                                backgroundColor:
                                                    Colors.green.shade600,
                                                behavior:
                                                    SnackBarBehavior.floating,
                                                margin: const EdgeInsets.all(
                                                  16,
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                duration: const Duration(
                                                  seconds: 2,
                                                ),
                                              ),
                                            );
                                          }
                                        }
                                      },
                                      icon: Icons.check_circle,
                                      color: const Color(0xFF6B43FF),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildToggleButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? color : Colors.white.withOpacity(0.7),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? color : Colors.white.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKeyButton(
    BuildContext context,
    String? text,
    VoidCallback onPressed, {
    IconData? icon,
    Color? color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 60,
            decoration: BoxDecoration(
              color: color != null
                  ? color.withOpacity(0.08)
                  : (isDark
                        ? Theme.of(
                            context,
                          ).scaffoldBackgroundColor.withOpacity(0.5)
                        : Colors.grey.shade100),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: color != null
                    ? color.withOpacity(0.3)
                    : Colors.grey.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Center(
              child: icon != null
                  ? Icon(
                      icon,
                      size: 26,
                      color:
                          color ??
                          (isDark
                              ? Colors.white.withOpacity(0.85)
                              : Colors.black87),
                    )
                  : Text(
                      text!,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? Colors.white.withOpacity(0.85)
                            : Colors.black87,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
