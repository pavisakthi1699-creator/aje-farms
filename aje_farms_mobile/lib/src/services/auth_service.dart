/// Sign-up/sign-in/reset go straight to Supabase Auth; `getSession`,
/// `updateProfile`, `cancelSubscription`, and admin diagnostics go to the AJE
/// backend, authenticated with the Supabase access token. See
/// [BackendAuthService] for the split.
abstract interface class AuthService {
  Future<void> signUp({required String email, required String password});
  Future<void> signIn({required String email, required String password});
  Future<void> signOut();
  Future<void> sendPasswordResetEmail(String email);
  Future<void> updatePassword(String newPassword);

  /// The Supabase-backed implementation returns the current session (if the
  /// SDK already restored one) without a network call; callers still need
  /// [getSession] afterward to load role/accountStatus/profile fields.
  bool get hasLocalSession;

  Future<AuthSession> getSession();
  Future<AuthSession> cancelSubscription();
  Future<AuthSession> updateProfile({
    String? displayName,
    String? preferredLocation,
  });
  Future<AdminAccessDiagnostics> getAdminAccessDiagnostics();
}

class AuthSession {
  const AuthSession({
    required this.email,
    this.userId,
    this.role,
    this.accountStatus,
    this.subscriptionPlan,
    this.subscriptionStartedAt,
    this.displayName,
    this.preferredLocation,
  });

  final String email;
  final String? userId;
  final String? role;

  /// 'pending_activation' | 'active' | 'suspended'.
  final String? accountStatus;
  final String? subscriptionPlan;
  final DateTime? subscriptionStartedAt;
  final String? displayName;
  final String? preferredLocation;

  bool get hasActiveAccess => accountStatus == 'active';
}

class AdminAccessDiagnostics {
  const AdminAccessDiagnostics({
    required this.email,
    required this.role,
    required this.hasAdminAccess,
    required this.allowlistedAdmin,
    required this.source,
  });

  final String email;
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
