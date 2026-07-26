import path from 'node:path';

import { validateAndroidApk } from '../android-release.js';

const apkPath = path.resolve(
  process.cwd(),
  process.argv[2] ??
    'aje_farms_mobile/build/app/outputs/flutter-apk/app-release.apk',
);

try {
  const result = validateAndroidApk(apkPath);
  if (!result.ok) {
    console.error('Android APK validation failed:');
    for (const error of result.errors) {
      console.error(`- ${error}`);
    }
    process.exitCode = 1;
  } else {
    console.log('Android APK validation passed.');
    console.log(`- APK: ${result.apkPath}`);
    console.log(`- Package: ${result.packageName}`);
    console.log(`- Activity: ${result.launchActivity}`);
    console.log('- Runtime: Flutter native');
  }
} catch (error) {
  console.error(
    error instanceof Error ? error.message : 'Android APK validation failed.',
  );
  process.exitCode = 1;
}
