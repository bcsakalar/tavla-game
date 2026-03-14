const { server } = require('./app');
const config = require('./config');
const db = require('./models/db');

async function start() {
  try {
    // Test database connection
    await db.query('SELECT NOW()');
    console.warn('[DB] PostgreSQL bağlantısı başarılı');

    server.listen(config.port, () => {
      console.warn(`[Server] Tavla Online - Port ${config.port} - ${config.env}`);
    });
  } catch (err) {
    console.error('[Server] Başlatma hatası:', err.message);
    process.exit(1);
  }
}

start();
