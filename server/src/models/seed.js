const bcrypt = require('bcrypt');
const crypto = require('crypto');
const db = require('./db');

async function seed() {
  try {
    const adminPassword = process.env.ADMIN_PASSWORD || crypto.randomBytes(12).toString('hex');
    const passwordHash = await bcrypt.hash(adminPassword, 12);

    await db.query(`
      INSERT INTO users (username, email, password_hash, role, elo_rating)
      VALUES ($1, $2, $3, $4, $5)
      ON CONFLICT (username) DO NOTHING
    `, ['admin', 'admin@tavla.com', passwordHash, 'admin', 1500]);

    if (!process.env.ADMIN_PASSWORD) {
      console.log(`Seed completed: admin user created (admin / ${adminPassword})`);
    } else {
      console.log('Seed completed: admin user created');
    }
  } catch (err) {
    console.error('Seed failed:', err.message);
    process.exit(1);
  } finally {
    await db.pool.end();
  }
}

if (require.main === module) {
  seed();
}

module.exports = { seed };
