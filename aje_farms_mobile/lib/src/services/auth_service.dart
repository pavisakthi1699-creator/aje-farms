abstract interface class AuthService {
  Future<OtpChallenge> requestOtp(String phoneNumber);
  Future<AuthSession> verifyOtp({
    required String phoneNumber,
    required String otp,
    required String challengeId,
  });
}

class OtpChallenge {
  const OtpChallenge({
    required this.challengeId,
    required this.message,
    this.debugOtp,
  });

  final String challengeId;
  final String message;
  final String? debugOtp;
}

class AuthSession {
  const AuthSession({required this.phoneNumber});

  final String phoneNumber;
}

class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => 'AuthException: $message';
}
