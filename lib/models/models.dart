class UserProfile {
  final int id;
  final String name;
  final String email;
  final String? phoneNumber;
  final bool mustChangePassword;

  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    this.phoneNumber,
    this.mustChangePassword = false,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    id: json['id'] as int,
    name: json['name'] as String? ?? '',
    email: json['email'] as String? ?? '',
    phoneNumber: json['phone_number'] as String?,
    mustChangePassword: json['must_change_password'] as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'phone_number': phoneNumber,
    'must_change_password': mustChangePassword,
  };
}

class ScheduleRow {
  final int installmentNo;
  final DateTime? dueDate;
  final double amountDue;
  final double amountPaid;
  final String status;

  const ScheduleRow({required this.installmentNo, this.dueDate, required this.amountDue, required this.amountPaid, required this.status});

  factory ScheduleRow.fromJson(Map<String, dynamic> json) => ScheduleRow(
    installmentNo: json['installment_no'] as int,
    dueDate: DateTime.tryParse(json['due_date']?.toString() ?? ''),
    amountDue: (json['amount_due'] as num?)?.toDouble() ?? 0,
    amountPaid: (json['amount_paid'] as num?)?.toDouble() ?? 0,
    status: json['status'] as String? ?? 'pending',
  );
}

class Repayment {
  final int id;
  final String type;
  final double amount;
  final String channel;
  final String status;
  final DateTime? receivedAt;
  final DateTime? createdAt;

  const Repayment({required this.id, required this.type, required this.amount, required this.channel, required this.status, this.receivedAt, this.createdAt});

  factory Repayment.fromJson(Map<String, dynamic> json) => Repayment(
    id: json['id'] as int,
    type: json['type'] as String? ?? 'installment',
    amount: (json['amount'] as num?)?.toDouble() ?? 0,
    channel: json['channel'] as String? ?? 'mobile_money',
    status: json['status'] as String? ?? 'pending',
    receivedAt: DateTime.tryParse(json['received_at']?.toString() ?? ''),
    createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
  );
}

class Loan {
  final int id;
  final String contractNo;
  final String status;
  final double depositAmount;
  final double installmentAmount;
  final String paymentFrequency;
  final double totalPayable;
  final double balance;
  final DateTime? paidThroughAt;
  final DateTime? nextRepaymentAt;
  final String phoneName;
  final String? imei;
  final List<ScheduleRow> schedule;
  final List<Repayment> repayments;

  const Loan({
    required this.id,
    required this.contractNo,
    required this.status,
    required this.depositAmount,
    required this.installmentAmount,
    required this.paymentFrequency,
    required this.totalPayable,
    required this.balance,
    this.paidThroughAt,
    this.nextRepaymentAt,
    required this.phoneName,
    this.imei,
    this.schedule = const [],
    this.repayments = const [],
  });

  factory Loan.fromJson(Map<String, dynamic> json) {
    final phone = (json['phone_unit'] as Map<String, dynamic>?) ?? {};
    return Loan(
      id: json['id'] as int,
      contractNo: json['contract_no'] as String? ?? '',
      status: json['status'] as String? ?? '',
      depositAmount: (json['deposit_amount'] as num?)?.toDouble() ?? 0,
      installmentAmount: (json['installment_amount'] as num?)?.toDouble() ?? 0,
      paymentFrequency: json['payment_frequency'] as String? ?? '',
      totalPayable: (json['total_payable'] as num?)?.toDouble() ?? 0,
      balance: (json['balance'] as num?)?.toDouble() ?? 0,
      paidThroughAt: DateTime.tryParse(json['paid_through_at']?.toString() ?? ''),
      nextRepaymentAt: DateTime.tryParse(json['next_repayment_at']?.toString() ?? ''),
      phoneName: phone['phone_name'] as String? ?? 'Phone',
      imei: phone['imei'] as String?,
      schedule: ((json['schedule'] as List<dynamic>?) ?? const [])
          .map((item) => ScheduleRow.fromJson(item as Map<String, dynamic>))
          .toList(),
      repayments: ((json['repayments'] as List<dynamic>?) ?? const [])
          .map((item) => Repayment.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class CustomerCase {
  final int id;
  final String caseNo;
  final String category;
  final String status;
  final String priority;
  final double amountCollected;
  final DateTime? createdAt;

  const CustomerCase({required this.id, required this.caseNo, required this.category, required this.status, required this.priority, required this.amountCollected, this.createdAt});

  factory CustomerCase.fromJson(Map<String, dynamic> json) => CustomerCase(
    id: json['id'] as int,
    caseNo: json['case_no'] as String? ?? '',
    category: json['category'] as String? ?? '',
    status: json['status'] as String? ?? '',
    priority: json['priority'] as String? ?? '',
    amountCollected: (json['amount_collected'] as num?)?.toDouble() ?? 0,
    createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
  );
}

class CaseActivity {
  final String type;
  final String? notes;
  final DateTime? promisedPayDate;
  final String loggedBy;
  final DateTime? createdAt;

  const CaseActivity({required this.type, this.notes, this.promisedPayDate, required this.loggedBy, this.createdAt});

  factory CaseActivity.fromJson(Map<String, dynamic> json) => CaseActivity(
    type: json['activity_type'] as String? ?? '',
    notes: json['notes'] as String?,
    promisedPayDate: DateTime.tryParse(json['promised_pay_date']?.toString() ?? ''),
    loggedBy: json['logged_by'] as String? ?? '',
    createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
  );
}

class CustomerCaseDetail extends CustomerCase {
  final List<CaseActivity> activities;
  final List<String> recordingUrls;

  const CustomerCaseDetail({
    required super.id,
    required super.caseNo,
    required super.category,
    required super.status,
    required super.priority,
    required super.amountCollected,
    super.createdAt,
    this.activities = const [],
    this.recordingUrls = const [],
  });

  factory CustomerCaseDetail.fromJson(Map<String, dynamic> json) => CustomerCaseDetail(
    id: json['id'] as int,
    caseNo: json['case_no'] as String? ?? '',
    category: json['category'] as String? ?? '',
    status: json['status'] as String? ?? '',
    priority: json['priority'] as String? ?? '',
    amountCollected: (json['amount_collected'] as num?)?.toDouble() ?? 0,
    createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
    activities: ((json['activities'] as List<dynamic>?) ?? const [])
        .map((item) => CaseActivity.fromJson(item as Map<String, dynamic>))
        .toList(),
    recordingUrls: ((json['recordings'] as List<dynamic>?) ?? const [])
        .map((item) => (item as Map<String, dynamic>)['url']?.toString() ?? '')
        .where((url) => url.isNotEmpty)
        .toList(),
  );
}

class PaymentAttempt {
  final int paymentId;
  final String status;
  final String? transactionId;
  final String message;

  const PaymentAttempt({required this.paymentId, required this.status, this.transactionId, required this.message});

  factory PaymentAttempt.fromJson(Map<String, dynamic> json) => PaymentAttempt(
    paymentId: json['payment_id'] as int,
    status: json['status'] as String? ?? 'pending',
    transactionId: json['transaction_id'] as String?,
    message: json['message'] as String? ?? '',
  );
}
