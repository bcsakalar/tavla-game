# Tavla (Backgammon) Oyun Kuralları

## Tahta Düzeni

Tavla tahtası 24 üçgen noktadan (sivri) oluşur. Her oyuncunun 15 taşı vardır.

### Başlangıç Pozisyonu

```
Beyaz (W) Taşları:        Siyah (B) Taşları:
  Nokta 24 → 2 taş          Nokta 1  → 2 taş
  Nokta 13 → 5 taş          Nokta 12 → 5 taş
  Nokta 8  → 3 taş          Nokta 17 → 3 taş
  Nokta 6  → 5 taş          Nokta 19 → 5 taş
```

(Yazılımda 0-indeksli: W → [23:2, 12:5, 7:3, 5:5], B → [0:2, 11:5, 16:3, 18:5])

## Temel Kurallar

### 1. Oyunun Başlaması
- Her oyuncu birer zar atar
- Yüksek zar atan ilk oynar
- Eşit gelirse tekrar atılır

### 2. Zar Atma ve Hamle
- Her turda 2 zar atılır
- Her zar değeri için bir hamle yapılır
- **Çift** gelirse (ör: 4-4) → 4 hamle yapılır (o zarın değerinde)

### 3. Hareket Yönü
- **Beyaz**: Yüksek noktalardan düşük noktalara (24→1)
- **Siyah**: Düşük noktalardan yüksek noktalara (1→24)

### 4. Açık Nokta Kuralı
Bir noktaya hamle yapılabilmesi için:
- Boş olmalı, VEYA
- Kendi taşlarınız olmalı, VEYA
- Rakibin **en fazla 1** taşı olmalı (blot/yalın taş)

### 5. Vurma (Hit)
Rakibin yalın taşına (1 taş olan nokta) gelirseniz, o taş **bar**'a (ortaya) gönderilir.

### 6. Bar'dan Giriş
- Bar'daki taşlar öncelikle girilmelidir
- Bar'da taş varken başka hamle yapılamaz
- Beyaz: Rakibin iç sahası (nokta 1-6) üzerinden girer
- Siyah: Rakibin iç sahası (nokta 19-24) üzerinden girer

### 7. Kırma (Bearing Off)
Tüm 15 taş iç sahanıza (home board) ulaştığında kırma başlar:
- **Beyaz iç saha**: Nokta 1-6
- **Siyah iç saha**: Nokta 19-24

Kırma kuralları:
- Zar değeri tam noktaya denk gelirse, o taş kırılır
- Zar değeri en yüksek dolu noktadan büyükse, en yüksek noktadaki taş kırılabilir
- Her zaman mümkün olduğunca çok zar kullanılmalıdır

## İleri Kurallar

### Zorunlu Hamle Kuralı
- İki zar da kullanılabiliyorsa, ikisi de kullanılmalıdır
- Sadece biri kullanılabiliyorsa, **büyük zar** tercih edilmelidir
- Hiçbir hamle yoksa sıra geçer

## Oyun Sonu Türleri

| Tür | Açıklama | ELO Çarpanı |
|-----|----------|-------------|
| **Normal** | Rakip en az 1 taş kırmış | 1x |
| **Mars (Gammon)** | Rakip hiç taş kırmamış | 2x |
| **Üç Mars (Backgammon)** | Rakip hiç taş kırmamış VE bar'da veya sizin iç sahanızda rakip taşı var | 3x |
| **Teslim** | Oyuncu teslim oldu | 1x |
| **Süre Aşımı** | Hamle süresi doldu | 1x |
| **Bağlantı Kopması** | 60 saniye içinde yeniden bağlanılamadı | 1x |

## ELO Derecelendirme

Standard ELO formülü uygulanır:

- **K-Faktör**: 32
- **Başlangıç Puanı**: 1200
- **Minimum Puan**: 100

### Seviyeler

| Seviye | ELO Aralığı |
|--------|-------------|
| Çaylak (Novice) | < 1200 |
| Başlangıç (Beginner) | 1200 - 1399 |
| Orta (Intermediate) | 1400 - 1599 |
| İleri (Advanced) | 1600 - 1799 |
| Uzman (Expert) | 1800 - 1999 |
| Usta (Master) | 2000 - 2199 |
| Büyükusta (Grandmaster) | 2200+ |
