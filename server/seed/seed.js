'use strict';

// Idempotent seed: `npm run seed`
// - Categories are upserted by unique name.
// - Questions are upserted by exact question text.
// Safe to run multiple times; existing documents are updated in place.

const mongoose = require('mongoose');
const env = require('../src/config/env');
const logger = require('../src/utils/logger');
const Category = require('../src/models/Category');
const Question = require('../src/models/Question');
const DATA = require('./questions');

async function seed() {
  await mongoose.connect(env.mongoUri);
  logger.info(`Seeding ${env.mongoUri}`);

  let catUpserted = 0;
  let qUpserted = 0;

  for (const cat of DATA) {
    const category = await Category.findOneAndUpdate(
      { name: cat.name },
      { $set: { icon: cat.icon, color: cat.color, description: cat.description } },
      { upsert: true, new: true, setDefaultsOnInsert: true }
    );
    catUpserted += 1;

    for (const q of cat.questions) {
      await Question.findOneAndUpdate(
        { question: q.question },
        {
          $set: {
            category: category._id,
            difficulty: q.difficulty,
            options: q.options,
            answerIndex: q.answerIndex,
            explanation: q.explanation,
          },
        },
        { upsert: true, setDefaultsOnInsert: true }
      );
      qUpserted += 1;
    }
  }

  // Clean up: drop questions whose category vanished (keeps seed reruns tidy).
  const catIds = await Category.distinct('_id');
  const orphaned = await Question.deleteMany({ category: { $nin: catIds } });

  const totals = await Question.aggregate([{ $group: { _id: '$category', n: { $sum: 1 } } }]);
  logger.info(`Seed complete: ${catUpserted} categories, ${qUpserted} question upserts, ${orphaned.deletedCount} orphans removed`);
  logger.info(`Questions in DB: ${totals.reduce((t, r) => t + r.n, 0)}`);

  await mongoose.disconnect();
}

if (require.main === module) {
  seed().catch((err) => {
    logger.error('Seed failed', err);
    process.exit(1);
  });
}

module.exports = { seed };
