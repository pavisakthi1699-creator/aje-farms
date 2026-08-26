import 'payment_service.dart';

class LocalPaymentService implements PaymentService {
  const LocalPaymentService();

  @override
  Future<PaymentTransaction> startCheckout({
    required String planTitle,
    required String price,
    required String method,
    required String phoneNumber,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    final id = 'local-${DateTime.now().microsecondsSinceEpoch}';
    return PaymentTransaction(
      id: id,
      planTitle: planTitle,
      price: price,
      method: method,
      phoneNumber: phoneNumber,
      status: PaymentStatus.paid,
      message: 'Malipo yamethibitishwa kupitia $method.',
      receiptNumber: 'CKM-${id.substring(id.length - 6)}',
      subscriptionPlan: planTitle,
      subscriptionStartedAt: DateTime.now(),
      checkoutInstructions: 'Malipo ya ndani yamethibitishwa.',
    );
  }

  @override
  Future<PaymentTransaction> getStatus(String transactionId) async {
    return PaymentTransaction(
      id: transactionId,
      planTitle: 'Kifurushi',
      price: '',
      method: 'Local',
      phoneNumber: '',
      status: PaymentStatus.paid,
      message: 'Malipo yamethibitishwa.',
      receiptNumber: 'CKM-${transactionId.substring(transactionId.length - 6)}',
      subscriptionPlan: 'Kifurushi',
      subscriptionStartedAt: DateTime.now(),
      checkoutInstructions: 'Malipo ya ndani yamethibitishwa.',
    );
  }
}
