# RezidansPro — Apartman, Site ve Rezidans Yönetim Platformu

> **"Binanızın iletişim merkezi."**  
> Modern, güvenli ve kurumsal apartman, site ve rezidans yönetim mobil uygulaması.

---

## 🌟 Ürün Vizyonu ve Temel İlkeler

RezidansPro; apartman, site, rezidans, toplu konut ve küçük konut kompleksleri için iletişim, duyuru, arıza bildirimi, toplantı, anket, aidat bilgilendirme ve yönetici-sakin etkileşimini tek bir mobil platformda birleştiren yeni nesil bir uygulamadır.

### 🛡️ Temel Tasarım Kuralları
1. **YÖNETİCİ VE SAKİN KESİN AYRIMI**:
   - Sakinler (`RESIDENT`) ve Yöneticiler (`MANAGER`) farklı arayüz ve yetkilere sahiptir.
   - Yetkilendirme kontrolleri hem Flutter istemcisinde hem de FastAPI backend katmanında sıkı biçimde uygulanır.
2. **AİDAT BORCU BİLGİSİ ASLA KAMUYA AÇIK DEĞİLDİR (Aidat Gizliliği)**:
   - Bir kişinin aidat borcu ana sayfada, bina duyurularında, komşular listesinde, grup mesajlarında veya kilit ekranı bildirimlerinde **kesinlikle görünemez**.
   - Sadece **ilgili sakin** ve **yetkili yönetici** tarafından görüntülenebilir.
3. **SOSYAL MEDYA DEĞİLDİR**:
   - Takip etme, beğeni, açık profil akışı gibi dedikoduya veya suistimale açık sosyal özellikler içermez.
   - İletişim, sakin ile yönetici arasında 1-e-1 güvenli hat üzerinden yürütülür.

---

## 🚀 Teknoloji Mimarisi

- **Mobil Uygulama**:
  - Flutter 3.47+ / Dart 3.13+
  - Google Material 3 Tasarım Sistemi (`useMaterial3: true`)
  - SaaS estetiği, yumuşak gölgeler, 12-16px kart yuvarlatmaları
  - State Management: `Provider` & `ChangeNotifier`
  - Çoklu Dil Desteği: Türkçe & İngilizce (`AppLocalizations`)
  - Paket Kimliği: `com.rezidanspro.app` (Version 1.0.0)
- **Sunucu & API (Backend)**:
  - Python 3.12+ / FastAPI
  - ORM: SQLAlchemy 2.0 (`Mapped[T]`)
  - Veritabanı Migrasyonları: Alembic
  - Kimlik Doğrulama: JWT (Access Token 120 dk, Refresh Token 30 gün) + Argon2 / bcrypt Parola Şifreleme
  - Veritabanı: PostgreSQL (Geliştirme ve hızlı testler için SQLite desteği)
- **Güvenlik & Uyumluluk**:
  - Google Play Store ve GDPR/KVKK uyumlu Hesap Silme (`DELETE /api/v1/auth/account`)
  - Katı RBAC (Role-Based Access Control)
  - Denetim İzi (Audit Logging)

---

## 📁 Dizin Yapısı

```
rezidanspro/
├── mobile/                  # Flutter Mobil Uygulama Projesi
│   ├── lib/
│   │   ├── core/            # Config, Theme, Routing, Models, Services, Localizations
│   │   ├── features/        # Auth, Onboarding, Home, Announcements, Maintenance, Dues, Meetings, Polls, Messages, Profile
│   │   └── widgets/         # Yeniden kullanılabilir UI bileşenleri (StatKpiCard, StatusBadge, PriorityBadge, vb.)
│   ├── assets/              # SVG Logo, Launcher ikonları
│   ├── test/                # Flutter Widget ve Birim Testleri
│   └── android/             # Android yapılandırması (build.gradle.kts, AndroidManifest.xml)
├── backend/                 # FastAPI REST API Sunucusu
│   ├── app/
│   │   ├── api/v1/          # Endpoint yönlendirmeleri (auth, communities, dues, maintenance, vb.)
│   │   ├── core/            # Config, Session, DB Init, Auth Dependencies, Security
│   │   ├── models/          # 20 SQLAlchemy Tablo Modeli
│   │   └── schemas/         # Pydantic v2 Doğrulama Şemaları
│   ├── alembic/             # Veritabanı migrasyon scriptleri
│   ├── tests/               # Pytest otomatik güvenlik ve yetki testleri
│   └── requirements.txt     # Python bağımlılıkları
├── docs/                    # Detaylı Teknik Dokümantasyon
│   ├── architecture.md      # Sistem mimarisi ve ilkeler
│   ├── api.md               # REST API uç nokta referansı
│   ├── database.md          # Veritabanı şeması ve ilişkiler
│   ├── security.md          # Güvenlik ve gizlilik modeli
│   └── deployment.md        # Canlı sunucu ve Google Play yayınlama kılavuzu
├── .env.example             # Örnek çevre değişkenleri
└── README.md                # Ana proje tanıtımı
```

---

## ⚡ Hızlı Başlangıç

### 1. Backend Kurulumu ve Çalıştırma

```bash
cd backend

# Sanal ortam oluşturma ve etkinleştirme
python -m venv .venv
# Windows:
.venv\Scripts\activate
# Linux/macOS:
# source .venv/bin/activate

# Bağımlılıkları yükleme
pip install -r requirements.txt

# Veritabanı migrasyonlarını uygulama
alembic upgrade head

# Demo verilerini (Gül Sitesi, 20 daire, duyurular, aidatlar) oluşturma
python -m app.core.db.init_db

# FastAPI sunucusunu başlatma
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```
Swagger API dokümantasyonuna `http://localhost:8000/docs` adresinden erişebilirsiniz.

### 2. Hazır Demo Kullanıcı Hesapları

Veritabanında önceden hazırlanmış test kullanıcıları:

| Rol | E-Posta | Parola | Açıklama |
|---|---|---|---|
| **Yönetici (Manager)** | `manager@rezidanspro.app` | `RezidansPro123!` | Gül Sitesi Yöneticisi (Tüm bina yetkileri) |
| **Sakin (Resident)** | `resident@rezidanspro.app` | `RezidansPro123!` | A Blok Daire 1 Sakini (Kişisel ekranlar) |

### 3. Mobil Uygulamayı (Flutter) Çalıştırma

```bash
cd mobile

# Paketleri yükleme
flutter pub get

# Uygulamayı başlatma (Emülatör, Gerçek Cihaz veya Windows Desktop)
flutter run
```

---

## 🧪 Otomatik Testler

Proje, hem arka yüz hem de ön yüz için kapsamlı test suiteleri ile korunmaktadır.

### Backend Testleri (Pytest — 12 Test)
Aidat gizliliği, rol tabanlı erişim engelleri, arıza izolasyonu ve anket tekil oy mekanizmalarını doğrular:
```bash
python -m pytest backend/tests/test_api.py -v
```
*(Sonuç: 12 passed in ~2s)*

### Mobil Testleri (Flutter Test — 11 Test)
Kurumsal renk kodları, model serileştirme, dinamik hızlı işlem menüleri (yönetici vs sakin) ve çoklu dil doğrulamalarını kapsar:
```bash
cd mobile
flutter test
```
*(Sonuç: All 11 tests passed!)*

---

## 📖 Kapsamlı Dokümantasyon Bağlantıları

- [Mimarisi ve Tasarım İlkeleri](docs/architecture.md)
- [REST API Referansı](docs/api.md)
- [Veritabanı Şeması ve Modeller](docs/database.md)
- [Güvenlik ve Gizlilik Rehberi](docs/security.md)
- [Canlıya Alma ve Google Play Yayınlama](docs/deployment.md)

---

## 📄 Lisans ve Telif Hakkı
RezidansPro © 2026. Tüm hakları saklıdır.
