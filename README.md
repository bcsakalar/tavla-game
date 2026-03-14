# 🎲 Tavla Online — Real-Time Multiplayer Backgammon

<div align="center">

**Gerçek zamanlı çevrimiçi Tavla (Backgammon) oyunu**

Klasik tavla deneyimini modern teknoloji ile buluşturan, ELO puan sistemi, otomatik eşleştirme, bot modu ve admin paneli içeren tam donanımlı bir oyun platformu.

[![Node.js](https://img.shields.io/badge/Node.js-20+-339933?logo=node.js&logoColor=white)](https://nodejs.org/)
[![Flutter](https://img.shields.io/badge/Flutter-3.16+-02569B?logo=flutter&logoColor=white)](https://flutter.dev/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16-4169E1?logo=postgresql&logoColor=white)](https://www.postgresql.org/)
[![Socket.IO](https://img.shields.io/badge/Socket.IO-4.8-010101?logo=socket.io&logoColor=white)](https://socket.io/)
[![Docker](https://img.shields.io/badge/Docker-Compose-2496ED?logo=docker&logoColor=white)](https://www.docker.com/)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

</div>

---

## 📋 İçindekiler

- [Genel Bakış](#-genel-bakış)
- [Teknoloji Yığını](#-teknoloji-yığını)
- [Mimari](#-mimari)
- [Özellikler](#-özellikler)
- [Oyun Kuralları ve Motor](#-oyun-kuralları-ve-motor)
- [Hızlı Başlangıç](#-hızlı-başlangıç)
- [API Dokümantasyonu](#-api-dokümantasyonu)
- [Socket Olayları](#-socket-olayları)
- [Veritabanı Şeması](#-veritabanı-şeması)
- [ELO Derecelendirme Sistemi](#-elo-derecelendirme-sistemi)
- [Proje Yapısı](#-proje-yapısı)
- [Test](#-test)
- [Deployment](#-deployment)
- [Ekran Görüntüleri](#-ekran-görüntüleri)
- [Katkıda Bulunma](#-katkıda-bulunma)

---

## 🌟 Genel Bakış

Tavla Online, klasik Türk tavla oyununu çevrimiçi ortama taşıyan full-stack bir projedir. Backend Node.js/Express ile REST API ve Socket.IO gerçek zamanlı iletişim sunarken, mobil tarafta Flutter ile cross-platform (Android, iOS, Web) deneyim sağlar.

### Temel Bileşenler

| Bileşen | Açıklama |
|---------|----------|
| **Game Engine** | Sunucu taraflı saf JavaScript tavla motoru — tam kural doğrulama |
| **REST API** | Kullanıcı yönetimi, oyun geçmişi, liderlik tablosu |
| **WebSocket** | Gerçek zamanlı oyun olayları, sohbet, eşleştirme |
| **Flutter App** | Riverpod state management, animasyonlu UI, çoklu platform |
| **Admin Panel** | Bootstrap 5 + EJS server-rendered dashboard |
| **Bot AI** | Easy/Medium/Hard zorluk seviyeli yapay zeka rakip |

---

## 🛠 Teknoloji Yığını

### Backend
| Teknoloji | Versiyon | Amaç |
|-----------|----------|------|
| **Node.js** | 20+ | Runtime |
| **Express.js** | 4.21 | REST API framework |
| **Socket.IO** | 4.8 | Gerçek zamanlı WebSocket iletişim |
| **PostgreSQL** | 16 | İlişkisel veritabanı |
| **node-postgres (pg)** | 8.13 | Veritabanı driver |
| **JWT** | 9.0 | Token tabanlı kimlik doğrulama |
| **bcrypt** | 5.1 | Şifre hashleme (12 round) |
| **Helmet** | 7.1 | HTTP güvenlik başlıkları |
| **express-rate-limit** | 7.4 | Rate limiting |
| **EJS** | 3.1 | Admin panel şablon motoru |
| **Jest + Supertest** | 29.7 | Unit ve integration testler |

### Mobil (Flutter)
| Teknoloji | Versiyon | Amaç |
|-----------|----------|------|
| **Flutter** | 3.16+ | Cross-platform mobil framework |
| **Dart** | 3.2+ | Programlama dili |
| **Riverpod** | 2.5 | State management |
| **Dio** | 5.4 | HTTP client + interceptors |
| **Socket.IO Client** | 2.0 | WebSocket client |
| **GoRouter** | 14.2 | Deklaratif routing |
| **Flutter Secure Storage** | 9.2 | Encrypted token depolama |
| **Audioplayers** | 6.0 | Ses efektleri |
| **Google Fonts** | 6.2 | Noto Serif tipografi |

### Altyapı
| Teknoloji | Amaç |
|-----------|------|
| **Docker** | Konteynerizasyon (multi-stage build) |
| **Docker Compose** | Servis orkestrasyonu |
| **Nginx** | Reverse proxy + WebSocket desteği |

---

## 🏛 Mimari

```
┌─────────────────────────────────────────────────────────┐
│                    Flutter Mobile App                     │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌─────────┐ │
│  │   Auth    │  │   Game   │  │  Lobby   │  │ Profile │ │
│  │  Screen   │  │  Screen  │  │  Screen  │  │ Screen  │ │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬────┘ │
│       │              │              │              │      │
│  ┌────┴──────────────┴──────────────┴──────────────┴───┐ │
│  │              Riverpod Providers                      │ │
│  │   AuthProvider │ GameProvider │ LobbyProvider         │ │
│  └────────────────┬─────────────┬───────────────────────┘ │
│              ┌────┴────┐   ┌────┴────┐                    │
│              │   Dio   │   │Socket.IO│                    │
│              │  Client │   │  Client │                    │
│              └────┬────┘   └────┬────┘                    │
└───────────────────┼─────────────┼────────────────────────┘
                    │  HTTP/WS    │
┌───────────────────┼─────────────┼────────────────────────┐
│                   ▼             ▼         Nginx           │
│              ┌─────────────────────────┐                  │
│              │     Express + Socket.IO │                  │
│              │         (Port 3000)     │                  │
│              └────┬───────────┬────────┘                  │
│   ┌───────────────┤           ├────────────────┐          │
│   ▼               ▼           ▼                ▼          │
│ ┌──────┐   ┌───────────┐  ┌────────┐   ┌────────────┐   │
│ │Routes│   │Game Engine│  │Services│   │ Middleware  │   │
│ │ API  │   │  Board    │  │  User  │   │  Auth/JWT  │   │
│ │Admin │   │  Moves    │  │  Game  │   │  RateLimit │   │
│ └──┬───┘   │  Dice     │  └───┬────┘   │  Error     │   │
│    │       │  Scoring  │      │        └────────────┘   │
│    │       │  Bot AI   │      │                          │
│    │       └───────────┘      │                          │
│    └──────────────────────────┘                          │
│                    │                                      │
│              ┌─────▼─────┐                                │
│              │ PostgreSQL │                                │
│              │   (pg)     │                                │
│              └───────────┘                                │
└──────────────────────────────────────────────────────────┘
```

### Katmanlı Mimari (Backend)

```
Routes → Controllers/Handlers → Services → Database (pg)
                                    ↕
                              Game Engine (pure logic)
```

- **Routes**: HTTP endpoint tanımları (`/api/auth`, `/api/users`, `/api/games`, `/api/leaderboard`, `/admin`)
- **Middleware**: JWT doğrulama, rate limiting, hata yönetimi
- **Services**: İş mantığı katmanı (`userService`, `gameService`)
- **Game Engine**: Saf JavaScript oyun motoru (state machine, hareket doğrulama, skor hesaplama)
- **Socket Handlers**: Gerçek zamanlı olay işleyicileri (lobby, game, bot)

### Feature-Based Mimari (Flutter)

```
lib/
├── app/          → MaterialApp.router, GoRouter route definitions
├── core/         → Yatay paylaşılan altyapı (network, storage, theme, audio)
├── features/     → Dikey feature modülleri (auth, game, lobby, profile, vb.)
└── shared/       → Paylaşılan modeller ve widgetlar
```

---

## ✨ Özellikler

### 🎮 Oyun
- **Tam Kural Uyumu** — Bar, bearing off, gammon/backgammon, çift zar (4 hamle)
- **Sunucu Taraflı Doğrulama** — Tüm hamle ve zar kontrolü sunucuda yapılır
- **Güvenli Zar** — `crypto.randomInt()` ile kriptografik olarak güvenli rastgele sayı üretimi
- **Oyun Tekrarı** — Tüm hamleler `game_moves` tablosunda saklanır
- **Hamle Geri Alma** — Tur içinde hamle geri alma desteği
- **Bot Modu** — Easy / Medium / Hard zorluk seviyeli yapay zeka

### ⚡ Gerçek Zamanlı
- **Socket.IO WebSocket** — Düşük gecikme süreli çok oyunculu deneyim
- **Matchmaking** — ELO tabanlı otomatik eşleştirme (±200 başlangıç, 30s sonra ±400)
- **Oyun İçi Sohbet** — Anlık mesajlaşma (500 karakter limit)
- **Emoji Reaksiyonları** — Oyuncu emoji tepkileri
- **Bağlantı Kopma Koruması** — 60 saniyelik yeniden bağlanma penceresi
- **Sıra Zamanlayıcısı** — Hamle başına 60 saniye, 10s kritik uyarı

### 📊 Derecelendirme ve İstatistik
- **ELO Puan Sistemi** — K=32, gammon 2x, backgammon 3x çarpanları
- **Liderlik Tablosu** — Top 50 oyuncu sıralaması (paginated)
- **Oyuncu Profili** — Detaylı istatistikler (wins, losses, gammons, backgammons)
- **Rating Tier'ları** — Novice → Beginner → Intermediate → Advanced → Expert → Master → Grandmaster

### 🔐 Güvenlik
- **JWT Authentication** — 15 dakikalık access token + 7 günlük refresh token
- **bcrypt** — 12 round şifre hashleme
- **Helmet.js** — HTTP güvenlik başlıkları
- **Rate Limiting** — API: 100 req/15min, Auth: 20 req/15min
- **Input Validation** — Tüm girdiler sunucu tarafında doğrulanır

### 🛡 Admin Panel
- **Dashboard** — Genel istatistikler ve günlük oyun sayıları
- **Kullanıcı Yönetimi** — Kullanıcı arama, profil görüntüleme
- **Rapor Sistemi** — Oyuncu raporları yönetimi
- **Session Tabanlı Auth** — `express-session` + `connect-pg-simple`

### 📱 Mobil (Flutter)
- **Cross-Platform** — Android, iOS, Web desteği
- **Animasyonlu UI** — Zar animasyonu, zamanlayıcı efektleri, emoji overlay
- **Ses Efektleri** — Zar, hamle, hit, bear-off, chat, maç bulma sesleri
- **Haptic Feedback** — Dokunsal geri bildirim desteği
- **Güvenli Depolama** — Tokenlar şifreli depolanır (Flutter Secure Storage)
- **Tutorial** — 10 adımlık interaktif öğretici (Türkçe)
- **Tema** — Material 3, özel tavla renk paleti

---

## 🎯 Oyun Kuralları ve Motor

### Tahta Düzeni
- **24 puan** (point), her oyuncu **15 taş**
- **Beyaz (White)**: 24→1 yönünde hareket (yüksek indeksten düşüğe)
- **Siyah (Black)**: 1→24 yönünde hareket (düşük indeksten yükseğe)

### Başlangıç Pozisyonu
```
Beyaz: [24:2, 13:5, 8:3, 6:5]
Siyah: [1:2, 12:5, 17:3, 19:5]
```

### Hamle Kuralları
| Kural | Açıklama |
|-------|----------|
| **Bar Önceliği** | Bar'daki taşlar önce sahaya girmeli |
| **Hedef Nokta** | Boş, kendi taşı, veya tek rakip taşı olan noktaya gidilebilir |
| **Vurma (Hit)** | Tek rakip taşı olan noktaya gidildiğinde rakip bar'a gider |
| **Çift Zar** | Çift gelirse 4 hamle yapılır |
| **Zar Kullanımı** | İki zar da kullanılmalı; sadece biri yapılabiliyorsa büyük zar kullanılır |
| **Kırma (Bear Off)** | Tüm 15 taş iç sahaya geldikten sonra kırma başlar |
| **Kırma Kuralı** | Tam eşleşme veya en yüksek noktadan büyük zar ile kırma |

### Oyun Akışı (State Machine)
```
WAITING → INITIAL_ROLL → PLAYING → FINISHED
                           │
                     ROLLING → MOVING → (sonraki tur veya bitiş)
```

### Kazanma Türleri

| Tür | Türkçe | Açıklama | ELO Çarpanı |
|-----|--------|----------|-------------|
| **Normal** | Normal | Rakip en az 1 taş kırmış | 1x |
| **Gammon** | Mars | Rakip hiç taş kırmamış | 2x |
| **Backgammon** | Kara Mars | Rakip taş kırmamış + taşları bar'da veya iç sahada | 3x |
| **Resign** | Teslim | Oyuncu teslim olmuş | 1x |
| **Timeout** | Zaman Aşımı | Hamle süresi dolmuş | 1x |
| **Disconnect** | Bağlantı Kopma | 60s içinde geri bağlanmamış | 1x |

---

## 🚀 Hızlı Başlangıç

### Gereksinimler
- **Node.js** 20+
- **Docker** & **Docker Compose**
- **Flutter** 3.16+ (mobil uygulama için)
- **Git**

### 1. Depoyu Klonla
```bash
git clone https://github.com/bcsakalar/tavla-game.git
cd tavla-game
```

### 2. Ortam Değişkenlerini Ayarla

**Docker için:**
```bash
cp docker/.env.example docker/.env
# docker/.env dosyasını düzenle — güçlü parolalar gir
```

**Server için (Docker kullanmadan geliştirme):**
```bash
cp server/.env.example server/.env
# server/.env dosyasını düzenle
```

### 3. Docker ile Başlat (Önerilen)
```bash
cd docker
docker compose -f docker-compose.dev.yml up --build -d
```

Bu komut:
- PostgreSQL 16 veritabanını başlatır (port 5436)
- Node.js sunucusunu derleyip çalıştırır (port 3006)

### 4. Veritabanını Hazırla
```bash
# Tabloları oluştur
docker exec tavla-server node src/models/migrate.js

# Admin kullanıcıyı oluştur
docker exec tavla-server node src/models/seed.js
```

### 5. Flutter Uygulamasını Çalıştır
```bash
cd mobile
flutter pub get
flutter run
```

> **Not:** `lib/core/config/app_config.dart` dosyasında API URL'sini kendi ortamınıza göre ayarlayın.

### 6. Admin Paneli
Tarayıcıda `http://localhost:3006/admin` adresine gidin.
- **Kullanıcı:** `admin`
- **Şifre:** `admin123456`

> ⚠️ Production'da admin şifresini mutlaka değiştirin.

---

## 📡 API Dokümantasyonu

### Kimlik Doğrulama (Auth)
| Method | Endpoint | Açıklama | Auth |
|--------|----------|----------|------|
| `POST` | `/api/auth/register` | Yeni kullanıcı kaydı | ❌ |
| `POST` | `/api/auth/login` | Giriş (username/email + password) | ❌ |
| `POST` | `/api/auth/refresh` | Token yenileme | 🔄 Refresh Token |

### Kullanıcılar
| Method | Endpoint | Açıklama | Auth |
|--------|----------|----------|------|
| `GET` | `/api/users/me` | Kendi profilim | ✅ JWT |
| `PATCH` | `/api/users/me` | Profil güncelle (avatar) | ✅ JWT |
| `GET` | `/api/users/:id` | Kullanıcı profili | ❌ |
| `GET` | `/api/users/:id/games` | Oyun geçmişi (paginated) | ❌ |

### Oyunlar
| Method | Endpoint | Açıklama | Auth |
|--------|----------|----------|------|
| `GET` | `/api/games/:id` | Oyun detayları | ❌ |
| `GET` | `/api/games/:id/moves` | Hamle geçmişi (replay) | ❌ |
| `GET` | `/api/games/:id/chat` | Sohbet mesajları | ✅ JWT |

### Liderlik Tablosu
| Method | Endpoint | Açıklama | Auth |
|--------|----------|----------|------|
| `GET` | `/api/leaderboard` | Top oyuncular (limit, offset) | ❌ |

> Detaylı API dokümantasyonu için: [docs/API.md](docs/API.md)

---

## 🔌 Socket Olayları

### Lobi / Eşleştirme

**Client → Server:**
| Olay | Açıklama |
|------|----------|
| `lobby:queue` | Eşleştirme kuyruğuna katıl |
| `lobby:cancel` | Kuyruktan çık |
| `lobby:online` | Çevrimiçi oyuncu sayısı iste |

**Server → Client:**
| Olay | Payload | Açıklama |
|------|---------|----------|
| `lobby:queued` | `{ message }` | Kuyrukta onaylandı |
| `lobby:cancelled` | `{ message }` | Kuyruktan çıkıldı |
| `lobby:onlineCount` | `{ count }` | Çevrimiçi oyuncu sayısı |
| `game:start` | `GameSnapshot` | Maç bulundu, oyun başlıyor |

### Oyun İçi

**Client → Server:**
| Olay | Payload | Açıklama |
|------|---------|----------|
| `game:rollDice` | — | Zar at |
| `game:move` | `{ from, to, dieValue }` | Taş hamle et |
| `game:undoMove` | — | Son hamleyi geri al |
| `game:endTurn` | — | Sırayı bitir |
| `game:resign` | — | Teslim ol |
| `game:chat` | `{ message }` | Sohbet mesajı gönder |
| `game:reconnect` | — | Yeniden bağlan |

**Server → Client:**
| Olay | Payload | Açıklama |
|------|---------|----------|
| `game:diceRolled` | `{ dice, autoSkip, snapshot }` | Zar sonucu |
| `game:moved` | `{ move, turnOver, snapshot }` | Hamle yapıldı |
| `game:turnChanged` | `GameSnapshot` | Sıra değişti |
| `game:ended` | `{ winnerId, resultType, eloChange }` | Oyun bitti |
| `game:error` | `{ message }` | Hata bildirimi |
| `game:opponentDisconnected` | `{ reconnectWindow }` | Rakip bağlantısı koptu |
| `game:opponentReconnected` | `{ message }` | Rakip geri bağlandı |

> Detaylı socket dokümantasyonu için: [docs/SOCKET_EVENTS.md](docs/SOCKET_EVENTS.md)

---

## 🗃 Veritabanı Şeması

```sql
┌─────────────┐     ┌─────────────┐     ┌──────────────┐
│    users     │     │    games     │     │  game_moves  │
├─────────────┤     ├─────────────┤     ├──────────────┤
│ id (PK)     │◄──┐ │ id (PK)     │◄──┐ │ id (PK)      │
│ username    │   ├─│ white_player│   │ │ game_id (FK) │
│ email       │   ├─│ black_player│   │ │ user_id (FK) │
│ password_   │   │ │ status      │   │ │ move_number  │
│   hash      │   │ │ winner_id   │   │ │ dice_values  │
│ elo_rating  │   │ │ result_type │   │ │ moves (JSONB)│
│ total_wins  │   │ │ board_state │   │ │ board_after  │
│ total_losses│   │ │ current_turn│   │ │ created_at   │
│ total_draws │   │ │ elo_change_ │   │ └──────────────┘
│ total_      │   │ │   white/blk │   │
│   gammons   │   │ │ total_moves │   │ ┌──────────────┐
│ total_back- │   │ │ started_at  │   │ │chat_messages │
│   gammons   │   │ │ finished_at │   │ ├──────────────┤
│ is_online   │   │ └─────────────┘   ├─│ game_id (FK) │
│ is_banned   │   │                    │ │ user_id (FK) │
│ role        │   │ ┌─────────────┐   │ │ message      │
│ last_login  │   │ │   reports   │   │ │ is_system    │
│ created_at  │   │ ├─────────────┤   │ │ created_at   │
│ updated_at  │   ├─│ reporter_id │   │ └──────────────┘
└─────────────┘   ├─│ reported_id │   │
                  │ │ game_id (FK)│───┘ ┌──────────────┐
                  │ │ reason      │     │ daily_stats  │
                  │ │ status      │     ├──────────────┤
                  │ │ admin_note  │     │ date (UNIQUE)│
                  │ └─────────────┘     │ total_games  │
                  │                     │ total_new_   │
                  │                     │   users      │
                  └─────────────────────│ peak_        │
                                        │   concurrent │
                                        └──────────────┘
```

### Tablolar Özeti

| Tablo | Açıklama |
|-------|----------|
| `users` | Oyuncu bilgileri, ELO, istatistikler, roller |
| `games` | Oyun kayıtları, tahta durumu, sonuçlar |
| `game_moves` | Hamle geçmişi (replay için JSONB) |
| `chat_messages` | Oyun içi sohbet mesajları |
| `reports` | Oyuncu raporları / şikayetler |
| `daily_stats` | Günlük platform istatistikleri |

---

## 📈 ELO Derecelendirme Sistemi

### Formül
```
Beklenen Skor: E(A) = 1 / (1 + 10^((Rb - Ra) / 400))
ELO Değişimi:  ΔR = K × (S - E) × Çarpan
```

### Parametreler
| Parametre | Değer |
|-----------|-------|
| **K-Faktör** | 32 |
| **Başlangıç ELO** | 1200 |
| **Minimum ELO** | 100 |

### Kazanma Çarpanları
| Tür | Çarpan |
|-----|--------|
| Normal | 1x |
| Mars (Gammon) | 2x |
| Kara Mars (Backgammon) | 3x |
| Teslim / Timeout / Disconnect | 1x |

### Rating Tier'ları
| Tier | ELO Aralığı |
|------|-------------|
| 🟤 Novice | < 1200 |
| 🟢 Beginner | 1200 – 1399 |
| 🔵 Intermediate | 1400 – 1599 |
| 🟣 Advanced | 1600 – 1799 |
| 🟠 Expert | 1800 – 1999 |
| 🔴 Master | 2000 – 2199 |
| 👑 Grandmaster | 2200+ |

---

## 📁 Proje Yapısı

```
tavla-game/
│
├── server/                          # 🖥  Node.js Backend
│   ├── src/
│   │   ├── app.js                   # Express + Socket.IO kurulumu
│   │   ├── index.js                 # Sunucu giriş noktası
│   │   ├── config/
│   │   │   └── index.js             # Ortam değişkenleri yapılandırma
│   │   ├── middleware/
│   │   │   ├── auth.js              # JWT doğrulama, token üretimi
│   │   │   ├── rateLimiter.js       # İstek hız sınırlama
│   │   │   └── errorHandler.js      # Merkezi hata yakalama
│   │   ├── models/
│   │   │   ├── db.js                # PostgreSQL bağlantı havuzu
│   │   │   ├── migrate.js           # Veritabanı şeması oluşturma
│   │   │   └── seed.js              # Admin kullanıcı oluşturma
│   │   ├── services/
│   │   │   ├── userService.js       # Kullanıcı iş mantığı
│   │   │   └── gameService.js       # Oyun CRUD işlemleri
│   │   ├── game/                    # 🎲 Tavla Oyun Motoru
│   │   │   ├── engine.js            # Oyun state machine
│   │   │   ├── board.js             # Tahta durumu ve doğrulama
│   │   │   ├── moves.js             # Hamle doğrulama ve sıralama
│   │   │   ├── dice.js              # Kriptografik zar (crypto.randomInt)
│   │   │   ├── scoring.js           # ELO hesaplama
│   │   │   └── bot.js               # Yapay zeka rakip
│   │   ├── routes/
│   │   │   ├── api/                 # REST API rotaları
│   │   │   │   ├── auth.js          # /api/auth/*
│   │   │   │   ├── users.js         # /api/users/*
│   │   │   │   ├── games.js         # /api/games/*
│   │   │   │   └── leaderboard.js   # /api/leaderboard
│   │   │   └── admin/
│   │   │       └── index.js         # Admin panel rotaları
│   │   ├── socket/
│   │   │   ├── index.js             # Socket.IO başlatma
│   │   │   ├── middleware/
│   │   │   │   └── auth.js          # Socket JWT doğrulama
│   │   │   └── handlers/
│   │   │       ├── lobby.js         # Eşleştirme kuyruğu
│   │   │       ├── game.js          # Oyun olayları
│   │   │       └── bot.js           # Bot oyun olayları
│   │   └── views/                   # EJS admin şablonları
│   ├── tests/                       # Jest test dosyaları
│   ├── public/                      # Statik dosyalar (admin CSS/JS)
│   ├── Dockerfile                   # Multi-stage Docker build
│   ├── package.json
│   └── .env.example                 # Ortam değişkenleri şablonu
│
├── mobile/                          # 📱 Flutter Mobil Uygulama
│   ├── lib/
│   │   ├── main.dart                # Uygulama giriş noktası
│   │   ├── app/
│   │   │   ├── app.dart             # MaterialApp.router yapılandırma
│   │   │   └── routes.dart          # GoRouter rota tanımları
│   │   ├── core/
│   │   │   ├── config/              # API URL, zamanlayıcı ayarları
│   │   │   ├── network/             # Dio HTTP + Socket.IO client
│   │   │   ├── storage/             # Flutter Secure Storage (tokenlar)
│   │   │   ├── theme/               # Material 3 tema, renk paleti
│   │   │   ├── audio/               # Ses efektleri yönetimi
│   │   │   └── haptic/              # Dokunsal geri bildirim
│   │   ├── features/
│   │   │   ├── auth/                # Giriş / Kayıt ekranları
│   │   │   ├── game/                # Oyun tahtası, zar, hamleler
│   │   │   ├── lobby/               # Eşleştirme bekleme ekranı
│   │   │   ├── leaderboard/         # Liderlik tablosu
│   │   │   ├── profile/             # Oyuncu profili
│   │   │   ├── settings/            # Uygulama ayarları
│   │   │   └── tutorial/            # 10 adımlık öğretici
│   │   └── shared/
│   │       └── models/              # User modeli
│   ├── assets/
│   │   ├── images/                  # Oyun görselleri
│   │   └── sounds/                  # Ses dosyaları
│   ├── pubspec.yaml
│   └── analysis_options.yaml
│
├── docker/                          # 🐳 Docker Yapılandırma
│   ├── docker-compose.yml           # Production compose
│   ├── docker-compose.dev.yml       # Development compose
│   ├── .env.example                 # Docker ortam değişkenleri
│   └── nginx/
│       └── nginx.conf               # Reverse proxy (WebSocket desteği)
│
├── docs/                            # 📖 Dokümantasyon
│   ├── API.md                       # API endpoint detayları
│   ├── GAME_RULES.md                # Oyun kuralları
│   └── SOCKET_EVENTS.md             # Socket olay referansı
│
├── .gitignore
└── README.md                        # ← Bu dosya
```

---

## 🧪 Test

### Backend Testleri
```bash
cd server

# Tüm testleri çalıştır
npm test

# Coverage raporu ile
npm run test:coverage

# Watch modunda
npm run test:watch
```

**Test kapsamı:**
- **Unit testler**: Oyun motoru (board, moves, dice, scoring, engine)
- **Integration testler**: API endpoint'leri (auth, users, games, leaderboard)
- **Test framework**: Jest + Supertest + fixtures

---

## 🐳 Deployment

### Docker ile Production

```bash
# Ortam değişkenlerini ayarla
cp docker/.env.example docker/.env
# docker/.env dosyasını production değerlerle güncelle

# Production'ı başlat
cd docker
docker compose up --build -d

# Veritabanını hazırla
docker exec tavla-server node src/models/migrate.js
docker exec tavla-server node src/models/seed.js
```

### Servisler

| Servis | Port | Açıklama |
|--------|------|----------|
| **Nginx** | 80 | Reverse proxy + WebSocket |
| **Server** | 3000 (internal) | Express + Socket.IO |
| **PostgreSQL** | 5432 (internal) | Veritabanı |

### Production Checklist

- [ ] `.env` dosyasında güçlü, rastgele secret'lar kullanın
- [ ] Admin şifresini `admin123456`'dan değiştirin
- [ ] `CORS_ORIGIN`'i gerçek domain ile sınırlayın
- [ ] HTTPS (SSL/TLS) yapılandırın
- [ ] Veritabanı backup stratejisi oluşturun
- [ ] Log toplama sistemi kurun

---

## 🤝 Katkıda Bulunma

1. Fork yapın
2. Feature branch oluşturun (`git checkout -b feature/yeni-ozellik`)
3. Commit atın (`git commit -m 'feat: yeni özellik eklendi'`)
4. Branch'inizi push edin (`git push origin feature/yeni-ozellik`)
5. Pull Request açın

---

## 📄 Lisans

Bu proje [MIT Lisansı](LICENSE) ile lisanslanmıştır.

---

<div align="center">

**Tavla Online** ile klasik tavla deneyimini çevrimiçi yaşayın! 🎲

Made with ❤️ by [bcsakalar](https://github.com/bcsakalar)

</div>
│   ├── docker-compose.yml   # Üretim
│   ├── docker-compose.dev.yml # Geliştirme
│   └── nginx/nginx.conf     # Reverse proxy
│
├── .github/workflows/       # CI/CD
│   ├── server-ci.yml
│   ├── mobile-ci.yml
│   └── deploy.yml
│
└── docs/                    # Belgeler
    ├── API.md
    ├── SOCKET_EVENTS.md
    └── GAME_RULES.md
```

## Testler

```bash
cd server
npm test              # Tüm testleri çalıştır
npm test -- --coverage # Kapsam raporu ile
```

75 birim testi: board, dice, moves, engine, scoring modülleri.

## Docker ile Üretim Dağıtımı

```bash
cd docker
docker compose up -d --build
```

Bu komut PostgreSQL + Node.js sunucu + Nginx reverse proxy'yi başlatır.

## Lisans

MIT
