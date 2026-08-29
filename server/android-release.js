import { spawnSync } from 'node:child_process';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';

export const ANDROID_APPLICATION_ID = 'com.ajefarms.mobile';
export const ANDROID_APPLICATION_LABEL = 'Chuo Kikuu Cha Mtaani';
export const ANDROID_LAUNCH_ACTIVITY =
  'com.ajefarms.mobile.MainActivity';
export const PRODUCTION_API_BASE_URL =
  'https://aje-farms-api-production.up.railway.app';

export function releaseDartDefines(env) {
  const requiredValues = [
    'AJE_ANDROID_API_BASE_URL',
    'AJE_WHATSAPP_EXPERT_PHONE',
    'SUPABASE_URL',
    'SUPABASE_PUBLISHABLE_KEY',
    'AJE_PRIVACY_POLICY_URL',
    'AJE_ACCOUNT_DELETION_URL',
    'AJE_PLAY_DISTRIBUTION_MODE',
  ];
  for (const name of requiredValues) {
    requireReleaseValue(name, env[name]);
  }

  return [
    `--dart-define=AJE_API_BASE_URL=${env.AJE_ANDROID_API_BASE_URL}`,
    `--dart-define=AJE_WHATSAPP_EXPERT_PHONE=${env.AJE_WHATSAPP_EXPERT_PHONE}`,
    `--dart-define=SUPABASE_URL=${env.SUPABASE_URL}`,
    `--dart-define=SUPABASE_PUBLISHABLE_KEY=${env.SUPABASE_PUBLISHABLE_KEY}`,
    `--dart-define=AJE_PRIVACY_POLICY_URL=${env.AJE_PRIVACY_POLICY_URL}`,
    `--dart-define=AJE_ACCOUNT_DELETION_URL=${env.AJE_ACCOUNT_DELETION_URL}`,
    `--dart-define=AJE_PLAY_CONSUMPTION_ONLY=${env.AJE_PLAY_DISTRIBUTION_MODE === 'consumption_only'}`,
  ];
}

function requireReleaseValue(name, value) {
  const normalized = String(value ?? '').trim();
  if (!normalized || normalized === 'undefined' || normalized === 'null') {
    throw new Error(`${name} is required for Android release builds.`);
  }
}

export function internalTestingDartDefines(env) {
  if (env.AJE_ANDROID_API_BASE_URL !== PRODUCTION_API_BASE_URL) {
    throw new Error(
      `Internal testing APK must use the production API: ${PRODUCTION_API_BASE_URL}`,
    );
  }
  return [
    ...releaseDartDefines(env),
    '--dart-define=AJE_INTERNAL_BUILD=true',
  ];
}

export function validateAndroidArtifactMetadata({ entries, badging }) {
  const errors = [];
  const entrySet = new Set(entries);

  if (
    !badging.includes(`package: name='${ANDROID_APPLICATION_ID}'`)
  ) {
    errors.push(
      `Expected package ${ANDROID_APPLICATION_ID}; this is not the Chuo Kikuu Cha Mtaani Flutter application.`,
    );
  }
  if (
    !badging.includes(
      `application-label:'${ANDROID_APPLICATION_LABEL}'`,
    )
  ) {
    errors.push(
      `Expected application label ${ANDROID_APPLICATION_LABEL}.`,
    );
  }
  if (
    !badging.includes(
      `launchable-activity: name='${ANDROID_LAUNCH_ACTIVITY}'`,
    )
  ) {
    errors.push(
      `Expected Flutter launch activity ${ANDROID_LAUNCH_ACTIVITY}.`,
    );
  }
  if (!entries.some((entry) => /^lib\/[^/]+\/libapp\.so$/.test(entry))) {
    errors.push('Flutter release library is missing (libapp.so).');
  }
  if (
    !entries.some((entry) => /^lib\/[^/]+\/libflutter\.so$/.test(entry))
  ) {
    errors.push('Flutter engine library is missing (libflutter.so).');
  }
  if (!entrySet.has('assets/flutter_assets/AssetManifest.bin')) {
    errors.push('Flutter asset manifest is missing.');
  }

  const launcherIcon = extractBadgingValue(
    badging,
    /application:\s+label='[^']*'\s+icon='([^']+)'/,
  );
  if (!launcherIcon || !entrySet.has(launcherIcon)) {
    errors.push('Packaged Android launcher icon is missing.');
  }

  const wrapperAsset = entries.find(
    (entry) =>
      entry === 'assets/appConfig.json' ||
      entry.endsWith('/GoNativeJSBridgeLibrary.js'),
  );
  if (wrapperAsset) {
    errors.push(`WebView wrapper asset detected: ${wrapperAsset}.`);
  }

  return { ok: errors.length === 0, errors };
}

export function validateAndroidApk(
  apkPath,
  {
    aaptBin,
    spawnSyncImpl = spawnSync,
    existsSync = fs.existsSync,
    readdirSync = fs.readdirSync,
    env = process.env,
  } = {},
) {
  if (!existsSync(apkPath)) {
    throw new Error(`Android APK not found: ${apkPath}`);
  }

  const resolvedAapt =
    aaptBin ??
    resolveAaptBin({
      env,
      existsSync,
      readdirSync,
    });
  const entriesOutput = runCommand(
    'unzip',
    ['-Z1', apkPath],
    spawnSyncImpl,
  );
  const badging = runCommand(
    resolvedAapt,
    ['dump', 'badging', apkPath],
    spawnSyncImpl,
  );
  const entries = entriesOutput
    .split(/\r?\n/)
    .map((entry) => entry.trim())
    .filter(Boolean);
  const result = validateAndroidArtifactMetadata({ entries, badging });

  return {
    ...result,
    apkPath,
    packageName: extractBadgingValue(badging, /package: name='([^']+)'/),
    applicationLabel: extractBadgingValue(
      badging,
      /application-label:'([^']+)'/,
    ),
    launcherIcon: extractBadgingValue(
      badging,
      /application:\s+label='[^']*'\s+icon='([^']+)'/,
    ),
    launchActivity: extractBadgingValue(
      badging,
      /launchable-activity: name='([^']+)'/,
    ),
  };
}

export function resolveAaptBin({
  env = process.env,
  existsSync = fs.existsSync,
  readdirSync = fs.readdirSync,
} = {}) {
  if (env.AAPT_BIN && existsSync(env.AAPT_BIN)) {
    return env.AAPT_BIN;
  }

  const executable = process.platform === 'win32' ? 'aapt.exe' : 'aapt';
  const sdkRoots = [
    env.ANDROID_HOME,
    env.ANDROID_SDK_ROOT,
    path.join(os.homedir(), 'Library', 'Android', 'sdk'),
    path.join(os.homedir(), 'Android', 'Sdk'),
  ].filter(Boolean);

  for (const sdkRoot of sdkRoots) {
    const buildToolsRoot = path.join(sdkRoot, 'build-tools');
    if (!existsSync(buildToolsRoot)) continue;
    const versions = readdirSync(buildToolsRoot).sort((left, right) =>
      right.localeCompare(left, undefined, { numeric: true }),
    );
    for (const version of versions) {
      const candidate = path.join(buildToolsRoot, version, executable);
      if (existsSync(candidate)) return candidate;
    }
  }

  throw new Error(
    'Android aapt was not found. Set AAPT_BIN, ANDROID_HOME, or ANDROID_SDK_ROOT.',
  );
}

function runCommand(command, args, spawnSyncImpl) {
  const result = spawnSyncImpl(command, args, {
    encoding: 'utf8',
    maxBuffer: 20 * 1024 * 1024,
  });
  if (result.error) throw result.error;
  if (result.status !== 0) {
    const detail = String(result.stderr ?? '').trim();
    throw new Error(
      `${command} failed with exit code ${result.status}${detail ? `: ${detail}` : ''}`,
    );
  }
  return String(result.stdout ?? '');
}

function extractBadgingValue(badging, pattern) {
  return pattern.exec(badging)?.[1] ?? null;
}
