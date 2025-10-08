import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../db/transaction.dart';
import '../Services/hive_helper.dart';

class SyncService {
  static var _subscription;
  static StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
  _firestoreListener;

  static bool _isPulling = false;
  static bool _isStarted = false;
  static bool _isSyncing = false;
  static Timer? _debounceTimer;

  static TransactionModel? _parseTransaction(Map<String, dynamic> data) {
    try {
      final id = data['id']?.toString() ?? '';
      final category = data['category']?.toString() ?? '';
      final note = data['note']?.toString() ?? '';

      double amount = 0.0;
      final amountData = data['amount'];
      if (amountData is num) {
        amount = amountData.toDouble();
      } else if (amountData is String) {
        amount = double.tryParse(amountData) ?? 0.0;
      }

      DateTime date = DateTime.now();
      final dateData = data['date'];
      if (dateData is Timestamp) {
        date = dateData.toDate();
      } else if (dateData is num) {
        date = DateTime.fromMillisecondsSinceEpoch(dateData.toInt());
      } else if (dateData is String) {
        date = DateTime.tryParse(dateData) ?? DateTime.now();
      }

      final isIncomeRaw = data['isIncome'];
      bool isIncome = false;
      if (isIncomeRaw is bool) {
        isIncome = isIncomeRaw;
      } else if (isIncomeRaw is num) {
        isIncome = isIncomeRaw != 0;
      } else if (isIncomeRaw is String) {
        isIncome = isIncomeRaw.toLowerCase() == 'true' || isIncomeRaw == '1';
      }

      return TransactionModel(
        id: id,
        category: category,
        amount: amount,
        note: note,
        date: date,
        isIncome: isIncome,
        isSynced: true,
      );
    } catch (e) {
      return null;
    }
  }

  //kiem tra ket noi Internet va sync data
  static void start() {
    if (_isStarted) {
      return;
    }
    _isStarted = true;

    _subscription = Connectivity().onConnectivityChanged.listen((result) {
      if (result != ConnectivityResult.none) {
        _debounceTimer?.cancel();
        _debounceTimer = Timer(const Duration(seconds: 2), () {
          _syncUnsyncedTransactions();
        });
      }
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      pullFromFirebase().catchError((e) {});
      _listenRealtime(user.uid);
    }
  }

  static void stop() {
    _subscription?.cancel();
    _firestoreListener?.cancel();
    _debounceTimer?.cancel();
    _isStarted = false;
  }

  //dong bo du lieu off-online
  static Future<void> _syncUnsyncedTransactions() async {
    if (_isSyncing) {
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _isSyncing = true;

    try {
      final box = await HiveHelper.getTransactionBox();
      final unsynced = box.values.where((t) => !t.isSynced).toList();

      if (unsynced.isEmpty) {
        return;
      }

      const batchSize = 500;
      for (var i = 0; i < unsynced.length; i += batchSize) {
        final end = (i + batchSize < unsynced.length)
            ? i + batchSize
            : unsynced.length;
        final chunk = unsynced.sublist(i, end);

        final batch = FirebaseFirestore.instance.batch();

        for (var txn in chunk) {
          final docRef = FirebaseFirestore.instance
              .collection('transactions')
              .doc(user.uid)
              .collection('items')
              .doc(txn.id);

          batch.set(docRef, {
            'id': txn.id.toString(),
            'category': txn.category.toString(),
            'amount': txn.amount.toDouble(),
            'note': txn.note.toString(),
            'date': Timestamp.fromDate(txn.date),
            'isIncome': txn.isIncome == true,
          }, SetOptions(merge: true));
        }

        await batch.commit();
      }
    } catch (e) {
    } finally {
      _isSyncing = false;
    }
  }

  static Future<void> pullFromFirebase() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (_isPulling) {
      return;
    }

    _isPulling = true;

    try {
      final box = await HiveHelper.getTransactionBox();

      final snapshot = await FirebaseFirestore.instance
          .collection('transactions')
          .doc(user.uid)
          .collection('items')
          .get()
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw TimeoutException('Pull timeout'),
          );

      final Map<String, TransactionModel> toPut = {};
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final txn = _parseTransaction(data);
        if (txn != null) {
          toPut[txn.id] = txn;
        }
      }
      if (toPut.isNotEmpty) await box.putAll(toPut);
    } catch (e) {
    } finally {
      _isPulling = false;
    }
  }

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

              final txn = _parseTransaction(data);
              if (txn == null) {
                continue;
              }

              final existing = box.get(txn.id);

              if (change.type == DocumentChangeType.added ||
                  change.type == DocumentChangeType.modified) {
                if (existing == null || !existing.isSynced) {
                  box.put(txn.id, txn);
                }
              } else if (change.type == DocumentChangeType.removed) {
                box.delete(txn.id);
              }
            }
          }, onError: (error) {});
    } catch (e) {}
  }

  static Future<void> forceSyncNow() async {
    await _syncUnsyncedTransactions();
  }
}
