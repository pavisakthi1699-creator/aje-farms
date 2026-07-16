import assert from 'node:assert/strict';
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

test('crop and livestock course image mappings remain unchanged', () => {
  assert.equal(
    courseImageForCode('RICE-SEED-001'),
    'assets/images/courses/mpunga.jpg',
  );
  assert.equal(
    courseImageForCode('CRS-KUK-02'),
    'assets/images/courses/kuku.jpg',
  );
  assert.equal(
    courseImageForCode('NYANYA-001'),
    'assets/images/courses/nyanya.jpg',
  );
});
