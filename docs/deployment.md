# RezidansPro — Canlıya Alma ve Dağıtım Rehberi (Deployment)

Bu kılavuz, RezidansPro arka yüz servislerinin (FastAPI + PostgreSQL) sunucuda yayına alınmasını ve mobil uygulamanın (Flutter) Google Play Store için derlenip yayınlanmasını adım adım açıklar.

---

## 1. Backend Dağıtımı (Docker & Production Server)

### 1.1. Docker Compose ile Hızlı Dağıtım

Proje kök dizininde veya backend klasöründe bir `docker-compose.yml` dosyası oluşturulabilir:

```yaml
version: '3.8'

services:
  db:
    image: postgres:16-alpine
    restart: always
    environment:
      POSTGRES_DB: rezidanspro_db
      POSTGRES_USER: rezidans_user
      POSTGRES_PASSWORD: StrongProductionPassword2026!
    volumes:
      - postgres_data:/var/lib/postgresql/data
    ports:
      - "5432:5432"

  api:
    build:
      context: ./backend
      dockerfile: Dockerfile
    restart: always
    environment:
      DATABASE_URL: postgresql+psycopg2://rezidans_user:StrongProductionPassword2026!@db:5432/rezidanspro_db
      JWT_SECRET: super_secure_production_jwt_secret_key_change_in_prod
      JWT_REFRESH_SECRET: super_secure_production_refresh_jwt_key_change_in_prod
      APP_ENV: production
    ports:
      - "8000:8000"
    depends_on:
      - db

volumes:
  postgres_data:
```

### 1.2. Alembic Migrasyonlarını Çalıştırma
Canlı veritabanı şemasını güncellemek için:
```bash
docker compose exec api alembic upgrade head
```

Demo verilerini oluşturmak için (İsteğe bağlı):
```bash
docker compose exec api python -m app.core.db.init_db
```

### 1.3. Nginx & SSL (Tersine Vekil - Reverse Proxy)
FastAPI uygulamasını güvenli HTTPS üzerinden sunmak için örnek Nginx bloğu:
```nginx
server {
    server_name api.rezidanspro.app;

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    listen 443 ssl;
    ssl_certificate /etc/letsencrypt/live/api.rezidanspro.app/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.rezidanspro.app/privkey.pem;
}
```

---

## 2. Mobil Dağıtım (Google Play Store Release)

### 2.1. Paket Bilgileri
- **Uygulama Adı**: RezidansPro
- **Paket Adı (Application ID)**: `com.rezidanspro.app`
- **Sürüm Kodu (Version Code)**: `1`
- **Sürüm Adı (Version Name)**: `1.0.0`
- **Hedef SDK (Target SDK)**: 34 (Android 14)
- **Minimum SDK (Min SDK)**: 24 (Android 7.0)

### 2.2. Android İmza Anahtarı (Keystore) Oluşturma
Üretim ortamı için imzalama anahtarı oluşturun:
```bash
keytool -genkey -v -keystore rezidanspro-upload-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

### 2.3. `key.properties` Dosyasını Yapılandırma
`mobile/android/key.properties` dosyasını oluşturun (Bu dosya `.gitignore` içinde olmalıdır):
```properties
storePassword=YourStorePassword
keyPassword=YourKeyPassword
keyAlias=upload
storeFile=/path/to/rezidanspro-upload-key.jks
```

### 2.4. Google Play Android App Bundle (AAB) Derleme
Google Play Store artık APK yerine optimize `.aab` formatını zorunlu kılmaktadır:
```bash
cd mobile
flutter clean
flutter pub get
flutter build appbundle --release
```
Derlenen dosya: `mobile/build/app/outputs/bundle/release/app-release.aab`

---

## 3. Google Play Console Yayınlama Kontrol Listesi

1. **Uygulama Kimliği & Başlık**:
   - Mağaza Başlığı: `RezidansPro - Apartman & Site`
   - Kısa Açıklama: `Binanızın iletişim merkezi. Duyuru, arıza, toplantı ve aidat yönetimi tek uygulamada.`
2. **Grafik Varlıkları**:
   - Uygulama Simgesi: 512x512 PNG (`mobile/assets/icons/app_icon_1024.svg` kaynaklı).
   - Özellik Grafiği (Feature Graphic): 1024x500 PNG.
   - Telefon ve Tablet Ekran Görüntüleri (En az 4 adet: Sakin Ana Sayfası, Yönetici Paneli, Arıza Bildirimi, Aidat Ekranı).
3. **Veri Güvenliği Formu (Data Safety)**:
   - Kullanıcı Bilgileri: Ad, Soyad, E-posta (Hesap yönetimi için).
   - Fotoğraflar: Kullanıcı tarafından arıza bildirimine eklenen teknik görseller (İsteğe bağlı).
   - Veri Şifreleme: Tüm veriler HTTPS/TLS üzerinden iletilmektedir.
   - Hesap Silme: Kullanıcılar uygulama içerisinden veya web üzerinden hesaplarını silebilir (`DELETE /api/v1/auth/account`).
4. **Gizlilik Politikası (Privacy Policy)**:
   - URL: `https://rezidanspro.app/privacy-policy`
