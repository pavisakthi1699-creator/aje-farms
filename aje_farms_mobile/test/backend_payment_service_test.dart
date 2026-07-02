import 'package:aje_farms_mobile/src/services/backend_payment_service.dart';
import 'package:aje_farms_mobile/src/services/payment_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('starts checkout with backend and returns transaction', () async {
    late http.Request capturedRequest;
    final service = BackendPaymentService(
      baseUrl: Uri.parse('http://localhost:3000'),
      client: MockClient((request) async {
        capturedRequest = request;
        return http.Response(
          '{"id":"pay-1","planTitle":"Wiki 1","price":"TZS 3,000","method":"Tigo","phoneNumber":"0712345678","status":"paid","message":"Paid","receiptNumber":"AJE-000001"}',
          200,
        );
      }),
    );

    final transaction = await service.startCheckout(
      planTitle: 'Wiki 1',
      price: 'TZS 3,000',
      method: 'Tigo',
      phoneNumber: '0712345678',
    );

    expect(transaction.id, 'pay-1');
    expect(transaction.isPaid, isTrue);
    expect(transaction.receiptNumber, 'AJE-000001');
    expect(capturedRequest.url.toString(),
        'http://localhost:3000/api/payments/checkout');
    expect(capturedRequest.body, contains('"method":"Tigo"'));
  });

  test('gets payment status from backend', () async {
    final service = BackendPaymentService(
      baseUrl: Uri.parse('http://localhost:3000'),
      client: MockClient((request) async {
        expect(
            request.url.toString(), 'http://localhost:3000/api/payments/pay-1');
        return http.Response(
          '{"id":"pay-1","planTitle":"Wiki 1","price":"TZS 3,000","method":"Tigo","phoneNumber":"0712345678","status":"paid","message":"Paid"}',
          200,
        );
      }),
    );

    final transaction = await service.getStatus('pay-1');

    expect(transaction.status, PaymentStatus.paid);
  });

  test('throws typed exception for backend payment errors', () {
    final service = BackendPaymentService(
      baseUrl: Uri.parse('http://localhost:3000'),
      client: MockClient((_) async {
        return http.Response('{"error":"Payment failed"}', 400);
      }),
    );

    expect(
      () => service.startCheckout(
        planTitle: 'Wiki 1',
        price: 'TZS 3,000',
        method: 'Tigo',
        phoneNumber: '0712345678',
      ),
      throwsA(isA<PaymentException>()),
    );
  });

  test('fallback payment service uses local payment when backend fails',
      () async {
    final service = FallbackPaymentService(
      primary: BackendPaymentService(
        baseUrl: Uri.parse('http://localhost:3000'),
        client: MockClient((_) async {
          return http.Response('{"error":"Offline"}', 500);
        }),
      ),
      fallback: const LocalPaymentForTest(),
    );

    final transaction = await service.startCheckout(
      planTitle: 'Wiki 1',
      price: 'TZS 3,000',
      method: 'Tigo',
      phoneNumber: '0712345678',
    );

    expect(transaction.id, 'local-test');
    expect(transaction.status, PaymentStatus.paid);
  });
}

class LocalPaymentForTest implements PaymentService {
  const LocalPaymentForTest();

  @override
  Future<PaymentTransaction> startCheckout({
    required String planTitle,
    required String price,
    required String method,
    required String phoneNumber,
  }) async {
    return PaymentTransaction(
      id: 'local-test',
      planTitle: planTitle,
      price: price,
      method: method,
      phoneNumber: phoneNumber,
      status: PaymentStatus.paid,
      message: 'Paid locally',
    );
  }

  @override
  Future<PaymentTransaction> getStatus(String transactionId) async {
    return PaymentTransaction(
      id: transactionId,
      planTitle: 'Wiki 1',
      price: 'TZS 3,000',
      method: 'Local',
      phoneNumber: '0712345678',
      status: PaymentStatus.paid,
      message: 'Paid locally',
    );
  }
}
