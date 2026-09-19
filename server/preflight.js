import { configuredGeminiApiKey } from './gemini-config.js';

const placeholderValues = new Set([
  '',
  'MY_APP_URL',
  'MY_GEMINI_API_KEY',
  'replace-with-secret',
]);

export function releasePreflight(env = process.env, fileExists = () => false) {
  const blockers = [];
  const warnings = [];

  requireValue(blockers, 'NODE_ENV', env.NODE_ENV, (value) => {
    return value === 'production' ? null : 'must be "production" for release.';
  });
  requireValue(blockers, 'APP_URL', env.APP_URL, (value) => {
    return placeholderValues.has(value)
      ? 'must be set to the deployed backend URL.'
      : null;
  });
  validateHttpsUrl(blockers, 'APP_URL', env.APP_URL);
  validateProductionHostname(blockers, 'APP_URL', env.APP_URL);

  const storeMode = (env.AJE_STORE ?? 'json').toLowerCase();
  if (storeMode !== 'postgres' && storeMode !== 'supabase') {
    blockers.push('AJE_STORE must be "postgres" or "supabase" for release.');
  }
  const databaseUrlName = storeMode === 'supabase' ? 'SUPABASE_DATABASE_URL' : 'DATABASE_URL';
  requireValue(blockers, databaseUrlName, env[databaseUrlName] ?? env.DATABASE_URL);
  // Required regardless of store mode: authenticated requests are verified
  // against Supabase Auth (requireAuthSession in auth.js) independent of
  // which backend holds application data.
  requireValue(blockers, 'SUPABASE_URL', env.SUPABASE_URL);
  validateHttpsUrl(blockers, 'SUPABASE_URL', env.SUPABASE_URL);
  validateProductionHostname(blockers, 'SUPABASE_URL', env.SUPABASE_URL);
  requireValue(
    blockers,
    'SUPABASE_SERVICE_ROLE_KEY',
    env.SUPABASE_SERVICE_ROLE_KEY,
  );
  requireValue(
    blockers,
    'SUPABASE_PUBLISHABLE_KEY',
    env.SUPABASE_PUBLISHABLE_KEY,
    (value) => validateSupabasePublishableKey(
      value,
      env.SUPABASE_SERVICE_ROLE_KEY,
    ),
  );
  requireValue(blockers, 'AJE_PRIVACY_POLICY_URL', env.AJE_PRIVACY_POLICY_URL);
  validateHttpsUrl(
    blockers,
    'AJE_PRIVACY_POLICY_URL',
    env.AJE_PRIVACY_POLICY_URL,
  );
  validateProductionHostname(
    blockers,
    'AJE_PRIVACY_POLICY_URL',
    env.AJE_PRIVACY_POLICY_URL,
  );
  requireValue(
    blockers,
    'AJE_ACCOUNT_DELETION_URL',
    env.AJE_ACCOUNT_DELETION_URL,
  );
  requireValue(
    blockers,
    'AJE_PRIVACY_CONTACT_EMAIL',
    env.AJE_PRIVACY_CONTACT_EMAIL,
    (value) => /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value)
      ? null
      : 'must be a valid monitored email address.',
  );
  requireValue(
    blockers,
    'AJE_ANDROID_APP_SIGNING_SHA256',
    env.AJE_ANDROID_APP_SIGNING_SHA256,
    (value) => {
      const fingerprints = value.split(',').map((item) => item.trim());
      return fingerprints.every((item) =>
        /^([0-9A-Fa-f]{2}:){31}[0-9A-Fa-f]{2}$/.test(item),
      )
        ? null
        : 'must contain comma-separated SHA-256 certificate fingerprints.';
    },
  );
  validateHttpsUrl(
    blockers,
    'AJE_ACCOUNT_DELETION_URL',
    env.AJE_ACCOUNT_DELETION_URL,
  );
  validateProductionHostname(
    blockers,
    'AJE_ACCOUNT_DELETION_URL',
    env.AJE_ACCOUNT_DELETION_URL,
  );
  requireValue(
    blockers,
    'AJE_PLAY_DISTRIBUTION_MODE',
    env.AJE_PLAY_DISTRIBUTION_MODE,
    (value) =>
      value === 'consumption_only'
        ? null
        : 'must be "consumption_only" for this release.',
  );
  // Gates the dev-only /api/auth/dev-session bypass in api.js — must never
  // be reachable in a release build.
  if (env.AJE_ENABLE_DEBUG_OTP === 'true') {
    blockers.push('AJE_ENABLE_DEBUG_OTP must not be true for release.');
  }
  if (env.AJE_ENABLE_LEGACY_DEV_PAYMENTS === 'true') {
    blockers.push(
      'AJE_ENABLE_LEGACY_DEV_PAYMENTS must not be true for release.',
    );
  }
  if (String(env.AJE_INTERNAL_BUILD ?? '').toLowerCase() === 'true') {
    blockers.push('AJE_INTERNAL_BUILD must not be true for release.');
  }

  requireValue(blockers, 'AJE_ANDROID_API_BASE_URL', env.AJE_ANDROID_API_BASE_URL, (value) => {
    if (!value.startsWith('https://')) {
      return 'must be an HTTPS production API URL.';
    }
    if (value.includes('localhost') || value.includes('10.0.2.2')) {
      return 'must not point at a local development host.';
    }
    return null;
  });
  validateProductionHostname(
    blockers,
    'AJE_ANDROID_API_BASE_URL',
    env.AJE_ANDROID_API_BASE_URL,
  );
  requireValue(
    blockers,
    'AJE_WHATSAPP_EXPERT_PHONE',
    env.AJE_WHATSAPP_EXPERT_PHONE,
    (value) => (/^\d{9,15}$/.test(value) ? null : 'must be digits only.'),
  );
  if (!fileExists('aje_farms_mobile/android/key.properties')) {
    blockers.push(
      'aje_farms_mobile/android/key.properties is required to sign release builds.',
    );
  }

  if (!String(env.AJE_ADMIN_EMAILS ?? '').trim()) {
    warnings.push('AJE_ADMIN_EMAILS is not set; admin access must be managed through stored user roles.');
  }
  const pushProvider = String(env.AJE_PUSH_PROVIDER ?? 'development').toLowerCase();
  if (pushProvider === 'development') {
    warnings.push('Push notifications use the development provider; configure a real provider before public launch.');
  } else if (pushProvider === 'fcm') {
    if (!hasFcmServiceAccount(env)) {
      blockers.push(
        'FCM push provider requires FCM_SERVICE_ACCOUNT_JSON or FCM_PROJECT_ID, FCM_CLIENT_EMAIL, and FCM_PRIVATE_KEY.',
      );
    }
  } else {
    blockers.push('AJE_PUSH_PROVIDER must be "development" or "fcm".');
  }
  const geminiApiKey = configuredGeminiApiKey(env);
  if (!geminiApiKey || placeholderValues.has(geminiApiKey)) {
    warnings.push('GEMINI_API is missing; AI will use the approved knowledge-base fallback.');
  }

  return {
    ok: blockers.length === 0,
    blockers,
    warnings,
  };
}

function validateSupabasePublishableKey(value, serviceRoleKey) {
  if (value === String(serviceRoleKey ?? '').trim()) {
    return 'must not equal SUPABASE_SERVICE_ROLE_KEY.';
  }
  if (value.startsWith('sb_secret_')) {
    return 'must be a client-safe publishable key, not an sb_secret_ key.';
  }
  const parts = value.split('.');
  if (parts.length === 3) {
    try {
      const payload = JSON.parse(
        Buffer.from(parts[1], 'base64url').toString('utf8'),
      );
      if (payload?.role === 'service_role') {
        return 'must not contain a service_role JWT.';
      }
    } catch {
      // Key format validation belongs to Supabase; only block known secrets.
    }
  }
  return null;
}

function requireValue(blockers, name, value, validate) {
  const normalized = String(value ?? '').trim();
  if (!normalized || placeholderValues.has(normalized)) {
    blockers.push(`${name} is required for release.`);
    return;
  }
  const validationMessage = validate?.(normalized);
  if (validationMessage) {
    blockers.push(`${name} ${validationMessage}`);
  }
}

function validateHttpsUrl(blockers, name, value) {
  const normalized = String(value ?? '').trim();
  if (!normalized || placeholderValues.has(normalized)) return;
  try {
    const parsed = new URL(normalized);
    if (parsed.protocol !== 'https:') {
      blockers.push(`${name} must use HTTPS for release.`);
    }
  } catch {
    blockers.push(`${name} must be a valid URL.`);
  }
}

function validateProductionHostname(blockers, name, value) {
  const normalized = String(value ?? '').trim();
  if (!normalized || placeholderValues.has(normalized)) return;
  try {
    const { hostname } = new URL(normalized);
    const reserved =
      hostname === 'localhost' ||
      hostname === 'example.com' ||
      hostname.endsWith('.example.com') ||
      hostname.endsWith('.example') ||
      hostname.endsWith('.invalid') ||
      hostname.endsWith('.localhost') ||
      hostname.endsWith('.test');
    if (reserved) {
      blockers.push(
        `${name} must not use a placeholder or reserved hostname.`,
      );
    }
  } catch {
    // URL syntax is reported by validateHttpsUrl or the field validator.
  }
}

function hasAll(env, names) {
  return names.every((name) => String(env[name] ?? '').trim().length > 0);
}

function hasFcmServiceAccount(env) {
  const serviceAccountJson = String(env.FCM_SERVICE_ACCOUNT_JSON ?? '').trim();
  if (serviceAccountJson) {
    try {
      const parsed = JSON.parse(serviceAccountJson);
      return Boolean(parsed.project_id && parsed.client_email && parsed.private_key);
    } catch {
      return false;
    }
  }
  return hasAll(env, ['FCM_PROJECT_ID', 'FCM_CLIENT_EMAIL', 'FCM_PRIVATE_KEY']);
}
