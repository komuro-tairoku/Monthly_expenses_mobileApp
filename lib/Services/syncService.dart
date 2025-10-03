import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../db/transaction.dart';
import '../Services/hiveHelper.dart';

class SyncService {
  static StreamSubscription<List<ConnectivityResult>>? _subscription;
  static StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
  _firestoreListener;

  static bool _isPulling = false;

  static void start() {
    _subscription = Connectivity().onConnectivityChanged.listen((results) {
      if (results.isNotEmpty && results.first != ConnectivityResult.none) {
        _syncUnsyncedTransactions();
      }
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      pullFromFirebase();
      _listenRealtime(user.uid);
    }
  }

  /// Dừng service
  static void stop() {
    _subscription?.cancel();
    _firestoreListener?.cancel();
  }

  static Future<void> _syncUnsyncedTransactions() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final box = await HiveHelper.getTransactionBox();
      final unsynced = box.values.where((t) => !t.isSynced).toList();

      for (var txn in unsynced) {
        try {
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
        } catch (e) {
          print("❌ Sync thất bại cho txn ${txn.id}: $e");
        }
      }
    } catch (e) {
      print("❌ Lỗi khi sync: $e");
    }
  }

  static Future<void> pullFromFirebase() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _isPulling = true;

    try {
      final box = await HiveHelper.getTransactionBox();

      final snapshot = await FirebaseFirestore.instance
          .collection('transactions')
          .doc(user.uid)
          .collection('items')
          .get();

      for (var doc in snapshot.docs) {
        final data = doc.data();

        final txn = TransactionModel(
          id: data['id'],
          category: data['category'],
          amount: (data['amount'] as num).toDouble(),
          note: data['note'],
          date: (data['date'] as Timestamp).toDate(),
          isIncome: data['isIncome'] ?? false,
          isSynced: true,
        );

        await box.put(txn.id, txn);
      }
    } catch (e) {
      print("❌ Pull từ Firebase thất bại: $e");
    } finally {
      _isPulling = false;
    }
  }

  /// Lắng nghe thay đổi realtime từ Firebase
  static void _listenRealtime(String uid) async {
    try {
      final box = await HiveHelper.getTransactionBox();

      _firestoreListener = FirebaseFirestore.instance
          .collection('transactions')
          .doc(uid)
          .collection('items')
          .snapshots()
          .listen((snapshot) {
            for (var change in snapshot.docChanges) {
              if (_isPulling) continue;

              final data = change.doc.data();
              if (data == null) continue;

              final txn = TransactionModel(
                id: data['id'],
                category: data['category'],
                amount: (data['amount'] as num).toDouble(),
                note: data['note'],
                date: (data['date'] as Timestamp).toDate(),
                isIncome: data['isIncome'] ?? false,
                isSynced: true,
              );

              if (change.type == DocumentChangeType.added ||
                  change.type == DocumentChangeType.modified) {
                final existing = box.get(txn.id);
                if (existing == null || !existing.isSynced) {
                  box.put(txn.id, txn);
                }
              } else if (change.type == DocumentChangeType.removed) {
                box.delete(txn.id);
              }
            }
          });
    } catch (e) {
      print("❌ Lỗi khi listen realtime: $e");
    }
  }
}
