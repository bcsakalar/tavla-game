const db = require('./db');

async function resetAdmin() {
  try {
    const result = await db.query(
      `DELETE FROM users WHERE role = 'admin'`
    );
    console.log(`${result.rowCount} admin kullanıcı silindi.`);
  } catch (err) {
    console.error('Admin silme hatası:', err.message);
    process.exit(1);
  } finally {
    await db.pool.end();
  }
}

resetAdmin();
