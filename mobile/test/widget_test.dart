import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rezidanspro/core/config/app_config.dart';
import 'package:rezidanspro/core/theme/app_colors.dart';
import 'package:rezidanspro/core/models/app_models.dart';
import 'package:rezidanspro/core/l10n/app_localizations.dart';
import 'package:rezidanspro/widgets/priority_badge.dart';
import 'package:rezidanspro/widgets/status_badge.dart';
import 'package:rezidanspro/widgets/empty_state_view.dart';
import 'package:rezidanspro/widgets/stat_kpi_card.dart';
import 'package:rezidanspro/widgets/quick_action_sheet.dart';

void main() {
  group('RezidansPro Brand & Configuration Tests', () {
    test('Verify central brand configuration', () {
      expect(AppConfig.appName, 'RezidansPro');
      expect(AppConfig.tagline, 'Binanızın iletişim merkezi.');
      expect(AppConfig.storeTitle, 'RezidansPro - Apartman & Site');
      expect(AppConfig.primaryColor, const Color(0xFF2563EB));
    });

    test('Verify exact brand palette hex values from prompt', () {
      expect(AppColors.primary, const Color(0xFF2563EB));
      expect(AppColors.secondary, const Color(0xFF14B8A6));
      expect(AppColors.dark, const Color(0xFF0F172A));
      expect(AppColors.backgroundLight, const Color(0xFFF8FAFC));
      expect(AppColors.warning, const Color(0xFFF59E0B));
      expect(AppColors.error, const Color(0xFFDC2626));
      expect(AppColors.success, const Color(0xFF16A34A));
    });

    test('Verify model deserialization', () {
      final user = UserModel.fromJson({
        'id': 1,
        'uuid': 'uuid-123',
        'email': 'manager@rezidanspro.app',
        'first_name': 'Kemal',
        'last_name': 'Yılmaz',
        'is_active': true,
        'created_at': '2026-10-03T12:00:00Z',
      });

      expect(user.id, 1);
      expect(user.fullName, 'Kemal Yılmaz');

      final due = DueModel.fromJson({
        'id': 101,
        'community_id': 1,
        'apartment_id': 3,
        'period': 'Ekim 2026',
        'amount': 2500.0,
        'due_date': '2026-10-10T00:00:00Z',
        'status': 'UNPAID',
        'created_at': '2026-10-01T00:00:00Z',
        'payments': [],
      });

      expect(due.amount, 2500.0);
      expect(due.isPaid, false);
      expect(due.apartmentId, 3);
    });
  });

  group('RezidansPro UI Components Tests', () {
    testWidgets('PriorityBadge renders Urgent correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PriorityBadge(priority: 'URGENT'),
          ),
        ),
      );

      expect(find.text('Acil'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
    });

    testWidgets('StatusBadge renders Dues Paid correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatusBadge(status: 'PAID', isDues: true),
          ),
        ),
      );

      expect(find.text('Ödendi'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    });

    testWidgets('EmptyStateView renders according to prompt spec', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyStateView(
              icon: Icons.campaign_rounded,
              title: 'Henüz duyuru bulunmuyor.',
              subtitle: 'Açıklama metni',
            ),
          ),
        ),
      );

      expect(find.text('Henüz duyuru bulunmuyor.'), findsOneWidget);
      expect(find.text('Açıklama metni'), findsOneWidget);
    });

    testWidgets('StatKpiCard renders metric', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatKpiCard(
              title: 'TOPLAM DAİRE',
              value: '48',
              icon: Icons.apartment_rounded,
            ),
          ),
        ),
      );

      expect(find.text('TOPLAM DAİRE'), findsOneWidget);
      expect(find.text('48'), findsOneWidget);
    });

    testWidgets('QuickActionSheet renders manager actions for manager role', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuickActionSheet(
              isManager: true,
              onNewAnnouncement: () {},
              onReportFault: () {},
              onNewMeeting: () {},
              onNewPoll: () {},
              onNewDue: () {},
              onNewMessage: () {},
            ),
          ),
        ),
      );

      expect(find.text('Hızlı İşlemler'), findsOneWidget);
      expect(find.text('Duyuru Yayınla'), findsOneWidget);
      expect(find.text('Arıza Kaydı Aç'), findsOneWidget);
      expect(find.text('Toplantı Planla'), findsOneWidget);
      expect(find.text('Yeni Anket'), findsOneWidget);
      expect(find.text('Aidat Tanımla'), findsOneWidget);
      expect(find.text('Sakine Mesaj Yaz'), findsOneWidget);
      expect(find.text('Yöneticiye Mesaj'), findsNothing);
    });

    testWidgets('QuickActionSheet renders only resident actions for resident role', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuickActionSheet(
              isManager: false,
              onNewAnnouncement: () {},
              onReportFault: () {},
              onNewMeeting: () {},
              onNewPoll: () {},
              onNewDue: () {},
              onNewMessage: () {},
            ),
          ),
        ),
      );

      expect(find.text('Hızlı İşlemler'), findsOneWidget);
      expect(find.text('Arıza Bildir'), findsOneWidget);
      expect(find.text('Yöneticiye Mesaj'), findsOneWidget);
      // Manager actions must NOT be rendered for residents
      expect(find.text('Duyuru Yayınla'), findsNothing);
      expect(find.text('Toplantı Planla'), findsNothing);
      expect(find.text('Anket Başlat'), findsNothing);
      expect(find.text('Aidat Tanımla'), findsNothing);
    });
  });

  group('RezidansPro Localization Tests', () {
    test('Verify Turkish localization keys', () {
      final l10nTr = AppLocalizations(const Locale('tr', 'TR'));
      expect(l10nTr.appName, 'RezidansPro');
      expect(l10nTr.tagline, 'Binanızın iletişim merkezi.');
      expect(l10nTr.navManagement, 'Yönetim');
      expect(l10nTr.navAnnouncements, 'Duyurular');
    });

    test('Verify English localization keys', () {
      final l10nEn = AppLocalizations(const Locale('en', 'US'));
      expect(l10nEn.appName, 'RezidansPro');
      expect(l10nEn.tagline, 'Your building communication hub.');
      expect(l10nEn.navManagement, 'Management');
      expect(l10nEn.navAnnouncements, 'Announcements');
    });
  });
}
