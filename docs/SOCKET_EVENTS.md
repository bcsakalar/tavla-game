# Socket.IO Event Spesifikasyonu

Bağlantı URL: `ws://localhost:3000`

## Bağlantı

Socket bağlantısı kurulurken JWT token gönderilmelidir:

```javascript
const socket = io('http://localhost:3000', {
  auth: { token: 'JWT_ACCESS_TOKEN' },
  transports: ['websocket']
});
```

---

## Lobi Olayları

### Client → Server

| Olay | Veri | Açıklama |
|------|------|----------|
| `lobby:queue` | — | Eşleştirme kuyruğuna katıl |
| `lobby:cancel` | — | Kuyruktan çık |
| `lobby:online` | — | Çevrimiçi oyuncu sayısını iste |

### Server → Client

| Olay | Veri | Açıklama |
|------|------|----------|
| `lobby:online` | `{ count: number }` | Çevrimiçi oyuncu sayısı |
| `lobby:queued` | `{ message: string }` | Kuyruğa alındı onayı |
| `lobby:cancelled` | `{ message: string }` | Kuyruktan çıkıldı |
| `game:start` | `GameSnapshot` | Eşleşme bulundu, oyun başlıyor |

### Matchmaking Kuralları
- İlk arama: ±200 ELO aralığı
- 30 saniye sonra: ±400 ELO aralığına genişler
- Her 5 saniyede bir eşleşme denemesi yapılır

---

## Oyun Olayları

### Client → Server

| Olay | Veri | Açıklama |
|------|------|----------|
| `game:rollDice` | — | Zar at |
| `game:move` | `{ from: number\|'bar', to: number\|'off' }` | Taş hareket ettir |
| `game:endTurn` | — | Sırayı bitir |
| `game:resign` | — | Teslim ol |
| `game:chat` | `{ message: string }` | Sohbet mesajı gönder (max 500 karakter) |
| `game:reconnect` | — | Oyuna yeniden bağlan |

### Server → Client

| Olay | Veri | Açıklama |
|------|------|----------|
| `game:diceRolled` | `GameSnapshot` | Zar atıldı, güncel durum |
| `game:moved` | `GameSnapshot` | Hamle yapıldı |
| `game:turnChanged` | `GameSnapshot` | Sıra değişti |
| `game:ended` | `{ winnerId, resultType, eloChange, ... }` | Oyun bitti |
| `game:chat` | `{ username, message, timestamp }` | Sohbet mesajı alındı |
| `game:error` | `{ message: string }` | Hata mesajı |
| `game:opponentDisconnected` | `{ message, reconnectWindow }` | Rakip bağlantısı koptu |
| `game:opponentReconnected` | `{ message }` | Rakip yeniden bağlandı |
| `game:reconnected` | `GameSnapshot` | Yeniden bağlanma başarılı |

---

## GameSnapshot Formatı

```javascript
{
  state: 'WAITING' | 'INITIAL_ROLL' | 'PLAYING' | 'FINISHED',
  board: {
    points: [          // 24 nokta (index 0-23)
      { count: 2, player: 'W' },
      { count: 0, player: null },
      // ...
    ],
    bar: { W: 0, B: 0 },
    borneOff: { W: 0, B: 0 }
  },
  currentTurn: 'W' | 'B',
  turnPhase: 'ROLLING' | 'MOVING' | 'WAITING',
  dice: [3, 5],           // Atılan zarlar
  remainingDice: [5],     // Kalan (kullanılmamış) zarlar
  moveNumber: 12,
  whitePlayerId: 1,
  blackPlayerId: 2,
  winner: null | 'W' | 'B',
  resultType: null | 'normal' | 'gammon' | 'backgammon'
}
```

---

## Oyun Akışı

```
1. Her iki oyuncu da game:start alır
2. INITIAL_ROLL: Her oyuncu game:rollDice gönderir
   → Yüksek zar atan ilk oynar
3. PLAYING döngüsü:
   a. Aktif oyuncu game:rollDice → game:diceRolled alınır
   b. Oyuncu game:move ile hamle yapar → game:moved alınır
   c. Tüm zarlar kullanıldığında veya game:endTurn → game:turnChanged
   d. Kazanan belirlenir → game:ended
4. Teslim veya süre aşımı → game:ended
```

---

## Zamanlayıcılar

| Zamanlayıcı | Süre | Sonuç |
|-------------|------|-------|
| Hamle süresi | 30 saniye | Otomatik sıra geçişi veya zaman aşımı kaybı |
| Yeniden bağlanma | 60 saniye | Bağlantı kopma kaybı |

---

## Hata Kodları

| Mesaj | Açıklama |
|-------|----------|
| `Sıra sizde değil` | Sıra dışı hamle denemesi |
| `Önce zar atmalısınız` | Zar atılmadan hamle |
| `Geçersiz hamle` | Kurallara aykırı hamle |
| `Aktif oyun bulunamadı` | Oyun bulunamadı |
