import 'auth_service.dart';

class LocalAuthService implements AuthService {
  const LocalAuthService();

  static const _otp = '1234';

  @override
  Future<OtpChallenge> requestOtp(String phoneNumber) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return OtpChallenge(
      challengeId: 'local-$phoneNumber',
      message: 'OTP ya majaribio imetumwa kwa $phoneNumber.',
      debugOtp: _otp,
    );
  }

  @override
  Future<AuthSession> verifyOtp({
    required String phoneNumber,
    required String otp,
    required String challengeId,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    if (otp != _otp) {
      throw const AuthException('OTP si sahihi. Jaribu tena.');
    }
    return AuthSession(phoneNumber: phoneNumber);
  }

  @override
  Future<AuthSession> getSession(String phoneNumber) async {
    return AuthSession(phoneNumber: phoneNumber);
  }

  @override
  Future<AuthSession> cancelSubscription(String phoneNumber) async {
    return AuthSession(phoneNumber: phoneNumber);
  }

  @override
  Future<AuthSession> updateProfile({
    required String phoneNumber,
    String? displayName,
    String? preferredLocation,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    return AuthSession(
      phoneNumber: phoneNumber,
      displayName:
          displayName?.trim().isEmpty ?? true ? null : displayName?.trim(),
      preferredLocation: preferredLocation?.trim().isEmpty ?? true
          ? null
          : preferredLocation?.trim(),
    );
  }

  @override
  Future<AdminAccessDiagnostics> getAdminAccessDiagnostics() async {
    return const AdminAccessDiagnostics(
      phoneNumber: '+255000000000',
      role: 'learner',
      hasAdminAccess: false,
      allowlistedAdmin: false,
      source: 'local_mock',
    );
  }
}
