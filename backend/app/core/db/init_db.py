import datetime
from sqlalchemy.orm import Session
from app.core.auth.security import hash_password
from app.models.all_models import (
    User, Community, CommunityInviteCode, CommunityMember, Block, Apartment, ApartmentMember,
    Announcement, MaintenanceRequest, MaintenanceComment, Meeting, MeetingAttendee,
    Poll, PollOption, PollVote, Due, DuePayment, PrivateMessage, Notification
)

def seed_demo_data(db: Session):
    """Seeds the canonical demo data for 'Gül Sitesi' as specified in Master Prompt Sec 71."""
    # Check if demo manager already exists
    existing = db.query(User).filter(User.email == "manager@rezidanspro.app").first()
    if existing:
        return

    default_password_hash = hash_password("RezidansPro123!")

    # 1. Create Demo Manager
    manager = User(
        email="manager@rezidanspro.app",
        phone="+905551234567",
        password_hash=default_password_hash,
        first_name="Kemal",
        last_name="Yılmaz",
        is_active=True
    )
    db.add(manager)

    # 2. Create Demo Resident (Necati Erkal - Sec 8, 13)
    resident = User(
        email="resident@rezidanspro.app",
        phone="+905559876543",
        password_hash=default_password_hash,
        first_name="Necati",
        last_name="Erkal",
        is_active=True
    )
    db.add(resident)

    # 3. Create Second Resident for isolation testing
    resident_b = User(
        email="resident2@rezidanspro.app",
        phone="+905554443322",
        password_hash=default_password_hash,
        first_name="Ayşe",
        last_name="Demir",
        is_active=True
    )
    db.add(resident_b)
    db.commit()
    db.refresh(manager)
    db.refresh(resident)
    db.refresh(resident_b)

    # 4. Create Gül Sitesi Community (Sec 8, 71)
    community = Community(
        name="Gül Sitesi",
        type="SITE",
        address="Atatürk Bulvarı No: 142",
        city="Ankara",
        district="Çankaya",
        rules="1. Sessizlik saatleri: 23:00 - 08:00\n2. Otoparkta tahsisli numaralı alanlara park ediniz.\n3. Evcil hayvanların ortak alanlarda tasmayla dolaştırılması zorunludur.",
        emergency_contacts="112 Acil Çağrı Merkezi | Güvenlik: +90 312 400 0001 | Asansör Servisi: +90 312 400 0002"
    )
    db.add(community)
    db.commit()
    db.refresh(community)

    # 5. Invite Code
    invite = CommunityInviteCode(
        community_id=community.id,
        code="REZIDANS82K9",
        is_active=True
    )
    db.add(invite)

    # 6. Community Memberships
    m_member = CommunityMember(
        community_id=community.id,
        user_id=manager.id,
        role="MANAGER",
        status="ACTIVE"
    )
    r_member = CommunityMember(
        community_id=community.id,
        user_id=resident.id,
        role="RESIDENT",
        status="ACTIVE"
    )
    rb_member = CommunityMember(
        community_id=community.id,
        user_id=resident_b.id,
        role="RESIDENT",
        status="ACTIVE"
    )
    db.add_all([m_member, r_member, rb_member])
    db.commit()

    # 7. Blocks (A Blok, B Blok)
    block_a = Block(community_id=community.id, name="A Blok")
    block_b = Block(community_id=community.id, name="B Blok")
    db.add_all([block_a, block_b])
    db.commit()
    db.refresh(block_a)
    db.refresh(block_b)

    # 8. 20 Apartments (10 in A Blok, 10 in B Blok)
    created_apts = []
    for b in [block_a, block_b]:
        for no in range(101, 111):
            apt = Apartment(
                block_id=b.id,
                apartment_no=str(no),
                floor=(no - 100) // 2 + 1,
                type="3+1"
            )
            db.add(apt)
            created_apts.append(apt)
    db.commit()

    # Bind Necati to A Blok 103 (Sec 8)
    apt_necati = db.query(Apartment).filter(
        Apartment.block_id == block_a.id,
        Apartment.apartment_no == "103"
    ).first()
    if apt_necati:
        db.add(ApartmentMember(
            apartment_id=apt_necati.id,
            user_id=resident.id,
            is_owner=True,
            is_primary_resident=True
        ))

    # Bind Ayşe to B Blok 104
    apt_ayse = db.query(Apartment).filter(
        Apartment.block_id == block_b.id,
        Apartment.apartment_no == "104"
    ).first()
    if apt_ayse:
        db.add(ApartmentMember(
            apartment_id=apt_ayse.id,
            user_id=resident_b.id,
            is_owner=False,
            is_primary_resident=True
        ))
    db.commit()

    # 9. 5 Announcements (Sec 71)
    announcements = [
        Announcement(
            community_id=community.id,
            author_id=manager.id,
            title="Asansör Bakım Çalışması",
            body="A Blok ana asansörün periyodik bakımı 14:00 - 16:00 saatleri arasında gerçekleştirilecektir.",
            priority="IMPORTANT"
        ),
        Announcement(
            community_id=community.id,
            author_id=manager.id,
            title="Su Deposu Bakımı ve Temizliği",
            body="14 Ekim Çarşamba günü 10:00-13:00 arasında su deposu bakımı ve dezenfeksiyonu yapılacaktır. Kısa süreli su kesintisi yaşanabilir.",
            priority="URGENT"
        ),
        Announcement(
            community_id=community.id,
            author_id=manager.id,
            title="Bahar Bahçe Düzenlemesi",
            body="Sitemizin ortak bahçe alanlarında mevsimlik çiçek dikimi ve çim havalandırma çalışmaları başlatılmıştır.",
            priority="NORMAL"
        ),
        Announcement(
            community_id=community.id,
            author_id=manager.id,
            title="Kapalı Otopark Zemin Temizliği",
            body="Pazar günü 09:00 - 12:00 arasında otopark yıkama çalışması yapılacaktır.",
            priority="NORMAL"
        ),
        Announcement(
            community_id=community.id,
            author_id=manager.id,
            title="Geri Dönüşüm Kutuları Yenilendi",
            body="Sıfır Atık projesi kapsamında blok girişlerine yeni cam, plastik ve kağıt geri dönüşüm üniteleri yerleştirilmiştir.",
            priority="NORMAL"
        ),
    ]
    db.add_all(announcements)
    db.commit()

    # 10. 3 Maintenance Requests (Sec 71)
    m1 = MaintenanceRequest(
        community_id=community.id,
        apartment_id=apt_necati.id if apt_necati else None,
        reported_by=resident.id,
        category="ELEVATOR",
        title="Asansör çalışmıyor",
        description="A Blok asansörü 3. katta durmuyor ve kabin kapısı zor kapanıyor.",
        status="IN_PROGRESS",
        priority="IMPORTANT"
    )
    m2 = MaintenanceRequest(
        community_id=community.id,
        apartment_id=apt_necati.id if apt_necati else None,
        reported_by=resident.id,
        category="LIGHTING",
        title="3. Kat Koridor Lambası Yanmıyor",
        description="A Blok 3. kat koridor sensörlü aydınlatma lambası arızalı.",
        status="OPEN",
        priority="NORMAL"
    )
    m3 = MaintenanceRequest(
        community_id=community.id,
        apartment_id=apt_ayse.id if apt_ayse else None,
        reported_by=resident_b.id,
        category="WATER",
        title="Otopark Tavanından Su Damlıyor",
        description="B Blok kapalı otopark girişinde tavan borusundan hafif sızıntı var.",
        status="RESOLVED",
        priority="IMPORTANT"
    )
    db.add_all([m1, m2, m3])
    db.commit()

    # 11. 2 Meetings (Sec 71)
    meeting_date = datetime.datetime.now(datetime.timezone.utc) + datetime.timedelta(days=12)
    m_meet1 = Meeting(
        community_id=community.id,
        title="Olağan Kat Malikleri Genel Kurul Toplantısı",
        description="Yıllık bütçe, yakıt planlaması ve bahçe peyzaj projesinin oylanması.",
        location="Gül Sitesi Sosyal Tesis / Toplantı Salonu",
        start_at=meeting_date.replace(hour=19, minute=30),
        created_by=manager.id
    )
    m_meet2 = Meeting(
        community_id=community.id,
        title="Güvenlik & Kamera Sistemi İstişare Toplantısı",
        description="Çevre güvenlik kameralarının yenilenmesi hakkında bilgilendirme.",
        location="Site Yönetim Ofisi",
        start_at=meeting_date.replace(hour=14, minute=0) + datetime.timedelta(days=7),
        created_by=manager.id
    )
    db.add_all([m_meet1, m_meet2])
    db.commit()
    db.refresh(m_meet1)

    # RSVP for Necati
    db.add(MeetingAttendee(
        meeting_id=m_meet1.id,
        user_id=resident.id,
        status="ATTENDING"
    ))
    db.commit()

    # 12. 2 Polls (Sec 71)
    p1 = Poll(
        community_id=community.id,
        title="Bahçe düzenlemesi için hangi seçenek tercih ediliyor?",
        description="Ortak alanın yeniden projelendirilmesi için sakinlerimizin tercihini belirliyoruz.",
        created_by=manager.id,
        status="ACTIVE",
        is_public_result=True
    )
    db.add(p1)
    db.commit()
    db.refresh(p1)

    p1_opt1 = PollOption(poll_id=p1.id, label="Çim alan ve kamelya")
    p1_opt2 = PollOption(poll_id=p1.id, label="Çocuk oyun alanı")
    p1_opt3 = PollOption(poll_id=p1.id, label="Misafir araç otoparkı")
    db.add_all([p1_opt1, p1_opt2, p1_opt3])
    db.commit()
    db.refresh(p1_opt1)

    # Necati votes for option 1
    db.add(PollVote(poll_id=p1.id, option_id=p1_opt1.id, user_id=resident.id))
    db.commit()

    p2 = Poll(
        community_id=community.id,
        title="Merkezi Isıtma Başlangıç Tarihi",
        description="Hava tahminlerine göre kazan dairesi ısıtma sisteminin devreye alınması.",
        created_by=manager.id,
        status="ACTIVE",
        is_public_result=True
    )
    db.add(p2)
    db.commit()
    db.refresh(p2)
    db.add_all([
        PollOption(poll_id=p2.id, label="15 Ekim"),
        PollOption(poll_id=p2.id, label="1 Kasım")
    ])
    db.commit()

    # 13. Dues (Sec 71 & 22)
    # Necati: A Blok Daire 103, Ekim 2026, 2.500 TL
    due_necati = Due(
        community_id=community.id,
        apartment_id=apt_necati.id,
        period="Ekim 2026",
        amount=2500.0,
        due_date=datetime.datetime(2026, 10, 10, 23, 59, tzinfo=datetime.timezone.utc),
        status="UNPAID",
        notes="Genel giderler ve güvenlik aidatı"
    )
    # Ayşe: B Blok Daire 104, Ekim 2026, 2.500 TL, PAID
    due_ayse = Due(
        community_id=community.id,
        apartment_id=apt_ayse.id,
        period="Ekim 2026",
        amount=2500.0,
        due_date=datetime.datetime(2026, 10, 10, 23, 59, tzinfo=datetime.timezone.utc),
        status="PAID",
        notes="Genel giderler"
    )
    db.add_all([due_necati, due_ayse])
    db.commit()
    db.refresh(due_ayse)

    # Add payment record for Ayşe
    db.add(DuePayment(
        due_id=due_ayse.id,
        amount=2500.0,
        payment_method="BANK_TRANSFER",
        reference="DEKONT-8921"
    ))
    db.commit()

    # 14. Private Messages (Sec 24, 71, 77)
    # Manager -> Necati private message (ONLY Necati and Manager can see this!)
    msg1 = PrivateMessage(
        community_id=community.id,
        sender_id=manager.id,
        receiver_id=resident.id,
        subject="Ekim Ayı Aidat Bilgilendirmesi",
        body="Merhaba Necati Bey,\nEkim ayı aidat ödemenizin henüz sisteme işlenmediğini görüyoruz. Havale yaptıysanız lütfen dekont referans numarasını iletiniz."
    )
    msg2 = PrivateMessage(
        community_id=community.id,
        sender_id=resident.id,
        receiver_id=manager.id,
        subject="Yanıt: Ekim Ayı Aidat Bilgilendirmesi",
        body="Merhaba Kemal Bey,\nÖdemeyi bugün internet bankacılığından gerçekleştireceğim, teşekkürler."
    )
    db.add_all([msg1, msg2])
    db.commit()

    print("Canonical demo data for Gül Sitesi successfully seeded.")
