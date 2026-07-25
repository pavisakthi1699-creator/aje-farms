import 'dotenv/config';

import { spawnSync } from 'node:child_process';
import fs from 'node:fs';
import path from 'node:path';

import {
  releaseDartDefines,
  validateAndroidApk,
} from '../android-release.js';
import { releasePreflight } from '../preflight.js';

const rootDir = process.cwd();

const preflight = releasePreflight(process.env, (relativePath) => {
  return fs.existsSync(path.resolve(rootDir, relativePath));
});

if (preflight.blockers.length > 0) {
  console.error('Android release build blocked:');
  for (const blocker of preflight.blockers) {
    console.error(`- ${blocker}`);
  }
}

if (preflight.warnings.length > 0) {
  console.warn(preflight.blockers.length > 0 ? '\nWarnings:' : 'Warnings:');
  for (const warning of preflight.warnings) {
    console.warn(`- ${warning}`);
  }
}

if (!preflight.ok) {
  process.exit(1);
}

const flutterBin =
  process.env.FLUTTER_BIN ?? '/Users/frankmchaina/development/flutter/bin/flutter';
const dartDefines = releaseDartDefines(process.env);
const mobileDir = path.join(rootDir, 'aje_farms_mobile');

const apkResult = spawnSync(flutterBin, [
  'build',
  'apk',
  '--release',
  ...dartDefines,
], {
  cwd: mobileDir,
  stdio: 'inherit',
});

if (apkResult.status !== 0) {
  process.exit(apkResult.status ?? 1);
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
  console.error('Android release APK validation failed:');
  for (const error of validation.errors) {
    console.error(`- ${error}`);
  }
  process.exit(1);
}
console.log(
  `Validated native Flutter APK: ${validation.packageName} (${apkPath})`,
);

const bundleResult = spawnSync(flutterBin, [
  'build',
  'appbundle',
  '--release',
  ...dartDefines,
], {
  cwd: mobileDir,
  stdio: 'inherit',
});

process.exit(bundleResult.status ?? 1);
