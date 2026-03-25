# Tavla Online — İş Mantığı ve Kurallar

> **Son güncelleme:** 2026-03-17

---

## 1. Projenin Ana Amacı

Tavla Online, gerçek zamanlı **çok oyunculu Tavla (Backgammon)** platformudur. Oyuncular:
- ELO tabanlı eşleşme sistemiyle rakip bulabilir
- Bot'a karşı pratik yapabilir (Easy / Medium / Hard)
- Oyun geçmişlerini ve istatistiklerini takip edebilir
- Sıralama tablosunda yarışabilir

**Hedef Kitle:** Türkçe konuşan tavla severler (tüm UI metinleri Türkçe)

---

## 2. Tavla Oyun Kuralları (Sunucu Tarafında Zorunlu)

### 2.1 Tahta Düzeni

```
Siyah ev ◄─────── Siyah dış ◄─────── Beyaz dış ◄─────── Beyaz ev
 19-24              13-18              7-12               1-6

Başlangıç Pozisyonu:
  Beyaz: Nokta 24→2, 13→5, 8→3, 6→5  (toplam 15 taş)
  Siyah: Nokta 1→2, 12→5, 17→3, 19→5 (toplam 15 taş)

Hareket Yönü:
  Beyaz: 24 → 1 (yüksekten düşüğe)
  Siyah: 1 → 24 (düşükten yükseğe)
```

### 2.2 Kritik Oyun Kuralları (server/src/game/moves.js)

| Kural | Açıklama | Kod Referansı |
|-------|----------|---------------|
| **Bar önceliği** | Bar'daki taşlar diğer hamlelerden önce girilmeli | `getValidMoveSequences()` |
| **Açık nokta** | Sadece boş, kendi taşı olan veya tek rakip taşı olan noktaya gidilebilir | `getSingleMoves()` |
| **Vurma** | Tek rakip taşına (blot) inilince, rakip taşı bar'a gider | `applySingleMove()` |
| **Çift zar** | Aynı sayı gelince 4 hamle hakkı (ör: 4-4 = 4x4) | `dice.js expandDice()` |
| **Maksimum kullanım** | İki zar da kullanılabiliyorsa ikisi de kullanılmalı | `getValidMoveSequences()` |
| **Tek zar kuralı** | Sadece bir zar kullanılabiliyorsa büyük olan kullanılmalı | `getValidMoveSequences()` |
| **Taş kırma (Bearing Off)** | Tüm 15 taş iç bölgede olmalı | `canBearOff()` |
| **Bearing off kuralı** | Tam sayı veya en yüksek noktadaki taş çıkarılabilir | `getSingleMoves()` |

### 2.3 Oyun Sonucu Tipleri

```javascript
// server/src/game/engine.js — getResultType()

Normal (1x ELO):
  → Kaybeden en az 1 taş kırmışsa

Gammon / Mars (2x ELO):
  → Kaybeden hiç taş kırmamışsa (borneOff === 0)
  → VE kaybeden taşları kazananın iç bölge/bar'ında DEĞİLSE

Backgammon / Üç Mars (3x ELO):
  → Kaybeden hiç taş kırmamışsa
  → VE kaybeden taşları kazananın iç bölge veya bar'ında varsa

Resign (1x ELO):
  → Oyuncu teslim olduğunda

Timeout (1x ELO):
  → 60 saniye hamle süresi dolduğunda

Disconnect (1x ELO):
  → 60 saniye yeniden bağlantı penceresi dolduğunda
```

---

## 3. ELO Derecelendirme Sistemi

### 3.1 Formül (server/src/game/scoring.js)

```
Beklenen Skor:
  E(A) = 1 / (1 + 10^((Rb - Ra) / 400))

Puan Değişimi:
  ΔR = K × (S - E) × Çarpan

  K = 32 (sabit K-faktörü)
  S = 1 (kazanma) veya 0 (kaybetme)
  E = beklenen skor
  Çarpan = Normal(1x) | Gammon(2x) | Backgammon(3x)
```

### 3.2 Sabitler

| Parametre | Değer |
|-----------|-------|
| K-Faktörü | 32 |
| Başlangıç ELO | 1200 |
| Minimum ELO | 100 |
| Normal çarpan | 1x |
| Gammon çarpan | 2x |
| Backgammon çarpan | 3x |
| Resign/Timeout/Disconnect çarpan | 1x |

### 3.3 Tier Sistemi

| Tier | ELO Aralığı |
|------|-------------|
| Novice (Çaylak) | < 1200 |
| Beginner (Başlangıç) | 1200 – 1399 |
| Intermediate (Orta) | 1400 – 1599 |
| Advanced (İleri) | 1600 – 1799 |
| Expert (Uzman) | 1800 – 1999 |
| Master (Usta) | 2000 – 2199 |
| Grandmaster (Büyükusta) | 2200+ |

---

## 4. Eşleşme (Matchmaking) Sistemi

### 4.1 Kural Seti (server/src/socket/handlers/lobby.js)

```
1. Oyuncu kuyruğa girer (lobby:queue)
2. Her 5 saniyede eşleşme kontrolü
3. İlk 30 saniye: ±200 ELO aralığında rakip ara
4. 30 saniye sonra: ±400 ELO aralığına genişlet
5. Eşleşme bulununca:
   - Rastgele renk ataması (beyaz/siyah)
   - Oyun oluştur (engine.createGame)
   - DB'ye kaydet (status: 'playing')
   - Her iki oyuncuyu game:${id} odasına katıl
   - game:start emit et (GameSnapshot ile)
```

### 4.2 Kısıtlar

- Bir oyuncu aynı anda sadece **1 aktif oyunda** olabilir
- Kuyrukta beklerken başka oyuna katılamaz
- Bot oyunları eşleşmeyi etkilemez (ayrı map'te tutulur)

---

## 5. Zamanlayıcı (Timer) Sistemi

### 5.1 Hamle Zamanlayıcısı

```
Süre: 60 saniye (MOVE_TIMER_SECONDS)
Başlangıç: Zar atıldıktan sonra (turnPhase: MOVING)
Duruş: Tur geçişinde, oyun bitişinde
Süre dolduğunda: Süre dolan oyuncu KAYBEDER (resultType: timeout)

Güvenlik: turnId ile race condition koruması
  → Timer tetiklendiğinde turnId kontrolü yapılır
  → Eğer tur zaten geçmişse timer geçersiz kabul edilir
```

### 5.2 Yeniden Bağlantı Penceresi

```
Süre: 60 saniye (RECONNECT_WINDOW_SECONDS)
Tetikleme: Oyuncunun socket bağlantısı koptuğunda
İptal: Oyuncu süre içinde game:reconnect emit ederse
Süre dolduğunda: Bağlantısı kopan oyuncu KAYBEDER (resultType: disconnect)
Rakibe bildirim: game:playerDisconnected → game:playerReconnected
```

---

## 6. Bot AI Sistemi

### 6.1 Zorluk Seviyeleri (server/src/game/bot.js)

```javascript
// Easy — Rastgele hamle
chooseMoves(board, player, dice, 'easy'):
  → Geçerli hamle dizilerinden rastgele birini seç

// Medium — Basit puanlama
chooseMoves(board, player, dice, 'medium'):
  → Her dizi için puan hesapla:
    +50: Rakip taşı vurma
    +30: Taş kırma (bearing off)
    +10: Kullanılan zar başına
  → En yüksek 3 puanlıdan rastgele seç

// Hard — Pozisyonel analiz
chooseMoves(board, player, dice, 'hard'):
  → Sonuç tahtasını değerlendir:
    -15: Açık taş (blot) başına
    +5: Yapılmış nokta (2+ taş) başına
    -20: Bar'daki taş başına
  → En yüksek puanlı diziyi seç
```

### 6.2 Bot Davranışı

- Bot her zaman **Siyah ('B')** oynar
- Bot hamleleri **gecikmeli** yapılır (1.5s ilk hamle, 1.2s sonrakiler) — görsel doğallık için
- Bot oyunları **veritabanına kaydedilmez** (sadece pratik)
- Bot oyunlarında **ELO değişmez**

---

## 7. Chat ve Emoji Sistemi

### 7.1 Chat Kuralları

- Maksimum mesaj uzunluğu: **500 karakter**
- Mesajlar **veritabanına kaydedilir** (chat_messages tablosu)
- Sistem mesajları: `is_system: true` (oyun olayları)
- Sadece aynı oyundaki oyuncular birbirine mesaj gönderebilir

### 7.2 Emoji Reaksiyonları

```javascript
// İzin verilen emojiler (whitelist):
const ALLOWED_EMOJIS = ['👍', '😂', '😮', '😡', '🎉', '🤔'];

// game:emoji event → rakibe iletilir
// 3 saniye sonra otomatik temizlenir (client-side)
```

---

## 8. Admin Panel İş Mantığı

### 8.1 Yetkiler

- Admin girişi: **Session bazlı** (JWT değil)
- Sadece `role: 'admin'` olan kullanıcılar erişebilir
- Endpoint: `/admin/login` (POST)
- **CSRF koruması:** Tüm POST formlarında session-based CSRF token doğrulaması
- **Rate limiting:** Admin login 5 istek/15 dakika

### 8.2 Admin İşlemleri

| İşlem | Endpoint | Açıklama |
|-------|----------|----------|
| Dashboard | `GET /admin` | Toplam kullanıcı, oyun, aktif oyuncu, günlük istatistik |
| Kullanıcı listesi | `GET /admin/users` | Arama, sayfalama, ELO gösterimi |
| Ban/Unban | `POST /admin/users/:id/ban` | Toggle — banlı kullanıcı giriş yapamaz |
| Oyun geçmişi | `GET /admin/games` | Tüm oyunlar, sonuçlar, 20'lik sayfalama |
| Şikayetler | `GET /admin/reports` | Bekleyen raporlar |
| Rapor çöz | `POST /admin/reports/:id/resolve` | Admin notu ekle, durumu güncelle |

---

## 9. Kimlik Doğrulama Akışı

### 9.1 Kayıt (Register)

```
Validasyonlar:
  - username: 3-50 karakter, benzersiz
  - email: geçerli format, benzersiz
  - password: minimum uzunluk (client'ta 8, server'da kontrol)

İşlem:
  1. Şifreyi bcrypt ile hashle (12 round)
  2. users tablosuna INSERT
  3. JWT access token + refresh token üret
  4. { user, accessToken, refreshToken } döndür

Rate Limit: 20 istek / 15 dakika
```

### 9.2 Giriş (Login)

```
Girdi: identifier (username VEYA email) + password
  1. Username veya email ile kullanıcıyı bul
  2. Banlı mı kontrol et (is_banned → 403)
  3. Şifreyi bcrypt ile karşılaştır
  4. Token çifti üret
  5. Döndür

Hata Durumları:
  - 401: Geçersiz kullanıcı adı/email veya şifre
  - 403: Hesap banlanmış
  - 429: Rate limit aşıldı
```

### 9.3 Token Yenileme

```
1. Client 401 alır (access token süresi dolmuş)
2. POST /api/auth/refresh { refreshToken }
3. Refresh token doğrula
4. Yeni access + refresh token çifti üret
5. Döndür

Flutter ApiClient:
  → 401 interceptor ile otomatik yenileme
  → Yenilemeden sonra orijinal isteği tekrarla
```

---

## 10. Kritik İş Kısıtları

| Kısıt | Açıklama |
|-------|----------|
| **Tek oyun kuralı** | Bir oyuncu aynı anda sadece 1 çevrimiçi oyunda olabilir |
| **Server-side doğrulama** | Tüm hamle doğrulaması sunucuda yapılır — client'a güvenilmez |
| **In-memory oyunlar** | Aktif oyunlar RAM'de tutulur ve Redis'e persist edilir — sunucu çökmesinde kurtarulabilir |
| **ELO minimum** | ELO puanı 100'ün altına düşemez |
| **Chat sınırı** | Tek mesaj maksimum 500 karakter |
| **Emoji whitelist** | Sadece 6 izin verilen emoji gönderilebilir |
| **Bot = pratik** | Bot oyunları DB'ye kaydedilmez, ELO etkilemez |
| **Admin = session** | Admin panel JWT değil, express-session kullanır |
| **Şifre hash** | bcrypt 12 round — değiştirmek zorunludur |
| **Zar adilliği** | `crypto.randomInt()` kullanılır — Math.random() değil |
