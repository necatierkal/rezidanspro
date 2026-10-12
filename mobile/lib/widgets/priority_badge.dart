import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class PriorityBadge extends StatelessWidget {
  final String priority;

  const PriorityBadge({super.key, required this.priority});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label;
    IconData icon;

    switch (priority.toUpperCase()) {
      case 'URGENT':
        bg = AppColors.priorityUrgent.withValues(alpha: 0.12);
        fg = AppColors.priorityUrgent;
        label = 'Acil';
        icon = Icons.error_outline_rounded;
        break;
      case 'IMPORTANT':
        bg = AppColors.priorityImportant.withValues(alpha: 0.12);
        fg = AppColors.priorityImportant;
        label = 'Önemli';
        icon = Icons.priority_high_rounded;
        break;
      case 'NORMAL':
      default:
        bg = AppColors.priorityNormal.withValues(alpha: 0.10);
        fg = AppColors.priorityNormal;
        label = 'Normal';
        icon = Icons.info_outline_rounded;
        break;
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
