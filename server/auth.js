import { createClient } from '@supabase/supabase-js';

export const currentTermsVersion = '2026-08-11';

export function configuredAdminEmails() {
  return String(process.env.AJE_ADMIN_EMAILS ?? '')
    .split(',')
    .map((email) => email.trim().toLowerCase())
    .filter((email) => email.length > 0);
}

export function isAllowlistedAdminEmail(email) {
  const normalized = String(email ?? '').trim().toLowerCase();
  if (!normalized) return false;
  return configuredAdminEmails().includes(normalized);
}

export function userHasAdminAccess(user, email = user?.email) {
  return user?.role === 'admin' || isAllowlistedAdminEmail(email);
}

export function userWithEffectiveRole(user, email = user?.email) {
  if (!user) return user;
  return {
    ...user,
    role: userHasAdminAccess(user, email) ? 'admin' : user.role,
  };
}

let cachedSupabaseAdmin = null;

// Lazily created so tests and dev (which never call Supabase) don't require
// SUPABASE_URL/SUPABASE_SERVICE_ROLE_KEY to be set.
function supabaseAdminClient() {
  if (cachedSupabaseAdmin) return cachedSupabaseAdmin;
  const url = process.env.SUPABASE_URL;
  const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
  if (!url || !serviceRoleKey) {
    throw new Error(
      'SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY are required to verify Supabase Auth sessions.',
    );
  }
  cachedSupabaseAdmin = createClient(url, serviceRoleKey, {
    auth: { persistSession: false },
  });
  return cachedSupabaseAdmin;
}

export async function deleteSupabaseAuthUser(authUserId) {
  if (!authUserId) return;
  const { error } = await supabaseAdminClient().auth.admin.deleteUser(authUserId);
  if (error) throw error;
}

export function hasSupabaseAdminConfiguration() {
  return Boolean(
    process.env.SUPABASE_URL && process.env.SUPABASE_SERVICE_ROLE_KEY,
  );
}

function devModeEnabled() {
  return (
    ['development', 'test'].includes(process.env.NODE_ENV) &&
    process.env.AJE_ENABLE_DEBUG_OTP === 'true'
  );
}

// Identity is derived exclusively from a verified token, never from request
// body/params. Two token kinds are accepted:
//   1. A Supabase Auth access token, verified against Supabase's Auth server
//      (asks Supabase "whose token is this", so we never handle JWT signing
//      keys ourselves). This is the only path in production.
//   2. In development only, a session token minted by the dev-only endpoint
//      in api.js, looked up in the store's own auth_sessions table. This lets
//      local dev and `npm run test:server` authenticate without a real
//      Supabase project configured.
export function requireAuthSession(store) {
  return async (req, res, next) => {
    const header = req.headers.authorization;
    if (typeof header !== 'string' || !header.startsWith('Bearer ')) {
      res.status(401).json({ error: 'Ingia tena ili kuendelea.' });
      return;
    }
    const token = header.slice('Bearer '.length);

    if (devModeEnabled()) {
      const devSession = await store.getAuthSession(token);
      if (devSession) {
        req.userId = devSession.userId;
        next();
        return;
      }
      if (!hasSupabaseAdminConfiguration()) {
        res.status(401).json({ error: 'Kikao kimeisha. Ingia tena.' });
        return;
      }
    }

    try {
      const supabase = supabaseAdminClient();
      const { data, error } = await supabase.auth.getUser(token);
      if (error) {
        const status = authVerificationFailureStatus(error);
        res.status(status).json({
          error: status === 401
            ? 'Kikao kimeisha. Ingia tena.'
            : 'Huduma ya kuingia haipatikani kwa sasa. Jaribu tena.',
        });
        return;
      }
      if (!data?.user) {
        res.status(401).json({ error: 'Kikao kimeisha. Ingia tena.' });
        return;
      }
      const user = await store.linkOrCreateUserForAuth({
        authUserId: data.user.id,
        email: data.user.email,
        termsAcceptedVersion:
          data.user.user_metadata?.terms_accepted_version ?? null,
        termsAcceptedAt: data.user.user_metadata?.terms_accepted_at ?? null,
      });
      const reconciledUser = await store.reconcileUserEntitlements(user.id);
      req.userId = reconciledUser.id;
      req.authUserId = data.user.id;
      next();
    } catch (error) {
      console.error('Failed to verify auth session:', error);
      res.status(503).json({
        error: 'Huduma ya kuingia haipatikani kwa sasa. Jaribu tena.',
      });
    }
  };
}

export function authVerificationFailureStatus(error) {
  const status = Number(error?.status ?? error?.statusCode);
  return status === 401 || status === 403 ? 401 : 503;
}

export function requireCommunityTerms(store) {
  return async (req, res, next) => {
    const user = await store.getUser(req.userId);
    if (user?.termsAcceptedVersion !== currentTermsVersion) {
      res.status(403).json({
        error: 'Kubali Masharti na Mwongozo wa Jamii ili kuendelea.',
        code: 'COMMUNITY_TERMS_REQUIRED',
        termsVersion: currentTermsVersion,
      });
      return;
    }
    next();
  };
}

export function requireAdminSession(store) {
  return async (req, res, next) => {
    const user = await store.getUser(req.userId);
    const isAdmin = userHasAdminAccess(user, user?.email);
    if (!isAdmin) {
      res.status(403).json({ error: 'Admin access is required.' });
      return;
    }
    next();
  };
}
