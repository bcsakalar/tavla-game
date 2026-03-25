# Tavla Online — Test Stratejisi

> **Son güncelleme:** 2026-03-24
> **KRİTİK:** Bu projede yazılan veya değiştirilen her kod (en küçük bir util fonksiyonu bile olsa) ilgili test senaryolarıyla birlikte teslim edilmeli ve mevcut testlerin bozulmadığından emin olunmalıdır.

---

## 1. Test Altyapısı Özeti

| Platform | Framework | Konum | Komut |
|----------|-----------|-------|-------|
| **Server** | Jest 29.7 | `server/tests/` | `cd server && npm test` |
| **Flutter** | flutter_test | `mobile/test/` | `cd mobile && flutter test` |

### 1.1 Server Test Yapılandırması

```json
// server/package.json
{
  "scripts": {
    "test": "jest --coverage --forceExit --detectOpenHandles",
    "test:watch": "jest --watch",
    "test:unit": "jest tests/unit/"
  },
  "jest": {
    "testEnvironment": "node",
    "coverageDirectory": "coverage",
    "collectCoverageFrom": ["src/**/*.js", "!src/index.js", "!src/views/**"]
  }
}
```

### 1.2 Mevcut Test Dosyaları ve Kapsamları

```
server/tests/
├── unit/
│   ├── board.test.js              ✅ ~25 test — tahta oluşturma, klonlama, serileştirme
│   ├── dice.test.js               ✅ ~20 test — zar adilliği, çiftler, ilk oyuncu
│   ├── moves.test.js              ✅ ~50 test — hamle doğrulama, bar, bearing off
│   ├── engine.test.js             ✅ ~35 test — state machine, tur geçişi, sonuçlar
│   ├── scoring.test.js            ✅ ~20 test — ELO hesaplama, çarpanlar, tier'lar
│   ├── appError.test.js           ✅ 4 test  — AppError sınıfı (statusCode, type, stack)
│   ├── constants.test.js          ✅ 3 test  — Sabit değerler doğrulama
│   ├── logger.test.js             ✅ 4 test  — Yapılandırılmış loglama
│   ├── csrf.test.js               ✅ 7 test  — CSRF middleware
│   ├── socketRateLimiter.test.js  ✅ 7 test  — Socket rate limiter
│   ├── validateMove.test.js       ✅ 14 test — Hamle verisi doğrulama
│   └── requestId.test.js          ✅ 4 test  — Request ID middleware
├── integration/          ⚠️ BOŞ — henüz eklenmemiş
└── fixtures/             📁 Test verileri
```

**Toplam: 12 suite, 118 server test + 17 Flutter test**

### 1.3 Flutter Mevcut Testler

```
mobile/test/
├── auth_provider_test.dart   ✅ 5 test — socket fail, startup race, timeout, auth error
├── board_layout_test.dart    ✅ 2 test — tavla viewport oranı, tall ve height-limited ekran senaryoları
├── board_widget_test.dart    ✅ 3 test — premium board layout smoke testi + point drop + bear-off tray drag-drop etkileşimleri
├── game_provider_test.dart   ✅ 6 test — bear-off parity, overshoot validity, higher-die selection, socket error feedback, bot-mode parity
└── widget_test.dart          ✅ 1 test — app açılış smoke testi
```

---

## 2. Test İsimlendirme Standartları

### 2.1 Dosya İsimlendirme

```
Server (Jest):
  server/tests/unit/{modül}.test.js
  server/tests/integration/{özellik}.test.js

  Örnekler:
    server/tests/unit/board.test.js        ← game/board.js modülü için
    server/tests/unit/scoring.test.js      ← game/scoring.js modülü için
    server/tests/unit/userService.test.js  ← services/userService.js için
    server/tests/integration/auth.test.js  ← Auth akışı testi

Flutter (flutter_test):
  mobile/test/{özellik}_test.dart
  mobile/test/unit/{modül}_test.dart
  mobile/test/widget/{widget}_test.dart

  Örnekler:
    mobile/test/unit/user_model_test.dart
    mobile/test/unit/game_state_test.dart
    mobile/test/widget/board_widget_test.dart
    mobile/test/widget/dice_widget_test.dart
    mobile/test/providers/auth_provider_test.dart
```

### 2.2 Test Bloğu İsimlendirme

```javascript
// Server (Jest) — Türkçe veya İngilizce kabul edilir, tutarlılık önemli
describe('ModülAdı', () => {
  describe('fonksiyonAdı', () => {
    it('should [beklenen davranış] when [koşul]', () => {});
    it('should throw error when [hata koşulu]', () => {});
    it('should return [dönüş değeri] for [girdi]', () => {});
  });
});

// Gerçek örnekler (mevcut testlerden):
describe('Board', () => {
  describe('createInitialBoard', () => {
    it('should create a board with 24 points', () => {});
    it('should place 15 white pieces correctly', () => {});
    it('should place 15 black pieces correctly', () => {});
  });
});

describe('Scoring', () => {
  describe('calculateEloChange', () => {
    it('should return positive change for winner', () => {});
    it('should apply 2x multiplier for gammon', () => {});
    it('should not go below minimum rating', () => {});
  });
});
```

```dart
// Flutter — group() ve test() kullanımı
group('User Model', () => {
  test('should parse from JSON correctly', () {});
  test('should calculate win rate', () {});
  test('should determine correct tier', () {});
});

group('BoardWidget', () => {
  testWidgets('should render 24 points', (tester) async {});
  testWidgets('should highlight valid moves', (tester) async {});
});
```

---

## 3. Test Yazma Kuralları (KATI)

### KURAL 1: Her Yeni Kod = Test
> Yazılan veya değiştirilen her fonksiyon, modül veya bileşen için test yazılmalıdır.

### KURAL 2: Mevcut Testleri Kırma
> Kod değişikliği yapmadan önce `npm test` çalıştır. Değişiklik sonrası tekrar çalıştır. Kırılan test varsa düzelt.

### KURAL 3: Test Bağımsızlığı
> Her test kendi state'ini oluşturmalı, başka testlere bağımlı olmamalı.

### KURAL 4: Kenar Durumları
> Sadece "happy path" değil, hata durumları, sınır değerleri ve edge case'ler de test edilmeli.

### KURAL 5: Mock Kullanım
> Veritabanı, ağ çağrıları ve dış bağımlılıklar mock'lanmalı. Game engine gibi saf fonksiyonlar doğrudan test edilmeli.

---

## 4. Yeni Bileşen Ekleme Senaryoları + Test Şablonları

### Senaryo A: Yeni Game Engine Modülü

Örneğin `server/src/game/timer.js` eklendiğinde:

```javascript
// server/tests/unit/timer.test.js
const { createTimer, isExpired, getRemainingTime } = require('../../src/game/timer');

describe('Timer', () => {
  describe('createTimer', () => {
    it('should create timer with specified duration', () => {
      const timer = createTimer(60);
      expect(timer.duration).toBe(60);
      expect(timer.startTime).toBeDefined();
    });

    it('should throw error for invalid duration', () => {
      expect(() => createTimer(-1)).toThrow();
      expect(() => createTimer(0)).toThrow();
    });
  });

  describe('isExpired', () => {
    it('should return false for fresh timer', () => {
      const timer = createTimer(60);
      expect(isExpired(timer)).toBe(false);
    });

    it('should return true for expired timer', () => {
      const timer = createTimer(1);
      timer.startTime = Date.now() - 2000; // 2 saniye önce başlamış
      expect(isExpired(timer)).toBe(true);
    });
  });

  describe('getRemainingTime', () => {
    it('should return remaining seconds', () => {
      const timer = createTimer(60);
      const remaining = getRemainingTime(timer);
      expect(remaining).toBeGreaterThan(58);
      expect(remaining).toBeLessThanOrEqual(60);
    });

    it('should return 0 for expired timer', () => {
      const timer = createTimer(1);
      timer.startTime = Date.now() - 5000;
      expect(getRemainingTime(timer)).toBe(0);
    });
  });
});
```

### Senaryo B: Yeni API Route / Controller / Service

Örneğin `POST /api/reports` eklendiğinde:

```javascript
// server/tests/unit/reportService.test.js
const reportService = require('../../src/services/reportService');
const pool = require('../../src/models/db');

// DB'yi mock'la
jest.mock('../../src/models/db', () => ({
  query: jest.fn(),
}));

describe('ReportService', () => {
  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('createReport', () => {
    it('should create a report with valid data', async () => {
      pool.query.mockResolvedValueOnce({
        rows: [{ id: 1, reporter_id: 1, reported_id: 2, reason: 'cheating', status: 'pending' }],
      });

      const report = await reportService.createReport(1, 2, 'cheating', 5);
      expect(pool.query).toHaveBeenCalledWith(
        expect.stringContaining('INSERT INTO reports'),
        expect.arrayContaining([1, 2, 'cheating', 5])
      );
      expect(report.status).toBe('pending');
    });

    it('should throw error when reporter and reported are same', async () => {
      await expect(reportService.createReport(1, 1, 'cheating', 5))
        .rejects.toThrow();
    });

    it('should throw error when reason is empty', async () => {
      await expect(reportService.createReport(1, 2, '', 5))
        .rejects.toThrow();
    });
  });

  describe('getReportsByStatus', () => {
    it('should return pending reports', async () => {
      pool.query.mockResolvedValueOnce({
        rows: [{ id: 1, status: 'pending' }, { id: 2, status: 'pending' }],
      });

      const reports = await reportService.getReportsByStatus('pending');
      expect(reports).toHaveLength(2);
    });

    it('should return empty array when no reports', async () => {
      pool.query.mockResolvedValueOnce({ rows: [] });
      const reports = await reportService.getReportsByStatus('pending');
      expect(reports).toEqual([]);
    });
  });
});
```

### Senaryo C: Yeni Flutter Widget

Örneğin `EloTierBadge` widget'ı eklendiğinde:

```dart
// mobile/test/widget/elo_tier_badge_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tavla_online/features/profile/widgets/elo_tier_badge.dart';

void main() {
  group('EloTierBadge', () => {
    testWidgets('should display Novice for ELO < 1200', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: EloTierBadge(elo: 1100)),
        ),
      );

      expect(find.text('Novice'), findsOneWidget);
    });

    testWidgets('should display Grandmaster for ELO >= 2200', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: EloTierBadge(elo: 2500)),
        ),
      );

      expect(find.text('Grandmaster'), findsOneWidget);
    });

    testWidgets('should use gold color for Master tier', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: EloTierBadge(elo: 2100)),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container));
      // Renk doğrulama...
    });
  });
}
```

### Senaryo D: Yeni Flutter Provider

Örneğin yeni bir provider eklendiğinde:

```dart
// mobile/test/providers/chat_provider_test.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:tavla_online/features/game/providers/chat_provider.dart';

class MockSocketService extends Mock implements SocketService {}

void main() {
  late ProviderContainer container;
  late MockSocketService mockSocket;

  setUp(() {
    mockSocket = MockSocketService();
    container = ProviderContainer(
      overrides: [
        socketServiceProvider.overrideWithValue(mockSocket),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('ChatProvider', () => {
    test('should start with empty messages', () {
      final state = container.read(chatProvider);
      expect(state.messages, isEmpty);
    });

    test('should add message on sendMessage', () {
      container.read(chatProvider.notifier).sendMessage('Merhaba');
      verify(mockSocket.emit('game:chat', {'message': 'Merhaba'})).called(1);
    });

    test('should not send message longer than 500 chars', () {
      final longMessage = 'a' * 501;
      expect(
        () => container.read(chatProvider.notifier).sendMessage(longMessage),
        throwsArgumentError,
      );
    });
  });
}
```

### Senaryo E: Yeni Middleware

Örneğin `server/src/middleware/validator.js` eklendiğinde:

```javascript
// server/tests/unit/validator.test.js
const { validateBody } = require('../../src/middleware/validator');

describe('Validator Middleware', () => {
  let req, res, next;

  beforeEach(() => {
    req = { body: {} };
    res = {
      status: jest.fn().mockReturnThis(),
      json: jest.fn(),
    };
    next = jest.fn();
  });

  describe('validateBody', () => {
    const schema = {
      username: { required: true, minLength: 3, maxLength: 50 },
      email: { required: true, pattern: /^[^\s@]+@[^\s@]+\.[^\s@]+$/ },
    };

    it('should call next() for valid body', () => {
      req.body = { username: 'testuser', email: 'test@test.com' };
      validateBody(schema)(req, res, next);
      expect(next).toHaveBeenCalled();
    });

    it('should return 400 for missing required field', () => {
      req.body = { username: 'testuser' };
      validateBody(schema)(req, res, next);
      expect(res.status).toHaveBeenCalledWith(400);
      expect(next).not.toHaveBeenCalled();
    });

    it('should return 400 for invalid email format', () => {
      req.body = { username: 'testuser', email: 'invalid' };
      validateBody(schema)(req, res, next);
      expect(res.status).toHaveBeenCalledWith(400);
    });
  });
});
```

---

## 5. Integration Test Şablonu

```javascript
// server/tests/integration/auth.test.js
const request = require('supertest');
const app = require('../../src/app');
const pool = require('../../src/models/db');

describe('Auth Integration', () => {
  beforeAll(async () => {
    // Test DB'sini hazırla
    await pool.query('DELETE FROM users WHERE username LIKE $1', ['test_%']);
  });

  afterAll(async () => {
    // Temizlik
    await pool.query('DELETE FROM users WHERE username LIKE $1', ['test_%']);
    await pool.end();
  });

  describe('POST /api/auth/register', () => {
    it('should register a new user', async () => {
      const res = await request(app)
        .post('/api/auth/register')
        .send({
          username: 'test_user1',
          email: 'test1@test.com',
          password: 'password123',
        });

      expect(res.status).toBe(201);
      expect(res.body).toHaveProperty('accessToken');
      expect(res.body).toHaveProperty('refreshToken');
      expect(res.body.user.username).toBe('test_user1');
      expect(res.body.user.elo_rating).toBe(1200);
    });

    it('should reject duplicate username', async () => {
      const res = await request(app)
        .post('/api/auth/register')
        .send({
          username: 'test_user1',        // Zaten kayıtlı
          email: 'test2@test.com',
          password: 'password123',
        });

      expect(res.status).toBe(409);
    });

    it('should reject duplicate email', async () => {
      const res = await request(app)
        .post('/api/auth/register')
        .send({
          username: 'test_user2',
          email: 'test1@test.com',       // Zaten kayıtlı
          password: 'password123',
        });

      expect(res.status).toBe(409);
    });
  });

  describe('POST /api/auth/login', () => {
    it('should login with username', async () => {
      const res = await request(app)
        .post('/api/auth/login')
        .send({ identifier: 'test_user1', password: 'password123' });

      expect(res.status).toBe(200);
      expect(res.body).toHaveProperty('accessToken');
    });

    it('should login with email', async () => {
      const res = await request(app)
        .post('/api/auth/login')
        .send({ identifier: 'test1@test.com', password: 'password123' });

      expect(res.status).toBe(200);
    });

    it('should reject wrong password', async () => {
      const res = await request(app)
        .post('/api/auth/login')
        .send({ identifier: 'test_user1', password: 'wrongpass' });

      expect(res.status).toBe(401);
    });
  });
});
```

---

## 6. Test Çalıştırma Kontrol Listesi

Her PR/commit öncesi:

```bash
# 1. Server testlerini çalıştır
cd server
npm test
# ✅ Tüm testler geçmeli
# ✅ Coverage düşmemeli

# 2. Flutter testlerini çalıştır
cd ../mobile
flutter test
# ✅ Tüm testler geçmeli

# 3. Lint kontrolü
cd ../server
npm run lint
# ✅ Lint hatası olmamalı

cd ../mobile
flutter analyze
# ✅ Analiz hatası olmamalı
```

---

## 7. Coverage Hedefleri

| Modül | Mevcut | Hedef | Durum |
|-------|--------|-------|-------|
| `server/src/game/` | ~90% | >90% | ✅ İyi |
| `server/src/utils/` | ~80% | >80% | ✅ İyi |
| `server/src/middleware/` | ~40% | >80% | ⚠️ Kısmi |
| `server/src/services/` | ~0% | >80% | ❌ Eksik |
| `server/src/controllers/` | ~0% | >80% | ❌ Eksik |
| `server/src/routes/` | ~0% | >70% | ❌ Eksik |
| `mobile/lib/` | ~0% | >60% | ❌ Eksik |

**Öncelikli test ihtiyaçları:**
1. `userService.js` — unit test (mock DB)
2. `gameService.js` — unit test (mock DB)
3. `auth.js` middleware — unit test
4. Integration tests — auth flow, game flow
5. Flutter model testleri — User, GameSnapshot, BoardState
6. Flutter provider testleri — AuthNotifier, GameNotifier

---

## 8. Test Veri Yardımcıları (Fixtures)

Test verilerini `server/tests/fixtures/` dizininde tut:

```javascript
// server/tests/fixtures/gameFixtures.js
const { createInitialBoard } = require('../../src/game/board');

function createTestGame(overrides = {}) {
  return {
    state: 'PLAYING',
    board: createInitialBoard(),
    currentTurn: 'W',
    turnPhase: 'ROLLING',
    dice: [],
    remainingDice: [],
    whitePlayerId: 1,
    blackPlayerId: 2,
    moveNumber: 0,
    turnId: 0,
    moveHistory: [],
    winner: null,
    resultType: null,
    ...overrides,
  };
}

function createEndgameBoard() {
  // Tüm taşlar iç bölgede — bearing off test senaryosu
  const board = createInitialBoard();
  // ... pozisyon ayarla
  return board;
}

module.exports = { createTestGame, createEndgameBoard };
```

---

## 9. AI Ajanlar İçin Test Talimatları

> **ZORUNLU:** Her görevden sonra aşağıdaki adımları takip et:

```
1. Yeni kod yaz veya mevcut kodu değiştir
2. İlgili test dosyasını oluştur veya güncelle
3. Server testlerini çalıştır: cd server && npm test
4. Flutter testlerini çalıştır: cd mobile && flutter test
5. Tüm testler geçtiyse → MEMORY.md'yi güncelle
6. Test kırıldıysa → ÖNCE testi düzelt, sonra devam et
```

> **YASAKLAR:**
> - Test yazmadan kod teslim etme
> - Kırık testi atlamak için `skip` veya `xit` kullanma
> - Coverage'ı düşüren kod teslim etme
> - `console.log` veya `print` ile test yapma — assertion kullan
