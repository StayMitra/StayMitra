import 'transaction_model.dart';
import 'database_helper.dart';

class TransactionService {
  // ------------------------------------------------------------
  // IN-MEMORY TRANSACTION LIST
  // ------------------------------------------------------------
  //
  // Dashboard ప్రస్తుతం synchronous methods ఉపయోగిస్తోంది.
  // అందుకే existing list ని maintain చేస్తున్నాం.
  //
  // SQLite database permanent storage కోసం ఉపయోగిస్తాం.
  //

  static final List<TransactionModel> _transactions = [];

  // ------------------------------------------------------------
  // INITIALIZE TRANSACTION SERVICE
  // ------------------------------------------------------------
  //
  // App start అయినప్పుడు SQLite నుండి saved transactions
  // memory లోకి load చేయడానికి ఇది ఉపయోగపడుతుంది.
  //

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
    // Immediately update memory.
    _transactions.add(transaction);

    // Permanently save into SQLite.
    DatabaseHelper.instance.insertTransaction(
      transaction,
    );
  }

  // ------------------------------------------------------------
  // GET ALL TRANSACTIONS
  // ------------------------------------------------------------

  static List<TransactionModel> getTransactions() {
    return List.unmodifiable(_transactions);
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
  // TOTAL INCOME
  // ------------------------------------------------------------

  static double getTotalIncome() {
    return _transactions
        .where(
          (transaction) =>
              transaction.type == TransactionType.income,
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
              transaction.type == TransactionType.expense,
        )
        .fold(
          0.0,
          (total, transaction) =>
              total + transaction.amount,
        );
  }

  // ------------------------------------------------------------
  // TODAY INCOME
  // ------------------------------------------------------------

  static double getTodayIncome() {
    final today = DateTime.now();

    return getTransactionsForDate(today)
        .where(
          (transaction) =>
              transaction.type == TransactionType.income,
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
              transaction.type == TransactionType.expense,
        )
        .fold(
          0.0,
          (total, transaction) =>
              total + transaction.amount,
        );
  }

  // ------------------------------------------------------------
  // MONTHLY INCOME
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

    return getTransactionsForRange(start, end)
        .where(
          (transaction) =>
              transaction.type == TransactionType.income,
        )
        .fold(
          0.0,
          (total, transaction) =>
              total + transaction.amount,
        );
  }

  // ------------------------------------------------------------
  // MONTHLY EXPENSE
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

    return getTransactionsForRange(start, end)
        .where(
          (transaction) =>
              transaction.type == TransactionType.expense,
        )
        .fold(
          0.0,
          (total, transaction) =>
              total + transaction.amount,
        );
  }

  // ------------------------------------------------------------
  // BALANCE BY PAYMENT METHOD
  // ------------------------------------------------------------

  static double getBalanceForMethod(
    PaymentMethod method,
  ) {
    double balance = 0;

    for (final transaction in _transactions) {
      if (transaction.paymentMethod != method) {
        continue;
      }

      if (transaction.type == TransactionType.income) {
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
  // UPI BALANCE
  // ------------------------------------------------------------

  static double getUpiBalance() {
    return getBalanceForMethod(
      PaymentMethod.upi,
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
  // TRANSACTION COUNT
  // ------------------------------------------------------------

  static int getTodayIncomeCount() {
    final today = DateTime.now();

    return getTransactionsForDate(today)
        .where(
          (transaction) =>
              transaction.type == TransactionType.income,
        )
        .length;
  }

  // ------------------------------------------------------------
  // DELETE TRANSACTION
  // ------------------------------------------------------------

  static void deleteTransaction(String id) {
    // Remove from memory.
    _transactions.removeWhere(
      (transaction) => transaction.id == id,
    );

    // Remove permanently from SQLite.
    DatabaseHelper.instance.deleteTransaction(id);
  }

  // ------------------------------------------------------------
  // CLEAR ALL
  // ------------------------------------------------------------

  static void clearTransactions() {
    // Clear memory.
    _transactions.clear();

    // Clear SQLite database.
    DatabaseHelper.instance.clearTransactions();
  }
}