# RezidansPro — REST API Dokümantasyonu

Tüm API uç noktaları `http(s)://<host>/api/v1` önekiyle sunulur.  
Kimlik doğrulama gerektiren tüm istekler `Authorization: Bearer <access_token>` başlığı içermelidir.

---

## 1. Kimlik Doğrulama & Kullanıcı Hesabı (`/auth`)

### 1.1. Kayıt Ol (`POST /auth/register`)
- **Açıklama**: Yeni kullanıcı kaydı oluşturur.
- **Yetki**: Herkese Açık
- **İstek Gövdesi**:
  ```json
  {
    "email": "resident@example.com",
    "password": "StrongPassword123!",
    "first_name": "Ahmet",
    "last_name": "Yılmaz",
    "phone": "+905551234567"
  }
  ```
- **Yanıt (201 Created)**:
  ```json
  {
    "access_token": "eyJhbG...",
    "refresh_token": "eyJhbG...",
    "token_type": "bearer",
    "user": {
      "id": 1,
      "email": "resident@example.com",
      "first_name": "Ahmet",
      "last_name": "Yılmaz",
      "phone": "+905551234567",
      "is_active": true
    }
  }
  ```

### 1.2. Giriş Yap (`POST /auth/login`)
- **Açıklama**: E-posta ve şifre ile JWT çifti alır.
- **Yetki**: Herkese Açık
- **İstek Gövdesi**:
  ```json
  {
    "email": "manager@rezidanspro.app",
    "password": "RezidansPro123!"
  }
  ```
- **Yanıt (200 OK)**: Token çifti ve kullanıcı objesi.

### 1.3. Token Yenile (`POST /auth/refresh`)
- **Açıklama**: Geçerli bir `refresh_token` vererek yeni bir `access_token` alır.
- **Yetki**: Herkese Açık
- **İstek Gövdesi**:
  ```json
  {
    "refresh_token": "eyJhbG..."
  }
  ```
- **Yanıt (200 OK)**: Yeni `access_token` ve `refresh_token`.

### 1.4. Profil Bilgisi (`GET /auth/me`)
- **Açıklama**: Oturum açmış kullanıcının profil ve site üyelik bilgilerini döner.
- **Yetki**: Authenticated User

### 1.5. Hesap Silme (`DELETE /auth/account`)
- **Açıklama**: Google Play Store Kullanıcı Verisi Güvenliği ve KVKK/GDPR gereğince kullanıcı hesabını ve ilişkili kişisel verilerini anonimleştirerek siler.
- **Yetki**: Authenticated User
- **Yanıt (200 OK)**:
  ```json
  {
    "status": "success",
    "message": "Hesabınız ve ilişkili veriler başarıyla silindi."
  }
  ```

---

## 2. Bina & Site Yönetimi (`/communities`)

### 2.1. Site / Bina Oluştur (`POST /communities`)
- **Açıklama**: Yeni bir site kurar ve oluşturan kişiyi otomatik olarak `MANAGER` rolüyle kaydeder.
- **Yetki**: Authenticated User
- **İstek Gövdesi**:
  ```json
  {
    "name": "Gül Sitesi",
    "type": "SITE",
    "address": "Atatürk Mah. Orkide Cad. No:12",
    "city": "İstanbul",
    "district": "Kadıköy"
  }
  ```
- **Yanıt (201 Created)**: Topluluk objesi ve yöneticinin üyelik bilgisi.

### 2.2. Davet Kodu ile Siteye Katıl (`POST /communities/join`)
- **Açıklama**: Yöneticiden alınan davet kodu ile siteye sakin veya yönetici olarak katılır.
- **Yetki**: Authenticated User
- **İstek Gövdesi**:
  ```json
  {
    "invite_code": "GUL2026",
    "apartment_id": 5,
    "is_owner": false
  }
  ```

### 2.3. Blok ve Daire Listesi (`GET /communities/{id}/blocks`, `GET /communities/{id}/apartments`)
- **Açıklama**: Sitedeki blokları ve daireleri listeler.
- **Yetki**: Sitede kayıtlı üye.

### 2.4. Sakin Listesi (`GET /communities/{id}/members`)
- **Açıklama**: Sitedeki üyeleri listeler. Gizlilik prensibi gereği diğer sakinlerin hassas finansal bilgileri ve şahsi iletişim numaraları maskelenir.

---

## 3. Duyurular (`/announcements`)

### 3.1. Duyuruları Listele (`GET /announcements?community_id={id}`)
- **Açıklama**: Sitedeki aktif duyuruları öncelik sıralamasına göre listeler (`URGENT`, `IMPORTANT`, `NORMAL`).
- **Yetki**: Sitede kayıtlı üye.

### 3.2. Yeni Duyuru Yayınla (`POST /announcements`)
- **Açıklama**: Yeni duyuru oluşturur ve sakinlere bildirim tetikler.
- **Yetki**: Yalnızca `MANAGER` veya `ASSISTANT_MANAGER`.
- **İstek Gövdesi**:
  ```json
  {
    "community_id": 1,
    "title": "Asansör Periyodik Bakımı",
    "body": "Pazartesi günü saat 10:00 - 13:00 saatleri arasında A Blok asansörleri bakıma alınacaktır.",
    "priority": "IMPORTANT"
  }
  ```

---

## 4. Arıza Bildirimleri (`/maintenance`)

### 4.1. Arıza Taleplerini Listele (`GET /maintenance?community_id={id}`)
- **Açıklama**:
  - **Sakin**: Yalnızca **kendi bildirdiği** arıza kayıtlarını görür. Başka sakinlerin arızaları gösterilmez.
  - **Yönetici**: Sitedeki **tüm** arıza kayıtlarını görür ve filtreleyebilir.
- **Yetki**: Sitede kayıtlı üye.

### 4.2. Arıza Bildirimi Oluştur (`POST /maintenance`)
- **Açıklama**: Sakin veya yönetici arıza kaydı açar.
- **Yetki**: Sitede kayıtlı üye.
- **İstek Gövdesi**:
  ```json
  {
    "community_id": 1,
    "apartment_id": 3,
    "category": "ELEVATOR",
    "title": "Asansör 3. Katta Durmuyor",
    "description": "Butona basılmasına rağmen 3. kat pas geçiliyor.",
    "priority": "HIGH"
  }
  ```

### 4.3. Arıza Durumu Güncelle (`PATCH /maintenance/{id}/status`)
- **Açıklama**: Arıza durumunu günceller (`OPEN`, `IN_PROGRESS`, `WAITING`, `RESOLVED`, `CLOSED`).
- **Yetki**: Yalnızca `MANAGER`.

### 4.4. Yorum Ekle (`POST /maintenance/{id}/comments`)
- **Açıklama**: Arıza kaydı altına teknik bilgilendirme veya takip mesajı ekler.

---

## 5. Aidat & Finans Modülü (`/dues`) — [GİZLİLİK KRİTİK]

### 5.1. Sakin Kendi Aidat Borçları (`GET /dues/my?community_id={id}`)
- **Açıklama**: Yalnızca oturum açmış sakinin ikamet ettiği veya sahibi olduğu dairelere ait aidatları döner. Başka hiçbir dairenin veya sakinin bilgisi dönmez.
- **Yetki**: Sitede kayıtlı üye.

### 5.2. Yönetici Aidat Takip Listesi (`GET /dues/manager?community_id={id}`)
- **Açıklama**: Yönetici için tüm blok ve dairelerin aidat tahakkuk ve ödeme durumlarını listeler.
- **Yetki**: Yalnızca `MANAGER` veya `ASSISTANT_MANAGER`. Sakin bu uca istek atarsa **HTTP 403 Forbidden** alır.

### 5.3. Yeni Aidat Tahakkuk Ettir (`POST /dues`)
- **Açıklama**: Bir veya tüm dairelere belirli bir dönem için aidat tanımlar.
- **Yetki**: Yalnızca `MANAGER`.

### 5.4. Aidat Ödemesi İşle (`POST /dues/{id}/payments`)
- **Açıklama**: Banka havalesi, nakit veya POS ile alınan aidat ödemesini kaydeder ve durumu `PAID` yapar.
- **Yetki**: Yalnızca `MANAGER`. Sakin tek taraflı ödeme işaretleyemez.

---

## 6. Toplantılar (`/meetings`)

### 6.1. Toplantıları Listele (`GET /meetings?community_id={id}`)
- **Açıklama**: Yaklaşan ve geçmiş genel kurul / kat malikleri toplantılarını listeler.
- **Yetki**: Sitede kayıtlı üye.

### 6.2. Yeni Toplantı Oluştur (`POST /meetings`)
- **Yetki**: Yalnızca `MANAGER`.

### 6.3. Toplantı Katılım Durumu Bildir (`POST /meetings/{id}/rsvp`)
- **İstek Gövdesi**: `{"status": "ATTENDING"}` veya `{"status": "NOT_ATTENDING"}`.
- **Yetki**: Sitede kayıtlı üye.

---

## 7. Anketler (`/polls`)

### 7.1. Anketleri Listele (`GET /polls?community_id={id}`)
- **Yetki**: Sitede kayıtlı üye.

### 7.2. Anket Oluştur (`POST /polls`)
- **Yetki**: Yalnızca `MANAGER`.

### 7.3. Oy Kullan (`POST /polls/{id}/vote`)
- **Açıklama**: Sakin ankette tek bir seçeneğe oy verir. Veritabanındaki `UNIQUE(poll_id, user_id)` kısıtı ile mükerrer oy kullanımı kesin olarak engellenir.
- **İstek Gövdesi**: `{"option_id": 2}`.

---

## 8. Güvenli Mesajlaşma (`/messages`)

### 8.1. Mesajları Listele (`GET /messages?community_id={id}`)
- **Açıklama**: Oturum açan kullanıcının dahil olduğu 1-e-1 mesajları listeler.
- **Kural**: Sakinler kendi aralarında mesajlaşamaz. Yalnızca Sakin ↔ Yönetici iletişimi geçerlidir.

### 8.2. Mesaj Gönder (`POST /messages`)
- **Açıklama**: Sakinden yöneticiye veya yöneticiden sakine özel mesaj iletir.
- **İstek Gövdesi**:
  ```json
  {
    "community_id": 1,
    "receiver_id": 1,
    "subject": "Otopark Giriş Kartı Talebi",
    "body": "Merhabalar Kemal Bey, yeni aracım için otopark kartı talep ediyorum."
  }
  ```

---

## 9. Dashboard Özetleri (`/dashboard`)

### 9.1. Sakin Dashboard'u (`GET /dashboard/resident?community_id={id}`)
- **Yanıt**: En son duyuru, sakinin açık arızaları sayısı, yaklaşan toplantı, aktif anket ve **yalnızca sakinin kendi** ödenmemiş aidat özeti.

### 9.2. Yönetici KPI Paneli (`GET /dashboard/manager?community_id={id}`)
- **Yetki**: Yalnızca `MANAGER`.
- **Yanıt**: Toplam daire sayısı, aktif sakin sayısı, açık arıza sayısı, bekleyen talepler ve tahsilat istatistikleri.
