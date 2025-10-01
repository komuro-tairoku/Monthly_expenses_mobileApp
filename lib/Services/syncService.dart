import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../db/transaction.dart';

class SyncService {
  static StreamSubscription<List<ConnectivityResult>>? _subscription;

  static void start() {
    _subscription = Connectivity().onConnectivityChanged.listen((results) {
      if (results.isNotEmpty && results.first != ConnectivityResult.none) {
        _syncUnsyncedTransactions();
      }
    });
  }

  static void stop() {
    _subscription?.cancel();
  }

  static Future<void> _syncUnsyncedTransactions() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final box = Hive.box<TransactionModel>('transactions');
    final unsynced = box.values.where((t) => !t.isSynced).toList();

    for (var txn in unsynced) {
      try {
        await FirebaseFirestore.instance
            .collection('transactions')
            .doc(user.uid)
            .collection('items')
            .doc(txn.id) // dùng id làm docId cho chắc
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
      } catch (e) {
        print("❌ Sync thất bại cho txn ${txn.id}: $e");
      }
    }
  }
}
