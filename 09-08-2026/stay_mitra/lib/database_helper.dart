import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'transaction_model.dart';

class DatabaseHelper {
  DatabaseHelper._privateConstructor();

  static final DatabaseHelper instance =
      DatabaseHelper._privateConstructor();

  static Database? _database;

  // ------------------------------------------------------------
  // DATABASE INSTANCE
  // ------------------------------------------------------------

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initDatabase();
    return _database!;
  }

  // ------------------------------------------------------------
  // INITIALIZE DATABASE
  // ------------------------------------------------------------

  Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();

    final path = join(
      databasePath,
      'stay_mitra.db',
    );

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  // ------------------------------------------------------------
  // CREATE TABLES
  // ------------------------------------------------------------

  Future<void> _onCreate(
    Database db,
    int version,
  ) async {
    await db.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        payment_method TEXT NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        description TEXT NOT NULL
      )
    ''');
  }

  // ------------------------------------------------------------
  // INSERT TRANSACTION
  // ------------------------------------------------------------

  Future<void> insertTransaction(
    TransactionModel transaction,
  ) async {
    final db = await database;

    await db.insert(
      'transactions',
      {
        'id': transaction.id,
        'type': transaction.type.name,
        'payment_method':
            transaction.paymentMethod.name,
        'amount': transaction.amount,
        'date': transaction.date.toIso8601String(),
        'description': transaction.description,
      },
      conflictAlgorithm:
          ConflictAlgorithm.replace,
    );
  }

  // ------------------------------------------------------------
  // GET ALL TRANSACTIONS
  // ------------------------------------------------------------

  Future<List<TransactionModel>>
      getTransactions() async {
    final db = await database;

    final result = await db.query(
      'transactions',
      orderBy: 'date DESC',
    );

    return result.map((row) {
      return TransactionModel(
        id: row['id'] as String,
        type: _transactionTypeFromString(
          row['type'] as String,
        ),
        paymentMethod:
            _paymentMethodFromString(
          row['payment_method'] as String,
        ),
        amount:
            (row['amount'] as num).toDouble(),
        date: DateTime.parse(
          row['date'] as String,
        ),
        description:
            row['description'] as String,
      );
    }).toList();
  }

  // ------------------------------------------------------------
  // GET TRANSACTION BY ID
  // ------------------------------------------------------------

  Future<TransactionModel?> getTransactionById(
    String id,
  ) async {
    final db = await database;

    final result = await db.query(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    final row = result.first;

    return TransactionModel(
      id: row['id'] as String,
      type: _transactionTypeFromString(
        row['type'] as String,
      ),
      paymentMethod:
          _paymentMethodFromString(
        row['payment_method'] as String,
      ),
      amount:
          (row['amount'] as num).toDouble(),
      date: DateTime.parse(
        row['date'] as String,
      ),
      description:
          row['description'] as String,
    );
  }

  // ------------------------------------------------------------
  // DELETE TRANSACTION
  // ------------------------------------------------------------

  Future<void> deleteTransaction(
    String id,
  ) async {
    final db = await database;

    await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ------------------------------------------------------------
  // CLEAR ALL TRANSACTIONS
  // ------------------------------------------------------------

  Future<void> clearTransactions() async {
    final db = await database;

    await db.delete(
      'transactions',
    );
  }

  // ------------------------------------------------------------
  // TRANSACTION TYPE CONVERSION
  // ------------------------------------------------------------

  TransactionType _transactionTypeFromString(
    String value,
  ) {
    switch (value) {
      case 'income':
        return TransactionType.income;

      case 'expense':
        return TransactionType.expense;

      default:
        return TransactionType.income;
    }
  }

  // ------------------------------------------------------------
  // PAYMENT METHOD CONVERSION
  // ------------------------------------------------------------

  PaymentMethod _paymentMethodFromString(
    String value,
  ) {
    switch (value) {
      case 'cash':
        return PaymentMethod.cash;

      case 'upi':
        return PaymentMethod.upi;

      case 'bank':
        return PaymentMethod.bank;

      default:
        return PaymentMethod.cash;
    }
  }
}