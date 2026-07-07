import crypto from 'node:crypto';

export function createOtpCode() {
  return String(crypto.randomInt(100000, 1000000));
}

export function createOtpSender() {
  if (
    process.env.TWILIO_ACCOUNT_SID &&
    process.env.TWILIO_AUTH_TOKEN &&
    process.env.TWILIO_FROM_NUMBER
  ) {
    return new TwilioOtpSender({
      accountSid: process.env.TWILIO_ACCOUNT_SID,
      authToken: process.env.TWILIO_AUTH_TOKEN,
      fromNumber: process.env.TWILIO_FROM_NUMBER,
    });
  }

  return new DevelopmentOtpSender();
}

class TwilioOtpSender {
  constructor({ accountSid, authToken, fromNumber }) {
    this.accountSid = accountSid;
    this.authToken = authToken;
    this.fromNumber = fromNumber;
  }

  async sendOtp({ phoneNumber, otp }) {
    const params = new URLSearchParams({
      From: this.fromNumber,
      To: phoneNumber,
      Body: `AJE Farms OTP yako ni ${otp}. Itatumika kwa dakika 10.`,
    });
    const response = await fetch(
      `https://api.twilio.com/2010-04-01/Accounts/${this.accountSid}/Messages.json`,
      {
        method: 'POST',
        headers: {
          Authorization: `Basic ${Buffer.from(
            `${this.accountSid}:${this.authToken}`,
          ).toString('base64')}`,
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: params,
      },
    );

    if (!response.ok) {
      const text = await response.text();
      throw new Error(`Twilio OTP delivery failed: ${text}`);
    }

    return { provider: 'twilio' };
  }
}

class DevelopmentOtpSender {
  async sendOtp({ phoneNumber, otp }) {
    if (process.env.NODE_ENV === 'production') {
      throw new Error('SMS provider is not configured.');
    }

    console.log(`[AJE OTP] ${phoneNumber}: ${otp}`);
    return {
      provider: 'development',
      debugOtp:
        process.env.NODE_ENV === 'development' ||
        process.env.AJE_ENABLE_DEBUG_OTP === 'true'
          ? otp
          : undefined,
    };
  }
}
