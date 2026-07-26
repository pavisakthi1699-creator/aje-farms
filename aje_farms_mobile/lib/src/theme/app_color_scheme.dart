import 'package:flutter/material.dart';

/// Semantic colors resolved from the active theme (light or dark).
@immutable
class AppColorScheme extends ThemeExtension<AppColorScheme> {
  const AppColorScheme({
    required this.background,
    required this.surface,
    required this.surfaceMuted,
    required this.surfaceLavender,
    required this.surfaceAqua,
    required this.surfacePeach,
    required this.primary,
    required this.primaryDark,
    required this.primaryContainer,
    required this.onPrimary,
    required this.onPrimarySubtle,
    required this.onPrimaryFaint,
    required this.onPrimaryBorder,
    required this.onPrimaryContainer,
    required this.textPrimary,
    required this.textSecondary,
    required this.borderSubtle,
    required this.charcoal,
    required this.onCharcoal,
    required this.onCharcoalAccent,
    required this.success,
    required this.successSurface,
    required this.warning,
    required this.error,
    required this.accentWarm,
    required this.whatsapp,
    required this.whatsappSurface,
    required this.whatsappChatBg,
    required this.whatsappBubble,
    required this.mpesa,
    required this.tigo,
    required this.airtel,
  });

  final Color background;
  final Color surface;
  final Color surfaceMuted;
  final Color surfaceLavender;
  final Color surfaceAqua;
  final Color surfacePeach;
  final Color primary;
  final Color primaryDark;
  final Color primaryContainer;
  final Color onPrimary;
  final Color onPrimarySubtle;
  final Color onPrimaryFaint;
  final Color onPrimaryBorder;
  final Color onPrimaryContainer;
  final Color textPrimary;
  final Color textSecondary;
  final Color borderSubtle;
  final Color charcoal;

  /// Foreground for [charcoal] surfaces (snack bars). [charcoal] is the same
  /// dark tone in light and dark themes, so this must stay light in both.
  final Color onCharcoal;

  /// Accent for interactive labels on [charcoal] (snack bar actions). Also
  /// theme-invariant, and kept clear of the body text colour for affordance.
  final Color onCharcoalAccent;
  final Color success;
  final Color successSurface;
  final Color warning;
  final Color error;
  final Color accentWarm;
  final Color whatsapp;
  final Color whatsappSurface;
  final Color whatsappChatBg;
  final Color whatsappBubble;
  final Color mpesa;
  final Color tigo;
  final Color airtel;

  Color get text => textPrimary;
  Color get muted => textSecondary;
  Color get mint => surfaceAqua;
  Color get blue => surfaceMuted;
  Color get peach => surfacePeach;
  Color get secondary => accentWarm;
  Color get outline => borderSubtle;

  static const light = AppColorScheme(
    background: Color(0xFFF0F4F8),
    surface: Color(0xFFFFFFFF),
    surfaceMuted: Color(0xFFE8EFF8),
    surfaceLavender: Color(0xFFECE8F8),
    surfaceAqua: Color(0xFFE0F4F0),
    surfacePeach: Color(0xFFF4EBE6),
    primary: Color(0xFF1B6B7A),
    primaryDark: Color(0xFF145A66),
    primaryContainer: Color(0xFFDCEEF3),
    onPrimary: Color(0xFFFFFFFF),
    onPrimarySubtle: Color(0xFFD8EEF2),
    onPrimaryFaint: Color(0x29FFFFFF),
    onPrimaryBorder: Color(0x33FFFFFF),
    onPrimaryContainer: Color(0xFF0F3D46),
    textPrimary: Color(0xFF1A1F2C),
    textSecondary: Color(0xFF64748B),
    borderSubtle: Color(0xFFE2E8F0),
    charcoal: Color(0xFF1A1F2C),
    onCharcoal: Color(0xFFF7F7F5),
    onCharcoalAccent: Color(0xFF5CB8CC),
    success: Color(0xFF2F8F5B),
    successSurface: Color(0xFFE8F5EE),
    warning: Color(0xFFD4A03A),
    error: Color(0xFFC85A3C),
    accentWarm: Color(0xFFC85A3C),
    whatsapp: Color(0xFF25D366),
    whatsappSurface: Color(0xFFE8F8EE),
    whatsappChatBg: Color(0xFFE5DDD5),
    whatsappBubble: Color(0xFFDCF8C6),
    mpesa: Color(0xFFE31937),
    tigo: Color(0xFF00377B),
    airtel: Color(0xFFE40000),
  );

  static const dark = AppColorScheme(
    background: Color(0xFF0E1218),
    surface: Color(0xFF171E28),
    surfaceMuted: Color(0xFF1F2835),
    surfaceLavender: Color(0xFF252038),
    surfaceAqua: Color(0xFF152824),
    surfacePeach: Color(0xFF2A221E),
    primary: Color(0xFF5CB8CC),
    primaryDark: Color(0xFF1B6B7A),
    primaryContainer: Color(0xFF1A3A42),
    onPrimary: Color(0xFF062028),
    onPrimarySubtle: Color(0xFFB8DDE6),
    onPrimaryFaint: Color(0x24FFFFFF),
    onPrimaryBorder: Color(0x33FFFFFF),
    onPrimaryContainer: Color(0xFFDCEEF3),
    textPrimary: Color(0xFFF0F4F8),
    textSecondary: Color(0xFFA6B3C2),
    borderSubtle: Color(0xFF3A4556),
    charcoal: Color(0xFF1A1F2C),
    onCharcoal: Color(0xFFF7F7F5),
    onCharcoalAccent: Color(0xFF5CB8CC),
    success: Color(0xFF5BBF82),
    successSurface: Color(0xFF1A2E24),
    warning: Color(0xFFE0B04A),
    error: Color(0xFFE07A5A),
    accentWarm: Color(0xFFE07A5A),
    whatsapp: Color(0xFF25D366),
    whatsappSurface: Color(0xFF163322),
    whatsappChatBg: Color(0xFF1E2A24),
    whatsappBubble: Color(0xFF234832),
    mpesa: Color(0xFFE31937),
    tigo: Color(0xFF4A8FD4),
    airtel: Color(0xFFE40000),
  );

  @override
  AppColorScheme copyWith({
    Color? background,
    Color? surface,
    Color? surfaceMuted,
    Color? surfaceLavender,
    Color? surfaceAqua,
    Color? surfacePeach,
    Color? primary,
    Color? primaryDark,
    Color? primaryContainer,
    Color? onPrimary,
    Color? onPrimarySubtle,
    Color? onPrimaryFaint,
    Color? onPrimaryBorder,
    Color? onPrimaryContainer,
    Color? textPrimary,
    Color? textSecondary,
    Color? borderSubtle,
    Color? charcoal,
    Color? onCharcoal,
    Color? onCharcoalAccent,
    Color? success,
    Color? successSurface,
    Color? warning,
    Color? error,
    Color? accentWarm,
    Color? whatsapp,
    Color? whatsappSurface,
    Color? whatsappChatBg,
    Color? whatsappBubble,
    Color? mpesa,
    Color? tigo,
    Color? airtel,
  }) {
    return AppColorScheme(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceMuted: surfaceMuted ?? this.surfaceMuted,
      surfaceLavender: surfaceLavender ?? this.surfaceLavender,
      surfaceAqua: surfaceAqua ?? this.surfaceAqua,
      surfacePeach: surfacePeach ?? this.surfacePeach,
      primary: primary ?? this.primary,
      primaryDark: primaryDark ?? this.primaryDark,
      primaryContainer: primaryContainer ?? this.primaryContainer,
      onPrimary: onPrimary ?? this.onPrimary,
      onPrimarySubtle: onPrimarySubtle ?? this.onPrimarySubtle,
      onPrimaryFaint: onPrimaryFaint ?? this.onPrimaryFaint,
      onPrimaryBorder: onPrimaryBorder ?? this.onPrimaryBorder,
      onPrimaryContainer: onPrimaryContainer ?? this.onPrimaryContainer,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      borderSubtle: borderSubtle ?? this.borderSubtle,
      charcoal: charcoal ?? this.charcoal,
      onCharcoal: onCharcoal ?? this.onCharcoal,
      onCharcoalAccent: onCharcoalAccent ?? this.onCharcoalAccent,
      success: success ?? this.success,
      successSurface: successSurface ?? this.successSurface,
      warning: warning ?? this.warning,
      error: error ?? this.error,
      accentWarm: accentWarm ?? this.accentWarm,
      whatsapp: whatsapp ?? this.whatsapp,
      whatsappSurface: whatsappSurface ?? this.whatsappSurface,
      whatsappChatBg: whatsappChatBg ?? this.whatsappChatBg,
      whatsappBubble: whatsappBubble ?? this.whatsappBubble,
      mpesa: mpesa ?? this.mpesa,
      tigo: tigo ?? this.tigo,
      airtel: airtel ?? this.airtel,
    );
  }

  @override
  AppColorScheme lerp(AppColorScheme? other, double t) {
    if (other == null) return this;
    Color lerpColor(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppColorScheme(
      background: lerpColor(background, other.background),
      surface: lerpColor(surface, other.surface),
      surfaceMuted: lerpColor(surfaceMuted, other.surfaceMuted),
      surfaceLavender: lerpColor(surfaceLavender, other.surfaceLavender),
      surfaceAqua: lerpColor(surfaceAqua, other.surfaceAqua),
      surfacePeach: lerpColor(surfacePeach, other.surfacePeach),
      primary: lerpColor(primary, other.primary),
      primaryDark: lerpColor(primaryDark, other.primaryDark),
      primaryContainer: lerpColor(primaryContainer, other.primaryContainer),
      onPrimary: lerpColor(onPrimary, other.onPrimary),
      onPrimarySubtle: lerpColor(onPrimarySubtle, other.onPrimarySubtle),
      onPrimaryFaint: lerpColor(onPrimaryFaint, other.onPrimaryFaint),
      onPrimaryBorder: lerpColor(onPrimaryBorder, other.onPrimaryBorder),
      onPrimaryContainer:
          lerpColor(onPrimaryContainer, other.onPrimaryContainer),
      textPrimary: lerpColor(textPrimary, other.textPrimary),
      textSecondary: lerpColor(textSecondary, other.textSecondary),
      borderSubtle: lerpColor(borderSubtle, other.borderSubtle),
      charcoal: lerpColor(charcoal, other.charcoal),
      onCharcoal: lerpColor(onCharcoal, other.onCharcoal),
      onCharcoalAccent: lerpColor(onCharcoalAccent, other.onCharcoalAccent),
      success: lerpColor(success, other.success),
      successSurface: lerpColor(successSurface, other.successSurface),
      warning: lerpColor(warning, other.warning),
      error: lerpColor(error, other.error),
      accentWarm: lerpColor(accentWarm, other.accentWarm),
      whatsapp: lerpColor(whatsapp, other.whatsapp),
      whatsappSurface: lerpColor(whatsappSurface, other.whatsappSurface),
      whatsappChatBg: lerpColor(whatsappChatBg, other.whatsappChatBg),
      whatsappBubble: lerpColor(whatsappBubble, other.whatsappBubble),
      mpesa: lerpColor(mpesa, other.mpesa),
      tigo: lerpColor(tigo, other.tigo),
      airtel: lerpColor(airtel, other.airtel),
    );
  }
}

extension AppColorSchemeContext on BuildContext {
  AppColorScheme get colors =>
      Theme.of(this).extension<AppColorScheme>() ?? AppColorScheme.light;
}
