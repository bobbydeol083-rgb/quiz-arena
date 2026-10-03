'use strict';

const CoinTransaction = require('../models/CoinTransaction');

/**
 * Apply a coin delta to a user document and record it in the ledger.
 * The caller saves the user; this helper keeps the math in one place.
 *
 * @param {User} user mongoose user doc (will be mutated, not saved)
 * @param {number} amount +credit / -debit
 * @param {string} reason human-readable reason
 * @param {string|null} refType
 * @param {ObjectId|null} refId
 * @returns {Promise<CoinTransaction>}
 */
async function applyCoins(user, amount, reason, refType = null, refId = null) {
  const next = (user.coins || 0) + amount;
  if (next < 0) {
    const err = new Error('Insufficient coins');
    err.code = 'INSUFFICIENT_COINS';
    throw err;
  }
  user.coins = next;
  const tx = await CoinTransaction.create({
    userId: user._id,
    amount,
    reason,
    refType,
    refId,
    balanceAfter: next,
  });
  return tx;
}

module.exports = { applyCoins };
