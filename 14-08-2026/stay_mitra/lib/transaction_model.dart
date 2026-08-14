enum TransactionType {
  income,
  expense,
}

enum PaymentMethod {
  cash,
  upi,
  bank,
}

enum ExpenseCategory {
  rent,
  propertyMaintenance,
  buildingRepair,
  plumbing,
  electricalRepair,
  painting,
  furniture,
  mattressBed,
  appliances,
  pestControl,

  electricity,
  water,
  gas,
  internet,
  dthCable,
  garbage,

  groceries,
  vegetables,
  milk,
  kitchenSupplies,
  drinkingWater,

  cleaningSupplies,
  laundry,
  housekeepingSalary,

  staffSalary,
  caretakerSalary,
  wardenSalary,
  securitySalary,
  bonus,

  phoneRecharge,
  printingStationery,
  transportation,
  deliveryCourier,
  bankCharges,

  advertising,
  onlineListing,
  referralCommission,

  propertyTax,
  licenseFee,
  registrationFee,
  legalProfessionalFee,
  insurance,

  loanEmi,
  loanInterest,
  paymentGatewayCharges,

  other,
}

class TransactionModel {
  // ============================================================
  // BASIC TRANSACTION DETAILS
  // ============================================================

  final String id;

  final TransactionType type;

  final PaymentMethod paymentMethod;

  final double amount;

  final DateTime date;

  final String description;

  // ============================================================
  // TENANT PAYMENT DETAILS
  // ============================================================
  //
  // For income/payment transactions, tenantId identifies
  // which tenant made the payment.
  //
  // Example:
  // tenantId = "tenant-123"
  //
  // This is important for calculating the tenant's pending balance.
  // ============================================================

  final String? tenantId;

  // ============================================================
  // ROOM / BED DETAILS
  // ============================================================
  //
  // These fields help us know where the payment came from.
  //
  // Example:
  // Room G11
  // Bed 1
  //
  // They are optional because an expense transaction may not
  // belong to a particular tenant/room.
  // ============================================================

  final String? roomId;

  final String? bedId;

  // ============================================================
  // EXPENSE CATEGORY
  // ============================================================

  final ExpenseCategory? expenseCategory;

  // ============================================================
  // CUSTOM EXPENSE CATEGORY
  // ============================================================
  //
  // Used when ExpenseCategory.other is selected.
  //
  // Example:
  // "Water Tank Cleaning"
  // ============================================================

  final String? customExpenseCategory;

  // ============================================================
  // CONSTRUCTOR
  // ============================================================

  const TransactionModel({
    required this.id,
    required this.type,
    required this.paymentMethod,
    required this.amount,
    required this.date,
    required this.description,

    this.tenantId,

    this.roomId,

    this.bedId,

    this.expenseCategory,

    this.customExpenseCategory,
  });

  // ============================================================
  // HELPER: IS INCOME
  // ============================================================

  bool get isIncome => type == TransactionType.income;

  // ============================================================
  // HELPER: IS EXPENSE
  // ============================================================

  bool get isExpense => type == TransactionType.expense;

  // ============================================================
  // HELPER: IS TENANT PAYMENT
  // ============================================================
  //
  // A transaction is considered a tenant payment when:
  // 1. It is income
  // 2. tenantId is available
  // ============================================================

  bool get isTenantPayment =>
      type == TransactionType.income &&
      tenantId != null &&
      tenantId!.isNotEmpty;

  // ============================================================
  // HELPER: IS OTHER EXPENSE
  // ============================================================

  bool get isOtherExpense =>
      type == TransactionType.expense &&
      expenseCategory == ExpenseCategory.other;

  // ============================================================
  // COPY WITH
  // ============================================================
  //
  // Useful when we need to update a transaction without creating
  // everything again.
  // ============================================================

  TransactionModel copyWith({
    String? id,
    TransactionType? type,
    PaymentMethod? paymentMethod,
    double? amount,
    DateTime? date,
    String? description,
    String? tenantId,
    String? roomId,
    String? bedId,
    ExpenseCategory? expenseCategory,
    String? customExpenseCategory,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      type: type ?? this.type,
      paymentMethod:
          paymentMethod ?? this.paymentMethod,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      description:
          description ?? this.description,
      tenantId:
          tenantId ?? this.tenantId,
      roomId:
          roomId ?? this.roomId,
      bedId:
          bedId ?? this.bedId,
      expenseCategory:
          expenseCategory ?? this.expenseCategory,
      customExpenseCategory:
          customExpenseCategory ??
              this.customExpenseCategory,
    );
  }
}