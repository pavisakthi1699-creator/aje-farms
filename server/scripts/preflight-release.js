import 'dotenv/config';

import fs from 'node:fs';
import path from 'node:path';

import { releasePreflight } from '../preflight.js';

const result = releasePreflight(process.env, (relativePath) => {
  return fs.existsSync(path.resolve(process.cwd(), relativePath));
});

if (result.blockers.length > 0) {
  console.error('Release preflight failed:');
  for (const blocker of result.blockers) {
    console.error(`- ${blocker}`);
  }
}

if (result.warnings.length > 0) {
  console.warn(result.blockers.length > 0 ? '\nWarnings:' : 'Release preflight warnings:');
  for (const warning of result.warnings) {
    console.warn(`- ${warning}`);
  }
}

if (!result.ok) {
  process.exit(1);
}

console.log('Release preflight passed.');
