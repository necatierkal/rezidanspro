import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(const Locale('tr', 'TR'));
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  bool get isTurkish => locale.languageCode == 'tr';

  // Branding & General
  String get appName => 'RezidansPro';
  String get tagline => isTurkish
      ? 'Binanızın iletişim merkezi.'
      : 'Your building communication hub.';
  String get secondaryTagline =>
      isTurkish ? 'Binanız artık cebinizde.' : 'Your building in your pocket.';

  // Navigation
  String get navHome => isTurkish ? 'Ana Sayfa' : 'Home';
  String get navAnnouncements => isTurkish ? 'Duyurular' : 'Announcements';
  String get navMaintenance => isTurkish ? 'Arızalar' : 'Faults';
  String get navCalendar => isTurkish ? 'Takvim' : 'Calendar';
  String get navProfile => isTurkish ? 'Profil' : 'Profile';
  String get navManagement => isTurkish ? 'Yönetim' : 'Management';

  // Management Subsections
  String get mgmtDues => isTurkish ? 'Aidatlar' : 'Dues';
  String get mgmtResidents => isTurkish ? 'Sakinler' : 'Residents';
  String get mgmtMeetings => isTurkish ? 'Toplantılar' : 'Meetings';
  String get mgmtPolls => isTurkish ? 'Anketler' : 'Polls';
  String get mgmtReports => isTurkish ? 'Raporlar' : 'Reports';
  String get mgmtMessages => isTurkish ? 'Mesajlar' : 'Messages';
  String get mgmtBuildingSettings =>
      isTurkish ? 'Bina Ayarları' : 'Building Settings';

  // Onboarding & Auth
  String get welcomeTitle =>
      isTurkish ? "RezidansPro'ya Hoş Geldiniz" : 'Welcome to RezidansPro';
  String get findBuilding =>
      isTurkish ? 'Binanızı Bulun veya Katılın' : 'Find or Join Your Building';
  String get enterInviteCode =>
      isTurkish ? 'Davet Kodu Girin' : 'Enter Invite Code';
  String get scanQrCode => isTurkish ? 'QR Kod Tara' : 'Scan QR Code';
  String get selectApartment => isTurkish ? 'Dairenizi Seçin' : 'Select Your Apartment';
  String get pendingApproval =>
      isTurkish ? 'Yönetici Onayı Bekleniyor' : 'Awaiting Manager Approval';
  String get login => isTurkish ? 'Giriş Yap' : 'Log In';
  String get register => isTurkish ? 'Kayıt Ol' : 'Register';
  String get email => isTurkish ? 'E-posta' : 'Email';
  String get password => isTurkish ? 'Şifre' : 'Password';
  String get firstName => isTurkish ? 'Ad' : 'First Name';
  String get lastName => isTurkish ? 'Soyad' : 'Last Name';
  String get phone => isTurkish ? 'Telefon' : 'Phone Number';
  String get forgotPassword =>
      isTurkish ? 'Şifremi Unuttum' : 'Forgot Password';
  String get deleteAccount => isTurkish ? 'Hesabımı Sil' : 'Delete Account';
  String get logout => isTurkish ? 'Çıkış Yap' : 'Log Out';

  // Dashboard & Cards
  String get greeting => isTurkish ? 'Merhaba' : 'Hello';
  String get latestAnnouncement =>
      isTurkish ? 'SON DUYURU' : 'LATEST ANNOUNCEMENT';
  String get myOpenFaults =>
      isTurkish ? 'Açık arızalarım' : 'My open faults';
  String get upcomingMeeting =>
      isTurkish ? 'Yaklaşan toplantı' : 'Upcoming meeting';
  String get activePoll => isTurkish ? 'Aktif anket' : 'Active poll';
  String get myDuesStatus =>
      isTurkish ? 'Aidat durumum' : 'My dues status';
  String get thisMonthDue =>
      isTurkish ? 'Bu ayki aidat' : 'This month due';
  String get unpaidDuesAlert => isTurkish
      ? 'Ödenmemiş aidatınız bulunuyor.'
      : 'You have unpaid dues.';
  String get duesPaidSuccess =>
      isTurkish ? 'Ödenmemiş aidatınız yok.' : 'All dues are paid.';

  // Manager Dashboard KPIs
  String get totalApartments =>
      isTurkish ? 'TOPLAM DAİRE' : 'TOTAL APARTMENTS';
  String get activeResidents =>
      isTurkish ? 'AKTİF SAKİN' : 'ACTIVE RESIDENTS';
  String get openFaults => isTurkish ? 'AÇIK ARIZA' : 'OPEN FAULTS';
  String get pendingRequests =>
      isTurkish ? 'BEKLEYEN TALEP' : 'PENDING REQUESTS';
  String get totalDues => isTurkish ? 'TOPLAM AİDAT' : 'TOTAL DUES';
  String get collectionRate =>
      isTurkish ? 'Tahsilat Oranı' : 'Collection Rate';

  // Maintenance Categories
  String get catElevator => isTurkish ? 'Asansör' : 'Elevator';
  String get catWater => isTurkish ? 'Su & Tesisat' : 'Water & Plumbing';
  String get catElectricity => isTurkish ? 'Elektrik' : 'Electricity';
  String get catLighting => isTurkish ? 'Aydınlatma' : 'Lighting';
  String get catDoor => isTurkish ? 'Kapı & Giriş' : 'Door & Gate';
  String get catParking => isTurkish ? 'Otopark' : 'Parking';
  String get catGarden => isTurkish ? 'Bahçe & Çevre' : 'Garden';
  String get catHeating => isTurkish ? 'Isıtma' : 'Heating';
  String get catCleaning => isTurkish ? 'Temizlik' : 'Cleaning';
  String get catSecurity => isTurkish ? 'Güvenlik' : 'Security';
  String get catOther => isTurkish ? 'Diğer' : 'Other';

  // Maintenance Statuses
  String get statusOpen => isTurkish ? 'Açık' : 'Open';
  String get statusInProgress => isTurkish ? 'İşlemde' : 'In Progress';
  String get statusWaiting => isTurkish ? 'Beklemede' : 'Waiting';
  String get statusResolved => isTurkish ? 'Çözüldü' : 'Resolved';
  String get statusClosed => isTurkish ? 'Kapandı' : 'Closed';

  // Priorities
  String get priorityNormal => isTurkish ? 'Normal' : 'Normal';
  String get priorityImportant => isTurkish ? 'Önemli' : 'Important';
  String get priorityUrgent => isTurkish ? 'Acil' : 'Urgent';

  // Dues Statuses
  String get duesStatusPaid => isTurkish ? 'Ödendi' : 'Paid';
  String get duesStatusUnpaid => isTurkish ? 'Ödenmedi' : 'Unpaid';
  String get duesStatusPartial => isTurkish ? 'Kısmi' : 'Partial';
  String get duesStatusOverdue => isTurkish ? 'Gecikmiş' : 'Overdue';

  // Empty States (Master Prompt Sec 61)
  String get emptyAnnouncements =>
      isTurkish ? 'Henüz duyuru bulunmuyor.' : 'No announcements yet.';
  String get emptyFaults => isTurkish
      ? 'Harika! Açık bir arıza bulunmuyor.'
      : 'Great! No open faults.';
  String get emptyDues => isTurkish
      ? 'Bu döneme ait aidat kaydınız bulunmuyor.'
      : 'No dues record for this period.';
  String get emptyMessages =>
      isTurkish ? 'Henüz özel mesajınız yok.' : 'No private messages yet.';
  String get emptyMeetings =>
      isTurkish ? 'Planlanmış toplantı bulunmuyor.' : 'No planned meetings.';
  String get emptyPolls =>
      isTurkish ? 'Aktif bir anket bulunmuyor.' : 'No active polls.';

  // Error States (Master Prompt Sec 62)
  String get defaultError => isTurkish
      ? 'Bir sorun oluştu. Lütfen tekrar deneyin.'
      : 'Something went wrong. Please try again.';
  String get networkError => isTurkish
      ? 'İnternet bağlantınızı kontrol edip tekrar deneyin.'
      : 'Please check your connection and try again.';
  String get unauthorizedError => isTurkish
      ? 'Bu işlem için yetkiniz bulunmuyor.'
      : 'You are not authorized for this action.';

  // Actions
  String get actionSave => isTurkish ? 'Kaydet' : 'Save';
  String get actionSend => isTurkish ? 'Gönder' : 'Send';
  String get actionCancel => isTurkish ? 'İptal' : 'Cancel';
  String get actionDelete => isTurkish ? 'Sil' : 'Delete';
  String get actionReportFault =>
      isTurkish ? 'Arıza Bildir' : 'Report Fault';
  String get actionNewAnnouncement =>
      isTurkish ? 'Duyuru Oluştur' : 'New Announcement';
  String get actionNewMeeting =>
      isTurkish ? 'Toplantı Oluştur' : 'New Meeting';
  String get actionNewPoll => isTurkish ? 'Anket Oluştur' : 'New Poll';
  String get actionNewDue => isTurkish ? 'Aidat Tanımla' : 'Define Due';
  String get actionNewMessage =>
      isTurkish ? 'Özel Mesaj Yaz' : 'New Private Message';
  String get actionVote => isTurkish ? 'Oy Ver' : 'Vote';
  String get actionAttend => isTurkish ? 'Katılacağım' : 'I will attend';
  String get actionNotAttend =>
      isTurkish ? 'Katılamayacağım' : 'Cannot attend';
  String get actionMarkPaid =>
      isTurkish ? 'Ödendi Olarak İşaretle' : 'Mark as Paid';
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['tr', 'en'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(AppLocalizations(locale));
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
