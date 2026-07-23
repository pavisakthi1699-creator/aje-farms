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
  if (storeMode === 'supabase') {
    requireValue(blockers, 'SUPABASE_URL', env.SUPABASE_URL);
    validateHttpsUrl(blockers, 'SUPABASE_URL', env.SUPABASE_URL);
    validateProductionHostname(blockers, 'SUPABASE_URL', env.SUPABASE_URL);
    requireValue(
      blockers,
      'SUPABASE_SERVICE_ROLE_KEY',
      env.SUPABASE_SERVICE_ROLE_KEY,
    );
  }
  requireValue(blockers, 'AJE_OTP_PEPPER', env.AJE_OTP_PEPPER, (value) => {
    return value.length < 32
      ? 'must be at least 32 characters for release.'
      : null;
  });
  if (env.AJE_ENABLE_DEBUG_OTP === 'true') {
    blockers.push('AJE_ENABLE_DEBUG_OTP must not be true for release.');
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

  if (!hasAll(env, ['TWILIO_ACCOUNT_SID', 'TWILIO_AUTH_TOKEN', 'TWILIO_FROM_NUMBER'])) {
    warnings.push('SMS OTP provider is not fully configured; development OTP sender cannot be used in production.');
  }
  if (!String(env.AJE_ADMIN_PHONE_NUMBERS ?? '').trim()) {
    warnings.push('AJE_ADMIN_PHONE_NUMBERS is not set; moderation admin access must be managed through stored user roles.');
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
  if (!env.GEMINI_API_KEY || placeholderValues.has(env.GEMINI_API_KEY)) {
    warnings.push('GEMINI_API_KEY is missing; AI will use the approved knowledge-base fallback.');
  }
  warnings.push('Payment provider is still the development adapter; keep real provider integration as the final payment slice.');

  return {
    ok: blockers.length === 0,
    blockers,
    warnings,
  };
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
