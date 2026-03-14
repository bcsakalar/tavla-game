# 🚀 Tavla Online — VPS Production Deployment Kılavuzu

**Domain:** `tavla.berkecansakalar.com`  
**Backend Port:** `3005` (Nginx → Docker)  
**SSL:** Cloudflare Origin Certificate (Full Strict)  
**VPS Dizini:** `/opt/tavla/`

---

## 📋 İçindekiler

1. [Gereksinimler](#1-gereksinimler)
2. [Cloudflare DNS Ayarları](#2-cloudflare-dns-ayarları)
3. [Cloudflare Origin Certificate](#3-cloudflare-origin-certificate)
4. [GitHub'tan Repo Çekme](#4-githubtan-repo-çekme)
5. [SSL Sertifikalarını Yerleştirme](#5-ssl-sertifikalarını-yerleştirme)
6. [Nginx Kurulumu](#6-nginx-kurulumu)
7. [Production .env Dosyası](#7-production-env-dosyası)
8. [Docker Compose — Build & Run](#8-docker-compose--build--run)
9. [Veritabanı Migration & Seed](#9-veritabanı-migration--seed)
10. [Doğrulama ve Test](#10-doğrulama-ve-test)
11. [Flutter APK Kurulumu](#11-flutter-apk-kurulumu)
12. [Güncelleme Prosedürü](#12-güncelleme-prosedürü)
13. [Yedekleme](#13-yedekleme)
14. [Troubleshooting](#14-troubleshooting)
15. [Faydalı Komutlar](#15-faydalı-komutlar)

---

## 1. Gereksinimler

VPS'te aşağıdakilerin **kurulu** olması gerekir (zaten mevcut):

- ✅ Docker & Docker Compose
- ✅ Nginx
- ✅ Git

---

## 2. Cloudflare DNS Ayarları

Cloudflare Dashboard → DNS → Records:

| Type | Name | Content | Proxy Status | TTL |
|------|------|---------|--------------|-----|
| `A` | `tavla` | `VPS_IP_ADRESI` | ☁️ Proxied | Auto |

> ⚠️ **Proxy Status: Proxied** olmalı (turuncu bulut). Böylece Cloudflare üzerinden SSL + DDoS koruması aktif olur.

---

## 3. Cloudflare Origin Certificate

SSL sertifikasını Cloudflare'den oluşturuyoruz (ücretsiz, 15 yıl geçerli):

1. Cloudflare Dashboard → **SSL/TLS** → **Origin Server**
2. **Create Certificate** butonuna tıklayın
3. Ayarlar:
   - **Private key type:** RSA (2048)
   - **Hostnames:** `tavla.berkecansakalar.com`
   - **Certificate Validity:** 15 years
4. **Create** butonuna tıklayın
5. **Origin Certificate** (PEM formatı) → kopyalayın → VPS'te `origin.pem` dosyasına yapıştırın
6. **Private Key** → kopyalayın → VPS'te `origin-key.pem` dosyasına yapıştırın

> ⚠️ **Private Key sadece bir kez gösterilir!** Hemen kopyalayın.

### Cloudflare SSL Mode Ayarı

Cloudflare Dashboard → **SSL/TLS** → **Overview**:

```
SSL/TLS encryption mode: Full (strict)
```

---

## 4. GitHub'tan Repo Çekme

```bash
# Repo dizinini oluştur
mkdir -p /opt/tavla
cd /opt/tavla

# GitHub'tan klonla (token ile private repo erişimi)
git clone https://<GITHUB_TOKEN>@github.com/bcsakalar/tavla-game.git .

# Eğer zaten klonlanmışsa güncelle
# cd /opt/tavla && git pull origin main
```

> **GitHub Token almak için:**
> 1. GitHub → Settings → Developer Settings → Personal Access Tokens → Fine-grained tokens
> 2. **Generate new token** → Repository: `bcsakalar/tavla-game` → Permissions: Contents (Read)
> 3. Token'ı kopyalayıp yukarıdaki komutta `<GITHUB_TOKEN>` yerine yapıştırın

---

## 5. SSL Sertifikalarını Yerleştirme

```bash
# SSL dizinini oluştur
mkdir -p /etc/ssl/tavla

# Sertifika dosyalarını oluştur (Cloudflare'den kopyaladığınız içerikleri yapıştırın)
nano /etc/ssl/tavla/origin.pem
# → Cloudflare Origin Certificate içeriğini yapıştırın

nano /etc/ssl/tavla/origin-key.pem
# → Cloudflare Private Key içeriğini yapıştırın

# İzinleri güvenli hale getir
chmod 600 /etc/ssl/tavla/origin-key.pem
chmod 644 /etc/ssl/tavla/origin.pem
chown root:root /etc/ssl/tavla/*
```

---

## 6. Nginx Kurulumu

```bash
# Nginx config dosyasını kopyala
cp /opt/tavla/deploy/nginx/tavla.berkecansakalar.com.conf \
   /etc/nginx/sites-available/tavla.berkecansakalar.com.conf

# Symlink oluştur (sites-enabled)
ln -sf /etc/nginx/sites-available/tavla.berkecansakalar.com.conf \
       /etc/nginx/sites-enabled/tavla.berkecansakalar.com.conf

# Nginx config syntax testi
nginx -t

# Eğer "syntax is ok" derse → Nginx'i reload et
systemctl reload nginx
```

**Beklenen çıktı:**
```
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
```

> ❌ Hata alırsan `nginx -t` çıktısındaki satır numarasına bak.

---

## 7. Production .env Dosyası

```bash
cd /opt/tavla/deploy

# Template'den kopyala
cp .env.example .env

# Güçlü secret'lar üret ve yaz
nano .env
```

**Her secret alanı için güçlü değer üret:**

```bash
# PostgreSQL şifresi
openssl rand -base64 32

# JWT Secret
openssl rand -base64 48

# JWT Refresh Secret
openssl rand -base64 48

# Session Secret
openssl rand -base64 48
```

**Örnek doldurulmuş `.env` (kendi değerlerini koy!):**

```env
POSTGRES_DB=tavla_db
POSTGRES_USER=tavla_user
POSTGRES_PASSWORD=AbCdEfGhIjKlMnOpQrStUvWxYz123456789012==

JWT_SECRET=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx==
JWT_REFRESH_SECRET=yyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy==
JWT_EXPIRES_IN=15m
JWT_REFRESH_EXPIRES_IN=7d

SESSION_SECRET=zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz==

MOVE_TIMER_SECONDS=60
RECONNECT_WINDOW_SECONDS=60
```

> ⚠️ Bu `.env` dosyası **asla git'e push edilmez**. `.gitignore`'da zaten tanımlı.

---

## 8. Docker Compose — Build & Run

```bash
cd /opt/tavla/deploy

# İlk kez — Build ve başlat
docker compose -f docker-compose.prod.yml up --build -d

# Container durumunu kontrol et
docker compose -f docker-compose.prod.yml ps
```

**Beklenen çıktı:**

```
NAME                STATUS              PORTS
tavla-prod-db       Up (healthy)        5432/tcp
tavla-prod-server   Up                  127.0.0.1:3005->3000/tcp
```

> **Not:** DB portu dışarıya açık DEĞİL (güvenlik). Server sadece `127.0.0.1:3005`'ten erişilebilir (Nginx üzerinden).

---

## 9. Veritabanı Migration & Seed

```bash
# Tabloları oluştur
docker exec tavla-prod-server node src/models/migrate.js

# Admin kullanıcı oluştur (admin / admin123456)
docker exec tavla-prod-server node src/models/seed.js
```

> ⚠️ **Admin şifresini hemen değiştirin!** Admin paneline `https://tavla.berkecansakalar.com/admin` adresinden giriş yapıp şifreyi güncelleyin ya da veritabanında değiştirin:
>
> ```bash
> # Veritabanına bağlan
> docker exec -it tavla-prod-db psql -U tavla_user -d tavla_db
>
> # Yeni bcrypt hash oluşturmak için Node.js kullan:
> docker exec -it tavla-prod-server node -e "
>   const bcrypt = require('bcrypt');
>   bcrypt.hash('YENI_SIFRE', 12).then(h => console.log(h));
> "
>
> # Sonra psql'de:
> UPDATE users SET password_hash = 'HASH_DEGERI' WHERE username = 'admin';
> ```

---

## 10. Doğrulama ve Test

### Health Check
```bash
curl https://tavla.berkecansakalar.com/health
```

**Beklenen cevap:**
```json
{"status":"ok","uptime":123.456}
```

### SSL ve Güvenlik Başlıkları
```bash
curl -I https://tavla.berkecansakalar.com
```

**Beklenilen header'lar:**
```
HTTP/2 200
x-frame-options: SAMEORIGIN
x-content-type-options: nosniff
x-xss-protection: 1; mode=block
strict-transport-security: max-age=31536000; includeSubDomains
referrer-policy: strict-origin-when-cross-origin
```

### API Testi
```bash
# Register
curl -X POST https://tavla.berkecansakalar.com/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"username":"testuser","email":"test@test.com","password":"test12345"}'

# Login
curl -X POST https://tavla.berkecansakalar.com/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"identifier":"testuser","password":"test12345"}'

# Leaderboard
curl https://tavla.berkecansakalar.com/api/leaderboard
```

### Admin Panel
Tarayıcıda açın: `https://tavla.berkecansakalar.com/admin`

### Docker Logları
```bash
# Server logları (son 50 satır)
docker logs tavla-prod-server --tail 50

# Canlı log takibi
docker logs tavla-prod-server -f

# DB logları
docker logs tavla-prod-db --tail 20
```

---

## 11. Flutter APK Kurulumu

Masaüstündeki `tavla_online_prod.apk` dosyasını telefona aktarın:

**Yöntem 1 — USB ile:**
- APK'yı USB ile telefona kopyalayın → Dosya yöneticisinden açın → Yükleyin

**Yöntem 2 — ADB ile:**
```bash
adb install tavla_online_prod.apk
```

**Yöntem 3 — Google Drive / Telegram:**
- APK'yı Drive'a yükleyin → Telefondan indirip yükleyin

> ⚠️ "Bilinmeyen kaynaklardan uygulama yüklemeye izin ver" seçeneği açık olmalı.

---

## 12. Güncelleme Prosedürü

Kod değişikliği yaptığında VPS'teki uygulamayı güncellemek için:

### Hızlı Güncelleme (sadece kod değişikliği)

```bash
cd /opt/tavla

# 1. Son değişiklikleri çek
git pull origin main

# 2. Server'ı yeniden build et ve başlat
cd deploy
docker compose -f docker-compose.prod.yml up --build -d

# 3. (Gerekirse) Migration çalıştır
docker exec tavla-prod-server node src/models/migrate.js
```

### Nginx Config Güncellemesi

```bash
cd /opt/tavla

# 1. Değişiklikleri çek
git pull origin main

# 2. Nginx config'i güncelle
cp deploy/nginx/tavla.berkecansakalar.com.conf \
   /etc/nginx/sites-available/tavla.berkecansakalar.com.conf

# 3. Syntax testi ve reload
nginx -t && systemctl reload nginx
```

### Flutter APK Güncellemesi

Lokal bilgisayarında:
```bash
cd mobile
flutter build apk --release \
  --dart-define=API_BASE_URL=https://tavla.berkecansakalar.com \
  --dart-define=SOCKET_URL=https://tavla.berkecansakalar.com
```

Yeni APK'yı telefona yükle (eski sürümün üzerine yüklenir).

---

## 13. Yedekleme

### Veritabanı Yedeği Alma

```bash
# Tek seferlik yedek
docker exec tavla-prod-db pg_dump -U tavla_user tavla_db > /opt/tavla/backups/tavla_$(date +%Y%m%d_%H%M%S).sql

# Sıkıştırılmış yedek
docker exec tavla-prod-db pg_dump -U tavla_user tavla_db | gzip > /opt/tavla/backups/tavla_$(date +%Y%m%d).sql.gz
```

### Yedekten Geri Yükleme

```bash
# Önce mevcut DB'yi temizle (DİKKAT!)
docker exec -i tavla-prod-db psql -U tavla_user -d tavla_db < /opt/tavla/backups/tavla_YYYYMMDD.sql
```

### Otomatik Günlük Yedek (Crontab)

```bash
crontab -e
```

Ekle:
```cron
# Her gece 03:00'te tavla DB yedeği
0 3 * * * docker exec tavla-prod-db pg_dump -U tavla_user tavla_db | gzip > /opt/tavla/backups/tavla_$(date +\%Y\%m\%d).sql.gz

# 30 günden eski yedekleri sil
0 4 * * * find /opt/tavla/backups/ -name "tavla_*.sql.gz" -mtime +30 -delete
```

```bash
# Backup dizinini oluştur
mkdir -p /opt/tavla/backups
```

---

## 14. Troubleshooting

### Container başlamıyorsa

```bash
# Logları kontrol et
docker logs tavla-prod-server --tail 100
docker logs tavla-prod-db --tail 100

# Container detaylarını gör
docker inspect tavla-prod-server

# Yeniden başlat
cd /opt/tavla/deploy
docker compose -f docker-compose.prod.yml restart
```

### "Port already in use" hatası

```bash
# 3005 portunu kim kullanıyor?
lsof -i :3005

# Gerekirse container'ı durdur
docker stop tavla-prod-server
docker compose -f docker-compose.prod.yml down
docker compose -f docker-compose.prod.yml up -d
```

### Nginx 502 Bad Gateway

```bash
# Server container çalışıyor mu?
docker ps | grep tavla-prod-server

# Server logları
docker logs tavla-prod-server --tail 50

# Port dinleniyor mu?
curl http://127.0.0.1:3005/health
```

### WebSocket bağlantı sorunu

```bash
# Nginx WebSocket logları
tail -f /var/log/nginx/tavla.berkecansakalar.com.error.log

# Socket.IO token sorunu olabilir — server loglarını kontrol et
docker logs tavla-prod-server -f | grep -i socket
```

### DB bağlantı hatası

```bash
# DB container healthy mi?
docker ps | grep tavla-prod-db

# DB'ye bağlanabilir mi?
docker exec tavla-prod-server node -e "
  const db = require('./src/models/db');
  db.query('SELECT NOW()').then(r => {
    console.log('DB OK:', r.rows[0].now);
    process.exit(0);
  }).catch(e => {
    console.error('DB FAIL:', e.message);
    process.exit(1);
  });
"
```

### Tüm sistemi sıfırdan başlatma

```bash
cd /opt/tavla/deploy

# Durdur ve volume'ları koru
docker compose -f docker-compose.prod.yml down

# Yeniden build et ve başlat
docker compose -f docker-compose.prod.yml up --build -d

# Migration (tablolar zaten varsa hata vermez)
docker exec tavla-prod-server node src/models/migrate.js
```

> ⚠️ **Volume'ları silme!** `docker compose down -v` kullanırsan tüm veritabanı verileri silinir.

---

## 15. Faydalı Komutlar

```bash
# ─── Container Yönetimi ────────────────────────────
docker compose -f docker-compose.prod.yml ps        # Durumları gör
docker compose -f docker-compose.prod.yml logs -f   # Canlı loglar
docker compose -f docker-compose.prod.yml restart   # Yeniden başlat
docker compose -f docker-compose.prod.yml stop      # Durdur
docker compose -f docker-compose.prod.yml start     # Başlat
docker compose -f docker-compose.prod.yml down      # Kapat (volume kalır)

# ─── Server ────────────────────────────────────────
docker exec -it tavla-prod-server sh               # Container shell
docker stats tavla-prod-server tavla-prod-db       # CPU/RAM kullanımı

# ─── Veritabanı ────────────────────────────────────
docker exec -it tavla-prod-db psql -U tavla_user -d tavla_db  # SQL shell
docker exec tavla-prod-db psql -U tavla_user -d tavla_db -c "SELECT count(*) FROM users;"
docker exec tavla-prod-db psql -U tavla_user -d tavla_db -c "SELECT count(*) FROM games;"

# ─── Nginx ─────────────────────────────────────────
nginx -t                                           # Config syntax testi
systemctl status nginx                             # Nginx durumu
systemctl reload nginx                             # Config reload
tail -f /var/log/nginx/tavla.berkecansakalar.com.access.log   # Erişim logları
tail -f /var/log/nginx/tavla.berkecansakalar.com.error.log    # Hata logları

# ─── Disk & Temizlik ──────────────────────────────
docker system df                                   # Docker disk kullanımı
docker system prune -f                             # Kullanılmayan objeleri temizle
docker image prune -f                              # Eski image'ları temizle
```

---

## 📁 Dosya Haritası — Ne Nereye Gidiyor?

### GitHub'tan çekilen dosyalar (`/opt/tavla/`):

```
/opt/tavla/
├── deploy/
│   ├── docker-compose.prod.yml    ← Docker Compose production
│   ├── .env.example               ← Env şablonu
│   ├── .env                       ← 🔒 SEN OLUŞTURACAKSIN (git'te yok)
│   └── nginx/
│       └── tavla.berkecansakalar.com.conf  ← Nginx config
├── server/                        ← Node.js backend kodu
│   ├── Dockerfile                 ← Docker image build
│   ├── src/                       ← Uygulama kodu
│   └── package.json
├── mobile/                        ← Flutter kodu (VPS'te gerekli değil)
├── docs/                          ← Dokümantasyon
├── SERVER.md                      ← Bu dosya
└── README.md
```

### VPS'te sen oluşturacağın dosyalar:

```
/etc/ssl/tavla/
├── origin.pem          ← Cloudflare Origin Certificate
└── origin-key.pem      ← Cloudflare Private Key

/etc/nginx/sites-available/
└── tavla.berkecansakalar.com.conf  ← deploy/nginx/'den kopyalandı

/etc/nginx/sites-enabled/
└── tavla.berkecansakalar.com.conf  → symlink (sites-available'a)

/opt/tavla/deploy/
└── .env                ← Production secret'lar (sen oluşturacaksın)

/opt/tavla/backups/     ← Veritabanı yedekleri (sen oluşturacaksın)
```

---

## 🔐 Güvenlik Kontrol Listesi

- [ ] `.env` dosyasında güçlü, benzersiz rastgele secret'lar kullanıldı
- [ ] Admin şifresi `admin123456`'dan değiştirildi
- [ ] Cloudflare SSL mode: `Full (strict)`
- [ ] Cloudflare Proxy aktif (turuncu bulut)
- [ ] PostgreSQL portu dışarıya kapalı (sadece Docker internal)
- [ ] Server portu sadece `127.0.0.1:3005` (sadece localhost)
- [ ] SSL key izinleri: `chmod 600`
- [ ] Otomatik yedekleme crontab'a eklendi

---

## ⚡ Hızlı Başlangıç Özeti (TL;DR)

```bash
# 1. Repo çek
cd /opt && git clone https://<TOKEN>@github.com/bcsakalar/tavla-game.git tavla && cd tavla

# 2. SSL sertifika
mkdir -p /etc/ssl/tavla
nano /etc/ssl/tavla/origin.pem       # Cloudflare cert yapıştır
nano /etc/ssl/tavla/origin-key.pem   # Cloudflare key yapıştır
chmod 600 /etc/ssl/tavla/origin-key.pem

# 3. Nginx
cp deploy/nginx/tavla.berkecansakalar.com.conf /etc/nginx/sites-available/
ln -sf /etc/nginx/sites-available/tavla.berkecansakalar.com.conf /etc/nginx/sites-enabled/
nginx -t && systemctl reload nginx

# 4. Env + Docker
cd deploy && cp .env.example .env && nano .env   # Secret'ları doldur
docker compose -f docker-compose.prod.yml up --build -d

# 5. DB hazırlık
docker exec tavla-prod-server node src/models/migrate.js
docker exec tavla-prod-server node src/models/seed.js

# 6. Test
curl https://tavla.berkecansakalar.com/health
```
