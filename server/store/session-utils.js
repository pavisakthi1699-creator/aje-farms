import crypto from 'node:crypto';

export const sessionTtlMs = 30 * 24 * 60 * 60 * 1000;

export function createSessionToken() {
  return crypto.randomBytes(32).toString('hex');
}

export function sessionExpiresAt(now = Date.now()) {
  return new Date(now + sessionTtlMs).toISOString();
}

export function isSessionExpired(expiresAt) {
  return Date.parse(expiresAt) <= Date.now();
}
