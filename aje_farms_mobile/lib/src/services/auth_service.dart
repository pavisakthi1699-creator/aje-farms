abstract interface class AuthService {
  Future<OtpChallenge> requestOtp(String phoneNumber);
  Future<AuthSession> verifyOtp({
    required String phoneNumber,
    required String otp,
    required String challengeId,
  });
  Future<AuthSession> getSession(String phoneNumber);
  Future<AuthSession> cancelSubscription(String phoneNumber);
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
  const AuthSession({
    required this.phoneNumber,
    this.userId,
    this.role,
    this.subscriptionPlan,
    this.subscriptionStartedAt,
    this.sessionToken,
  });

  final String phoneNumber;
  final String? userId;
  final String? role;
  final String? subscriptionPlan;
  final DateTime? subscriptionStartedAt;
  final String? sessionToken;

  bool get hasActiveSubscription => subscriptionPlan != null;
}

class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => 'AuthException: $message';
}
