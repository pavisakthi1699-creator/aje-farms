import assert from 'node:assert/strict';
import test from 'node:test';

import { validateAndroidArtifactMetadata } from '../android-release.js';

test('native Android release metadata accepts the Flutter application', () => {
  const result = validateAndroidArtifactMetadata({
    entries: [
      'assets/flutter_assets/AssetManifest.bin',
      'lib/arm64-v8a/libapp.so',
      'lib/arm64-v8a/libflutter.so',
    ],
    badging: [
      "package: name='com.ajefarms.mobile' versionCode='1' versionName='0.1.0'",
      "launchable-activity: name='com.ajefarms.mobile.MainActivity'",
    ].join('\n'),
  });

  assert.deepEqual(result, { ok: true, errors: [] });
});

test('native Android release metadata rejects a Median WebView wrapper', () => {
  const result = validateAndroidArtifactMetadata({
    entries: [
      'assets/GoNativeJSBridgeLibrary.js',
      'assets/appConfig.json',
      'classes.dex',
    ],
    badging: [
      "package: name='co.median.android.wexpnqx' versionCode='3' versionName='1.0.0'",
      "launchable-activity: name='co.median.android.LaunchActivity'",
    ].join('\n'),
  });

  assert.equal(result.ok, false);
  assert.ok(
    result.errors.some((error) =>
      error.includes('Expected package com.ajefarms.mobile'),
    ),
  );
  assert.ok(
    result.errors.some((error) =>
      error.includes('Flutter release library is missing'),
    ),
  );
  assert.ok(
    result.errors.some((error) =>
      error.includes('WebView wrapper asset detected'),
    ),
  );
});

test('native Android release metadata requires Flutter assets and activity', () => {
  const result = validateAndroidArtifactMetadata({
    entries: ['classes.dex', 'lib/arm64-v8a/libflutter.so'],
    badging: [
      "package: name='com.ajefarms.mobile' versionCode='1' versionName='0.1.0'",
      "launchable-activity: name='com.example.MainActivity'",
    ].join('\n'),
  });

  assert.equal(result.ok, false);
  assert.ok(
    result.errors.some((error) =>
      error.includes('Flutter asset manifest is missing'),
    ),
  );
  assert.ok(
    result.errors.some((error) =>
      error.includes('Expected Flutter launch activity'),
    ),
  );
});
