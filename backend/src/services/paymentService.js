const crypto = require('crypto');

/**
 * DigiPay Payment Gateway Service
 * Isolated external service wrapper for DigiPay API
 */
const processDigiPayPayment = async ({ bookingId, amount, paymentMethod }) => {
  const randomRef = crypto.randomBytes(6).toString('hex').toUpperCase();
  const transactionReference = `DIGIPAY-${Date.now()}-${randomRef}`;

  return {
    success: true,
    transactionReference,
    paymentMethod: paymentMethod || 'DIGIPAY',
    amount,
    paymentStatus: 'SUCCESSFUL',
    paymentDate: new Date()
  };
};

module.exports = {
  processDigiPayPayment
};
