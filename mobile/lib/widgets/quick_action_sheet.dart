import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class QuickActionSheet extends StatelessWidget {
  final bool isManager;
  final VoidCallback onNewAnnouncement;
  final VoidCallback onReportFault;
  final VoidCallback onNewMeeting;
  final VoidCallback onNewPoll;
  final VoidCallback onNewDue;
  final VoidCallback onNewMessage;

  const QuickActionSheet({
    super.key,
    required this.isManager,
    required this.onNewAnnouncement,
    required this.onReportFault,
    required this.onNewMeeting,
    required this.onNewPoll,
    required this.onNewDue,
    required this.onNewMessage,
  });

  static void show(
    BuildContext context, {
    required bool isManager,
    required VoidCallback onNewAnnouncement,
    required VoidCallback onReportFault,
    required VoidCallback onNewMeeting,
    required VoidCallback onNewPoll,
    required VoidCallback onNewDue,
    required VoidCallback onNewMessage,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => QuickActionSheet(
        isManager: isManager,
        onNewAnnouncement: onNewAnnouncement,
        onReportFault: onReportFault,
        onNewMeeting: onNewMeeting,
        onNewPoll: onNewPoll,
        onNewDue: onNewDue,
        onNewMessage: onNewMessage,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.black12,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                'Hızlı İşlemler',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              )
            ],
          ),
          const SizedBox(height: 16),
          if (isManager) ...[
            // MANAGER QUICK ACTIONS (Sec 12, 82)
            Row(
              children: [
                Expanded(
                  child: _ActionTile(
                    title: 'Duyuru Yayınla',
                    icon: Icons.campaign_rounded,
                    color: AppColors.primary,
                    onTap: () {
                      Navigator.pop(context);
                      onNewAnnouncement();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionTile(
                    title: 'Arıza Kaydı Aç',
                    icon: Icons.build_rounded,
                    color: AppColors.statusInProgress,
                    onTap: () {
                      Navigator.pop(context);
                      onReportFault();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _ActionTile(
                    title: 'Toplantı Planla',
                    icon: Icons.calendar_month_rounded,
                    color: AppColors.info,
                    onTap: () {
                      Navigator.pop(context);
                      onNewMeeting();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionTile(
                    title: 'Yeni Anket',
                    icon: Icons.poll_rounded,
                    color: AppColors.secondary,
                    onTap: () {
                      Navigator.pop(context);
                      onNewPoll();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _ActionTile(
                    title: 'Aidat Tanımla',
                    icon: Icons.credit_card_rounded,
                    color: AppColors.warning,
                    onTap: () {
                      Navigator.pop(context);
                      onNewDue();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionTile(
                    title: 'Sakine Mesaj Yaz',
                    icon: Icons.mail_rounded,
                    color: AppColors.primaryLight,
                    onTap: () {
                      Navigator.pop(context);
                      onNewMessage();
                    },
                  ),
                ),
              ],
            ),
          ] else ...[
            // RESIDENT QUICK ACTIONS (Sec 82)
            Row(
              children: [
                Expanded(
                  child: _ActionTile(
                    title: 'Arıza Bildir',
                    icon: Icons.build_rounded,
                    color: AppColors.statusInProgress,
                    onTap: () {
                      Navigator.pop(context);
                      onReportFault();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionTile(
                    title: 'Yöneticiye Mesaj',
                    icon: Icons.mail_rounded,
                    color: AppColors.primary,
                    onTap: () {
                      Navigator.pop(context);
                      onNewMessage();
                    },
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionTile({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.15 : 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: isDark ? Colors.white : AppColors.textPrimaryLight,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
