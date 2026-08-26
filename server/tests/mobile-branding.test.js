import assert from 'node:assert/strict';
import crypto from 'node:crypto';
import fs from 'node:fs';
import path from 'node:path';
import test from 'node:test';

const rootDir = path.resolve(import.meta.dirname, '..', '..');
const mobileDir = path.join(rootDir, 'aje_farms_mobile');

function read(relativePath) {
  return fs.readFileSync(path.join(rootDir, relativePath), 'utf8');
}

function pngDimensions(relativePath) {
  const buffer = fs.readFileSync(path.join(rootDir, relativePath));
  assert.equal(buffer.subarray(1, 4).toString('ascii'), 'PNG');
  return {
    width: buffer.readUInt32BE(16),
    height: buffer.readUInt32BE(20),
  };
}

function sha256(relativePath) {
  return crypto
    .createHash('sha256')
    .update(fs.readFileSync(path.join(rootDir, relativePath)))
    .digest('hex');
}

test('mobile product name is consistently branded for users', () => {
  const manifest = read(
    'aje_farms_mobile/android/app/src/main/AndroidManifest.xml',
  );
  const materialApp = read(
    'aje_farms_mobile/lib/src/app/aje_farms_app.dart',
  );
  const webManifest = JSON.parse(
    read('aje_farms_mobile/web/manifest.json'),
  );
  const profile = read(
    'aje_farms_mobile/lib/src/features/profile/profile_screen.dart',
  );
  const api = read('server/api.js');

  assert.match(manifest, /android:label="Chuo Kikuu Cha Mtaani"/);
  assert.match(materialApp, /title: 'Chuo Kikuu Cha Mtaani'/);
  assert.equal(webManifest.name, 'Chuo Kikuu Cha Mtaani');
  assert.equal(webManifest.short_name, 'Chuo Mtaani');
  assert.doesNotMatch(profile, /return signedIn \? 'MF' : 'AJE'/);
  assert.doesNotMatch(api, /timu ya AJE(?:\.|')/);

  for (const directory of ['lib', 'web']) {
    const files = fs
      .readdirSync(path.join(mobileDir, directory), {
        recursive: true,
        withFileTypes: true,
      })
      .filter((entry) => entry.isFile())
      .map((entry) => path.join(entry.parentPath, entry.name));

    for (const file of files) {
      assert.doesNotMatch(
        fs.readFileSync(file, 'utf8'),
        /AJE Farms/i,
        `${file} still contains the former user-facing product name`,
      );
    }
  }
});

test('supplied logo drives app, adaptive, web, and Android icon assets', () => {
  const pubspec = read('aje_farms_mobile/pubspec.yaml');
  const brandMark = read(
    'aje_farms_mobile/lib/src/shared/widgets/brand_mark.dart',
  );

  assert.match(pubspec, /chuo-kikuu-cha-mtaani-logo\.png/);
  assert.match(pubspec, /chuo-kikuu-cha-mtaani-logo-adaptive-fg\.png/);
  assert.match(brandMark, /chuo-kikuu-cha-mtaani-logo\.png/);

  assert.deepEqual(
    pngDimensions(
      'aje_farms_mobile/assets/branding/chuo-kikuu-cha-mtaani-logo.png',
    ),
    { width: 1024, height: 1024 },
  );
  assert.deepEqual(
    pngDimensions(
      'aje_farms_mobile/assets/branding/chuo-kikuu-cha-mtaani-logo-adaptive-fg.png',
    ),
    { width: 1536, height: 1536 },
  );
  assert.deepEqual(
    pngDimensions('aje_farms_mobile/web/icons/Icon-512.png'),
    { width: 512, height: 512 },
  );
  assert.deepEqual(
    pngDimensions(
      'aje_farms_mobile/android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png',
    ),
    { width: 192, height: 192 },
  );
  assert.equal(
    sha256(
      'aje_farms_mobile/assets/branding/chuo-kikuu-cha-mtaani-logo.png',
    ),
    '2f1922224f25d157464356a3eb26815a610ec0cf3339d5cb4e379f86d7699f49',
  );
  assert.equal(
    sha256(
      'aje_farms_mobile/assets/branding/chuo-kikuu-cha-mtaani-logo-adaptive-fg.png',
    ),
    '975416692d6d1c7758cc3236fbb84788d6bba6e817a5b69f786f6afa2b6b8f0b',
  );
  assert.equal(
    sha256(
      'aje_farms_mobile/android/app/src/main/res/drawable-xxxhdpi/ic_launcher_foreground.png',
    ),
    'c2142336d699263a1810d7a611b2478419d43fcf131acafb67ba66fe0e0ef5ef',
  );
  assert.equal(
    sha256(
      'aje_farms_mobile/android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png',
    ),
    'e14587ecfef29a7c47535ae90a0d0a300b36aeca9d6c1142a8106900c4c1925b',
  );
});
