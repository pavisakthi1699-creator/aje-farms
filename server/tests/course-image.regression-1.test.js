import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import test from 'node:test';

import { courseImageForCode } from '../store/postgres-store.js';

// Regression: ISSUE-002 — the Ushuhuda business course displayed a tomato photo
// Found by /qa on 2026-07-16
// Report: .gstack/qa-reports/qa-report-ushuhuda-pilot-2026-07-16.md
test('Ushuhuda course codes use the neutral farm-field image', () => {
  assert.equal(
    courseImageForCode('CRS-USH-01'),
    'assets/images/courses/pasheni.jpg',
  );
});

test('crop and livestock course image mappings use bundled assets', () => {
  assert.equal(
    courseImageForCode('RICE-SEED-001'),
    'assets/images/courses/nyanya.jpg',
  );
  assert.equal(
    courseImageForCode('CRS-KUK-02'),
    'assets/images/courses/kuku.jpg',
  );
  assert.equal(
    courseImageForCode('NYANYA-001'),
    'assets/images/courses/nyanya.jpg',
  );

  const reviewedCourseCodes = [
    'CRS-001',
    'CRS-ALZ-01',
    'CRS-CHK-01',
    'CRS-KUK-01',
    'CRS-MGB-01',
    'CRS-MHG-01',
    'CRS-MPU-01',
    'CRS-NAN-01',
    'CRS-PSH-01',
  ];
  for (const code of reviewedCourseCodes) {
    const imagePath = courseImageForCode(code);
    assert.equal(
      fs.existsSync(path.resolve('aje_farms_mobile', imagePath)),
      true,
      `${code} maps to missing Flutter asset ${imagePath}`,
    );
  }
});
