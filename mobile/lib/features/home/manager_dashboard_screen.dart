import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/community_provider.dart';
import '../../core/providers/dashboard_provider.dart';
import '../../widgets/stat_kpi_card.dart';

class ManagerDashboardScreen extends StatefulWidget {
  final VoidCallback onNavigateAnnouncements;
  final VoidCallback onNavigateFaults;
  final VoidCallback onNavigateManagement;
  final VoidCallback onNavigateDues;
  final VoidCallback onNavigateMeetings;
  final VoidCallback onNavigatePolls;
  final VoidCallback onNavigateMessages;

  const ManagerDashboardScreen({
    super.key,
    required this.onNavigateAnnouncements,
    required this.onNavigateFaults,
    required this.onNavigateManagement,
    required this.onNavigateDues,
    required this.onNavigateMeetings,
    required this.onNavigatePolls,
    required this.onNavigateMessages,
  });

  @override
  State<ManagerDashboardScreen> createState() => _ManagerDashboardScreenState();
}

class _ManagerDashboardScreenState extends State<ManagerDashboardScreen> {
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
      await context.read<DashboardProvider>().loadManagerDashboard(comm.activeCommunity!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final comm = context.watch<CommunityProvider>();
    final dashboard = context.watch<DashboardProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final stats = dashboard.managerStats;
    final activeComm = comm.activeCommunity;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Yönetici Paneli 🛡️',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            Text(
              activeComm?.name ?? 'Site Seçilmedi',
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
              // KPI CARDS 2x2 GRID (Sec 11)
              Row(
                children: [
                  Expanded(
                    child: StatKpiCard(
                      title: 'TOPLAM DAİRE',
                      value: '${stats?.totalApartments ?? 20}',
                      icon: Icons.apartment_rounded,
                      color: AppColors.primary,
                      onTap: widget.onNavigateManagement,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatKpiCard(
                      title: 'AKTİF SAKİN',
                      value: '${stats?.activeResidents ?? 3}',
                      icon: Icons.people_alt_rounded,
                      color: AppColors.secondary,
                      onTap: widget.onNavigateManagement,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: StatKpiCard(
                      title: 'AÇIK ARIZA',
                      value: '${stats?.openFaults ?? 2}',
                      icon: Icons.build_rounded,
                      color: AppColors.statusInProgress,
                      onTap: widget.onNavigateFaults,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatKpiCard(
                      title: 'TAHSİLAT ORANI',
                      value: '%${stats?.collectionRatePct.toStringAsFixed(0) ?? "50"}',
                      icon: Icons.pie_chart_rounded,
                      color: AppColors.duesPaid,
                      onTap: widget.onNavigateDues,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // AİDAT FİNANSAL ÖZET BARI (Sec 11, 36 - MANAGER ONLY)
              Text(
                'AİDAT VE FİNANS ÖZETİ',
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
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          const Text('Tahsil Edilen', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          const SizedBox(height: 4),
                          Text(
                            '₺${stats?.totalDuesCollected.toStringAsFixed(0) ?? "2500"}',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.success),
                          ),
                        ],
                      ),
                      Container(height: 30, width: 1, color: isDark ? Colors.white12 : Colors.black12),
                      Column(
                        children: [
                          const Text('Bekleyen Aidat', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          const SizedBox(height: 4),
                          Text(
                            '₺${stats?.totalDuesUnpaid.toStringAsFixed(0) ?? "2500"}',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.error),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // HIZLI İŞLEM BUTONLARI (Sec 12)
              Text(
                'YÖNETİM HIZLI ERİŞİM',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 12),

              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _QuickButton(
                    label: 'Aidat Yönetimi',
                    icon: Icons.credit_card_rounded,
                    color: AppColors.warning,
                    onTap: widget.onNavigateDues,
                  ),
                  _QuickButton(
                    label: 'Duyurular',
                    icon: Icons.campaign_rounded,
                    color: AppColors.primary,
                    onTap: widget.onNavigateAnnouncements,
                  ),
                  _QuickButton(
                    label: 'Arızalar',
                    icon: Icons.build_rounded,
                    color: AppColors.statusInProgress,
                    onTap: widget.onNavigateFaults,
                  ),
                  _QuickButton(
                    label: 'Toplantılar',
                    icon: Icons.event_rounded,
                    color: AppColors.info,
                    onTap: widget.onNavigateMeetings,
                  ),
                  _QuickButton(
                    label: 'Anketler',
                    icon: Icons.poll_rounded,
                    color: AppColors.secondary,
                    onTap: widget.onNavigatePolls,
                  ),
                  _QuickButton(
                    label: 'Özel Mesajlar',
                    icon: Icons.mail_rounded,
                    color: AppColors.primaryDark,
                    onTap: widget.onNavigateMessages,
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: (MediaQuery.of(context).size.width - 64) / 2,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
