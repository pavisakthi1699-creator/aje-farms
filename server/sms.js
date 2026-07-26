import crypto from 'node:crypto';

export function createOtpCode() {
  return String(crypto.randomInt(100000, 1000000));
}

export function createOtpSender({
  env = process.env,
  fetchImpl = globalThis.fetch,
} = {}) {
  const provider = configuredSmsProvider(env);
  if (provider === 'africas_talking') {
    return new AfricasTalkingOtpSender({
      username: env.AFRICASTALKING_USERNAME,
      apiKey: env.AFRICASTALKING_API_KEY,
      senderId: env.AFRICASTALKING_SENDER_ID,
      environment: env.AFRICASTALKING_ENVIRONMENT,
      fetchImpl,
    });
  }

  return new DevelopmentOtpSender(env);
}

export function configuredSmsProvider(env = process.env) {
  const configured = String(env.AJE_SMS_PROVIDER ?? '').trim().toLowerCase();
  if (configured) return configured;
  if (env.AFRICASTALKING_USERNAME || env.AFRICASTALKING_API_KEY) {
    return 'africas_talking';
  }
  return 'development';
}

class AfricasTalkingOtpSender {
  constructor({
    username,
    apiKey,
    senderId,
    environment,
    fetchImpl,
  }) {
    this.name = 'africas_talking';
    this.username = String(username ?? '').trim();
    this.apiKey = String(apiKey ?? '').trim();
    this.senderId = String(senderId ?? '').trim();
    this.environment =
      String(environment ?? '').trim().toLowerCase() ||
      (this.username === 'sandbox' ? 'sandbox' : 'production');
    this.fetchImpl = fetchImpl;
    this.isProductionReady =
      this.username.length > 0 &&
      this.apiKey.length > 0 &&
      ['production', 'sandbox'].includes(this.environment);
  }

  async sendOtp({ phoneNumber, otp }) {
    if (!this.isProductionReady) {
      throw new Error("Africa's Talking SMS provider is not configured.");
    }

    const body = new URLSearchParams({
      username: this.username,
      to: phoneNumber,
      message: `AJE Farms OTP yako ni ${otp}. Itatumika kwa dakika 10.`,
      enqueue: '0',
    });
    if (this.senderId) {
      body.set('from', this.senderId);
    }

    const baseUrl =
      this.environment === 'sandbox'
        ? 'https://api.sandbox.africastalking.com'
        : 'https://api.africastalking.com';
    const response = await this.fetchImpl(`${baseUrl}/version1/messaging`, {
      method: 'POST',
      headers: {
        Accept: 'application/json',
        apiKey: this.apiKey,
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body,
      signal: AbortSignal.timeout(10_000),
    });
    if (!response.ok) {
      throw new Error(
        `Africa's Talking OTP delivery failed with HTTP ${response.status}.`,
      );
    }

    const payload = await response.json();
    const recipient = payload?.SMSMessageData?.Recipients?.[0];
    if (
      !recipient ||
      (Number(recipient.statusCode) !== 101 && recipient.status !== 'Success')
    ) {
      throw new Error(
        `Africa's Talking rejected the OTP recipient${
          recipient?.statusCode ? ` (status ${recipient.statusCode})` : ''
        }.`,
      );
    }

    return {
      provider: 'africas_talking',
      messageId: recipient.messageId,
    };
  }
}

class DevelopmentOtpSender {
  constructor(env) {
    this.name = 'development';
    this.env = env;
    this.debugOtpEnabled = env.AJE_ENABLE_DEBUG_OTP === 'true';
    this.isProductionReady = this.debugOtpEnabled;
  }

  async sendOtp({ phoneNumber, otp }) {
    if (this.env.NODE_ENV === 'production' && !this.debugOtpEnabled) {
      throw new Error('SMS provider is not configured.');
    }

    console.log(`[AJE OTP] ${phoneNumber}: ${otp}`);
    return {
      provider: 'development',
      debugOtp:
        this.env.NODE_ENV === 'development' ||
        this.debugOtpEnabled
          ? otp
          : undefined,
    };
  }
}
