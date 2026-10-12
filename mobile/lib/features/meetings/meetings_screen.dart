import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/community_provider.dart';
import '../../core/providers/meeting_provider.dart';
import '../../widgets/empty_state_view.dart';

class MeetingsScreen extends StatefulWidget {
  const MeetingsScreen({super.key});

  @override
  State<MeetingsScreen> createState() => _MeetingsScreenState();
}

class _MeetingsScreenState extends State<MeetingsScreen> {
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
      context.read<MeetingProvider>().loadMeetings(comm.activeCommunity!.id);
    }
  }

  void _showCreateDialog() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final locationController = TextEditingController(text: 'Gül Sitesi Toplantı Salonu');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Yeni Toplantı Planla'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Toplantı Başlığı')),
              const SizedBox(height: 12),
              TextField(controller: locationController, decoration: const InputDecoration(labelText: 'Konum')),
              const SizedBox(height: 12),
              TextField(controller: descController, maxLines: 3, decoration: const InputDecoration(labelText: 'Gündem / Açıklama')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.trim().isEmpty) return;
              final comm = context.read<CommunityProvider>();
              if (comm.activeCommunity != null) {
                await context.read<MeetingProvider>().createMeeting(
                      communityId: comm.activeCommunity!.id,
                      title: titleController.text,
                      description: descController.text,
                      location: locationController.text,
                      startAt: DateTime.now().add(const Duration(days: 7, hours: 19, minutes: 30)),
                    );
                if (mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final comm = context.watch<CommunityProvider>();
    final meetingProvider = context.watch<MeetingProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isManager = comm.isCurrentUserManager;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Toplantılar & Takvim'),
        actions: [
          if (isManager)
            IconButton(
              icon: const Icon(Icons.add_circle_outline_rounded),
              tooltip: 'Toplantı Planla',
              onPressed: _showCreateDialog,
            ),
        ],
      ),
      body: meetingProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : meetingProvider.meetings.isEmpty
              ? EmptyStateView(
                  icon: Icons.calendar_month_rounded,
                  title: 'Planlanmış toplantı bulunmuyor.',
                  actionLabel: isManager ? 'Toplantı Planla' : null,
                  onAction: isManager ? _showCreateDialog : null,
                )
              : RefreshIndicator(
                  onRefresh: () async => _load(),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: meetingProvider.meetings.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (ctx, index) {
                      final item = meetingProvider.meetings[index];
                      final isAttending = item.userRsvp == 'ATTENDING';

                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurface : Colors.white,
                          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                          border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.event_available_rounded, color: AppColors.primary, size: 22),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.title,
                                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Tarih: ${item.startAt.toLocal().toString().substring(0, 16)}',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: isDark ? AppColors.primaryLight : AppColors.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    item.location,
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ),
                              ],
                            ),
                            if (item.description != null && item.description!.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(item.description!, style: Theme.of(context).textTheme.bodyMedium),
                            ],
                            const SizedBox(height: 16),
                            const Divider(),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Katılacak Sakin Sayısı: ${item.attendingCount}',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                                ),
                                Row(
                                  children: [
                                    OutlinedButton(
                                      style: OutlinedButton.styleFrom(
                                        backgroundColor: isAttending ? AppColors.success.withValues(alpha: 0.1) : null,
                                        side: BorderSide(color: isAttending ? AppColors.success : AppColors.borderLight),
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        minimumSize: Size.zero,
                                      ),
                                      onPressed: () {
                                        context.read<MeetingProvider>().rsvp(item.id, 'ATTENDING', item.communityId);
                                      },
                                      child: Text(
                                        isAttending ? '✓ Katılıyorum' : 'Katılacağım',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isAttending ? AppColors.success : null,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    TextButton(
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        minimumSize: Size.zero,
                                      ),
                                      onPressed: () {
                                        context.read<MeetingProvider>().rsvp(item.id, 'NOT_ATTENDING', item.communityId);
                                      },
                                      child: const Text('Katılamam', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
