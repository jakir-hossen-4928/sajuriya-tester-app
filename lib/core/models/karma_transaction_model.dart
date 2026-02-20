class KarmaTransaction {
  final String id;
  final String userId;
  final int amount;
  final String type; // credit, debit
  final String reason;
  final String? referenceId;
  final DateTime createdAt;

  KarmaTransaction({
    required this.id,
    required this.userId,
    required this.amount,
    required this.type,
    required this.reason,
    this.referenceId,
    required this.createdAt,
  });

  factory KarmaTransaction.fromMap(Map<String, dynamic> map) {
    return KarmaTransaction(
      id: map['id'],
      userId: map['user_id'],
      amount: map['amount'],
      type: map['type'],
      reason: map['reason'],
      referenceId: map['reference_id'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'amount': amount,
      'type': type,
      'reason': reason,
      'reference_id': referenceId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  bool get isCredit => type == 'credit';
}
