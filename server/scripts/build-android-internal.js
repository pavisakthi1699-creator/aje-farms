import 'dotenv/config';

import { spawnSync } from 'node:child_process';
import path from 'node:path';

import {
  internalTestingDartDefines,
  validateAndroidApk,
} from '../android-release.js';

const rootDir = process.cwd();
const flutterBin =
  process.env.FLUTTER_BIN ??
  '/Users/frankmchaina/development/flutter/bin/flutter';
const mobileDir = path.join(rootDir, 'aje_farms_mobile');

let dartDefines;
try {
  dartDefines = internalTestingDartDefines(process.env);
} catch (error) {
  console.error(error instanceof Error ? error.message : error);
  process.exit(1);
}

const result = spawnSync(
  flutterBin,
  ['build', 'apk', '--release', ...dartDefines],
  { cwd: mobileDir, stdio: 'inherit' },
);
if (result.status !== 0) {
  process.exit(result.status ?? 1);
}

const apkPath = path.join(
  mobileDir,
  'build',
  'app',
  'outputs',
  'flutter-apk',
  'app-release.apk',
);
const validation = validateAndroidApk(apkPath);
if (!validation.ok) {
  console.error('Internal Android APK validation failed:');
  for (const error of validation.errors) console.error(`- ${error}`);
  process.exit(1);
}

console.log(
  `Validated production-parity internal APK: ${validation.packageName} (${apkPath})`,
);
