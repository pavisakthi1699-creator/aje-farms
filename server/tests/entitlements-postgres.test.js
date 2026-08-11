import assert from 'node:assert/strict';

import test from 'node:test';

import { catalog } from '../catalog.js';
import { PostgresStore } from '../store/postgres-store.js';

const databaseUrl = process.env.SUPABASE_DATABASE_URL ?? process.env.DATABASE_URL;

async function withPostgresStore(run) {
  const store = await PostgresStore.create(databaseUrl, catalog, { schema: 'public' });
  try {
    await store.resetForTests();
    await run(store);
  } finally {
    await store.close();
  }
}

async function seedUsers(store) {
  const admin = await store.linkOrCreateUserForAuth({
    authUserId: 'dev-admin',
    email: 'admin@aje.test',
  });
  const learner = await store.linkOrCreateUserForAuth({
    authUserId: 'dev-learner',
    email: 'learner@aje.test',
  });
  return { admin, learner };
}

test(
  'postgres: approving a payment is transactional and idempotent under a real transaction',
  { skip: databaseUrl ? false : 'DATABASE_URL is not set' },
  async () => {
    await withPostgresStore(async (store) => {
      const { admin, learner } = await seedUsers(store);

      const record = await store.recordPaymentRecord({
        userId: learner.id,
        planId: 'mwezi-1',
        method: 'bank_transfer',
        amountTzs: 10000,
        reference: 'PG-REF-001',
        recordedByUserId: admin.id,
      });
      assert.equal(record.status, 'pending');

      const [first, second] = await Promise.all([
        store.approvePaymentRecord({
          paymentRecordId: record.id,
          approvedByUserId: admin.id,
        }),
        store.approvePaymentRecord({
          paymentRecordId: record.id,
          approvedByUserId: admin.id,
        }),
      ]);

      assert.equal(first.entitlement.id, second.entitlement.id);

      const entitlements = await store.entitlementsForUser(learner.id);
      assert.equal(entitlements.length, 1);
      assert.equal(entitlements[0].status, 'active');

      const updatedLearner = await store.getUser(learner.id);
      assert.equal(updatedLearner.accountStatus, 'active');

      const events = await store.auditEventsFor({
        targetType: 'payment_record',
        targetId: record.id,
      });
      assert.equal(events.length, 1);
    });
  },
);

test(
  'postgres: a duplicate payment reference is rejected at the database level',
  { skip: databaseUrl ? false : 'DATABASE_URL is not set' },
  async () => {
    await withPostgresStore(async (store) => {
      const { admin, learner } = await seedUsers(store);

      await store.recordPaymentRecord({
        userId: learner.id,
        planId: 'wiki-1',
        method: 'cash',
        amountTzs: 3000,
        reference: 'PG-DUP-REF',
        recordedByUserId: admin.id,
      });

      await assert.rejects(
        () =>
          store.recordPaymentRecord({
            userId: learner.id,
            planId: 'wiki-1',
            method: 'cash',
            amountTzs: 3000,
            reference: 'PG-DUP-REF',
            recordedByUserId: admin.id,
          }),
        /DUPLICATE_REFERENCE|already exists/,
      );
    });
  },
);

test(
  'postgres: payment amount and currency must match the selected plan',
  { skip: databaseUrl ? false : 'DATABASE_URL is not set' },
  async () => {
    await withPostgresStore(async (store) => {
      const { admin, learner } = await seedUsers(store);
      await assert.rejects(
        () =>
          store.recordPaymentRecord({
            userId: learner.id,
            planId: 'wiki-1',
            method: 'cash',
            amountTzs: 0,
            recordedByUserId: admin.id,
          }),
        /PAYMENT_AMOUNT_MISMATCH|must match/,
      );
    });
  },
);

test(
  'postgres: reversal and expiry reconciliation serialize without stale access',
  { skip: databaseUrl ? false : 'DATABASE_URL is not set' },
  async () => {
    await withPostgresStore(async (store) => {
      const { admin, learner } = await seedUsers(store);
      const record = await store.recordPaymentRecord({
        userId: learner.id,
        planId: 'mwezi-1',
        method: 'bank_transfer',
        amountTzs: 10000,
        recordedByUserId: admin.id,
      });
      await store.approvePaymentRecord({
        paymentRecordId: record.id,
        approvedByUserId: admin.id,
      });

      await Promise.all([
        store.reversePaymentRecord({
          paymentRecordId: record.id,
          actorUserId: admin.id,
        }),
        store.reconcileUserEntitlements(learner.id),
      ]);

      const reconciled = await store.reconcileUserEntitlements(learner.id);
      assert.equal(reconciled.accountStatus, 'suspended');
      assert.equal(await store.hasActiveEntitlement(learner.id), false);
    });
  },
);

test(
  'postgres: reversing revokes the entitlement and suspends the account when no other access remains',
  { skip: databaseUrl ? false : 'DATABASE_URL is not set' },
  async () => {
    await withPostgresStore(async (store) => {
      const { admin, learner } = await seedUsers(store);

      const record = await store.recordPaymentRecord({
        userId: learner.id,
        planId: 'mwaka-1',
        method: 'bank_transfer',
        amountTzs: 100000,
        recordedByUserId: admin.id,
      });
      await store.approvePaymentRecord({
        paymentRecordId: record.id,
        approvedByUserId: admin.id,
      });
      assert.equal(await store.hasActiveEntitlement(learner.id), true);

      const reversed = await store.reversePaymentRecord({
        paymentRecordId: record.id,
        actorUserId: admin.id,
        reason: 'Refund',
      });
      assert.equal(reversed.paymentRecord.status, 'reversed');
      assert.equal(reversed.entitlement.status, 'revoked');
      assert.equal(await store.hasActiveEntitlement(learner.id), false);

      const suspendedLearner = await store.getUser(learner.id);
      assert.equal(suspendedLearner.accountStatus, 'suspended');
      assert.equal(suspendedLearner.subscriptionPlan, null);
      assert.equal(suspendedLearner.subscriptionStartedAt, null);
    });
  },
);

test(
  'postgres: reversing one of two active entitlements keeps the other plan active',
  { skip: databaseUrl ? false : 'DATABASE_URL is not set' },
  async () => {
    await withPostgresStore(async (store) => {
      const { admin, learner } = await seedUsers(store);

      const first = await store.recordPaymentRecord({
        userId: learner.id,
        planId: 'wiki-1',
        method: 'cash',
        amountTzs: 3000,
        recordedByUserId: admin.id,
      });
      await store.approvePaymentRecord({
        paymentRecordId: first.id,
        approvedByUserId: admin.id,
      });

      const second = await store.recordPaymentRecord({
        userId: learner.id,
        planId: 'mwaka-1',
        method: 'bank_transfer',
        amountTzs: 100000,
        recordedByUserId: admin.id,
      });
      await store.approvePaymentRecord({
        paymentRecordId: second.id,
        approvedByUserId: admin.id,
      });

      await store.reversePaymentRecord({
        paymentRecordId: first.id,
        actorUserId: admin.id,
      });

      const stillActiveLearner = await store.getUser(learner.id);
      assert.equal(stillActiveLearner.accountStatus, 'active');
      assert.equal(stillActiveLearner.subscriptionPlan, 'Mwaka 1');
      assert.equal(await store.hasActiveEntitlement(learner.id), true);
    });
  },
);
