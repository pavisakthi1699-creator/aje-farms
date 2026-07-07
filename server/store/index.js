import { JsonStore } from './json-store.js';
import { PostgresStore } from './postgres-store.js';

export { normalizePhoneNumber } from './utils.js';

export async function createStore(catalog) {
  const mode = (process.env.AJE_STORE ?? 'json').toLowerCase();
  if (mode === 'postgres') {
    const databaseUrl = process.env.DATABASE_URL;
    if (!databaseUrl) {
      throw new Error('DATABASE_URL is required when AJE_STORE=postgres.');
    }
    return PostgresStore.create(databaseUrl, catalog);
  }

  return new JsonStore({ catalog });
}
