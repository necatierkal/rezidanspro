import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/community_provider.dart';
import '../../core/providers/dashboard_provider.dart';
import '../../core/providers/dues_provider.dart';
import '../../widgets/priority_badge.dart';

class ResidentHomeScreen extends StatefulWidget {
  final VoidCallback onNavigateAnnouncements;
  final VoidCallback onNavigateFaults;
  final VoidCallback onNavigateCalendar;
  final VoidCallback onNavigateDues;

  const ResidentHomeScreen({
    super.key,
    required this.onNavigateAnnouncements,
    required this.onNavigateFaults,
    required this.onNavigateCalendar,
    required this.onNavigateDues,
  });

  @override
  State<ResidentHomeScreen> createState() => _ResidentHomeScreenState();
}

class _ResidentHomeScreenState extends State<ResidentHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refresh();
    });
  }

  Future<void> _refresh() async {
    final comm = context.read<CommunityProvider>();
    if (comm.activeCommunity != null) {
      await context.read<DashboardProvider>().loadResidentDashboard(comm.activeCommunity!.id);
      await context.read<DuesProvider>().loadMyDues(comm.activeCommunity!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final comm = context.watch<CommunityProvider>();
    final dashboard = context.watch<DashboardProvider>();
    final duesProvider = context.watch<DuesProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final summary = dashboard.residentSummary;
    final activeComm = comm.activeCommunity;
    final aptDisplay = comm.activeMembership?.apartmentDisplay ?? 'Daire Tanımsız';

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Merhaba ${auth.currentUser?.firstName ?? "Komşu"} 👋',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            Text(
              '${activeComm?.name ?? "Bina Seçilmedi"} · $aptDisplay',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            onPressed: () => Navigator.pushNamed(context, '/notifications'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. SON DUYURU KARTI (Sec 13)
              if (summary?.latestAnnouncement != null) ...[
                Text(
                  'SON DUYURU',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: widget.onNavigateAnnouncements,
                  borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : Colors.white,
                      borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                      border: Border.all(
                        color: isDark ? AppColors.borderDark : AppColors.borderLight,
                      ),
                      boxShadow: isDark ? AppTheme.softShadowDark : AppTheme.softShadowLight,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            PriorityBadge(priority: summary!.latestAnnouncement!.priority),
                            Text(
                              summary.latestAnnouncement!.publishedAt.toLocal().toString().substring(0, 10),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          summary.latestAnnouncement!.title,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          summary.latestAnnouncement!.body,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // 2. AİDAT DURUMUM KARTI (Sec 10, 13, 97 - STRICT PRIVACY)
              Text(
                'AİDAT DURUMUM',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: widget.onNavigateDues,
                borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: duesProvider.hasMyUnpaidDues
                        ? AppColors.error.withValues(alpha: isDark ? 0.15 : 0.06)
                        : AppColors.success.withValues(alpha: isDark ? 0.15 : 0.06),
                    borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                    border: Border.all(
                      color: duesProvider.hasMyUnpaidDues
                          ? AppColors.error.withValues(alpha: 0.25)
                          : AppColors.success.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: (duesProvider.hasMyUnpaidDues ? AppColors.error : AppColors.success)
                              .withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          duesProvider.hasMyUnpaidDues
                              ? Icons.warning_amber_rounded
                              : Icons.check_circle_outline_rounded,
                          color: duesProvider.hasMyUnpaidDues ? AppColors.error : AppColors.success,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              duesProvider.hasMyUnpaidDues
                                  ? 'Ödenmemiş Aidatınız Bulunuyor'
                                  : 'Tüm Aidatlarınız Ödendi',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: duesProvider.hasMyUnpaidDues ? AppColors.error : AppColors.success,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              duesProvider.hasMyUnpaidDues
                                  ? 'Toplam Borç: ₺${duesProvider.myTotalUnpaidAmount.toStringAsFixed(0)}'
                                  : 'Herhangi bir gecikmiş borcunuz bulunmamaktadır.',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 3. STATS & QUICK NAVIGATION GRID (Açık Arızalarım, Yaklaşan Toplantı)
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: widget.onNavigateFaults,
                      borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurface : Colors.white,
                          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                          border: Border.all(
                            color: isDark ? AppColors.borderDark : AppColors.borderLight,
                          ),
                          boxShadow: isDark ? AppTheme.softShadowDark : AppTheme.softShadowLight,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.statusInProgress.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.build_rounded, color: AppColors.statusInProgress, size: 20),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '${summary?.myOpenFaultsCount ?? 0}',
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Açık Arızalarım',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: widget.onNavigateCalendar,
                      borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurface : Colors.white,
                          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                          border: Border.all(
                            color: isDark ? AppColors.borderDark : AppColors.borderLight,
                          ),
                          boxShadow: isDark ? AppTheme.softShadowDark : AppTheme.softShadowLight,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.info.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.event_rounded, color: AppColors.info, size: 20),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              summary?.upcomingMeeting != null ? 'Planlandı' : 'Yok',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Yaklaşan Toplantı',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 4. BİNA ACİL BİLGİ BUTONU (Sec 32, 33)
              InkWell(
                onTap: () => Navigator.pushNamed(context, '/building-info'),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.contact_phone_rounded, color: AppColors.primary, size: 22),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Binamız & Acil Numaralar',
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                            ),
                            Text(
                              '112 Acil, Güvenlik, Asansör servisi ve site kuralları',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded, color: Colors.grey),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
