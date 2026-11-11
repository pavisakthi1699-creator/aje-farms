import 'package:flutter/material.dart';

import 'app_session.dart';
import '../l10n/app_strings.dart';

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
    shortLabelSw: 'Hujaingia',
    bodySw: 'Jisajili ili kuona mafunzo yanayopatikana.',
  ),

  /// Registered, waiting for an admin to verify the account.
  pending(
    icon: Icons.hourglass_empty,
    shortLabelSw: 'Inasubiri uthibitisho',
    bodySw:
        'Umesajiliwa. Timu ya Chuo Kikuu Cha Mtaani itathibitisha akaunti yako '
        'ili kufungua mafunzo.',
  ),

  /// Access was granted and later withdrawn.
  suspended(
    icon: Icons.error_outline,
    shortLabelSw: 'Imesitishwa',
    bodySw: 'Wasiliana na timu ya Chuo Kikuu Cha Mtaani kwa msaada.',
  ),

  /// Verified by an admin; content is unlocked.
  active(
    icon: Icons.check_circle_outline,
    shortLabelSw: 'Imewashwa',
    bodySw: 'Premium iko hai. Endelea na masomo, AI na jamii.',
  );

  const AccountAccessStatus({
    required this.icon,
    required this.shortLabelSw,
    required this.bodySw,
  });

  final IconData icon;

  /// Kiswahili source text; read [shortLabel] / [body] for display.
  final String shortLabelSw;
  final String bodySw;

  /// One-word status for compact rows, e.g. the profile card.
  String get shortLabel => tr(shortLabelSw);

  /// The explanatory sentence shown under the status.
  String get body => tr(bodySw);

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
      guest => tr('Fungua akaunti yako'),
      pending => tr('Akaunti yako inasubiri uthibitisho'),
      suspended => tr('Akaunti yako imesitishwa'),
      // Falls back when access is active before the plan name has synced.
      active => session.subscriptionPlan == null
          ? tr('Akaunti yako imewashwa')
          : tr('{subscriptionPlan} imewashwa', {
              'subscriptionPlan': tr(session.subscriptionPlan ?? ''),
            }),
    };
  }
}
