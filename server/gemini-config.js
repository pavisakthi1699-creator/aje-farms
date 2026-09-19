const CANONICAL_GEMINI_API_ENV = 'GEMINI_API';
const LEGACY_GEMINI_API_ENV = 'GEMINI_API_KEY';

/**
 * Returns the configured Gemini credential without exposing it to callers.
 *
 * GEMINI_API is the supported deployment setting. GEMINI_API_KEY remains only
 * for backwards compatibility with existing local environments.
 */
export function configuredGeminiApiKey(env = process.env) {
  for (const variableName of [
    CANONICAL_GEMINI_API_ENV,
    LEGACY_GEMINI_API_ENV,
  ]) {
    const value = String(env[variableName] ?? '').trim();
    if (value) return value;
  }

  return null;
}

export function hasConfiguredGeminiApiKey(env = process.env) {
  return configuredGeminiApiKey(env) !== null;
}
