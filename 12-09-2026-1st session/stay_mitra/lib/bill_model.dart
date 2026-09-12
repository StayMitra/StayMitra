class BillModel {
  final String id;
  final String tenantId;
  final String tenantName;
  final String buildingId;
  final String billType;
  final double amount;
  final String dueDate;
  final String? note;
  final String status;
  final String createdAt;

  BillModel({
    required this.id,
    required this.tenantId,
    required this.tenantName,
    required this.buildingId,
    required this.billType,
    required this.amount,
    required this.dueDate,
    this.note,
    required this.status,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tenant_id': tenantId,
      'tenant_name': tenantName,
      'building_id': buildingId,
      'bill_type': billType,
      'amount': amount,
      'due_date': dueDate,
      'note': note,
      'status': status,
      'created_at': createdAt,
    };
  }

  factory BillModel.fromMap(Map<String, dynamic> map) {
    return BillModel(
      id: map['id'].toString(),
      tenantId: map['tenant_id'].toString(),
      tenantName: map['tenant_name'].toString(),
      buildingId: map['building_id'].toString(),
      billType: map['bill_type']?.toString() ?? 'Monthly Rent',
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      dueDate: map['due_date'].toString(),
      note: map['note']?.toString(),
      status: map['status']?.toString() ?? 'pending',
      createdAt: map['created_at'].toString(),
    );
  }
}