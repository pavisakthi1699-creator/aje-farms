import 'package:flutter/foundation.dart';

/// True for debug and profile builds, and for release builds explicitly marked
/// internal with `--dart-define=AJE_INTERNAL_BUILD=true`.
///
/// Gates internal-only affordances (development OTP hint, admin access
/// diagnostics). The release build script never passes AJE_INTERNAL_BUILD, so
/// store builds always evaluate this to false.
const kInternalBuild =
    !kReleaseMode || bool.fromEnvironment('AJE_INTERNAL_BUILD');

const privacyPolicyUrl = String.fromEnvironment('AJE_PRIVACY_POLICY_URL');
const accountDeletionUrl = String.fromEnvironment('AJE_ACCOUNT_DELETION_URL');

/// The Play build is intentionally consumption-only: learners can use access
/// already assigned to their account, but cannot buy or be directed to buy
/// digital access from inside the application.
const kPlayConsumptionOnly = bool.fromEnvironment(
  'AJE_PLAY_CONSUMPTION_ONLY',
  defaultValue: true,
);
