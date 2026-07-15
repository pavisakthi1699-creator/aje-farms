import crypto from 'node:crypto';
import fs from 'node:fs';
import path from 'node:path';
import { spawnSync } from 'node:child_process';

const rootDir = process.cwd();
const androidDir = path.join(rootDir, 'aje_farms_mobile', 'android');
const keysDir = path.join(androidDir, 'keys');
const keystorePath = path.join(keysDir, 'aje-farms-upload.jks');
const propertiesPath = path.join(androidDir, 'key.properties');
const lockPath = path.join(androidDir, '.aje-upload-key-generation.lock');

if (fs.existsSync(keystorePath) || fs.existsSync(propertiesPath)) {
  console.error(
    'Android signing files already exist. Refusing to replace the upload key.',
  );
  process.exit(1);
}

fs.mkdirSync(keysDir, { recursive: true, mode: 0o700 });

let lockHandle;
let temporaryDir;
let installedKeystore = false;

function acquireGenerationLock() {
  for (let attempt = 0; attempt < 3; attempt += 1) {
    try {
      const handle = fs.openSync(lockPath, 'wx', 0o600);
      fs.writeFileSync(handle, `${process.pid}\n`);
      return handle;
    } catch (error) {
      if (!(error instanceof Error) || error.code !== 'EEXIST') throw error;

      let ownerIsRunning = false;
      try {
        const ownerPid = Number.parseInt(fs.readFileSync(lockPath, 'utf8'), 10);
        if (Number.isSafeInteger(ownerPid) && ownerPid > 0) {
          process.kill(ownerPid, 0);
          ownerIsRunning = true;
        } else {
          const lockAgeMs = Date.now() - fs.statSync(lockPath).mtimeMs;
          ownerIsRunning = lockAgeMs < 10 * 60 * 1000;
        }
      } catch (lockError) {
        if (lockError instanceof Error && lockError.code === 'EPERM') {
          ownerIsRunning = true;
        } else if (
          !(lockError instanceof Error) ||
          !['ENOENT', 'ESRCH'].includes(lockError.code)
        ) {
          throw lockError;
        }
      }

      if (ownerIsRunning) {
        throw new Error('Android upload-key generation is already running.');
      }
      fs.rmSync(lockPath, { force: true });
    }
  }
  throw new Error('Unable to acquire the Android upload-key generation lock.');
}

try {
  lockHandle = acquireGenerationLock();

  // Check again while holding the lock so concurrent invocations cannot both
  // proceed after the initial user-friendly guard above.
  if (fs.existsSync(keystorePath) || fs.existsSync(propertiesPath)) {
    throw new Error(
      'Android signing files already exist. Refusing to replace the upload key.',
    );
  }

  temporaryDir = fs.mkdtempSync(path.join(androidDir, '.aje-upload-key-'));
  const temporaryKeystorePath = path.join(temporaryDir, 'upload.jks');
  const temporaryPropertiesPath = path.join(temporaryDir, 'key.properties');
  const password = crypto.randomBytes(32).toString('base64url');
  const passwordEnvironmentName = 'AJE_ANDROID_UPLOAD_KEY_PASSWORD';
  const keytool = process.env.KEYTOOL_BIN ?? 'keytool';
  const result = spawnSync(
    keytool,
    [
      '-genkeypair',
      '-v',
      '-keystore',
      temporaryKeystorePath,
      '-storepass:env',
      passwordEnvironmentName,
      '-keypass:env',
      passwordEnvironmentName,
      '-alias',
      'aje-farms-upload',
      '-keyalg',
      'RSA',
      '-keysize',
      '2048',
      '-validity',
      '10000',
      '-dname',
      'CN=AJE Farms, OU=Mobile, O=AJE Farms, L=Kigali, ST=Kigali, C=RW',
    ],
    {
      env: {
        ...process.env,
        [passwordEnvironmentName]: password,
      },
      stdio: ['ignore', 'inherit', 'inherit'],
    },
  );

  if (result.status !== 0) {
    process.exitCode = result.status ?? 1;
    throw new Error('keytool did not generate the Android upload key.');
  }

  const properties = [
    'storeFile=../keys/aje-farms-upload.jks',
    `storePassword=${password}`,
    'keyAlias=aje-farms-upload',
    `keyPassword=${password}`,
    '',
  ].join('\n');

  fs.writeFileSync(temporaryPropertiesPath, properties, { mode: 0o600 });
  fs.chmodSync(temporaryKeystorePath, 0o600);
  fs.renameSync(temporaryKeystorePath, keystorePath);
  installedKeystore = true;
  fs.renameSync(temporaryPropertiesPath, propertiesPath);
} catch (error) {
  if (installedKeystore && !fs.existsSync(propertiesPath)) {
    fs.rmSync(keystorePath, { force: true });
  }
  console.error(error instanceof Error ? error.message : error);
  process.exitCode = process.exitCode || 1;
} finally {
  if (lockHandle !== undefined) {
    fs.closeSync(lockHandle);
    fs.rmSync(lockPath, { force: true });
  }
  if (temporaryDir) fs.rmSync(temporaryDir, { recursive: true, force: true });
}

if (process.exitCode) process.exit(process.exitCode);

console.log('Generated Android upload signing files:');
console.log('- aje_farms_mobile/android/keys/aje-farms-upload.jks');
console.log('- aje_farms_mobile/android/key.properties');
console.log('The password was saved only in the ignored key.properties file.');
console.log('Back up both files securely before uploading the first Play build.');
