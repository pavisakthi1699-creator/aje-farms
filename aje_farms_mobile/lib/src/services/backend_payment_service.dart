import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'payment_service.dart';

class BackendPaymentService implements PaymentService {
  BackendPaymentService({
    required Uri baseUrl,
    http.Client? client,
    this.timeout = const Duration(seconds: 20),
  })  : _baseUrl = baseUrl,
        _client = client ?? http.Client();

  final Uri _baseUrl;
  final http.Client _client;
  final Duration timeout;

  @override
  Future<PaymentTransaction> startCheckout({
    required String planTitle,
    required String price,
    required String method,
    required String phoneNumber,
  }) async {
    final payload = await _post('/api/payments/checkout', {
      'planTitle': planTitle,
      'price': price,
      'method': method,
      'phoneNumber': phoneNumber,
    });
    return _transactionFromJson(payload);
  }

  @override
  Future<PaymentTransaction> getStatus(String transactionId) async {
    final response = await _client
        .get(_baseUrl.resolve('/api/payments/$transactionId'))
        .timeout(timeout);

    final payload = jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw PaymentException(
        payload is Map<String, dynamic> && payload['error'] is String
            ? payload['error'] as String
            : 'Payment status request failed.',
      );
    }
    if (payload is! Map<String, dynamic>) {
      throw const PaymentException(
          'Payment service returned an invalid response.');
    }
    return _transactionFromJson(payload);
  }

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body,
  ) async {
    final response = await _client
        .post(
          _baseUrl.resolve(path),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(timeout);

    final payload = jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw PaymentException(
        payload is Map<String, dynamic> && payload['error'] is String
            ? payload['error'] as String
            : 'Payment request failed.',
      );
    }
    if (payload is! Map<String, dynamic>) {
      throw const PaymentException(
          'Payment service returned an invalid response.');
    }
    return payload;
  }
}

class FallbackPaymentService implements PaymentService {
  const FallbackPaymentService({
    required this.primary,
    required this.fallback,
  });

  final PaymentService primary;
  final PaymentService fallback;

  @override
  Future<PaymentTransaction> startCheckout({
    required String planTitle,
    required String price,
    required String method,
    required String phoneNumber,
  }) async {
    try {
      return await primary.startCheckout(
        planTitle: planTitle,
        price: price,
        method: method,
        phoneNumber: phoneNumber,
      );
    } catch (_) {
      return fallback.startCheckout(
        planTitle: planTitle,
        price: price,
        method: method,
        phoneNumber: phoneNumber,
      );
    }
  }

  @override
  Future<PaymentTransaction> getStatus(String transactionId) async {
    try {
      return await primary.getStatus(transactionId);
    } catch (_) {
      return fallback.getStatus(transactionId);
    }
  }
}

PaymentTransaction _transactionFromJson(Map<String, dynamic> json) {
  return PaymentTransaction(
    id: json['id'] as String,
    planTitle: json['planTitle'] as String,
    price: json['price'] as String,
    method: json['method'] as String,
    phoneNumber: json['phoneNumber'] as String,
    status: PaymentStatus.fromWire(json['status'] as String),
    message: json['message'] as String,
    receiptNumber: json['receiptNumber'] as String?,
  );
}
