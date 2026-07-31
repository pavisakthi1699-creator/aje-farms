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

test('Android release keeps WhatsApp launch visibility and avoids a false-negative preflight', () => {
  const manifest = fs.readFileSync(
    path.join(rootDir, 'aje_farms_mobile/android/app/src/main/AndroidManifest.xml'),
    'utf8',
  );
  const launcher = fs.readFileSync(
    path.join(
      rootDir,
      'aje_farms_mobile/lib/src/features/expert_support/whatsapp_escalation_screen.dart',
    ),
    'utf8',
  );

  assert.match(manifest, /android:name="android\.intent\.action\.VIEW"/);
  assert.match(manifest, /android:scheme="https"/);
  assert.match(manifest, /android:name="com\.whatsapp"/);
  assert.match(manifest, /android:name="com\.whatsapp\.w4b"/);
  assert.match(launcher, /defaultValue: '255743812853'/);
  assert.doesNotMatch(launcher, /defaultValue: '255700000000'/);
  assert.doesNotMatch(launcher, /canLaunchUrl\(/);
  assert.match(launcher, /launchUrl\(uri, mode: LaunchMode\.externalApplication\)/);
});
