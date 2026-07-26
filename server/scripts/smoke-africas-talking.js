import 'dotenv/config';

import { createOtpCode, createOtpSender } from '../sms.js';

const phoneNumber = process.argv[2]?.trim();

if (!phoneNumber || !/^\+[1-9]\d{7,14}$/.test(phoneNumber)) {
  console.error(
    'Usage: npm run smoke:sms -- +255700000000 (international E.164 format)',
  );
  process.exitCode = 1;
} else {
  const sender = createOtpSender();

  if (sender.name !== 'africas_talking' || !sender.isProductionReady) {
    console.error(
      "Africa's Talking is not configured. Set AFRICASTALKING_USERNAME, " +
        'AFRICASTALKING_API_KEY, and AFRICASTALKING_ENVIRONMENT in .env.',
    );
    process.exitCode = 1;
  } else {
    try {
      const result = await sender.sendOtp({
        phoneNumber,
        otp: createOtpCode(),
      });
      console.log(
        `SMS accepted by Africa's Talking for ${phoneNumber}` +
          `${result.messageId ? ` (message ${result.messageId})` : ''}.`,
      );
    } catch (error) {
      console.error(
        `SMS smoke failed: ${error instanceof Error ? error.message : error}`,
      );
      process.exitCode = 1;
    }
  }
}
