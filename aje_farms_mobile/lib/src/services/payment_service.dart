abstract interface class PaymentService {
  Future<PaymentTransaction> startCheckout({
    required String planTitle,
    required String price,
    required String method,
    required String phoneNumber,
  });

  Future<PaymentTransaction> getStatus(String transactionId);
}

class PaymentTransaction {
  const PaymentTransaction({
    required this.id,
    required this.planTitle,
    required this.price,
    required this.method,
    required this.phoneNumber,
    required this.status,
    required this.message,
    this.receiptNumber,
    this.subscriptionPlan,
    this.subscriptionStartedAt,
    this.checkoutInstructions,
  });

  final String id;
  final String planTitle;
  final String price;
  final String method;
  final String phoneNumber;
  final PaymentStatus status;
  final String message;
  final String? receiptNumber;
  final String? subscriptionPlan;
  final DateTime? subscriptionStartedAt;
  final String? checkoutInstructions;

  bool get isPaid => status == PaymentStatus.paid;
  bool get isPending => status == PaymentStatus.pending;
}

enum PaymentStatus {
  pending,
  paid,
  failed;

  static PaymentStatus fromWire(String value) {
    return switch (value) {
      'pending' => PaymentStatus.pending,
      'paid' => PaymentStatus.paid,
      'failed' => PaymentStatus.failed,
      _ => throw PaymentException('Unknown payment status: $value'),
    };
  }

  String get wireValue => switch (this) {
        PaymentStatus.pending => 'pending',
        PaymentStatus.paid => 'paid',
        PaymentStatus.failed => 'failed',
      };
}

class PaymentException implements Exception {
  const PaymentException(this.message);

  final String message;

  @override
  String toString() => 'PaymentException: $message';
}
