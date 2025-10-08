import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../db/transaction.dart';

class TransactionService {
  /// 🗑️ Xóa giao dịch
  static Future<void> deleteTransaction(TransactionModel txn) async {
    final user = FirebaseAuth.instance.currentUser;
    await txn.delete();

    if (user == null || user.isAnonymous) {
      print("🟡 Guest mode: không xoá trên Firebase");
      return;
    }

    if (txn.isSynced) {
      try {
        await FirebaseFirestore.instance
            .collection('transactions')
            .doc(user.uid)
            .collection('items')
            .doc(txn.id)
            .delete();
        print("Đã xoá giao dịch trên Firebase");
      } catch (e) {
        txn.isSynced = false;
        await txn.save();
        print("Lỗi khi xoá Firebase: $e");
      }
    }
  }

  static Future<void> updateTransaction(
    TransactionModel txn,
    String newNote,
    double newAmount,
  ) async {
    final user = FirebaseAuth.instance.currentUser;

    txn.note = newNote;
    txn.amount = newAmount;
    await txn.save();

    if (user == null || user.isAnonymous) {
      print("Guest mode: không cập nhật Firebase");
      return;
    }

    if (txn.isSynced) {
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
        print("Cập nhật Firebase thành công");
      } catch (e) {
        print("Lỗi cập nhật Firebase: $e");
      }
    }
  }

  static List<TransactionModel> getSortedTransactions(
    Box<TransactionModel> box,
  ) {
    final transactions = box.values.toList();
    transactions.sort((a, b) => b.date.compareTo(a.date));
    return transactions;
  }

  static Map<String, double> calculateTotals(
    List<TransactionModel> transactions,
  ) {
    double totalIncome = 0;
    double totalExpense = 0;

    for (var txn in transactions) {
      if (txn.isIncome) {
        totalIncome += txn.amount;
      } else {
        totalExpense += txn.amount;
      }
    }

    return {
      'income': totalIncome,
      'expense': totalExpense,
      'balance': totalIncome - totalExpense,
    };
  }
}
