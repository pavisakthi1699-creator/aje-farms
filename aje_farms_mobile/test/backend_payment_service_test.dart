import 'package:aje_farms_mobile/src/services/backend_payment_service.dart';
import 'package:aje_farms_mobile/src/services/backend_session_storage.dart';
import 'package:aje_farms_mobile/src/services/payment_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  test('starts checkout with backend and returns transaction', () async {
    await BackendSessionStorage.writeToken('token-abc');
    late http.Request capturedRequest;
    final service = BackendPaymentService(
      baseUrl: Uri.parse('http://localhost:3000'),
      client: MockClient((request) async {
        capturedRequest = request;
        return http.Response(
          '{"id":"pay-1","planTitle":"Wiki 1","price":"TZS 3,000","method":"Tigo","phoneNumber":"+255712345678","status":"pending","message":"Pending","checkoutInstructions":"Confirm on phone","receiptNumber":null,"subscriptionPlan":null,"subscriptionStartedAt":null}',
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
    expect(transaction.status, PaymentStatus.pending);
    expect(transaction.isPending, isTrue);
    expect(transaction.checkoutInstructions, 'Confirm on phone');
    expect(transaction.subscriptionPlan, isNull);
    expect(capturedRequest.url.toString(),
        'http://localhost:3000/api/payments/checkout');
    expect(capturedRequest.headers['Authorization'], 'Bearer token-abc');
    expect(capturedRequest.body, contains('"method":"Tigo"'));
  });

  test('gets payment status from backend', () async {
    await BackendSessionStorage.writeToken('token-abc');
    final service = BackendPaymentService(
      baseUrl: Uri.parse('http://localhost:3000'),
      client: MockClient((request) async {
        expect(
            request.url.toString(), 'http://localhost:3000/api/payments/pay-1');
        expect(request.headers['Authorization'], 'Bearer token-abc');
        return http.Response(
          '{"id":"pay-1","planTitle":"Wiki 1","price":"TZS 3,000","method":"Tigo","phoneNumber":"+255712345678","status":"paid","message":"Paid","subscriptionPlan":"Wiki 1","subscriptionStartedAt":"2026-07-02T10:00:00.000Z"}',
          200,
        );
      }),
    );

    final transaction = await service.getStatus('pay-1');

    expect(transaction.status, PaymentStatus.paid);
    expect(transaction.subscriptionPlan, 'Wiki 1');
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
}
