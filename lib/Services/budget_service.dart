import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../db/budget.dart';
import '../db/transaction.dart';

class BudgetService {
  static const String _boxName = 'budgets';

  /// Lấy box budgets
  static Future<Box<BudgetModel>> getBudgetBox() async {
    if (Hive.isBoxOpen(_boxName)) {
      return Hive.box<BudgetModel>(_boxName);
    }
    return await Hive.openBox<BudgetModel>(_boxName);
  }

  /// Lấy tất cả budget của tháng hiện tại
  static Future<List<BudgetModel>> getCurrentMonthBudgets() async {
    final box = await getBudgetBox();
    final now = DateTime.now();

    return box.values.where((budget) {
      return budget.month == now.month && budget.year == now.year;
    }).toList();
  }

  /// Lấy budget của một category cụ thể trong tháng hiện tại
  static Future<BudgetModel?> getBudgetForCategory(String category) async {
    final box = await getBudgetBox();
    final now = DateTime.now();

    try {
      return box.values.firstWhere((budget) {
        return budget.category == category &&
            budget.month == now.month &&
            budget.year == now.year;
      });
    } catch (e) {
      return null;
    }
  }

  /// Tạo hoặc cập nhật budget cho tháng hiện tại
  static Future<void> saveBudget({
    required String category,
    required double amount,
  }) async {
    final box = await getBudgetBox();
    final now = DateTime.now();

    // Tìm budget hiện có cho category và tháng hiện tại
    BudgetModel? existingBudget;
    try {
      existingBudget = box.values.firstWhere((budget) {
        return budget.category == category &&
            budget.month == now.month &&
            budget.year == now.year;
      });
    } catch (e) {
      existingBudget = null;
    }

    if (existingBudget != null) {
      // Cập nhật budget hiện có
      existingBudget.amount = amount;
      existingBudget.updatedAt = DateTime.now();
      existingBudget.isSynced = false;
      await existingBudget.save();

      // Sync to Firebase
      await _syncToFirebase(existingBudget);
    } else {
      // Tạo budget mới
      final id = '${category}_${now.month}_${now.year}';
      final budget = BudgetModel(
        id: id,
        category: category,
        amount: amount,
        month: now.month,
        year: now.year,
      );

      await box.add(budget);

      // Sync to Firebase
      await _syncToFirebase(budget);
    }
  }

  /// Xóa budget
  static Future<void> deleteBudget(BudgetModel budget) async {
    final user = FirebaseAuth.instance.currentUser;

    await budget.delete();

    // Xóa trên Firebase
    if (user != null && !user.isAnonymous && budget.isSynced) {
      try {
        await FirebaseFirestore.instance
            .collection('budgets')
            .doc(user.uid)
            .collection('items')
            .doc(budget.id)
            .delete();
        print("✅ Đã xóa budget trên Firebase");
      } catch (e) {
        print("❌ Lỗi khi xóa budget trên Firebase: $e");
      }
    }
  }

  /// Tính tổng chi tiêu của một category trong tháng
  static Future<double> getSpentAmountForCategory(
    String category,
    Box<TransactionModel> transactionBox,
    int month,
    int year,
  ) async {
    double total = 0;
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0, 23, 59, 59);

    // Debug
    print('🔍 Kiểm tra budget cho category: $category (tháng $month/$year)');
    int matchCount = 0;

    for (var txn in transactionBox.values) {
      // Kiểm tra nếu là chi tiêu (không phải thu nhập)
      if (txn.isIncome) continue;

      // Kiểm tra nếu transaction trong khoảng thời gian
      if (txn.date.isBefore(startDate) || txn.date.isAfter(endDate)) continue;

      // So sánh cả category và note vì transaction có thể lưu ở note
      final txnCategory = txn.category.trim();
      final txnNote = txn.note.trim();
      final budgetCategory = category.trim();

      // So sánh trực tiếp hoặc thông qua translation
      final isMatch =
          txnCategory == budgetCategory ||
          txnNote == budgetCategory ||
          _normalizeCategory(txnCategory) ==
              _normalizeCategory(budgetCategory) ||
          _normalizeCategory(txnNote) == _normalizeCategory(budgetCategory);

      if (isMatch) {
        total += txn.amount;
        matchCount++;
        print('  ✓ Match: ${txn.note} = ${txn.amount}đ');
      }
    }

    print('  → Tổng: ${matchCount} giao dịch, $total đ');
    return total;
  }

  /// Normalize category name để so sánh (chuyển về dạng chuẩn)
  static String _normalizeCategory(String category) {
    // Map các tên tiếng Việt và English về cùng một key
    const Map<String, String> categoryMap = {
      // Vietnamese
      'Mua sắm': 'shopping',
      'Ăn uống': 'food',
      'Điện thoại': 'phone',
      'Giải trí': 'entertainment',
      'Giáo dục': 'education',
      'Làm đẹp': 'beauty',
      'Thể thao': 'sports',
      'Xã hội': 'social',
      'Nhà ở': 'housing',
      'Tiền điện': 'electricity',
      'Tiền nước': 'water',
      'Quần áo': 'clothes',
      'Đi lại': 'travel',
      'Chi khác': 'other_expense',
      // English
      'Shopping': 'shopping',
      'Food': 'food',
      'Phone': 'phone',
      'Entertainment': 'entertainment',
      'Education': 'education',
      'Beauty': 'beauty',
      'Sports': 'sports',
      'Social': 'social',
      'Housing': 'housing',
      'Electricity Bill': 'electricity',
      'Water Bill': 'water',
      'Clothes': 'clothes',
      'Travel': 'travel',
      'Other Expenses': 'other_expense',
    };

    return categoryMap[category] ?? category.toLowerCase();
  }

  /// Tính tổng chi tiêu trong khoảng thời gian (tất cả categories)
  static Future<double> getTotalSpentInPeriod(
    Box<TransactionModel> transactionBox,
    DateTime startDate,
    DateTime endDate,
  ) async {
    double total = 0;
    for (var txn in transactionBox.values) {
      if (!txn.isIncome &&
          txn.date.isAfter(startDate.subtract(const Duration(seconds: 1))) &&
          txn.date.isBefore(endDate.add(const Duration(seconds: 1)))) {
        total += txn.amount;
      }
    }

    return total;
  }

  /// Sync budget lên Firebase
  static Future<void> _syncToFirebase(BudgetModel budget) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null || user.isAnonymous) {
      print("🟡 Guest mode: không sync budget lên Firebase");
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('budgets')
          .doc(user.uid)
          .collection('items')
          .doc(budget.id)
          .set(budget.toMap());

      budget.isSynced = true;
      await budget.save();

      print("✅ Đã sync budget lên Firebase");
    } catch (e) {
      print("❌ Lỗi khi sync budget lên Firebase: $e");
    }
  }

  /// Sync tất cả budgets chưa được sync
  static Future<void> syncAllBudgets() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null || user.isAnonymous) {
      print("🟡 Guest mode: không sync budgets");
      return;
    }

    try {
      final box = await getBudgetBox();
      final unsyncedBudgets = box.values
          .where((budget) => !budget.isSynced)
          .toList();

      for (var budget in unsyncedBudgets) {
        await _syncToFirebase(budget);
      }

      print("✅ Đã sync ${unsyncedBudgets.length} budgets lên Firebase");
    } catch (e) {
      print("❌ Lỗi khi sync budgets: $e");
    }
  }

  /// Load budgets từ Firebase về Hive
  static Future<void> loadBudgetsFromFirebase() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null || user.isAnonymous) {
      print("⚠️ Chưa đăng nhập, không thể tải budgets từ Firebase");
      return;
    }

    try {
      final box = await getBudgetBox();
      final snapshot = await FirebaseFirestore.instance
          .collection('budgets')
          .doc(user.uid)
          .collection('items')
          .get();

      for (var doc in snapshot.docs) {
        try {
          final data = doc.data();

          // Kiểm tra xem có phải dữ liệu cũ không (có field 'month' hoặc thiếu startDate)
          if (!data.containsKey('startDate') || data['startDate'] == null) {
            print(
              "⚠️ Bỏ qua budget cũ (id: ${doc.id}) - cấu trúc không hợp lệ",
            );
            // Có thể xóa document cũ này
            await doc.reference.delete();
            continue;
          }

          final budget = BudgetModel.fromMap(data);
          budget.isSynced = true;

          // Kiểm tra xem budget đã tồn tại chưa
          BudgetModel? existing;
          try {
            existing = box.values.firstWhere((b) => b.id == budget.id);
          } catch (e) {
            existing = null;
          }

          if (existing != null) {
            // Cập nhật budget hiện có
            existing.category = budget.category;
            existing.amount = budget.amount;
            existing.month = budget.month;
            existing.year = budget.year;
            existing.isSynced = true;
            existing.updatedAt = budget.updatedAt;
            await existing.save();
          } else {
            // Thêm budget mới
            await box.add(budget);
          }
        } catch (e) {
          print("❌ Lỗi khi parse budget (id: ${doc.id}): $e");
          print("Data: ${doc.data()}");
          // Xóa document lỗi
          await doc.reference.delete();
          continue;
        }
      }

      print("✅ Đã load budgets từ Firebase");
    } catch (e) {
      print("❌ Lỗi khi load budgets từ Firebase: $e");
    }
  }

  /// Xóa tất cả budgets (cả local và Firebase)
  static Future<void> clearAllBudgets() async {
    final user = FirebaseAuth.instance.currentUser;

    try {
      // Xóa local
      final box = await getBudgetBox();
      await box.clear();
      print("✅ Đã xóa budgets local");

      // Xóa Firebase
      if (user != null && !user.isAnonymous) {
        final snapshot = await FirebaseFirestore.instance
            .collection('budgets')
            .doc(user.uid)
            .collection('items')
            .get();

        for (var doc in snapshot.docs) {
          await doc.reference.delete();
        }
        print("✅ Đã xóa budgets trên Firebase");
      }
    } catch (e) {
      print("❌ Lỗi khi xóa budgets: $e");
    }
  }

  /// Kiểm tra và trả về warning level (0-3)
  /// 0: OK (< 80%)
  /// 1: Warning (80-90%)
  /// 2: Alert (90-100%)
  /// 3: Critical (> 100%)
  static int getWarningLevel(double spent, double budget) {
    if (budget <= 0) return 0;

    final percentage = (spent / budget) * 100;

    if (percentage > 100) return 4;
    if (percentage == 100) return 3;
    if (percentage >= 90) return 2;
    if (percentage >= 80) return 1;
    return 0;
  }

  /// Lấy thông báo phù hợp với warning level
  static String getWarningMessage(int level, String category) {
    switch (level) {
      case 4:
        return '🚨 $category: Đã vượt ngân sách';
      case 3:
        return '🚨 $category: Đã hết ngân sách!';
      case 2:
        return '⚠️ $category: Sắp hết ngân sách';
      case 1:
        return '💡 $category: Đã chi 80% ngân sách';
      default:
        return '✅ $category: Trong tầm kiểm soát';
    }
  }
}
