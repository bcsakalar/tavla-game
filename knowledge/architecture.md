# Tavla Online — Mimari Dokümantasyonu

> **Son güncelleme:** 2026-03-24
> **Proje:** Gerçek zamanlı çok oyunculu Tavla (Backgammon) platformu

---

## 1. Genel Mimari Bakış

Tavla Online **3 katmanlı** bir full-stack uygulamadır:

```
┌──────────────────────────────────────────────────────────────┐
│                     Flutter Mobile App                       │
│              (Riverpod + GoRouter + Socket.IO)               │
├───────────────────────┬──────────────────────────────────────┤
│    HTTP REST (Dio)    │    WebSocket (Socket.IO Client)      │
└───────────┬───────────┴──────────────┬───────────────────────┘
            │                          │
┌───────────▼──────────────────────────▼───────────────────────┐
│                     Nginx Reverse Proxy                       │
│          (SSL Termination + Rate Limiting + WS Upgrade)       │
├──────────────────────────────────────────────────────────────┤
│                     Node.js Backend                           │
│          (Express 4.21 + Socket.IO 4.8 + JWT Auth)           │
├───────────────────────┬──────────────────────────────────────┤
│   REST API Layer      │   Socket.IO Real-Time Layer          │
│   (Routes/Controllers)│   (Handlers: Lobby, Game, Bot)       │
├───────────────────────┴──────────────────────────────────────┤
│                  Service Layer (Business Logic)               │
│            (userService.js + gameService.js)                  │
├──────────────────────────────────────────────────────────────┤
│              Pure Game Engine (Saf JavaScript)                │
│   (board.js, dice.js, moves.js, engine.js, scoring.js, bot)  │
├──────────────────────────────────────────────────────────────┤
│                  PostgreSQL 16 (6 Tablo)                      │
│          (users, games, game_moves, chat, reports, stats)     │
└──────────────────────────────────────────────────────────────┘
```

---

## 2. Backend Mimarisi (Node.js)

### 2.1 Katmanlı Yapı

```
İstek Akışı:
  Client → Nginx → Express Middleware → Route → Controller → Service → DB/Game Engine
```

| Katman | Dosya Yolu | Sorumluluk |
|--------|-----------|------------|
| **Middleware** | `server/src/middleware/` | JWT doğrulama, rate limiting, hata yönetimi, request ID, CSRF |
| **Routes** | `server/src/routes/api/` | HTTP endpoint tanımları |
| **Controllers** | `server/src/controllers/` | Request/response işleme (ince katman) |
| **Services** | `server/src/services/` | İş mantığı (userService, gameService) |
| **Game Engine** | `server/src/game/` | Saf JS oyun mantığı + Redis state store — **DB bağımlılığı yok** |
| **Models** | `server/src/models/` | PostgreSQL pool, migration, seed |
| **Socket Handlers** | `server/src/socket/handlers/` | WebSocket olay işleyicileri |

### 2.2 Middleware Zinciri (Sıralı)

```javascript
// server/src/app.js içindeki sıra:
1. requestId()           // Her istek için benzersiz UUID (X-Request-ID)
2. helmet()              // Güvenlik başlıkları (CSP, X-Frame-Options vb.)
3. cors({ origin })      // CORS — CORS_ORIGIN env'den
4. express.json()        // JSON body parser
5. express.urlencoded()  // Form body parser
6. express.static()      // public/ klasörü (admin CSS/JS)
7. express-session()     // Admin panel oturumları
8. rateLimiter           // 100 req/15min (genel), 20 req/15min (auth), 5 req/15min (admin login)
9. csrfToken             // Admin route'larda CSRF token üretimi
10. Routes               // /api/* ve /admin/*
11. errorHandler         // Global hata yakalayıcı (en son) + request ID loglama
```

### 2.3 Kimlik Doğrulama Mimarisi

```
┌─ REST API ─────────────────────────────────────────┐
│  Authorization: Bearer <accessToken>                │
│  JWT → auth.js middleware → req.user = { id, role } │
└─────────────────────────────────────────────────────┘

┌─ Socket.IO ────────────────────────────────────────┐
│  auth: { token: 'JWT_TOKEN' } (handshake)          │
│  socket/middleware/auth.js → socket.user = { id }  │
└─────────────────────────────────────────────────────┘

┌─ Admin Panel ──────────────────────────────────────┐
│  express-session + cookie                          │
│  req.session.admin = { id, username }              │
└─────────────────────────────────────────────────────┘

Token Yaşam Döngüsü:
  Access Token  → 15 dakika (JWT_EXPIRES_IN)
  Refresh Token → 7 gün (JWT_REFRESH_EXPIRES_IN)
  Yenileme: POST /api/auth/refresh { refreshToken }
```

---

## 3. Frontend Mimarisi (Flutter / Dart)

### 3.1 State Management — Riverpod

```
Provider Hiyerarşisi:
┌──────────────────────────────────────────────────────────┐
│  ProviderScope (main.dart)                               │
│  ├── authProvider (StateNotifierProvider<AuthNotifier>)   │
│  │   ├── apiClientProvider (Singleton)                   │
│  │   ├── authStorageProvider (FlutterSecureStorage)       │
│  │   └── socketServiceProvider (Singleton)               │
│  ├── settingsProvider (StateNotifierProvider)             │
│  ├── lobbyProvider (StateNotifierProvider)                │
│  ├── gameProvider (StateNotifierProvider) [autoDispose]   │
│  └── botGameProvider (StateNotifierProvider) [autoDispose]│
└──────────────────────────────────────────────────────────┘
```

### 3.2 Navigasyon — GoRouter

```dart
// Tüm route'lar: mobile/lib/app/routes.dart
/login          → LoginScreen        (public)
/register       → RegisterScreen     (public)
/lobby          → LobbyScreen        (protected)
/game           → GameScreen         (protected, extra: gameData)
/bot            → BotGameScreen      (protected, extra: difficulty)
/profile        → ProfileScreen      (protected, optional: userId)
/profile/:userId → ProfileScreen     (protected)
/leaderboard    → LeaderboardScreen  (protected)
/settings       → SettingsScreen     (protected)
/tutorial       → TutorialScreen     (protected)
/match-found    → MatchFoundScreen   (protected, extra: gameData)
```

### 3.3 Ağ Katmanı

```
┌─────────────────┐     ┌─────────────────────┐
│    ApiClient     │     │   SocketService      │
│  (Dio HTTP)      │     │  (socket_io_client)  │
├─────────────────┤     ├─────────────────────┤
│ Base: dart-define│     │ URL: dart-define      │
│ Prod varsayılan: │     │ Prod varsayılan:      │
│ tavla.berkecan...│     │ tavla.berkecan...     │
│ Public auth path │     │ JWT in handshake      │
│ skip token read  │     │ Event buffering       │
│ 401 → refresh    │     │ Auto-reconnect (10x)  │
└─────────────────┘     └─────────────────────┘
```

- `AppConfig.apiBaseUrl` ve `AppConfig.socketUrl` üretimde varsayılan olarak `https://tavla.berkecansakalar.com` kullanır
- Login/register/refresh istekleri public auth path sayılır; bu isteklerde Authorization header için secure storage okunmaz
- Auth provider, startup `checkAuth()` ile kullanıcı aksiyonları arasındaki yarış durumlarını operation ID ile engeller
- Auth HTTP çağrıları 15 saniyelik üst timeout ile korunur; cihaz tarafında request takılırsa sonsuz loading yerine hata state'i oluşur

---

## 4. Gerçek Zamanlı İletişim (Socket.IO)

### 4.1 Event Akışları

```
LOBBY AKIŞI:
  Client                    Server
    │ lobby:queue ──────────▶│ Kuyruğa ekle
    │                        │ Eşleşme kontrolü (5s interval)
    │◀──── lobby:queued ─────│
    │                        │ Eşleşme bulundu!
    │◀──── game:start ───────│ GameSnapshot gönder
    │                        │ game:${id} odasına katıl

OYUN AKIŞI:
  White                 Server                 Black
    │ game:rollDice ────▶│◀── game:rollDice ────│
    │◀─ game:diceRolled ─│── game:diceRolled ──▶│
    │ game:move ────────▶│                      │
    │◀─ game:moved ──────│── game:moved ───────▶│
    │ game:endTurn ─────▶│                      │
    │◀─ game:turnEnded ──│── game:turnEnded ───▶│
    │                    │                      │
    │ [15 taş kırılınca] │                      │
    │◀─ game:finished ───│── game:finished ────▶│+ ELO güncellemeleri

BOT AKIŞI (prefix: bot:):
  Client                    Server (In-Memory)
    │ bot:startGame ────────▶│ Oyun oluştur (DB'ye kaydetme)
    │◀── bot:gameStarted ───│
    │ bot:rollDice ─────────▶│
    │◀── bot:diceRolled ────│
    │ bot:move ─────────────▶│
    │◀── bot:moved ─────────│
    │                        │ Bot sırası → AI hamle seç
    │◀── bot:diceRolled ────│ (otomatik zar)
    │◀── bot:moved ─────────│ (1.5s + 1.2s gecikmeli)
```

### 4.2 Oyun State Machine

```
Durum Geçişleri:
  WAITING ──▶ INITIAL_ROLL ──▶ PLAYING ──▶ FINISHED
      │              │              │           ▲
      │              │              │           │
      └──────────────┴──── resign/timeout/disconnect
                                    │
                           turnPhase:
                           ROLLING → MOVING → (turn switch)
```

---

## 5. Veritabanı Mimarisi

```
┌─────────────┐     ┌─────────────┐     ┌──────────────┐
│   users      │────▶│   games      │────▶│  game_moves   │
│ (profil+ELO) │     │ (state+skor) │     │ (hamle geçmişi)│
└─────────────┘     └─────────────┘     └──────────────┘
       │                    │
       │                    │
       ▼                    ▼
┌─────────────┐     ┌──────────────┐     ┌──────────────┐
│   reports    │     │chat_messages  │     │  daily_stats  │
│ (şikayetler)│     │ (oyun içi)    │     │ (admin metrikleri)│
└─────────────┘     └──────────────┘     └──────────────┘
```

- **Connection Pool:** `pg` modülü, max 20 bağlantı, 30s idle timeout
- **Migrations:** `server/src/models/migrate.js` — DDL sorguları ile şema oluşturma
- **Seed:** `server/src/models/seed.js` — Admin kullanıcı oluşturma
- **ORM yok** — Doğrudan parametrik SQL sorguları (SQL injection korumalı)

---

## 6. Oyun In-Memory vs Persistent Data

```
IN-MEMORY (Socket handler'larda):
  ├── activeGames Map: gameId → GameState (canlı oyun nesnesi)
  ├── playerGames Map: playerId → gameId
  ├── matchmakingQueue Array: { socket, userId, elo, joinedAt }
  └── botGames Map: odaId → BotGameState

PERSISTENT (PostgreSQL):
  ├── Oyun bittiğinde → games tablosuna kaydet
  ├── Her tur sonunda → game_moves tablosuna kaydet
  ├── Chat mesajları → chat_messages tablosuna kaydet
  └── ELO değişiklikleri → users tablosunu güncelle
```

**Önemli:** Aktif oyunlar bellekte tutulur ve ayrıca **Redis'e persist** edilir (stateStore). Sunucu çökerse, yeniden başlatıldığında aktif oyunlar Redis'ten kurtarulabilir. Redis bağlanamıyorsa sadece bellek kullanılır (graceful fallback). Sadece bitmiş oyunlar veritabanına kaydedilir.

---

## 7. Güvenlik Mimarisi

```
KATMANLI GÜVENLİK:
┌─ Cloudflare ──────────────────────────────────────┐
│  DDoS koruması, SSL termination (Full Strict)     │
├─ Nginx ───────────────────────────────────────────┤
│  Rate limit: 30r/s API, 10r/s WS                 │
│  HSTS, X-Frame, X-XSS, Referrer-Policy           │
│  Gizli dosya erişim engeli (location ~ /\.)       │
├─ Express ─────────────────────────────────────────┤
│  Helmet, CORS, Rate limit: 100/15min, 20/15min   │
│  express-session (httpOnly, sameSite, secure)     │
│  Request ID (X-Request-ID), CSRF (admin forms)   │
├─ Socket.IO ───────────────────────────────────────┤
│  Token bucket rate limit (move:30/10s, chat:10)   │
│  Hamle verisi doğrulama (validateMoveData)        │
├─ Uygulama ────────────────────────────────────────┤
│  bcrypt (12 round), JWT (ayrı secret'lar)         │
│  Parametrik SQL (pg), input validation            │
│  AppError class (statusCode + type)               │
│  Structured logging (logger.js)                   │
├─ Docker ──────────────────────────────────────────┤
│  Non-root user (tavla:1001), 512M memory limit    │
│  DB + Redis portu dışarıya kapalı, bridge network  │
└───────────────────────────────────────────────────┘
```

---

## 8. Deployment Mimarisi

```
PRODUCTION (tavla.berkecansakalar.com):

Internet ──▶ Cloudflare (Proxy + SSL) ──▶ VPS Nginx (:443)
                                              │
                              ┌───────────────┤
                              ▼               ▼
                    /socket.io/ (WS)    /api/ & /admin/
                              │               │
                              ▼               ▼
                      tavla-prod-server (127.0.0.1:3005)
                              │
                        ┌─────┴─────┐
                        ▼           ▼
               tavla-prod-db   tavla-prod-redis
                PostgreSQL 16    Redis 7

DEVELOPMENT (localhost):
  docker-compose.dev.yml
    ├── tavla-db (:5436 → :5432)
    ├── tavla-redis (:6379)
    └── tavla-server (:3006 → :3000)

  Flutter: flutter run (localhost:3006'ya bağlanır)
```

---

## 9. Kritik Mimari Kararlar ve Gerekçeleri

| Karar | Gerekçe |
|-------|---------|
| **In-memory oyun state** | Düşük gecikme — her hamle DB'ye gitmez |
| **Saf JS oyun motoru** | DB bağımlılığı yok, unit test edilebilir |
| **Socket.IO** | WebSocket + fallback, oda desteği, otomatik yeniden bağlantı |
| **JWT + Refresh** | Stateless auth, kısa ömür access, uzun ömür refresh |
| **Riverpod** | Compile-time güvenlik, auto-dispose, test edilebilirlik |
| **GoRouter** | Deklaratif routing, deep linking, type-safe navigasyon |
| **PostgreSQL** | JSONB desteği (board_state), güvenilir ACID |
| **ORM yok** | Performans, tam SQL kontrolü, basitlik |
| **Nginx reverse proxy** | SSL termination, rate limiting, WebSocket upgrade |
| **Docker multi-stage** | Küçük image boyutu, güvenli production build |
