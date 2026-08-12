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
  // GET TRANSACTIONS FOR SPECIFIC DATE
  // ------------------------------------------------------------

  static List<TransactionModel> getTransactionsForDate(
    DateTime date,
  ) {
    return _transactions.where((transaction) {
      return transaction.date.year == date.year &&
          transaction.date.month == date.month &&
          transaction.date.day == date.day;
    }).toList();
  }

  // ------------------------------------------------------------
  // GET TRANSACTIONS BETWEEN DATES
  // ------------------------------------------------------------

  static List<TransactionModel> getTransactionsForRange(
    DateTime start,
    DateTime end,
  ) {
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
      return !transaction.date.isBefore(startDate) &&
          !transaction.date.isAfter(endDate);
    }).toList();
  }

  // ------------------------------------------------------------
  // TODAY INCOME
  // ------------------------------------------------------------

  static double getTodayIncome() {
    final today = DateTime.now();

    return getTransactionsForDate(today)
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

  static double getTodayExpense() {
    final today = DateTime.now();

    return getTransactionsForDate(today)
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

  static int getTodayIncomeCount() {
    final today = DateTime.now();

    return getTransactionsForDate(today)
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

  static double getCurrentMonthIncome() {
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

  static double getCurrentMonthExpense() {
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

  static double getTotalIncome() {
    return _transactions
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

  static double getTotalExpense() {
    return _transactions
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

  static double getNetBalance() {
    return getTotalIncome() -
        getTotalExpense();
  }

  // ------------------------------------------------------------
  // BALANCE FOR PAYMENT METHOD
  // ------------------------------------------------------------

  static double getBalanceForMethod(
    PaymentMethod method,
  ) {
    double balance = 0;

    for (final transaction in _transactions) {
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

  static double getCashBalance() {
    return getBalanceForMethod(
      PaymentMethod.cash,
    );
  }

  // ------------------------------------------------------------
  // BANK BALANCE
  // ------------------------------------------------------------

  static double getBankBalance() {
    return getBalanceForMethod(
      PaymentMethod.bank,
    );
  }

  // ------------------------------------------------------------
  // UPI BALANCE
  // ------------------------------------------------------------

  static double getUpiBalance() {
    return getBalanceForMethod(
      PaymentMethod.upi,
    );
  }

  // ------------------------------------------------------------
  // TRANSACTION COUNT
  // ------------------------------------------------------------

  static int getTransactionCount() {
    return _transactions.length;
  }

  // ------------------------------------------------------------
  // INCOME COUNT
  // ------------------------------------------------------------

  static int getIncomeCount() {
    return _transactions
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

  static int getExpenseCount() {
    return _transactions
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