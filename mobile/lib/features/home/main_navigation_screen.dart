import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/community_provider.dart';
import '../../widgets/quick_action_sheet.dart';

// Screens
import 'resident_home_screen.dart';
import 'manager_dashboard_screen.dart';
import '../announcements/announcements_screen.dart';
import '../maintenance/maintenance_screen.dart';
import '../meetings/meetings_screen.dart';
import '../profile/profile_screen.dart';
import '../dues/manager_dues_screen.dart';
import '../dues/resident_dues_screen.dart';
import '../messages/messages_screen.dart';
import '../polls/polls_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final comm = context.watch<CommunityProvider>();
    final isManager = comm.isCurrentUserManager;

    // Screens per role (Sec 39)
    final List<Widget> pages = isManager
        ? [
            ManagerDashboardScreen(
              onNavigateAnnouncements: () => setState(() => _currentIndex = 1),
              onNavigateFaults: () => setState(() => _currentIndex = 2),
              onNavigateManagement: () => setState(() => _currentIndex = 3),
              onNavigateDues: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManagerDuesScreen())),
              onNavigateMeetings: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MeetingsScreen())),
              onNavigatePolls: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PollsScreen())),
              onNavigateMessages: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MessagesScreen())),
            ),
            const AnnouncementsScreen(),
            const MaintenanceScreen(),
            _ManagerHubScreen(
              onDues: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManagerDuesScreen())),
              onMeetings: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MeetingsScreen())),
              onPolls: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PollsScreen())),
              onMessages: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MessagesScreen())),
              onBuilding: () => Navigator.pushNamed(context, '/building-info'),
            ),
            const ProfileScreen(),
          ]
        : [
            ResidentHomeScreen(
              onNavigateAnnouncements: () => setState(() => _currentIndex = 1),
              onNavigateFaults: () => setState(() => _currentIndex = 2),
              onNavigateCalendar: () => setState(() => _currentIndex = 3),
              onNavigateDues: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ResidentDuesScreen())),
            ),
            const AnnouncementsScreen(),
            const MaintenanceScreen(),
            const MeetingsScreen(),
            const ProfileScreen(),
          ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          QuickActionSheet.show(
            context,
            isManager: isManager,
            onNewAnnouncement: () => Navigator.pushNamed(context, '/announcements'),
            onReportFault: () => Navigator.pushNamed(context, '/report-fault'),
            onNewMeeting: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MeetingsScreen())),
            onNewPoll: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PollsScreen())),
            onNewDue: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManagerDuesScreen())),
            onNewMessage: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MessagesScreen())),
          );
        },
        backgroundColor: AppColors.primary,
        elevation: 3,
        child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 28),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        destinations: isManager
            ? const [
                NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Ana Sayfa'),
                NavigationDestination(icon: Icon(Icons.campaign_outlined), selectedIcon: Icon(Icons.campaign_rounded), label: 'Duyurular'),
                NavigationDestination(icon: Icon(Icons.build_outlined), selectedIcon: Icon(Icons.build_rounded), label: 'Arızalar'),
                NavigationDestination(icon: Icon(Icons.admin_panel_settings_outlined), selectedIcon: Icon(Icons.admin_panel_settings_rounded), label: 'Yönetim'),
                NavigationDestination(icon: Icon(Icons.person_outline_rounded), selectedIcon: Icon(Icons.person_rounded), label: 'Profil'),
              ]
            : const [
                NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Ana Sayfa'),
                NavigationDestination(icon: Icon(Icons.campaign_outlined), selectedIcon: Icon(Icons.campaign_rounded), label: 'Duyurular'),
                NavigationDestination(icon: Icon(Icons.build_outlined), selectedIcon: Icon(Icons.build_rounded), label: 'Arızalar'),
                NavigationDestination(icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month_rounded), label: 'Takvim'),
                NavigationDestination(icon: Icon(Icons.person_outline_rounded), selectedIcon: Icon(Icons.person_rounded), label: 'Profil'),
              ],
      ),
    );
  }
}

class _ManagerHubScreen extends StatelessWidget {
  final VoidCallback onDues;
  final VoidCallback onMeetings;
  final VoidCallback onPolls;
  final VoidCallback onMessages;
  final VoidCallback onBuilding;

  const _ManagerHubScreen({
    required this.onDues,
    required this.onMeetings,
    required this.onPolls,
    required this.onMessages,
    required this.onBuilding,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Site Yönetimi')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _HubTile(
            title: 'Aidat Yönetimi & Takip',
            subtitle: 'Daire bazında aidat tahakkuku, tahsilat ve ödeme işleme',
            icon: Icons.credit_card_rounded,
            color: AppColors.warning,
            onTap: onDues,
          ),
          const SizedBox(height: 12),
          _HubTile(
            title: 'Sakinlere Özel Mesajlar',
            subtitle: 'Birebir 1-on-1 mesajlaşma ve bildirimler',
            icon: Icons.mail_rounded,
            color: AppColors.primary,
            onTap: onMessages,
          ),
          const SizedBox(height: 12),
          _HubTile(
            title: 'Toplantılar & Kararlar',
            subtitle: 'Kat malikleri toplantısı planlama ve katılım listesi',
            icon: Icons.event_rounded,
            color: AppColors.info,
            onTap: onMeetings,
          ),
          const SizedBox(height: 12),
          _HubTile(
            title: 'Anketler & Oylamalar',
            subtitle: 'Sakinlerin katılım göstereceği anketler düzenleme',
            icon: Icons.poll_rounded,
            color: AppColors.secondary,
            onTap: onPolls,
          ),
          const SizedBox(height: 12),
          _HubTile(
            title: 'Bina & Site Ayarları',
            subtitle: 'Adres, kurallar, acil numaralar ve davet kodları',
            icon: Icons.settings_suggest_rounded,
            color: isDark ? AppColors.primaryLight : AppColors.primaryDark,
            onTap: onBuilding,
          ),
        ],
      ),
    );
  }
}

class _HubTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _HubTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        subtitle: Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}
