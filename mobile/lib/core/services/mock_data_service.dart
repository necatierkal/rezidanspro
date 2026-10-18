import '../models/app_models.dart';

class MockDataService {
  static final MockDataService _instance = MockDataService._internal();
  factory MockDataService() => _instance;
  MockDataService._internal();

  // In-memory state for offline/demo experience
  bool isManagerMode = false;

  final CommunityModel demoCommunity = CommunityModel(
    id: 1,
    name: 'Gül Sitesi',
    type: 'SITE',
    address: 'Atatürk Bulvarı No: 142 Çankaya',
    city: 'Ankara',
    district: 'Çankaya',
  );

  List<AnnouncementModel> announcements = [
    AnnouncementModel(
      id: 1,
      communityId: 1,
      authorId: 1,
      authorName: 'Kemal Yılmaz (Yönetici)',
      title: 'Asansör Periyodik Bakım Çalışması',
      body: '14 Ekim Çarşamba günü saat 10:00 - 13:00 arasında A ve B Blok asansörleri periyodik güvenlik bakımına alınacaktır. Lütfen bu saatlerde merdivenleri kullanınız.',
      priority: 'URGENT',
      publishedAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    AnnouncementModel(
      id: 2,
      communityId: 1,
      authorId: 1,
      authorName: 'Kemal Yılmaz (Yönetici)',
      title: 'Su Deposu Temizliği ve Dezenfeksiyonu',
      body: 'Merkezi içme ve kullanım suyu deposu cumartesi günü temizlenecektir. 09:00 - 12:00 arasında kısa süreli su kesintisi yaşanacaktır.',
      priority: 'IMPORTANT',
      publishedAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    AnnouncementModel(
      id: 3,
      communityId: 1,
      authorId: 1,
      authorName: 'Yönetim',
      title: 'Site Güvenlik & Misafir Otopark Kuralları',
      body: 'Misafir araçlarının blok girişlerini ve yangın çıkışlarını kapatmayacak şekilde otopark çizgilerine uygun park edilmesi önemle rica olunur.',
      priority: 'NORMAL',
      publishedAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
  ];

  List<MaintenanceModel> maintenanceRequests = [
    MaintenanceModel(
      id: 1,
      communityId: 1,
      apartmentId: 3,
      reportedBy: 2,
      reporterName: 'Necati Erkal',
      category: 'Asansör',
      title: 'Asansör 3. Katta Titreme Yapıyor',
      description: 'A Blok sağ asansör 3. kata gelirken ses çıkarıyor ve kabin sarsılıyor.',
      status: 'IN_PROGRESS',
      priority: 'HIGH',
      createdAt: DateTime.now().subtract(const Duration(hours: 18)),
      comments: [],
    ),
    MaintenanceModel(
      id: 2,
      communityId: 1,
      apartmentId: 1,
      reportedBy: 1,
      reporterName: 'Kemal Yılmaz (Yönetici)',
      category: 'Aydınlatma',
      title: 'Kapalı Otopark Lambaları Yanmıyor',
      description: 'B1 katındaki 3 adet LED floresan arızalandı, alan karanlık kalıyor.',
      status: 'OPEN',
      priority: 'MEDIUM',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      comments: [],
    ),
    MaintenanceModel(
      id: 3,
      communityId: 1,
      apartmentId: 2,
      reportedBy: 3,
      reporterName: 'Ahmet Demir',
      category: 'Kapı',
      title: 'Bina Ana Giriş Kapısı Hidroliği',
      description: 'Giriş kapısı hızla çarpıyor, hidrolik ayarı yapılması gerekiyor.',
      status: 'RESOLVED',
      priority: 'LOW',
      createdAt: DateTime.now().subtract(const Duration(days: 4)),
      resolvedAt: DateTime.now().subtract(const Duration(days: 1)),
      comments: [],
    ),
  ];

  List<DueModel> duesList = [
    DueModel(
      id: 101,
      communityId: 1,
      apartmentId: 3, // Necati Erkal (A Blok 103)
      blockName: 'A Blok',
      apartmentNo: '103',
      period: 'Ekim 2026',
      amount: 2500.0,
      dueDate: DateTime(2026, 10, 15),
      status: 'UNPAID',
      createdAt: DateTime(2026, 10, 1),
      payments: [],
    ),
    DueModel(
      id: 102,
      communityId: 1,
      apartmentId: 3,
      blockName: 'A Blok',
      apartmentNo: '103',
      period: 'Eylül 2026',
      amount: 2500.0,
      dueDate: DateTime(2026, 9, 15),
      status: 'PAID',
      createdAt: DateTime(2026, 9, 1),
      payments: [
        DuePaymentModel(
          id: 1,
          dueId: 102,
          amount: 2500.0,
          paidAt: DateTime(2026, 9, 12),
          paymentMethod: 'HAVALE_EFT',
          reference: 'DEK-9921',
        )
      ],
    ),
    DueModel(
      id: 103,
      communityId: 1,
      apartmentId: 1, // Kemal Yılmaz (A Blok 101)
      blockName: 'A Blok',
      apartmentNo: '101',
      period: 'Ekim 2026',
      amount: 2500.0,
      dueDate: DateTime(2026, 10, 15),
      status: 'PAID',
      createdAt: DateTime(2026, 10, 1),
      payments: [],
    ),
    DueModel(
      id: 104,
      communityId: 1,
      apartmentId: 2, // A Blok 102
      blockName: 'A Blok',
      apartmentNo: '102',
      period: 'Ekim 2026',
      amount: 2500.0,
      dueDate: DateTime(2026, 10, 15),
      status: 'OVERDUE',
      createdAt: DateTime(2026, 10, 1),
      payments: [],
    ),
  ];

  List<MeetingModel> meetings = [
    MeetingModel(
      id: 1,
      communityId: 1,
      title: '2026 Yılı Olağan Kat Malikleri Genel Kurulu',
      description: 'Yıllık bütçe onayı, çatı izolasyonu tekliflerinin oylanması ve yeni dönem yönetici seçimi gündem maddeleri ile toplanılacaktır.',
      location: 'Site Sosyal Tesisleri Toplantı Salonu',
      startAt: DateTime(2026, 10, 25, 19, 30),
      endAt: DateTime(2026, 10, 25, 21, 30),
      createdBy: 1,
      createdAt: DateTime(2026, 10, 1),
      attendingCount: 28,
      userRsvp: 'ATTENDING',
    ),
  ];

  List<PollModel> polls = [
    PollModel(
      id: 1,
      communityId: 1,
      title: 'Ortak Bahçe ve Sosyal Alan Yenileme Projesi',
      description: 'Site bütçesinden ayrılacak pay ile arka bahçeye hangi alanın kazandırılmasını istersiniz?',
      status: 'ACTIVE',
      isPublicResult: true,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      endAt: DateTime.now().add(const Duration(days: 10)),
      totalVotes: 51,
      userVotedOptionId: null,
      options: [
        PollOptionModel(id: 1, pollId: 1, label: 'Çocuk Oyun Parkı ve Kauçuk Zemin', voteCount: 18, votePercentage: 35.3),
        PollOptionModel(id: 2, pollId: 1, label: 'Kamelya, Oturma Alanı & Peyzaj', voteCount: 24, votePercentage: 47.1),
        PollOptionModel(id: 3, pollId: 1, label: 'Açık Spor ve Fitness Aletleri', voteCount: 9, votePercentage: 17.6),
      ],
    ),
  ];

  List<PrivateMessageModel> messages = [
    PrivateMessageModel(
      id: 1,
      communityId: 1,
      senderId: 1,
      senderName: 'Kemal Yılmaz (Yönetici)',
      receiverId: 2,
      receiverName: 'Necati Erkal',
      subject: 'Aidat Bilgilendirmesi',
      body: 'Merhaba Necati Bey,\nEkim ayı aidat ödemeniz sistemimizde henüz görünmemektedir. İlgili dekontu iletebilir veya sistem üzerinden kontrol edebilirsiniz. Saygılarımızla, Gül Sitesi Yönetimi.',
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      readAt: null,
    ),
    PrivateMessageModel(
      id: 2,
      communityId: 1,
      senderId: 2,
      senderName: 'Necati Erkal',
      receiverId: 1,
      receiverName: 'Kemal Yılmaz (Yönetici)',
      subject: 'Asansör Bakım Saati',
      body: 'Merhaba Kemal Bey, çarşamba günkü asansör bakımı sırasında yük asansörü açık kalacak mı?',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      readAt: DateTime.now().subtract(const Duration(hours: 20)),
    ),
  ];

  List<NotificationModel> notifications = [
    NotificationModel(
      id: 1,
      userId: 2,
      type: 'ANNOUNCEMENT',
      title: 'Yeni Duyuru Yayınlandı',
      body: 'Asansör periyodik bakım çalışması duyurusu paylaşıldı.',
      isRead: false,
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    NotificationModel(
      id: 2,
      userId: 2,
      type: 'DUES_REMINDER',
      title: 'Aidat Hatırlatması',
      body: 'Ekim ayı aidat durumunuzla ilgili yeni bir bildirim var.',
      isRead: false,
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
    ),
    NotificationModel(
      id: 3,
      userId: 2,
      type: 'MAINTENANCE',
      title: 'Arıza Kaydı Güncellendi',
      body: 'Bildirdiğiniz asansör arızası teknisyen tarafından işleme alındı.',
      isRead: true,
      createdAt: DateTime.now().subtract(const Duration(hours: 12)),
    ),
  ];

  // Mock API Handlers
  dynamic handleGet(String endpoint, Map<String, dynamic>? queryParams) {
    if (endpoint == '/communities/my') {
      final role = isManagerMode ? 'MANAGER' : 'RESIDENT';
      final aptNo = isManagerMode ? '101' : '103';
      return [
        {
          'id': 1,
          'user_id': isManagerMode ? 1 : 2,
          'community': {
            'id': 1,
            'name': 'Gül Sitesi',
            'type': 'SITE',
            'address': 'Atatürk Bulvarı No: 142 Çankaya',
            'city': 'Ankara',
            'district': 'Çankaya',
          },
          'role': role,
          'status': 'ACTIVE',
          'joined_at': DateTime.now().toIso8601String(),
          'apartment': {
            'id': isManagerMode ? 1 : 3,
            'block_name': 'A Blok',
            'apartment_no': aptNo,
            'floor': 1,
            'type': '3+1',
          },
        }
      ];
    } else if (endpoint == '/dashboard/resident') {
      final latest = announcements.isNotEmpty ? announcements.first : null;
      return {
        'community_name': 'Gül Sitesi',
        'apartment_display': 'A Blok · Daire 103',
        'latest_announcement': latest != null
            ? {
                'id': latest.id,
                'community_id': latest.communityId,
                'author_id': latest.authorId,
                'author_name': latest.authorName,
                'title': latest.title,
                'body': latest.body,
                'priority': latest.priority,
                'published_at': latest.publishedAt.toIso8601String(),
              }
            : null,
        'open_fault_count': maintenanceRequests.where((m) => m.reportedBy == 2 && m.status != 'RESOLVED').length,
        'upcoming_meeting': meetings.isNotEmpty
            ? {
                'id': meetings.first.id,
                'title': meetings.first.title,
                'date_time': meetings.first.startAt.toIso8601String(),
                'location': meetings.first.location,
              }
            : null,
        'active_poll': polls.isNotEmpty
            ? {
                'id': polls.first.id,
                'title': polls.first.title,
                'total_votes': polls.first.totalVotes,
              }
            : null,
        'dues_status': {
          'period': 'Ekim 2026',
          'amount': 2500.0,
          'status': 'UNPAID',
        },
      };
    } else if (endpoint == '/dashboard/manager') {
      return {
        'total_apartments': 48,
        'active_residents': 112,
        'open_faults': maintenanceRequests.where((m) => m.status != 'RESOLVED').length,
        'pending_requests': 4,
        'total_dues_collected': 92500.0,
        'pending_dues_amount': 27500.0,
        'collection_rate': 77.1,
      };
    } else if (endpoint == '/announcements') {
      return announcements
          .map((a) => {
                'id': a.id,
                'community_id': a.communityId,
                'author_id': a.authorId,
                'author_name': a.authorName,
                'title': a.title,
                'body': a.body,
                'priority': a.priority,
                'published_at': a.publishedAt.toIso8601String(),
              })
          .toList();
    } else if (endpoint == '/maintenance') {
      var list = maintenanceRequests;
      if (!isManagerMode) {
        list = list.where((m) => m.reportedBy == 2).toList();
      }
      return list
          .map((m) => {
                'id': m.id,
                'community_id': m.communityId,
                'apartment_id': m.apartmentId,
                'reported_by': m.reportedBy,
                'reporter_name': m.reporterName,
                'category': m.category,
                'title': m.title,
                'description': m.description,
                'status': m.status,
                'priority': m.priority,
                'created_at': m.createdAt.toIso8601String(),
                'resolved_at': m.resolvedAt?.toIso8601String(),
                'comments': [],
              })
          .toList();
    } else if (endpoint == '/dues/my') {
      return duesList
          .where((d) => d.apartmentId == 3)
          .map((d) => {
                'id': d.id,
                'community_id': d.communityId,
                'apartment_id': d.apartmentId,
                'block_name': d.blockName,
                'apartment_no': d.apartmentNo,
                'period': d.period,
                'amount': d.amount,
                'due_date': d.dueDate.toIso8601String(),
                'status': d.status,
                'created_at': d.createdAt.toIso8601String(),
                'payments': d.payments
                    .map((p) => {
                          'id': p.id,
                          'due_id': p.dueId,
                          'amount': p.amount,
                          'paid_at': p.paidAt.toIso8601String(),
                          'payment_method': p.paymentMethod,
                          'reference': p.reference,
                        })
                    .toList(),
              })
          .toList();
    } else if (endpoint == '/manager/dues') {
      return duesList
          .map((d) => {
                'id': d.id,
                'community_id': d.communityId,
                'apartment_id': d.apartmentId,
                'block_name': d.blockName,
                'apartment_no': d.apartmentNo,
                'period': d.period,
                'amount': d.amount,
                'due_date': d.dueDate.toIso8601String(),
                'status': d.status,
                'created_at': d.createdAt.toIso8601String(),
                'payments': d.payments
                    .map((p) => {
                          'id': p.id,
                          'due_id': p.dueId,
                          'amount': p.amount,
                          'paid_at': p.paidAt.toIso8601String(),
                          'payment_method': p.paymentMethod,
                          'reference': p.reference,
                        })
                    .toList(),
              })
          .toList();
    } else if (endpoint == '/meetings') {
      return meetings
          .map((m) => {
                'id': m.id,
                'community_id': m.communityId,
                'title': m.title,
                'description': m.description,
                'location': m.location,
                'start_at': m.startAt.toIso8601String(),
                'end_at': m.endAt?.toIso8601String(),
                'created_by': m.createdBy,
                'created_at': m.createdAt.toIso8601String(),
                'attending_count': m.attendingCount,
                'user_rsvp': m.userRsvp,
              })
          .toList();
    } else if (endpoint == '/polls') {
      return polls
          .map((p) => {
                'id': p.id,
                'community_id': p.communityId,
                'title': p.title,
                'description': p.description,
                'status': p.status,
                'is_public_result': p.isPublicResult,
                'created_at': p.createdAt.toIso8601String(),
                'end_at': p.endAt?.toIso8601String(),
                'user_voted_option_id': p.userVotedOptionId,
                'total_votes': p.totalVotes,
                'options': p.options
                    .map((o) => {
                          'id': o.id,
                          'poll_id': o.pollId,
                          'label': o.label,
                          'vote_count': o.voteCount,
                          'vote_percentage': o.votePercentage,
                        })
                    .toList(),
              })
          .toList();
    } else if (endpoint == '/messages') {
      final currentUserId = isManagerMode ? 1 : 2;
      final userMsgs = messages.where((m) => m.senderId == currentUserId || m.receiverId == currentUserId).toList();
      return userMsgs
          .map((m) => {
                'id': m.id,
                'community_id': m.communityId,
                'sender_id': m.senderId,
                'sender_name': m.senderName,
                'receiver_id': m.receiverId,
                'receiver_name': m.receiverName,
                'subject': m.subject,
                'body': m.body,
                'created_at': m.createdAt.toIso8601String(),
                'read_at': m.readAt?.toIso8601String(),
              })
          .toList();
    } else if (endpoint == '/notifications') {
      return notifications
          .map((n) => {
                'id': n.id,
                'user_id': n.userId,
                'type': n.type,
                'title': n.title,
                'body': n.body,
                'is_read': n.isRead,
                'created_at': n.createdAt.toIso8601String(),
              })
          .toList();
    }

    return {};
  }

  dynamic handlePost(String endpoint, Map<String, dynamic>? body) {
    if (endpoint == '/auth/login') {
      final email = (body?['email'] as String? ?? '').toLowerCase();
      isManagerMode = email.contains('manager');

      return {
        'access_token': 'demo_access_token_12345',
        'refresh_token': 'demo_refresh_token_12345',
        'token_type': 'bearer',
        'user_id': isManagerMode ? 1 : 2,
        'email': email.isNotEmpty ? email : (isManagerMode ? 'manager@rezidanspro.app' : 'resident@rezidanspro.app'),
        'first_name': isManagerMode ? 'Kemal' : 'Necati',
        'last_name': isManagerMode ? 'Yılmaz' : 'Erkal',
        'role': isManagerMode ? 'MANAGER' : 'RESIDENT',
        'user': {
          'id': isManagerMode ? 1 : 2,
          'uuid': isManagerMode ? 'u-mgr-001' : 'u-res-002',
          'email': email.isNotEmpty ? email : (isManagerMode ? 'manager@rezidanspro.app' : 'resident@rezidanspro.app'),
          'first_name': isManagerMode ? 'Kemal' : 'Necati',
          'last_name': isManagerMode ? 'Yılmaz' : 'Erkal',
          'phone': isManagerMode ? '0555 123 4567' : '0555 987 6543',
          'is_active': true,
          'created_at': DateTime.now().toIso8601String(),
        },
      };
    } else if (endpoint == '/auth/register') {
      return {
        'access_token': 'demo_access_token_12345',
        'refresh_token': 'demo_refresh_token_12345',
        'token_type': 'bearer',
        'user_id': 2,
        'email': body?['email'] ?? 'yeni.sakin@rezidanspro.app',
        'first_name': body?['first_name'] ?? 'Yeni',
        'last_name': body?['last_name'] ?? 'Sakin',
        'role': 'RESIDENT',
        'user': {
          'id': 2,
          'uuid': 'u-res-new',
          'email': body?['email'] ?? 'yeni.sakin@rezidanspro.app',
          'first_name': body?['first_name'] ?? 'Yeni',
          'last_name': body?['last_name'] ?? 'Sakin',
          'is_active': true,
          'created_at': DateTime.now().toIso8601String(),
        },
      };
    } else if (endpoint == '/announcements') {
      final newAnn = AnnouncementModel(
        id: announcements.length + 1,
        communityId: 1,
        authorId: 1,
        authorName: 'Kemal Yılmaz (Yönetici)',
        title: body?['title'] ?? 'Yeni Duyuru',
        body: body?['body'] ?? '',
        priority: body?['priority'] ?? 'NORMAL',
        publishedAt: DateTime.now(),
      );
      announcements.insert(0, newAnn);
      return {'message': 'Duyuru başarıyla yayınlandı', 'id': newAnn.id};
    } else if (endpoint == '/maintenance') {
      final newReq = MaintenanceModel(
        id: maintenanceRequests.length + 1,
        communityId: 1,
        apartmentId: 3,
        reportedBy: 2,
        reporterName: 'Necati Erkal',
        category: body?['category'] ?? 'Diğer',
        title: body?['title'] ?? 'Arıza Bildirimi',
        description: body?['description'] ?? '',
        status: 'OPEN',
        priority: body?['priority'] ?? 'NORMAL',
        createdAt: DateTime.now(),
        comments: [],
      );
      maintenanceRequests.insert(0, newReq);
      return {'message': 'Arıza kaydı başarıyla oluşturuldu', 'id': newReq.id};
    } else if (endpoint.contains('/vote')) {
      return {'message': 'Oyunuz başarıyla kaydedildi'};
    } else if (endpoint == '/messages') {
      final newMsg = PrivateMessageModel(
        id: messages.length + 1,
        communityId: 1,
        senderId: isManagerMode ? 1 : 2,
        senderName: isManagerMode ? 'Kemal Yılmaz (Yönetici)' : 'Necati Erkal',
        receiverId: isManagerMode ? 2 : 1,
        receiverName: isManagerMode ? 'Necati Erkal' : 'Kemal Yılmaz (Yönetici)',
        subject: body?['subject'] ?? 'Mesaj',
        body: body?['body'] ?? '',
        createdAt: DateTime.now(),
      );
      messages.insert(0, newMsg);
      return {'message': 'Mesaj iletildi', 'id': newMsg.id};
    }

    return {'message': 'İşlem başarılı'};
  }
}
