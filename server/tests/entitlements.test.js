import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import test from 'node:test';

import { catalog } from '../catalog.js';
import { JsonStore } from '../store/json-store.js';

function tempDataFile() {
  return path.join(
    os.tmpdir(),
    `aje-entitlements-${Date.now()}-${Math.random().toString(36).slice(2)}.json`,
  );
}

function freshStore() {
  return new JsonStore({ catalog, filePath: tempDataFile() });
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

test('active plans expose server-owned price and duration', () => {
  const store = freshStore();
  const plans = store.activePlans();

  assert.ok(plans.length >= 3);
  const monthly = plans.find((plan) => plan.id === 'mwezi-1');
  assert.equal(monthly.priceTzs, 10000);
  assert.equal(monthly.durationDays, 30);
  assert.equal(monthly.price, 'TZS 10,000');
});

test('recording a payment against an unknown plan is rejected', async () => {
  const store = freshStore();
  const { admin, learner } = await seedUsers(store);

  const record = await store.recordPaymentRecord({
    userId: learner.id,
    planId: 'not-a-real-plan',
    method: 'cash',
    amountTzs: 10000,
    recordedByUserId: admin.id,
  });

  assert.equal(record, null);
});

test('approving a payment grants an entitlement and activates the account', async () => {
  const store = freshStore();
  const { admin, learner } = await seedUsers(store);

  const record = await store.recordPaymentRecord({
    userId: learner.id,
    planId: 'mwezi-1',
    method: 'bank_transfer',
    amountTzs: 10000,
    reference: 'REF-001',
    recordedByUserId: admin.id,
  });
  assert.equal(record.status, 'pending');

  const { paymentRecord, entitlement } = await store.approvePaymentRecord({
    paymentRecordId: record.id,
    approvedByUserId: admin.id,
    reason: 'Bank statement confirmed',
  });

  assert.equal(paymentRecord.status, 'approved');
  assert.equal(entitlement.userId, learner.id);
  assert.equal(entitlement.planId, 'mwezi-1');
  assert.equal(entitlement.status, 'active');

  const updatedLearner = await store.getUser(learner.id);
  assert.equal(updatedLearner.accountStatus, 'active');
  assert.equal(updatedLearner.subscriptionPlan, 'Mwezi 1');

  assert.equal(await store.hasActiveEntitlement(learner.id), true);

  const events = await store.auditEventsFor({
    targetType: 'payment_record',
    targetId: record.id,
  });
  assert.equal(events.length, 1);
  assert.equal(events[0].action, 'payment_approved');
  assert.equal(events[0].previousStatus, 'pending');
  assert.equal(events[0].newStatus, 'approved');
  assert.equal(events[0].actorUserId, admin.id);
});

test('approving the same payment twice does not mint a second entitlement', async () => {
  const store = freshStore();
  const { admin, learner } = await seedUsers(store);

  const record = await store.recordPaymentRecord({
    userId: learner.id,
    planId: 'wiki-1',
    method: 'cash',
    amountTzs: 3000,
    recordedByUserId: admin.id,
  });

  const first = await store.approvePaymentRecord({
    paymentRecordId: record.id,
    approvedByUserId: admin.id,
  });
  const second = await store.approvePaymentRecord({
    paymentRecordId: record.id,
    approvedByUserId: admin.id,
  });

  assert.equal(first.entitlement.id, second.entitlement.id);

  const allEntitlements = await store.entitlementsForUser(learner.id);
  assert.equal(allEntitlements.length, 1);

  const events = await store.auditEventsFor({
    targetType: 'payment_record',
    targetId: record.id,
  });
  assert.equal(events.length, 1, 'the second approval must not write a second audit event');
});

test('reversing an approved payment revokes access and is itself idempotent', async () => {
  const store = freshStore();
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

  const first = await store.reversePaymentRecord({
    paymentRecordId: record.id,
    actorUserId: admin.id,
    reason: 'Refund requested',
  });
  assert.equal(first.paymentRecord.status, 'reversed');
  assert.equal(first.entitlement.status, 'revoked');
  assert.equal(await store.hasActiveEntitlement(learner.id), false);

  const revokedLearner = await store.getUser(learner.id);
  assert.equal(revokedLearner.accountStatus, 'suspended');
  // A suspended user must not still read as "Premium" from a stale plan
  // label — the profile screen's premium badge keys off subscriptionPlan,
  // not accountStatus, so this has to be cleared too.
  assert.equal(revokedLearner.subscriptionPlan, null);
  assert.equal(revokedLearner.subscriptionStartedAt, null);

  // Reversing again must not write a second audit event or error.
  const second = await store.reversePaymentRecord({
    paymentRecordId: record.id,
    actorUserId: admin.id,
  });
  assert.equal(second.paymentRecord.status, 'reversed');

  const events = await store.auditEventsFor({
    targetType: 'payment_record',
    targetId: record.id,
  });
  assert.equal(
    events.filter((event) => event.action === 'payment_reversed').length,
    1,
  );
});

test('reversing one of two active entitlements keeps the other plan active', async () => {
  const store = freshStore();
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

test('a duplicate payment reference is rejected before it can be approved twice', async () => {
  const store = freshStore();
  const { admin, learner } = await seedUsers(store);

  await store.recordPaymentRecord({
    userId: learner.id,
    planId: 'wiki-1',
    method: 'cash',
    amountTzs: 3000,
    reference: 'DUP-REF',
    recordedByUserId: admin.id,
  });

  await assert.rejects(
    () =>
      store.recordPaymentRecord({
        userId: learner.id,
        planId: 'wiki-1',
        method: 'cash',
        amountTzs: 3000,
        reference: 'DUP-REF',
        recordedByUserId: admin.id,
      }),
    /DUPLICATE_REFERENCE|already exists/,
  );
});
