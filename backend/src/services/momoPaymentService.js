const crypto = require('crypto');

/**
 * Mobile Money Payment Gateway (MTN MoMo & Orange Money) Service
 */
const initiateMobilePayment = async ({ paymentMethod, phoneNumber, amount, campaignId }) => {
  const prefix = paymentMethod === 'MTN_MOMO' ? 'MOMO' : 'OM';
  const randomRef = crypto.randomBytes(6).toString('hex').toUpperCase();
  const transactionRef = `TX-${prefix}-${Date.now()}-${randomRef}`;

  // Validate phone number format (Basic Mobile Money format check)
  const cleanPhone = phoneNumber.replace(/[^0-9]/g, '');
  if (cleanPhone.length < 8) {
    throw new Error('Invalid mobile money phone number');
  }

  // Simulate payment request handshake
  return {
    success: true,
    transactionRef,
    paymentMethod,
    phoneNumber: cleanPhone,
    amount,
    currency: 'XAF',
    status: 'PENDING',
    instructions: `A USSD payment prompt has been sent to ${cleanPhone}. Please enter your PIN to authorize ${amount} XAF payment.`
  };
};

const verifyMobilePayment = async (transactionRef) => {
  // Simulates instant API verification with Mobile Money gateway
  return {
    success: true,
    transactionRef,
    status: 'SUCCESS',
    paidAt: new Date()
  };
};

module.exports = {
  initiateMobilePayment,
  verifyMobilePayment
};
