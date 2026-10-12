// Core Data Models for RezidansPro Mobile Application

class UserModel {
  final int id;
  final String uuid;
  final String email;
  final String? phone;
  final String firstName;
  final String lastName;
  final String? avatarUrl;
  final bool isActive;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.uuid,
    required this.email,
    this.phone,
    required this.firstName,
    required this.lastName,
    this.avatarUrl,
    required this.isActive,
    required this.createdAt,
  });

  String get fullName => '$firstName $lastName';

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      uuid: json['uuid'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String?,
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'uuid': uuid,
    'email': email,
    'phone': phone,
    'first_name': firstName,
    'last_name': lastName,
    'avatar_url': avatarUrl,
    'is_active': isActive,
    'created_at': createdAt.toIso8601String(),
  };
}

class CommunityModel {
  final int id;
  final String name;
  final String type;
  final String? address;
  final String? city;
  final String? district;
  final String? rules;
  final String? emergencyContacts;

  CommunityModel({
    required this.id,
    required this.name,
    required this.type,
    this.address,
    this.city,
    this.district,
    this.rules,
    this.emergencyContacts,
  });

  factory CommunityModel.fromJson(Map<String, dynamic> json) {
    return CommunityModel(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? 'APARTMENT',
      address: json['address'] as String?,
      city: json['city'] as String?,
      district: json['district'] as String?,
      rules: json['rules'] as String?,
      emergencyContacts: json['emergency_contacts'] as String?,
    );
  }
}

class UserMembershipModel {
  final CommunityModel community;
  final String role; // RESIDENT, MANAGER, ASSISTANT_MANAGER, SUPER_ADMIN
  final String status;
  final DateTime joinedAt;
  final Map<String, dynamic>? apartment;

  UserMembershipModel({
    required this.community,
    required this.role,
    required this.status,
    required this.joinedAt,
    this.apartment,
  });

  bool get isManager => role == 'MANAGER' || role == 'ASSISTANT_MANAGER' || role == 'SUPER_ADMIN';

  String get apartmentDisplay {
    if (apartment != null) {
      final bName = apartment!['block_name'] ?? '';
      final aNo = apartment!['apartment_no'] ?? '';
      return '$bName · Daire $aNo';
    }
    return 'Daire Tanımsız';
  }

  factory UserMembershipModel.fromJson(Map<String, dynamic> json) {
    return UserMembershipModel(
      community: CommunityModel.fromJson(json['community'] as Map<String, dynamic>),
      role: json['role'] as String? ?? 'RESIDENT',
      status: json['status'] as String? ?? 'PENDING',
      joinedAt: DateTime.tryParse(json['joined_at'] as String? ?? '') ?? DateTime.now(),
      apartment: json['apartment'] as Map<String, dynamic>?,
    );
  }
}

class AnnouncementModel {
  final int id;
  final int communityId;
  final int? authorId;
  final String authorName;
  final String title;
  final String body;
  final String priority; // NORMAL, IMPORTANT, URGENT
  final String? attachmentUrl;
  final DateTime publishedAt;
  final DateTime? expiresAt;

  AnnouncementModel({
    required this.id,
    required this.communityId,
    this.authorId,
    required this.authorName,
    required this.title,
    required this.body,
    required this.priority,
    this.attachmentUrl,
    required this.publishedAt,
    this.expiresAt,
  });

  factory AnnouncementModel.fromJson(Map<String, dynamic> json) {
    return AnnouncementModel(
      id: json['id'] as int,
      communityId: json['community_id'] as int,
      authorId: json['author_id'] as int?,
      authorName: json['author_name'] as String? ?? 'Yönetim',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      priority: json['priority'] as String? ?? 'NORMAL',
      attachmentUrl: json['attachment_url'] as String?,
      publishedAt: DateTime.tryParse(json['published_at'] as String? ?? '') ?? DateTime.now(),
      expiresAt: json['expires_at'] != null ? DateTime.tryParse(json['expires_at'] as String) : null,
    );
  }
}

class MaintenanceCommentModel {
  final int id;
  final int requestId;
  final int authorId;
  final String authorName;
  final String body;
  final DateTime createdAt;

  MaintenanceCommentModel({
    required this.id,
    required this.requestId,
    required this.authorId,
    required this.authorName,
    required this.body,
    required this.createdAt,
  });

  factory MaintenanceCommentModel.fromJson(Map<String, dynamic> json) {
    return MaintenanceCommentModel(
      id: json['id'] as int,
      requestId: json['request_id'] as int,
      authorId: json['author_id'] as int,
      authorName: json['author_name'] as String? ?? 'Sakin',
      body: json['body'] as String? ?? '',
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

class MaintenanceModel {
  final int id;
  final int communityId;
  final int? apartmentId;
  final int reportedBy;
  final String reporterName;
  final String category;
  final String title;
  final String description;
  final String status; // OPEN, IN_PROGRESS, WAITING, RESOLVED, CLOSED
  final String priority;
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final List<MaintenanceCommentModel> comments;

  MaintenanceModel({
    required this.id,
    required this.communityId,
    this.apartmentId,
    required this.reportedBy,
    required this.reporterName,
    required this.category,
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    this.photoUrl,
    required this.createdAt,
    this.resolvedAt,
    required this.comments,
  });

  factory MaintenanceModel.fromJson(Map<String, dynamic> json) {
    return MaintenanceModel(
      id: json['id'] as int,
      communityId: json['community_id'] as int,
      apartmentId: json['apartment_id'] as int?,
      reportedBy: json['reported_by'] as int,
      reporterName: json['reporter_name'] as String? ?? '',
      category: json['category'] as String? ?? 'OTHER',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      status: json['status'] as String? ?? 'OPEN',
      priority: json['priority'] as String? ?? 'NORMAL',
      photoUrl: json['photo_url'] as String?,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
      resolvedAt: json['resolved_at'] != null ? DateTime.tryParse(json['resolved_at'] as String) : null,
      comments: (json['comments'] as List<dynamic>? ?? [])
          .map((c) => MaintenanceCommentModel.fromJson(c as Map<String, dynamic>))
          .toList(),
    );
  }
}

class DuePaymentModel {
  final int id;
  final int dueId;
  final double amount;
  final DateTime paidAt;
  final String paymentMethod;
  final String? reference;

  DuePaymentModel({
    required this.id,
    required this.dueId,
    required this.amount,
    required this.paidAt,
    required this.paymentMethod,
    this.reference,
  });

  factory DuePaymentModel.fromJson(Map<String, dynamic> json) {
    return DuePaymentModel(
      id: json['id'] as int,
      dueId: json['due_id'] as int,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      paidAt: DateTime.tryParse(json['paid_at'] as String? ?? '') ?? DateTime.now(),
      paymentMethod: json['payment_method'] as String? ?? 'BANK_TRANSFER',
      reference: json['reference'] as String?,
    );
  }
}

class DueModel {
  final int id;
  final int communityId;
  final int apartmentId;
  final String? blockName;
  final String? apartmentNo;
  final String period;
  final double amount;
  final DateTime dueDate;
  final String status; // UNPAID, PAID, PARTIAL, OVERDUE
  final String? notes;
  final DateTime createdAt;
  final List<DuePaymentModel> payments;

  DueModel({
    required this.id,
    required this.communityId,
    required this.apartmentId,
    this.blockName,
    this.apartmentNo,
    required this.period,
    required this.amount,
    required this.dueDate,
    required this.status,
    this.notes,
    required this.createdAt,
    required this.payments,
  });

  bool get isPaid => status == 'PAID';

  factory DueModel.fromJson(Map<String, dynamic> json) {
    return DueModel(
      id: json['id'] as int,
      communityId: json['community_id'] as int,
      apartmentId: json['apartment_id'] as int,
      blockName: json['block_name'] as String?,
      apartmentNo: json['apartment_no'] as String?,
      period: json['period'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      dueDate: DateTime.tryParse(json['due_date'] as String? ?? '') ?? DateTime.now(),
      status: json['status'] as String? ?? 'UNPAID',
      notes: json['notes'] as String?,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
      payments: (json['payments'] as List<dynamic>? ?? [])
          .map((p) => DuePaymentModel.fromJson(p as Map<String, dynamic>))
          .toList(),
    );
  }
}

class MeetingModel {
  final int id;
  final int communityId;
  final String title;
  final String? description;
  final String location;
  final DateTime startAt;
  final DateTime? endAt;
  final int? createdBy;
  final DateTime createdAt;
  final int attendingCount;
  final String? userRsvp; // ATTENDING, NOT_ATTENDING, TENTATIVE

  MeetingModel({
    required this.id,
    required this.communityId,
    required this.title,
    this.description,
    required this.location,
    required this.startAt,
    this.endAt,
    this.createdBy,
    required this.createdAt,
    required this.attendingCount,
    this.userRsvp,
  });

  factory MeetingModel.fromJson(Map<String, dynamic> json) {
    return MeetingModel(
      id: json['id'] as int,
      communityId: json['community_id'] as int,
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      location: json['location'] as String? ?? '',
      startAt: DateTime.tryParse(json['start_at'] as String? ?? '') ?? DateTime.now(),
      endAt: json['end_at'] != null ? DateTime.tryParse(json['end_at'] as String) : null,
      createdBy: json['created_by'] as int?,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
      attendingCount: json['attending_count'] as int? ?? 0,
      userRsvp: json['user_rsvp'] as String?,
    );
  }
}

class PollOptionModel {
  final int id;
  final int pollId;
  final String label;
  final int voteCount;
  final double votePercentage;

  PollOptionModel({
    required this.id,
    required this.pollId,
    required this.label,
    required this.voteCount,
    required this.votePercentage,
  });

  factory PollOptionModel.fromJson(Map<String, dynamic> json) {
    return PollOptionModel(
      id: json['id'] as int,
      pollId: json['poll_id'] as int,
      label: json['label'] as String? ?? '',
      voteCount: json['vote_count'] as int? ?? 0,
      votePercentage: (json['vote_percentage'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class PollModel {
  final int id;
  final int communityId;
  final String title;
  final String? description;
  final String status;
  final bool isPublicResult;
  final DateTime createdAt;
  final DateTime? endAt;
  final int totalVotes;
  final int? userVotedOptionId;
  final List<PollOptionModel> options;

  PollModel({
    required this.id,
    required this.communityId,
    required this.title,
    this.description,
    required this.status,
    required this.isPublicResult,
    required this.createdAt,
    this.endAt,
    required this.totalVotes,
    this.userVotedOptionId,
    required this.options,
  });

  bool get hasVoted => userVotedOptionId != null;

  factory PollModel.fromJson(Map<String, dynamic> json) {
    return PollModel(
      id: json['id'] as int,
      communityId: json['community_id'] as int,
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      status: json['status'] as String? ?? 'ACTIVE',
      isPublicResult: json['is_public_result'] as bool? ?? true,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
      endAt: json['end_at'] != null ? DateTime.tryParse(json['end_at'] as String) : null,
      totalVotes: json['total_votes'] as int? ?? 0,
      userVotedOptionId: json['user_voted_option_id'] as int?,
      options: (json['options'] as List<dynamic>? ?? [])
          .map((o) => PollOptionModel.fromJson(o as Map<String, dynamic>))
          .toList(),
    );
  }
}

class PrivateMessageModel {
  final int id;
  final int communityId;
  final int senderId;
  final String senderName;
  final int receiverId;
  final String receiverName;
  final String? subject;
  final String body;
  final DateTime createdAt;
  final DateTime? readAt;

  PrivateMessageModel({
    required this.id,
    required this.communityId,
    required this.senderId,
    required this.senderName,
    required this.receiverId,
    required this.receiverName,
    this.subject,
    required this.body,
    required this.createdAt,
    this.readAt,
  });

  bool isSentByMe(int currentUserId) => senderId == currentUserId;

  factory PrivateMessageModel.fromJson(Map<String, dynamic> json) {
    return PrivateMessageModel(
      id: json['id'] as int,
      communityId: json['community_id'] as int,
      senderId: json['sender_id'] as int,
      senderName: json['sender_name'] as String? ?? '',
      receiverId: json['receiver_id'] as int,
      receiverName: json['receiver_name'] as String? ?? '',
      subject: json['subject'] as String?,
      body: json['body'] as String? ?? '',
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
      readAt: json['read_at'] != null ? DateTime.tryParse(json['read_at'] as String) : null,
    );
  }
}

class NotificationModel {
  final int id;
  final int userId;
  final String type;
  final String title;
  final String body;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      type: json['type'] as String? ?? 'IMPORTANT',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

class ManagerDashboardStatsModel {
  final int totalApartments;
  final int activeResidents;
  final int openFaults;
  final int pendingRequests;
  final double totalDuesCollected;
  final double totalDuesUnpaid;
  final double collectionRatePct;

  ManagerDashboardStatsModel({
    required this.totalApartments,
    required this.activeResidents,
    required this.openFaults,
    required this.pendingRequests,
    required this.totalDuesCollected,
    required this.totalDuesUnpaid,
    required this.collectionRatePct,
  });

  factory ManagerDashboardStatsModel.fromJson(Map<String, dynamic> json) {
    return ManagerDashboardStatsModel(
      totalApartments: json['total_apartments'] as int? ?? 0,
      activeResidents: json['active_residents'] as int? ?? 0,
      openFaults: json['open_faults'] as int? ?? 0,
      pendingRequests: json['pending_requests'] as int? ?? 0,
      totalDuesCollected: (json['total_dues_collected'] as num?)?.toDouble() ?? 0.0,
      totalDuesUnpaid: (json['total_dues_unpaid'] as num?)?.toDouble() ?? 0.0,
      collectionRatePct: (json['collection_rate_pct'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class ResidentDashboardSummaryModel {
  final String greeting;
  final String communityName;
  final String blockAndApartment;
  final bool hasUnpaidDues;
  final int unpaidDuesCount;
  final AnnouncementModel? latestAnnouncement;
  final int myOpenFaultsCount;
  final MeetingModel? upcomingMeeting;
  final PollModel? activePoll;

  ResidentDashboardSummaryModel({
    required this.greeting,
    required this.communityName,
    required this.blockAndApartment,
    required this.hasUnpaidDues,
    required this.unpaidDuesCount,
    this.latestAnnouncement,
    required this.myOpenFaultsCount,
    this.upcomingMeeting,
    this.activePoll,
  });

  factory ResidentDashboardSummaryModel.fromJson(Map<String, dynamic> json) {
    return ResidentDashboardSummaryModel(
      greeting: json['greeting'] as String? ?? 'Merhaba',
      communityName: json['community_name'] as String? ?? '',
      blockAndApartment: json['block_and_apartment'] as String? ?? '',
      hasUnpaidDues: json['has_unpaid_dues'] as bool? ?? false,
      unpaidDuesCount: json['unpaid_dues_count'] as int? ?? 0,
      latestAnnouncement: json['latest_announcement'] != null
          ? AnnouncementModel.fromJson(json['latest_announcement'] as Map<String, dynamic>)
          : null,
      myOpenFaultsCount: json['my_open_faults_count'] as int? ?? 0,
      upcomingMeeting: json['upcoming_meeting'] != null
          ? MeetingModel.fromJson(json['upcoming_meeting'] as Map<String, dynamic>)
          : null,
      activePoll: json['active_poll'] != null
          ? PollModel.fromJson(json['active_poll'] as Map<String, dynamic>)
          : null,
    );
  }
}
