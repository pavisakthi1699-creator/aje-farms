abstract interface class AuthService {
  Future<OtpChallenge> requestOtp(String phoneNumber);
  Future<AuthSession> verifyOtp({
    required String phoneNumber,
    required String otp,
    required String challengeId,
  });
  Future<AuthSession> getSession(String phoneNumber);
  Future<AuthSession> cancelSubscription(String phoneNumber);
  Future<AuthSession> updateProfile({
    required String phoneNumber,
    String? displayName,
    String? preferredLocation,
  });
  Future<AdminAccessDiagnostics> getAdminAccessDiagnostics();
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
    this.displayName,
    this.preferredLocation,
  });

  final String phoneNumber;
  final String? userId;
  final String? role;
  final String? subscriptionPlan;
  final DateTime? subscriptionStartedAt;
  final String? sessionToken;
  final String? displayName;
  final String? preferredLocation;

  bool get hasActiveSubscription => subscriptionPlan != null;
}

class AdminAccessDiagnostics {
  const AdminAccessDiagnostics({
    required this.phoneNumber,
    required this.role,
    required this.hasAdminAccess,
    required this.allowlistedAdmin,
    required this.source,
  });

  final String phoneNumber;
  final String role;
  final bool hasAdminAccess;
  final bool allowlistedAdmin;
  final String source;
}

class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => 'AuthException: $message';
}
