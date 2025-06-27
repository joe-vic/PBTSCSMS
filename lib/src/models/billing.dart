class Billing {
  final String id;
  final String studentId;
  final double amount;
  final String paymentMethod; // 'gcash', 'paymaya', 'cash'
  final String status; // 'pending', 'completed', 'failed'
  final DateTime dueDate;
  final DateTime? paymentDate;

  Billing({
    required this.id,
    required this.studentId,
    required this.amount,
    required this.paymentMethod,
    required this.status,
    required this.dueDate,
    this.paymentDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'studentId': studentId,
      'amount': amount,
      'paymentMethod': paymentMethod,
      'status': status,
      'dueDate': dueDate.toIso8601String(),
      'paymentDate': paymentDate?.toIso8601String(),
    };
  }

  factory Billing.fromMap(Map<String, dynamic> map) {
    return Billing(
      id: map['id'] ?? '',
      studentId: map['studentId'] ?? '',
      amount: (map['amount'] as num).toDouble(),
      paymentMethod: map['paymentMethod'] ?? '',
      status: map['status'] ?? 'pending',
      dueDate: DateTime.parse(map['dueDate']),
      paymentDate: map['paymentDate'] != null
          ? DateTime.parse(map['paymentDate'])
          : null,
    );
  }
}