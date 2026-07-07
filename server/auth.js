import { normalizePhoneNumber } from './store.js';

export function requireAuthSession(store) {
  return async (req, res, next) => {
    const header = req.headers.authorization;
    if (typeof header !== 'string' || !header.startsWith('Bearer ')) {
      res.status(401).json({ error: 'Ingia tena ili kuendelea.' });
      return;
    }

    const session = await store.getAuthSession(header.slice('Bearer '.length));
    if (!session) {
      res.status(401).json({ error: 'Kikao kimeisha. Ingia tena.' });
      return;
    }

    req.authPhoneNumber = session.phoneNumber;
    next();
  };
}

export function requireAuthPhoneMatch(paramName = 'phoneNumber') {
  return (req, res, next) => {
    const requested = normalizePhoneNumber(req.params[paramName] ?? '');
    if (requested !== req.authPhoneNumber) {
      res.status(403).json({ error: 'Huna ruhusa kwa akaunti hii.' });
      return;
    }
    next();
  };
}

export function requireAdminSession(store) {
  return async (req, res, next) => {
    const user = await store.getUser(req.authPhoneNumber);
    const adminPhones = String(process.env.AJE_ADMIN_PHONE_NUMBERS ?? '')
      .split(',')
      .map((phoneNumber) => normalizePhoneNumber(phoneNumber))
      .filter((phoneNumber) => phoneNumber.length > 1);
    const isAdmin =
      user?.role === 'admin' || adminPhones.includes(req.authPhoneNumber);
    if (!isAdmin) {
      res.status(403).json({ error: 'Admin access is required.' });
      return;
    }
    next();
  };
}
