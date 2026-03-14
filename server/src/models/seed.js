const bcrypt = require('bcrypt');
const db = require('./db');

async function seed() {
  try {
    const passwordHash = await bcrypt.hash('admin123456', 12);

    await db.query(`
      INSERT INTO users (username, email, password_hash, role, elo_rating)
      VALUES ($1, $2, $3, $4, $5)
      ON CONFLICT (username) DO NOTHING
    `, ['admin', 'admin@tavla.com', passwordHash, 'admin', 1500]);

    console.error('Seed completed: admin user created (admin / admin123456)');
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
