# Tavla Online — Komutlar ve Script'ler

> **Son güncelleme:** 2026-03-24
> Projeyi çalıştırmak, test etmek ve deploy etmek için gereken tüm komutlar

---

## 1. Geliştirme Ortamını Ayağa Kaldırma

### 1.1 Ön Koşullar

- Docker & Docker Compose
- Node.js 20+ (lokal geliştirme için)
- Flutter SDK 3.16+ (mobil uygulama için)
- Git

### 1.2 İlk Kurulum (Sıfırdan)

```bash
# 1. Repo'yu klonla
git clone https://github.com/bcsakalar/tavla-game.git
cd tavla-game

# 2. Docker container'larını başlat (PostgreSQL + Server)
cd docker
docker compose -f docker-compose.dev.yml up --build -d

# 3. Veritabanı tablolarını oluştur
docker exec tavla-server node src/models/migrate.js

# 4. Admin kullanıcıyı seed et (admin / admin123456)
docker exec tavla-server node src/models/seed.js

# 5. Flutter uygulamasını çalıştır
cd ../mobile
flutter pub get
flutter run
```

### 1.3 Günlük Geliştirme Başlatma

```bash
# Container'ları başlat (zaten build edilmişse)
cd docker
docker compose -f docker-compose.dev.yml up -d

# Flutter çalıştır
cd ../mobile
flutter run

# Admin paneli aç: http://localhost:3006/admin
# API endpoint: http://localhost:3006/api
# Redis CLI: docker exec -it tavla-redis redis-cli
```

---

## 2. Docker Komutları

### 2.1 Geliştirme (docker/docker-compose.dev.yml)

```bash
# Container'ları build edip başlat
docker compose -f docker-compose.dev.yml up --build -d

# Container'ları başlat (rebuild olmadan)
docker compose -f docker-compose.dev.yml up -d

# Container'ları durdur
docker compose -f docker-compose.dev.yml down

# Container'ları durdur + volume'ları sil (DB verisi dahil!)
docker compose -f docker-compose.dev.yml down -v

# Logları izle
docker compose -f docker-compose.dev.yml logs -f

# Sadece server logları
docker logs -f tavla-server

# Sadece DB logları
docker logs -f tavla-db

# Redis logları
docker logs -f tavla-redis

# Redis CLI bağlantısı
docker exec -it tavla-redis redis-cli

# Container durumlarını kontrol et
docker compose -f docker-compose.dev.yml ps

# Server container'ına shell aç
docker exec -it tavla-server sh

# DB container'ına psql ile bağlan
docker exec -it tavla-db psql -U tavla_user -d tavla_db
```

### 2.2 Üretim (deploy/docker-compose.prod.yml)

```bash
# ÖNEMLİ: .env dosyası deploy/ dizininde olmalı
cd deploy

# Container'ları build edip başlat
docker compose -f docker-compose.prod.yml up --build -d

# Migration
docker exec tavla-prod-server node src/models/migrate.js
docker exec tavla-prod-server node src/models/seed.js

# Güncelleme
git pull origin main
docker compose -f docker-compose.prod.yml up --build -d

# Logları kontrol et
docker logs -f tavla-prod-server

# Health check
curl https://tavla.berkecansakalar.com/health
```

---

## 3. Server (Node.js) Komutları

### 3.1 npm Script'leri (server/package.json)

```bash
cd server

# Sunucuyu başlat (NODE_ENV=production)
npm start

# Geliştirme modunda başlat (nodemon ile hot-reload)
npm run dev

# Tüm testleri çalıştır (coverage ile)
npm test

# Testleri izleme modunda çalıştır
npm run test:watch

# Sadece unit testleri çalıştır
npm run test:unit

# ESLint kontrolü
npm run lint

# ESLint otomatik düzeltme
npm run lint:fix
```

### 3.2 Veritabanı Yönetimi

```bash
# Migration — Tabloları oluştur/güncelle
docker exec tavla-server node src/models/migrate.js

# Seed — Admin kullanıcı oluştur
docker exec tavla-server node src/models/seed.js

# DB'ye doğrudan bağlan (geliştirme)
docker exec -it tavla-db psql -U tavla_user -d tavla_db

# Lokal psql bağlantısı (port 5436)
psql -h localhost -p 5436 -U tavla_user -d tavla_db

# Tüm tabloları listele
docker exec tavla-db psql -U tavla_user -d tavla_db -c "\dt"

# Kullanıcı sayısını kontrol et
docker exec tavla-db psql -U tavla_user -d tavla_db -c "SELECT COUNT(*) FROM users;"

# Aktif oyunları kontrol et
docker exec tavla-db psql -U tavla_user -d tavla_db -c "SELECT * FROM games WHERE status = 'playing';"
```

### 3.3 Veritabanı Yedekleme

```bash
# Manuel yedekleme
docker exec tavla-prod-db pg_dump -U tavla_user tavla_db | gzip > backup_$(date +%Y%m%d).sql.gz

# Yedeği geri yükle
gunzip < backup_20260316.sql.gz | docker exec -i tavla-prod-db psql -U tavla_user -d tavla_db

# Otomatik yedekleme (cron — her gece 03:00)
# crontab -e ile ekle:
0 3 * * * docker exec tavla-prod-db pg_dump -U tavla_user tavla_db | gzip > /opt/backups/tavla_$(date +\%Y\%m\%d).sql.gz
```

---

## 4. Flutter (Mobile) Komutları

### 4.1 Temel Geliştirme

```bash
cd mobile

# Bağımlılıkları yükle
flutter pub get

# Uygulamayı çalıştır (bağlı cihaz/emülatörde)
flutter run

# Web'de çalıştır
flutter run -d chrome

# Release modunda çalıştır (performans testi)
flutter run --release

# Lokal API/socket override ile çalıştır
./run_dev.sh

# Hot restart (terminal'den)
# r → hot reload
# R → hot restart
# q → çık
```

### 4.2 Build

```bash
# Android APK (debug)
flutter build apk --debug

# Android APK (release)
flutter build apk --release

# Production domain dart-define'ları ile release APK
./build_prod.sh

# Android App Bundle (Play Store)
flutter build appbundle --release

# Web build
flutter build web --release

# Build çıktı konumu:
# APK: mobile/build/app/outputs/flutter-apk/app-release.apk
# Web: mobile/build/web/
```

> **Not:** `API_BASE_URL` ve `SOCKET_URL` değerleri domain kökü olarak verilmelidir. `/api` eklenmez çünkü istemci request path'leri zaten `/api/...` ile başlar.

### 4.3 Test

```bash
# Tüm testleri çalıştır
flutter test

# Belirli bir test dosyası
flutter test test/widget_test.dart

# Coverage ile
flutter test --coverage

# Dart analiz (linting)
flutter analyze
```

### 4.4 Temizlik ve Bakım

```bash
# Build cache'ini temizle
flutter clean

# Pub cache'ini yenile
flutter pub get

# Flutter SDK güncelle
flutter upgrade

# Doktor kontrolü (ortam doğrulama)
flutter doctor

# Bağımlılık güvenlik kontrolü
flutter pub outdated
```

---

## 5. Test Komutları (Detaylı)

### 5.1 Server Testleri

```bash
cd server

# Tüm testler + coverage raporu
npm test
# Çıktı: coverage/ dizini (HTML rapor: coverage/lcov-report/index.html)

# Sadece belirli bir test dosyası
npx jest tests/unit/moves.test.js

# Sadece belirli bir test bloğu
npx jest tests/unit/engine.test.js -t "should create a new game"

# Verbose modda (detaylı çıktı)
npx jest --verbose

# Watch modda (dosya değişikliklerini izle)
npx jest --watch

# Coverage eşik kontrolü
npx jest --coverage --coverageThreshold='{"global":{"branches":80,"functions":80,"lines":80,"statements":80}}'
```

### 5.2 Flutter Testleri

```bash
cd mobile

# Tüm testleri çalıştır
flutter test

# Belirli test dosyası
flutter test test/widget_test.dart

# Coverage ile
flutter test --coverage
# Çıktı: mobile/coverage/lcov.info
```

---

## 6. Nginx Komutları (Üretim Sunucusu)

```bash
# Konfigürasyonu test et
sudo nginx -t

# Nginx'i yeniden yükle (sıfır kesinti)
sudo systemctl reload nginx

# Nginx'i yeniden başlat
sudo systemctl restart nginx

# Nginx logları
sudo tail -f /var/log/nginx/tavla.berkecansakalar.com.access.log
sudo tail -f /var/log/nginx/tavla.berkecansakalar.com.error.log

# Nginx durumu
sudo systemctl status nginx
```

---

## 7. API Test Komutları (curl)

```bash
BASE_URL="http://localhost:3006"

# Kayıt
curl -X POST $BASE_URL/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"username":"test","email":"test@test.com","password":"test12345"}'

# Giriş
curl -X POST $BASE_URL/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"identifier":"test","password":"test12345"}'

# Profil (token gerekli)
TOKEN="eyJhbGciOiJIUzI1NiIs..."
curl -H "Authorization: Bearer $TOKEN" $BASE_URL/api/users/me

# Leaderboard
curl $BASE_URL/api/leaderboard

# Token yenileme
curl -X POST $BASE_URL/api/auth/refresh \
  -H "Content-Type: application/json" \
  -d '{"refreshToken":"..."}'

# Health check
curl $BASE_URL/health
```

---

## 8. Sorun Giderme Komutları

```bash
# Container durumlarını kontrol et
docker ps -a

# Container kaynak kullanımı
docker stats

# Port kullanımını kontrol et
# Windows:
netstat -ano | findstr :3006
netstat -ano | findstr :5436

# Linux:
ss -tlnp | grep -E '3005|5432'

# Docker disk kullanımı
docker system df

# Kullanılmayan Docker kaynaklarını temizle
docker system prune -f

# Volume'ları temizle (DİKKAT: DB verisi silinir!)
docker volume prune -f

# Server container'ını yeniden başlat
docker restart tavla-server

# DB bağlantı testi
docker exec tavla-db pg_isready -U tavla_user -d tavla_db
```

---

## 9. Environment Değişkenleri

### 9.1 Geliştirme (.env veya docker-compose.dev.yml)

```env
NODE_ENV=development
PORT=3000
DATABASE_URL=postgresql://tavla_user:changeme@postgres:5432/tavla_db
JWT_SECRET=change-me-in-development
JWT_REFRESH_SECRET=change-me-in-development
SESSION_SECRET=change-me-in-development
CORS_ORIGIN=*
POSTGRES_PASSWORD=changeme
REDIS_URL=redis://redis:6379
ADMIN_PASSWORD=dev-admin-pass
```

### 9.2 Üretim (deploy/.env — GEREKLİ)

```env
POSTGRES_DB=tavla_db
POSTGRES_USER=tavla_user
POSTGRES_PASSWORD=<openssl rand -base64 32>
JWT_SECRET=<openssl rand -base64 48>
JWT_REFRESH_SECRET=<openssl rand -base64 48>
SESSION_SECRET=<openssl rand -base64 48>
JWT_EXPIRES_IN=15m
JWT_REFRESH_EXPIRES_IN=7d
MOVE_TIMER_SECONDS=60
RECONNECT_WINDOW_SECONDS=60
REDIS_URL=redis://redis:6379
ADMIN_PASSWORD=<openssl rand -base64 16>
```

### 9.3 Flutter (mobile/lib/core/config/app_config.dart)

```dart
static const String apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:3006',
);
static const String socketUrl = String.fromEnvironment(
  'SOCKET_URL',
  defaultValue: 'http://localhost:3006',
);
```

Özel URL ile flutter çalıştırma:
```bash
flutter run --dart-define=API_BASE_URL=https://tavla.berkecansakalar.com --dart-define=SOCKET_URL=https://tavla.berkecansakalar.com
```
