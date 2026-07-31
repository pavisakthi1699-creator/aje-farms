import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Atkinson Hyperlegible is the app's legibility typeface, chosen for farmers
/// reading on cheap screens in bright sun. Fetching it from a CDN at first
/// launch meant a learner on a weak rural connection — the exact person the
/// typeface is for — saw the fallback font instead, or never got it at all.
/// These tests keep the font in the APK.
void main() {
  const fontFiles = [
    'assets/fonts/AtkinsonHyperlegible-Regular.ttf',
    'assets/fonts/AtkinsonHyperlegible-Bold.ttf',
  ];

  test('brand font files ship with the app', () {
    for (final path in fontFiles) {
      final file = File(path);
      expect(file.existsSync(), isTrue, reason: '$path is missing');

      // sfnt magic: a truncated or LFS-pointer download would still "exist".
      final magic = file.readAsBytesSync().take(4).toList();
      expect(magic, [0x00, 0x01, 0x00, 0x00], reason: '$path is not TrueType');
    }
  });

  test('pubspec declares the bundled font family', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();

    expect(pubspec, contains('family: Atkinson Hyperlegible'));
    for (final path in fontFiles) {
      expect(pubspec, contains(path));
    }
  });

  test('the OFL licence travels with the font', () {
    final licence = File('assets/fonts/OFL.txt');

    expect(licence.existsSync(), isTrue);
    expect(licence.readAsStringSync(), contains('SIL Open Font License'));
  });

  test('no runtime font fetching is reachable from app code', () {
    final offenders = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .where((file) => file.readAsStringSync().contains('google_fonts'))
        .map((file) => file.path)
        .toList();

    expect(
      offenders,
      isEmpty,
      reason: 'google_fonts downloads at first launch; use the bundled family',
    );
  });
}
