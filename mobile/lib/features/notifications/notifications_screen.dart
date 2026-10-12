import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/notification_provider.dart';
import '../../widgets/empty_state_view.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().loadNotifications();
    });
  }

  IconData _getIcon(String type) {
    switch (type.toUpperCase()) {
      case 'ANNOUNCEMENT':
        return Icons.campaign_rounded;
      case 'MAINTENANCE':
        return Icons.build_rounded;
      case 'MEETING':
        return Icons.event_rounded;
      case 'POLL':
        return Icons.poll_rounded;
      case 'PRIVATE_MESSAGE':
        return Icons.mail_rounded;
      case 'DUES_REMINDER':
        return Icons.credit_card_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _getColor(String type) {
    switch (type.toUpperCase()) {
      case 'ANNOUNCEMENT':
        return AppColors.primary;
      case 'MAINTENANCE':
        return AppColors.statusInProgress;
      case 'MEETING':
        return AppColors.info;
      case 'POLL':
        return AppColors.secondary;
      case 'DUES_REMINDER':
        return AppColors.warning;
      case 'PRIVATE_MESSAGE':
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifProvider = context.watch<NotificationProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bildirimler'),
        actions: [
          if (notifProvider.notifications.isNotEmpty)
            TextButton(
              onPressed: () => notifProvider.markAllRead(),
              child: const Text('Tümünü Oku'),
            ),
        ],
      ),
      body: notifProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : notifProvider.notifications.isEmpty
              ? const EmptyStateView(
                  icon: Icons.notifications_none_rounded,
                  title: 'Henüz yeni bildiriminiz yok.',
                  subtitle: 'Duyurular, arıza güncellemeleri ve site bilgilendirmeleri burada listelenir.',
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: notifProvider.notifications.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (ctx, index) {
                    final item = notifProvider.notifications[index];
                    final color = _getColor(item.type);

                    return InkWell(
                      onTap: () {
                        if (!item.isRead) notifProvider.markRead(item.id);
                      },
                      borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: item.isRead
                              ? (isDark ? AppColors.darkSurface : Colors.white)
                              : color.withValues(alpha: isDark ? 0.12 : 0.05),
                          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                          border: Border.all(
                            color: item.isRead
                                ? (isDark ? AppColors.borderDark : AppColors.borderLight)
                                : color.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(_getIcon(item.type), color: color, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.title,
                                    style: TextStyle(
                                      fontWeight: item.isRead ? FontWeight.w600 : FontWeight.w800,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item.body,
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                        ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    item.createdAt.toLocal().toString().substring(0, 16),
                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                  ),
                                ],
                              ),
                            ),
                            if (!item.isRead)
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
