import 'package:aje_farms_mobile/src/app.dart';

/// An [AuthService] that reports whatever account status a test needs.
///
/// The demo [LocalAuthService] always answers `active`, which is the wrong
/// backend for any test about *not* having access: the pending screen
/// re-checks with the server on open, so a demo-backed session unlocks itself.
class StubAuthService implements AuthService {
  StubAuthService(this.accountStatus, {this.role = 'learner'});

  /// Mutable so a test can simulate an admin approving mid-session.
  String accountStatus;
  final String role;

  @override
  bool get hasLocalSession => true;

  @override
  Future<AuthSession> getSession() async => AuthSession(
        email: 'mkulima@aje.test',
        role: role,
        accountStatus: accountStatus,
        subscriptionPlan: accountStatus == 'active' ? 'Wiki 1' : null,
        termsAcceptedVersion: currentTermsVersion,
      );

  @override
  Future<AuthSession> cancelSubscription() async => getSession();

  @override
  Future<void> deleteAccount() async {}

  @override
  Future<AuthSession> acceptCommunityTerms() async => AuthSession(
        email: 'mkulima@aje.test',
        role: role,
        accountStatus: accountStatus,
        termsAcceptedVersion: currentTermsVersion,
      );

  @override
  Future<AuthSession> updateProfile({
    String? displayName,
    String? preferredLocation,
  }) async =>
      getSession();

  @override
  Future<AdminAccessDiagnostics> getAdminAccessDiagnostics() async =>
      AdminAccessDiagnostics(
        email: 'mkulima@aje.test',
        role: role,
        hasAdminAccess: role == 'admin',
        allowlistedAdmin: false,
        source: 'stub',
      );

  @override
  Future<SignUpResult> signUp({
    required String email,
    required String password,
  }) async =>
      const SignUpResult(emailConfirmationRequired: false);

  @override
  Future<void> resendSignUpConfirmation(String email) async {}

  @override
  Future<void> signIn({
    required String email,
    required String password,
  }) async {}

  @override
  Future<void> signOut() async {}

  @override
  Future<void> sendPasswordResetEmail(String email) async {}

  @override
  Future<void> updatePassword(String newPassword) async {}
}
