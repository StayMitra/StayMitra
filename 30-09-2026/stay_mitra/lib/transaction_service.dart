import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'transaction_model.dart';
import 'pg_manager_service.dart';

class TransactionService {
  // ------------------------------------------------------------
  // FIREBASE
  // ------------------------------------------------------------

  static final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  static final FirebaseAuth _auth =
      FirebaseAuth.instance;

  // ------------------------------------------------------------
  // IN-MEMORY TRANSACTION LIST
  // ------------------------------------------------------------
  //
  // This is only an in-memory working list.
  // Firebase is the permanent source of truth.
  // ------------------------------------------------------------

  static final List<TransactionModel> _transactions = [];

  // ------------------------------------------------------------
  // OWNER ID
  // ------------------------------------------------------------

  static String? get _ownerId {
    return _auth.currentUser?.uid;
  }

  // ------------------------------------------------------------
  // PROPERTY REFERENCE
  // ------------------------------------------------------------

  static DocumentReference<Map<String, dynamic>> _propertyRef(
    String buildingId,
  ) {
    final ownerId = _ownerId;

    if (ownerId == null || ownerId.isEmpty) {
      throw Exception('User is not logged in.');
    }

    return _firestore
        .collection('owners')
        .doc(ownerId)
        .collection('properties')
        .doc(buildingId);
  }

  // ------------------------------------------------------------
  // TRANSACTIONS COLLECTION
  // ------------------------------------------------------------

  static CollectionReference<Map<String, dynamic>>
      _transactionsCollection(
    String buildingId,
  ) {
    return _propertyRef(buildingId)
        .collection('transactions');
  }

  // ------------------------------------------------------------
  // INITIALIZE TRANSACTION SERVICE
  // ------------------------------------------------------------
  //
  // Loads transactions from Firebase.
  //
  // SQLite is NOT used.
  // ------------------------------------------------------------

  static Future<void> initialize() async {
    _transactions.clear();

    final ownerId = _ownerId;

    if (ownerId == null || ownerId.isEmpty) {
      return;
    }

    try {
      final propertiesSnapshot = await _firestore
          .collection('owners')
          .doc(ownerId)
          .collection('properties')
          .get();

      for (final propertyDoc in propertiesSnapshot.docs) {
        final buildingId = propertyDoc.id;

        final transactionsSnapshot =
            await _transactionsCollection(
          buildingId,
        ).get();

        for (final transactionDoc
            in transactionsSnapshot.docs) {
          final data =
              transactionDoc.data();

          // If building_id is missing in an old document,
          // use the property ID from the parent path.
          data['building_id'] ??= buildingId;
          data['id'] ??= transactionDoc.id;

          final transaction =
              _transactionFromFirestore(
            data,
            buildingId,
          );

          if (transaction != null) {
            _transactions.add(transaction);
          }
        }
      }

      // Latest transactions first
      _transactions.sort(
        (a, b) => b.date.compareTo(a.date),
      );
    } catch (e) {
      // Keep application running even if Firebase read fails.
      // Firebase remains the source of truth.
      print(
        'TRANSACTION SERVICE INITIALIZE ERROR: $e',
      );
    }
  }

  // ------------------------------------------------------------
  // ADD TRANSACTION
  // ------------------------------------------------------------
  //
  // Saves transaction to Firebase.
  //
  // Existing API remains void so existing screens do not need
  // to be changed immediately.
  // ------------------------------------------------------------

  static void addTransaction(
    TransactionModel transaction,
  ) {
    // Remove existing transaction with same ID
    _transactions.removeWhere(
      (item) => item.id == transaction.id,
    );

    // ----------------------------------------------------------
    // FIND ACTIVE PG
    // ----------------------------------------------------------

    final activePg = PgManagerService.activePg;

    String? buildingId =
        transaction.buildingId;

    // If transaction does not already contain a building ID,
    // use the currently active PG.
    buildingId ??= activePg?.id;

    // ----------------------------------------------------------
    // UPDATE IN-MEMORY TRANSACTION
    // ----------------------------------------------------------

    final transactionToSave =
        transaction.copyWith(
      buildingId: buildingId,
    );

    _transactions.insert(
      0,
      transactionToSave,
    );

    // ----------------------------------------------------------
    // SAVE TO FIREBASE
    // ----------------------------------------------------------

    unawaited(
      _saveTransactionToFirebase(
        transactionToSave,
        buildingId,
      ),
    );
  }

  // ------------------------------------------------------------
  // SAVE TRANSACTION TO FIREBASE
  // ------------------------------------------------------------

  static Future<void> _saveTransactionToFirebase(
    TransactionModel transaction,
    String? buildingId,
  ) async {
    if (buildingId == null ||
        buildingId.isEmpty) {
      print(
        'TRANSACTION SAVE ERROR: No building/PG ID available.',
      );
      return;
    }

    try {
      await _transactionsCollection(
        buildingId,
      )
          .doc(transaction.id)
          .set(
        _transactionToFirestore(
          transaction,
          buildingId,
        ),
        SetOptions(
          merge: true,
        ),
      );
    } catch (e) {
      print(
        'TRANSACTION FIREBASE SAVE ERROR: $e',
      );
    }
  }

  // ------------------------------------------------------------
  // GET ALL TRANSACTIONS
  // ------------------------------------------------------------

  static List<TransactionModel> getTransactions() {
    return List<TransactionModel>.unmodifiable(
      _transactions,
    );
  }

  // ------------------------------------------------------------
  // GET TRANSACTIONS FOR SPECIFIC BUILDING / PG
  // ------------------------------------------------------------

  static List<TransactionModel>
      getTransactionsForBuilding(
    String buildingId,
  ) {
    return _transactions
        .where(
          (transaction) =>
              transaction.buildingId == buildingId,
        )
        .toList();
  }

  // ------------------------------------------------------------
  // GET TRANSACTIONS FOR SPECIFIC DATE
  // ------------------------------------------------------------

  static List<TransactionModel> getTransactionsForDate(
    DateTime date, {
    String? buildingId,
  }) {
    return _transactions.where((transaction) {
      final sameDate =
          transaction.date.year == date.year &&
              transaction.date.month == date.month &&
              transaction.date.day == date.day;

      if (buildingId == null) {
        return sameDate;
      }

      return sameDate &&
          transaction.buildingId == buildingId;
    }).toList();
  }

  // ------------------------------------------------------------
  // GET TRANSACTIONS BETWEEN DATES
  // ------------------------------------------------------------

  static List<TransactionModel> getTransactionsForRange(
    DateTime start,
    DateTime end, {
    String? buildingId,
  }) {
    final startDate = DateTime(
      start.year,
      start.month,
      start.day,
    );

    final endDate = DateTime(
      end.year,
      end.month,
      end.day,
      23,
      59,
      59,
      999,
    );

    return _transactions.where((transaction) {
      final withinDateRange =
          !transaction.date.isBefore(startDate) &&
              !transaction.date.isAfter(endDate);

      if (buildingId == null) {
        return withinDateRange;
      }

      return withinDateRange &&
          transaction.buildingId == buildingId;
    }).toList();
  }

  // ------------------------------------------------------------
  // TODAY INCOME
  // ------------------------------------------------------------

  static double getTodayIncome({
    String? buildingId,
  }) {
    final today = DateTime.now();

    return getTransactionsForDate(
      today,
      buildingId: buildingId,
    )
        .where(
          (transaction) =>
              transaction.type ==
              TransactionType.income,
        )
        .fold(
          0.0,
          (total, transaction) =>
              total + transaction.amount,
        );
  }

  // ------------------------------------------------------------
  // TODAY EXPENSE
  // ------------------------------------------------------------

  static double getTodayExpense({
    String? buildingId,
  }) {
    final today = DateTime.now();

    return getTransactionsForDate(
      today,
      buildingId: buildingId,
    )
        .where(
          (transaction) =>
              transaction.type ==
              TransactionType.expense,
        )
        .fold(
          0.0,
          (total, transaction) =>
              total + transaction.amount,
        );
  }

  // ------------------------------------------------------------
  // TODAY INCOME COUNT
  // ------------------------------------------------------------

  static int getTodayIncomeCount({
    String? buildingId,
  }) {
    final today = DateTime.now();

    return getTransactionsForDate(
      today,
      buildingId: buildingId,
    )
        .where(
          (transaction) =>
              transaction.type ==
              TransactionType.income,
        )
        .length;
  }

  // ------------------------------------------------------------
  // CURRENT MONTH INCOME
  // ------------------------------------------------------------

  static double getCurrentMonthIncome({
    String? buildingId,
  }) {
    final now = DateTime.now();

    final start = DateTime(
      now.year,
      now.month,
      1,
    );

    final end = DateTime(
      now.year,
      now.month + 1,
      0,
    );

    return getTransactionsForRange(
      start,
      end,
      buildingId: buildingId,
    )
        .where(
          (transaction) =>
              transaction.type ==
              TransactionType.income,
        )
        .fold(
          0.0,
          (total, transaction) =>
              total + transaction.amount,
        );
  }

  // ------------------------------------------------------------
  // CURRENT MONTH EXPENSE
  // ------------------------------------------------------------

  static double getCurrentMonthExpense({
    String? buildingId,
  }) {
    final now = DateTime.now();

    final start = DateTime(
      now.year,
      now.month,
      1,
    );

    final end = DateTime(
      now.year,
      now.month + 1,
      0,
    );

    return getTransactionsForRange(
      start,
      end,
      buildingId: buildingId,
    )
        .where(
          (transaction) =>
              transaction.type ==
              TransactionType.expense,
        )
        .fold(
          0.0,
          (total, transaction) =>
              total + transaction.amount,
        );
  }

  // ------------------------------------------------------------
  // TOTAL INCOME
  // ------------------------------------------------------------

  static double getTotalIncome({
    String? buildingId,
  }) {
    final transactions =
        buildingId == null
            ? _transactions
            : getTransactionsForBuilding(
                buildingId,
              );

    return transactions
        .where(
          (transaction) =>
              transaction.type ==
              TransactionType.income,
        )
        .fold(
          0.0,
          (total, transaction) =>
              total + transaction.amount,
        );
  }

  // ------------------------------------------------------------
  // TOTAL EXPENSE
  // ------------------------------------------------------------

  static double getTotalExpense({
    String? buildingId,
  }) {
    final transactions =
        buildingId == null
            ? _transactions
            : getTransactionsForBuilding(
                buildingId,
              );

    return transactions
        .where(
          (transaction) =>
              transaction.type ==
              TransactionType.expense,
        )
        .fold(
          0.0,
          (total, transaction) =>
              total + transaction.amount,
        );
  }

  // ------------------------------------------------------------
  // NET BALANCE
  // ------------------------------------------------------------

  static double getNetBalance(
    String buildingId,
  ) {
    return getTotalIncome(
          buildingId: buildingId,
        ) -
        getTotalExpense(
          buildingId: buildingId,
        );
  }

  // ------------------------------------------------------------
  // BALANCE FOR PAYMENT METHOD
  // ------------------------------------------------------------

  static double getBalanceForMethod(
    String buildingId,
    PaymentMethod method,
  ) {
    double balance = 0;

    for (final transaction in _transactions) {
      if (transaction.buildingId != buildingId) {
        continue;
      }

      if (transaction.paymentMethod != method) {
        continue;
      }

      if (transaction.type ==
          TransactionType.income) {
        balance += transaction.amount;
      } else {
        balance -= transaction.amount;
      }
    }

    return balance;
  }

  // ------------------------------------------------------------
  // CASH BALANCE
  // ------------------------------------------------------------

  static double getCashBalance(
    String buildingId,
  ) {
    return getBalanceForMethod(
      buildingId,
      PaymentMethod.cash,
    );
  }

  // ------------------------------------------------------------
  // BANK BALANCE
  // ------------------------------------------------------------

  static double getBankBalance(
    String buildingId,
  ) {
    return getBalanceForMethod(
      buildingId,
      PaymentMethod.bank,
    );
  }

  // ------------------------------------------------------------
  // UPI BALANCE
  // ------------------------------------------------------------

  static double getUpiBalance(
    String buildingId,
  ) {
    return getBalanceForMethod(
      buildingId,
      PaymentMethod.upi,
    );
  }

  // ------------------------------------------------------------
  // TRANSACTION COUNT
  // ------------------------------------------------------------

  static int getTransactionCount({
    String? buildingId,
  }) {
    if (buildingId == null) {
      return _transactions.length;
    }

    return getTransactionsForBuilding(
      buildingId,
    ).length;
  }

  // ------------------------------------------------------------
  // INCOME COUNT
  // ------------------------------------------------------------

  static int getIncomeCount({
    String? buildingId,
  }) {
    final transactions =
        buildingId == null
            ? _transactions
            : getTransactionsForBuilding(
                buildingId,
              );

    return transactions
        .where(
          (transaction) =>
              transaction.type ==
              TransactionType.income,
        )
        .length;
  }

  // ------------------------------------------------------------
  // EXPENSE COUNT
  // ------------------------------------------------------------

  static int getExpenseCount({
    String? buildingId,
  }) {
    final transactions =
        buildingId == null
            ? _transactions
            : getTransactionsForBuilding(
                buildingId,
              );

    return transactions
        .where(
          (transaction) =>
              transaction.type ==
              TransactionType.expense,
        )
        .length;
  }

  // ------------------------------------------------------------
  // DELETE TRANSACTION
  // ------------------------------------------------------------

  static void deleteTransaction(
    String id,
  ) {
    String? buildingId;

    // Find transaction in memory first
    for (final transaction in _transactions) {
      if (transaction.id == id) {
        buildingId = transaction.buildingId;
        break;
      }
    }

    // Remove from memory
    _transactions.removeWhere(
      (transaction) => transaction.id == id,
    );

    // Remove from Firebase
    unawaited(
      _deleteTransactionFromFirebase(
        id,
        buildingId,
      ),
    );
  }

  // ------------------------------------------------------------
  // DELETE TRANSACTION FROM FIREBASE
  // ------------------------------------------------------------

  static Future<void>
      _deleteTransactionFromFirebase(
    String id,
    String? buildingId,
  ) async {
    try {
      // If building ID is available, delete directly.
      if (buildingId != null &&
          buildingId.isNotEmpty) {
        await _transactionsCollection(
          buildingId,
        )
            .doc(id)
            .delete();

        return;
      }

      // --------------------------------------------------------
      // FALLBACK SEARCH
      // --------------------------------------------------------
      //
      // This is only used when an old/in-memory transaction
      // does not contain buildingId.
      // --------------------------------------------------------

      final ownerId = _ownerId;

      if (ownerId == null ||
          ownerId.isEmpty) {
        return;
      }

      final propertiesSnapshot =
          await _firestore
              .collection('owners')
              .doc(ownerId)
              .collection('properties')
              .get();

      for (final propertyDoc
          in propertiesSnapshot.docs) {
        final transactionRef =
            _transactionsCollection(
          propertyDoc.id,
        ).doc(id);

        final transactionSnapshot =
            await transactionRef.get();

        if (transactionSnapshot.exists) {
          await transactionRef.delete();
          return;
        }
      }
    } catch (e) {
      print(
        'TRANSACTION FIREBASE DELETE ERROR: $e',
      );
    }
  }

  // ------------------------------------------------------------
  // CLEAR ALL TRANSACTIONS
  // ------------------------------------------------------------

  static Future<void> clearAllTransactions() async {
    _transactions.clear();

    final ownerId = _ownerId;

    if (ownerId == null ||
        ownerId.isEmpty) {
      return;
    }

    try {
      final propertiesSnapshot =
          await _firestore
              .collection('owners')
              .doc(ownerId)
              .collection('properties')
              .get();

      for (final propertyDoc
          in propertiesSnapshot.docs) {
        final transactionsSnapshot =
            await _transactionsCollection(
          propertyDoc.id,
        ).get();

        for (final transactionDoc
            in transactionsSnapshot.docs) {
          await transactionDoc.reference.delete();
        }
      }
    } catch (e) {
      print(
        'TRANSACTION FIREBASE CLEAR ERROR: $e',
      );
    }
  }

  // ------------------------------------------------------------
  // BACKWARD COMPATIBILITY
  // ------------------------------------------------------------
  //
  // Existing screens can continue calling:
  //
  // TransactionService.clearTransactions();
  //
  // No SQLite is used.
  // ------------------------------------------------------------

  static void clearTransactions() {
    _transactions.clear();

    unawaited(
      clearAllTransactions(),
    );
  }

  // ============================================================
  // FIRESTORE -> TRANSACTION MODEL
  // ============================================================

  static TransactionModel?
      _transactionFromFirestore(
    Map<String, dynamic> data,
    String buildingId,
  ) {
    try {
      final typeValue =
          data['type']?.toString();

      final paymentMethodValue =
          data['payment_method']?.toString();

      final id =
          data['id']?.toString();

      if (id == null ||
          id.isEmpty ||
          typeValue == null ||
          paymentMethodValue == null) {
        return null;
      }

      // --------------------------------------------------------
      // TRANSACTION TYPE
      // --------------------------------------------------------

      final type =
          TransactionType.values.firstWhere(
        (value) =>
            value.name == typeValue,
        orElse: () =>
            TransactionType.income,
      );

      // --------------------------------------------------------
      // PAYMENT METHOD
      // --------------------------------------------------------

      final paymentMethod =
          PaymentMethod.values.firstWhere(
        (value) =>
            value.name == paymentMethodValue,
        orElse: () =>
            PaymentMethod.cash,
      );

      // --------------------------------------------------------
      // DATE
      // --------------------------------------------------------

      DateTime date;

      final rawDate =
          data['date'];

      if (rawDate is Timestamp) {
        date = rawDate.toDate();
      } else if (rawDate is DateTime) {
        date = rawDate;
      } else if (rawDate is String) {
        date =
            DateTime.tryParse(rawDate) ??
                DateTime.now();
      } else {
        date = DateTime.now();
      }

      // --------------------------------------------------------
      // AMOUNT
      // --------------------------------------------------------

      double amount = 0;

      final rawAmount =
          data['amount'];

      if (rawAmount is num) {
        amount = rawAmount.toDouble();
      } else {
        amount =
            double.tryParse(
                  rawAmount?.toString() ??
                      '',
                ) ??
                0;
      }

      // --------------------------------------------------------
      // EXPENSE CATEGORY
      // --------------------------------------------------------

      ExpenseCategory?
          expenseCategory;

      final rawExpenseCategory =
          data['expense_category'];

      if (rawExpenseCategory != null) {
        final categoryName =
            rawExpenseCategory.toString();

        for (final category
            in ExpenseCategory.values) {
          if (category.name ==
              categoryName) {
            expenseCategory =
                category;
            break;
          }
        }
      }

      // --------------------------------------------------------
      // BUILD TRANSACTION MODEL
      // --------------------------------------------------------

      return TransactionModel(
        id: id,

        type: type,

        paymentMethod:
            paymentMethod,

        amount: amount,

        date: date,

        description:
            data['description']
                    ?.toString() ??
                '',

        buildingId:
            data['building_id']
                    ?.toString() ??
                buildingId,

        tenantId:
            data['tenant_id']
                ?.toString(),

        roomId:
            data['room_id']
                ?.toString(),

        bedId:
            data['bed_id']
                ?.toString(),

        expenseCategory:
            expenseCategory,

        customExpenseCategory:
            data[
              'custom_expense_category'
            ]?.toString(),
      );
    } catch (e) {
      print(
        'TRANSACTION FIRESTORE PARSE ERROR: $e',
      );

      return null;
    }
  }

  // ============================================================
  // TRANSACTION MODEL -> FIRESTORE
  // ============================================================

  static Map<String, dynamic>
      _transactionToFirestore(
    TransactionModel transaction,
    String buildingId,
  ) {
    return {
      'id': transaction.id,

      'building_id':
          buildingId,

      'type':
          transaction.type.name,

      'payment_method':
          transaction.paymentMethod.name,

      'amount':
          transaction.amount,

      'date':
          Timestamp.fromDate(
        transaction.date,
      ),

      'description':
          transaction.description,

      'tenant_id':
          transaction.tenantId,

      'room_id':
          transaction.roomId,

      'bed_id':
          transaction.bedId,

      'expense_category':
          transaction.expenseCategory?.name,

      'custom_expense_category':
          transaction.customExpenseCategory,

      'created_at':
          FieldValue.serverTimestamp(),
    };
  }
}