import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import test from 'node:test';

import { courseImageForCode } from '../store/postgres-store.js';

const sourceCourseCodes = [
  'CRS-001',
  'CRS-ALZ-01',
  'CRS-CHK-01',
  'CRS-KUK-01',
  'CRS-KUK-02',
  'CRS-MGB-01',
  'CRS-MHG-01',
  'CRS-MPU-01',
  'CRS-NAN-01',
  'CRS-NYN-01',
  'CRS-PSH-01',
  'CRS-USH-01',
];

test('courses with linked PDFs use their own source cover artwork', () => {
  const imagePaths = sourceCourseCodes.map((code) =>
    courseImageForCode(code),
  );

  assert.equal(new Set(imagePaths).size, sourceCourseCodes.length);
  for (const [index, code] of sourceCourseCodes.entries()) {
    const expected = `assets/images/courses/${code.toLowerCase()}.jpg`;
    assert.equal(imagePaths[index], expected);
    assert.equal(
      fs.existsSync(path.resolve('aje_farms_mobile', expected)),
      true,
      `${code} maps to missing Flutter asset ${expected}`,
    );
  }
});

test('courses without source artwork retain bundled fallback images', () => {
  assert.equal(
    courseImageForCode('RICE-SEED-001'),
    'assets/images/courses/nyanya.jpg',
  );
  assert.equal(
    courseImageForCode('NYANYA-001'),
    'assets/images/courses/nyanya.jpg',
  );
});
