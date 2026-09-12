class TenantModel {
  final String id;

  final String bedId;

  final String fullName;
  final String phone;

  final String? alternatePhone;
  final String? email;

  final String? idProofType;
  final String? idProofNumber;

  final DateTime joiningDate;

  final double monthlyRent;
  final double securityDeposit;

  final String status;

  final DateTime createdAt;

  const TenantModel({
    required this.id,
    required this.bedId,
    required this.fullName,
    required this.phone,
    this.alternatePhone,
    this.email,
    this.idProofType,
    this.idProofNumber,
    required this.joiningDate,
    required this.monthlyRent,
    required this.securityDeposit,
    this.status = 'active',
    required this.createdAt,
  });

  bool get isActive => status == 'active';

  bool get isVacated => status == 'vacated';
}