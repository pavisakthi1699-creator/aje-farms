import 'dotenv/config';

import { spawnSync } from 'node:child_process';
import fs from 'node:fs';
import path from 'node:path';

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
const args = [
  'build',
  'appbundle',
  '--release',
  `--dart-define=AJE_API_BASE_URL=${process.env.AJE_ANDROID_API_BASE_URL}`,
  `--dart-define=AJE_WHATSAPP_EXPERT_PHONE=${process.env.AJE_WHATSAPP_EXPERT_PHONE}`,
];

const result = spawnSync(flutterBin, args, {
  cwd: path.join(rootDir, 'aje_farms_mobile'),
  stdio: 'inherit',
});

process.exit(result.status ?? 1);
