import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/community_provider.dart';
import '../../core/providers/announcement_provider.dart';
import '../../widgets/priority_badge.dart';
import '../../widgets/empty_state_view.dart';

class AnnouncementsScreen extends StatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  String _selectedPriority = 'ALL';

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
      context.read<AnnouncementProvider>().loadAnnouncements(comm.activeCommunity!.id);
    }
  }

  void _showCreateDialog() {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();
    String priority = 'NORMAL';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Yeni Duyuru Yayınla'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Başlık', hintText: 'Örn: Asansör Bakımı'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: bodyController,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'Duyuru Metni', hintText: 'Açıklama giriniz...'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: priority,
                  decoration: const InputDecoration(labelText: 'Öncelik Derecesi'),
                  items: const [
                    DropdownMenuItem(value: 'NORMAL', child: Text('Normal Duyuru')),
                    DropdownMenuItem(value: 'IMPORTANT', child: Text('Önemli')),
                    DropdownMenuItem(value: 'URGENT', child: Text('Acil')),
                  ],
                  onChanged: (val) => setDialogState(() => priority = val ?? 'NORMAL'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.trim().isEmpty || bodyController.text.trim().isEmpty) return;
                final comm = context.read<CommunityProvider>();
                if (comm.activeCommunity != null) {
                  await context.read<AnnouncementProvider>().createAnnouncement(
                        communityId: comm.activeCommunity!.id,
                        title: titleController.text,
                        body: bodyController.text,
                        priority: priority,
                      );
                  if (mounted) Navigator.pop(ctx);
                }
              },
              child: const Text('Yayınla'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final comm = context.watch<CommunityProvider>();
    final provider = context.watch<AnnouncementProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isManager = comm.isCurrentUserManager;

    var filtered = provider.announcements;
    if (_selectedPriority != 'ALL') {
      filtered = filtered.where((a) => a.priority == _selectedPriority).toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Duyurular'),
        actions: [
          if (isManager)
            IconButton(
              icon: const Icon(Icons.add_circle_outline_rounded),
              tooltip: 'Duyuru Ekle',
              onPressed: _showCreateDialog,
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
                  selected: _selectedPriority == 'ALL',
                  onSelected: (_) => setState(() => _selectedPriority = 'ALL'),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Normal'),
                  selected: _selectedPriority == 'NORMAL',
                  onSelected: (_) => setState(() => _selectedPriority = 'NORMAL'),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Önemli'),
                  selected: _selectedPriority == 'IMPORTANT',
                  onSelected: (_) => setState(() => _selectedPriority = 'IMPORTANT'),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Acil'),
                  selected: _selectedPriority == 'URGENT',
                  onSelected: (_) => setState(() => _selectedPriority = 'URGENT'),
                ),
              ],
            ),
          ),
          const Divider(),

          // Content List
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? EmptyStateView(
                        icon: Icons.campaign_rounded,
                        title: 'Henüz duyuru bulunmuyor.',
                        subtitle: 'Yönetim tarafından yeni bir duyuru yayınlandığında burada görebilirsiniz.',
                        actionLabel: isManager ? 'Duyuru Oluştur' : null,
                        onAction: isManager ? _showCreateDialog : null,
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
                                      PriorityBadge(priority: item.priority),
                                      Text(
                                        item.publishedAt.toLocal().toString().substring(0, 16),
                                        style: Theme.of(context).textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    item.title,
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    item.body,
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                          height: 1.45,
                                        ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      const Icon(Icons.person_pin_circle_outlined, size: 16, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Text(
                                        item.authorName,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                        ),
                                      ),
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
