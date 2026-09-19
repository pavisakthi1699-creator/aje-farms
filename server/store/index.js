import { JsonStore } from './json-store.js';
import { PostgresStore } from './postgres-store.js';

export { normalizePhoneNumber } from './utils.js';

export async function createStore(catalog) {
  const config = resolveStoreConfig(process.env);
  if (config.mode === 'postgres' || config.mode === 'supabase') {
    const databaseUrl = config.databaseUrl;
    if (!databaseUrl) {
      throw new Error(
        `${config.databaseUrlEnvName} is required when AJE_STORE=${config.mode}.`,
      );
    }
    return PostgresStore.create(databaseUrl, catalog, {
      schema: config.schema,
    });
  }

  return new JsonStore({ catalog });
}

export function resolveStoreConfig(env = process.env) {
  const mode = (env.AJE_STORE ?? 'json').toLowerCase();
  if (mode === 'supabase') {
    return {
      mode,
      databaseUrl: env.SUPABASE_DATABASE_URL ?? env.DATABASE_URL,
      databaseUrlEnvName: env.SUPABASE_DATABASE_URL
        ? 'SUPABASE_DATABASE_URL'
        : 'DATABASE_URL',
      schema: env.AJE_DB_SCHEMA ?? 'public',
    };
  }
  if (mode === 'postgres') {
    return {
      mode,
      databaseUrl: env.DATABASE_URL,
      databaseUrlEnvName: 'DATABASE_URL',
      schema: env.AJE_DB_SCHEMA ?? 'public',
    };
  }
  return {
    mode,
    databaseUrl: null,
    databaseUrlEnvName: 'DATABASE_URL',
    schema: env.AJE_DB_SCHEMA ?? 'public',
  };
}
