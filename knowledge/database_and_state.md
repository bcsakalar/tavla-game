# Tavla Online — Veritabanı ve State Management

> **Son güncelleme:** 2026-03-17

---

## 1. Veritabanı: PostgreSQL 16

### 1.1 Bağlantı Yapılandırması

```javascript
// server/src/models/db.js
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  // postgresql://tavla_user:password@host:5432/tavla_db
  max: 20,              // Maksimum bağlantı sayısı
  idleTimeoutMillis: 30000,  // 30 saniye boşta kalma süresi
});
```

| Ortam | Host | Port | DB Adı | Kullanıcı |
|-------|------|------|--------|-----------|
| **Dev** | `postgres` (Docker internal) | 5432 (internal), 5436 (external) | `tavla_db` | `tavla_user` |
| **Prod** | `db` (Docker internal) | 5432 (internal only, dışarıya kapalı) | `tavla_db` | `tavla_user` |

### 1.2 Şema Diyagramı

```
┌────────────────────────────────────────────────────────────────┐
│                           users                                 │
├────────────────────────────────────────────────────────────────┤
│ id              SERIAL PRIMARY KEY                              │
│ username        VARCHAR(50) UNIQUE NOT NULL                     │
│ email           VARCHAR(255) UNIQUE NOT NULL                    │
│ password_hash   VARCHAR(255) NOT NULL                           │
│ avatar_url      TEXT                                            │
│ elo_rating      INTEGER DEFAULT 1200                            │
│ total_wins      INTEGER DEFAULT 0                               │
│ total_losses    INTEGER DEFAULT 0                               │
│ total_draws     INTEGER DEFAULT 0                               │
│ gammon_wins     INTEGER DEFAULT 0                               │
│ backgammon_wins INTEGER DEFAULT 0                               │
│ is_online       BOOLEAN DEFAULT false                           │
│ is_banned       BOOLEAN DEFAULT false                           │
│ role            VARCHAR(20) DEFAULT 'player' (player | admin)   │
│ created_at      TIMESTAMP DEFAULT NOW()                         │
│ updated_at      TIMESTAMP DEFAULT NOW() [auto-trigger]          │
└────────────────────────────────────────────────────────────────┘
         │ (1)                              │ (1)
         │                                  │
         ▼ (N)                              ▼ (N)
┌────────────────────────────────────────┐ ┌──────────────────────┐
│              games                      │ │      reports          │
├────────────────────────────────────────┤ ├──────────────────────┤
│ id              SERIAL PK              │ │ id         SERIAL PK │
│ white_player_id INT → users(id)        │ │ reporter_id→users(id)│
│ black_player_id INT → users(id)        │ │ reported_id→users(id)│
│ status          VARCHAR(20)            │ │ game_id    → games(id)│
│   'waiting'|'playing'|'finished'|      │ │ reason     TEXT       │
│   'abandoned'                          │ │ status     VARCHAR(20)│
│ winner_id       INT → users(id)        │ │   'pending'|'reviewed'│
│ result_type     VARCHAR(20)            │ │   |'resolved'        │
│   'normal'|'gammon'|'backgammon'|      │ │ admin_note TEXT       │
│   'resign'|'timeout'|'disconnect'      │ │ created_at TIMESTAMP │
│ board_state     JSONB                  │ │ updated_at TIMESTAMP │
│ elo_changes     JSONB                  │ └──────────────────────┘
│ total_moves     INTEGER DEFAULT 0      │
│ started_at      TIMESTAMP              │
│ finished_at     TIMESTAMP              │
│ created_at      TIMESTAMP DEFAULT NOW()│
└────────────────────────────────────────┘
         │ (1)                    │ (1)
         │                        │
         ▼ (N)                    ▼ (N)
┌────────────────────────────┐  ┌──────────────────────────────┐
│       game_moves            │  │       chat_messages           │
├────────────────────────────┤  ├──────────────────────────────┤
│ id         SERIAL PK       │  │ id         SERIAL PK         │
│ game_id    INT → games(id) │  │ game_id    INT → games(id)   │
│ user_id    INT → users(id) │  │ user_id    INT → users(id)   │
│ move_number INT             │  │ message    VARCHAR(500)       │
│ dice_values INT[]           │  │ is_system  BOOLEAN DEFAULT f │
│ moves      JSONB            │  │ created_at TIMESTAMP NOW()   │
│ board_after JSONB           │  └──────────────────────────────┘
│ created_at TIMESTAMP NOW() │       INDEX: (game_id, created_at)
└────────────────────────────┘
     INDEX: (game_id, move_number)

┌────────────────────────────────────────┐
│           daily_stats                   │
├────────────────────────────────────────┤
│ id                   SERIAL PK         │
│ date                 DATE UNIQUE       │
│ total_games          INTEGER DEFAULT 0 │
│ total_new_users      INTEGER DEFAULT 0 │
│ peak_concurrent      INTEGER DEFAULT 0 │
│ avg_game_duration    INTERVAL          │
└────────────────────────────────────────┘
```

### 1.3 İndeksler

```sql
-- users tablosu
CREATE INDEX idx_users_elo_rating ON users(elo_rating DESC);
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_role ON users(role);

-- games tablosu
CREATE INDEX idx_games_white_player ON games(white_player_id);
CREATE INDEX idx_games_black_player ON games(black_player_id);
CREATE INDEX idx_games_status ON games(status);
CREATE INDEX idx_games_created_at ON games(created_at DESC);
CREATE INDEX idx_games_winner ON games(winner_id);

-- game_moves tablosu
CREATE INDEX idx_game_moves_game_move ON game_moves(game_id, move_number);

-- chat_messages tablosu
CREATE INDEX idx_chat_messages_game ON chat_messages(game_id, created_at);
```

### 1.4 Trigger

```sql
-- users.updated_at otomatik güncelleme
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
```

### 1.5 JSONB Veri Yapıları

**games.board_state** — Son tahta durumu:
```json
{
  "points": [
    { "count": 2, "player": "W" },
    { "count": 0, "player": null },
    ...  // 24 nokta
  ],
  "bar": { "W": 0, "B": 0 },
  "borneOff": { "W": 15, "B": 12 }
}
```

**games.elo_changes** — Puan değişiklikleri:
```json
{
  "white": { "before": 1200, "after": 1232, "change": 32 },
  "black": { "before": 1250, "after": 1218, "change": -32 }
}
```

**game_moves.moves** — Tur hamleleri:
```json
[
  { "from": 24, "to": 20 },
  { "from": 13, "to": 10 }
]
```

**game_moves.board_after** — Hamle sonrası tahta (board_state ile aynı format)

### 1.6 Seed Data

```javascript
// server/src/models/seed.js
Admin Kullanıcı:
  username: 'admin'
  email: 'admin@tavla.com'
  password: process.env.ADMIN_PASSWORD || crypto.randomBytes(12).toString('hex')
  role: 'admin'
  elo_rating: 1200
```

> ℹ️ `ADMIN_PASSWORD` env var belirtilmezse rastgele şifre üretilir ve loglanır.

---

## 2. Sorgu Kalıpları (ORM Yok — Doğrudan pg)

### 2.1 Parametrik Sorgu Kullanımı (SQL Injection Koruması)

```javascript
// ✅ DOĞRU — Parametrik sorgu
const result = await pool.query(
  'SELECT * FROM users WHERE id = $1',
  [userId]
);

// ❌ YANLIŞ — String interpolation (ASLA kullanma)
const result = await pool.query(
  `SELECT * FROM users WHERE id = ${userId}`
);
```

### 2.2 Servis Katmanı Sorgu Örnekleri

```javascript
// userService.js — Kayıt
await pool.query(
  'INSERT INTO users (username, email, password_hash) VALUES ($1, $2, $3) RETURNING *',
  [username, email, hashedPassword]
);

// userService.js — Leaderboard
await pool.query(
  `SELECT id, username, avatar_url, elo_rating, total_wins, total_losses 
   FROM users 
   WHERE (total_wins + total_losses) > 0 
   ORDER BY elo_rating DESC 
   LIMIT $1 OFFSET $2`,
  [limit, offset]
);

// gameService.js — Oyun bitişi güncelleme
await pool.query(
  `UPDATE games SET 
    status = 'finished', winner_id = $1, result_type = $2,
    board_state = $3, elo_changes = $4, total_moves = $5, finished_at = NOW()
   WHERE id = $6`,
  [winnerId, resultType, JSON.stringify(boardState), JSON.stringify(eloChanges), totalMoves, gameId]
);
```

---

## 3. Backend In-Memory State

### 3.1 Socket Handler State (In-Memory + Redis Persist)

```javascript
// server/src/socket/handlers/lobby.js
const matchmakingQueue = [];  // [{ socket, userId, elo, joinedAt }]

// server/src/socket/handlers/game.js
const activeGames = new Map();      // gameId → GameState nesnesi
const playerGames = new Map();      // playerId → gameId
const turnTimers = new Map();       // gameId → setTimeout referansı
const disconnectTimers = new Map(); // gameId → { playerId, timer }

// server/src/socket/handlers/bot.js
const botGames = new Map();      // odaId → { game, difficulty, isProcessing }
```

> **Redis Persistence:** Aktif oyunlar `stateStore` aracılığıyla Redis'e persist edilir.
> Oyun oluşturulduğunda → `stateStore.saveGame()`, oyun bittiğinde → `stateStore.deleteGame()`.
> Sunucu kapatılırken → `stateStore.saveAllGames()` ile tüm aktif oyunlar Redis'e kaydedilir.
> Redis bağlanamıyorsa → sadece in-memory (graceful fallback).

### 3.2 GameState Nesnesi (In-Memory)

```javascript
// engine.js createGame() tarafından üretilir
{
  state: 'PLAYING',         // WAITING → INITIAL_ROLL → PLAYING → FINISHED
  board: {
    points: Array(24),      // Her nokta: { count, player }
    bar: { W: 0, B: 0 },
    borneOff: { W: 0, B: 0 }
  },
  currentTurn: 'W',         // 'W' veya 'B'
  turnPhase: 'ROLLING',     // 'ROLLING' veya 'MOVING'
  dice: [],                 // [3, 5] veya çiftlerde [4, 4, 4, 4]
  remainingDice: [],        // Kullanılmamış zarlar
  whitePlayerId: 12,
  blackPlayerId: 34,
  moveNumber: 0,
  turnId: 0,               // Timeout race condition koruması
  moveHistory: [],          // Mevcut turun hamleleri [{ from, to }]
  winner: null,
  resultType: null
}
```

---

## 4. Frontend State Management (Flutter / Riverpod)

### 4.1 Provider Hiyerarşisi

```
Global Scope (uygulama yaşam döngüsü):
├── authProvider ─────────── StateNotifierProvider<AuthNotifier, AuthState>
│   ├── status: initial | loading | authenticated | unauthenticated | error
│   ├── user: User?
│   └── error: String?
│
├── apiClientProvider ────── Provider<ApiClient> (Singleton)
│   └── Dio with auto-refresh interceptor
│
├── socketServiceProvider ── Provider<SocketService> (Singleton)
│   └── Socket.IO with event buffering
│
├── authStorageProvider ──── Provider<AuthStorage> (Singleton)
│   └── FlutterSecureStorage wrapper
│
└── settingsProvider ─────── StateNotifierProvider<SettingsNotifier, SettingsState>
    ├── soundEnabled: bool
    ├── hapticEnabled: bool
    ├── moveHintsEnabled: bool
    ├── pointNumbersEnabled: bool
    └── hasSeenTutorial: bool

Feature Scope (sayfa yaşam döngüsü — autoDispose):
├── lobbyProvider ────────── StateNotifierProvider<LobbyNotifier, LobbyState>
│   ├── status: idle | searching | matched
│   ├── onlineCount: int
│   ├── searchSeconds: int
│   └── matchData: Map?
│
├── gameProvider ─────────── StateNotifierProvider<GameNotifier, GamePlayState>
│   ├── phase: loading | initialRoll | playing | finished
│   ├── snapshot: GameSnapshot?
│   ├── myColor: String (W veya B)
│   ├── selectedPoint: int?
│   ├── validMoves: Map<int, List<int>>
│   ├── validMoveTargets: List<int>
│   ├── chatMessages: List<Map>
│   ├── turnTimer / maxTimer: int
│   ├── canUndo: bool
│   └── resultMessage / eloChange
│
└── botGameProvider ──────── StateNotifierProvider<BotGameNotifier, GamePlayState>
    └── (gameProvider ile aynı state, isBotGame=true)
```

### 4.2 State Güncelleme Akışı

```
1. Socket Event Gelir
   ↓
2. Provider'daki listener tetiklenir
   ↓
3. State copyWith() ile immutable güncelleme
   ↓
4. Riverpod otomatik widget rebuild tetikler
   ↓
5. UI güncellenir

Örnek:
  Socket: game:diceRolled → { dice: [3, 5], snapshot: {...} }
  Provider: state = state.copyWith(
    snapshot: newSnapshot,
    phase: GamePhase.playing,
    turnTimer: 60,
  )
  UI: DiceWidget yeni değerleri gösterir, butonlar güncellenir
```

### 4.3 Persistent State (SharedPreferences)

```dart
// Kaydedilen anahtarlar:
'sound_enabled'          → bool (varsayılan: true)
'haptic_enabled'         → bool (varsayılan: true)
'move_hints_enabled'     → bool (varsayılan: true)
'point_numbers_enabled'  → bool (varsayılan: false)
'has_seen_tutorial'      → bool (varsayılan: false)
```

### 4.4 Secure Storage (FlutterSecureStorage)

```dart
// Şifrelenmiş token saklama:
'access_token'   → JWT access token (15dk ömürlü)
'refresh_token'  → JWT refresh token (7 gün ömürlü)
```

---

## 5. Veri Akış Diyagramı

```
KAYIT AKIŞI:
  Flutter Form → ApiClient.register()
    → POST /api/auth/register
    → userService.register()
    → INSERT INTO users
    → JWT token üret
    ← { user, accessToken, refreshToken }
  → AuthStorage.saveTokens()
  → SocketService.connect(token)
  → authProvider.state = authenticated

OYUN BAŞLATMA:
  LobbyScreen → SocketService.joinQueue()
    → lobby:queue event
    → matchmakingQueue.push()
    → 5s interval: ELO eşleşme kontrolü
    → Eşleşme! → engine.createGame()
    → games INSERT (status: playing)
    → game:start emit (her iki oyuncuya)
  ← GameSnapshot
  → gameProvider.initGame(snapshot)

HAMLE YAPMA:
  GameScreen → tap point → gameProvider.selectPoint()
    → validMoves hesapla (client-side önizleme)
    → tap target → SocketService.move(from, to)
    → game:move event
    → engine.makeMove() [server-side doğrulama]
    → game:moved emit (her iki oyuncuya)
  ← { move, snapshot, turnOver, remainingDice }
  → gameProvider.state güncelle

OYUN BİTİŞİ:
  Son taş kırılır → engine detects winner
    → scoring.calculateElo()
    → gameService.finishGameRecord()
    → UPDATE games SET status='finished'
    → INSERT INTO game_moves (tüm turlar)
    → UPDATE users SET elo_rating, total_wins/losses
    → game:finished emit
  ← { winner, resultType, eloChanges }
  → gameProvider.phase = finished
  → Game over dialog göster
```
