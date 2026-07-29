import 'auth_service.dart';

/// Offline demo stand-in: no real Supabase project, so sign-up/sign-in just
/// accepts anything and simulates an already-active demo account.
class LocalAuthService implements AuthService {
  const LocalAuthService();

  @override
  bool get hasLocalSession => false;

  @override
  Future<void> signUp({required String email, required String password}) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
  }

  @override
  Future<void> signOut() async {}

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
  }

  @override
  Future<void> updatePassword(String newPassword) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
  }

  @override
  Future<AuthSession> getSession() async {
    return const AuthSession(
      email: 'mkulima@demo.aje',
      accountStatus: 'active',
    );
  }

  @override
  Future<AuthSession> cancelSubscription() async {
    return const AuthSession(email: 'mkulima@demo.aje');
  }

  @override
  Future<AuthSession> updateProfile({
    String? displayName,
    String? preferredLocation,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    return AuthSession(
      email: 'mkulima@demo.aje',
      accountStatus: 'active',
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
      email: 'mkulima@demo.aje',
      role: 'learner',
      hasAdminAccess: false,
      allowlistedAdmin: false,
      source: 'local_mock',
    );
  }
}
