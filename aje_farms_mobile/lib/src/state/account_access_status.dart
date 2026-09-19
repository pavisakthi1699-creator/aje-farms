import 'package:flutter/material.dart';

import 'app_session.dart';

/// The four states an account can be in, and the one place their wording lives.
///
/// Paid access is granted by staff after they approve a payment recorded
/// outside the app — there is no in-app checkout — so nothing here may invite a
/// learner to choose or buy a package.
///
/// This exists because the home card and the profile card each derived status
/// separately, from [AppSessionState.subscriptionPlan] rather than
/// [AppSessionState.hasActiveAccess]. A suspended admin was told "Akaunti yako
/// imesitishwa" on one screen and "Ufikiaji wa kawaida" on the next. Deriving
/// both from this enum keeps them in step.
enum AccountAccessStatus {
  /// Signed out. The only state where asking someone to register makes sense.
  guest(
    icon: Icons.person_add_alt_outlined,
    shortLabel: 'Hujaingia',
    body: 'Jisajili ili kuona mafunzo yanayopatikana.',
  ),

  /// Registered, waiting for an admin to verify the account.
  pending(
    icon: Icons.hourglass_empty,
    shortLabel: 'Inasubiri uthibitisho',
    body:
        'Umesajiliwa. Timu ya Chuo Kikuu Cha Mtaani itathibitisha akaunti yako '
        'ili kufungua mafunzo.',
  ),

  /// Access was granted and later withdrawn.
  suspended(
    icon: Icons.error_outline,
    shortLabel: 'Imesitishwa',
    body: 'Wasiliana na timu ya Chuo Kikuu Cha Mtaani kwa msaada.',
  ),

  /// Verified by an admin; content is unlocked.
  active(
    icon: Icons.check_circle_outline,
    shortLabel: 'Imewashwa',
    body: 'Premium iko hai. Endelea na masomo, AI na jamii.',
  );

  const AccountAccessStatus({
    required this.icon,
    required this.shortLabel,
    required this.body,
  });

  final IconData icon;

  /// One-word status for compact rows, e.g. the profile card.
  final String shortLabel;

  /// The explanatory sentence shown under the status.
  final String body;

  /// Access is keyed on [AppSessionState.hasActiveAccess] — the entitlement the
  /// server actually gates on — never on a plan name, which can lag behind it.
  static AccountAccessStatus of(AppSessionState session) {
    if (session.isGuest) return guest;
    if (session.hasActiveAccess) return active;
    return session.accountStatus == 'suspended' ? suspended : pending;
  }

  /// Headline for the home status card.
  String title(AppSessionState session) {
    return switch (this) {
      guest => 'Fungua akaunti yako',
      pending => 'Akaunti yako inasubiri uthibitisho',
      suspended => 'Akaunti yako imesitishwa',
      // Falls back when access is active before the plan name has synced.
      active => session.subscriptionPlan == null
          ? 'Akaunti yako imewashwa'
          : '${session.subscriptionPlan} imewashwa',
    };
  }
}
