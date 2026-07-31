import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import test from 'node:test';
import { fileURLToPath } from 'node:url';

const rootDir = path.resolve(
  path.dirname(fileURLToPath(import.meta.url)),
  '..',
  '..',
);

test('production deployment exposes the API only, not the retired React prototype', () => {
  assert.equal(fs.existsSync(path.join(rootDir, 'index.html')), false);

  const manifest = JSON.parse(
    fs.readFileSync(path.join(rootDir, 'package.json'), 'utf8'),
  );
  for (const dependency of [
    'react',
    'react-dom',
    'react-router-dom',
    'vite',
  ]) {
    assert.equal(manifest.dependencies?.[dependency], undefined);
    assert.equal(manifest.devDependencies?.[dependency], undefined);
  }

  const entry = fs.readFileSync(path.join(rootDir, 'server', 'index.js'), 'utf8');
  assert.doesNotMatch(entry, /express\.static|sendFile|distPath/);

  const railway = JSON.parse(
    fs.readFileSync(path.join(rootDir, 'railway.json'), 'utf8'),
  );
  assert.equal(railway.build?.buildCommand, undefined);
  assert.equal(railway.deploy.healthcheckPath, '/api/health/live');
});
