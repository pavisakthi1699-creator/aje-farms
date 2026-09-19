import assert from 'node:assert/strict';
import test from 'node:test';

import { verifyReleasePolicyPages } from '../release-policy-pages.js';

const env = {
  AJE_PRIVACY_POLICY_URL: 'https://ajefarms.example/privacy',
  AJE_ACCOUNT_DELETION_URL: 'https://ajefarms.example/delete-account',
};

test('release policy pages must be reachable public HTML', async () => {
  const blockers = await verifyReleasePolicyPages(env, {
    fetchImpl: async (url) => {
      if (url.includes('privacy')) {
        return new Response('Not found', {
          status: 404,
          headers: { 'content-type': 'text/html' },
        });
      }
      return new Response('%PDF', {
        status: 200,
        headers: { 'content-type': 'application/pdf' },
      });
    },
  });

  assert.deepEqual(blockers, [
    'AJE_PRIVACY_POLICY_URL returned HTTP 404.',
    'AJE_ACCOUNT_DELETION_URL must serve a public HTML account deletion page.',
  ]);
});

test('release policy pages pass when substantive HTML is available', async () => {
  const blockers = await verifyReleasePolicyPages(env, {
    fetchImpl: async (url) =>
      new Response(`<html><body><h1>Chuo Kikuu Cha Mtaani</h1>${
        url.includes('privacy')
          ? 'Sera ya Faragha'
          : 'Omba kufuta akaunti'
      }${' Policy and request details. '.repeat(8)}</body></html>`, {
        status: 200,
        headers: { 'content-type': 'text/html; charset=utf-8' },
      }),
  });

  assert.deepEqual(blockers, []);
});

test('release policy verification rejects a generic HTML page', async () => {
  const blockers = await verifyReleasePolicyPages(env, {
    fetchImpl: async () =>
      new Response(`<html><body>${'Generic landing page. '.repeat(12)}</body></html>`, {
        status: 200,
        headers: { 'content-type': 'text/html; charset=utf-8' },
      }),
  });

  assert.deepEqual(blockers, [
    'AJE_PRIVACY_POLICY_URL does not contain the expected Chuo Kikuu Cha Mtaani privacy policy page.',
    'AJE_ACCOUNT_DELETION_URL does not contain the expected Chuo Kikuu Cha Mtaani account deletion page.',
  ]);
});
