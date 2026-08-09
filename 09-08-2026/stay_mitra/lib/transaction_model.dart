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
  final String id;
  final TransactionType type;
  final PaymentMethod paymentMethod;
  final double amount;
  final DateTime date;
  final String description;

  // Expense category
  final ExpenseCategory? expenseCategory;

  // Used when "Other" is selected
  final String? customExpenseCategory;

  TransactionModel({
    required this.id,
    required this.type,
    required this.paymentMethod,
    required this.amount,
    required this.date,
    required this.description,
    this.expenseCategory,
    this.customExpenseCategory,
  });
}