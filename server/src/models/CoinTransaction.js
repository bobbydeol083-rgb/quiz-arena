'use strict';

const mongoose = require('mongoose');

// Server-side coin ledger (Elite's tbl_tracker equivalent). Every coin
// movement is recorded with the balance after the change.
const coinTransactionSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    amount: { type: Number, required: true }, // +credit / -debit
    reason: { type: String, required: true, trim: true, maxlength: 120 },
    refType: { type: String, default: null }, // e.g. 'contest', 'daily', 'referral'
    refId: { type: mongoose.Schema.Types.ObjectId, default: null },
    balanceAfter: { type: Number, required: true, min: 0 },
  },
  { timestamps: { createdAt: true, updatedAt: false } }
);

coinTransactionSchema.index({ userId: 1, createdAt: -1 });

module.exports = mongoose.model('CoinTransaction', coinTransactionSchema);
