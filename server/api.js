import { chatWithMwalimuServer } from './mwalimu.js';

const otpChallenges = new Map();
const paymentTransactions = new Map();
const localOtp = process.env.LOCAL_AUTH_OTP ?? '1234';

export function registerApiRoutes(app) {
  app.post('/api/auth/request-otp', (req, res) => {
    const { phoneNumber } = req.body;

    if (typeof phoneNumber !== 'string' || phoneNumber.trim().length < 9) {
      res.status(400).json({ error: 'Phone number is required.' });
      return;
    }

    const normalizedPhone = phoneNumber.trim();
    const challengeId = `otp-${Date.now()}-${Math.random()
      .toString(36)
      .slice(2)}`;
    otpChallenges.set(challengeId, {
      phoneNumber: normalizedPhone,
      otp: localOtp,
      expiresAt: Date.now() + 10 * 60 * 1000,
    });

    res.json({
      challengeId,
      message: `OTP imetumwa kwa ${normalizedPhone}.`,
      debugOtp: process.env.NODE_ENV === 'production' ? undefined : localOtp,
    });
  });

  app.post('/api/auth/verify-otp', (req, res) => {
    const { phoneNumber, otp, challengeId } = req.body;
    const challenge =
      typeof challengeId === 'string' ? otpChallenges.get(challengeId) : null;

    if (!challenge) {
      res.status(400).json({ error: 'OTP imeisha muda wake. Tuma tena.' });
      return;
    }
    if (challenge.expiresAt < Date.now()) {
      otpChallenges.delete(challengeId);
      res.status(400).json({ error: 'OTP imeisha muda wake. Tuma tena.' });
      return;
    }
    if (challenge.phoneNumber !== phoneNumber || challenge.otp !== otp) {
      res.status(401).json({ error: 'OTP si sahihi. Jaribu tena.' });
      return;
    }

    otpChallenges.delete(challengeId);
    res.json({ phoneNumber });
  });

  app.post('/api/payments/checkout', (req, res) => {
    const { planTitle, price, method, phoneNumber } = req.body;

    if (
      typeof planTitle !== 'string' ||
      typeof price !== 'string' ||
      typeof method !== 'string' ||
      typeof phoneNumber !== 'string' ||
      phoneNumber.trim().length < 9
    ) {
      res.status(400).json({ error: 'Payment details are required.' });
      return;
    }

    const id = `pay-${Date.now()}-${Math.random().toString(36).slice(2)}`;
    const transaction = {
      id,
      planTitle,
      price,
      method,
      phoneNumber: phoneNumber.trim(),
      status: 'paid',
      message: `Malipo yamethibitishwa kupitia ${method}.`,
      receiptNumber: `AJE-${id.slice(-6).toUpperCase()}`,
    };
    paymentTransactions.set(id, transaction);
    res.json(transaction);
  });

  app.get('/api/payments/:transactionId', (req, res) => {
    const transaction = paymentTransactions.get(req.params.transactionId);
    if (!transaction) {
      res.status(404).json({ error: 'Muamala haujapatikana.' });
      return;
    }
    res.json(transaction);
  });

  app.post('/api/mwalimu-chat', async (req, res) => {
    const { message, history } = req.body;

    if (typeof message !== 'string' || message.trim().length === 0) {
      res.status(400).json({ error: 'Message is required.' });
      return;
    }

    try {
      const text = await chatWithMwalimuServer(
        message,
        Array.isArray(history) ? history : [],
      );
      res.json({ text });
    } catch (error) {
      console.error('Mwalimu AI server error:', error);
      res.status(500).json({
        error:
          'Samahani, kuna tatizo la kimtandao. Tafadhali jaribu tena baadae au wasiliana na mtaalamu.',
      });
    }
  });
}
