import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

const _assetRoot = 'assets/images';
const _maxPhotoBytes = 400 * 1024;
const _minPhotoWidth = 800;
const _minPhotoHeight = 600;

void main() {
  final expectedPhotos = [
    File('$_assetRoot/courses/pasheni.jpg'),
    File('$_assetRoot/courses/nyanya.jpg'),
    File('$_assetRoot/courses/kuku.jpg'),
    File('$_assetRoot/hero/farm-field.jpg'),
  ];

  test('photo asset directories are registered in pubspec', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();

    expect(pubspec, contains('- assets/images/courses/'));
    expect(pubspec, contains('- assets/images/hero/'));
  });

  test('all curated photos exist, are JPEGs, and stay within size budget', () {
    for (final file in expectedPhotos) {
      expect(file.existsSync(), isTrue, reason: '${file.path} is missing');

      final bytes = file.readAsBytesSync();
      expect(bytes.lengthInBytes, lessThanOrEqualTo(_maxPhotoBytes),
          reason: '${file.path} exceeds the photo byte budget');
      expect(bytes.take(3), [0xff, 0xd8, 0xff],
          reason: '${file.path} is not a JPEG');
    }
  });

  test('all curated photos meet minimum display dimensions', () {
    for (final file in expectedPhotos) {
      final bytes = file.readAsBytesSync();
      final dimensions = _readJpegDimensions(bytes);

      expect(dimensions.width, greaterThanOrEqualTo(_minPhotoWidth),
          reason: '${file.path} is too narrow for release UI');
      expect(dimensions.height, greaterThanOrEqualTo(_minPhotoHeight),
          reason: '${file.path} is too short for release UI');
    }
  });

  test('hero photo is visually distinct from course photos', () {
    final heroBytes = File('$_assetRoot/hero/farm-field.jpg').readAsBytesSync();
    final courseFiles = expectedPhotos.where(
      (file) => file.path.startsWith('$_assetRoot/courses/'),
    );

    for (final file in courseFiles) {
      expect(
        listEquals(heroBytes, file.readAsBytesSync()),
        isFalse,
        reason: 'Hero photo duplicates ${file.path}',
      );
    }
  });
}

({int width, int height}) _readJpegDimensions(List<int> bytes) {
  var offset = 2;
  while (offset + 9 < bytes.length) {
    while (offset < bytes.length && bytes[offset] != 0xff) {
      offset += 1;
    }
    if (offset + 3 >= bytes.length) break;

    final marker = bytes[offset + 1];
    offset += 2;
    if (marker == 0xd9 || marker == 0xda) break;

    final segmentLength = (bytes[offset] << 8) + bytes[offset + 1];
    if (_isStartOfFrame(marker)) {
      final height = (bytes[offset + 3] << 8) + bytes[offset + 4];
      final width = (bytes[offset + 5] << 8) + bytes[offset + 6];
      return (width: width, height: height);
    }
    offset += segmentLength;
  }

  throw const FormatException('Could not read JPEG dimensions.');
}

bool _isStartOfFrame(int marker) {
  return switch (marker) {
    0xc0 ||
    0xc1 ||
    0xc2 ||
    0xc3 ||
    0xc5 ||
    0xc6 ||
    0xc7 ||
    0xc9 ||
    0xca ||
    0xcb ||
    0xcd ||
    0xce ||
    0xcf =>
      true,
    _ => false,
  };
}
