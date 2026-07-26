import 'dart:math' as math;

import 'package:aje_farms_mobile/src/theme/app_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// WCAG 2.1 relative luminance.
double _luminance(Color color) {
  double channel(double value) {
    return value <= 0.03928
        ? value / 12.92
        : math.pow((value + 0.055) / 1.055, 2.4).toDouble();
  }

  return 0.2126 * channel(color.r) +
      0.7152 * channel(color.g) +
      0.0722 * channel(color.b);
}

/// WCAG 2.1 contrast ratio between two opaque colours.
double contrastRatio(Color a, Color b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  final hi = math.max(la, lb);
  final lo = math.min(la, lb);
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  // `charcoal` is deliberately the same dark tone in both themes, so its
  // foregrounds must be legible in both. A regression here previously left dark
  // mode snack bar text at 1.03:1 — invisible.
  const schemes = <String, AppColorScheme>{
    'light': AppColorScheme.light,
    'dark': AppColorScheme.dark,
  };

  group('snack bar surface contrast', () {
    schemes.forEach((name, colors) {
      test('$name: body text on charcoal meets AA (4.5:1)', () {
        expect(
          contrastRatio(colors.onCharcoal, colors.charcoal),
          greaterThanOrEqualTo(4.5),
        );
      });

      test('$name: action label on charcoal meets AA (4.5:1)', () {
        expect(
          contrastRatio(colors.onCharcoalAccent, colors.charcoal),
          greaterThanOrEqualTo(4.5),
        );
      });

      test('$name: action label is distinct from body text', () {
        expect(colors.onCharcoalAccent, isNot(colors.onCharcoal));
      });

      // Tone icons are non-text UI glyphs, so 3:1 is the applicable threshold.
      test('$name: error and success tone icons on charcoal meet 3:1', () {
        expect(
          contrastRatio(colors.error, colors.charcoal),
          greaterThanOrEqualTo(3.0),
        );
        expect(
          contrastRatio(colors.success, colors.charcoal),
          greaterThanOrEqualTo(3.0),
        );
      });
    });
  });

  group('core text contrast', () {
    schemes.forEach((name, colors) {
      test('$name: primary text on background meets AA (4.5:1)', () {
        expect(
          contrastRatio(colors.textPrimary, colors.background),
          greaterThanOrEqualTo(4.5),
        );
      });

      test('$name: primary text on surface meets AA (4.5:1)', () {
        expect(
          contrastRatio(colors.textPrimary, colors.surface),
          greaterThanOrEqualTo(4.5),
        );
      });

      test('$name: secondary text on surface meets 3:1', () {
        expect(
          contrastRatio(colors.textSecondary, colors.surface),
          greaterThanOrEqualTo(3.0),
        );
      });
    });
  });
}
