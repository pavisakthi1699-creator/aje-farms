export function createPaymentProvider() {
  return new DevelopmentPaymentProvider();
}

class DevelopmentPaymentProvider {
  name = 'development';

  isProductionReady = false;

  startCheckout({ transactionId, planTitle, price, method, phoneNumber }) {
    const autoConfirmAt = new Date(Date.now() + 3000).toISOString();
    return {
      provider: 'development',
      providerReference: `dev-${transactionId}`,
      status: 'pending',
      message: `Ombi la malipo ${price} kwa ${planTitle} limetumwa kupitia ${method}.`,
      checkoutInstructions:
        `Thibitisha malipo kwenye simu ${phoneNumber}. ` +
        'Tutawasha kifurushi baada ya uthibitisho wa mtoa huduma.',
      autoConfirmAt,
    };
  }

  shouldConfirm(transaction) {
    if (transaction.provider !== 'development') return false;
    if (transaction.status !== 'pending') return false;
    if (!transaction.autoConfirmAt) return false;
    return Date.parse(transaction.autoConfirmAt) <= Date.now();
  }
}
