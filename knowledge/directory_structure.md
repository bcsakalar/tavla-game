# Tavla Online — Klasör Yapısı Rehberi

> **Son güncelleme:** 2026-03-17
> AI ajanları için tam referans — her klasör ve dosyanın ne işe yaradığı

---

## 1. Kök Dizin

```
tavla-online/
├── AGENTS.md                    # AI ajan giriş noktası — kurallar ve yönlendirmeler
├── MEMORY.md                    # Dinamik hafıza — aktif görevler, bilinen hatalar
├── .cursorrules                 # Cursor AI yapılandırması
├── .github/
│   └── copilot-instructions.md  # GitHub Copilot yapılandırması
├── README.md                    # Proje genel bakışı ve hızlı başlangıç
├── SERVER.md                    # VPS üretim dağıtım rehberi
├── knowledge/                   # AI ajanları için proje detay dosyaları
├── .agents/skills/              # Genel yazılım becerileri ve teknoloji kuralları
├── docs/                        # API, oyun kuralları, socket event dökümantasyonu
├── server/                      # Node.js backend uygulaması
├── mobile/                      # Flutter mobil uygulama
├── docker/                      # Geliştirme Docker yapılandırmaları
└── deploy/                      # Üretim Docker ve Nginx yapılandırmaları
```

---

## 2. Server (Backend) — `server/`

```
server/
├── Dockerfile                   # Multi-stage build (Node 20 Alpine, non-root user)
├── package.json                 # Bağımlılıklar ve npm script'leri
│
├── src/
│   ├── index.js                 # ⚡ ENTRY POINT — DB bağlantı testi + HTTP sunucusu başlatma
│   ├── app.js                   # Express uygulaması — middleware zinciri + route tanımları
│   │
│   ├── config/
│   │   ├── index.js             # 🔧 Environment değişkenleri (PORT, JWT, DB, Redis, Timer sabitleri)
│   │   ├── redis.js             # 🟥 Redis bağlantısı (ioredis, lazyConnect, graceful fallback)
│   │   └── constants.js         # 📌 Paylaşılan sabitler (ALLOWED_EMOJIS, RESULT_TYPES, limitler)
│   │
│   ├── middleware/
│   │   ├── auth.js              # 🔐 JWT doğrulama (Bearer token), token üretimi
│   │   ├── errorHandler.js      # ❌ Global hata yakalayıcı (statusCode + message + request ID)
│   │   ├── rateLimiter.js       # 🚦 Rate limit: 100/15dk genel, 20/15dk auth, 5/15dk admin login
│   │   ├── requestId.js         # 🆔 Her HTTP isteği için benzersiz UUID (X-Request-ID header)
│   │   └── csrf.js              # 🛡️ Admin panel CSRF koruması (session-based token)
│   │
│   ├── models/
│   │   ├── db.js                # 🗄️ PostgreSQL bağlantı pool'u (pg, max 20)
│   │   ├── migrate.js           # 📋 Veritabanı şema oluşturma (6 tablo + trigger + index)
│   │   └── seed.js              # 🌱 Seed data (admin kullanıcı: admin / ADMIN_PASSWORD env veya rastgele)
│   │
│   ├── services/
│   │   ├── userService.js       # 👤 Kullanıcı CRUD, auth, ELO güncelleme, leaderboard
│   │   └── gameService.js       # 🎮 Oyun CRUD, hamle kayıt, chat, günlük istatistik
│   │
│   ├── routes/
│   │   ├── api/
│   │   │   ├── auth.js          # POST /api/auth/register, /login, /refresh
│   │   │   ├── users.js         # GET/PATCH /api/users/me, GET /api/users/:id, /:id/games
│   │   │   ├── games.js         # GET /api/games/:id, /:id/moves, /:id/chat
│   │   │   └── leaderboard.js   # GET /api/leaderboard
│   │   └── admin/
│   │       └── index.js         # Admin dashboard, kullanıcı/oyun/rapor yönetimi (EJS)
│   │
│   ├── controllers/             # Route handler fonksiyonları (ince katman)
│   │   ├── authController.js    # Register, login, refresh logic
│   │   ├── userController.js    # Profile get/update, leaderboard
│   │   └── gameController.js    # Game details, moves, chat
│   │
│   ├── game/                    # 🎲 SAF JAVASCRIPT OYUN MOTORU (DB bağımlılığı yok)
│   │   ├── index.js             # Barrel export (tüm oyun modüllerini dışa aktarır)
│   │   ├── board.js             # Tahta oluşturma, klonlama, serileştirme (24 nokta)
│   │   ├── dice.js              # Zar atma (crypto.randomInt), çiftler, ilk oyuncu belirleme
│   │   ├── moves.js             # 🧠 HAMLE DOĞRULAMA MOTORU — kural uygulama
│   │   ├── engine.js            # Oyun state machine (WAITING→PLAYING→FINISHED)
│   │   ├── scoring.js           # ELO hesaplama (K=32, gammon 2x, backgammon 3x)
│   │   ├── bot.js               # AI hamle seçimi (Easy: rastgele, Medium: puanlı, Hard: pozisyonel)
│   │   └── stateStore.js        # 🟥 Redis oyun state persistence (save/load/delete, 4h TTL)
│   │
│   ├── socket/
│   │   ├── index.js             # Socket.IO sunucu başlatma ve handler bağlama
│   │   ├── middleware/
│   │   │   ├── auth.js          # WebSocket JWT doğrulama
│   │   │   └── rateLimiter.js   # 🚦 Socket event rate limiting (move:30/10s, chat:10/10s, emoji:20/10s)
│   │   └── handlers/
│   │       ├── lobby.js         # 🔍 Eşleşme kuyruğu, ELO bazlı matchmaking
│   │       ├── game.js          # 🎮 Canlı çok oyunculu — zar, hamle, chat, resign, reconnect
│   │       └── bot.js           # 🤖 Bot modu — AI ile pratik (DB'ye kaydetmez)
│   │
│   ├── utils/                   # Yardımcı fonksiyonlar
│   │   ├── logger.js            # 📝 Yapılandırılmış loglama (debug/info/warn/error, tag, timestamp)
│   │   └── AppError.js          # ❌ Özel hata sınıfı (message + statusCode + type)
│   │
│   └── views/                   # EJS şablonları (Admin Panel)
│       ├── admin/
│       │   ├── login.ejs        # Admin giriş sayfası
│       │   ├── dashboard.ejs    # Ana dashboard — istatistikler
│       │   ├── users.ejs        # Kullanıcı listesi + arama + ban
│       │   ├── games.ejs        # Oyun geçmişi (sayfalı)
│       │   └── reports.ejs      # Şikayet yönetimi
│       └── partials/
│           ├── layout.ejs       # Ortak HTML layout
│           └── footer.ejs       # Footer
│
├── public/                      # Statik dosyalar (admin panel CSS/JS/images)
│   ├── css/
│   ├── js/
│   └── images/
│
├── tests/
│   ├── unit/
│   │   ├── board.test.js        # Tahta oluşturma, klonlama, serileştirme testleri
│   │   ├── dice.test.js         # Zar adilliği, çiftler, ilk oyuncu testleri
│   │   ├── moves.test.js        # Hamle doğrulama, bar, bearing off testleri
│   │   ├── engine.test.js       # Oyun durumları, tur geçişi, sonuç tipleri testleri
│   │   ├── scoring.test.js      # ELO hesaplama, çarpanlar, tier testleri
│   │   ├── appError.test.js     # AppError sınıfı testleri
│   │   ├── constants.test.js    # Sabit değerler doğrulama testleri
│   │   ├── logger.test.js       # Yapılandırılmış loglama testleri
│   │   ├── csrf.test.js         # CSRF middleware testleri
│   │   ├── socketRateLimiter.test.js  # Socket rate limiter testleri
│   │   ├── validateMove.test.js # Hamle verisi doğrulama testleri
│   │   └── requestId.test.js    # Request ID middleware testleri
│   ├── integration/             # Entegrasyon testleri (mevcut değil)
│   └── fixtures/                # Test verileri
│
└── coverage/                    # Jest coverage raporları
    ├── lcov.info
    ├── clover.xml
    ├── coverage-final.json
    └── lcov-report/             # HTML coverage raporu
```

---

## 3. Mobile (Flutter) — `mobile/`

```
mobile/
├── pubspec.yaml                 # Bağımlılıklar ve asset tanımları
├── analysis_options.yaml        # Dart linting kuralları
├── README.md                    # Flutter başlangıç rehberi
│
├── lib/
│   ├── main.dart                # ⚡ ENTRY POINT — AudioManager init + ProviderScope
│   │
│   ├── app/
│   │   ├── app.dart             # MaterialApp.router yapılandırması + TavlaTheme
│   │   └── routes.dart          # GoRouter route tanımları (12 route)
│   │
│   ├── core/                    # 🔧 Temel altyapı servisleri
│   │   ├── config/
│   │   │   └── app_config.dart  # API/Socket URL'leri, timer sabitleri
│   │   ├── network/
│   │   │   ├── api_client.dart  # Dio HTTP istemcisi (auto-refresh, interceptor)
│   │   │   └── socket_service.dart # Socket.IO istemcisi (event buffering, reconnect)
│   │   ├── storage/
│   │   │   └── auth_storage.dart # FlutterSecureStorage (token saklama)
│   │   ├── theme/
│   │   │   └── tavla_theme.dart # Renk paleti, tipografi, widget stil tanımları
│   │   ├── audio/
│   │   │   └── audio_manager.dart # Ses efektleri yöneticisi (12 ses dosyası)
│   │   └── haptic/
│   │       └── haptic_helper.dart # Dokunsal geri bildirim (titreşim) yardımcısı
│   │
│   ├── features/                # 📦 Feature-based modüler yapı
│   │   ├── auth/
│   │   │   ├── providers/
│   │   │   │   └── auth_provider.dart # AuthNotifier (login, register, logout, checkAuth)
│   │   │   └── screens/
│   │   │       ├── login_screen.dart    # Giriş formu (identifier + password)
│   │   │       └── register_screen.dart # Kayıt formu (username, email, password, confirm)
│   │   │
│   │   ├── lobby/
│   │   │   ├── providers/
│   │   │   │   └── lobby_provider.dart # LobbyNotifier (queue, cancel, online count)
│   │   │   └── screens/
│   │   │       ├── lobby_screen.dart      # Ana lobi — rakip bulma, bot başlatma
│   │   │       └── match_found_screen.dart # Eşleşme bulundu animasyonu (2.5s)
│   │   │
│   │   ├── game/
│   │   │   ├── models/
│   │   │   │   └── game_state.dart  # BoardPoint, BoardState, GameSnapshot modelleri
│   │   │   ├── providers/
│   │   │   │   ├── game_provider.dart     # GameNotifier (hamle, zar, chat, timer)
│   │   │   │   └── bot_game_provider.dart # BotGameNotifier (AI oyun modu)
│   │   │   ├── screens/
│   │   │   │   ├── game_screen.dart       # Çok oyunculu oyun ekranı
│   │   │   │   └── bot_game_screen.dart   # Bot ile pratik ekranı
│   │   │   └── widgets/
│   │   │       ├── board_widget.dart    # 🎨 Tahta çizimi (24 nokta, taşlar, bar)
│   │   │       ├── dice_widget.dart     # 🎲 Zar animasyonu (döndürme + zıplama)
│   │   │       ├── piece_widget.dart    # ⚪ Taş widget'ı (3D metalik efekt)
│   │   │       └── timer_widget.dart    # ⏱️ Tur sayacı (yeşil→sarı→kırmızı)
│   │   │
│   │   ├── profile/
│   │   │   └── screens/
│   │   │       └── profile_screen.dart  # Kullanıcı profili (ELO, istatistik, tier)
│   │   │
│   │   ├── leaderboard/
│   │   │   └── screens/
│   │   │       └── leaderboard_screen.dart # Sıralama tablosu (top 50)
│   │   │
│   │   ├── settings/
│   │   │   ├── providers/
│   │   │   │   └── settings_provider.dart # Ayarlar (ses, titreşim, ipucu, nokta numaraları)
│   │   │   └── screens/
│   │   │       └── settings_screen.dart   # Ayarlar UI (toggle switch'ler)
│   │   │
│   │   └── tutorial/
│   │       └── screens/
│   │           └── tutorial_screen.dart # 10 sayfalık interaktif öğretici
│   │
│   └── shared/                  # Paylaşılan modeller
│       └── models/
│           └── user.dart        # User modeli (id, username, elo, stats, tier)
│
├── test/
│   └── widget_test.dart         # Placeholder test (henüz oyun testleri yok)
│
├── assets/
│   ├── sounds/                  # Ses efekti dosyaları (.mp3)
│   └── images/                  # Görsel dosyalar
│
├── android/                     # Android platform yapılandırması
├── web/                         # Web platform (debug/build çıktısı)
└── build/                       # Build artefaktları (gitignore'da olmalı)
```

---

## 4. Docker & DevOps — `docker/` ve `deploy/`

```
docker/                          # 🔧 GELİŞTİRME ortamı
├── docker-compose.yml           # Base compose (PostgreSQL + Server + Redis + Nginx)
├── docker-compose.dev.yml       # Dev override (:5436, :3006, CORS_ORIGIN=*, Redis)
└── nginx/
    └── nginx.conf               # Dev nginx (WS upgrade, basit proxy)

deploy/                          # 🚀 ÜRETİM ortamı
├── docker-compose.prod.yml      # Prod compose (güvenlik sertleştirilmiş, memory limit, Redis)
└── nginx/
    └── tavla.berkecansakalar.com.conf  # Prod nginx (SSL, rate limit, Cloudflare IP)
```

---

## 5. Dokümantasyon — `docs/`

```
docs/
├── API.md                       # REST API endpoint referansı (tüm path'ler, body, response)
├── GAME_RULES.md                # Tavla kuralları (Türkçe, ELO formülleri dahil)
└── SOCKET_EVENTS.md             # Socket.IO event kataloğu (lobby, game, bot)
```

---

## 6. Dosya Oluşturma Kuralları

Yeni dosya eklerken bu yapıyı takip et:

| Eklenecek Şey | Backend Yolu | Frontend Yolu |
|----------------|-------------|---------------|
| **Yeni API route** | `server/src/routes/api/{resource}.js` | — |
| **Yeni controller** | `server/src/controllers/{resource}Controller.js` | — |
| **Yeni service** | `server/src/services/{resource}Service.js` | — |
| **Yeni middleware** | `server/src/middleware/{name}.js` | — |
| **Yeni oyun modülü** | `server/src/game/{module}.js` | — |
| **Yeni socket handler** | `server/src/socket/handlers/{name}.js` | — |
| **Yeni unit test** | `server/tests/unit/{module}.test.js` | `mobile/test/{module}_test.dart` |
| **Yeni integration test** | `server/tests/integration/{name}.test.js` | — |
| **Yeni feature** | — | `mobile/lib/features/{feature}/` |
| **Yeni provider** | — | `mobile/lib/features/{feature}/providers/{name}_provider.dart` |
| **Yeni screen** | — | `mobile/lib/features/{feature}/screens/{name}_screen.dart` |
| **Yeni widget** | — | `mobile/lib/features/{feature}/widgets/{name}_widget.dart` |
| **Yeni model** | — | `mobile/lib/features/{feature}/models/{name}.dart` |
| **Yeni core servis** | — | `mobile/lib/core/{category}/{name}.dart` |
