import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/community_provider.dart';
import '../../core/providers/maintenance_provider.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/priority_badge.dart';
import '../../widgets/empty_state_view.dart';

class MaintenanceScreen extends StatefulWidget {
  const MaintenanceScreen({super.key});

  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen> {
  String _selectedStatus = 'ALL';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _load();
    });
  }

  void _load() {
    final comm = context.read<CommunityProvider>();
    if (comm.activeCommunity != null) {
      context.read<MaintenanceProvider>().loadRequests(comm.activeCommunity!.id);
    }
  }

  void _showStatusDialog(int id, String currentStatus) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Arıza Durumunu Güncelle', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.fiber_manual_record_rounded, color: AppColors.statusOpen),
                title: const Text('Açık'),
                onTap: () => _updateStatus(id, 'OPEN'),
              ),
              ListTile(
                leading: const Icon(Icons.sync_rounded, color: AppColors.statusInProgress),
                title: const Text('İşlemde'),
                onTap: () => _updateStatus(id, 'IN_PROGRESS'),
              ),
              ListTile(
                leading: const Icon(Icons.hourglass_top_rounded, color: AppColors.statusWaiting),
                title: const Text('Beklemede'),
                onTap: () => _updateStatus(id, 'WAITING'),
              ),
              ListTile(
                leading: const Icon(Icons.check_circle_rounded, color: AppColors.statusResolved),
                title: const Text('Çözüldü'),
                onTap: () => _updateStatus(id, 'RESOLVED'),
              ),
              ListTile(
                leading: const Icon(Icons.lock_outline_rounded, color: AppColors.statusClosed),
                title: const Text('Kapandı'),
                onTap: () => _updateStatus(id, 'CLOSED'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _updateStatus(int id, String newStatus) async {
    Navigator.pop(context);
    final comm = context.read<CommunityProvider>();
    if (comm.activeCommunity != null) {
      await context.read<MaintenanceProvider>().updateStatus(id, newStatus, comm.activeCommunity!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final comm = context.watch<CommunityProvider>();
    final provider = context.watch<MaintenanceProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isManager = comm.isCurrentUserManager;

    var filtered = provider.requests;
    if (_selectedStatus != 'ALL') {
      filtered = filtered.where((r) => r.status == _selectedStatus).toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isManager ? 'Tüm Arıza Talepleri' : 'Arızalarım'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Arıza Bildir',
            onPressed: () => Navigator.pushNamed(context, '/report-fault'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('Tümü'),
                  selected: _selectedStatus == 'ALL',
                  onSelected: (_) => setState(() => _selectedStatus = 'ALL'),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Açık'),
                  selected: _selectedStatus == 'OPEN',
                  onSelected: (_) => setState(() => _selectedStatus = 'OPEN'),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('İşlemde'),
                  selected: _selectedStatus == 'IN_PROGRESS',
                  onSelected: (_) => setState(() => _selectedStatus = 'IN_PROGRESS'),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Çözüldü'),
                  selected: _selectedStatus == 'RESOLVED',
                  onSelected: (_) => setState(() => _selectedStatus = 'RESOLVED'),
                ),
              ],
            ),
          ),
          const Divider(),

          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? EmptyStateView(
                        icon: Icons.build_rounded,
                        title: 'Harika! Açık bir arıza bulunmuyor.',
                        subtitle: 'Yeni bir teknik sorun veya arıza olduğunda bildirebilirsiniz.',
                        actionLabel: 'Arıza Bildir',
                        onAction: () => Navigator.pushNamed(context, '/report-fault'),
                      )
                    : RefreshIndicator(
                        onRefresh: () async => _load(),
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (ctx, index) {
                            final item = filtered[index];
                            return Container(
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
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      StatusBadge(status: item.status),
                                      PriorityBadge(priority: item.priority),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    item.title,
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item.description,
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Text(
                                        'Kategori: ${item.category}',
                                        style: Theme.of(context).textTheme.bodySmall,
                                      ),
                                      const Spacer(),
                                      if (isManager) ...[
                                        OutlinedButton.icon(
                                          style: OutlinedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            minimumSize: Size.zero,
                                          ),
                                          icon: const Icon(Icons.edit_rounded, size: 14),
                                          label: const Text('Durum Değiştir', style: TextStyle(fontSize: 12)),
                                          onPressed: () => _showStatusDialog(item.id, item.status),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
