import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final bool isDues;

  const StatusBadge({super.key, required this.status, this.isDues = false});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label;
    IconData icon;

    if (isDues) {
      switch (status.toUpperCase()) {
        case 'PAID':
          bg = AppColors.duesPaid.withValues(alpha: 0.12);
          fg = AppColors.duesPaid;
          label = 'Ödendi';
          icon = Icons.check_circle_rounded;
          break;
        case 'PARTIAL':
          bg = AppColors.duesPartial.withValues(alpha: 0.12);
          fg = AppColors.duesPartial;
          label = 'Kısmi Ödeme';
          icon = Icons.timelapse_rounded;
          break;
        case 'OVERDUE':
          bg = AppColors.duesOverdue.withValues(alpha: 0.12);
          fg = AppColors.duesOverdue;
          label = 'Gecikmiş';
          icon = Icons.warning_rounded;
          break;
        case 'UNPAID':
        default:
          bg = AppColors.duesUnpaid.withValues(alpha: 0.12);
          fg = AppColors.duesUnpaid;
          label = 'Ödenmedi';
          icon = Icons.pending_actions_rounded;
          break;
      }
    } else {
      switch (status.toUpperCase()) {
        case 'OPEN':
          bg = AppColors.statusOpen.withValues(alpha: 0.12);
          fg = AppColors.statusOpen;
          label = 'Açık';
          icon = Icons.fiber_manual_record_rounded;
          break;
        case 'IN_PROGRESS':
          bg = AppColors.statusInProgress.withValues(alpha: 0.12);
          fg = AppColors.statusInProgress;
          label = 'İşlemde';
          icon = Icons.sync_rounded;
          break;
        case 'WAITING':
          bg = AppColors.statusWaiting.withValues(alpha: 0.12);
          fg = AppColors.statusWaiting;
          label = 'Beklemede';
          icon = Icons.hourglass_top_rounded;
          break;
        case 'RESOLVED':
          bg = AppColors.statusResolved.withValues(alpha: 0.12);
          fg = AppColors.statusResolved;
          label = 'Çözüldü';
          icon = Icons.check_circle_rounded;
          break;
        case 'CLOSED':
        default:
          bg = AppColors.statusClosed.withValues(alpha: 0.12);
          fg = AppColors.statusClosed;
          label = 'Kapandı';
          icon = Icons.lock_outline_rounded;
          break;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
