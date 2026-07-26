import 'package:flutter/foundation.dart';

/// True for debug and profile builds, and for release builds explicitly marked
/// internal with `--dart-define=AJE_INTERNAL_BUILD=true`.
///
/// Gates internal-only affordances (development OTP hint, admin access
/// diagnostics). The release build script never passes AJE_INTERNAL_BUILD, so
/// store builds always evaluate this to false.
const kInternalBuild =
    !kReleaseMode || bool.fromEnvironment('AJE_INTERNAL_BUILD');
