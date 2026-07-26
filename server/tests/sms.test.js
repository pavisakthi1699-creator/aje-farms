import assert from 'node:assert/strict';
import test from 'node:test';

import {
  configuredSmsProvider,
  createOtpSender,
} from '../sms.js';

test("Africa's Talking sender delivers OTP through the production endpoint", async () => {
  let captured;
  const sender = createOtpSender({
    env: {
      NODE_ENV: 'production',
      AJE_SMS_PROVIDER: 'africas_talking',
      AFRICASTALKING_USERNAME: 'aje-farms',
      AFRICASTALKING_API_KEY: 'test-api-key',
      AFRICASTALKING_SENDER_ID: 'AJEFARMS',
      AFRICASTALKING_ENVIRONMENT: 'production',
    },
    fetchImpl: async (url, options) => {
      captured = { url, options };
      return {
        ok: true,
        status: 201,
        json: async () => ({
          SMSMessageData: {
            Recipients: [
              {
                statusCode: 101,
                status: 'Success',
                messageId: 'ATXid_test',
              },
            ],
          },
        }),
      };
    },
  });

  const result = await sender.sendOtp({
    phoneNumber: '+255712345678',
    otp: '123456',
  });

  assert.equal(sender.name, 'africas_talking');
  assert.equal(sender.isProductionReady, true);
  assert.equal(
    captured.url,
    'https://api.africastalking.com/version1/messaging',
  );
  assert.equal(captured.options.method, 'POST');
  assert.equal(captured.options.headers.apiKey, 'test-api-key');
  assert.equal(captured.options.body.get('username'), 'aje-farms');
  assert.equal(captured.options.body.get('to'), '+255712345678');
  assert.equal(captured.options.body.get('from'), 'AJEFARMS');
  assert.match(captured.options.body.get('message'), /123456/);
  assert.equal(result.provider, 'africas_talking');
  assert.equal(result.messageId, 'ATXid_test');
});

test("Africa's Talking sandbox uses the sandbox endpoint", async () => {
  let requestedUrl;
  const sender = createOtpSender({
    env: {
      NODE_ENV: 'development',
      AJE_SMS_PROVIDER: 'africas_talking',
      AFRICASTALKING_USERNAME: 'sandbox',
      AFRICASTALKING_API_KEY: 'sandbox-key',
      AFRICASTALKING_ENVIRONMENT: 'sandbox',
    },
    fetchImpl: async (url) => {
      requestedUrl = url;
      return {
        ok: true,
        status: 201,
        json: async () => ({
          SMSMessageData: {
            Recipients: [{ statusCode: 101, status: 'Success' }],
          },
        }),
      };
    },
  });

  await sender.sendOtp({
    phoneNumber: '+255712345678',
    otp: '123456',
  });

  assert.equal(
    requestedUrl,
    'https://api.sandbox.africastalking.com/version1/messaging',
  );
});
test("Africa's Talking recipient rejection fails OTP delivery", async () => {
  const sender = createOtpSender({
    env: {
      NODE_ENV: 'production',
      AJE_SMS_PROVIDER: 'africas_talking',
      AFRICASTALKING_USERNAME: 'aje-farms',
      AFRICASTALKING_API_KEY: 'test-api-key',
    },
    fetchImpl: async () => ({
      ok: true,
      status: 201,
      json: async () => ({
        SMSMessageData: {
          Recipients: [{ statusCode: 403, status: 'InvalidPhoneNumber' }],
        },
      }),
    }),
  });

  await assert.rejects(
    sender.sendOtp({
      phoneNumber: '+255712345678',
      otp: '123456',
    }),
    /rejected the OTP recipient/,
  );
});

test('SMS provider selection defaults safely to development', () => {
  assert.equal(configuredSmsProvider({}), 'development');
  assert.equal(
    configuredSmsProvider({
      AFRICASTALKING_USERNAME: 'aje-farms',
      AFRICASTALKING_API_KEY: 'key',
    }),
    'africas_talking',
  );
});
