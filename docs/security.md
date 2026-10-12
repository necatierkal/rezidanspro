# RezidansPro — Güvenlik & Gizlilik Mimarisi (Security Guide)

Güvenlik ve gizlilik, RezidansPro platformunun en temel yapı taşıdır.  
Bu doküman; aidat gizliliği, kimlik doğrulama, yetki denetimi, veri koruma ve Google Play Store uyumluluk standartlarını açıklar.

---

## 1. Temel İlke: Aidat ve Finansal Bilgi İzolasyonu

Toplu yaşam alanlarında en hassas konu bireylerin finansal durumudur. RezidansPro'da hiçbir sakin, diğer bir komşunun aidat borcunu, ödeme gecikmesini veya finansal geçmişini **kesinlikle göremez**.

### Güvenlik Bariyerleri:
1. **Veritabanı ve API İzolasyonu**:
   - `GET /api/v1/dues/my` uç noktası doğrudan kullanıcının `apartment_members` kayıtlarından türetilir. İstemciden gelen query parametrelerine güvenilmez.
   - Bir sakin başka bir sakine ait aidat ID'siyle (`GET /api/v1/dues/{id}`) sorgu yaptığında, backend kullanıcının bu daireye ait olmadığını tespit eder ve anında **HTTP 403 Forbidden** döner.
2. **Toplu Ekranlarda ve Akışlarda Gizleme**:
   - Bina ana sayfasında, genel duyurularda, komşular/üyeler listesinde finansal bakiye veya borç bilgisi yer alamaz.
3. **Kilit Ekranı ve Push Bildirim Sanitizasyonu**:
   - Push notification içeriğinde veya kilit ekranı önizlemesinde asla borç tutarı yer alamaz.  
     *(❌ "Ali Bey 1.250 TL borcunuz bulunmaktadır" ifadesi YASAKTIR).*  
     *(✅ "Ödenmemiş aidatınız bulunmaktadır. Detaylar için uygulamaya giriş yapın." ifadesi KULLANILIR).*

---

## 2. Rol Tabanlı Yetkilendirme (RBAC - Role-Based Access Control)

Mobil arayüzde bir butonu veya menüyü gizlemek tek başına güvenlik sağlamaz. Tüm koruma sunucu katmanında enforced edilmelidir.

```
+------------------+-----------------------+-------------------------+
| Rol              | Görüntüleme Yetkisi   | Yönetim Yetkisi         |
+------------------+-----------------------+-------------------------+
| RESIDENT         | Kendi Dairesi / Kendi | Kendi Arızasını Açma    |
|                  | Arızaları / Duyurular | Toplantıya Katılım/Oy   |
|                  | ve Anketler           | Yöneticiye 1-1 Mesaj    |
+------------------+-----------------------+-------------------------+
| MANAGER          | Tüm Bloklar/Daireler, | Duyuru Yayınlama,       |
|                  | Tüm Arızalar, Genel   | Arıza Durumu Değiştirme,|
|                  | Aidat & Bütçe Durumu  | Toplantı/Anket Açma,    |
|                  |                       | Aidat Tahakkuk/Tahsilat |
+------------------+-----------------------+-------------------------+
| ASSISTANT_MGR    | Operasyonel Listeler  | Arıza & Duyuru Yönetimi |
+------------------+-----------------------+-------------------------+
```

### Yetkilendirme Kontrol Katmanı (`dependencies.py`):
```python
async def require_manager_role(
    community_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
) -> CommunityMember:
    # Kullanıcının hedef sitedeki yöneticilik rolünü sorgular.
    # Rol 'MANAGER' veya 'ASSISTANT_MANAGER' değilse anında 403 Forbidden fırlatır.
```

---

## 3. Kimlik Doğrulama & Parola Güvenliği

### 3.1. Parola Özetleme (Password Hashing)
- Parolalar veritabanında kesinlikle düz metin (plain text) olarak saklanmaz.
- Endüstri standardı **Argon2** ve **bcrypt** algoritmaları tuzlama (salt) ile birlikte kullanılır.

### 3.2. JWT (JSON Web Token) Yaşam Döngüsü
- **Access Token**: Kısa süreli geçerlilik (120 dakika). `HS256` şifreleme algoritması ile imzalanır.
- **Refresh Token**: Uzun süreli geçerlilik (30 gün). Yalnızca yeni bir access token almak amacıyla kullanılır.
- Çıkış yapıldığında cihazdaki tokenlar sıfırlanır.

---

## 4. Mesajlaşma Güvenliği & İletişim Duvarı

- **Sakinler Arası Mesajlaşma Engeli**: RezidansPro bir dedikodu veya sosyal medya ağı değildir. Sakinlerin kendi aralarında kontrolsüz mesajlaşması, komşuluk sürtüşmelerini önlemek amacıyla engellenmiştir (`HTTP 403: Resident-to-resident messaging is not permitted`).
- **Yönetici ↔ Sakin Kanalı**: Sakin yalnızca bina yönetimi ile doğrudan iletişim kurabilir.
- **URL / ID Manipülasyon Koruması**: Kullanıcılar yalnızca dahil oldukları mesaj dizilerini okuyabilir.

---

## 5. Google Play Store & KVKK / GDPR Uyumluluğu

### 5.1. Hesap Silme Hakkı (Right to Erasure)
Google Play Store politikalarına tam uyum kapsamında, kullanıcıların uygulama içerisinden hesaplarını ve kişisel verilerini tek tıkla silebilmeleri sağlanmıştır:
- Uç Nokta: `DELETE /api/v1/auth/account`
- Davranış: Kullanıcının kişisel bilgileri (ad, soyad, telefon, e-posta) anonimleştirilir veya silinir, oturumları sonlandırılır.

### 5.2. Minimum İzin Prensibi (Least Privilege)
Uygulama yalnızca işlevi için zorunlu olan izinleri talep eder:
- `INTERNET` & `ACCESS_NETWORK_STATE`: API iletişimi.
- `POST_NOTIFICATIONS`: Yalnızca acil duyuru ve bilgilendirme bildirimleri (Android 13+).
- `CAMERA` / `READ_MEDIA_IMAGES`: Yalnızca arıza bildirimine teknik fotoğraf ekleme aşamasında.
- Arka planda konum, rehber erişimi, mikrofon vb. gereksiz hiçbir izin talep edilmez.

---

## 6. Denetim İzi (Audit Logging)

Yöneticilerin gerçekleştirdiği finansal veya kritik operasyonlar (`dues_payments`, `member_removal`, `fault_status_change`) denetim günlüğüne (`audit_logs`) kaydedilir:
- Hangi kullanıcı, hangi IP üzerinden, hangi tarihte, ne işlem gerçekleştirdi?  
Bu sayede bina genel kurullarında ve hukuki süreçlerde tam şeffaflık sağlanır.
