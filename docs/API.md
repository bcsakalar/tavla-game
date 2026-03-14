# API Dokümantasyonu

Base URL: `http://localhost:3000/api`

Tüm istekler JSON formatındadır. Auth gerektiren endpointler `Authorization: Bearer <token>` header'ı bekler.

---

## Auth

### `POST /api/auth/register`
Yeni kullanıcı kaydı.

**Body:**
```json
{
  "username": "oyuncu1",
  "email": "oyuncu1@email.com",
  "password": "sifre123"
}
```

**Response (201):**
```json
{
  "user": { "id": 1, "username": "oyuncu1", "elo_rating": 1200, ... },
  "accessToken": "eyJ...",
  "refreshToken": "eyJ..."
}
```

**Hatalar:**
- `400` — Eksik/geçersiz alanlar, kullanıcı adı/email zaten kayıtlı

---

### `POST /api/auth/login`
Giriş yap.

**Body:**
```json
{
  "identifier": "oyuncu1",
  "password": "sifre123"
}
```
`identifier` kullanıcı adı veya e-posta olabilir.

**Response (200):**
```json
{
  "user": { "id": 1, "username": "oyuncu1", ... },
  "accessToken": "eyJ...",
  "refreshToken": "eyJ..."
}
```

**Hatalar:**
- `401` — Geçersiz kimlik bilgileri
- `403` — Hesap engellenmiş

---

### `POST /api/auth/refresh`
Token yenile.

**Body:**
```json
{
  "refreshToken": "eyJ..."
}
```

**Response (200):**
```json
{
  "accessToken": "eyJ...",
  "refreshToken": "eyJ..."
}
```

---

## Users

### `GET /api/users/me` 🔒
Kendi profilini getir.

**Response (200):**
```json
{
  "user": {
    "id": 1,
    "username": "oyuncu1",
    "email": "oyuncu1@email.com",
    "avatar_url": null,
    "elo_rating": 1200,
    "total_wins": 5,
    "total_losses": 3,
    "total_games_played": 8,
    "gammon_wins": 1,
    "backgammon_wins": 0
  }
}
```

---

### `PATCH /api/users/me` 🔒
Profili güncelle.

**Body:**
```json
{
  "avatar_url": "https://example.com/avatar.jpg"
}
```

---

### `GET /api/users/:id`
Belirli bir kullanıcının profilini getir.

---

### `GET /api/users/:id/games`
Kullanıcının oyun geçmişi.

**Query:**
- `limit` (varsayılan: 20)
- `offset` (varsayılan: 0)

---

## Games

### `GET /api/games/:id` 🔒
Oyun detayı.

### `GET /api/games/:id/moves` 🔒
Oyun hamle geçmişi.

### `GET /api/games/:id/chat` 🔒
Oyun sohbet mesajları.

---

## Leaderboard

### `GET /api/leaderboard`
Sıralama tablosu (ELO'ya göre azalan).

**Query:**
- `limit` (varsayılan: 50)
- `offset` (varsayılan: 0)

**Response (200):**
```json
[
  { "id": 1, "username": "usta1", "elo_rating": 1850, "total_wins": 42, ... },
  { "id": 2, "username": "oyuncu2", "elo_rating": 1720, ... }
]
```

---

## Rate Limiting

| Endpoint | Limit |
|----------|-------|
| Genel API | 100 istek / 15 dakika |
| Auth endpointleri | 20 istek / 15 dakika |

---

## Hata Formatı

```json
{
  "error": "Hata mesajı burada"
}
```

| Kod | Açıklama |
|-----|----------|
| 400 | Geçersiz istek |
| 401 | Yetkilendirme gerekli |
| 403 | Erişim engellendi |
| 404 | Bulunamadı |
| 429 | Çok fazla istek |
| 500 | Sunucu hatası |
