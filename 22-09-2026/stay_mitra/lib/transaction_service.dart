import 'transaction_model.dart';
import 'database_helper.dart';

class TransactionService {
  // ------------------------------------------------------------
  // IN-MEMORY TRANSACTION LIST
  // ------------------------------------------------------------

  static final List<TransactionModel> _transactions = [];

  // ------------------------------------------------------------
  // INITIALIZE TRANSACTION SERVICE
  // ------------------------------------------------------------

  static Future<void> initialize() async {
    final savedTransactions =
        await DatabaseHelper.instance.getTransactions();

    _transactions.clear();
    _transactions.addAll(savedTransactions);
  }

  // ------------------------------------------------------------
  // ADD TRANSACTION
  // ------------------------------------------------------------

  static void addTransaction(
    TransactionModel transaction,
  ) {
    // Remove existing transaction with same ID
    _transactions.removeWhere(
      (item) => item.id == transaction.id,
    );

    // Add immediately to memory
    _transactions.insert(
      0,
      transaction,
    );

    // Save permanently to SQLite
    DatabaseHelper.instance.insertTransaction(
      transaction,
    );
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
    // Remove from memory
    _transactions.removeWhere(
      (transaction) => transaction.id == id,
    );

    // Remove from SQLite
    DatabaseHelper.instance.deleteTransaction(
      id,
    );
  }

  // ------------------------------------------------------------
  // CLEAR ALL TRANSACTIONS
  // ------------------------------------------------------------

  static Future<void> clearAllTransactions() async {
    _transactions.clear();

    await DatabaseHelper.instance.clearTransactions();
  }

  // ------------------------------------------------------------
  // BACKWARD COMPATIBILITY
  // ------------------------------------------------------------

  static void clearTransactions() {
    _transactions.clear();

    DatabaseHelper.instance.clearTransactions();
  }
}